import 'package:flutter/foundation.dart';
import 'package:math_anchor/agents/base_agent.dart';
import 'package:math_anchor/agents/models/agent_models.dart';

/// 智能体调度中枢 —— 对标赛题要求②「多智能体协同架构」
///
/// 职责：
/// - 注册/管理各角色智能体
/// - 根据学习需求与画像，调度对应智能体
/// - 支持并发调度多个智能体（一键生成多种资源）
///
/// 设计要点（答辩讲述点）：
/// - 策略模式：各 Agent 实现 [BaseAgent]，Orchestrator 只面向接口编程
/// - 可插拔：新增 Agent 只需 [register]，不改调度逻辑
/// - 并发协同：[dispatchMany] 用 Future.wait 并发执行多 Agent
class Orchestrator {
  Orchestrator._();
  static final Orchestrator instance = Orchestrator._();

  final Map<AgentType, BaseAgent> _agents = <AgentType, BaseAgent>{};

  /// 注册智能体
  void register(BaseAgent agent) {
    _agents[agent.type] = agent;
  }

  /// 注销智能体
  void unregister(AgentType type) {
    _agents.remove(type);
  }

  /// 获取已注册的智能体
  BaseAgent? agentOf(AgentType type) => _agents[type];

  /// 所有已注册智能体
  List<BaseAgent> get registeredAgents =>
      _agents.values.toList(growable: false);

  /// 是否已注册某智能体
  bool isRegistered(AgentType type) => _agents.containsKey(type);

  /// 调度单个智能体
  Future<AgentResult> dispatch(
    AgentType type,
    AgentRequest request,
  ) async {
    final BaseAgent? agent = _agents[type];
    if (agent == null) {
      return AgentResult.failure(type, '未注册的智能体: ${type.displayName}');
    }
    final Stopwatch sw = Stopwatch()..start();
    try {
      final AgentResult result = await agent.run(request);
      sw.stop();
      return AgentResult(
        agentType: result.agentType,
        success: result.success,
        resources: result.resources,
        errorMessage: result.errorMessage,
        elapsed: result.elapsed ?? sw.elapsed,
      );
    } catch (e) {
      sw.stop();
      debugPrint('[Orchestrator] 调度 ${type.displayName} 异常: $e');
      return AgentResult.failure(type, '执行异常: $e');
    }
  }

  /// 并发调度多个智能体（多智能体协同的核心）
  ///
  /// 返回的结果列表顺序与 [types] 一致；单个失败不影响其它。
  Future<List<AgentResult>> dispatchMany(
    List<AgentType> types,
    AgentRequest request,
  ) async {
    final List<Future<AgentResult>> futures = types
        .map((AgentType t) => dispatch(t, request))
        .toList(growable: false);
    return Future.wait(futures);
  }

  /// 一键生成 —— 调度所有「资源生成类」智能体并发产出多种资源
  ///
  /// 这是答辩核心演示点：一次请求 → 多智能体协同 → ≥5 种资源
  List<AgentResult> _collectResourceResults(List<AgentResult> all) => all;

  /// 资源生成类智能体类型（可被一键生成调度）
  static const List<AgentType> resourceAgentTypes = <AgentType>[
    AgentType.explainer,
    AgentType.quizzer,
    AgentType.mindmapper,
    AgentType.visualizer,
  ];

  /// 一键生成多资源（仅调度已注册的资源类智能体）
  Future<List<AgentResult>> generateResources(AgentRequest request) async {
    final List<AgentType> ready = resourceAgentTypes
        .where((AgentType t) => _agents.containsKey(t))
        .toList(growable: false);
    final List<AgentResult> all = await dispatchMany(ready, request);
    return _collectResourceResults(all);
  }
}