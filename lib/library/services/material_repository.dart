import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mathmate/library/models/study_material.dart';
import 'package:mathmate/services/app_logger.dart';

/// 学习资料存储 —— 复刻 ProfileRepository 的 Box<String> + JSON 方案
///
/// 设计要点（避坑）：
/// - 独立 box 'study_materials'，与现有 typeId(0-5) 不冲突
/// - 整份资料序列化为 JSON 字符串存储，**不写 @HiveType adapter**（避免撞 typeId）
/// - Web 端（kIsWeb）跳过 Hive，用内存缓存兜底，与现有 HistoryRepository 一致
class MaterialRepository {
  MaterialRepository._();
  static final MaterialRepository instance = MaterialRepository._();

  static const String _boxName = 'study_materials';

  Box<String>? _box;
  final Map<String, StudyMaterial> _cache = <String, StudyMaterial>{};
  final StreamController<List<StudyMaterial>> _controller =
      StreamController<List<StudyMaterial>>.broadcast();

  bool get isReady => _box != null && _box!.isOpen;

  /// 资料变更流（供 UI 监听刷新）
  Stream<List<StudyMaterial>> get watch => _controller.stream;

  Future<void> init() async {
    if (isReady) return;
    if (!kIsWeb) {
      await Hive.initFlutter();
      _box = await Hive.openBox<String>(_boxName);
      _loadCacheFromBox();
    }
    _emit();
  }

  void _loadCacheFromBox() {
    _cache.clear();
    if (_box == null) return;
    for (final dynamic key in _box!.keys) {
      final StudyMaterial? m = StudyMaterial.tryDecode(_box!.get(key));
      if (m != null) _cache[m.id] = m;
    }
  }

  /// 全部资料（按上传时间倒序）
  List<StudyMaterial> all() =>
      _cache.values.toList()
        ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

  /// 按 高校 + 课程 聚合查询
  List<StudyMaterial> byUniversityCourse({String? university, String? course}) {
    return _cache.values.where((m) {
      if (university != null && m.university != university) return false;
      if (course != null && m.course != course) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  }

  /// 关键词检索（标题 / 摘要 / 学科 / 知识点 / 关键概念）
  List<StudyMaterial> search(String keyword) {
    final String kw = keyword.trim();
    if (kw.isEmpty) return all();
    return _cache.values.where((m) {
      final String hay = <String>[
        m.title, m.summary, m.subject, ...m.knowledgePoints, ...m.keyConcepts,
      ].join(' ').toLowerCase();
      return hay.contains(kw.toLowerCase());
    }).toList()
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
  }

  /// 所有不重复的高校（用于筛选 chip）
  List<String> get universities => _cache.values
      .map((m) => m.university)
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  Future<void> save(StudyMaterial m) async {
    _cache[m.id] = m;
    if (_box != null) await _box!.put(m.id, m.encode());
    AppLogger.instance.info(
        '[MaterialRepo] 保存资料 ${m.id} (${m.kind.name}) · 标题=${m.title}');
    _emit();
  }

  Future<void> delete(String id) async {
    _cache.remove(id);
    if (_box != null) await _box!.delete(id);
    _emit();
  }

  Future<void> clear() async {
    _cache.clear();
    if (_box != null) await _box!.clear();
    _emit();
  }

  void _emit() {
    _controller.add(all());
  }
}
