-- ==============================================================================
-- simply todo - Database Initialization Script
-- ==============================================================================
-- Repository: todo-db
-- Target: PostgreSQL 15 (Alpine)
-- Purpose: Provisions the exact schema required for the todo-backend service.
-- Note: This script runs automatically inside the Docker container ONLY on 
--       the very first initialization of the persistent volume.
-- ==============================================================================

-- 1. Initialization Logging
-- Using standard SELECT outputs to safely log progress to the Docker container logs
SELECT 'Starting simply todo database schema initialization...' AS _log_status;

-- 2. Extensions
-- PostgreSQL 13+ includes gen_random_uuid() natively, but enabling pgcrypto 
-- ensures we have robust cryptographic functions if the architecture expands.
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 3. Table Creation: tasks
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

SELECT 'Table "tasks" created successfully.' AS _log_status;

-- 4. Automated Timestamps (Trigger & Function)
-- This ensures the backend worker doesn't have to manually update the 'updated_at' 
-- field every time a PUT request modifies a task. The database handles it automatically.
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER update_tasks_modtime
BEFORE UPDATE ON tasks
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

SELECT 'Timestamp triggers established.' AS _log_status;

-- 5. Data Dictionary Constraints & Comments
-- Self-documenting database schema that acts as the source of truth for the DATASHEET.md
COMMENT ON TABLE tasks IS 'Core table storing all task records for the simply todo microservice.';
COMMENT ON COLUMN tasks.id IS 'Primary Key: Cryptographically secure UUID for the task.';
COMMENT ON COLUMN tasks.title IS 'The main heading/title of the task. Cannot be null.';
COMMENT ON COLUMN tasks.description IS 'Optional detailed context, notes, or sub-text for the task.';
COMMENT ON COLUMN tasks.is_completed IS 'Boolean flag indicating if the task is done. Defaults to false.';
COMMENT ON COLUMN tasks.created_at IS 'Immutable timestamp of when the task was initially created.';
COMMENT ON COLUMN tasks.updated_at IS 'Mutable timestamp updated automatically by Postgres on row modification.';

-- 6. Completion Logging
SELECT 'simply todo database schema initialization completed successfully.' AS _log_status;
