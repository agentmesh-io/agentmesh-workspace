# AgentMesh + Auto-BADS Quick Start

## 🚀 Start Everything

### Step 1: Start AgentMesh Infrastructure
```bash
cd /Users/univers/projects/agentmesh/AgentMesh
./restart-agentmesh.sh
```

**This starts:**
- ✅ PostgreSQL (5432)
- ✅ Redis (6379)
- ✅ Kafka + Zookeeper (9092)
- ✅ Weaviate Vector DB (8081)
- ✅ Temporal Workflow Engine (7233)
- ✅ AgentMesh API (8080)
- ✅ AgentMesh UI (3001)
- ✅ Prometheus (9090)
- ✅ Grafana (3000)

### Step 2: Start Auto-BADS
```bash
cd /Users/univers/projects/agentmesh/Auto-BADS
./start-autobads.sh
```

**This starts:**
- ✅ Auto-BADS Business Analysis Service (8083)

## 🌐 Access the Platform

| Service | URL | Credentials |
|---------|-----|-------------|
| **AgentMesh UI** | http://localhost:3001 | - |
| **AgentMesh API** | http://localhost:8080 | - |
| **Auto-BADS API** | http://localhost:8083 | - |
| **Grafana** | http://localhost:3000 | admin / agentmesh123 |
| **Prometheus** | http://localhost:9090 | - |

## ✅ Verify Everything Works

### Check Services
```bash
cd /Users/univers/projects/agentmesh/AgentMesh
./check-status.sh
```

### Test Auto-BADS
```bash
curl http://localhost:8083/actuator/health
```

Expected response:
```json
{"status":"UP"}
```

### Test UI → Auto-BADS Connection
```bash
docker exec agentmesh-ui wget -qO- http://host.docker.internal:8083/actuator/health
```

## 🧪 Test the "Submit Idea" Feature

1. **Open AgentMesh UI:** http://localhost:3001
2. **Click "Submit New Idea"**
3. **Fill out the form:**
   - Title: "AI-Powered Personal Finance Assistant"
   - Description: Detailed business description
   - Target Market: "Millennials aged 25-40"
   - Problem Statement: What problem it solves
4. **Click "Submit Idea"**

**Expected behavior:**
- ✅ Form submits successfully
- ✅ Auto-BADS analyzes the idea
- ✅ Workflow appears in "View Workflows"
- ✅ AgentMesh begins code generation

**If you see "Failed to fetch":**
- ❌ Auto-BADS is not running → Start with `./start-autobads.sh`
- ❌ Port 8083 is blocked → Check `lsof -i :8083`

## 🛠️ Common Tasks

### Restart Everything
```bash
# Stop all services
cd /Users/univers/projects/agentmesh/AgentMesh
docker-compose down

# Stop Auto-BADS (Ctrl+C in terminal or)
pkill -f "Auto-BADS"

# Start AgentMesh
./restart-agentmesh.sh

# Start Auto-BADS (in new terminal)
cd ../Auto-BADS
./start-autobads.sh
```

### Clean Kafka State (Fix NodeExistsException)
```bash
cd /Users/univers/projects/agentmesh/AgentMesh
./restart-agentmesh.sh --clean-kafka
```

### Full Reset (Nuclear Option)
```bash
cd /Users/univers/projects/agentmesh/AgentMesh
./restart-agentmesh.sh --full-clean
# Then restart Auto-BADS
cd ../Auto-BADS
./start-autobads.sh
```

### View Logs
```bash
# AgentMesh API
docker logs -f agentmesh-api-server

# AgentMesh UI
docker logs -f agentmesh-ui

# Auto-BADS (if running in terminal, logs appear there)
# If running in background:
tail -f logs/autobads.log

# Kafka
docker logs -f agentmesh-kafka
```

## 🐛 Troubleshooting

### "Failed to fetch" on Submit Idea

**Symptom:** UI shows error when submitting business idea

**Cause:** Auto-BADS not running or not accessible

