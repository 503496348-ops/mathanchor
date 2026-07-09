# 📝 版本更新日志
## [version-2.3.4] - 2026-07-09

### ✨ 新增功能
- 📊 新增能力雷达图模块（`lib/profile_radar_chart.dart`）
  - 学习能力多维度可视化展示
  - 雷达图动画触发器，交互体验升级
- 🎯 新增能力自评页面（`lib/pages/ability_assessment_page.dart`）
  - 首次使用引导自评
  - 已有用户可重新评测
- 📝 新增练习页面（`lib/pages/practice_page.dart`）
- 🔢 新增能力评分服务（`lib/services/ability_score_service.dart`）
- 📚 新增题库问题模型与服务（`lib/models/library_question.dart`、`lib/services/library_question_service.dart`）
- 📈 新增用户雷达画像模型（`lib/models/user_radar_profile.dart`）
- 🔐 新增 GitHub SSH 密钥配置指南文档

### 🐛 问题修复
- 🔧 修复 `main.dart` 与 `profile_page.dart` 的分支合并冲突
  - 合并 `feature/ability-radar-chart` 分支功能到主分支
  - 保留学习画像入口 + 题库入口 + 能力雷达图全链路
- 📷 修复 README 中 Star History 图片无法显示问题（改用本地 SVG）
- 📺 修复 README 视频封面渲染问题（替换为渐变卡片样式）

### 🎨 UI/UX 改进
- 🏠 主页新增学习画像入口卡片（6 维特征展示）
- 🏠 主页新增题库入口卡片（云端共享题库）
- 📱 底部导航新增练习 Tab
- 👤 个人页面集成能力雷达图
- 📐 年级选择页面优化
