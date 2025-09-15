# 客户部署指南

## 🚀 快速部署

### 1. 获取许可证文件
- 联系供应商获取 `pyarmor.rkey` 许可证文件
- 将许可证文件放入 `license/` 目录

### 2. 启动服务
```bash
# 方法一：使用启动脚本（推荐）
./start.sh

# 方法二：手动启动
docker compose up -d
```

### 3. 访问系统
- **Web地址**: http://服务器IP:8000
- **默认账户**: admin/admin
- **首次登录后请立即修改密码**

## 📋 目录结构

```
customer_deployment/
├── docker-compose.yml          # Docker编排文件
├── initdb/
│   └── 00-init.sql            # 数据库初始化脚本
├── license/
│   └── pyarmor.rkey           # 许可证文件（客户提供）
├── start.sh                   # 启动脚本
├── stop.sh                    # 停止脚本
├── status.sh                  # 状态检查脚本
├── README_CUSTOMER.md         # 详细说明文档
└── DEPLOYMENT_GUIDE.md        # 本文件
```

## 🔧 常用命令

### 启动服务
```bash
./start.sh
# 或
docker compose up -d
```

### 停止服务
```bash
./stop.sh
# 或
docker compose down
```

### 查看状态
```bash
./status.sh
# 或
docker compose ps
```

### 查看日志
```bash
docker compose logs -f backend
```

## 📄 许可证管理

### 检查许可证状态
```bash
curl http://localhost:8000/api/system/license
```

### 许可证要求
- 许可证文件必须命名为 `pyarmor.rkey`
- 必须放在 `license/` 目录下
- 许可证过期后服务会自动停止
- 更新许可证后需要重启服务

## 🔍 故障排除

### 1. 许可证相关
```bash
# 检查许可证文件是否存在
ls -la license/pyarmor.rkey

# 检查许可证状态
curl http://localhost:8000/api/system/license

# 查看许可证检查日志
docker compose logs backend | grep LICENSE
```

### 2. 服务状态
```bash
# 检查所有服务状态
docker compose ps

# 检查特定服务日志
docker compose logs backend
docker compose logs postgres
docker compose logs redis
```

### 3. 网络连接
```bash
# 检查端口是否开放
netstat -tlnp | grep 8000

# 检查防火墙
firewall-cmd --list-ports
```

## 📞 技术支持

如遇问题，请提供以下信息：
1. `docker compose ps` 输出
2. `docker compose logs backend` 日志
3. 许可证状态信息
4. 系统环境信息（操作系统、Docker版本等）

## 🔒 安全说明

- 后端代码已使用PyArmor加密保护
- 客户无法查看或修改业务逻辑源码
- 许可证采用时间控制机制
- 建议定期更新管理员密码
- 建议配置防火墙限制访问来源
