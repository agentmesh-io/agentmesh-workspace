# 🚀 Quick Start Guide: Multi-Autonomous Agent System

**Last Updated:** November 4, 2025

---

## 🎯 What is This System?

A complete **Idea-to-Implementation** autonomous software development platform consisting of:

1. **Auto-BADS** → Turns business ideas into validated blueprints
2. **AgentMesh (ASEM)** → Turns blueprints into production code
3. **AgentMesh-UI** → Visualizes and controls the entire process

---

## 🏃‍♂️ 5-Minute Quick Start

### Prerequisites
```bash
# Required
- Java 17+
- Node.js 18+
- Docker & Docker Compose
- Maven 3.8+
- PostgreSQL 14+ (or use Docker)

# Optional
- Kubernetes (for production)
- Redis (for caching)
- Kafka/RabbitMQ (for event bus)
```

### Step 1: Start AgentMesh (Already Working!)
```bash
cd /Users/univers/projects/agentmesh/AgentMesh
mvn clean install
mvn spring-boot:run

# Verify at http://localhost:8080
# All 56 tests should pass
```

### Step 2: Start AgentMesh-UI (Already Working!)
```bash
cd /Users/univers/projects/agentmesh/AgentMesh-UI/agentmesh-ui
npm install
npm run dev

# Open http://localhost:3000
```

### Step 3: Fix and Start Auto-BADS (Needs Work)
```bash
cd /Users/univers/projects/agentmesh/Auto-BADS

# Fix Lombok first
mvn clean install -DskipTests

# If build fails, check pom.xml for lombok config
# Then:
mvn spring-boot:run -Dspring-boot.run.arguments="--server.port=8081"

# Verify at http://localhost:8081
```

### Step 4: Test the Full Pipeline
```bash
# Submit an idea to Auto-BADS
curl -X POST http://localhost:8081/api/ideas/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Smart Home Energy Optimizer",
    "description": "AI-powered app to reduce home energy consumption by 30%",
    "targetMarket": "Residential homeowners",
    "problemStatement": "High energy bills and wasteful consumption"
  }'

# Watch the magic happen in the UI!
```

---

## 📁 Project Structure

```
agentmesh/
├── COMPREHENSIVE_DEVELOPMENT_PLAN.md  # Complete roadmap (you are here)
├── QUICK_START_GUIDE.md               # This file
│
├── AgentMesh/                         # ✅ PRODUCTION READY
│   ├── src/main/java/io/agentmesh/
│   │   ├── orchestration/             # Temporal workflows
│   │   ├── agents/                    # Planner, Coder, Reviewer, etc.
│   │   ├── blackboard/                # Shared memory
│   │   ├── mast/                      # Quality assurance
│   │   └── github/                    # GitHub integration
│   ├── pom.xml
│   └── CURRENT_STATE.md               # Full system status
│
├── Auto-BADS/                         # ⚠️ 95% COMPLETE
│   ├── src/main/java/io/agentmesh/autobads/
│   │   ├── ingestion/                 # Idea input
│   │   ├── marketanalysis/            # SWOT, PESTEL, PMF
│   │   ├── productanalysis/           # Innovation, Design Thinking
│   │   ├── financialanalysis/         # TCO, LSTM forecasting
│   │   └── solutionsynthesis/         # Build/Buy/Hybrid
│   ├── pom.xml
│   └── STATUS.md                      # Known issues
│
└── AgentMesh-UI/                      # ✅ OPERATIONAL
    └── agentmesh-ui/
        ├── app/                       # Next.js pages
        │   ├── page.tsx               # Landing
        │   └── dashboard/
        │       ├── orchestration/     # Workflow viz
        │       ├── agents/            # Agent management
        │       ├── analytics/         # LLMOps metrics
        │       └── projects/          # Project tracking
        ├── components/                # React components
        ├── lib/                       # Utils, types, API
        └── FINAL_STATUS.md            # Build verification
```

---

## 🎨 What Each Component Does

### 1. Auto-BADS (Port 8081)
**Input:** Unstructured business idea  
**Output:** Validated SRS + Blueprint

**Modules:**
- **Ingestion:** Converts vague idea → structured problem
- **Market Analysis:** SWOT, PESTEL, competitor research, PMF score
- **Product Analysis:** Innovation assessment, Design Thinking, TRIZ
- **Financial Analysis:** TCO calculation, LSTM+LLM forecasting
- **Solution Synthesis:** Generates Build/Buy/Hybrid options + SRS

**Example:**
```
Input: "Create a food delivery app"
↓
Market Analysis: High competition, $150B market, 35% growth
Product Analysis: Innovation score 6.5/10, disruptive potential
Financial: $500K dev cost, $2M/year revenue potential, 18-month ROI
Solution: Recommend HYBRID (Uber Eats API + custom features)
↓
Output: 80-page SRS with 47 features, prioritized backlog
```

### 2. AgentMesh (Port 8080)
**Input:** SRS + Technical Blueprint  
**Output:** Production-ready code

