import 'package:flutter/material.dart';
import 'package:mathmate/models/library_question.dart';
import 'package:mathmate/models/user_radar_profile.dart';
import 'package:mathmate/services/ability_score_service.dart';

/// 答题页面 —— 从题库选题后进入，支持单选/填空，提交后看解析
class QuestionSolverPage extends StatefulWidget {
  final LibraryQuestion question;

  const QuestionSolverPage({super.key, required this.question});

  @override
  State<QuestionSolverPage> createState() => _QuestionSolverPageState();
}

class _QuestionSolverPageState extends State<QuestionSolverPage> {
  final AbilityScoreService _abilityService = AbilityScoreService();

  /// 用户选择的选项（单选题）
  String? _selectedOption;

  /// 用户填写的答案（填空题）
  final TextEditingController _answerController = TextEditingController();

  /// 是否已提交
  bool _submitted = false;

  /// 是否正确
  bool? _isCorrect;

  ColorScheme get cs => Theme.of(context).colorScheme;

  LibraryQuestion get q => widget.question;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  bool get _isChoice => q.type == '单选题' || q.type == '多选题';

  void _submit() {
    final String userAnswer = _isChoice
        ? (_selectedOption ?? '')
        : _answerController.text.trim();

    if (userAnswer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一个答案')),
      );
      return;
    }

    // 判断对错
    final bool correct = _isChoice
        ? userAnswer == q.answer
        : userAnswer.toLowerCase() == q.answer.toLowerCase();

    // 记录到能力评分
    final int dimIndex = _dimensionIndex;
    if (dimIndex >= 0) {
      _abilityService.recordAnswer(
        dimensionIndex: dimIndex,
        isCorrect: correct,
        difficulty: q.difficulty * 5.0, // 0~1 → 1~5 映射
      );
    }

    setState(() {
      _submitted = true;
      _isCorrect = correct;
    });
  }

  /// 根据 section 反查维度索引
  int get _dimensionIndex {
    for (final MapEntry<String, List<String>> e
        in UserRadarProfile.dimensionTags.entries) {
      if (e.value.contains(q.section)) {
        return UserRadarProfile.dimensionNames.indexOf(e.key);
      }
    }
    return -1;
  }

  void _retry() {
    setState(() {
      _submitted = false;
      _isCorrect = null;
      _selectedOption = null;
      _answerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          q.type,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: cs.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 题目来源 + 分类标签
              _buildMeta(),
              const SizedBox(height: 16),

              // 题目内容
              _buildQuestionContent(),
              const SizedBox(height: 24),

              // 选项 / 填空
              if (_isChoice)
                _buildOptions()
              else
                _buildFillBlank(),
              const SizedBox(height: 24),

              // 提交按钮 / 结果展示
              if (!_submitted)
                _buildSubmitButton()
              else
                _buildResult(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeta() {
    return Row(
      children: <Widget>[
        if (q.sourceRef.isNotEmpty) ...[
          Icon(Icons.menu_book_rounded, size: 14, color: cs.outline),
          const SizedBox(width: 4),
          Text(q.sourceRef, style: TextStyle(fontSize: 12, color: cs.outline)),
          const SizedBox(width: 12),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            q.section,
            style: TextStyle(
              fontSize: 11,
              color: cs.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 难度星级
        ...List<Widget>.generate(
          (q.difficulty * 5).round().clamp(1, 5),
          (i) => const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
        ),
      ],
    );
  }

  Widget _buildQuestionContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Text(
        q.content,
        style: const TextStyle(fontSize: 16, height: 1.6),
      ),
    );
  }

  Widget _buildOptions() {
    final List<String> options = q.options ?? <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: options.map((opt) {
        // 解析选项：如 "A. {−1, 0}" → label="A", text="{−1, 0}"
        final String label = opt.length >= 2 && opt[1] == '.'
            ? opt.substring(0, 1)
            : opt;
        final String text = opt.length >= 2 && opt[1] == '.'
            ? opt.substring(2).trim()
            : opt;

        final bool isSelected = _selectedOption == label;
        final bool showCorrect = _submitted && label == q.answer;
        final bool showWrong = _submitted && isSelected && label != q.answer;

        Color? bgColor;
        Color? borderColor;
        if (showCorrect) {
          bgColor = Colors.green.withValues(alpha: 0.1);
          borderColor = Colors.green;
        } else if (showWrong) {
          bgColor = Colors.red.withValues(alpha: 0.1);
          borderColor = Colors.red;
        } else if (isSelected) {
          bgColor = cs.primaryContainer;
          borderColor = cs.primary;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: _submitted
                ? null
                : () => setState(() => _selectedOption = label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor ?? cs.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: borderColor ?? cs.outlineVariant.withValues(alpha: 0.5),
                  width: borderColor != null ? 2 : 1,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected && !showWrong
                          ? cs.primary
                          : showCorrect
                              ? Colors.green
                              : showWrong
                                  ? Colors.red
                                  : cs.surfaceContainerHighest,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: (isSelected || showCorrect || showWrong)
                            ? Colors.white
                            : cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  if (showCorrect)
                    const Icon(Icons.check_circle, color: Colors.green, size: 22),
                  if (showWrong)
                    const Icon(Icons.cancel, color: Colors.red, size: 22),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFillBlank() {
    return TextField(
      controller: _answerController,
      enabled: !_submitted,
      decoration: InputDecoration(
        hintText: '请输入你的答案...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: const Icon(Icons.edit_rounded),
      ),
      style: const TextStyle(fontSize: 16),
      onSubmitted: _submitted ? null : (_) => _submit(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: _submit,
        icon: const Icon(Icons.check_rounded),
        label: const Text('提交答案', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCorrect == true
            ? Colors.green.withValues(alpha: 0.08)
            : Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCorrect == true
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 结果标题
          Row(
            children: <Widget>[
              Icon(
                _isCorrect == true
                    ? Icons.emoji_events_rounded
                    : Icons.lightbulb_outline_rounded,
                color: _isCorrect == true ? Colors.green : Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                _isCorrect == true ? '回答正确！' : '答案不正确',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _isCorrect == true ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 正确答案
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('正确答案：',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  q.answer,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 解析
          const Text('解析：',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            q.solution,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),

          // 操作按钮
          Row(
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('重新作答'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('下一题'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
