-- Migration: 001_tenant_model.sql
-- Purpose: Define tables for Business → Tenant → Agent → Worker hierarchy
-- Enforce non-nullable foreign keys and Row-Level Security (RLS) policies
-- Compatible with Postgres 16

-- Enable UUID extension if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Business table (root of the hierarchy)
CREATE TABLE businesses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    industry_tag TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tenant table (belongs to a Business)
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    tenant_code TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Agent table (belongs to a Tenant)
CREATE TABLE agents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    agent_id TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Worker table (belongs to an Agent)
CREATE TABLE workers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
    worker_id TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable row-level security on all tenant-scoped tables
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE workers ENABLE ROW LEVEL SECURITY;

-- Policy: Tenant members can SELECT/INSERT/UPDATE/DELETE only their own data
-- Tenant identity is passed via current_setting('app.current_tenant_id')
-- Must be a UUID; cast to TEXT for comparison with UUID primary keys

-- Policy for tenants table
CREATE POLICY tenant_policy ON tenants
    FOR ALL
    USING (current_setting('app.current_tenant_id')::UUID = id);

-- Policy for agents table
CREATE POLICY agent_policy ON agents
    FOR ALL
    USING (current_setting('app.current_tenant_id')::UUID = id);

-- Policy for workers table
CREATE POLICY worker_policy ON workers
    FOR ALL
    USING (current_setting('app.current_tenant_id')::UUID = id);

-- Optional: Additional check policies (INSERT/UPDATE) can ensure tenant_id matches
-- ALTER TABLE agents ADD CONSTRAINT agent_tenant_fk_check
--     CHECK (tenant_id = current_setting('app.current_tenant_id')::UUID);

-- Note: Application must issue SET app.current_tenant_id = '<tenant_id>'; before
-- any queries to enforce tenant isolation.