**Solution:**
```bash
# 1. Check Auto-BADS is running
curl http://localhost:8083/actuator/health

# 2. If not running, start it
cd /Users/univers/projects/agentmesh/Auto-BADS
./start-autobads.sh

# 3. Verify UI can reach it
docker exec agentmesh-ui wget -qO- http://host.docker.internal:8083/actuator/health

# 4. Check UI environment
docker exec agentmesh-ui env | grep AUTOBADS
# Should show: NEXT_PUBLIC_AUTOBADS_API=http://host.docker.internal:8083
```

### Port Conflicts

**Symptom:** Services fail to start with "port already allocated"

**Solution:**
```bash
cd /Users/univers/projects/agentmesh/AgentMesh
./restart-agentmesh.sh
# Script automatically handles port conflicts
```

### Kafka Won't Start

**Symptom:** Kafka exits with NodeExistsException

**Solution:**
```bash
cd /Users/univers/projects/agentmesh/AgentMesh
./restart-agentmesh.sh --clean-kafka
```

### Auto-BADS Database Errors

**Symptom:** Auto-BADS fails to connect to PostgreSQL

**Solution:**
```bash
# 1. Ensure AgentMesh infrastructure is running
cd /Users/univers/projects/agentmesh/AgentMesh
./check-status.sh

# 2. Check PostgreSQL
docker exec agentmesh-postgres pg_isready -U agentmesh

# 3. Create autobads database if needed
docker exec -it agentmesh-postgres psql -U agentmesh -c "CREATE DATABASE autobads;"

# 4. Restart Auto-BADS
cd ../Auto-BADS
./start-autobads.sh
```

## 📊 Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      User Browser                        │
│                  http://localhost:3001                   │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│              AgentMesh UI (Docker)                       │
│                     Port 3001                            │
├──────────────────────┬──────────────────────────────────┤
│  NEXT_PUBLIC_AGENTMESH_API: http://agentmesh-api:8080  │
│  NEXT_PUBLIC_AUTOBADS_API: http://host.docker.internal:8083 │
└──────────────────────┼──────────────────────────────────┘
                       │
         ┌─────────────┴───────────────┐
         │                             │
         ▼                             ▼
┌──────────────────┐          ┌──────────────────┐
│  AgentMesh API   │          │   Auto-BADS      │
│   (Docker)       │          │  (Standalone)    │
│   Port 8080      │          │   Port 8083      │
└────────┬─────────┘          └────────┬─────────┘
         │                             │
         └──────────┬──────────────────┘
                    │
    ┌───────────────┼───────────────────────┐
    │               │                       │
    ▼               ▼                       ▼
┌─────────┐   ┌──────────┐          ┌───────────┐
│PostgreSQL│   │  Kafka   │          │   Redis   │
│Port 5432│   │Port 9092 │          │ Port 6379 │
└─────────┘   └──────────┘          └───────────┘
```

## 📚 Additional Documentation

- **Troubleshooting Guide:** `/AgentMesh/TROUBLESHOOTING.md`
- **Auto-BADS Setup:** `/Auto-BADS/SETUP_GUIDE.md`
- **AgentMesh Documentation:** `/AgentMesh/DOCUMENTATION-INDEX.md`

## 🎯 Development Workflow

1. **Start infrastructure once per day:**
   ```bash
   cd /Users/univers/projects/agentmesh/AgentMesh
   ./restart-agentmesh.sh
   ```

2. **Start Auto-BADS for development:**
   ```bash
   cd /Users/univers/projects/agentmesh/Auto-BADS
   ./start-autobads.sh
   ```

3. **Make changes to Auto-BADS code**

4. **Restart Auto-BADS (Ctrl+C, then run again):**
   ```bash
   ./start-autobads.sh
   ```

5. **Check logs and test**

## 🔐 Security Notes

- Default passwords are **development only**
- Change passwords for production:
  - PostgreSQL: `agentmesh123`
  - Grafana: `agentmesh123`
- Auto-BADS API has no authentication (add before production)

## ⚡ Performance Tips

- **Auto-BADS uses Ollama** - Install `tinyllama:1.1b` for faster responses
- **Kafka needs 2GB+ RAM** - Adjust Docker Desktop settings if needed
- **PostgreSQL connection pooling** - Already configured in AgentMesh API
- **Redis caching enabled** - API responses are cached
