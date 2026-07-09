---
name: mathanchor-brand-rebrand
category: software-development
version: v1.0
status: active
description: 数理锚点 到其他品牌的最小入侵改造（配置化皮肤化）技能记录
---

# 数理锚点 换皮改造技能（`/tmp/mathanchor`）

## 触发条件
- 需要将 数理锚点 项目迁移到其他品牌名/域名/服务端点。
- 希望减少硬编码并用环境变量集中管理。
- 需要增强 AI 服务可配置性并提高错误可观测性。

## 目标
- **不改业务流程**，只做配置化与兼容性改造。
- 将品牌词、基础 URL、AI 服务端点集中到 `AppSkinConfig`。
- 强化关键服务的错误处理和空响应防御。

## 执行步骤

### 1. 建立统一皮肤配置
- 文件：`lib/config/app_skin_config.dart`
- 字段：
  - `APP_NAME`
  - `APP_VERSION`
  - `AUTH_API_BASE_URL`
  - `LIBRARY_API_BASE_URL`
  - `GEOGEBRA_CHAT_URL`
  - `APP_EXPORT_FILENAME`
  - `DEEPSEEK_API_URL`
  - `DEEPSEEK_MODEL_ID`
  - `VOLC_BASE_URL`
  - `VOLC_MODEL_ID`
  - `VIVO_BASE_URL`
  - `VIVO_MODEL_ID`
  - `APP_UPDATE_VERSION_URL`
  - `APP_BUILD_NUMBER`
  - `APP_FEATURE_VIDEO_RECOMMENDATION`
  - `APP_FEATURE_AUTO_UPDATE_CHECK`

### 2. 迁移服务端点到配置
按文件逐一替换：
- `lib/services/auth_service.dart`：`AUTH_API_BASE_URL`
- `lib/exam/services/question_api.dart`：`LIBRARY_API_BASE_URL`
- `lib/pages/geogebra_chat_stub.dart`：`GEOGEBRA_CHAT_URL`
- `lib/services/update_service.dart`：`APP_UPDATE_VERSION_URL`（以及版本号兜底）
- `lib/services/deepseek_service.dart`：`DEEPSEEK_API_URL`
- `lib/services/volc_ai_client_service.dart`：`VOLC_BASE_URL`
- `lib/services/vivo_chat_service.dart`：`VIVO_BASE_URL`
- `lib/services/formula_analysis_service.dart`：`VOLC_BASE_URL`/模型兜底
- `lib/services/handwriting_ocr_service.dart`：`VOLC_BASE_URL`/模型兜底
- `lib/services/chat_stream_service.dart`：`VIVO_BASE_URL`/模型兜底
- `lib/services/video_recommendation_service.dart`：`VIVO_BASE_URL`/模型兜底
- `lib/services/geogebra_agent_service.dart`：`DEEPSEEK_API_URL`（默认）/`DEEPSEEK_BASE_URL`（兼容）
- `lib/fusion/ai_drawing/services/ai_drawing_service.dart`：`DEEPSEEK_API_URL`（默认）/`DEEPSEEK_BASE_URL`（兼容）
- `lib/data/history_repository.dart`：`VIVO_BASE_URL`/模型兜底

### 3. 统一品牌文案（UI）
- `lib/pages/login_page.dart`
- `lib/about_mathanchor_page.dart`
- `lib/pages/beautiful_result_page.dart`
- `lib/services/katex_pdf_service.dart`
- `lib/models/user_profile.dart`
- `lib/edit_profile_page.dart`
- `lib/pages/flash_text_demo_page.dart`

### 4. 更新配置模板
- 更新 `.env.example`，补齐新增皮肤化变量及 `DEEPSEEK_MODEL_ID`。
- `DEEPSEEK_API_URL` 用基地址（如 `https://api.deepseek.com`）或完整路径均兼容。

### 5. 验证与回归
- 进行静态检查：确认无遗漏硬编码字符串（`数理锚点` / `your-domain.com` / 旧 endpoint）
- 检查服务错误处理：非 JSON、非 200、空内容均抛异常并可定位。
- 保留可选更新逻辑：`update_service.dart` 支持无更新配置时静默返回。

## 风险与避坑
- 不要把配置回退到硬编码旧地址。
- `DEEPSEEK_API_URL`、`VOLC_BASE_URL`、`VIVO_BASE_URL` 允许传基地址或完整 endpoint；服务侧要统一归一化。
- `update_service.dart` 非活跃页面入口时，保留安全返回，避免在未配置场景抛错。

## 运行与交付验收清单
1. 文件级改造覆盖：`lib/config/app_skin_config.dart` + 上述服务文件。
2. `AppSkinConfig` 在关键 UI/导出文案里生效。
3. 通过 `git diff` 复核：确认没有新的硬编码域名/品牌残留。
4. 补充测试（按团队能力）覆盖配置兜底与 URL 归一化行为。

## 变更记录
- 2026-07-09：完成第一阶段换皮改造（硬编码基础端点、品牌文本迁移）
- 2026-07-09：补充 `update_service.dart`/`deepseek_service.dart`/`volc_ai_client_service.dart`/`vivo_chat_service.dart` 配置化与错误处理
- 2026-07-09：补齐更多服务端点到 `AppSkinConfig`（公式解析、OCR、视频推荐、GeoGebra Agent、AI 绘图、历史摘要）
