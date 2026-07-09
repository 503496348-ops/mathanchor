import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mathmate/models/user_radar_profile.dart';

/// 单个维度的答题统计
class DimensionStats {
  int totalQuestions; // N
  int correctQuestions; // 正确题数
  double avgDifficulty; // D (1~5)

  DimensionStats({
    this.totalQuestions = 0,
    this.correctQuestions = 0,
    this.avgDifficulty = 3.0,
  });

  double get correctRate =>
      totalQuestions > 0 ? correctQuestions / totalQuestions : 0.0;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'totalQuestions': totalQuestions,
        'correctQuestions': correctQuestions,
        'avgDifficulty': avgDifficulty,
      };

  factory DimensionStats.fromJson(Map<String, dynamic> json) =>
      DimensionStats(
        totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
        correctQuestions: (json['correctQuestions'] as num?)?.toInt() ?? 0,
        avgDifficulty:
            (json['avgDifficulty'] as num?)?.toDouble() ?? 3.0,
      );
}

/// 数学能力评分服务
///
/// 实现 plan.md 中的三阶算法：
/// 1. 贝叶斯收缩正确率（自评作为先验）
/// 2. 题量熟练度权重（对数增长）
/// 3. 难度系数修正
///
/// 结果范围：1.0 ~ 5.0
///
/// **维度 0（计算能力）特殊处理**：
/// 题库中没有"计算"类型标签，因此该维度不接收独立的答题统计。
/// 其分数由其他 5 个维度的总做题量和总正确率综合计算，
/// 使用更慢的增长曲线（λ=60），且不低于自评分数（只升不降）。
class AbilityScoreService extends ChangeNotifier {
  static final AbilityScoreService _instance = AbilityScoreService._();
  factory AbilityScoreService() => _instance;
  AbilityScoreService._();

  /// 超参数
  static const double n0 = 5.0; // 初始虚拟样本量
  static const double lambda = 30.0; // 题量成长半衰期

  /// 用户自评分数（1~5）
  UserRadarProfile? _selfAssessment;

  /// 各维度答题统计
  final List<DimensionStats> _stats = List<DimensionStats>.generate(
    UserRadarProfile.dimensionNames.length,
    (_) => DimensionStats(),
  );

  UserRadarProfile? get selfAssessment => _selfAssessment;
  List<DimensionStats> get stats => _stats;

  /// 是否已完成自评
  bool get hasAssessment => _selfAssessment != null;

  /// 保存自评分数
  Future<void> saveSelfAssessment(UserRadarProfile profile) async {
    _selfAssessment = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ability_self_assessment', jsonEncode(profile.toJson()));
    notifyListeners();
  }

  /// 加载已保存的自评
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString('ability_self_assessment');
    if (raw != null) {
      try {
        _selfAssessment = UserRadarProfile.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        _selfAssessment = null;
      }
    }
    // 加载答题统计
    final String? statsRaw = prefs.getString('ability_stats');
    if (statsRaw != null) {
      try {
        final List<dynamic> list = jsonDecode(statsRaw) as List<dynamic>;
        for (int i = 0; i < list.length && i < _stats.length; i++) {
          _stats[i] = DimensionStats.fromJson(list[i] as Map<String, dynamic>);
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  /// 保存答题统计
  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'ability_stats',
      jsonEncode(_stats.map((s) => s.toJson()).toList()),
    );
  }

  /// 更新某维度的答题统计（供题库模块调用）
  Future<void> recordAnswer({
    required int dimensionIndex,
    required bool isCorrect,
    double difficulty = 3.0,
  }) async {
    if (dimensionIndex < 0 || dimensionIndex >= _stats.length) return;

    final DimensionStats s = _stats[dimensionIndex];
    // 指数移动平均更新难度
    s.avgDifficulty = s.avgDifficulty * 0.9 + difficulty * 0.1;
    s.totalQuestions++;
    if (isCorrect) s.correctQuestions++;

    await _saveStats();
    notifyListeners();
  }

  /// 计算某个维度的最终能力分（核心算法）
  ///
  /// [dimensionIndex] 维度索引（0~5，对应六个数学能力维度）。
  /// 所有维度统一使用标准三阶算法计算。
  ///
  /// 返回 1.0 ~ 5.0 的分数
  double calculateScore(int dimensionIndex) {
    if (dimensionIndex < 0 ||
        dimensionIndex >= UserRadarProfile.dimensionNames.length) {
      return 1.0;
    }

    final double self =
        _selfAssessment?.scores[dimensionIndex] ?? 1.0;
    final DimensionStats s = _stats[dimensionIndex];
    final int N = s.totalQuestions;
    final double R = s.correctRate;
    final double D = s.avgDifficulty.clamp(1.0, 5.0);

    return _applyAlgorithm(
      self: self,
      N: N,
      R: R,
      D: D,
      lambdaValue: lambda,
    );
  }

  /// 通用三阶算法
  ///
  /// [self] 自评 1~5, [N] 做题量, [R] 正确率 0~1, [D] 平均难度 1~5,
  /// [lambdaValue] 半衰期参数
  double _applyAlgorithm({
    required double self,
    required int N,
    required double R,
    required double D,
    required double lambdaValue,
  }) {
    // 第一步：贝叶斯收缩正确率
    final double selfRate = self / 5.0;
    final double adjustedRate =
        (N * R + n0 * selfRate) / (N + n0);

    // 第二步：题量熟练度权重
    final double weight = 1 - math.exp(-N / lambdaValue);

    // 第三步：融合基础分
    final double baseScore =
        (selfRate * (1 - weight) + adjustedRate * weight) * 5.0;

    // 第四步：难度修正
    final double difficultyFactor = 1 + (D - 3) / 10;
    final double finalScore = baseScore * difficultyFactor;

    // 边界保护
    return finalScore.clamp(1.0, 5.0);
  }

  /// 获取所有维度的当前计算分数
  UserRadarProfile get computedProfile {
    final List<double> scores = <double>[];
    for (int i = 0; i < UserRadarProfile.dimensionNames.length; i++) {
      scores.add(calculateScore(i));
    }
    return UserRadarProfile(scores: scores);
  }

  /// 重置所有数据
  Future<void> reset() async {
    _selfAssessment = null;
    for (final DimensionStats s in _stats) {
      s.totalQuestions = 0;
      s.correctQuestions = 0;
      s.avgDifficulty = 3.0;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ability_self_assessment');
    await prefs.remove('ability_stats');
    notifyListeners();
  }
}
