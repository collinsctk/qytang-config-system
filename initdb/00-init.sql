-- 创建数据库表
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS credentials (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    username VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS device_groups (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    device_type VARCHAR(50) NOT NULL,
    credential_id INTEGER REFERENCES credentials(id),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS devices (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    ip_address VARCHAR(45) UNIQUE NOT NULL,
    group_id INTEGER REFERENCES device_groups(id),
    description VARCHAR(255),
    is_active VARCHAR(10) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    config_commands TEXT NOT NULL,
    device_type VARCHAR(50) NOT NULL,
    target_devices JSONB NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    error_stop VARCHAR(10) DEFAULT 'false',
    error_recovery VARCHAR(10) DEFAULT 'false',
    max_concurrent INTEGER DEFAULT 100,
    timeout INTEGER DEFAULT 30,
    retry_count INTEGER DEFAULT 3,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    total_devices INTEGER DEFAULT 0,
    success_count INTEGER DEFAULT 0,
    failed_count INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS task_results (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES tasks(id),
    device_id INTEGER REFERENCES devices(id),
    device_name VARCHAR(255) NOT NULL,
    device_ip VARCHAR(45) NOT NULL,
    success BOOLEAN DEFAULT FALSE,
    message TEXT,
    error TEXT,
    executed_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS system_configs (
    id SERIAL PRIMARY KEY,
    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- 插入默认管理员账户 (密码: admin)
INSERT INTO users (username, hashed_password, is_active, is_admin, created_at) 
VALUES (
    'admin', 
    '$pbkdf2-sha256$29000$2NtbK8WYMwbgvFeKkbL2/g$X32yjV5fAPB5rhzs38SDKLIFsgMD6VSGdWKZTkxe7b8',
    true, 
    true, 
    NOW()
) ON CONFLICT (username) DO NOTHING;

-- 不插入默认的设备凭据，让用户自己创建

-- 备份模板
CREATE TABLE IF NOT EXISTS backup_command_templates (
    id SERIAL PRIMARY KEY,
    device_type VARCHAR(50) NOT NULL,
    command TEXT NOT NULL,
    match_regex TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- 备份调度
CREATE TABLE IF NOT EXISTS backup_schedules (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    cron_expr VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    template_id INTEGER NOT NULL REFERENCES backup_command_templates(id),
    selectors JSONB NOT NULL DEFAULT '{}'::jsonb,
    device_type VARCHAR(50) NOT NULL,
    last_scheduled_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- 备份运行（增加 trigger_source 字段：manual/scheduler）
CREATE TABLE IF NOT EXISTS backup_runs (
    id SERIAL PRIMARY KEY,
    schedule_id INTEGER NOT NULL REFERENCES backup_schedules(id) ON DELETE CASCADE,
    device_type VARCHAR(50) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'pending',
    trigger_source VARCHAR(16),
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    success_count INTEGER DEFAULT 0,
    failed_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- 备份结果
CREATE TABLE IF NOT EXISTS backup_results (
    id SERIAL PRIMARY KEY,
    run_id INTEGER NOT NULL REFERENCES backup_runs(id) ON DELETE CASCADE,
    schedule_id INTEGER NOT NULL REFERENCES backup_schedules(id) ON DELETE CASCADE,
    device_id INTEGER NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    device_type VARCHAR(50) NOT NULL,
    error BOOLEAN DEFAULT FALSE,
    error_message TEXT,
    s3_key VARCHAR(512),
    config_sha256 VARCHAR(64),
    changed BOOLEAN DEFAULT FALSE,
    diff_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cisco PSIRT 安全通告表
CREATE TABLE IF NOT EXISTS cisco_psirt_advisories (
    id SERIAL PRIMARY KEY,
    advisory_id VARCHAR(100) UNIQUE NOT NULL,
    advisory_title TEXT NOT NULL,
    summary TEXT,
    sir VARCHAR(50),
    cvss_base_score VARCHAR(10),
    first_published TIMESTAMP WITH TIME ZONE,
    last_updated TIMESTAMP WITH TIME ZONE,
    status VARCHAR(50),
    publication_url TEXT,
    raw_json JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- 受影响产品版本表
CREATE TABLE IF NOT EXISTS cisco_psirt_products (
    id SERIAL PRIMARY KEY,
    advisory_id VARCHAR(100) NOT NULL REFERENCES cisco_psirt_advisories(advisory_id) ON DELETE CASCADE,
    product_name VARCHAR(255),
    product_family VARCHAR(100),
    affected_versions JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- CVE映射表
CREATE TABLE IF NOT EXISTS cisco_psirt_cves (
    id SERIAL PRIMARY KEY,
    advisory_id VARCHAR(100) NOT NULL REFERENCES cisco_psirt_advisories(advisory_id) ON DELETE CASCADE,
    cve_id VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 搜索优化索引表
CREATE TABLE IF NOT EXISTS cisco_psirt_search_index (
    id SERIAL PRIMARY KEY,
    advisory_id VARCHAR(100) NOT NULL REFERENCES cisco_psirt_advisories(advisory_id) ON DELETE CASCADE,
    product_type VARCHAR(50),
    version_major INT,
    version_minor INT,
    version_patch INT,
    version_letter VARCHAR(5),
    is_affected BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引以提升查询性能
CREATE INDEX IF NOT EXISTS idx_cisco_advisory_id ON cisco_psirt_advisories(advisory_id);
CREATE INDEX IF NOT EXISTS idx_cisco_product_advisory ON cisco_psirt_products(advisory_id);
CREATE INDEX IF NOT EXISTS idx_cisco_cve_id ON cisco_psirt_cves(cve_id);
CREATE INDEX IF NOT EXISTS idx_cisco_search_product_type ON cisco_psirt_search_index(product_type);
CREATE INDEX IF NOT EXISTS idx_cisco_search_version ON cisco_psirt_search_index(version_major, version_minor, version_patch);


