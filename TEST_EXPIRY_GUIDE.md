# 1小时测试许可证使用指南

## 📋 测试许可证信息

- **许可证类型**: 时间限制许可证
- **有效期**: 0.04天（约1小时）
- **过期日期**: 2025-09-15
- **生成时间**: 2025-09-15 22:06:04
- **版本**: 1.0.0

## 🧪 测试步骤

### 1. 启动系统
```bash
cd /qytang_config_system_customer
./start.sh
```

### 2. 检查许可证状态
```bash
# 通过API检查
curl http://localhost:8000/api/system/license

# 或访问Web界面
# http://服务器IP:8000 -> 系统设置 -> 许可证状态
```

### 3. 等待过期测试
- 系统每小时检查一次许可证状态
- 过期后系统会自动终止
- 可以通过日志观察过期处理过程

### 4. 观察过期行为
```bash
# 查看许可证检查日志
docker compose logs backend | grep LICENSE

# 查看服务状态
docker compose ps
```

## ⚠️ 预期行为

**过期前**：
- 系统正常运行
- 许可证状态显示剩余时间
- Web界面可正常访问

**过期后**：
- 系统自动终止
- 日志显示"许可证已过期，正在终止服务..."
- 所有服务停止运行

## 🔄 恢复测试

测试完成后，可以生成新的许可证：
```bash
# 生成30天测试许可证
python backend/app/tools/generate_license.py 30 customer_deployment/license/pyarmor.rkey

# 重启服务
./start.sh
```

## 📊 监控命令

```bash
# 实时监控许可证状态
watch -n 10 'curl -s http://localhost:8000/api/system/license | python3 -m json.tool'

# 监控服务日志
docker compose logs -f backend
```

## 🎯 测试重点

1. **启动时检查**: 验证启动时的许可证验证
2. **运行中检查**: 验证每小时的后台检查
3. **过期处理**: 验证过期时的自动终止
4. **状态显示**: 验证GUI中的许可证状态显示
5. **API响应**: 验证许可证状态API的响应

这个1小时测试许可证可以帮助您快速验证许可证过期机制是否正常工作！
