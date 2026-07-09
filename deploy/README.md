# 数理锚点 Web 部署指南

## 一、构建 Web 前端

在本机（Windows）执行：

```cmd
cd D:\projects\数理锚点

:: 备份原始 .env
copy .env .env.backup

:: 替换为 Web 版本的 .env（API URL 指向服务器代理）
copy deploy\.env.web .env

:: 构建
flutter build web --release

:: 恢复原始 .env
copy .env.backup .env
del .env.backup
```

产物在 `build/web/`。

---

## 二、上传到服务器

```bash
# 上传 Web 前端
scp -r build/web/* user@your-domain.com:/var/www/mathanchor/

# 上传代理服务
scp deploy/proxy_server.js user@your-domain.com:/opt/mathanchor/proxy_server.js
scp deploy/package.json user@your-domain.com:/opt/mathanchor/package.json
```

---

## 三、服务器配置（Ubuntu）

SSH 登录服务器后执行：

### 1. 安装 Node.js

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

### 2. 配置 API Key

```bash
sudo mkdir -p /opt/mathanchor
cd /opt/mathanchor

# 编辑 .env.server，填入你的真实 API Key
sudo nano /opt/mathanchor/.env.server
```

### 3. 启动 API 代理（PM2 守护）

```bash
sudo npm install -g pm2
cd /opt/mathanchor
pm2 start proxy_server.js --name mathanchor-proxy
pm2 save
pm2 startup   # 设置开机自启
```

### 4. 部署 Web 前端

```bash
sudo mkdir -p /var/www/mathanchor
# 上传 build/web/ 内容到此目录
```

### 5. 配置 Nginx

```bash
sudo apt install -y nginx

# 复制 Nginx 配置
sudo cp deploy/mathanchor.nginx /etc/nginx/sites-available/your-domain.com
sudo ln -s /etc/nginx/sites-available/your-domain.com /etc/nginx/sites-enabled/
sudo nginx -t   # 检查配置
sudo systemctl reload nginx
```

### 6. 配置 HTTPS（SSL）

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

---

## 四、验证

```bash
# 检查代理是否运行
curl http://127.0.0.1:3001/

# 测试 API 代理（应返回 JSON）
curl -X POST http://127.0.0.1:3001/api/deepseek \
  -H "Content-Type: application/json" \
  -d '{"model":"deepseek-chat","messages":[{"role":"user","content":"hello"}]}'

# 检查 Nginx
curl -I https://your-domain.com
```

---

## 五、更新流程

后续更新只需重新构建 Web 并上传：

```bash
# 本机
flutter build web --release   # 记得先用 deploy/.env.web 替换 .env
scp -r build/web/* user@your-domain.com:/var/www/mathanchor/
```

代理服务无需改动。
