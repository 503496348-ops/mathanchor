# 🎨 MathMate GitHub 仓库优化指南

本指南帮助你优化 MathMate 在 GitHub 上的展示效果，包括仓库简介、Description、Topics 等。

---

## 📝 仓库简介（Description）

### 推荐简介

**中文版**：
```
AI驱动的智能数学学习应用 | 拍照搜题 + 几何可视化 + AI对话助手 | Flutter + DeepSeek | MIT 协议
```

**英文版**：
```
AI-Powered Math Learning App | Photo Solver + Geometry Visualization + AI Chat | Flutter + DeepSeek | MIT License
```

---

## 🏷️ 仓库 Topics（标签）

在 GitHub 仓库设置 → Topics 中添加以下标签：

```
flutter, dart, mathematics, education, ai, deepseek, ocr, geometry-visualization, mobile-app, educational-app, math-solver, geogebra, chinese-education, flutter-web, cross-platform
```

### 标签分类

| 分类 | 标签 |
|------|------|
| **技术** | flutter, dart, ai, deepseek, ocr |
| **领域** | mathematics, education, chinese-education |
| **功能** | math-solver, geometry-visualization, geogebra |
| **平台** | mobile-app, android, ios, flutter-web, cross-platform |

---

## 📊 仓库信息设置

### 关于区（About）

在仓库主页的 "About" 区域设置：

1. **Website**: `https://mathmate.top`
2. **Topics**: 添加上述标签

---

## 🎨 社交媒体预览（Open Graph）

GitHub 会自动使用以下内容生成社交预览：

### 本地预览工具

使用以下工具预览你的仓库在社交媒体上的显示效果：

- **OpenGraph Preview**: https://www.opengraph.xyz/
- **Twitter Card Validator**: https://cards-dev.twitter.com/validator
- **LinkedIn Post Inspector**: https://www.linkedin.com/post-inspector/

### 测试链接

```
https://www.opengraph.xyz/https://github.com/mzk-C4/mathmate
```

---

## 🖼️ 仓库横幅（Social Image）

### 创建横幅图片

推荐尺寸：**1280 × 640 像素**

包含元素：
- MathMate Logo
- 应用截图
- 核心功能文字
- GitHub 信息

### Figma 模板

使用 Figma Canva 创建横幅：
1. 打开 [Figma](https://www.figma.com/)
2. 创建 1280×640 画布
3. 添加 Logo、截图、文字
4. 导出为 PNG/JPG
5. 上传到仓库：`images/banner.png`

### 在仓库中设置

GitHub 会自动检测仓库根目录下的以下文件作为社交图片：
- `social-preview.png`
- `images/banner.png`
- `assets/banner.png`

---

## 📱 仓库截图区域

### 创建 `.github` 目录

```bash
mkdir -p .github/images
```

### 上传截图到 GitHub

使用 GitHub 的 Asset 功能：
1. 在仓库中创建 Issue
2. 拖拽图片到评论区
3. 右键复制图片链接
4. 更新 README.md

### 推荐的截图尺寸

| 类型 | 尺寸 |
|------|------|
| 主屏幕截图 | 1080 × 1920 (9:16) |
| 功能演示 | 1200 × 800 (3:2) |
| 平板/桌面 | 1920 × 1080 (16:9) |

---

## 🔗 外部链接配置

### README 中的链接

确保以下链接正确：

```markdown
- 官网: https://mathmate.top
- 技术文档: https://mathmate.top/tech.html
- 演示视频: https://www.bilibili.com/video/BV1EfLJ6bEnw/
- 在线体验: https://mathmate.top/app
```

### Footer 链接

在 README.md 底部添加：

```html
<div align="center">
  <a href="https://mathmate.top">官网</a> •
  <a href="https://mathmate.top/tech.html">技术文档</a> •
  <a href="https://www.bilibili.com/video/BV1EfLJ6bEnw/">演示视频</a> •
  <a href="https://github.com/mzk-C4/mathmate/issues">问题反馈</a>
</div>
```

---

## 📌 仓库 Pin（置顶）

### 推荐置顶内容

在仓库主页置顶以下 Issue/Discussion：

1. **产品介绍**（Issue）
2. **功能路线图**（Issue）
3. **问题反馈收集**（Discussion）
4. **更新日志**（Issue）

---

## 🏢 仓库组织设置

### 创建 Organization

创建 `mathmate-app` Organization：
- 更专业的展示
- 多人协作管理
- 品牌化展示

### 仓库转移

```bash
# 在本地仓库执行
git remote set-url origin git@github.com:mathmate-app/mathmate.git
git push -u origin main
```

---

## 📊 Release 管理

### 创建标准 Release

每个版本应包含：

1. **Tag**: `v2.3.2`
2. **Title**: `MathMate v2.3.2 - 功能描述`
3. **Description**: 更新日志
4. **Assets**: APK 文件、截图

### Release 模板

```markdown
## 🎉 MathMate v2.3.2

### ✨ 新功能
- 功能 1
- 功能 2

### 🐛 Bug 修复
- 修复问题 1
- 修复问题 2

### 📦 下载
- [Android APK](attachments/apk/mathmate-v2.3.2.apk)

### 📸 截图
![截图1](attachments/screenshots/screenshot-1.jpg)

---
**完整更新日志**: [CHANGELOG.md](https://github.com/mzk-C4/mathmate/blob/main/CHANGELOG.md)
```

---

## 🎯 仓库 SEO 优化

### GitHub 搜索优化

1. **关键词丰富**：在 README 中包含技术栈、功能关键词
2. **结构化内容**：使用标题、列表、表格
3. **链接质量**：链接到官网、文档、演示视频

### 社交媒体分享

使用以下格式分享到社交媒体：

**Twitter:**
```
🧮 MathMate - AI驱动的智能数学学习应用

拍照搜题 + 几何可视化 + AI对话助手

#Flutter #AI #MathEducation

https://github.com/mzk-C4/mathmate
```

**LinkedIn:**
```
很高兴分享我们的开源项目 MathMate！

这是一款基于 Flutter + AI 的智能数学学习应用，提供拍照搜题、几何可视化、AI 对话等功能。

#opensource #flutter #education
```

---

## 📈 推广策略

### HackerNews

标题：`Show HN: MathMate - AI-Powered Math Learning App with Interactive Geometry`

### Reddit（r/FlutterDev, r/learnprogramming）

标题：`MathMate: Open-source AI math learning app built with Flutter`

### Product Hunt

标题：`MathMate - AI-powered math learning with interactive geometry`

---

## 🏆 成就徽章

在 README.md 中添加徽章：

```markdown
![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Stars](https://img.shields.io/github/stars/mzk-C4/mathmate)
![License](https://img.shields.io/badge/License-MIT-green)
![Issues](https://img.shields.io/github/issues/mzk-C4/mathmate)
```

---

## ✅ 优化检查清单

- [ ] 仓库 Description 已优化
- [ ] Topics 标签已添加
- [ ] Website 链接已设置
- [ ] README.md 包含视频和图片
- [ ] 创建了第一个 Release
- [ ] 添加了社交预览横幅
- [ ] 设置了 GitHub Actions
- [ ] 创建了 Issue 模板
- [ ] 创建了 PR 模板
- [ ] 添加了 LICENSE 文件

---

完成以上优化后，你的 GitHub 仓库将更加专业和吸引人！
