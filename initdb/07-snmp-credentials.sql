-- SNMP身份信息绑定表
CREATE TABLE IF NOT EXISTS snmp_credentials (
    id SERIAL PRIMARY KEY,
    credential_name VARCHAR(100) UNIQUE NOT NULL,
    snmp_version VARCHAR(10) NOT NULL,
    community VARCHAR(255),
    username VARCHAR(255),
    auth_protocol VARCHAR(50),
    auth_key VARCHAR(255),
    priv_protocol VARCHAR(50),
    priv_key VARCHAR(255),
    group_id INTEGER REFERENCES device_groups(id),
    description TEXT,
    is_active VARCHAR(10) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- SNMP任务配置表
CREATE TABLE IF NOT EXISTS snmp_tasks (
    id SERIAL PRIMARY KEY,
    task_name VARCHAR(100) UNIQUE NOT NULL,
    schedule_interval_minutes INTEGER DEFAULT 5,
    max_concurrent_workers INTEGER DEFAULT 100,
    snmp_timeout INTEGER DEFAULT 5,
    snmp_retries INTEGER DEFAULT 2,
    oids JSONB DEFAULT '[]'::jsonb,
    status VARCHAR(20) DEFAULT 'stopped',
    is_active VARCHAR(10) DEFAULT 'active',
    trigger_mode VARCHAR(20) DEFAULT 'scheduler',
    celery_task_id VARCHAR(255) UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    stopped_at TIMESTAMP WITH TIME ZONE
);

-- SNMP任务与凭证关联表
CREATE TABLE IF NOT EXISTS snmp_task_credentials (
    id SERIAL PRIMARY KEY,
    task_id INTEGER NOT NULL REFERENCES snmp_tasks(id) ON DELETE CASCADE,
    credential_id INTEGER NOT NULL REFERENCES snmp_credentials(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(task_id, credential_id)
);

-- SNMP任务执行历史表
CREATE TABLE IF NOT EXISTS snmp_task_executions (
    id SERIAL PRIMARY KEY,
    task_id INTEGER NOT NULL REFERENCES snmp_tasks(id) ON DELETE CASCADE,
    device_id INTEGER REFERENCES devices(id) ON DELETE SET NULL,
    credential_id INTEGER REFERENCES snmp_credentials(id) ON DELETE SET NULL,
    device_name VARCHAR(255),
    device_ip VARCHAR(45),
    status VARCHAR(20) DEFAULT 'pending',
    response_time_ms FLOAT,
    success BOOLEAN DEFAULT FALSE,
    error_message TEXT,
    collected_data JSONB DEFAULT '{}'::jsonb,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_snmp_cred_name ON snmp_credentials(credential_name);
CREATE INDEX IF NOT EXISTS idx_snmp_cred_version ON snmp_credentials(snmp_version);
CREATE INDEX IF NOT EXISTS idx_snmp_task_name ON snmp_tasks(task_name);
CREATE INDEX IF NOT EXISTS idx_snmp_task_status ON snmp_tasks(status);
CREATE INDEX IF NOT EXISTS idx_snmp_exec_task ON snmp_task_executions(task_id);
CREATE INDEX IF NOT EXISTS idx_snmp_exec_device ON snmp_task_executions(device_id);
CREATE INDEX IF NOT EXISTS idx_snmp_exec_created ON snmp_task_executions(created_at);

-- 注：为避免在生产/开发环境自动生成演示凭证，
-- 以下示例数据已移除。如需演示数据，可手动执行以下语句。
-- INSERT INTO snmp_credentials (credential_name, snmp_version, community, description, is_active)
-- VALUES ('example_v2c', 'v2c', 'public', '示例SNMPv2c凭证', 'active')
-- ON CONFLICT (credential_name) DO NOTHING;
-- 
-- INSERT INTO snmp_credentials (credential_name, snmp_version, username, auth_protocol, auth_key, priv_protocol, priv_key, description, is_active)
-- VALUES ('example_v3', 'v3', 'qytanguser', 'SHA', 'qytang_auth_pass', 'AES', 'qytang_priv_pass', '示例SNMPv3凭证', 'active')
-- ON CONFLICT (credential_name) DO NOTHING;
