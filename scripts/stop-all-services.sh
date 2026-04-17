#!/bin/bash

# Master Shutdown Script for AgentMesh + Auto-BADS Integration
# Stops all services gracefully

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTMESH_DIR="$SCRIPT_DIR/AgentMesh"

echo "════════════════════════════════════════════════════════"
echo "  Stopping AgentMesh + Auto-BADS System"
echo "════════════════════════════════════════════════════════"
echo ""

# Step 1: Stop Auto-BADS
echo "🛑 Step 1: Stopping Auto-BADS"
echo "────────────────────────────────────────────────────────"

if lsof -i :8083 > /dev/null 2>&1; then
    echo "Stopping Auto-BADS (port 8083)..."
    pkill -f "autobads.AutoBadsApplication" || true
    sleep 2
    
    if lsof -i :8083 > /dev/null 2>&1; then
        echo "⚠️  Auto-BADS still running, force killing..."
        pkill -9 -f "autobads.AutoBadsApplication" || true
        sleep 1
    fi
    
    if ! lsof -i :8083 > /dev/null 2>&1; then
        echo "  ✅ Auto-BADS stopped"
    else
        echo "  ❌ Failed to stop Auto-BADS"
    fi
else
    echo "  Auto-BADS is not running"
fi

echo ""

# Step 2: Stop AgentMesh Docker services
echo "🐳 Step 2: Stopping AgentMesh Docker Services"
echo "────────────────────────────────────────────────────────"
cd "$AGENTMESH_DIR"

if docker-compose ps | grep -q "Up"; then
    echo "Stopping AgentMesh services..."
    docker-compose down
    echo "  ✅ AgentMesh services stopped"
else
    echo "  AgentMesh services are not running"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "  ✅ All Services Stopped"
echo "════════════════════════════════════════════════════════"
