import 'package:flutter/material.dart';
import 'package:math_anchor/library/models/study_material.dart';

/// 上传选择底部弹层 —— 4 类资料入口
///
/// L1：图片(板书) / PDF(真题) 可用；PPT / 录音 为「即将上线」占位。
class MaterialUploadSheet extends StatelessWidget {
  const MaterialUploadSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('上传学习资料',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('AI 会自动分类、打标签、整理到你的资料库',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _option(
                    context,
                    Icons.image_outlined,
                    '板书 / 图片',
                    '拍照或从相册',
                    MaterialKind.image,
                    enabled: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _option(
                    context,
                    Icons.picture_as_pdf_outlined,
                    '真题 PDF',
                    '选择 PDF 文件',
                    MaterialKind.pdf,
                    enabled: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _option(
                    context,
                    Icons.slideshow_outlined,
                    'PPT 课件',
                    '即将上线',
                    MaterialKind.pptx,
                    enabled: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _option(
                    context,
                    Icons.mic_none_rounded,
                    '划重点录音',
                    '即将上线',
                    MaterialKind.audio,
                    enabled: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    MaterialKind kind, {
    required bool enabled,
  }) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: enabled
          ? () => Navigator.of(context).pop(kind)
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('该类型即将上线'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: enabled
              ? cs.primaryContainer.withValues(alpha: 0.5)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? cs.primary.withValues(alpha: 0.3)
                : cs.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: enabled ? cs.primary : cs.outline, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: enabled ? cs.onSurface : cs.outline,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
