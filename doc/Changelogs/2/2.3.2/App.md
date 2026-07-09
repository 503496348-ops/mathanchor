# 📝 版本更新日志
## [version-2.3.2] - 2026-07-07

### ✨ 新增功能
- 🔧 新增学习资料库模块 (`lib/library/`)
  - 新增学习资料模型 (`lib/library/models/study_material.dart`)
  - 新增资料库页面 (`lib/library/presentation/library_page.dart`)
  - 新增资料上传表单 (`lib/library/presentation/material_upload_sheet.dart`)
  - 新增资料分类提示词 (`lib/library/prompts/classification_prompt.dart`)
  - 新增资料分类服务 (`lib/library/services/classification_service.dart`)
  - 新增资料导入服务 (`lib/library/services/ingestion_service.dart`)
  - 新增资料仓库 (`lib/library/services/material_repository.dart`)
  - 新增图片 OCR 解析器 (`lib/library/services/parsing/image_ocr_parser.dart`)
- 🔧 新增响应式布局模块 (`lib/responsive/`)
  - 新增响应式断点定义 (`lib/responsive/breakpoints.dart`)
  - 新增响应式壳组件 (`lib/responsive/responsive_shell.dart`)
- 📄 新增资料库模块设计文档 (`docs/library_module_design.md`)

### 🚀 功能优化
- 🔧 优化美丽结果页面 (`lib/beautiful_result_page.dart`)
- 🔧 优化历史记录仓库 (`lib/data/history_repository.dart`)
- 🔧 优化历史记录列表页面 (`lib/history_list_page.dart`)
- 🔧 优化主页面 (`lib/main.dart`)
- 🔧 优化聊天首页 (`lib/pages/chat_home_page.dart`)
- 🔧 优化识别器页面 (`lib/recognizer_page.dart`)
- 🔧 优化增强裁剪页面 (`lib/scanner/enhanced_crop_page.dart`)
- 🔧 优化扫描器服务 (`lib/services/scanner_service.dart`)

### 📚 文档更新
- 📝 新增资料库模块设计文档，包含架构设计和使用说明

### 🎨 UI/UX 改进
- 🔧 响应式布局支持，适配不同屏幕尺寸
- 🔧 资料库页面交互优化
