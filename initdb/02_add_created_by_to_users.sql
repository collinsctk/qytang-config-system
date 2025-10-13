-- 为 users 表添加 created_by 字段
-- 用于记录用户的创建者

-- 添加 created_by 字段
ALTER TABLE users ADD COLUMN IF NOT EXISTS created_by INTEGER;

-- 添加外键约束（如果不存在）
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'fk_users_created_by'
    ) THEN
        ALTER TABLE users ADD CONSTRAINT fk_users_created_by 
            FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;
    END IF;
END $$;

-- 为现有的 admin 用户设置 created_by 为 NULL（自创建）
UPDATE users SET created_by = NULL WHERE username = 'admin';

