import 'dart:convert';

/// 学习者画像 —— 对标赛题要求①「对话式学习画像」
///
/// 包含 6 个维度（赛题硬性要求）：
/// ① 知识基础  ② 认知风格  ③ 易错点偏好
/// ④ 学习目标  ⑤ 学习历史  ⑥ 学习偏好
///
/// 通过自然语言对话抽取特征构建，支持「随学随新」（copyWith 增量更新）。
class LearnerProfile {
  /// 画像唯一 ID（一个用户一份画像）
  final String id;

  /// 创建时间
  final DateTime createdAt;

  /// 最后更新时间（随学随新）
  final DateTime updatedAt;

  /// ① 知识基础：已学知识点及掌握程度
  final KnowledgeDimension knowledgeBase;

  /// ② 认知风格：视觉/听觉/读写/动觉 + 抽象/具体倾向
  final CognitiveDimension cognitiveStyle;

  /// ③ 易错点：常见错误类型与薄弱环节
  final ErrorDimension errorPatterns;

  /// ④ 学习目标：方向、目标考试、截止时间
  final GoalDimension learningGoals;

  /// ⑤ 学习历史：近期学习记录摘要
  final HistoryDimension learningHistory;

  /// ⑥ 学习偏好：资源类型/难度/节奏偏好
  final PreferenceDimension preferences;

  LearnerProfile({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.knowledgeBase,
    required this.cognitiveStyle,
    required this.errorPatterns,
    required this.learningGoals,
    required this.learningHistory,
    required this.preferences,
  });

  /// 画像完整度（0.0–1.0），用于判断是否需要继续对话补充
  double get completeness {
    int filled = 0;
    if (knowledgeBase.isNotEmpty) filled++;
    if (cognitiveStyle.isFilled) filled++;
    if (errorPatterns.isNotEmpty) filled++;
    if (learningGoals.isFilled) filled++;
    if (learningHistory.isNotEmpty) filled++;
    if (preferences.isFilled) filled++;
    return filled / 6.0;
  }

  /// 是否已达到可用阈值（≥4/6 维度已填充）
  bool get isUsable => completeness >= 0.66;

  /// 增量更新（随学随新）
  LearnerProfile copyWith({
    KnowledgeDimension? knowledgeBase,
    CognitiveDimension? cognitiveStyle,
    ErrorDimension? errorPatterns,
    GoalDimension? learningGoals,
    HistoryDimension? learningHistory,
    PreferenceDimension? preferences,
  }) {
    return LearnerProfile(
      id: id,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      knowledgeBase: knowledgeBase ?? this.knowledgeBase,
      cognitiveStyle: cognitiveStyle ?? this.cognitiveStyle,
      errorPatterns: errorPatterns ?? this.errorPatterns,
      learningGoals: learningGoals ?? this.learningGoals,
      learningHistory: learningHistory ?? this.learningHistory,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'knowledgeBase': knowledgeBase.toJson(),
        'cognitiveStyle': cognitiveStyle.toJson(),
        'errorPatterns': errorPatterns.toJson(),
        'learningGoals': learningGoals.toJson(),
        'learningHistory': learningHistory.toJson(),
        'preferences': preferences.toJson(),
      };

  factory LearnerProfile.fromJson(Map<String, dynamic> json) {
    return LearnerProfile(
      id: json['id'] as String? ?? 'default',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      knowledgeBase: KnowledgeDimension.fromJson(
          json['knowledgeBase'] as Map<String, dynamic>? ?? {}),
      cognitiveStyle: CognitiveDimension.fromJson(
          json['cognitiveStyle'] as Map<String, dynamic>? ?? {}),
      errorPatterns: ErrorDimension.fromJson(
          json['errorPatterns'] as Map<String, dynamic>? ?? {}),
      learningGoals: GoalDimension.fromJson(
          json['learningGoals'] as Map<String, dynamic>? ?? {}),
      learningHistory: HistoryDimension.fromJson(
          json['learningHistory'] as Map<String, dynamic>? ?? {}),
      preferences: PreferenceDimension.fromJson(
          json['preferences'] as Map<String, dynamic>? ?? {}),
    );
  }

  /// 创建空白画像
  factory LearnerProfile.empty() {
    final now = DateTime.now();
    return LearnerProfile(
      id: 'default',
      createdAt: now,
      updatedAt: now,
      knowledgeBase: KnowledgeDimension.empty(),
      cognitiveStyle: CognitiveDimension.empty(),
      errorPatterns: ErrorDimension.empty(),
      learningGoals: GoalDimension.empty(),
      learningHistory: HistoryDimension.empty(),
      preferences: PreferenceDimension.empty(),
    );
  }

  /// 序列化为 JSON 字符串（用于 Hive 存储）
  String encode() => jsonEncode(toJson());

  /// 从 JSON 字符串反序列化
  static LearnerProfile? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return LearnerProfile.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// 画像文本摘要（供 Agent 调度时注入 Prompt）
  String toPromptSummary() {
    final buffer = StringBuffer();
    buffer.writeln('=== 学习者画像 ===');
    if (knowledgeBase.isNotEmpty) {
      buffer.writeln('知识基础: ${knowledgeBase.summary}');
    }
    if (cognitiveStyle.isFilled) {
      buffer.writeln('认知风格: ${cognitiveStyle.summary}');
    }
    if (errorPatterns.isNotEmpty) {
      buffer.writeln('易错点: ${errorPatterns.summary}');
    }
    if (learningGoals.isFilled) {
      buffer.writeln('学习目标: ${learningGoals.summary}');
    }
    if (preferences.isFilled) {
      buffer.writeln('学习偏好: ${preferences.summary}');
    }
    return buffer.toString().trim();
  }
}

// ---------------------------------------------------------------------------
// 六个维度
// ---------------------------------------------------------------------------

/// ① 知识基础维度
class KnowledgeDimension {
  /// 知识点掌握列表（知识点名 → 掌握度 0.0~1.0）
  final List<KnowledgeMastery> points;

