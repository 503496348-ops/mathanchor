import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_anchor/config/app_skin_config.dart';

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: <String, String>{});
  });

  tearDown(() {
    dotenv.clear();
  });

  test('AppSkinConfig normalizeChatCompletionUrl appends suffix when needed', () {
    dotenv.testLoad(fileInput: <String, String>{
      'DEEPSEEK_API_URL': 'https://api.deepseek.com/v1',
    });

    expect(
      AppSkinConfig.deepseekBaseUrl,
      'https://api.deepseek.com/v1/chat/completions',
    );
  });

  test('AppSkinConfig deepseekBaseUrl supports legacy DEEPSEEK_BASE_URL', () {
    dotenv.testLoad(fileInput: <String, String>{
      'DEEPSEEK_BASE_URL': 'https://api.deepseek.com/chat/completions',
    });

    expect(
      AppSkinConfig.deepseekBaseUrl,
      'https://api.deepseek.com/chat/completions',
    );
  });

  test('AppSkinConfig service defaults stay available when env missing', () {
    // 不注入任何变量，走内建 fallback。
    expect(AppSkinConfig.authApiBaseUrl.isNotEmpty, true);
    expect(AppSkinConfig.vivoBaseUrl.endsWith('/chat/completions'), true);
  });
}
