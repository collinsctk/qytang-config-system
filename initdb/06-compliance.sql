-- Compliance Management Tables
-- 合规性管理相关表

-- 1. 合规规则表（用户定义规则）
CREATE TABLE IF NOT EXISTS compliance_rules (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    severity VARCHAR(50) NOT NULL,  -- critical, high, medium, low
    platforms JSONB NOT NULL,  -- ['cisco_ios', 'cisco_xe', etc.]
    check_command VARCHAR(500) NOT NULL,  -- 检查命令，如 'show running-config | section line vty'
    check_function TEXT NOT NULL,  -- Python 函数代码（完整函数）
    is_custom BOOLEAN DEFAULT TRUE,  -- 是否为用户自定义规则
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_compliance_rules_severity ON compliance_rules(severity);
CREATE INDEX IF NOT EXISTS idx_compliance_rules_created ON compliance_rules(created_at DESC);

-- 2. 合规扫描任务表
CREATE TABLE IF NOT EXISTS compliance_scan_tasks (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',  -- pending, running, completed, failed
    target_devices TEXT NOT NULL,  -- JSON 格式或逗号分隔的设备标识
    total_devices INTEGER DEFAULT 0,
    completed_devices INTEGER DEFAULT 0,
    failed_devices INTEGER DEFAULT 0,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_compliance_scan_tasks_status ON compliance_scan_tasks(status);
CREATE INDEX IF NOT EXISTS idx_compliance_scan_tasks_created ON compliance_scan_tasks(created_at DESC);

-- 3. 合规扫描结果表
CREATE TABLE IF NOT EXISTS compliance_scan_results (
    id SERIAL PRIMARY KEY,
    task_id INTEGER NOT NULL REFERENCES compliance_scan_tasks(id) ON DELETE CASCADE,
    device_id INTEGER NOT NULL REFERENCES devices(id),
    rule_id INTEGER NOT NULL REFERENCES compliance_rules(id),
    passed BOOLEAN NOT NULL,  -- True: 通过, False: 失败
    command_output TEXT,  -- 检查命令的输出
    error_message TEXT,  -- 检查过程中的错误信息
    checked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_compliance_scan_results_task_device ON compliance_scan_results(task_id, device_id);
CREATE INDEX IF NOT EXISTS idx_compliance_scan_results_rule ON compliance_scan_results(rule_id);
CREATE INDEX IF NOT EXISTS idx_compliance_scan_results_passed ON compliance_scan_results(passed);

-- 4. 合规扫描报告表（汇总）
CREATE TABLE IF NOT EXISTS compliance_scan_reports (
    id SERIAL PRIMARY KEY,
    task_id INTEGER NOT NULL REFERENCES compliance_scan_tasks(id) ON DELETE CASCADE,
    device_id INTEGER NOT NULL REFERENCES devices(id),
    device_name VARCHAR(255),
    device_ip VARCHAR(45),
    device_type VARCHAR(50),
    total_rules INTEGER DEFAULT 0,
    passed_rules INTEGER DEFAULT 0,
    failed_rules INTEGER DEFAULT 0,
    compliance_score FLOAT,  -- 0-100，计算：通过规则数 / 总规则数 * 100
    critical_issues INTEGER DEFAULT 0,  -- 严重规则失败数
    high_issues INTEGER DEFAULT 0,  -- 高优先级规则失败数
    medium_issues INTEGER DEFAULT 0,
    low_issues INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_compliance_scan_reports_unique ON compliance_scan_reports(task_id, device_id);
CREATE INDEX IF NOT EXISTS idx_compliance_scan_reports_device ON compliance_scan_reports(device_id);
CREATE INDEX IF NOT EXISTS idx_compliance_scan_reports_score ON compliance_scan_reports(compliance_score);
CREATE INDEX IF NOT EXISTS idx_compliance_scan_reports_created ON compliance_scan_reports(created_at DESC);

-- 以下是旧表，保留以兼容之前的数据
-- Keeping old tables for backwards compatibility

CREATE TABLE IF NOT EXISTS compliance_policies (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    supported_platforms JSONB DEFAULT '[]',
    is_builtin BOOLEAN DEFAULT FALSE,
    rule_count INTEGER DEFAULT 0,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS compliance_policy_rules (
    id SERIAL PRIMARY KEY,
    policy_id INTEGER NOT NULL REFERENCES compliance_policies(id) ON DELETE CASCADE,
    rule_id VARCHAR(100) NOT NULL,
    enabled BOOLEAN DEFAULT TRUE,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. 通知渠道配置表
CREATE TABLE IF NOT EXISTS compliance_notification_channels (
    id SERIAL PRIMARY KEY,
    channel_type VARCHAR(50) NOT NULL,  -- email, dingtalk, webhook
    name VARCHAR(255) NOT NULL,
    config JSONB NOT NULL,  -- 渠道特定配置
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. 通知规则表
CREATE TABLE IF NOT EXISTS compliance_notification_rules (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    trigger_type VARCHAR(50) NOT NULL,  -- task_completed, critical_found, score_below_threshold
    trigger_config JSONB,  -- 触发条件配置
    channel_ids INTEGER[],  -- 使用的通知渠道 ID 数组
    recipients JSONB,  -- 收件人列表
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 8. 通知历史表
CREATE TABLE IF NOT EXISTS compliance_notification_logs (
    id SERIAL PRIMARY KEY,
    channel_id INTEGER REFERENCES compliance_notification_channels(id),
    task_id INTEGER REFERENCES compliance_scan_tasks(id),
    notification_type VARCHAR(50),
    recipients JSONB,
    content TEXT,
    status VARCHAR(50),  -- success, failed
    error_message TEXT,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_compliance_notification_logs_task ON compliance_notification_logs(task_id);
CREATE INDEX IF NOT EXISTS idx_compliance_notification_logs_sent ON compliance_notification_logs(sent_at DESC);

-- 创建索引以提升查询性能
CREATE INDEX IF NOT EXISTS idx_compliance_policies_created ON compliance_policies(created_at DESC);

-- 添加注释
COMMENT ON TABLE compliance_rules IS '用户定义的合规规则表';
COMMENT ON TABLE compliance_scan_tasks IS '合规扫描任务表';
COMMENT ON TABLE compliance_scan_results IS '合规扫描结果表';
COMMENT ON TABLE compliance_scan_reports IS '合规扫描报告表';
COMMENT ON TABLE compliance_notification_channels IS '通知渠道配置表';
COMMENT ON TABLE compliance_notification_rules IS '通知规则表';
COMMENT ON TABLE compliance_notification_logs IS '通知历史表';

