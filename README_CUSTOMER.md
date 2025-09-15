# 网络设备批量配置管理系统 - 客户部署说明

本文件用于客户一键部署与授权。按“客户侧步骤”操作即可完成部署，无需手工执行 SQL。

## 1. 环境要求
- Rocky Linux 9（或任意 64 位 Linux，已安装 Docker 与 docker compose）
- 对外开放 8000 端口（Web 访问）

## 2. 授权与交付
授权采用时间控制机制，不绑定硬件。流程如下：

### 2.1 供应商侧：生成许可证文件
- 供应商会根据客户需求生成指定有效期的许可证文件
- 许可证文件包含过期时间信息，到期后服务会自动停止

### 2.2 客户侧：接收并部署许可证文件
- 供应商会提供 `license/pyarmor.rkey` 文件
- 请将许可证文件放置到本目录 `license/pyarmor.rkey`

目录关键结构（示例）：
```
customer_deployment/
├── docker-compose.yml
├── initdb/
│   └── 00-init.sql        # 首次启动自动执行，创建表并写入 admin/admin
├── license/
│   └── pyarmor.rkey       # 授权运行密钥（供应商生成）
└── README_CUSTOMER.md
```

## 3. 一键启动
在 `customer_deployment` 目录运行：
```bash
docker compose up -d
docker compose ps
```
说明：
- 首次启动会自动创建数据库并初始化（由 `./initdb/00-init.sql` 完成）。
- 后端镜像使用本地构建的 `qytang-config-system-backend:latest`，包含PyArmor加密的源码。
- 所有依赖镜像均使用固定版本标签。

## 4. 访问与默认账户
- Web: `http://<服务器IP>:8000`
- 默认管理员：`admin`
- 默认密码：`admin`

首次登录后请立即在系统中修改管理员密码。

## 5. 常见问题
### 5.1 首次登录失败（admin/admin 不生效）
可能之前已创建过数据库数据卷，未触发自动初始化。可按需重置（风险：清空数据库）：
```bash
docker compose down
docker volume rm customer_deployment_postgres_data || true
docker compose up -d
```

### 5.2 授权相关
- 确认 `license/pyarmor.rkey` 存在；该文件会被自动挂载为容器内 `/app/license/pyarmor.rkey`。
- 检查许可证状态：
```bash
curl http://localhost:8000/api/system/license
```
- 更新授权后重启相关服务：
```bash
docker compose restart backend celery_worker backup_scheduler
```
- 查看许可证检查日志：
```bash
docker compose logs backend | grep LICENSE
```

### 5.3 服务状态与日志
```bash
docker compose ps
docker compose logs -f backend
```

## 6. 升级后端
供应商发布新版本后，客户需要：
1. 获取新的部署包
2. 停止现有服务：`docker compose down`
3. 替换部署文件
4. 重新启动：`docker compose up -d`

## 7. 安全性说明（源码保护）
后端镜像中仅包含经 PyArmor 保护后的产物，不包含明文源码。
可选自检命令：
```bash
# 查看产物结构
docker compose exec backend sh -lc 'cd /app && ls -lah'

# 抽样查看入口与模块（应为 PyArmor 引导/不可读内容，不是业务源码）
docker compose exec backend sh -lc 'head -n 60 /app/main.py | cat'
docker compose exec backend sh -lc 'for f in $(find /app/app -maxdepth 1 -type f -name "*.py" | head -n 3); do echo "== $f =="; head -n 30 "$f" | cat; done'
```

---
如需技术支持，请将 `docker compose ps` 与相关 `docker compose logs` 片段发送给供应商。