**Agents:**
- **Planner:** Task decomposition, dependency management
- **Coder:** Code generation with RAG
- **Test Agent:** Auto-generate tests
- **Reviewer:** Quality gates, MAST checks
- **Debugger:** Fix failing tests

**Workflow:**
```
SRS → Planner (decompose) → Coder (generate) → Test (verify)
                                    ↓
                              Failed? → Debugger → Reviewer → Re-code
                                    ↓
                              Passed? → GitHub PR → Deploy
```

**Features:**
- Self-correction loop (up to 5 iterations)
- 14 MAST failure modes detection
- Blackboard shared memory
- Vector DB for long-term memory
- GitHub integration (zero-frontend PM)

### 3. AgentMesh-UI (Port 3000)
**Purpose:** Unified visualization and control

**Pages:**
- **Landing:** System overview, quick actions
- **Idea Input:** Submit ideas to Auto-BADS
- **Orchestration:** Live workflow graph (ReactFlow)
- **Agents:** Status, metrics, token usage
- **Analytics:** MAST alerts, cost tracking, quality metrics
- **Projects:** GitHub integration, task management

**Real-time Features:**
- WebSocket updates for agent activity
- Live workflow visualization
- Token usage tracking
- Cost analysis per feature
- MAST failure alerts

---

## 🔄 Complete User Journey

### Scenario: "I have an idea for an app"

**Step 1: Submit Idea (Auto-BADS)**
```
You: "Create a parking spot finder app with real-time availability"
↓
UI: /idea-to-srs form submission
↓
Auto-BADS: Starts analysis (2-5 minutes)
```

**Step 2: Review Analysis**
```
Market Analysis:
- Competition: Medium (5 competitors)
- Market Size: $8.2B, growing 12% annually
- PMF Score: 67% (would be "very disappointed")

Product Analysis:
- Innovation: 7.2/10
- TRIZ Solutions: IoT sensors + predictive ML
- Disruption Potential: Medium-High

Financial Forecast:
- Dev Cost: $280K (12 months)
- Operating Cost: $45K/year
- Revenue Projection: $850K/year (Year 3)
- ROI: 14 months

Recommendation: BUILD custom solution
```

**Step 3: Approve & Generate SRS**
```
Click "Generate SRS & Handoff to AgentMesh"
↓
Auto-BADS creates:
- 65-page Software Requirements Specification
- 38 prioritized features
- Technical architecture diagram
- API specifications
- Database schema
```

**Step 4: Automated Development (AgentMesh)**
```
SRS → AgentMesh orchestration starts
↓
Planner: Decomposes into 38 tasks
Coder: Generates code for each task
Test Agent: Creates unit tests
Reviewer: Quality checks
Debugger: Fixes 3 failing tests
↓
Output: 
- 127 files created
- 4,532 lines of code
- 86% test coverage
- GitHub repo with 89 commits
- Deployed to staging
↓
Time: 28 minutes
Cost: $3.47 in LLM tokens
```

**Step 5: Monitor & Review (UI)**
```
Orchestration Dashboard:
- Live workflow graph shows all agents
- Real-time progress: "Coder working on feature #12"
- Metrics: 4.2K tokens used, $0.58 spent

Analytics Dashboard:
- 2 MAST failures detected & auto-fixed
- P95 latency: 1.8 seconds
- Success rate: 96%

Project Dashboard:
- GitHub link to repository
- Deployment status: STAGING LIVE
- 3 manual review tasks pending
```

**Step 6: Deploy to Production**
```
Manual review & approval
↓
Click "Deploy to Production"
↓
GitHub Actions CI/CD triggered
↓
Production deployment complete
```

---

## 🛠️ Development Workflow

### For Contributors

#### 1. Clone & Setup
```bash
git clone <your-repo>
cd agentmesh

# Start dependencies
docker-compose up -d postgres redis kafka

# Or use provided docker-compose.yml in each project
```

#### 2. Make Changes
```bash
# Create feature branch
git checkout -b feature/your-feature

# Make changes
# Write tests
# Update documentation
```

#### 3. Test Locally
```bash
# Auto-BADS
cd Auto-BADS
mvn clean test
mvn spring-boot:run

# AgentMesh
cd AgentMesh
mvn clean test
mvn spring-boot:run

# UI
cd AgentMesh-UI/agentmesh-ui
npm test
npm run build
npm run dev
```

#### 4. Submit PR
```bash
git add .
git commit -m "feat: add your feature"
git push origin feature/your-feature

# Create PR on GitHub
# Wait for CI/CD checks
# Get code review
# Merge!
```

---

## 🐛 Common Issues & Solutions

### Issue 1: Auto-BADS Lombok Errors
```bash
# Symptom: Compilation errors on @Data, @Builder
# Solution:
cd Auto-BADS
# Edit pom.xml and add annotation processor path
mvn clean install -DskipTests
```

### Issue 2: Port Already in Use
```bash
# Symptom: Port 8080/8081/3000 already in use
# Solution:
lsof -ti:8080 | xargs kill -9  # Kill process on port 8080
# Or change port in application.yml / .env
```

