import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mathmate/library/models/study_material.dart';
import 'package:mathmate/library/presentation/material_upload_sheet.dart';
import 'package:mathmate/library/services/ingestion_service.dart';
import 'package:mathmate/library/services/material_repository.dart';

/// 资料库主页
///
/// 监听 MaterialRepository.watch 自动刷新；支持高校筛选 + 关键词检索。
/// L1 闭环演示点：上传 → AI 分类 → 自动出现在网格。
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  ColorScheme get cs => Theme.of(context).colorScheme;

  StreamSubscription<List<StudyMaterial>>? _sub;
  List<StudyMaterial> _materials = const <StudyMaterial>[];
  String _filterUni = '';
  String _keyword = '';
  bool _busy = false;
  String _busyText = '';

  @override
  void initState() {
    super.initState();
    _materials = MaterialRepository.instance.all();
    _sub = MaterialRepository.instance.watch.listen((List<StudyMaterial> list) {
      if (mounted) {
        _materials = list;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<StudyMaterial> get _filtered {
    List<StudyMaterial> list = _materials;
    if (_filterUni.isNotEmpty) {
      list = list.where((m) => m.university == _filterUni).toList();
    }
    if (_keyword.trim().isNotEmpty) {
      final String kw = _keyword.trim().toLowerCase();
      list = list.where((StudyMaterial m) {
        final String hay = <String>[
          m.title, m.summary, m.subject,
          ...m.knowledgePoints, ...m.keyConcepts,
        ].join(' ').toLowerCase();
        return hay.contains(kw);
      }).toList();
    }
    return list;
  }

  List<String> get _unis => MaterialRepository.instance.universities;

  Future<void> _openUpload() async {
    final MaterialKind? kind = await showModalBottomSheet<MaterialKind>(
      context: context,
      builder: (_) => const MaterialUploadSheet(),
    );
    if (kind == null || !mounted) return;
    setState(() {
      _busy = true;
      _busyText = '正在采集资料…';
    });
    try {
      await IngestionService.instance.ingest(
        kind,
        onProgress: (String t) {
          if (mounted) setState(() => _busyText = t);
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('资料已入库'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的学习资料库')),
      body: _busy
          ? _buildBusy()
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '搜索知识点 / 关键词…',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (String v) => setState(() => _keyword = v),
                  ),
                ),
                if (_unis.isNotEmpty)
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: <Widget>[
                        _chip('全部', _filterUni.isEmpty,
                            () => setState(() => _filterUni = '')),
                        ..._unis.map((String u) => _chip(
                              u,
                              _filterUni == u,
                              () => setState(() => _filterUni = u),
                            )),
                      ],
                    ),
                  ),
                Expanded(
                  child: _filtered.isEmpty ? _buildEmpty() : _buildGrid(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _openUpload,
        icon: const Icon(Icons.upload_file),
        label: const Text('上传资料'),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? cs.primary : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final List<StudyMaterial> list = _filtered;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: list.length,
      itemBuilder: (_, int i) => _MaterialCard(material: list[i]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.folder_open_rounded, size: 64, color: cs.outline),
          const SizedBox(height: 12),
          const Text('资料库还是空的',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            '点击右下角上传课件 / 真题 / 板书',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBusy() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(_busyText, style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final StudyMaterial material;
  const _MaterialCard({required this.material});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final IconData kindIcon = <MaterialKind, IconData>{
      MaterialKind.pdf: Icons.picture_as_pdf_outlined,
      MaterialKind.pptx: Icons.slideshow_outlined,
      MaterialKind.image: Icons.image_outlined,
      MaterialKind.audio: Icons.mic_none_rounded,
    }[material.kind] ??
        Icons.insert_drive_file_outlined;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(kindIcon, color: cs.primary, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  material.kind.displayName,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ),
              if (material.university != null)
                Flexible(
                  child: Text(
                    material.university!,
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              material.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          if (material.summary.isNotEmpty)
            Text(
              material.summary,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: material.knowledgePoints
                .take(3)
                .map((String k) => _tag(k, cs))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: cs.onPrimaryContainer),
      ),
    );
  }
}
