-- Initialize logical databases for AgentMesh venture
-- Per ~/infra/onboarding.md: Logical isolation via CREATE DATABASE on shared dev-postgres (port 5435)

CREATE DATABASE agentmesh;
CREATE DATABASE autobads;

-- Test databases (onboarding rule: use _test suffix, clean up after tests)
CREATE DATABASE agentmesh_test;
CREATE DATABASE autobads_test;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE agentmesh TO admin;
GRANT ALL PRIVILEGES ON DATABASE autobads TO admin;
GRANT ALL PRIVILEGES ON DATABASE agentmesh_test TO admin;
GRANT ALL PRIVILEGES ON DATABASE autobads_test TO admin;
