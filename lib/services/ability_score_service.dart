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
  static const double lambdaComputation = 60.0; // 计算能力增长半衰期（更慢）

  /// 计算能力维度索引
  static const int computationIndex = 0;

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
  ///
  /// 注意：计算能力（index 0）不接收独立答题统计，
  /// 传入 0 会被忽略，其分数由其他维度的聚合数据自动计算。
  Future<void> recordAnswer({
    required int dimensionIndex,
    required bool isCorrect,
    double difficulty = 3.0,
  }) async {
    if (dimensionIndex <= 0 || dimensionIndex >= _stats.length) return;

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
  /// [dimensionIndex] 维度索引。
  /// - 索引 0（计算能力）：聚合维度 1~5 的总做题量 + 总正确率，慢增长，不低于自评。
  /// - 其他索引：使用该维度独立的答题统计计算。
  ///
  /// 返回 1.0 ~ 5.0 的分数
  double calculateScore(int dimensionIndex) {
    if (dimensionIndex < 0 ||
        dimensionIndex >= UserRadarProfile.dimensionNames.length) {
      return 1.0;
    }

    // 计算能力：聚合其他维度统计，缓慢提升
    if (dimensionIndex == computationIndex) {
      return _calculateComputationScore();
    }

    // 其他维度：标准标签驱动算法
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

  /// 计算能力专属算法：
  /// 聚合维度 1~5 的总做题量和总正确率，
  /// 使用更慢的增长曲线（λ=60），且分数不低于自评值。
  double _calculateComputationScore() {
    // 聚合其他 5 个维度的统计数据
    int totalN = 0;
    int totalCorrect = 0;
    double totalDifficultyWeight = 0;
    double weightedDifficulty = 0;

    for (int i = 1; i < _stats.length; i++) {
      final DimensionStats s = _stats[i];
      totalN += s.totalQuestions;
      totalCorrect += s.correctQuestions;
      if (s.totalQuestions > 0) {
        weightedDifficulty += s.avgDifficulty * s.totalQuestions;
        totalDifficultyWeight += s.totalQuestions;
      }
    }

    final double R =
        totalN > 0 ? totalCorrect / totalN : 0.0;
    final double D = totalDifficultyWeight > 0
        ? (weightedDifficulty / totalDifficultyWeight).clamp(1.0, 5.0)
        : 3.0;

    final double self = _selfAssessment?.scores[computationIndex] ?? 1.0;

    final double score = _applyAlgorithm(
      self: self,
      N: totalN,
      R: R,
      D: D,
      lambdaValue: lambdaComputation,
    );

    // 计算能力只升不降，不低于自评分数
    return score.clamp(self, 5.0);
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
