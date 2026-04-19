# Phase 2: UI-Backend Integration Plan
## AgentMesh + Auto-BADS + AgentMesh-UI

**Started:** November 11, 2025  
**Status:** In Progress  
**Goal:** Connect all three systems into a unified platform

---

## Current Status Summary

### ✅ Backend Services (Ready)
- **AgentMesh:** 79/79 tests passing (100%) - Port 8080
- **Auto-BADS:** 127/128 tests passing (99.2%) - Port 8081
- **AgentMesh-UI:** Build successful, all pages functional - Port 3000

### 🎯 Integration Objectives

1. **API Gateway Setup** - Single entry point for all services
2. **Backend Service Integration** - Connect UI to AgentMesh and Auto-BADS
3. **Real-time Updates** - WebSocket integration for live workflow monitoring
4. **Authentication & Authorization** - Unified security across services
5. **Data Synchronization** - Shared state management

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    AgentMesh-UI (Next.js)                        │
│                         Port 3000                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Dashboard  │  │ Orchestration│  │   Analytics  │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└────────────┬──────────────────────────────────────────┬─────────┘
             │                                           │
             │ HTTP/WebSocket                            │ HTTP/WS
             │                                           │
┌────────────▼──────────────────────────────────────────▼─────────┐
│                    API Gateway (Optional)                         │
│              nginx / Spring Cloud Gateway                         │
│                         Port 80/443                               │
└────────────┬──────────────────────────────────────────┬─────────┘
             │                                           │
    ┌────────▼────────┐                        ┌────────▼────────┐
    │   AgentMesh     │                        │   Auto-BADS     │
    │   Port 8080     │                        │   Port 8081     │
    │                 │                        │                 │
    │ REST APIs:      │                        │ REST APIs:      │
    │ /api/agents     │                        │ /api/ideas      │
    │ /api/workflows  │                        │ /api/analysis   │
    │ /api/blackboard │                        │ /api/srs        │
    │ /api/mast       │                        │                 │
    │                 │                        │                 │
    │ WebSocket:      │                        │                 │
    │ /ws/workflow    │                        │                 │
    └─────────────────┘                        └─────────────────┘
             │                                           │
             └───────────────┬───────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │   PostgreSQL    │
                    │   Redis Cache   │
                    │   Weaviate VDB  │
                    └─────────────────┘
