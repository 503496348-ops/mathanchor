# 📝 版本更新日志
## [version-2.3.3] - 2026-07-08

### ✨ 新增功能
- 📚 新增题库系统模块 (`lib/exam/`)
  - 新增题目模型 (`lib/exam/models/question.dart`)
  - 新增题库页面 (`lib/exam/pages/question_bank_page.dart`)
  - 新增题目 API 服务 (`lib/exam/services/question_api.dart`)
- 📦 新增题库数据构建脚本 (`scripts/question_pipeline/`)
- 🚀 新增资料库后端服务 (`deploy/library_server.js`)
- 📋 新增部署脚本 (`deploy/deploy_library.sh`)
- 📄 新增设计文档（考试系统规划/服务器交接/资料库API）

### 🐛 问题修复
- 📷 修复 README 中无法显示的白色 banner 图
- 📷 修复几何可视化部分错误的产品介绍截图
- 📺 替换视频封面为渐变卡片样式，避免图片无法加载

### 🎨 UI/UX 改进
- 🔧 资料库页面大幅重构优化
- 🔧 响应式布局优化
- 🔧 主页导航结构调整
- 🔧 年级选择页、笔记页、个人资料页微调