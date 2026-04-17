#!/bin/bash
# phoenix-backup.sh — AgentMesh Platform Backup Script
# Per Architect Protocol v7.7: Run after significant changes
set -euo pipefail

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="${HOME}/.agentmesh-backups/${TIMESTAMP}"
WORKSPACE="/Volumes/Blackhole/Developer_Storage/Repositories/Work/agentmesh"

echo "═══════════════════════════════════════════════════════"
echo "  🔥 Phoenix Backup — AgentMesh Platform"
echo "  Timestamp: ${TIMESTAMP}"
echo "═══════════════════════════════════════════════════════"

mkdir -p "${BACKUP_DIR}"

# 1. Git bundle for each project (full repo backup)
echo ""
echo "📦 Creating git bundles..."
for project in AgentMesh AgentMesh-UI Auto-BADS; do
    if [ -d "${WORKSPACE}/${project}/.git" ]; then
        echo "  → ${project}"
        cd "${WORKSPACE}/${project}"
        git bundle create "${BACKUP_DIR}/${project}.bundle" --all 2>/dev/null
        echo "    ✅ ${project}.bundle created"
    fi
done

# Workspace repo
if [ -d "${WORKSPACE}/.git" ]; then
    echo "  → workspace"
    cd "${WORKSPACE}"
    git bundle create "${BACKUP_DIR}/workspace.bundle" --all 2>/dev/null
    echo "    ✅ workspace.bundle created"
fi

# 2. Copy configuration files
echo ""
echo "📄 Backing up configurations..."
mkdir -p "${BACKUP_DIR}/config"
cp -f "${WORKSPACE}/docker-compose.yml" "${BACKUP_DIR}/config/" 2>/dev/null || true
cp -f "${WORKSPACE}/docker-compose.gateway.yml" "${BACKUP_DIR}/config/" 2>/dev/null || true
cp -f "${WORKSPACE}/AgentMesh/src/main/resources/application.yml" "${BACKUP_DIR}/config/agentmesh-application.yml" 2>/dev/null || true
cp -f "${WORKSPACE}/Auto-BADS/src/main/resources/application.yml" "${BACKUP_DIR}/config/autobads-application.yml" 2>/dev/null || true
echo "  ✅ Config files backed up"

# 3. Copy docs
echo ""
echo "📚 Backing up docs..."
cp -r "${WORKSPACE}/docs" "${BACKUP_DIR}/docs" 2>/dev/null || true
echo "  ✅ Docs backed up"

# 4. Calculate backup size
BACKUP_SIZE=$(du -sh "${BACKUP_DIR}" | cut -f1)

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  ✅ Backup Complete"
echo "  Location: ${BACKUP_DIR}"
echo "  Size: ${BACKUP_SIZE}"
echo "  Contents:"
ls -la "${BACKUP_DIR}/"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "  To restore: ./scripts/lazarus-restore.sh ${BACKUP_DIR}"

