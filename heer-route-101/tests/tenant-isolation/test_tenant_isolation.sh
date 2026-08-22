#!/bin/bash
# Tenant Isolation Test Script

# Setup: Create test user
psql -U postgres -d heer -c "DO \$\$ BEGIN CREATE USER IF NOT EXISTS test_user WITH PASSWORD 'test'; EXCEPTION WHEN duplicate_object THEN RAISE NOTICE 'User exists'; END \$\$;"

# Grant necessary privileges
psql -U postgres -d heer -c "GRANT CONNECT ON DATABASE heer TO test_user;"
psql -U postgres -d heer -c "GRANT USAGE ON SCHEMA public TO test_user;"
psql -U postgres -d heer -c "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO test_user;"

# Clean up previous test data
psql -U postgres -d heer -c "
TRUNCATE TABLE workers RESTART IDENTITY CASCADE;
TRUNCATE TABLE agents RESTART IDENTITY CASCADE;
TRUNCATE TABLE tenants RESTART IDENTITY CASCADE;
TRUNCATE TABLE businesses RESTART IDENTITY CASCADE;
" 2>/dev/null || true

# Create test businesses and tenants
psql -U postgres -d heer -c "
INSERT INTO businesses (name, industry_tag) VALUES
  ('Business A', 'finance'),
  ('Business B', 'tech')
ON CONFLICT DO NOTHING;

WITH business_a AS (SELECT id FROM businesses WHERE name = 'Business A' LIMIT 1),
     business_b AS (SELECT id FROM businesses WHERE name = 'Business B' LIMIT 1)
INSERT INTO tenants (business_id, tenant_code)
VALUES
  ((SELECT id FROM business_a), 'tenant-a'),
  ((SELECT id FROM business_b), 'tenant-b')
ON CONFLICT DO NOTHING;
"

# Create test agents for each tenant
psql -U postgres -d heer -c "
WITH tenant_a AS (SELECT id FROM tenants WHERE tenant_code = 'tenant-a' LIMIT 1),
     tenant_b AS (SELECT id FROM tenants WHERE tenant_code = 'tenant-b' LIMIT 1)
INSERT INTO agents (tenant_id, agent_id)
VALUES
  ((SELECT id FROM tenant_a), 'agent-a-001'),
  ((SELECT id FROM tenant_b), 'agent-b-001')
ON CONFLICT DO NOTHING;
"

# Create test workers
psql -U postgres -d heer -c "
WITH agent_a AS (SELECT id FROM agents WHERE agent_id = 'agent-a-001' LIMIT 1),
     agent_b AS (SELECT id FROM agents WHERE agent_id = 'agent-b-001' LIMIT 1)
INSERT INTO workers (agent_id, worker_id)
VALUES
  ((SELECT id FROM agent_a), 'worker-a-001'),
  ((SELECT id FROM agent_b), 'worker-b-001')
ON CONFLICT DO NOTHING;
"

# Test 1: Tenant A should only see its own agent
echo "Testing tenant-a isolation..."
TENANT_A_RESULT=$(PGPASSWORD=test psql -U test_user -d heer -t -A -c "
SET app.current_tenant_id = (SELECT id FROM tenants WHERE tenant_code = 'tenant-a');
SELECT COUNT(*) FROM agents;
")

if [ "$TENANT_A_RESULT" -eq 1 ]; then
  echo "✅ Tenant A sees exactly 1 agent (own)"
else
  echo "❌ Tenant A sees $TENANT_A_RESULT agents (expected 1)"
  exit 1
fi

# Test 2: Tenant A should NOT see Tenant B's agent
echo "Testing tenant-a cannot access tenant-b data..."
TENANT_A_SEE_B_RESULT=$(PGPASSWORD=test psql -U test_user -d heer -t -A -c "
SET app.current_tenant_id = (SELECT id FROM tenants WHERE tenant_code = 'tenant-a');
SELECT COUNT(*) FROM agents WHERE agent_id = 'agent-b-001';
")

if [ "$TENANT_A_SEE_B_RESULT" -eq 0 ]; then
  echo "✅ Tenant A cannot see Tenant B's agent"
else
  echo "❌ Tenant A can see Tenant B's agent (RLS FAILED)"
  exit 1
fi

# Test 3: Tenant B should only see its own agent
echo "Testing tenant-b isolation..."
TENANT_B_RESULT=$(PGPASSWORD=test psql -U test_user -d heer -t -A -c "
SET app.current_tenant_id = (SELECT id FROM tenants WHERE tenant_code = 'tenant-b');
SELECT COUNT(*) FROM agents;
")

if [ "$TENANT_B_RESULT" -eq 1 ]; then
  echo "✅ Tenant B sees exactly 1 agent (own)"
else
  echo "❌ Tenant B sees $TENANT_B_RESULT agents (expected 1)"
  exit 1
fi

# Test 4: Tenant B should NOT see Tenant A's agent
echo "Testing tenant-b cannot access tenant-a data..."
TENANT_B_SEE_A_RESULT=$(PGPASSWORD=test psql -U test_user -d heer -t -A -c "
SET app.current_tenant_id = (SELECT id FROM tenants WHERE tenant_code = 'tenant-b');
SELECT COUNT(*) FROM agents WHERE agent_id = 'agent-a-001';
")

if [ "$TENANT_B_SEE_A_RESULT" -eq 0 ]; then
  echo "✅ Tenant B cannot see Tenant A's agent"
else
  echo "❌ Tenant B can see Tenant A's agent (RLS FAILED)"
  exit 1
fi

echo "🎉 All tenant isolation tests passed!"
exit 0