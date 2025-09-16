# 网络设备批量配置管理系统（客户版 README）

由“乾颐堂现任明教教主”开发与交付的网络设备批量配置管理系统，为企业提供批量配置、自动备份与基础智能检查能力，帮助网络团队提升效率与稳定性。

## 项目简介
- 面向企业网络设备（如 Cisco、Juniper、华为等）的日常运维场景
- 一键部署，开箱即用，Web 界面操作，默认账户：admin / admin（首次登录请及时修改）
- 支持批量配置下发、计划备份、结果留存与基础告警提示

## 授权说明
- 本系统采用“时间限制的文件授权”机制（离线校验，不绑定硬件）。
- 授权文件名固定为：`license/pyarmor.rkey`。
- 授权类型：
  - 试用许可：30 天（用于 PoC / 内测）
  - 年度订阅：1 年（正式商用）
- 到期行为：到达“过期时间”后，系统会在巡检中自动停止服务，界面会提前显示剩余时间。
- 续期方式：联系供应商获取新的授权文件，替换 `license/pyarmor.rkey` 并重启服务即可。

## 交付内容
```
customer_deployment/
├── docker-compose.yml
├── initdb/00-init.sql          # 首次启动自动初始化（默认账户：admin/admin）
└── license/pyarmor.rkey        # 授权文件（供应商提供/替换）
```

## 快速使用
1. 将供应商提供的授权文件放入 `customer_deployment/license/pyarmor.rkey`
2. 在服务器执行：`docker compose up -d` 或者 `./start.sh`
3. 浏览器访问：`http://<服务器IP>:8000`

## 常见问题（简要）
- 无法登录：请确认首次启动已完成初始化；如仍异常，请联系技术支持。
- 授权到期：替换新的授权文件后，执行 `docker compose restart backend celery_worker backup_scheduler`。
- 日志排查：`docker compose logs -f backend`（如需，请将关键片段提供给技术支持）。

## 声明
- 本系统镜像已对源码进行加密保护，客户无法查看或修改内部实现。
- 如需功能扩展或定制，请联系供应商对接。