-- Initialize databases for AgentMesh and Auto-BADS
CREATE DATABASE agentmesh;
CREATE DATABASE autobads;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE agentmesh TO postgres;
GRANT ALL PRIVILEGES ON DATABASE autobads TO postgres;
