import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:math_anchor/library/prompts/classification_prompt.dart';
import 'package:math_anchor/services/app_logger.dart';
import 'package:math_anchor/services/volc_ai_client_service.dart';

/// 板书 / 图片 内容提取 —— 走火山 Vision API
///
/// 复用现有 VOLC_OCR_MODEL_ID 配置与 VolcAiClientService.callVisionPrompt，
/// 但用「资料内容转录」Prompt（而非数学公式 OCR），完整提取板书/课件全部文字。
class ImageOcrParser {
  static const String _ocrModelEnv = 'VOLC_OCR_MODEL_ID';

  final VolcAiClientService _client;

  ImageOcrParser({VolcAiClientService? client})
      : _client = client ?? VolcAiClientService();

  /// 从图片路径提取文字内容
  Future<String> extractFromPath(String path) async {
    final File file = File(path);
    if (!await file.exists()) {
      AppLogger.instance.warn('[ImgOCR] 文件不存在: $path');
      return '';
    }
    final XFile xfile = XFile(path);
    final String raw = await _client.callVisionPrompt(
      imageFile: xfile,
      prompt: ClassificationPrompt.imageContentPrompt,
      modelEnv: _ocrModelEnv,
    );
    return raw.trim();
  }
}
