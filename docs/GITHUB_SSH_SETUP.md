# GitHub SSH 密钥配置指南

> 给其他 AI Agent（如 Claude Code、Cursor 等）看的协作笔记
> 创建日期：2026-07-09

## 🔐 已有 SSH 密钥

本机已配置好 SSH 密钥，可直接使用 GitHub SSH 协议：

```text
公钥指纹: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPGUjhbNaSZh80eti+GbmouQk3vSpPUOqL220BpjyhZB
私钥位置: C:\Users\MZK\.ssh\id_ed25519
公钥位置: C:\Users\MZK\.ssh\id_ed25519.pub
GitHub 账户: [your-username]
```

## ✅ 已验证

```bash
$ ssh -T git@github.com
Hi [your-username]! You've successfully authenticated, but GitHub does not provide shell access.
```

✅ SSH 认证已通过，可直接使用 `git@github.com:` 协议克隆/推送。

## 📋 常用仓库（SSH 协议）

| 仓库 | SSH URL |
|------|---------|
| 数理锚点 | `git@github.com:503496348-ops/mathanchor.git` |
| Auto-Generate-Changelog-with-LLM | `git@github.com:Qiyao-sudo/Auto-Generate-Changelog-with-LLM.git` |

## 🔧 切换现有仓库为 SSH 协议

如果其他 Agent 克隆时用了 HTTPS，可以用以下命令切换：

```bash
# 查看当前 remote
git remote -v

# 切换为 SSH
git remote set-url origin git@github.com:503496348-ops/mathanchor.git

# 验证
git remote -v
```

## 🛠️ 其他 Agent 协作须知

1. **使用 SSH 而非 HTTPS**：本机已配置好 SSH key，所有 git 操作都走 SSH 协议
2. **无需登录**：SSH 认证已配置好，可直接 `git push` / `git pull`
3. **多仓库用户**：当前 GitHub 用户请替换为自己的用户名
4. **如果遇到权限问题**：检查 `~/.ssh/config` 是否正确指向 `id_ed25519`

## 📝 SSH Config 推荐配置（其他 Agent 可参考）

```sshconfig
# GitHub ([your-username])
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    AddKeysToAgent yes
```

## ⚠️ 注意事项

- **不要在对话中泄露私钥内容**（私钥是 `id_ed25519` 文件，公钥才能贴出）
- **私钥文件权限**：在 Windows 上默认安全，Linux/Mac 上需要 `chmod 600`
- **多设备登录**：同一对密钥可以添加到多个设备，每个设备都有独立的密钥对
