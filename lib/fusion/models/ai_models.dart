/// 融合模块通用数据模型
///
/// 定义了 AI 绘图功能中使用的核心数据结构
library;

/// AI 生成结果
class AIGenerationResult {
  /// 生成的代码
  final String code;

  /// 生成时间戳
  final DateTime generatedAt;

  /// 是否成功
  final bool isSuccess;

  /// 错误信息（如果失败）
  final String? errorMessage;

  /// 使用的 Prompt 类型
  final String promptType;

  AIGenerationResult({
    required this.code,
    required this.generatedAt,
    required this.isSuccess,
    this.errorMessage,
    required this.promptType,
  });

  /// 创建成功结果
  factory AIGenerationResult.success({
    required String code,
    required String promptType,
  }) {
    return AIGenerationResult(
      code: code,
      generatedAt: DateTime.now(),
      isSuccess: true,
      promptType: promptType,
    );
  }

  /// 创建失败结果
  factory AIGenerationResult.failure({
    required String errorMessage,
    required String promptType,
  }) {
    return AIGenerationResult(
      code: '',
      generatedAt: DateTime.now(),
      isSuccess: false,
      errorMessage: errorMessage,
      promptType: promptType,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'generatedAt': generatedAt.toIso8601String(),
      'isSuccess': isSuccess,
      'errorMessage': errorMessage,
      'promptType': promptType,
    };
  }

  /// 从 JSON 创建
  factory AIGenerationResult.fromJson(Map<String, dynamic> json) {
    return AIGenerationResult(
      code: json['code'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      isSuccess: json['isSuccess'] as bool,
      errorMessage: json['errorMessage'] as String?,
      promptType: json['promptType'] as String,
    );
  }
}

/// 可视化请求
class VisualizationRequest {
  /// 用户描述
  final String description;

  /// 请求类型
  final VisualizationType type;

  /// 额外参数
  final Map<String, String> parameters;

  /// 创建时间
  final DateTime createdAt;

  VisualizationRequest({
    required this.description,
    required this.type,
    this.parameters = const {},
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'type': type.toString(),
      'parameters': parameters,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// 可视化类型
enum VisualizationType {
  /// 函数图像
  function,

  /// 几何图形
  geometry,

  /// 数据图表
  dataChart,

  /// 一般图形
  general,
}

/// 可视化记录
class VisualizationRecord {
  /// 记录 ID
  final String id;

  /// 用户描述
  final String description;

  /// 生成的代码
  final String generatedCode;

  /// 渲染结果图片路径（可选）
  final String? renderedImagePath;

  /// 可视化类型
  final VisualizationType type;

  /// 创建时间
  final DateTime createdAt;

  /// 标签
  final List<String> tags;

  /// 是否收藏
  final bool isFavorite;

  VisualizationRecord({
    required this.id,
    required this.description,
    required this.generatedCode,
    this.renderedImagePath,
    required this.type,
    required this.createdAt,
    this.tags = const [],
    this.isFavorite = false,
  });

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'generatedCode': generatedCode,
      'renderedImagePath': renderedImagePath,
      'type': type.toString(),
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
      'isFavorite': isFavorite,
    };
  }

  /// 从 JSON 创建
  factory VisualizationRecord.fromJson(Map<String, dynamic> json) {
    return VisualizationRecord(
      id: json['id'] as String,
      description: json['description'] as String,
      generatedCode: json['generatedCode'] as String,
      renderedImagePath: json['renderedImagePath'] as String?,
      type: _parseVisualizationType(json['type'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      tags: List<String>.from(json['tags'] as List),
      isFavorite: json['isFavorite'] as bool,
    );
  }

  static VisualizationType _parseVisualizationType(String typeStr) {
    switch (typeStr) {
      case 'VisualizationType.function':
        return VisualizationType.function;
      case 'VisualizationType.geometry':
        return VisualizationType.geometry;
      case 'VisualizationType.dataChart':
        return VisualizationType.dataChart;
      default:
        return VisualizationType.general;
    }
  }
}

/// 代码优化请求
class CodeOptimizeRequest {
  /// 当前代码
  final String currentCode;

  /// 优化指令
  final String instruction;

  /// 创建时间
  final DateTime createdAt;

  CodeOptimizeRequest({
    required this.currentCode,
    required this.instruction,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'currentCode': currentCode,
      'instruction': instruction,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// 代码修复请求
class CodeRepairRequest {
  /// 当前代码
  final String currentCode;

  /// 错误信息
  final String errorText;

  /// 创建时间
  final DateTime createdAt;

  CodeRepairRequest({
    required this.currentCode,
    required this.errorText,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'currentCode': currentCode,
      'errorText': errorText,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}