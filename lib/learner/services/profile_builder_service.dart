import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:math_anchor/learner/models/learner_profile.dart';
import 'package:math_anchor/learner/prompts/profile_prompts.dart';
import 'package:math_anchor/services/app_logger.dart';
import 'package:math_anchor/services/deepseek_service.dart';

/// 学习者画像构建服务 —— 对标赛题要求①
///
/// 通过自然语言对话，调用大模型抽取学习者 6 维特征，构建动态画像。
/// 支持增量更新（随学随新）：传入已有画像即可融合新信息。
class ProfileBuilderService {
  final DeepSeekService _deepseek;

  ProfileBuilderService({DeepSeekService? deepseek})
      : _deepseek = deepseek ?? DeepSeekService();

  /// 从自然语言对话抽取画像
  ///
  /// [userText] 用户的自然语言描述（专业、年级、目标、历史、薄弱点、偏好等）
  /// [existing] 已有画像（传入则做增量更新，随学随新）
  /// 返回构建/更新后的画像；解析失败返回 null
  Future<LearnerProfile?> buildProfile(
    String userText, {
    LearnerProfile? existing,
  }) async {
    try {
      // 构造系统提示词（含增量更新上下文）
      String systemPrompt = ProfilePrompts.systemPrompt;
      if (existing != null) {
        final existingMap = existing.toJson()
          ..remove('id')
          ..remove('createdAt')
          ..remove('updatedAt')
          ..remove('learningHistory');
        systemPrompt +=
            '${ProfilePrompts.incrementalHint}\n已有画像（请在此基础上融合更新）：\n${jsonEncode(existingMap)}';
      }

      AppLogger.instance.info(
          '[ProfileBuilder] 开始抽取画像，输入长度=${userText.length}，增量模式=${existing != null}');

      // 调用大模型
      final raw = await _deepseek.callTextPrompt(
        prompt: systemPrompt,
        userText: userText,
      );

      // 提取 JSON
      final jsonStr = _extractJson(raw);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      // 组装完整画像（保留历史维度，因为它来自行为数据而非对话）
      final now = DateTime.now();
      final profile = LearnerProfile(
        id: existing?.id ?? 'default',
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        knowledgeBase: KnowledgeDimension.fromJson(
            parsed['knowledgeBase'] as Map<String, dynamic>? ?? {}),
        cognitiveStyle: CognitiveDimension.fromJson(
            parsed['cognitiveStyle'] as Map<String, dynamic>? ?? {}),
        errorPatterns: ErrorDimension.fromJson(
            parsed['errorPatterns'] as Map<String, dynamic>? ?? {}),
        learningGoals: GoalDimension.fromJson(
            parsed['learningGoals'] as Map<String, dynamic>? ?? {}),
        learningHistory:
            existing?.learningHistory ?? HistoryDimension.empty(),
        preferences: PreferenceDimension.fromJson(
            parsed['preferences'] as Map<String, dynamic>? ?? {}),
      );

      AppLogger.instance.info(
          '[ProfileBuilder] 画像抽取成功，完整度=${(profile.completeness * 100).round()}%');
      return profile;
    } catch (e) {
      AppLogger.instance.error('[ProfileBuilder] 画像抽取失败: $e');
      debugPrint('[ProfileBuilder] 失败: $e');
      return null;
    }
  }

  /// 从大模型响应中提取 JSON 字符串
  ///
  /// 兼容三种情况：纯 JSON、```json 代码块、JSON 前后带说明文字
  String _extractJson(String content) {
    // 1. 尝试匹配 ```json ... ``` 代码块
    final jsonBlockReg = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
      caseSensitive: false,
    );
    final blockMatch = jsonBlockReg.firstMatch(content);
    String candidate = blockMatch != null && blockMatch.groupCount >= 1
        ? blockMatch.group(1)!
        : content;

    // 2. 截取第一个 { 到最后一个 }
    final start = candidate.indexOf('{');
    final end = candidate.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return candidate.substring(start, end + 1);
    }
    return candidate.trim();
  }
}