  /// 当前学段/年级（如：高中、大一、考研）
  final String stage;

  /// 主攻学科（如：数学）
  final String subject;

  KnowledgeDimension({
    this.points = const [],
    this.stage = '',
    this.subject = '',
  });

  bool get isNotEmpty =>
      points.isNotEmpty || stage.isNotEmpty || subject.isNotEmpty;

  String get summary {
    final parts = <String>[];
    if (subject.isNotEmpty) parts.add('学科=$subject');
    if (stage.isNotEmpty) parts.add('学段=$stage');
    if (points.isNotEmpty) {
      parts.add('掌握情况=${points.map((p) => '${p.topic}(${(p.mastery * 100).round()}%)').join(',')}');
    }
    return parts.join('；');
  }

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => p.toJson()).toList(),
        'stage': stage,
        'subject': subject,
      };

  factory KnowledgeDimension.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? [];
    return KnowledgeDimension(
      points: rawPoints
          .map((p) => KnowledgeMastery.fromJson(p as Map<String, dynamic>))
          .toList(),
      stage: json['stage'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
    );
  }

  static KnowledgeDimension empty() => KnowledgeDimension();
}

class KnowledgeMastery {
  final String topic;
  final double mastery; // 0.0~1.0

  KnowledgeMastery({required this.topic, required this.mastery});

  Map<String, dynamic> toJson() => {'topic': topic, 'mastery': mastery};

