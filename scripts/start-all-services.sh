#!/bin/bash

# Master Startup Script for AgentMesh + Auto-BADS Integration
# Starts all required services in the correct order

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTMESH_DIR="$SCRIPT_DIR/AgentMesh"
AUTOBADS_DIR="$SCRIPT_DIR/Auto-BADS"

echo "════════════════════════════════════════════════════════"
echo "  AgentMesh + Auto-BADS System Startup"
echo "════════════════════════════════════════════════════════"
echo ""

# Function to check if a service is running
check_service() {
    local service_name=$1
    local port=$2
    
    if nc -z localhost $port 2>/dev/null; then
        echo "  ✅ $service_name (port $port)"
        return 0
    else
        echo "  ❌ $service_name (port $port)"
        return 1
    fi
}

# Step 1: Start AgentMesh Docker services
echo "📦 Step 1: Starting AgentMesh Docker Services"
echo "────────────────────────────────────────────────────────"
cd "$AGENTMESH_DIR"

# Check if services are already running
if docker-compose ps | grep -q "Up"; then
    echo "Some AgentMesh services are already running"
    read -p "Restart all services? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Restarting AgentMesh services..."
        docker-compose down
        docker-compose up -d
    else
        echo "Using existing services"
    fi
else
    echo "Starting AgentMesh services..."
    docker-compose up -d
fi

echo ""
echo "⏳ Waiting for AgentMesh services to be healthy..."
sleep 5

# Wait for critical services
MAX_WAIT=60
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    if docker-compose ps | grep -q "unhealthy"; then
        echo "  Some services are still starting... ($ELAPSED/${MAX_WAIT}s)"
        sleep 5
        ELAPSED=$((ELAPSED + 5))
    else
        break
    fi
done

echo ""
echo "📊 AgentMesh Service Status:"
check_service "PostgreSQL" 5432
check_service "Kafka" 9092
check_service "Weaviate" 8081
check_service "Temporal" 7233
check_service "Redis" 6379
check_service "AgentMesh API" 8080

echo ""

# Step 2: Start Auto-BADS
echo "🤖 Step 2: Starting Auto-BADS"
echo "────────────────────────────────────────────────────────"

# Check if Auto-BADS startup script exists
if [ ! -f "$AUTOBADS_DIR/start-autobads.sh" ]; then
    echo "❌ Auto-BADS startup script not found: $AUTOBADS_DIR/start-autobads.sh"
    exit 1
fi

# Make sure it's executable
chmod +x "$AUTOBADS_DIR/start-autobads.sh"

# Start Auto-BADS
cd "$AUTOBADS_DIR"
./start-autobads.sh

if [ $? -eq 0 ]; then
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "  ✅ All Services Started Successfully!"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "📊 Service URLs:"
    echo "  AgentMesh API:  http://localhost:8080"
    echo "  Auto-BADS API:  http://localhost:8083"
    echo "  Weaviate:       http://localhost:8081"
    echo "  Temporal UI:    http://localhost:8082"
    echo "  Grafana:        http://localhost:3000"
    echo "  Prometheus:     http://localhost:9090"
    echo ""
    echo "🧪 Test Integration:"
    echo "  curl -X POST http://localhost:8083/api/v1/test/publish-srs \\"
    echo "    -H 'Content-Type: application/json' \\"
    echo "    -d '{\"projectName\":\"Test Project\"}'"
    echo ""
    echo "📝 Logs:"
    echo "  AgentMesh:  docker logs -f agentmesh-api-server"
    echo "  Auto-BADS:  tail -f $AUTOBADS_DIR/logs/autobads.log"
    echo ""
else
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "  ❌ Auto-BADS Failed to Start"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Check logs at: $AUTOBADS_DIR/logs/autobads.log"
    exit 1
fi
