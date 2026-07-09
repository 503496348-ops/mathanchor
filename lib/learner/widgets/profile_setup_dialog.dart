import 'package:flutter/material.dart';
import 'package:mathmate/learner/models/learner_profile.dart';
import 'package:mathmate/learner/services/profile_builder_service.dart';
import 'package:mathmate/learner/services/profile_repository.dart';

/// 对话式学习画像构建对话框 —— 对标赛题要求①
///
/// 摒弃传统表单，通过自然语言对话构建/更新 6 维画像。
/// 支持增量补充（随学随新）。
///
/// 用法：`final p = await showDialog<LearnerProfile>(context, builder: ...ProfileSetupDialog);`
class ProfileSetupDialog extends StatefulWidget {
  final ProfileBuilderService builderService;

  ProfileSetupDialog({super.key, ProfileBuilderService? builderService})
      : builderService = builderService ?? ProfileBuilderService();

  /// 便捷入口
  static Future<LearnerProfile?> show(BuildContext context) {
    return showDialog<LearnerProfile>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProfileSetupDialog(),
    );
  }

  @override
  State<ProfileSetupDialog> createState() => _ProfileSetupDialogState();
}

class _ProfileSetupDialogState extends State<ProfileSetupDialog> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ProfileRepository _repo = ProfileRepository.instance;

  bool _loading = false;
  LearnerProfile? _profile;
  String? _error;

  // 六维展示配置
  static final List<_DimMeta> _dims = <_DimMeta>[
    _DimMeta('① 知识基础', (p) => p.knowledgeBase.summary),
    _DimMeta('② 认知风格', (p) => p.cognitiveStyle.summary),
    _DimMeta('③ 易错点', (p) => p.errorPatterns.summary),
    _DimMeta('④ 学习目标', (p) => p.learningGoals.summary),
    _DimMeta('⑤ 学习历史', (p) => p.learningHistory.summary),
    _DimMeta('⑥ 学习偏好', (p) => p.preferences.summary),
  ];

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final p = await _repo.load();
    if (mounted && p != null) {
      setState(() => _profile = p);
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  /// 一键填入示例（降低使用门槛，便于答辩演示）
  void _fillExample() {
    _inputCtrl.text =
        '我是一名高三学生，主攻数学。目前函数和导数掌握得还行（约80%），但立体几何和概率统计比较薄弱（约40%）。'
        '我比较喜欢通过图形和动画理解概念，偏好有挑战性的题目，但基础也要打牢。'
        '我的目标是高考数学冲刺130分以上，常在解析几何上出错。希望学习节奏稳扎稳打。';
    setState(() {});
  }

  Future<void> _buildProfile() async {
    final String text = _inputCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _error = '请先描述你的学习情况');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final p = await widget.builderService.buildProfile(
      text,
      existing: _profile,
    );
    if (!mounted) return;
    if (p != null) {
      await _repo.save(p);
      setState(() {
        _profile = p;
        _loading = false;
        _inputCtrl.clear();
      });
    } else {
      setState(() {
        _loading = false;
        _error = '画像构建失败，请检查网络或 API 配置后重试';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildIntro(),
                    const SizedBox(height: 12),
                    _buildInput(),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13)),
                    ],
                    const SizedBox(height: 12),
                    if (_profile != null) ...<Widget>[
                      const Divider(),
                      _buildCompleteness(),
                      const SizedBox(height: 12),
                      ..._dims.map(_buildDimRow),
                    ],
                  ],
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF6A5BFF), Color(0xFF4C6FFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.psychology, color: Colors.white),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '构建你的学习画像',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(_profile),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '用自然语言描述你的学习情况，AI 会自动抽取 6 个维度的画像特征：',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            '专业/年级 · 学习目标 · 薄弱知识点 · 易错点 · 认知风格 · 学习偏好',
            style: TextStyle(fontSize: 12, color: Colors.blue[700]),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _fillExample,
              icon: const Icon(Icons.lightbulb_outline, size: 16),
              label: const Text('填入示例', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return TextField(
      controller: _inputCtrl,
      maxLines: 4,
      textInputAction: TextInputAction.newline,
      decoration: const InputDecoration(
        hintText: '例如：我是大一学生，想学好高数，微积分比较吃力，偏好看图理解……',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildCompleteness() {
    final double c = _profile!.completeness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text('画像完整度', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('${(c * 100).round()}% ${_profile!.isUsable ? "✓ 可用于个性化" : "（建议补充更多维度）"}'),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: c,
          minHeight: 8,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            _profile!.isUsable ? Colors.green : Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildDimRow(_DimMeta meta) {
    final String value = meta.value(_profile!);
    final bool filled = value.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            filled ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: filled ? Colors.green : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 13),
                children: <TextSpan>[
                  TextSpan(
                    text: '${meta.label}：',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: filled ? value : '待补充',
                    style: TextStyle(
                      color: filled ? null : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: <Widget>[
          if (_profile != null && _profile!.isUsable)
            TextButton(
              onPressed: () => Navigator.of(context).pop(_profile),
              child: const Text('保存并使用'),
            ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _loading ? null : _buildProfile,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              _profile == null ? '构建画像' : '继续补充（随学随新）',
            ),
          ),
        ],
      ),
    );
  }
}

class _DimMeta {
  final String label;
  final String Function(LearnerProfile) value;
  const _DimMeta(this.label, this.value);
}