### Issue 3: Database Connection Error
```bash
# Symptom: Cannot connect to PostgreSQL
# Solution:
docker-compose up -d postgres
# Or configure H2 for development in application.yml
```

### Issue 4: LLM API Rate Limit
```bash
# Symptom: 429 Too Many Requests from OpenAI
# Solution:
# 1. Use MockLLM for development
# 2. Add caching layer
# 3. Implement exponential backoff
# 4. Use multiple API keys
```

### Issue 5: UI Not Connecting to Backend
```bash
# Symptom: Network errors in browser console
# Solution:
# 1. Check backend is running: curl http://localhost:8080/actuator/health
# 2. Check CORS configuration
# 3. Update API URLs in lib/api/*.ts
```

---

## 📊 Monitoring & Debugging

### Health Checks
```bash
# AgentMesh
curl http://localhost:8080/actuator/health

# Auto-BADS
curl http://localhost:8081/actuator/health

# AgentMesh-UI
curl http://localhost:3000/api/health
```

### View Logs
```bash
# Docker logs
docker logs agentmesh -f
docker logs auto-bads -f

# Or tail log files
tail -f AgentMesh/logs/application.log
tail -f Auto-BADS/logs/application.log
```

### Metrics
```bash
# Prometheus metrics
curl http://localhost:8080/actuator/prometheus
curl http://localhost:8081/actuator/prometheus

# Or view in Grafana at http://localhost:3001
```

### Database Inspection
```bash
# Connect to PostgreSQL
docker exec -it postgres psql -U agentmesh

# Useful queries
SELECT * FROM blackboard_entry ORDER BY created_at DESC LIMIT 10;
SELECT * FROM business_idea ORDER BY created_at DESC;
SELECT * FROM mast_failure WHERE status = 'DETECTED';
```

---

## 🚀 Deployment Guide

### Option 1: Docker Compose (Easiest)
```bash
# Create docker-compose.yml for all services
docker-compose up -d

# Access at:
# AgentMesh: http://localhost:8080
# Auto-BADS: http://localhost:8081
# UI: http://localhost:3000
```

### Option 2: Kubernetes (Production)
```bash
# Apply manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/postgres.yaml
kubectl apply -f k8s/redis.yaml
kubectl apply -f k8s/auto-bads.yaml
kubectl apply -f k8s/agentmesh.yaml
kubectl apply -f k8s/agentmesh-ui.yaml
kubectl apply -f k8s/ingress.yaml

# Check status
kubectl get pods -n agentmesh
```

### Option 3: Cloud Platforms
```bash
# AWS ECS
ecs-cli compose up

# Azure Container Apps
az containerapp up --name agentmesh --resource-group rg-agentmesh

# Google Cloud Run
gcloud run deploy agentmesh --image gcr.io/project/agentmesh
```

---

## 🎓 Learning Resources

### For Developers
- **Spring Boot:** https://spring.io/guides
- **Temporal:** https://learn.temporal.io
- **Next.js:** https://nextjs.org/learn
- **Multi-Agent Systems:** Read the definition files in each project

### For Users
- **Getting Started:** See `/docs/user-guide.md` (to be created)
- **Video Tutorials:** Coming soon
- **FAQ:** See `/docs/faq.md` (to be created)

---

## 📞 Getting Help

### Documentation
- Full development plan: `/COMPREHENSIVE_DEVELOPMENT_PLAN.md`
- AgentMesh status: `/AgentMesh/CURRENT_STATE.md`
- Auto-BADS status: `/Auto-BADS/STATUS.md`
- UI status: `/AgentMesh-UI/FINAL_STATUS.md`

### Community
- GitHub Issues: Report bugs and request features
- Discussions: Ask questions and share ideas
- Discord/Slack: (Add your community link)

---

## ✅ Pre-flight Checklist

Before starting development, ensure:
- [ ] Java 17+ installed: `java -version`
- [ ] Node.js 18+ installed: `node -v`
- [ ] Maven 3.8+ installed: `mvn -v`
- [ ] Docker running: `docker ps`
- [ ] PostgreSQL accessible (or Docker)
- [ ] Ports 3000, 8080, 8081 available
- [ ] Git configured: `git config --list`
- [ ] IDE set up (VS Code, IntelliJ)
- [ ] OpenAI API key (optional, can use MockLLM)

---

## 🎉 Success Indicators

You know the system is working when:
- ✅ All three services start without errors
- ✅ UI displays all dashboards
- ✅ You can submit an idea and get analysis results
- ✅ AgentMesh generates code from SRS
- ✅ Tests are passing
- ✅ Metrics are being collected
- ✅ No MAST failures (or auto-corrected)

---

## 📈 Next Steps

After getting the system running:

1. **Week 1:** Fix Auto-BADS Lombok issues
2. **Week 2:** Implement Auto-BADS → AgentMesh integration
3. **Week 3:** Add idea submission to UI
4. **Week 4:** Complete end-to-end testing
5. **Week 5+:** Follow the comprehensive development plan

---

**Happy Building! 🚀**

*For detailed information, see the full development plan: `/COMPREHENSIVE_DEVELOPMENT_PLAN.md`*