  factory KnowledgeMastery.fromJson(Map<String, dynamic> json) {
    return KnowledgeMastery(
      topic: json['topic'] as String? ?? '',
      mastery: (json['mastery'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// ② 认知风格维度
class CognitiveDimension {
  /// VARK 倾向：视觉/听觉/读写/动觉
  final String varkType;

  /// 思维倾向：抽象/具体
  final String thinkingStyle;

  /// 详细描述
  final String description;

  CognitiveDimension({
    this.varkType = '',
    this.thinkingStyle = '',
    this.description = '',
  });

  bool get isFilled =>
      varkType.isNotEmpty ||
      thinkingStyle.isNotEmpty ||
      description.isNotEmpty;

  String get summary => [varkType, thinkingStyle, description]
      .where((s) => s.isNotEmpty)
      .join('；');

  Map<String, dynamic> toJson() => {
        'varkType': varkType,
        'thinkingStyle': thinkingStyle,
        'description': description,
      };

  factory CognitiveDimension.fromJson(Map<String, dynamic> json) {
    return CognitiveDimension(
      varkType: json['varkType'] as String? ?? '',
      thinkingStyle: json['thinkingStyle'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  static CognitiveDimension empty() => CognitiveDimension();
}

/// ③ 易错点维度
class ErrorDimension {
  /// 易错点描述列表
  final List<String> patterns;

  /// 薄弱知识点
  final List<String> weakTopics;

  ErrorDimension({
    this.patterns = const [],
    this.weakTopics = const [],
  });

  bool get isNotEmpty => patterns.isNotEmpty || weakTopics.isNotEmpty;

  String get summary => [
        if (patterns.isNotEmpty) '易错:${patterns.join(",")}',
        if (weakTopics.isNotEmpty) '薄弱:${weakTopics.join(",")}',
      ].join('；');

  Map<String, dynamic> toJson() => {
        'patterns': patterns,
        'weakTopics': weakTopics,
      };

  factory ErrorDimension.fromJson(Map<String, dynamic> json) {
    return ErrorDimension(
      patterns: (json['patterns'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      weakTopics: (json['weakTopics'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  static ErrorDimension empty() => ErrorDimension();
}

/// ④ 学习目标维度
class GoalDimension {
  final String goal; // 总目标描述
  final String subject; // 目标学科
  final String targetExam; // 目标考试（如：高考、考研、期末）
  final String? deadline; // 截止日期

  GoalDimension({
    this.goal = '',
    this.subject = '',
    this.targetExam = '',
    this.deadline,
  });

  bool get isFilled =>
      goal.isNotEmpty || subject.isNotEmpty || targetExam.isNotEmpty;

  String get summary => [goal, subject, targetExam]
      .where((s) => s.isNotEmpty)
      .join('；');

  Map<String, dynamic> toJson() => {
        'goal': goal,
        'subject': subject,
        'targetExam': targetExam,
        'deadline': deadline,
      };

  factory GoalDimension.fromJson(Map<String, dynamic> json) {
    return GoalDimension(
      goal: json['goal'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      targetExam: json['targetExam'] as String? ?? '',
      deadline: json['deadline'] as String?,
    );
  }

  static GoalDimension empty() => GoalDimension();
}

/// ⑤ 学习历史维度
class HistoryDimension {
  final List<HistoryItem> recentItems;

  HistoryDimension({this.recentItems = const []});

  bool get isNotEmpty => recentItems.isNotEmpty;

  String get summary =>
      recentItems.map((i) => '${i.topic}(${i.outcome})').join('，');

  Map<String, dynamic> toJson() => {
        'recentItems': recentItems.map((i) => i.toJson()).toList(),
      };

  factory HistoryDimension.fromJson(Map<String, dynamic> json) {
    final raw = json['recentItems'] as List<dynamic>? ?? [];
    return HistoryDimension(
      recentItems:
          raw.map((i) => HistoryItem.fromJson(i as Map<String, dynamic>)).toList(),
    );
  }

  static HistoryDimension empty() => HistoryDimension();
}

class HistoryItem {
  final String topic; // 学过的知识点
  final String outcome; // 掌握/未掌握/进行中
  final String? timestamp;

  HistoryItem({
    required this.topic,
    required this.outcome,
    this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'outcome': outcome,
        'timestamp': timestamp,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      topic: json['topic'] as String? ?? '',
      outcome: json['outcome'] as String? ?? '',
      timestamp: json['timestamp'] as String?,
    );
  }
}

/// ⑥ 学习偏好维度
class PreferenceDimension {
  /// 偏好的资源类型（文档/视频/图解/题目...）
  final List<String> preferredResourceTypes;

  /// 偏好难度（基础/中等/挑战）
  final String preferredDifficulty;

  /// 学习节奏（快速/稳扎/细致）
  final String pace;

  PreferenceDimension({
    this.preferredResourceTypes = const [],
    this.preferredDifficulty = '',
    this.pace = '',
  });

  bool get isFilled =>
      preferredResourceTypes.isNotEmpty ||
      preferredDifficulty.isNotEmpty ||
      pace.isNotEmpty;

  String get summary => [
        if (preferredResourceTypes.isNotEmpty)
          '资源偏好:${preferredResourceTypes.join(",")}',
        if (preferredDifficulty.isNotEmpty) '难度=$preferredDifficulty',
        if (pace.isNotEmpty) '节奏=$pace',
      ].join('；');

  Map<String, dynamic> toJson() => {
        'preferredResourceTypes': preferredResourceTypes,
        'preferredDifficulty': preferredDifficulty,
        'pace': pace,
      };

  factory PreferenceDimension.fromJson(Map<String, dynamic> json) {
    return PreferenceDimension(
      preferredResourceTypes:
          (json['preferredResourceTypes'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
      preferredDifficulty: json['preferredDifficulty'] as String? ?? '',
      pace: json['pace'] as String? ?? '',
    );
  }

  static PreferenceDimension empty() => PreferenceDimension();
}