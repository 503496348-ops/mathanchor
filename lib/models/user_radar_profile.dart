/// 用户六维数学能力画像数据模型
///
/// 内部存储 1.0~5.0 分，展示时 ×2 映射为 10 分制。
class UserRadarProfile {
  /// 维度名称列表（按六边形顶点顺序，从顶部顺时针排列）
  static const List<String> dimensionNames = [
    '基础代数工具',
    '函数微积分',
    '数列三角',
    '平面与空间几何',
    '概率统计',
    '组合计数',
  ];

  /// 维度 → 题库标签映射（用于服务器题目匹配）
  static const Map<String, List<String>> dimensionTags = <String, List<String>>{
    '基础代数工具': <String>['集合与逻辑', '复数', '不等式'],
    '函数微积分': <String>['函数与导数'],
    '数列三角': <String>['数列', '三角函数'],
    '平面与空间几何': <String>['向量', '立体几何', '解析几何'],
    '概率统计': <String>['概率统计'],
    '组合计数': <String>['计数原理'],
  };

  /// 内部满分值
  static const double maxScore = 5.0;

  /// 展示倍率（内部分数 × displayMultiplier = 展示分）
  static const double displayMultiplier = 2.0;

  /// 展示满分值
  static const double displayMaxScore = maxScore * displayMultiplier; // 10.0

  /// 各维度得分（1.0 ~ 5.0）
  final List<double> scores;

  UserRadarProfile({
    List<double>? scores,
  }) : scores = scores ?? List<double>.filled(dimensionNames.length, 1.0);

  /// 从 JSON 反序列化
  factory UserRadarProfile.fromJson(Map<String, dynamic> json) {
    final List<double> scores = <double>[];
    for (final String name in dimensionNames) {
      scores.add(((json[name] as num?)?.toDouble() ?? 1.0).clamp(1.0, maxScore));
    }
    return UserRadarProfile(scores: scores);
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    for (int i = 0; i < dimensionNames.length; i++) {
      json[dimensionNames[i]] = scores[i];
    }
    return json;
  }

  /// 获取指定维度的得分
  double getScore(String dimension) {
    final int index = dimensionNames.indexOf(dimension);
    return index >= 0 ? scores[index] : 1.0;
  }

  /// 获取维度名→得分的映射
  Map<String, double> get scoreMap {
    final Map<String, double> map = <String, double>{};
    for (int i = 0; i < dimensionNames.length; i++) {
      map[dimensionNames[i]] = scores[i];
    }
    return map;
  }
}
