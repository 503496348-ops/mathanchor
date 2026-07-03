import 'package:mathmate/agents/models/agent_models.dart';

/// 智能体统一接口 —— 对标赛题「多智能体协同架构设计」
///
/// 系统中所有智能体（解题/可视化/讲解/出题/导图/辅导/规划）都实现此接口，
/// 由 [Orchestrator] 调度中枢统一编排，实现「多智能体协同生成」。
///
/// 设计要点（答辩讲述点）：
/// - 统一接口：所有 Agent 输入 [AgentRequest]、输出 [AgentResult]
/// - 个性化：AgentRequest 携带 [LearnerProfile]，每个 Agent 可据此调节输出
/// - 可插拔：新增 Agent 只需实现此接口并在 Orchestrator 注册
abstract class BaseAgent {
  /// 智能体类型标识
  AgentType get type;

  /// 智能体名称（中文）
  String get name;

  /// 智能体职责描述
  String get description;

  /// 执行智能体任务
  ///
  /// [request] 包含主题、用户需求、学习者画像
  /// 返回 [AgentResult]，含产出的多模态资源
  Future<AgentResult> run(AgentRequest request);
}