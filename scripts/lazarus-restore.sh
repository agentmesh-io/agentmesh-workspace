#!/bin/bash
# lazarus-restore.sh — AgentMesh Platform Restore Script
# Per Architect Protocol v7.7: Priority 1 recovery workflow
set -euo pipefail

BACKUP_DIR="${1:?Usage: lazarus-restore.sh <backup-directory>}"
WORKSPACE="/Volumes/Blackhole/Developer_Storage/Repositories/Work/agentmesh"

if [ ! -d "${BACKUP_DIR}" ]; then
    echo "❌ Backup directory not found: ${BACKUP_DIR}"
    exit 1
fi

echo "═══════════════════════════════════════════════════════"
echo "  🧟 Lazarus Restore — AgentMesh Platform"
echo "  Source: ${BACKUP_DIR}"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "⚠️  This will overwrite current repos. Continue? (y/N)"
read -r confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborted."
    exit 0
fi

# 1. Restore git bundles
echo ""
echo "📦 Restoring git bundles..."
for project in AgentMesh AgentMesh-UI Auto-BADS; do
    BUNDLE="${BACKUP_DIR}/${project}.bundle"
    if [ -f "${BUNDLE}" ]; then
        TARGET="${WORKSPACE}/${project}"
        echo "  → Restoring ${project}..."
        if [ -d "${TARGET}" ]; then
            rm -rf "${TARGET}"
        fi
        git clone "${BUNDLE}" "${TARGET}"
        echo "    ✅ ${project} restored"
    fi
done

# Workspace
BUNDLE="${BACKUP_DIR}/workspace.bundle"
if [ -f "${BUNDLE}" ]; then
    echo "  → Restoring workspace..."
    # Only restore docs/scripts, not subprojects
    TEMP_DIR=$(mktemp -d)
    git clone "${BUNDLE}" "${TEMP_DIR}"
    cp -r "${TEMP_DIR}/docs" "${WORKSPACE}/docs" 2>/dev/null || true
    cp -r "${TEMP_DIR}/scripts" "${WORKSPACE}/scripts" 2>/dev/null || true
    cp -f "${TEMP_DIR}/docker-compose.yml" "${WORKSPACE}/" 2>/dev/null || true
    cp -f "${TEMP_DIR}/docker-compose.gateway.yml" "${WORKSPACE}/" 2>/dev/null || true
    rm -rf "${TEMP_DIR}"
    echo "    ✅ Workspace restored"
fi

# 2. Re-add GitHub remotes
echo ""
echo "🔗 Re-adding GitHub remotes..."
cd "${WORKSPACE}/AgentMesh" && git remote add origin git@github.com:agentmesh-io/agentmesh.git 2>/dev/null || true
cd "${WORKSPACE}/AgentMesh-UI" && git remote add origin git@github.com:agentmesh-io/agentmesh-ui.git 2>/dev/null || true
cd "${WORKSPACE}/Auto-BADS" && git remote add origin git@github.com:agentmesh-io/auto-bads.git 2>/dev/null || true
echo "  ✅ Remotes configured"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  ✅ Restore Complete"
echo ""
echo "  Next steps:"
echo "    1. git fetch origin (in each project)"
echo "    2. Verify with: git log --oneline -5"
echo "    3. Start services when ready"
echo "═══════════════════════════════════════════════════════"

