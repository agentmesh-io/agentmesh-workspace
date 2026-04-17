#!/bin/bash
# =============================================================================
# Setup Local LLM with Ollama for AgentMesh Development
# =============================================================================
# This script installs Ollama (if needed), pulls required models, and verifies
# the setup is working correctly.
#
# Usage: ./setup-ollama.sh
# =============================================================================

set -e

echo "🚀 Setting up Ollama for AgentMesh Local Development"
echo "===================================================="
echo ""

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "📦 Ollama not found. Installing..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install ollama
        else
            echo "❌ Homebrew not found. Please install from https://ollama.ai"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -fsSL https://ollama.ai/install.sh | sh
    else
        echo "❌ Unsupported OS. Please install from https://ollama.ai"
        exit 1
    fi
else
    echo "✅ Ollama is already installed: $(ollama --version)"
fi

echo ""

# Check if Ollama server is running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "🔄 Starting Ollama server..."
    ollama serve &
    sleep 3
else
    echo "✅ Ollama server is already running"
fi

echo ""

# Pull required models
echo "📥 Pulling required models (this may take a while)..."
echo ""

# Code generation model (primary)
echo "📦 Pulling codellama:13b (7GB - best for code generation)..."
ollama pull codellama:13b

# Embedding model for vector search
echo "📦 Pulling nomic-embed-text (for embeddings)..."
ollama pull nomic-embed-text

# Optional: Faster alternative model
echo "📦 Pulling phi3:mini (2.3GB - fast alternative)..."
ollama pull phi3:mini

echo ""
echo "✅ All models pulled successfully!"
echo ""

# Verify setup
echo "🔍 Verifying setup..."
echo ""

# List available models
echo "Available models:"
ollama list

echo ""

# Test code generation
echo "🧪 Testing code generation..."
RESPONSE=$(curl -s http://localhost:11434/api/generate \
    -d '{"model": "codellama:13b", "prompt": "Write a simple Java hello world program", "stream": false}')

if echo "$RESPONSE" | grep -q "public"; then
    echo "✅ Code generation working!"
else
    echo "⚠️  Code generation test may have issues. Response:"
    echo "$RESPONSE"
fi

echo ""
echo "===================================================="
echo "🎉 Ollama setup complete!"
echo ""
echo "📋 Quick Reference:"
echo "   - Ollama API: http://localhost:11434"
echo "   - Code Model: codellama:13b"
echo "   - Embedding Model: nomic-embed-text"
echo ""
echo "🚀 Start AgentMesh with: cd AgentMesh && mvn spring-boot:run"
echo "   Look for: 'OllamaClient initialized - Local LLM enabled'"
echo ""
echo "💡 To use a different model, set environment variable:"
echo "   export OLLAMA_MODEL=deepseek-coder:6.7b"
echo ""
echo "🔄 To switch to OpenAI for production, edit application.yml:"
echo "   agentmesh.llm.ollama.enabled=false"
echo "   agentmesh.llm.openai.enabled=true"
echo "===================================================="
