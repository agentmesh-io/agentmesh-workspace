#!/bin/bash

# Test script to verify PlannerAgentService integration
# Publishes a mock SRS event to Kafka to trigger the workflow

KAFKA_TOPIC="autobads.srs.generated"
KAFKA_CONTAINER="agentmesh-kafka"

# Mock SRS event payload
read -r -d '' SRS_EVENT <<'EOF'
{
  "ideaId": 12345,
  "projectName": "E-Commerce Platform Test",
  "generatedAt": "2025-12-07T14:00:00",
  "correlationId": "test-correlation-id-001",
  "srsData": {
    "ideaId": 12345,
    "ideaTitle": "E-Commerce Platform",
    "problemStatement": "Small businesses need an easy-to-use online store solution",
    "businessCase": "Target market of 1M small businesses, recurring revenue model",
    "targetMarket": "Small to medium businesses",
    "srs": {
      "introduction": {
        "purpose": "Build a scalable e-commerce platform",
        "scope": "MVP with product catalog, cart, and checkout"
      },
      "functionalRequirements": [
        {
          "id": "FR-001",
          "requirement": "User registration and authentication",
          "priority": "HIGH",
          "category": "Authentication"
        },
        {
          "id": "FR-002",
          "requirement": "Product catalog with search and filtering",
          "priority": "HIGH",
          "category": "Core Features"
        },
        {
          "id": "FR-003",
          "requirement": "Shopping cart functionality",
          "priority": "HIGH",
          "category": "Core Features"
        },
        {
          "id": "FR-004",
          "requirement": "Payment processing integration",
          "priority": "HIGH",
          "category": "Payment"
        },
        {
          "id": "FR-005",
          "requirement": "Order management and tracking",
          "priority": "MEDIUM",
          "category": "Order Management"
        }
      ],
      "nonFunctionalRequirements": [
        {
          "id": "NFR-001",
          "requirement": "System must handle 1000 concurrent users",
          "category": "Performance",
          "priority": "HIGH"
        },
        {
          "id": "NFR-002",
          "requirement": "99.9% uptime SLA",
          "category": "Availability",
          "priority": "HIGH"
        },
        {
          "id": "NFR-003",
          "requirement": "PCI-DSS compliant payment processing",
          "category": "Security",
          "priority": "HIGH"
        },
        {
          "id": "NFR-004",
          "requirement": "Page load time under 2 seconds",
          "category": "Performance",
          "priority": "MEDIUM"
        }
      ],
      "architecture": {
        "architectureStyle": "Microservices",
        "components": [
          {
            "name": "API Gateway",
            "description": "Entry point for all client requests",
            "technology": "Spring Cloud Gateway"
          },
          {
            "name": "Product Service",
            "description": "Manages product catalog",
            "technology": "Spring Boot"
          },
          {
            "name": "Order Service",
            "description": "Handles order processing",
            "technology": "Spring Boot"
          },
          {
            "name": "Payment Service",
            "description": "Processes payments",
            "technology": "Spring Boot + Stripe API"
          }
        ],
        "dataFlow": "Client -> API Gateway -> Microservices -> Database",
        "deploymentStrategy": "Containerized deployment on Kubernetes"
      },
      "techStack": {
        "backend": "Java 17, Spring Boot 3.x",
        "frontend": "React 18, TypeScript",
        "database": "PostgreSQL 15",
        "caching": "Redis",
        "messageQueue": "Apache Kafka"
      },
      "constraints": [
        {
          "type": "Technical",
          "description": "Must integrate with existing payment gateway"
        },
        {
          "type": "Business",
          "description": "6-month delivery timeline"
        },
        {
          "type": "Regulatory",
          "description": "GDPR and PCI-DSS compliance required"
        }
      ]
    }
  }
}
EOF

echo "Publishing SRS event to Kafka topic: $KAFKA_TOPIC"
echo ""

# Compact JSON to single line and publish to Kafka
echo "$SRS_EVENT" | jq -c '.' | docker exec -i $KAFKA_CONTAINER kafka-console-producer \
  --bootstrap-server localhost:9092 \
  --topic $KAFKA_TOPIC

if [ $? -eq 0 ]; then
  echo "✅ Successfully published SRS event to Kafka"
  echo ""
  echo "Monitor AgentMesh logs with:"
  echo "  docker logs -f agentmesh-api-server"
  echo ""
  echo "Expected workflow:"
  echo "  1. EventConsumer receives event"
  echo "  2. ProjectInitializationService creates project"
  echo "  3. Temporal workflow starts"
  echo "  4. PlannerAgentService.generateExecutionPlan() is called"
  echo "  5. SRS is retrieved from Auto-BADS (will fail - use mock)"
  echo "  6. Plan is generated and stored in Blackboard"
else
  echo "❌ Failed to publish event to Kafka"
  exit 1
fi
