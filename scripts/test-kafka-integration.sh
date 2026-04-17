#!/bin/bash

# Test script to publish a test SrsGeneratedEvent to Kafka
# This bypasses Auto-BADS startup issues and tests the Kafka→AgentMesh integration directly

KAFKA_CONTAINER="agentmesh-kafka"
TOPIC="autobads.srs.generated"

# Sample SrsGeneratedEvent JSON payload
EVENT_JSON='{
  "ideaId": 12345,
  "projectName": "Test E-Commerce Platform",
  "srsData": {
    "ideaId": "550e8400-e29b-41d4-a716-446655440000",
    "ideaTitle": "Test E-Commerce Platform",
    "generatedAt": "2025-11-04T16:00:00",
    "businessCase": "Build an online marketplace",
    "problemStatement": "Small businesses need affordable e-commerce solutions",
    "strategicAlignment": "High",
    "srs": {
      "version": "1.0",
      "functionalRequirements": [],
      "nonFunctionalRequirements": [],
      "architecture": {
        "architectureStyle": "MICROSERVICES",
        "components": ["Product Service", "Order Service", "Payment Service"],
        "integrationPoints": ["REST API", "Event Bus"],
        "databaseStrategy": "PostgreSQL"
      },
      "dependencies": []
    },
    "prioritizedBacklog": [],
    "technicalConstraints": [],
    "qualityAttributes": ["Scalability", "Security"],
    "financials": {
      "totalCostOfOwnership": 200000.0,
      "developmentCost": 100000.0,
      "operationalCostPerYear": 20000.0,
      "expectedRoi": 1.5,
      "breakEvenMonths": 24
    },
    "riskAssessment": {
      "overallRiskLevel": "MEDIUM",
      "identifiedRisks": []
    },
    "recommendedSolutionType": "BUILD",
    "recommendationScore": 85.0,
    "metadata": {}
  },
  "generatedAt": "2025-11-04T16:00:00",
  "correlationId": "test-correlation-123"
}'

echo "Publishing test SrsGeneratedEvent to Kafka topic: $TOPIC"
echo "Event: $EVENT_JSON"
echo ""

# Publish to Kafka using docker exec
docker exec -i $KAFKA_CONTAINER kafka-console-producer --bootstrap-server localhost:29092 --topic $TOPIC <<< "$EVENT_JSON"

if [ $? -eq 0 ]; then
    echo "✅ Successfully published test event to Kafka"
    echo "📊 Check AgentMesh logs to verify event consumption:"
    echo "   docker logs agentmesh-app -f | grep 'SRS Generated Event'"
else
    echo "❌ Failed to publish event to Kafka"
    exit 1
fi
