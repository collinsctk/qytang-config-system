# 客户部署镜像 Dockerfile
# 使用生产环境的二进制封装版本

FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# 安装必要的系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

# 安装运行时依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制加密后的应用代码（从生产环境构建）
COPY app/ .
COPY main.py .

# 复制前端静态资源
COPY frontend/ /app/frontend/

# 创建许可证目录
RUN mkdir -p /app/license

# 默认命令
CMD ["python", "main.py"]
