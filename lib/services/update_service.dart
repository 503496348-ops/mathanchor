import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:math_anchor/config/app_skin_config.dart';

/// 版本信息模型
class AppVersion {
  final String version;
  final int buildNumber;
  final String apkUrl;
  final String releaseNotes;

  AppVersion({
    required this.version,
    required this.buildNumber,
    required this.apkUrl,
    required this.releaseNotes,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      version: json['version'] as String? ?? '',
      buildNumber: (json['buildNumber'] as num?)?.toInt() ?? 0,
      apkUrl: json['apkUrl'] as String? ?? '',
      releaseNotes: json['releaseNotes'] as String? ?? '',
    );
  }
}

/// 联网自动更新服务。
///
/// 启动时若配置 APP_UPDATE_VERSION_URL，则检查该地址返回的 version.json。
class UpdateService {
  /// 是否正在下载
  static bool _isDownloading = false;

  /// 解析语义版本（支持 1.2.3）。解析失败返回 0。只作版本比较兜底。
  static int _versionCode(String version) {
    final List<String> parts = version.split('.');
    int code = 0;
    for (int i = 0; i < parts.length && i < 3; i++) {
      final int? num = int.tryParse(parts[i].trim());
      if (num == null) {
        continue;
      }
      code = code * 1000 + num;
    }
    return code;
  }

  /// 当前版本号。
  static int get _currentBuildNumber {
    if (AppSkinConfig.updateCurrentBuildNumber > 0) {
      return AppSkinConfig.updateCurrentBuildNumber;
    }
    return _versionCode(AppSkinConfig.updateCurrentVersion);
  }

  /// 检查更新。返回最新版本信息，若已是最新则返回 null。
  static Future<AppVersion?> checkUpdate() async {
    try {
      final String versionUrl = AppSkinConfig.updateVersionUrl;
      if (versionUrl.isEmpty) {
        return null;
      }

      final Uri uri = Uri.parse(versionUrl);
      if (uri.scheme.isEmpty) {
        return null;
      }

      final http.Response response = await http
          .get(uri)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final dynamic jsonBody = jsonDecode(utf8.decode(response.bodyBytes));
      if (jsonBody is! Map<String, dynamic>) {
        return null;
      }
      final AppVersion latest = AppVersion.fromJson(jsonBody);

      if (latest.version.isEmpty && latest.buildNumber <= 0) {
        return null;
      }

      final bool shouldUpdate = latest.buildNumber > _currentBuildNumber &&
          (latest.version.isNotEmpty
              ? _versionCode(latest.version) >= _versionCode(AppSkinConfig.updateCurrentVersion)
              : true);

      return shouldUpdate ? latest : null;
    } catch (_) {
      return null;
    }
  }

  /// Android：下载 APK 到本地并唤起安装器。
  /// Web / 桌面：打开浏览器下载。
  static Future<String?> downloadAndInstall(AppVersion version,
      {void Function(double progress)? onProgress}) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      // Web/桌面端 → 浏览器打开下载
      final url = Uri.parse(version.apkUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      return null;
    }

    if (_isDownloading) return null;
    _isDownloading = true;

    try {
      final dir = await getTemporaryDirectory();
      final safeFileName =
          version.version.isNotEmpty ? '${version.version}.apk' : 'app-release.apk';
      final file = File('${dir.path}/$safeFileName');

      final response = await http.get(Uri.parse(version.apkUrl));
      if (response.statusCode != 200) return '下载失败: HTTP ${response.statusCode}';

      await file.writeAsBytes(response.bodyBytes);

      // 唤起系统安装器
      final result = await OpenFile.open(file.path,
          type: 'application/vnd.android.package-archive');
      return result.message;
    } catch (e) {
      return '下载失败: $e';
    } finally {
      _isDownloading = false;
    }
  }
}
