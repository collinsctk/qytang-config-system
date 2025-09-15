#!/bin/bash

echo "============================================================"
echo "          网络设备批量配置管理系统"
echo "============================================================"

# 检查许可证文件
if [ ! -f "license/pyarmor.rkey" ]; then
    echo "❌ 错误: 找不到许可证文件"
    echo "请将供应商提供的 pyarmor.rkey 文件放入 license/ 目录"
    echo ""
    echo "目录结构应该是:"
    echo "license/"
    echo "└── pyarmor.rkey"
    exit 1
fi

echo "✅ 许可证文件检查通过"

# 启动服务
echo "🚀 启动服务..."
docker compose up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo "🔍 检查服务状态..."
docker compose ps

# 检查许可证状态
echo "📄 检查许可证状态..."
curl -s http://localhost:8000/api/system/license | python3 -m json.tool 2>/dev/null || echo "许可证状态检查失败"

echo ""
echo "🎉 部署完成！"
echo "📱 访问地址: http://服务器IP:8000"
echo "👤 默认账户: admin/admin"
echo "============================================================"
