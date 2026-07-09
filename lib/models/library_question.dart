/// 服务器题库题目模型（映射 API 返回字段）
class LibraryQuestion {
  final String id;
  final String subject;
  final String section;
  final String type;
  final String content;
  final List<String>? options;
  final String answer;
  final String solution;
  final double difficulty; // 0~1 (服务器难度值)
  final List<String> knowledgePoints;
  final String sourceRef;

  const LibraryQuestion({
    required this.id,
    this.subject = '数学',
    required this.section,
    required this.type,
    required this.content,
    this.options,
    required this.answer,
    required this.solution,
    required this.difficulty,
    this.knowledgePoints = const <String>[],
    this.sourceRef = '',
  });

  factory LibraryQuestion.fromJson(Map<String, dynamic> json) {
    return LibraryQuestion(
      id: json['id'] as String? ?? '',
      subject: json['subject'] as String? ?? '数学',
      section: json['section'] as String? ?? '',
      type: json['type'] as String? ?? '',
      content: json['content'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      answer: json['answer'] as String? ?? '',
      solution: json['solution'] as String? ?? '',
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0.5,
      knowledgePoints: (json['knowledgePoints'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      sourceRef: (json['source'] is Map
              ? (json['source'] as Map)['ref'] as String?
              : null) ??
          '',
    );
  }

  /// 将服务器难度 (0~1) 映射到用户能力分 (1~5)
  /// 服务器难度 0.2=极简单, 0.8=极难
  /// 返回 1.0~5.0 的等效能力分
  static double serverDifficultyToAbility(double serverDifficulty) {
    return (serverDifficulty * 5.0).clamp(1.0, 5.0);
  }
}
