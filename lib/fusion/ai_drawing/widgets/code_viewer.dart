import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 代码显示和编辑组件
///
/// 支持代码高亮、复制、编辑等功能
class CodeViewerWidget extends StatefulWidget {
  /// 代码内容
  final String code;

  /// 是否可编辑
  final bool editable;

  /// 代码变更回调
  final ValueChanged<String>? onCodeChanged;

  /// 代码语言
  final String language;

  /// 是否显示行号
  final bool showLineNumbers;

  /// 是否显示复制按钮
  final bool showCopyButton;

  const CodeViewerWidget({
    super.key,
    required this.code,
    this.editable = false,
    this.onCodeChanged,
    this.language = 'python',
    this.showLineNumbers = true,
    this.showCopyButton = true,
  });

  @override
  State<CodeViewerWidget> createState() => _CodeViewerWidgetState();
}

class _CodeViewerWidgetState extends State<CodeViewerWidget> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.code);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 工具栏
          if (widget.showCopyButton)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.language.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () => _copyCode(context),
                    tooltip: '复制代码',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          // 代码内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: widget.editable
                  ? _buildEditableCode()
                  : _buildReadOnlyCode(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建只读代码显示
  Widget _buildReadOnlyCode() {
    final lines = widget.code.split('\n');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showLineNumbers)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  lines.length,
                  (index) => Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          Text(
            widget.code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建可编辑代码
  Widget _buildEditableCode() {
    return TextField(
      controller: _textController,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        height: 1.5,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: widget.onCodeChanged,
    );
  }

  /// 复制代码到剪贴板
  void _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.code));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('代码已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}