```

---

## Phase 2 Tasks

### Task 1: Setup CORS & API Configuration ✅

**Goal:** Allow UI to communicate with backend services

#### 1.1 AgentMesh CORS Configuration
- [ ] Create `WebConfig.java` with CORS settings
- [ ] Allow origins: http://localhost:3000
- [ ] Allow methods: GET, POST, PUT, DELETE, OPTIONS
- [ ] Allow credentials: true
- [ ] Test with curl

#### 1.2 Auto-BADS CORS Configuration
- [ ] Add CORS configuration
- [ ] Same settings as AgentMesh
- [ ] Test with curl

#### 1.3 Update UI Backend Service
- [ ] Configure API base URLs in environment variables
- [ ] Update `backend-service.ts` with proper endpoints
- [ ] Add error handling and retry logic

---

### Task 2: Implement Core API Endpoints

#### 2.1 AgentMesh APIs (Port 8080)

**Agent Management**
```
GET    /api/agents                    # List all agents
GET    /api/agents/{id}               # Get agent details
POST   /api/agents/{id}/execute       # Execute agent task
GET    /api/agents/status             # Get all agent statuses
```

**Workflow Orchestration**
```
POST   /api/workflows/start           # Start new workflow
GET    /api/workflows/{id}            # Get workflow status
POST   /api/workflows/{id}/pause      # Pause workflow
POST   /api/workflows/{id}/resume     # Resume workflow
POST   /api/workflows/{id}/cancel     # Cancel workflow
GET    /api/workflows                 # List all workflows
```

**Blackboard**
```
GET    /api/blackboard/entries        # Get all blackboard entries
GET    /api/blackboard/entries/{type} # Get entries by type
POST   /api/blackboard/entries        # Post new entry
```

**MAST Monitoring**
```
GET    /api/mast/violations           # Get MAST violations
GET    /api/mast/metrics              # Get quality metrics
```

#### 2.2 Auto-BADS APIs (Port 8081)

**Idea Ingestion**
```
POST   /api/ideas/ingest              # Submit new business idea
GET    /api/ideas/{id}                # Get idea status
```

**Analysis**
```
GET    /api/analysis/market/{ideaId}  # Get market analysis
GET    /api/analysis/product/{ideaId} # Get product analysis
GET    /api/analysis/financial/{ideaId} # Get financial analysis
```

**SRS Generation**
```
POST   /api/srs/generate/{ideaId}     # Generate SRS from idea
GET    /api/srs/{id}                  # Get SRS document
GET    /api/srs/{id}/download         # Download SRS as PDF
```

---

### Task 3: WebSocket Integration

#### 3.1 AgentMesh WebSocket
- [ ] Implement `/ws/workflow` endpoint
- [ ] Send real-time workflow updates
- [ ] Send agent status changes
- [ ] Send blackboard updates

#### 3.2 UI WebSocket Client
- [ ] Update `websocket-service.ts`
- [ ] Connect to AgentMesh WebSocket
- [ ] Update workflow store on messages
- [ ] Handle reconnection logic

---

### Task 4: Complete End-to-End Flow

**User Journey:**
1. User submits idea via UI → Auto-BADS
2. Auto-BADS analyzes and generates SRS
3. User reviews SRS in UI
4. User approves → SRS sent to AgentMesh
5. AgentMesh starts workflow
6. UI shows real-time progress via WebSocket
7. User monitors agents, blackboard, MAST violations
8. Workflow completes → Code available for review

#### 4.1 Idea Submission Flow
- [ ] Create "Submit Idea" page in UI
- [ ] Form validation
- [ ] Submit to Auto-BADS API
- [ ] Show analysis progress
- [ ] Display results

#### 4.2 SRS Review Flow
- [ ] SRS viewer component
- [ ] Download SRS functionality
- [ ] Approval/Rejection workflow
- [ ] Send to AgentMesh on approval

#### 4.3 Workflow Monitoring
- [ ] Real-time workflow visualization
- [ ] Agent status cards
- [ ] Blackboard viewer
- [ ] MAST violation alerts

---

### Task 5: Authentication & Multi-Tenancy

#### 5.1 JWT Authentication
- [ ] Implement JWT token generation (AgentMesh)
- [ ] Add login endpoint
- [ ] Secure all APIs with JWT validation
- [ ] Store JWT in UI (httpOnly cookie)

#### 5.2 Tenant Context
- [ ] Add tenant ID to all requests
- [ ] Multi-tenant data isolation
- [ ] Tenant-specific dashboards

---

### Task 6: Testing & Validation

#### 6.1 Integration Tests
- [ ] Test UI → AgentMesh communication
- [ ] Test UI → Auto-BADS communication
- [ ] Test WebSocket connectivity
- [ ] Test error handling

#### 6.2 End-to-End Test
- [ ] Submit real idea through full pipeline
- [ ] Verify SRS generation
- [ ] Verify code generation
- [ ] Verify UI updates

---

## Implementation Order

**Week 1:**
1. ✅ Day 1: CORS configuration
2. Day 2: Core AgentMesh API endpoints
3. Day 3: Core Auto-BADS API endpoints
4. Day 4: UI backend service integration

**Week 2:**
5. Day 5: WebSocket integration
6. Day 6: Idea submission flow
7. Day 7: Workflow monitoring
8. Day 8: Testing & debugging

**Week 3:**
9. Day 9: Authentication setup
10. Day 10: Multi-tenancy
11. Day 11-14: Polish, documentation, deployment

---

## Next Immediate Steps

1. **Create CORS configuration in AgentMesh**
2. **Create REST controllers for missing endpoints**
3. **Update UI environment variables**
4. **Test basic connectivity**

Let's start with Task 1.1!
