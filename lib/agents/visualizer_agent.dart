import 'package:mathmate/agents/base_agent.dart';
import 'package:mathmate/agents/models/agent_models.dart';
import 'package:mathmate/fusion/ai_drawing/services/ai_drawing_service.dart';
import 'package:mathmate/fusion/models/ai_models.dart';

/// 可视化智能体 —— 包装现有 [AIDrawingService]
///
/// 将「AI 绘图」能力纳入多智能体体系，作为「可视化」资源生成角色。
/// 对标赛题要求②中「多模态教学视频/动画」「可视化」类资源。
class VisualizerAgent implements BaseAgent {
  final AIDrawingService _drawing;

  VisualizerAgent({AIDrawingService? drawing})
      : _drawing = drawing ?? AIDrawingService();

  @override
  AgentType get type => AgentType.visualizer;

  @override
  String get name => '可视化智能体';

  @override
  String get description => '根据学习需求生成 Matplotlib 可视化绘图代码';

  @override
  Future<AgentResult> run(AgentRequest request) async {
    // 根据画像调节可视化风格（如认知风格偏好）
    final String description = request.userNeed.trim().isEmpty
        ? request.topic
        : '${request.topic}：${request.userNeed}';

    // 若画像中有偏好，附加到描述（个性化体现）
    final String enriched = request.profile != null && request.profile!.isUsable
        ? '$description\n（请兼顾该学习者的偏好：${request.profileSummary}）'
        : description;

    final AIGenerationResult result = await _drawing.generateVisualization(
      description: enriched,
    );

    if (result.isSuccess) {
      return AgentResult.success(
        AgentType.visualizer,
        <AgentResource>[
          AgentResource(
            type: ResourceType.visualization,
            title: '${request.topic} · 可视化',
            content: result.code,
            format: ResourceFormat.python,
            meta: <String, dynamic>{'promptType': result.promptType},
          ),
        ],
      );
    }
    return AgentResult.failure(
      AgentType.visualizer,
      result.errorMessage ?? '可视化生成失败',
    );
  }
}