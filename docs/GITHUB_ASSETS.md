# 数理锚点 GitHub 资源配置指南

本指南说明如何在 GitHub 上正确配置 数理锚点 项目的图片和视频资源。

## 🖼️ 图片资源配置

### 方式一：使用 GitHub Releases Assets（推荐）

将应用截图上传到 GitHub Releases，然后在 README 中引用：

```bash
# 1. 创建 GitHub Release
gh release create v2.3.2 \
  --title "数理锚点 v2.3.2" \
  --notes "Release notes here"

# 2. 上传截图
gh release upload v2.3.2 \
  assets/screenshot-1.jpg \
  assets/screenshot-2.jpg \
  assets/screenshot-viz.png
```

然后在 README 中引用：

```markdown
![拍照搜题](https://github.com/mzk-C4/mathanchor/releases/download/v2.3.2/screenshot-1.jpg)
```

### 方式二：使用 GitHub Issue Comments

将图片作为 Issue 评论上传，然后右键复制图片链接：

```markdown
![截图描述](https://user-images.githubusercontent.com/your-user-id/12345678/screenshot-1.jpg)
```

### 方式三：创建专用截图目录

```bash
# 在项目根目录创建
mkdir -p docs/screenshots

# 复制截图
cp /path/to/screenshots/* docs/screenshots/

# 提交到 Git
git add docs/screenshots/
git commit -m "Add screenshots"
git push
```

然后在 README 中引用：

```markdown
![首页](docs/screenshots/home.jpg)
```

## 🎬 视频资源配置

### Bilibili 视频

在 README 中使用 Markdown 图片链接嵌入视频缩略图：

```markdown
[![视频标题](视频封面图片URL)](https://www.bilibili.com/video/BV1EfLJ6bEnw/)
```

完整示例：

```markdown
[![数理锚点 产品演示](images/video-cover.jpg)](https://www.bilibili.com/video/BV1EfLJ6bEnw/)
```

### YouTube 视频

```markdown
[![视频标题](缩略图URL)](https://www.youtube.com/watch?v=video_id)
```

## 📋 推荐的截图清单

### 必备截图

1. **应用启动/首页** (`home.png`)
2. **拍照搜题 - 拍照界面** (`search-camera.jpg`)
3. **拍照搜题 - 识别结果** (`search-result.jpg`)
4. **拍照搜题 - AI 解题** (`search-solve.jpg`)
5. **几何可视化 - 静态图形** (`viz-static.jpg`)
6. **几何可视化 - 拖拽交互** (`viz-interactive.jpg` 或 `.png`)
7. **AI 对话助手** (`chat.jpg`)
8. **手写笔记** (`notes.jpg`)
9. **数学工具箱** (`geogebra.jpg`)
10. **产品海报/横幅** (`banner.png`)

### 可选截图

- 视频推荐页面 (`video.jpg`)
- PDF 查看器 (`pdf.jpg`)
- 个人中心 (`profile.jpg`)
- 设置页面 (`settings.jpg`)
- 主题切换 (`theme.jpg`)

## 🎨 截图命名规范

建议使用以下命名规范：

```
screenshot-模块-功能.扩展名
```

示例：

```
screenshot-search-camera.jpg        # 拍照搜题 - 拍照
screenshot-search-result.jpg       # 拍照搜题 - 识别结果
screenshot-viz-interactive.png     # 几何可视化 - 交互
screenshot-chat-conversation.jpg   # AI 对话 - 对话界面
screenshot-notes-handwriting.jpg   # 笔记 - 手写
```

## 📐 图片尺寸建议

| 用途 | 建议尺寸 | 格式 |
|------|---------|------|
| README 截图 | 1080×1920 (9:16) 或 1200×800 (3:2) | JPG/PNG |
| 功能展示 | 1200×800 (3:2) | PNG (透明背景) |
| 产品横幅 | 1200×300 (4:1) | PNG |
| 视频封面 | 1280×720 (16:9) | JPG |
| 应用图标 | 512×512 (1:1) | PNG |

## 🔄 快速替换 README 中的图片

README.md 中使用了占位符 URL：

```markdown
![截图](https://github.com/mzk-C4/mathanchor/assets/your-username/screenshot-1.jpg)
```

将 `your-username` 替换为你的 GitHub 用户名，`screenshot-1.jpg` 替换为实际图片文件名。

## 🚀 自动化截图脚本（可选）

创建 `scripts/capture.sh` 自动生成截图：

```bash
#!/bin/bash
# Flutter Screenshot Automation

flutter drive --driver=test_driver/app.dart \
  --target=screenshots/ \
  --screenshot-screenshots/home.png
```

## 📝 README 中的图片展示格式

### 单张图片

```markdown
![功能描述](图片URL)
```

### 图片表格

```markdown
| 功能 A | 功能 B | 功能 C |
|:-------:|:-------:|:-------:|
| ![A](url-a) | ![B](url-b) | ![C](url-c) |
```

### 图片网格（使用 HTML）

```html
<table>
  <tr>
    <td><img src="url-1" width="300"></td>
    <td><img src="url-2" width="300"></td>
  </tr>
</table>
```

## 🌐 外部图片托管

如果不想将图片存放在 GitHub，可以使用：

- **Imgur**: https://imgur.com (免费，无需注册即可上传)
- **Cloudinary**: https://cloudinary.com (免费额度)
- **阿里云 OSS**: 配合国内访问

## ✅ 完成配置后检查清单

- [ ] 所有图片链接可正常访问
- [ ] 视频封面点击可跳转到 Bilibili
- [ ] 图片尺寸在不同设备上显示正常
- [ ] 截图清晰度足够（建议 1080p 及以上）
- [ ] 移动端和桌面端都能正常显示

---

配置完成后，提交到 GitHub：

```bash
git add README.md docs/screenshots/
git commit -m "docs: 添加产品截图和视频"
git push origin main
```
