# 🔄 Git Versioning & GitHub Sync Strategy

**Date:** April 17, 2026  
**Applies to:** All projects in the AgentMesh workspace

---

## 1. Branch Strategy (All Projects)

```
main          ← stable, deployable, protected
develop       ← integration branch (CI runs here)
feature/*     ← feature branches off develop
bugfix/*      ← bug fixes off develop
release/*     ← release candidates (develop → release → main)
hotfix/*      ← emergency fixes off main
```

### Branch Protection Rules (GitHub)
- `main`: Require PR, no force push, require passing CI
- `develop`: Require PR from feature branches

---

## 2. Versioning (Semantic Versioning)

All projects follow **SemVer** (`MAJOR.MINOR.PATCH`):

| Project | Current | Next Tag | Notes |
|---------|---------|----------|-------|
| AgentMesh | Untagged | `v0.5.0` | Phase 5 complete, pre-production |
| AgentMesh-UI | Untagged | `v0.3.0` | 90% feature-complete |
| Auto-BADS | Untagged | `v0.9.0` | 98% feature-complete |

### Tag Convention
```bash
git tag -a v0.5.0 -m "Phase 5: Hybrid search, monitoring, UI integration"
git push origin --tags
```

---

## 3. GitHub Repositories (LIVE)

| Project | Repository | Status |
|---------|-----------|--------|
| AgentMesh | https://github.com/agentmesh-io/agentmesh | ✅ Live |
| AgentMesh-UI | https://github.com/agentmesh-io/agentmesh-ui | ✅ Live |
| Auto-BADS | https://github.com/agentmesh-io/auto-bads | ✅ Live |

> **Org:** `agentmesh-io` — All repos transferred from personal account.

### 3.1 AgentMesh (Backend) — ✅ COMPLETED

```bash
# Step 1: Commit uncommitted changes
cd AgentMesh
git add -A && git commit -m "chore: organize docs and commit pending changes"

# Step 2: Merge branches into main (sequential)
git checkout main
git merge phase5-hybrid-search --no-ff -m "merge: Phase 5 hybrid search"
git merge appmod/java-upgrade-20251202063532 --no-ff -m "merge: Java upgrade and workflow persistence"

# Step 3: Clean up stale branches
git branch -d phase5-hybrid-search
git branch -d appmod/java-upgrade-20251202063532

# Step 4: Create develop branch
git checkout -b develop

# Step 5: Push to GitHub
git remote add origin git@github.com:<org>/agentmesh.git
git push -u origin main develop
git tag -a v0.5.0 -m "Phase 5 complete" && git push origin --tags
```

### 3.2 AgentMesh-UI (Frontend)

```bash
cd AgentMesh-UI
git add -A && git commit -m "chore: Phase 2 Task 4 + file reorganization"

# Rename master → main
git branch -m master main

# Push to GitHub
git remote add origin git@github.com:<org>/agentmesh-ui.git
git push -u origin main
git checkout -b develop && git push -u origin develop
git tag -a v0.3.0 -m "Dashboard MVP" && git push origin --tags
```

### 3.3 Auto-BADS (Analysis Service)

```bash
cd Auto-BADS
git add -A && git commit -m "chore: full feature implementation + file reorganization"

# Rename master → main
git branch -m master main

# Push to GitHub
git remote add origin git@github.com:<org>/auto-bads.git
git push -u origin main
git checkout -b develop && git push -u origin develop
git tag -a v0.9.0 -m "Feature-complete MVP" && git push origin --tags
```

### 3.4 Root Workspace (Optional)

```bash
cd /Repositories/Work/agentmesh
git init
cat > .gitignore << 'EOF'
AgentMesh/
AgentMesh-UI/
Auto-BADS/
logs/
.idea/
.DS_Store
EOF

git add -A && git commit -m "init: workspace config, docs, and scripts"
git remote add origin git@github.com:<org>/agentmesh-workspace.git
git push -u origin main
```

---

## 4. Commit Message Convention

Follow **Conventional Commits**:

```
feat:     New feature
fix:      Bug fix
docs:     Documentation only
chore:    Build, tooling, no production code change
refactor: Code change, no feature or fix
test:     Tests only
ci:       CI/CD changes
perf:     Performance improvement
```

Example: `feat(multi-tenancy): add tenant isolation for projects`

---

## 5. Release Workflow

```
feature/* → develop → release/v0.6.0 → main (tag v0.6.0)
```

1. Features merge to `develop` via PR
2. When ready, cut `release/vX.Y.Z` from `develop`
3. Test on release branch, fix bugs there
4. Merge release → `main` + tag
5. Back-merge `main` → `develop`

---

## 6. Pre-Push Checklist

- [ ] All tests pass locally
- [ ] No secrets in committed files
- [ ] `.gitignore` excludes logs, build artifacts, IDE files
- [ ] Commit messages follow convention
- [ ] Branch is up-to-date with target

