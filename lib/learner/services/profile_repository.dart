import 'package:hive_flutter/hive_flutter.dart';
import 'package:math_anchor/learner/models/learner_profile.dart';

/// 学习者画像存储 —— 对标赛题要求①「随学随新」
///
/// 采用 Hive + JSON 字符串方案（独立 box），无需 build_runner 生成 adapter，
/// 结构可随业务迭代灵活变化，且不与现有 typeId（0–3）冲突。
class ProfileRepository {
  ProfileRepository._();
  static final ProfileRepository instance = ProfileRepository._();

  static const String _boxName = 'learner_profile';
  static const String _key = 'default'; // 单用户单画像

  Box<String>? _box;

  bool get isReady => _box != null && _box!.isOpen;

  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
  }

  /// 读取画像（无则返回 null）
  Future<LearnerProfile?> load() async {
    await init();
    return LearnerProfile.tryDecode(_box!.get(_key));
  }

  /// 保存画像（随学随新：覆盖更新）
  Future<void> save(LearnerProfile profile) async {
    await init();
    await _box!.put(_key, profile.encode());
  }

  /// 是否已存在画像
  Future<bool> hasProfile() async {
    await init();
    final raw = _box!.get(_key);
    return raw != null && raw.isNotEmpty;
  }

  /// 清除画像
  Future<void> clear() async {
    await init();
    await _box!.delete(_key);
  }
}