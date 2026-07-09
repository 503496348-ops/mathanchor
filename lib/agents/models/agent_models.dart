import 'package:mathmate/learner/models/learner_profile.dart';

/// 智能体类型 —— 对应赛题「多智能体协同」的不同角色
enum AgentType {
  /// 解题智能体（已有 SolverService）
  solver,

  /// 可视化智能体（已有 AI绘图 + GeoChat）
  visualizer,

  /// 讲解智能体：生成讲解文档
  explainer,

  /// 出题智能体：生成练习题库
  quizzer,

  /// 导图智能体：生成知识点思维导图
  mindmapper,

  /// 辅导智能体：多模态答疑（加分项）
  tutor,

  /// 规划智能体：学习路径规划（加分项）
  planner,
}

/// 智能体类型显示名
extension AgentTypeX on AgentType {
  String get displayName {
    switch (this) {
      case AgentType.solver:
        return '解题';
      case AgentType.visualizer:
        return '可视化';
      case AgentType.explainer:
        return '讲解';
      case AgentType.quizzer:
        return '出题';
      case AgentType.mindmapper:
        return '思维导图';
      case AgentType.tutor:
        return '辅导';
      case AgentType.planner:
        return '规划';
    }
  }
}

/// 多模态资源类型（赛题要求 ≥5 种个性化资源）
enum ResourceType {
  /// 讲解文档（Markdown + LaTeX）
  document,

  /// 知识点思维导图（Mermaid 结构）
  mindmap,

  /// 练习题库（选择/填空/解答）
  quiz,

  /// 可视化图（Matplotlib 代码 / GeoGebra）
  visualization,

  /// 教学视频/动画脚本（加分）
  video,

  /// 代码实操案例（加分）
  codeCase,

  /// 解题方案
  solution,
}

extension ResourceTypeX on ResourceType {
  String get displayName {
    switch (this) {
      case ResourceType.document:
        return '讲解文档';
      case ResourceType.mindmap:
        return '思维导图';
      case ResourceType.quiz:
        return '练习题';
      case ResourceType.visualization:
        return '可视化';
      case ResourceType.video:
        return '视频脚本';
      case ResourceType.codeCase:
        return '代码案例';
      case ResourceType.solution:
        return '解题方案';
    }
  }
}

/// 资源内容格式
enum ResourceFormat {
  markdown,
  mermaid,
  python,
  json,
  geogebra,
  plainText,
}

/// 智能体请求
class AgentRequest {
  /// 学习主题 / 知识点（如"二次函数"）
  final String topic;

  /// 用户的自然语言需求描述
  final String userNeed;

  /// 学习者画像（个性化依据，可空）
  final LearnerProfile? profile;

  /// 额外参数（各 Agent 自定义）
  final Map<String, dynamic> extra;

  const AgentRequest({
    required this.topic,
    required this.userNeed,
    this.profile,
    this.extra = const {},
  });

  /// 画像摘要文本（供注入 Prompt），无画像则空串
  String get profileSummary => profile?.toPromptSummary() ?? '';
}

/// 智能体产出的多模态资源
class AgentResource {
  final ResourceType type;

  /// 资源标题
  final String title;

  /// 资源内容（markdown / mermaid / python 代码 / json 等）
  final String content;

  /// 内容格式
  final ResourceFormat format;

  /// 元数据（如题目数量、难度、关联知识点等）
  final Map<String, dynamic> meta;

  const AgentResource({
    required this.type,
    required this.title,
    required this.content,
    this.format = ResourceFormat.markdown,
    this.meta = const {},
  });
}

/// 智能体执行结果
class AgentResult {
  final AgentType agentType;

  /// 是否成功
  final bool success;

  /// 产出的资源列表（一个 Agent 可产出多个资源）
  final List<AgentResource> resources;

  /// 失败原因
  final String? errorMessage;

  /// 执行耗时
  final Duration? elapsed;

  const AgentResult({
    required this.agentType,
    required this.success,
    this.resources = const [],
    this.errorMessage,
    this.elapsed,
  });

  factory AgentResult.failure(AgentType type, String error) =>
      AgentResult(agentType: type, success: false, errorMessage: error);

  factory AgentResult.success(AgentType type, List<AgentResource> resources,
          {Duration? elapsed}) =>
      AgentResult(
          agentType: type,
          success: true,
          resources: resources,
          elapsed: elapsed);
}