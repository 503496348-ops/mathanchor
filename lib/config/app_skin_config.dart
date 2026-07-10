import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App skin/runtime configuration.
///
/// 约定：
/// - 运行时配置从 .env 读取；未配置时回退到安全默认值。
/// - 仅承担“皮肤化”参数，不承载业务流程逻辑。
/// - 任何字段变化都应通过配置文件完成，减少硬编码。
class AppSkinConfig {
  static const String _fallbackAppName = '数理锚点';
  static const String _fallbackVersion = '1.0.0';
  static const String _fallbackAuthApiBase = 'https://your-domain.com/api/auth';
  static const String _fallbackLibraryApiBase = 'https://your-domain.com/api/library';
  static const String _fallbackGeogebraChatUrl = '';
  static const String _fallbackExportFilename = 'mathanchor_export';
  static const String _fallbackDeepseekBaseUrl = 'https://api.deepseek.com/v1';
  static const String _fallbackVolcBaseUrl = 'https://ark.cn-beijing.volces.com/api/v3/chat/completions';
  static const String _fallbackVivoBaseUrl =
      'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions';

  static String _envValue(String key, String fallback) {
    final String? raw = dotenv.env[key];
    final String trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return fallback;
    return trimmed;
  }

  static bool _envBool(String key, bool fallback) {
    final String? raw = dotenv.env[key]?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return fallback;
    return raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on';
  }

  static String _stripTrailingSlash(String url) {
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }

  static String normalizeChatCompletionUrl(String baseUrl, {String? suffix}) {
    final String cleaned = _stripTrailingSlash(baseUrl.trim());
    if (cleaned.isEmpty) return cleaned;

    if (cleaned.endsWith('/chat/completions')) return cleaned;
    if (cleaned.endsWith('/v1')) {
      return '$cleaned/chat/completions';
    }

    if (cleaned.endsWith('/api/v3')) {
      return '$cleaned/chat/completions';
    }

    final String path = Uri.parse(cleaned).path.toLowerCase();
    if (path == '/v1') {
      return '$cleaned/chat/completions';
    }
    if (path == '/api/v3') {
      return '$cleaned/chat/completions';
    }

    final String customSuffix = (suffix ?? '/chat/completions');
    if (cleaned.endsWith(customSuffix)) return cleaned;

    if (!cleaned.endsWith('/')) {
      return '$cleaned$customSuffix';
    }
    return '${cleaned.substring(0, cleaned.length - 1)}$customSuffix';
  }

  static String get appName => _envValue('APP_NAME', _fallbackAppName);

  static String get appVersion => _envValue('APP_VERSION', _fallbackVersion);

  static String get authApiBaseUrl => _stripTrailingSlash(_envValue('AUTH_API_BASE_URL', _fallbackAuthApiBase));

  static String get libraryApiBaseUrl => _stripTrailingSlash(_envValue('LIBRARY_API_BASE_URL', _fallbackLibraryApiBase));

  static String get geogebraChatUrl => _envValue('GEOGEBRA_CHAT_URL', _fallbackGeogebraChatUrl);

  static String get exportFileBaseName => _envValue('APP_EXPORT_FILENAME', _fallbackExportFilename);

  static String get deepseekBaseUrl =>
      normalizeChatCompletionUrl(_envValue(
        'DEEPSEEK_API_URL',
        _envValue('DEEPSEEK_BASE_URL', _fallbackDeepseekBaseUrl),
      ));

  static String get deepseekModelId =>
      _envValue('DEEPSEEK_MODEL_ID', 'deepseek-chat');

  static String get volcBaseUrl =>
      normalizeChatCompletionUrl(_envValue('VOLC_BASE_URL', _fallbackVolcBaseUrl), suffix: '/chat/completions');

  static String get volcDefaultModelId =>
      _envValue('VOLC_MODEL_ID', 'ep-xxxxxxxxxxxxxxxxxxxx');

  static String get vivoBaseUrl =>
      normalizeChatCompletionUrl(_envValue('VIVO_BASE_URL', _fallbackVivoBaseUrl));

  static String get vivoModelId =>
      _envValue('VIVO_MODEL_ID', 'qwen-plus');

  static bool get featureVideoRecommendation => _envBool('APP_FEATURE_VIDEO_RECOMMENDATION', false);

  static bool get featureAutoUpdateCheck => _envBool('APP_FEATURE_AUTO_UPDATE_CHECK', false);

  static String get updateVersionUrl => _envValue('APP_UPDATE_VERSION_URL', '');

  static String get updateCurrentVersion => _envValue('APP_VERSION', _fallbackVersion);

  static int get updateCurrentBuildNumber =>
      int.tryParse(_envValue('APP_BUILD_NUMBER', '0')) ?? 0;
}
