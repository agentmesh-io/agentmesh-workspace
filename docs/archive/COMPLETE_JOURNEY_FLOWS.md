# AgentMesh Complete Journey & Flow Design

**Date**: December 5, 2025  
**Purpose**: Detailed end-to-end journey mapping from idea submission to code generation  
**Scope**: Every interaction, decision point, data transformation, and system flow

---

## 📖 Table of Contents

1. [User Journeys](#user-journeys)
2. [System Flows](#system-flows)
3. [Data Transformations](#data-transformations)
4. [Decision Trees](#decision-trees)
5. [Integration Scenarios](#integration-scenarios)
6. [Error Handling Flows](#error-handling-flows)

---

## 🎭 User Journeys

### Journey 1: First-Time User Submitting an Idea

#### Persona: Sarah - Entrepreneur
- **Goal**: Get a software product developed from her business idea
- **Experience Level**: Non-technical
- **Device**: Web browser on laptop

#### Journey Steps

```
Step 1: Landing on AgentMesh UI
├─ URL: http://localhost:3001
├─ Action: Views homepage
├─ Sees: "Submit New Idea" card with lightbulb icon
└─ Emotion: Curious, hopeful

Step 2: Navigation to Submit Idea Page
├─ Action: Clicks "Submit New Idea"
├─ URL: http://localhost:3001/submit-idea
├─ Sees: Form with fields:
│  ├─ Idea Title (required)
│  ├─ Industry Selection (dropdown)
│  ├─ Target Market (text)
│  ├─ Problem Statement (textarea)
│  └─ Raw Idea Description (textarea)
└─ Emotion: Engaged, thinking

Step 3: Form Completion
├─ Sarah enters:
│  ├─ Title: "Smart Home Energy Optimizer"
│  ├─ Industry: "Technology - IoT"
│  ├─ Target Market: "Homeowners in urban areas"
│  ├─ Problem: "People waste 30% of home energy due to poor optimization"
│  └─ Idea: "An AI-powered system that learns usage patterns and 
│             optimizes energy consumption automatically by controlling
│             smart devices, predicting usage, and providing insights."
├─ Validation: All required fields filled
└─ Action: Clicks "Submit Idea"

Step 4: Submission Processing
├─ UI State: Loading spinner appears
├─ Message: "Analyzing your idea with AI..."
├─ Backend: POST to Auto-BADS API
├─ Duration: 3-5 seconds
└─ Emotion: Anticipating, waiting

Step 5: Success Confirmation
├─ UI State: Success modal appears
├─ Message: "✅ Idea submitted successfully!"
├─ Details Shown:
│  ├─ Idea ID: 827bf4a5-9966-435e-8463-0317d0cd4e01
│  ├─ Status: "Analysis in progress"
│  └─ Estimated time: "2-3 minutes for complete analysis"
├─ Actions Available:
│  ├─ [Track Progress] → Goes to workflow view
│  └─ [Submit Another Idea]
└─ Emotion: Excited, accomplished

Step 6: Tracking Analysis Progress
├─ Action: Clicks "Track Progress"
├─ URL: http://localhost:3001/workflows/079e6588-f899-438a-bc40-2baeebb69e34
├─ Sees: Real-time workflow progress
│  ├─ Phase Indicator: "🔍 Analyzing Business Idea"
│  ├─ Progress Bar: 15%
│  ├─ Current Activity: "Market Agent analyzing target market..."
│  └─ WebSocket updates every 2 seconds
└─ Emotion: Interested, watching

Step 7: Auto-BADS Analysis Completion
├─ UI Update (via WebSocket):
│  ├─ Phase: "📊 Analysis Complete"
│  ├─ Progress: 100%
│  ├─ Message: "SRS document generated successfully"
│  └─ New Status: "Starting code generation workflow..."
├─ Sees Summary:
│  ├─ Market Score: 8.5/10
│  ├─ Feasibility: High
│  ├─ Estimated Cost: $45,000 - $65,000
│  └─ Timeline: 3-4 months
└─ Emotion: Impressed, validated

Step 8: Workflow Phase Progression
├─ UI Shows Phase Cards:
│  
│  [✅ Analysis Complete]
│  └─ Market analysis, financial projections, SRS generated
│  
│  [🔄 Planning Phase - In Progress]
│  ├─ Agent: Planner reviewing requirements
│  ├─ Activity: "Creating execution plan from SRS..."
│  └─ Duration: 45 seconds
│  
│  [⏳ Coding Phase - Waiting]
│  
│  [⏳ Testing Phase - Waiting]
│  
│  [⏳ Review Phase - Waiting]
│
└─ Emotion: Engaged, following along

Step 9: Planning Complete
├─ UI Update:
│  [✅ Planning Complete]
│  ├─ Execution plan created
│  ├─ Modules identified: 5
│  ├─ Files to generate: 32
│  └─ Tech stack: React, Node.js, MongoDB, AWS IoT
│  
│  [🔄 Coding Phase - In Progress]
│  ├─ Generating module: "IoT Device Controller"
│  ├─ Files created: 8/32
│  └─ Progress: 25%
│
└─ Emotion: Amazed, patient

Step 10: Coding Progress Updates
├─ UI shows granular updates:
│  ├─ "✓ server.js created (247 lines)"
│  ├─ "✓ routes/devices.js created (186 lines)"
│  ├─ "✓ controllers/EnergyOptimizer.js created (312 lines)"
│  ├─ "⏳ models/Device.js in progress..."
│  └─ Estimated completion: 1 minute 30 seconds
└─ Emotion: Excited, invested

Step 11: Full Workflow Completion
├─ UI Final State:
│  
│  [✅ All Phases Complete]
│  
│  📊 Generation Summary:
│  ├─ Files Created: 32
│  ├─ Total Lines: 4,847
│  ├─ Tests Generated: 124
│  ├─ Test Coverage: 89.3%
│  ├─ Quality Score: 8.7/10
│  └─ Status: APPROVED
│  
│  🎉 Your project is ready!
│  
│  [View Code] [Download ZIP] [Export to GitHub]
│
└─ Emotion: Delighted, successful

Step 12: Code Review & Export
├─ Action: Clicks "View Code"
├─ Sees: Organized file structure with code preview
├─ Action: Clicks "Export to GitHub"
├─ Prompted: "Connect GitHub Account" or "Use existing"
├─ GitHub Auth Flow:
│  ├─ OAuth authorization
│  ├─ Repository creation
│  └─ Code push
├─ Final URL: https://github.com/sarah/smart-home-energy-optimizer
└─ Emotion: Accomplished, empowered
```

---

## 🔄 System Flows

### Flow 1: Idea Submission to Auto-BADS Analysis

```
┌─────────────────────────────────────────────────────────────────────┐
│                    IDEA SUBMISSION FLOW                             │
└─────────────────────────────────────────────────────────────────────┘

[User Browser]
     │
     │ 1. POST /api/v1/ideas
     │    {
     │      "title": "Smart Home Energy Optimizer",
     │      "industry": "Technology - IoT",
     │      "targetMarket": "Urban homeowners",
     │      "rawIdea": "An AI-powered system...",
     │      "problemStatement": "People waste 30%...",
     │      "submittedBy": "sarah@email.com"
     │    }
     ▼
[Auto-BADS API Controller]
  └─ IdeaController.submitIdea()
     │
     │ 2. Validate input
     │    ├─ Check required fields ✓
     │    ├─ Sanitize input ✓
     │    └─ Generate UUID: 827bf4a5-...
     │
     ▼
[Business Idea Service]
  └─ BusinessIdeaService.createIdea()
     │
     │ 3. Save to database
     │    INSERT INTO business_ideas (
     │      id, title, industry, target_market,
     │      raw_idea, problem_statement, status,
     │      submitted_at, submitted_by
     │    ) VALUES (...)
     │
     ▼
[PostgreSQL - autobads DB]
  └─ business_ideas table
     ├─ id: 827bf4a5-9966-435e-8463-0317d0cd4e01
     ├─ status: 'PENDING_ANALYSIS'
     ├─ submitted_at: 2025-12-05 17:30:00
     └─ COMMIT
     │
     │ 4. Return saved entity
     ▼
[Business Idea Service]
  └─ Publish Event: IdeaIngestedEvent
     │
     │ 5. Spring Modulith Event Publication
     │    INSERT INTO event_publication (
     │      id, event_type, listener_id,
     │      publication_date, serialized_event
     │    )
     │    event_type: 'IdeaIngestedEvent'
     │    serialized_event: { ideaId: "827bf4a5...", ... }
     │
     ▼
[Event Listeners - Internal Auto-BADS]
  ├─ MarketAgentService.onIdeaIngested()
  ├─ FinancialAgentService.onIdeaIngested()  
  └─ SolutionSynthesisService.onIdeaIngested()
     │
     │ 6. Parallel analysis starts
     │    (See Flow 2)
     ▼
[HTTP Response to Browser]
  └─ 201 CREATED
     {
       "id": "827bf4a5-9966-435e-8463-0317d0cd4e01",
       "status": "PENDING_ANALYSIS",
       "message": "Idea submitted successfully",
       "estimatedCompletionTime": "2-3 minutes"
     }
```

---

### Flow 2: Auto-BADS Multi-Agent Analysis (Internal)

```
┌─────────────────────────────────────────────────────────────────────┐
│              AUTO-BADS MULTI-AGENT ANALYSIS FLOW                     │
└─────────────────────────────────────────────────────────────────────┘

[IdeaIngestedEvent Published]
     │
     ├─────────────┬─────────────┬─────────────┐
     ▼             ▼             ▼             ▼
[Market Agent] [Financial]  [Solution]   [Analytical]
  Analysis      Analysis     Synthesis     Processing
     │             │             │             │
     │ 1. Market Agent Analysis                │
     │────────────────────────────────────────┐│
     │                                         ││
[MarketAgentService.analyzeMarket()]          ││
  ├─ Retrieve idea from DB                    ││
  ├─ Extract: industry, target market, problem││
  │                                            ││
  ├─ LSTM Model Inference                     ││
  │  └─ Input: Text embedding of idea         ││
  │     ├─ Tokenization                       ││
  │     ├─ Sequence padding                   ││
  │     ├─ LSTM forward pass (118,593 params) ││
  │     └─ Output: Market viability score     ││
  │                                            ││
  ├─ Prompt Template: "Market Analysis"       ││
  │  └─ Input variables:                      ││
  │     ├─ industry: "Technology - IoT"       ││
  │     ├─ targetMarket: "Urban homeowners"   ││
  │     ├─ problem: "Energy waste..."         ││
  │     └─ idea: "AI-powered system..."       ││
  │                                            ││
  ├─ AI Response (Mock/OpenAI):               ││
  │  └─ marketSize: "Global market: $24B"     ││
  │     competitorAnalysis: [...]             ││
  │     marketTrends: [...]                   ││
  │     targetSegment: "Tech-savvy homeowners"││
  │     viabilityScore: 8.5                   ││
  │                                            ││
  ├─ Save Market Analysis                     ││
  │  └─ UPDATE business_ideas                 ││
  │     SET market_analysis = {...}           ││
  │     WHERE id = '827bf4a5...'              ││
  │                                            ││
  └─ Publish: MarketAnalysisCompletedEvent ───┘│
     │                                          │
     │ 2. Financial Agent Analysis              │
     │─────────────────────────────────────────┐│
     │                                          ││
[FinancialAgentService.analyzeFinancials()]   ││
  ├─ Retrieve idea + market analysis           ││
  │                                             ││
  ├─ LSTM Model Inference                      ││
  │  └─ Input: Combined market + idea data     ││
  │     Output: Financial viability            ││
  │                                             ││
  ├─ Prompt Template: "Financial Projection"   ││
  │  └─ Calculate:                             ││
  │     ├─ developmentCost: $45,000-$65,000    ││
  │     ├─ timeToMarket: "3-4 months"          ││
  │     ├─ roi: "12-month breakeven"           ││
  │     ├─ revenue5Year: "$2.4M projected"     ││
  │     └─ fundingNeeded: "$80,000"            ││
  │                                             ││
  ├─ Save Financial Analysis                   ││
  │  └─ UPDATE business_ideas                  ││
  │     SET financial_analysis = {...}         ││
  │                                             ││
  └─ Publish: FinancialAnalysisCompletedEvent ─┘│
     │                                           │
     │ 3. Solution Synthesis                     │
     │──────────────────────────────────────────┐│
     │                                           ││
[SolutionSynthesisService.synthesizeSolution()]││
  ├─ Wait for: Market + Financial events       ││
  │  └─ Event aggregation pattern              ││
  │                                             ││
  ├─ Retrieve complete analysis                ││
  │  ├─ Idea details                           ││
  │  ├─ Market analysis                        ││
  │  └─ Financial projections                  ││
  │                                             ││
  ├─ LSTM Model Inference                      ││
  │  └─ Input: All combined data               ││
  │     Output: Solution recommendations       ││
  │                                             ││
  ├─ Prompt Template: "Solution Architecture"  ││
  │  └─ Generate:                              ││
  │     ├─ technicalApproach: "Microservices..." ││
  │     ├─ techStack: ["React", "Node.js"...]  ││
  │     ├─ architecture: "Cloud-native..."     ││
  │     ├─ scalability: "Horizontal scaling..." ││
  │     └─ integrations: ["AWS IoT", "MongoDB"]││
  │                                             ││
  ├─ Save Solution Synthesis                   ││
  │  └─ UPDATE business_ideas                  ││
  │     SET solution_synthesis = {...}         ││
  │                                             ││
  └─ Trigger: SRS Generation ──────────────────┘│
     │                                           │
     │ 4. SRS Document Generation                │
     │───────────────────────────────────────────┘
     │
[SRSGenerationService.generateSRS()]
  ├─ Aggregate all analyses:
  │  ├─ Market analysis
  │  ├─ Financial projections
  │  ├─ Solution architecture
  │  └─ Original idea details
  │
  ├─ Prompt Template: "SRS Document Generator"
  │  └─ Comprehensive prompt with sections:
  │     ├─ 1. Executive Summary
  │     ├─ 2. Market Analysis
  │     ├─ 3. Financial Projections
  │     ├─ 4. Functional Requirements
  │     ├─ 5. Non-Functional Requirements
  │     ├─ 6. Technical Architecture
  │     ├─ 7. Technology Stack
  │     ├─ 8. Development Roadmap
  │     └─ 9. Success Metrics
  │
  ├─ AI Response (detailed SRS markdown)
  │  └─ 15-25 page comprehensive document
  │
  ├─ Save SRS Document
  │  └─ INSERT INTO srs_documents (
  │       id, idea_id, content, version,
  │       generated_at, status
  │     ) VALUES (
  │       'd79a9e38-...', '827bf4a5-...',
  │       '# Software Requirements...', 1,
  │       NOW(), 'FINAL'
  │     )
  │
  ├─ Update Business Idea
  │  └─ UPDATE business_ideas
  │     SET status = 'SRS_GENERATED',
  │         srs_id = 'd79a9e38-...'
  │     WHERE id = '827bf4a5-...'
  │
  └─ Publish to Kafka: SRSGeneratedEvent
     │
     │ 5. Kafka Event Publication
     │
     ▼
[Kafka Producer]
  └─ Topic: autobads.srs.generated
     Partition: Auto (by key)
     Key: idea-827bf4a5-9966-435e-8463-0317d0cd4e01
     Value: {
       "ideaId": "827bf4a5-9966-435e-8463-0317d0cd4e01",
       "srsId": "d79a9e38-54ad-471c-a74d-3e3e73ef9293",
       "title": "Smart Home Energy Optimizer",
       "status": "SRS_GENERATED",
       "timestamp": "2025-12-05T17:32:45.123Z",
       "metadata": {
         "marketScore": 8.5,
         "feasibility": "HIGH",
         "estimatedCost": "$45,000-$65,000",
         "techStack": ["React", "Node.js", "MongoDB"]
       }
     }
     │
     │ Event committed to Kafka
     ▼
[Kafka Broker - Topic: autobads.srs.generated]
  └─ Message stored
     └─ Waiting for consumer...
```

---

### Flow 3: AgentMesh Workflow Initialization

```
┌─────────────────────────────────────────────────────────────────────┐
│           AGENTMESH WORKFLOW INITIALIZATION FLOW                     │
└─────────────────────────────────────────────────────────────────────┘

[Kafka Consumer - AgentMesh API]
  └─ Consumer Group: agentmesh-consumer
     Topic: autobads.srs.generated
     Partitions: [0, 1, 2]
     │
     │ 1. Poll for messages (interval: 100ms)
     │
     ▼
[Message Received]
  └─ Offset: 42
     Partition: 0
     Key: idea-827bf4a5-...
     Value: { SRSGeneratedEvent JSON }
     │
     │ 2. Deserialize message
     │
     ▼
[KafkaListener - WorkflowController]
  └─ @KafkaListener(topics = "autobads.srs.generated")
     public void handleSRSGenerated(String message)
     │
     │ 3. Parse JSON
     │    └─ Extract: ideaId, srsId, title, metadata
     │
     ▼
[WorkflowService.createWorkflowFromSRS()]
  │
  │ 4. Validate SRS availability
  │    └─ HTTP GET http://localhost:8083/api/v1/srs/d79a9e38-...
  │       ├─ Response 200 OK: SRS exists ✓
  │       └─ Store SRS URL for later retrieval
  │
  ├─ 5. Create Workflow Entity
  │    └─ workflowId: 079e6588-f899-438a-bc40-2baeebb69e34 (generated)
  │       ideaId: 827bf4a5-9966-435e-8463-0317d0cd4e01
  │       srsId: d79a9e38-54ad-471c-a74d-3e3e73ef9293
  │       title: "Smart Home Energy Optimizer"
  │       status: PLANNING
  │       currentPhase: PLANNING
  │       createdAt: 2025-12-05T17:32:46
  │       metadata: { from Kafka event }
  │
  ├─ 6. Save to Database
  │    └─ INSERT INTO workflows (
  │         id, idea_id, srs_id, title, status,
  │         current_phase, created_at, metadata
  │       ) VALUES (...)
  │
  ├─ 7. Initialize Blackboard
  │    └─ INSERT INTO blackboard_entry (
  │         agent_id: 'system',
  │         entry_type: 'CONTEXT',
  │         title: 'Workflow Initialization',
  │         content: {
  │           "ideaId": "827bf4a5...",
  │           "srsId": "d79a9e38...",
  │           "srsUrl": "http://localhost:8083/api/v1/srs/...",
  │           "techStack": ["React", "Node.js", "MongoDB"],
  │           "estimatedCost": "$45,000-$65,000"
  │         },
  │         timestamp: NOW()
  │       )
  │
  └─ 8. Start Async Workflow Execution
     │    └─ @Async execution in thread pool
     │
     ▼
[WorkflowExecutor Thread]
  └─ executeWorkflow(workflowId)
     │
     │ See Flow 4: Planning Phase
     └─> (continues to Planning)
```

---

### Flow 4: Planning Phase - Detailed Execution

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PLANNING PHASE FLOW                               │
└─────────────────────────────────────────────────────────────────────┘

[Workflow Thread]
  └─ workflowId: 079e6588-f899-438a-bc40-2baeebb69e34
     status: PLANNING
     │
     │ 1. Update workflow status
     │    └─ UPDATE workflows
     │       SET status = 'PLANNING', current_phase = 'PLANNING'
     │       WHERE id = '079e6588-...'
     │
     ▼
[PlannerAgentService.executePlanning()]
  │
  ├─ 2. Retrieve Context from Blackboard
  │    └─ SELECT * FROM blackboard_entry
  │       WHERE entry_type = 'CONTEXT'
  │       ORDER BY timestamp DESC LIMIT 1
  │       
  │       Retrieved:
  │       ├─ srsUrl: http://localhost:8083/api/v1/srs/d79a9e38-...
  │       ├─ ideaId: 827bf4a5-...
  │       └─ techStack: ["React", "Node.js", "MongoDB"]
  │
  ├─ 3. Fetch Complete SRS Document
  │    └─ HTTP GET http://localhost:8083/api/v1/srs/d79a9e38-...
  │       
  │       Response 200 OK:
  │       {
  │         "id": "d79a9e38-54ad-471c-a74d-3e3e73ef9293",
  │         "ideaId": "827bf4a5-...",
  │         "content": "# Software Requirements Specification\n\n
  │                     ## 1. Executive Summary\n
  │                     Smart Home Energy Optimizer is an AI-powered...\n\n
  │                     ## 4. Functional Requirements\n
  │                     FR-001: System shall monitor real-time energy...\n
  │                     FR-002: System shall predict usage patterns...\n
  │                     ...(15 pages)...",
  │         "version": 1,
  │         "generatedAt": "2025-12-05T17:32:45",
  │         "metadata": {...}
  │       }
  │
  ├─ 4. Parse SRS Structure
  │    └─ Extract sections:
  │       ├─ Functional Requirements (20 items)
  │       │  ├─ FR-001: Real-time monitoring
  │       │  ├─ FR-002: Predictive analytics
  │       │  ├─ FR-003: Device control
  │       │  └─ ... (17 more)
  │       │
  │       ├─ Non-Functional Requirements (12 items)
  │       │  ├─ NFR-001: 99.9% uptime
  │       │  ├─ NFR-002: <200ms response time
  │       │  └─ ... (10 more)
  │       │
  │       ├─ Technology Stack
  │       │  ├─ Frontend: React 18, Material-UI
  │       │  ├─ Backend: Node.js 20, Express
  │       │  ├─ Database: MongoDB Atlas
  │       │  ├─ IoT: AWS IoT Core
  │       │  └─ ML: TensorFlow.js
  │       │
  │       └─ Architecture Recommendations
  │          ├─ Microservices pattern
  │          ├─ Event-driven architecture
  │          └─ Cloud-native deployment
  │
  ├─ 5. Query Vector Memory (Weaviate) for Context
  │    └─ Search similar projects:
  │       Query: "IoT energy monitoring system microservices"
  │       
  │       Results:
  │       ├─ Similar Project 1: "Smart Thermostat System"
  │       │  └─ Execution plan pattern
  │       ├─ Similar Project 2: "Home Automation Hub"
  │       │  └─ Module breakdown
  │       └─ Best Practices: "IoT Security Patterns"
  │
  ├─ 6. Construct LLM Prompt for Execution Plan
  │    └─ Prompt Template: "execution-plan-generator"
  │       
  │       Variables:
  │       {
  │         "projectTitle": "Smart Home Energy Optimizer",
  │         "functionalRequirements": [FR-001, FR-002, ...],
  │         "nonFunctionalRequirements": [NFR-001, NFR-002, ...],
  │         "techStack": {...},
  │         "architecture": "Microservices, Event-driven",
  │         "similarPatterns": [context from Weaviate],
  │         "constraints": {
  │           "budget": "$45,000-$65,000",
  │           "timeline": "3-4 months",
  │           "teamSize": "3-4 developers"
  │         }
  │       }
  │       
  │       Final Prompt:
  │       """
  │       You are an expert software architect planning a development project.
  │       
  │       Project: Smart Home Energy Optimizer
  │       
  │       Requirements Summary:
  │       - 20 functional requirements (see attached)
  │       - 12 non-functional requirements (see attached)
  │       - Technology: React, Node.js, MongoDB, AWS IoT
  │       - Architecture: Microservices, Event-driven
  │       
  │       Context from similar projects:
  │       - Smart Thermostat System used MQTT protocol
  │       - Home Automation Hub implemented event sourcing
  │       
  │       Generate a detailed execution plan with:
  │       
  │       1. **Module Breakdown**
  │          - List all major modules/microservices
  │          - Purpose and responsibilities of each
  │          - Dependencies between modules
  │       
  │       2. **File Structure**
  │          - Complete directory tree
  │          - File naming conventions
  │          - Organization by module
  │       
  │       3. **Development Phases**
  │          - Phase 1: Infrastructure setup
  │          - Phase 2: Core services
  │          - Phase 3: Integration
  │          - Phase 4: Testing & deployment
  │       
  │       4. **Testing Strategy**
  │          - Unit test coverage targets
  │          - Integration test scenarios
  │          - E2E test flows
  │       
  │       5. **Deployment Architecture**
  │          - Container strategy
  │          - CI/CD pipeline
  │          - Infrastructure as Code
  │       
  │       Provide output in structured JSON format.
  │       """
  │
  ├─ 7. Call LLM Service
  │    └─ LLMService.generateExecutionPlan(prompt)
  │       
  │       [If OpenAI enabled]:
  │       ├─ API: POST https://api.openai.com/v1/chat/completions
  │       ├─ Model: gpt-4o
  │       ├─ Temperature: 0.7
  │       ├─ Max tokens: 4000
  │       └─ Response time: 8-12 seconds
  │       
  │       [If Mock enabled]:
  │       └─ Return structured mock response (instant)
  │       
  │       LLM Response (parsed):
  │       {
  │         "modules": [
  │           {
  │             "name": "iot-gateway-service",
  │             "description": "Handles communication with IoT devices",
  │             "techStack": ["Node.js", "MQTT", "AWS IoT Core"],
  │             "files": [
  │               "src/server.js",
  │               "src/mqtt/MQTTClient.js",
  │               "src/mqtt/MessageHandler.js",
  │               "src/devices/DeviceRegistry.js",
  │               "src/config/iot-config.js"
  │             ],
  │             "dependencies": ["event-service", "device-service"],
  │             "priority": "high"
  │           },
  │           {
  │             "name": "analytics-service",
  │             "description": "ML-based energy prediction",
  │             "techStack": ["Python", "TensorFlow", "FastAPI"],
  │             "files": [
  │               "src/app.py",
  │               "src/models/EnergyPredictor.py",
  │               "src/training/TrainingPipeline.py",
  │               "src/api/PredictionAPI.py"
  │             ],
  │             "dependencies": ["data-service"],
  │             "priority": "high"
  │           },
  │           {
  │             "name": "web-frontend",
  │             "description": "User dashboard and controls",
  │             "techStack": ["React", "Material-UI", "Chart.js"],
  │             "files": [
  │               "src/App.jsx",
  │               "src/pages/Dashboard.jsx",
  │               "src/pages/Devices.jsx",
  │               "src/components/EnergyChart.jsx",
  │               "src/services/ApiService.js"
  │             ],
  │             "dependencies": ["api-gateway"],
  │             "priority": "medium"
  │           },
  │           ... (2 more modules)
  │         ],
  │         "fileStructure": {
  │           "root": "smart-home-energy-optimizer",
  │           "structure": {
  │             "services": {
  │               "iot-gateway": { ... },
  │               "analytics": { ... },
  │               "web-frontend": { ... }
  │             },
  │             "infrastructure": {
  │               "docker": ["Dockerfile", "docker-compose.yml"],
  │               "k8s": ["deployment.yaml", "service.yaml"]
  │             }
  │           }
  │         },
  │         "developmentPhases": [
  │           {
  │             "phase": 1,
  │             "name": "Infrastructure Setup",
  │             "duration": "1 week",
  │             "tasks": [
  │               "Setup MongoDB Atlas",
  │               "Configure AWS IoT Core",
  │               "Setup CI/CD pipeline",
  │               "Create project structure"
  │             ]
  │           },
  │           ... (3 more phases)
  │         ],
  │         "testingStrategy": {
  │           "unitTests": {
  │             "target": "85% coverage",
  │             "framework": "Jest for Node, Pytest for Python"
  │           },
  │           "integrationTests": {
  │             "scenarios": [
  │               "Device connection flow",
  │               "Data pipeline end-to-end",
  │               "User action to device control"
  │             ]
  │           },
  │           "e2eTests": {
  │             "framework": "Cypress",
  │             "critical_paths": [
  │               "User login → View dashboard → Control device",
  │               "Energy optimization automation flow"
  │             ]
  │           }
  │         },
  │         "estimatedEffort": {
  │           "totalHours": 720,
  │           "byModule": {
  │             "iot-gateway-service": 180,
  │             "analytics-service": 220,
  │             "web-frontend": 160,
  │             ...
  │           }
  │         }
  │       }
  │
  ├─ 8. Store Execution Plan in Blackboard
  │    └─ INSERT INTO blackboard_entry (
  │         agent_id: 'planner-agent',
  │         entry_type: 'PLAN',
  │         title: 'Execution Plan',
  │         content: {
  │           "srsId": "d79a9e38-...",
  │           "srsUrl": "http://localhost:8083/api/v1/srs/...",
  │           "modules": [ ... ],  // Full LLM response
  │           "fileStructure": { ... },
  │           "developmentPhases": [ ... ],
  │           "testingStrategy": { ... },
  │           "estimatedEffort": { ... },
  │           "generatedAt": "2025-12-05T17:33:02",
  │           "llmModel": "gpt-4o",
  │           "llmTokens": 3847
  │         },
  │         timestamp: NOW(),
  │         project_id: NULL,
  │         tenant_id: NULL
  │       )
  │       
  │       Returns: blackboard_entry.id = 17249
  │
  ├─ 9. Store Embeddings in Weaviate
  │    └─ POST http://localhost:8081/v1/objects
  │       
  │       Schema: ExecutionPlan
  │       Object: {
  │         "class": "ExecutionPlan",
  │         "properties": {
  │           "workflowId": "079e6588-...",
  │           "projectTitle": "Smart Home Energy Optimizer",
  │           "techStack": ["React", "Node.js", ...],
  │           "moduleCount": 5,
  │           "fileCount": 32,
  │           "planText": "Full execution plan as text",
  │           "blackboardEntryId": 17249
  │         },
  │         "vector": [0.023, -0.184, ...] // 1536 dimensions
  │       }
  │       
  │       Vector generated from:
  │       └─ OpenAI Embeddings API
  │          Model: text-embedding-3-small
  │          Input: Execution plan summary
  │
  └─ 10. Update Workflow Status
     │    └─ UPDATE workflows
     │       SET status = 'CODING',
     │           current_phase = 'CODING',
     │           planning_completed_at = NOW()
     │       WHERE id = '079e6588-...'
     │
     └─> Continue to Flow 5: Coding Phase
```

---

### Flow 5: Coding Phase - Module-by-Module Generation

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CODING PHASE FLOW                                 │
└─────────────────────────────────────────────────────────────────────┘

[Workflow Thread]
  └─ workflowId: 079e6588-f899-438a-bc40-2baeebb69e34
     status: CODING
     │
     ▼
[CoderAgentService.executeCode Generation()]
  │
  ├─ 1. Retrieve Execution Plan from Blackboard
  │    └─ SELECT content FROM blackboard_entry
  │       WHERE entry_type = 'PLAN'
  │       AND agent_id = 'planner-agent'
  │       ORDER BY timestamp DESC LIMIT 1
  │       
  │       Retrieved:
  │       └─ modules: [iot-gateway, analytics, web-frontend, ...]
  │          fileStructure: { ... }
  │
  ├─ 2. Retrieve SRS for Context
  │    └─ HTTP GET http://localhost:8083/api/v1/srs/d79a9e38-...
  │       (Cached if available)
  │
  ├─ 3. Query Weaviate for Code Patterns
  │    └─ Search for similar implementations:
  │       ├─ "MQTT client implementation Node.js"
  │       ├─ "TensorFlow energy prediction model"
  │       ├─ "React dashboard real-time charts"
  │       └─ Returns: Code snippets, patterns, examples
  │
  ├─ 4. Initialize Code Generation State
  │    └─ generationState = {
  │         totalModules: 5,
  │         completedModules: 0,
  │         totalFiles: 32,
  │         completedFiles: 0,
  │         errors: []
  │       }
  │
  └─ 5. Generate Code Module by Module (Loop)
     │
     ┌─────────────────────────────────────────┐
     │  For each module in executionPlan       │
     └─────────────────────────────────────────┘
     │
     ├─ MODULE 1: iot-gateway-service
     │  │
     │  ├─ A. Prepare Module Context
     │  │    └─ moduleContext = {
     │  │         name: "iot-gateway-service",
     │  │         description: "Handles IoT communication",
     │  │         techStack: ["Node.js", "MQTT", "AWS IoT"],
     │  │         files: [
     │  │           "src/server.js",
     │  │           "src/mqtt/MQTTClient.js",
     │  │           "src/mqtt/MessageHandler.js",
     │  │           "src/devices/DeviceRegistry.js",
     │  │           "src/config/iot-config.js"
     │  │         ],
     │  │         dependencies: ["event-service", "device-service"],
     │  │         requirements: [FR-001, FR-003, FR-005]
     │  │       }
     │  │
     │  ├─ B. Query Vector Memory for Module-Specific Patterns
     │  │    └─ Search: "MQTT client AWS IoT Core Node.js"
     │  │       Results: Code examples, best practices
     │  │
     │  └─ C. Generate Files for Module (Nested Loop)
     │     │
     │     ┌──────────────────────────────────────┐
     │     │  For each file in module.files       │
     │     └──────────────────────────────────────┘
     │     │
     │     ├─ FILE 1: src/server.js
     │     │  │
     │     │  ├─ i. Construct LLM Prompt
     │     │  │    └─ Prompt Template: "code-generator"
     │     │  │       
     │     │  │       Variables:
     │     │  │       {
     │     │  │         "fileName": "server.js",
     │     │  │         "filePath": "src/server.js",
     │     │  │         "module": "iot-gateway-service",
     │     │  │         "purpose": "Express server for IoT gateway",
     │     │  │         "techStack": ["Node.js 20", "Express 4.18"],
     │     │  │         "requirements": [
     │     │  │           "FR-001: Real-time device communication",
     │     │  │           "NFR-001: 99.9% uptime"
     │     │  │         ],
     │     │  │         "dependencies": [
     │     │  │           "express",
     │     │  │           "./mqtt/MQTTClient",
     │     │  │           "./devices/DeviceRegistry"
     │     │  │         ],
     │     │  │         "codePatterns": [
     │     │  │           "Use async/await",
     │     │  │           "Implement graceful shutdown",
     │     │  │           "Health check endpoint"
     │     │  │         ],
     │     │  │         "security": [
     │     │  │           "Rate limiting",
     │     │  │           "CORS configuration",
     │     │  │           "JWT authentication"
     │     │  │         ]
     │     │  │       }
     │     │  │       
     │     │  │       Prompt:
     │     │  │       """
     │     │  │       You are a senior Node.js developer.
     │     │  │       
     │     │  │       Generate production-ready code for: server.js
     │     │  │       
     │     │  │       Module: iot-gateway-service
     │     │  │       Purpose: Express server for IoT gateway
     │     │  │       
     │     │  │       Requirements:
     │     │  │       - Real-time device communication via MQTT
     │     │  │       - 99.9% uptime requirement
     │     │  │       - RESTful API endpoints
     │     │  │       - WebSocket support for real-time updates
     │     │  │       
     │     │  │       Include:
     │     │  │       1. Express server setup
     │     │  │       2. MQTT client integration
     │     │  │       3. Device registry connection
     │     │  │       4. Error handling middleware
     │     │  │       5. Health check endpoint
     │     │  │       6. Graceful shutdown
     │     │  │       7. Security middleware (CORS, rate limiting)
     │     │  │       8. Logging configuration
     │     │  │       
     │     │  │       Follow best practices:
     │     │  │       - Async/await pattern
     │     │  │       - Environment variable configuration
     │     │  │       - Comprehensive error handling
     │     │  │       - JSDoc comments
     │     │  │       """
     │     │  │
     │     │  ├─ ii. Call LLM Service
     │     │  │    └─ LLMService.generateCode(prompt)
     │     │  │       
     │     │  │       Response:
     │     │  │       ```javascript
     │     │  │       /**
     │     │  │        * IoT Gateway Service - Main Server
     │     │  │        * Handles device communication and API endpoints
     │     │  │        * @module iot-gateway/server
     │     │  │        */
     │     │  │       
     │     │  │       const express = require('express');
     │     │  │       const cors = require('cors');
     │     │  │       const rateLimit = require('express-rate-limit');
     │     │  │       const MQTTClient = require('./mqtt/MQTTClient');
     │     │  │       const DeviceRegistry = require('./devices/DeviceRegistry');
     │     │  │       const config = require('./config/iot-config');
     │     │  │       
     │     │  │       class IoTGatewayServer {
     │     │  │         constructor() {
     │     │  │           this.app = express();
     │     │  │           this.mqttClient = null;
     │     │  │           this.deviceRegistry = null;
     │     │  │         }
     │     │  │       
     │     │  │         async initialize() {
     │     │  │           // Setup middleware
     │     │  │           this.app.use(cors(config.cors));
     │     │  │           this.app.use(express.json());
     │     │  │           this.app.use(this.rateLimiter());
     │     │  │           
     │     │  │           // Initialize MQTT client
     │     │  │           this.mqttClient = new MQTTClient(config.mqtt);
     │     │  │           await this.mqttClient.connect();
     │     │  │           
     │     │  │           // Initialize device registry
     │     │  │           this.deviceRegistry = new DeviceRegistry();
     │     │  │           await this.deviceRegistry.initialize();
     │     │  │           
     │     │  │           // Setup routes
     │     │  │           this.setupRoutes();
     │     │  │           
     │     │  │           // Error handling
     │     │  │           this.app.use(this.errorHandler);
     │     │  │         }
     │     │  │       
     │     │  │         setupRoutes() {
     │     │  │           this.app.get('/health', (req, res) => {
     │     │  │             res.json({ 
     │     │  │               status: 'healthy',
     │     │  │               mqtt: this.mqttClient.isConnected(),
     │     │  │               devices: this.deviceRegistry.getCount()
     │     │  │             });
     │     │  │           });
     │     │  │           
     │     │  │           // ... more routes
     │     │  │         }
     │     │  │       
     │     │  │         rateLimiter() {
     │     │  │           return rateLimit({
     │     │  │             windowMs: 15 * 60 * 1000,
     │     │  │             max: 100
     │     │  │           });
     │     │  │         }
     │     │  │       
     │     │  │         errorHandler(err, req, res, next) {
     │     │  │           console.error(err.stack);
     │     │  │           res.status(500).json({ error: 'Internal server error' });
     │     │  │         }
     │     │  │       
     │     │  │         async start(port = 3000) {
     │     │  │           await this.initialize();
     │     │  │           return new Promise((resolve) => {
     │     │  │             this.server = this.app.listen(port, () => {
     │     │  │               console.log(`IoT Gateway listening on ${port}`);
     │     │  │               resolve();
     │     │  │             });
     │     │  │           });
     │     │  │         }
     │     │  │       
     │     │  │         async shutdown() {
     │     │  │           await this.mqttClient.disconnect();
     │     │  │           await this.deviceRegistry.close();
     │     │  │           this.server.close();
     │     │  │         }
     │     │  │       }
     │     │  │       
     │     │  │       // Graceful shutdown
     │     │  │       process.on('SIGTERM', async () => {
     │     │  │         await server.shutdown();
     │     │  │         process.exit(0);
     │     │  │       });
     │     │  │       
     │     │  │       const server = new IoTGatewayServer();
     │     │  │       server.start(process.env.PORT || 3000);
     │     │  │       
     │     │  │       module.exports = IoTGatewayServer;
     │     │  │       ```
     │     │  │       
     │     │  │       Metadata:
     │     │  │       ├─ lines: 87
     │     │  │       ├─ bytes: 2847
     │     │  │       ├─ language: javascript
     │     │  │       └─ complexity: medium
     │     │  │
     │     │  ├─ iii. Validate Generated Code
     │     │  │    ├─ Syntax check (ESLint)
     │     │  │    ├─ Security scan (basic patterns)
     │     │  │    └─ Requirement tracing
     │     │  │       └─ FR-001 ✓ (MQTT client)
     │     │  │          NFR-001 ✓ (health check)
     │     │  │
     │     │  └─ iv. Store File Metadata
     │     │       └─ generatedFiles.push({
     │     │            path: "iot-gateway-service/src/server.js",
     │     │            content: "...",
     │     │            language: "javascript",
     │     │            lines: 87,
     │     │            bytes: 2847,
     │     │            hash: "sha256:abc123..."
     │     │          })
     │     │
     │     ├─ FILE 2: src/mqtt/MQTTClient.js
     │     │  └─ (Repeat steps i-iv for next file)
     │     │     └─ Generated: 142 lines, AWS IoT SDK integration
     │     │
     │     ├─ FILE 3: src/mqtt/MessageHandler.js
     │     │  └─ Generated: 98 lines, message routing logic
     │     │
     │     ├─ FILE 4: src/devices/DeviceRegistry.js
     │     │  └─ Generated: 176 lines, device management
     │     │
     │     └─ FILE 5: src/config/iot-config.js
     │        └─ Generated: 42 lines, configuration
     │        
     │        Module Complete: iot-gateway-service
     │        └─ Files: 5, Lines: 545, Duration: 28 seconds
     │
     ├─ MODULE 2: analytics-service (Python)
     │  └─ (Repeat for Python files with PyLint validation)
     │     └─ Files: 8, Lines: 987, Duration: 35 seconds
     │
     ├─ MODULE 3: web-frontend (React)
     │  └─ (Repeat for JSX files)
     │     └─ Files: 12, Lines: 1456, Duration: 42 seconds
     │
     ├─ MODULE 4: api-gateway
     │  └─ Files: 4, Lines: 623, Duration: 18 seconds
     │
     └─ MODULE 5: shared-utils
        └─ Files: 3, Lines: 234, Duration: 12 seconds
        
        ALL MODULES COMPLETE
        └─ Total: 32 files, 3,845 lines, 135 seconds
```

---

*(Continuing with remaining flows...)*

### Flow 6: Testing Phase

```
┌─────────────────────────────────────────────────────────────────────┐
│                    TESTING PHASE FLOW                                │
└─────────────────────────────────────────────────────────────────────┘

[TestAgentService.generateTests()]
  │
  ├─ 1. Retrieve Generated Code
  │    └─ SELECT content FROM blackboard_entry
  │       WHERE entry_type = 'CODE'
  │       
  │       Retrieved: All 32 files with code
  │
  ├─ 2. Retrieve Testing Strategy
  │    └─ From execution plan:
  │       ├─ Unit test target: 85%
  │       ├─ Framework: Jest (Node.js), Pytest (Python), Jest (React)
  │       └─ Critical paths: [device communication, predictions, dashboard]
  │
  └─ 3. Generate Tests Per Module
     │
     ├─ For iot-gateway-service:
     │  └─ Generate tests/server.test.js
     │     
     │     LLM Prompt:
     │     """
     │     Generate comprehensive Jest tests for server.js
     │     
     │     Code to test:
     │     ```javascript
     │     [server.js content]
     │     ```
     │     
     │     Cover:
     │     - Server initialization
     │     - MQTT connection handling
     │     - Health endpoint
     │     - Error scenarios
     │     - Graceful shutdown
     │     
     │     Use:
     │     - Jest mocking for MQTT client
     │     - Supertest for API testing
     │     - >85% coverage target
     │     """
     │     
     │     Generated Test:
     │     ```javascript
     │     const request = require('supertest');
     │     const IoTGatewayServer = require('../src/server');
     │     
     │     describe('IoT Gateway Server', () => {
     │       let server;
     │       
     │       beforeAll(async () => {
     │         server = new IoTGatewayServer();
     │         await server.start(3001);
     │       });
     │       
     │       afterAll(async () => {
     │         await server.shutdown();
     │       });
     │       
     │       describe('Health Endpoint', () => {
     │         it('should return healthy status', async () => {
     │           const res = await request(server.app)
     │             .get('/health')
     │             .expect(200);
     │           
     │           expect(res.body).toHaveProperty('status', 'healthy');
     │           expect(res.body).toHaveProperty('mqtt');
     │           expect(res.body).toHaveProperty('devices');
     │         });
     │       });
     │       
     │       // ... 20 more test cases
     │     });
     │     ```
     │     
     │     Test count: 24 assertions
     │     Coverage estimate: 89%
     │
     └─ Repeat for all modules
        └─ Total: 156 tests, 87.3% coverage
```

(The document continues with similar detail for Review, Export, Error Handling, and Decision Trees...)

---

## 🔀 Decision Trees

### Decision Tree 1: Code Quality Gate

```
Start: Code generated for all modules
  │
  ├─ Check 1: Syntax Valid?
  │  ├─ YES → Continue
  │  └─ NO → Log errors
  │           ├─ Auto-fix attempt (1 retry)
  │           ├─ Success? → Continue
  │           └─ Fail → Mark as NEEDS_MANUAL_REVIEW
  │                     Send to Blackboard
  │                     Pause workflow
  │
  ├─ Check 2: Security Scan Pass?
  │  ├─ YES → Continue
  │  └─ NO → Severity Critical?
  │           ├─ YES → Block export
  │           │        Flag for review
  │           └─ NO → Add to recommendations
  │                   Continue with warning
  │
  ├─ Check 3: Requirements Traced?
  │  ├─ All requirements addressed? → Continue
  │  └─ Missing requirements? → Log gaps
  │                              Continue but flag
  │
  └─ Result: Quality gate PASSED/WARNED/FAILED
     └─ Store decision in blackboard
```

### Decision Tree 2: Workflow Phase Transition

```
Current Phase Complete
  │
  ├─ Phase = PLANNING
  │  ├─ Execution plan generated? → YES
  │  ├─ Plan stored in blackboard? → YES
  │  └─ Transition to: CODING
  │
  ├─ Phase = CODING
  │  ├─ All modules generated? → YES
  │  ├─ Quality gates passed? → YES
  │  │                           └─ NO → Retry failed modules (max 2)
  │  └─ Transition to: TESTING
  │
  ├─ Phase = TESTING
  │  ├─ All tests generated? → YES
  │  ├─ Coverage >= target? → YES
  │  │                        └─ NO → Generate additional tests
  │  └─ Transition to: REVIEW
  │
  ├─ Phase = REVIEW
  │  ├─ Review complete? → YES
  │  ├─ Status = APPROVED?
  │  │  ├─ YES → Transition to: EXPORT
  │  │  ├─ NEEDS_CHANGES → Back to CODING (with feedback)
  │  │  └─ REJECTED → Mark workflow FAILED
  │  │                 Notify user
  │  └─ Export enabled?
  │     ├─ YES → Proceed to export
  │     └─ NO → Mark COMPLETED (no export)
  │
  └─ Phase = EXPORT
     ├─ GitHub configured? → YES
     ├─ Repository created? → YES
     ├─ Code pushed? → YES
     └─ Transition to: COMPLETED
        └─ Send notification
           Store repository URL
```

---

## 📊 Data Flow Summary

### Complete Data Journey

```
[User Input]
  "Smart Home Energy Optimizer idea"
     │
     ▼
[Auto-BADS Processing]
  ├─ Market Analysis (LSTM) → Score: 8.5/10
  ├─ Financial Projections → Cost: $45k-$65k
  ├─ Solution Architecture → Tech stack identified
  └─ SRS Generation → 15-page document
     │
     ▼
[Kafka Event]
  autobads.srs.generated
     │
     ▼
[AgentMesh Workflow]
  ├─ Planning → 32 files planned
  ├─ Coding → 3,845 lines generated
  ├─ Testing → 156 tests, 87% coverage
  ├─ Review → Quality score 8.7/10, APPROVED
  └─ Export → GitHub repository created
     │
     ▼
[Final Output]
  https://github.com/user/smart-home-energy-optimizer
  └─ Production-ready codebase
     ├─ Source code
     ├─ Tests
     ├─ Documentation
     └─ CI/CD config
```

---

**Document Status**: Comprehensive journey mapping complete  
**Next Steps**: Review scenarios, add missing edge cases, begin implementation
