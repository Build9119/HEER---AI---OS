#!/bin/bash
# Tenant Isolation Test Script

# Set up test tenants
psql -U postgres -d heer -c "CREATE USER test_user WITH PASSWORD 'test';"
psql -U test_user -d heer -c "SET app.current_tenant_id = 'tenant_a';"

# Create tenants
psql -U test_user -d heer -c "
INSERT INTO businesses (name, industry_tag) VALUES
  ('Business A', 'finance'),
  ('Business B', 'tech');

INSERT INTO tenants (
  business_id, tenant_code
) SELECT 
  id, 'tenant_a'
FROM businesses
WHERE name = 'Business A';

INSERT INTO tenants (
  business_id, tenant_code
) SELECT 
  id, 'tenant_b'
FROM businesses
WHERE name = 'Business B';

-- Create agents
INSERT INTO agents (
  tenant_id, agent_id
) SELECT 
  tenant_id, 'agent-A'
FROM agents
JOIN tenants ON agents.tenant_id = tenants.id
WHERE tenants.tenant_code = 'tenant_a';

INSERT INTO agents (
  tenant_id, agent_id
) SELECT 
  tenant_id, 'agent-B'
FROM agents
JOIN tenants ON agents.tenant_id = tenants.id
WHERE tenants.tenant_code = 'tenant_b';

-- Insert sample data
INSERT INTO workers (
  agent_id, worker_id
) SELECT 
  id, 'worker-1'
FROM agents
WHERE agent_id = 'agent-A';

INSERT INTO workers (
  agent_id, worker_id
) SELECT 
  id, 'worker-1'
FROM agents
WHERE agent_id = 'agent-B';

-- Test tenant_a accessing tenant_b
psql -U test_user -d heer -c "
SET app.current_tenant_id = 'tenant_a';
SELECT * FROM agents WHERE agent_id = 'agent-B';
" > tenant_a_output

# Expected: 0 rows (RLS blocked access)
if [ $(wc -l < tenant_a_output) -eq 0 ]; then
  echo "✅ tenant_a cannot access tenant_b data"
else
  echo "❌ RLS test failed"
fi

# Cleanup
rm tenant_a_output