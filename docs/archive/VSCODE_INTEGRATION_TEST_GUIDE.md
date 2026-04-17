# 🚀 VS Code Integration - Quick Test Guide

## ⚡ Testing in 5 Minutes

### Step 1: Verify Services Running (30 seconds)

```bash
# Check backend
curl -s http://localhost:8080/actuator/health
# Should return: {"status":"UP"}

# Check frontend
curl -s http://localhost:3000 | head -n 1
# Should return HTML
```

✅ **Both services running?** Continue to Step 2  
❌ **Services not running?** See "Troubleshooting" below

---

### Step 2: Submit Test Workflow (2 minutes)

1. **Open AgentMesh UI**:
   ```bash
   open http://localhost:3000
   ```

2. **Submit a business idea**:
   - Click "New Workflow" or navigate to ideas page
   - Enter: "Build a simple todo list application with user authentication"
   - Click "Submit"

3. **Wait for completion**:
   - Workflow status should go: PLANNING → CODE_GENERATION → COMPLETED
   - Takes ~1-2 minutes with MockLLM

---

### Step 3: Test New Features (2 minutes)

#### 3A: View Generated Code Buttons

1. Navigate to workflow details page
2. Scroll to "Code Generation Tasks" section
3. Look for **"View Generated Code"** buttons (blue links with KB size)
4. Click any button → Should open Monaco editor in new tab

**Expected Result**:
```
✓ Monaco editor opens
✓ Syntax highlighting active
✓ Can copy/download code
```

#### 3B: Open in VS Code Button

1. On workflow details page, look for **"Open in VS Code"** button (purple, top right)
2. Click button → Should navigate to export page

**Expected Result**:
```
✓ Export page loads
✓ Download button visible
✓ Setup instructions shown
✓ Artifact cards displayed
```

#### 3C: Download Workspace File

1. On export page, click **"Download agentmesh-workflow-*.code-workspace"**
2. Check Downloads folder

**Expected Result**:
```
✓ File downloaded (5-10 KB)
✓ File is valid JSON
✓ Contains "folders", "settings", "extensions", "tasks"
```

---

## 🧪 API Testing (Optional)

### Test Backend Endpoints Directly:

```bash
# Replace WORKFLOW_ID with actual ID from your test
export WORKFLOW_ID="your-workflow-id-here"

# 1. Get workflow with artifact IDs
curl -s "http://localhost:8080/api/workflows/${WORKFLOW_ID}" | \
  jq '{
    id: .id,
    status: .status,
    codeArtifactIds: .codeArtifactIds,
    taskCount: .codeGenerationTasks | length
  }'

# Expected output:
# {
#   "id": "abc123...",
#   "status": "COMPLETED",
#   "codeArtifactIds": ["7", "8", "9", "10", "11", "12", "13"],
#   "taskCount": 7
# }

# 2. Export VS Code workspace
curl -s "http://localhost:8080/api/workflows/${WORKFLOW_ID}/export-vscode-workspace" | \
  jq '{
    workspaceFile: .workspaceFile,
    artifactCount: .codeArtifacts | length,
    recommendedExtensions: .workspace.extensions.recommendations,
    taskCount: .workspace.tasks.tasks | length
  }'

# Expected output:
# {
#   "workspaceFile": "agentmesh-workflow-abc123.code-workspace",
#   "artifactCount": 7,
#   "recommendedExtensions": [
#     "vscjava.vscode-java-pack",
#     "vmware.vscode-spring-boot",
#     "esbenp.prettier-vscode",
#     "dbaeumer.vscode-eslint",
#     "bradlc.vscode-tailwindcss"
#   ],
#   "taskCount": 4
# }

# 3. View specific artifact
export ARTIFACT_ID="7"  # Use ID from codeArtifactIds array
curl -s "http://localhost:8080/api/blackboard/entries/${ARTIFACT_ID}" | \
  jq '{
    id: .id,
    contentType: .contentType,
    size: .content | length,
    preview: .content[:100]
  }'

# Expected output:
# {
#   "id": "7",
#   "contentType": "text/plain",
#   "size": 1234,
#   "preview": "package com.example.demo.entity;\n\nimport jakarta.persistence.*;\nimport lombok.Data;..."
# }
```

---

## 📋 Feature Checklist

### Backend Features:
- [ ] Workflow stores `artifactId` in tasks
- [ ] Workflow has `codeArtifactIds` array
- [ ] Export endpoint returns valid JSON
- [ ] Export includes recommended extensions
- [ ] Export includes build/run tasks
- [ ] Export includes debug configuration

### Frontend Features:
- [ ] "View Generated Code" buttons appear on tasks
- [ ] Buttons link to correct artifact IDs
- [ ] Monaco editor opens and displays code
- [ ] "Open in VS Code" button appears when workflow complete
- [ ] Export page loads without errors
- [ ] Download button downloads .code-workspace file
- [ ] Copy button copies configuration to clipboard
- [ ] Setup instructions are clear and complete
- [ ] Artifact cards display and link correctly

### Integration Features:
- [ ] Downloaded workspace file is valid JSON
- [ ] Workspace file opens in VS Code
- [ ] VS Code recommends extensions
- [ ] Tasks appear in VS Code task list
- [ ] Debug configuration shows in Run panel

---

## 🔍 What to Look For

### ✅ Success Indicators:

**In the UI**:
1. Purple "Open in VS Code" button on completed workflows
2. Blue "View Generated Code" buttons on each code task
3. Artifact size displayed (e.g., "1.2 KB")
4. Export page shows all artifacts
5. Download works without errors

**In the API**:
1. `codeArtifactIds` array is populated and not empty
2. Tasks have `artifactId` field (not null)
3. Export endpoint returns 200 OK
4. Workspace JSON is valid and complete

**In VS Code**:
1. File opens as workspace (not plain text)
2. Extensions recommendation popup appears
3. Tasks visible in Terminal → Run Task menu
4. Debug configurations in Run panel
5. Java/TypeScript IntelliSense works

### ❌ Failure Indicators:

**In the UI**:
- No "Open in VS Code" button on completed workflow → Check `codeArtifactIds`
- No "View Generated Code" buttons → Check `artifactId` in tasks
- 404 on export page → Check workflow ID in URL
- Empty artifact list → No code was generated

**In the API**:
- `codeArtifactIds: null` → Code generated before update
- `artifactId: null` in tasks → Backend changes not applied
- Export endpoint 404 → Backend not restarted
- Export returns empty object → Workflow doesn't exist

**In VS Code**:
- Opens as text editor → File extension incorrect
- No extension recommendations → Extensions list missing
- No tasks available → Tasks configuration missing
- IntelliSense doesn't work → Extensions not installed

---

## 🛠️ Troubleshooting

### Problem: Services Not Running

```bash
# Check Docker containers
docker ps | grep agentmesh

# Expected: agentmesh-app, agentmesh-postgres, agentmesh-temporal, etc.

# Restart if needed
cd /Users/univers/projects/agentmesh/AgentMesh
docker-compose restart agentmesh-app

# Check frontend
cd /Users/univers/projects/agentmesh/AgentMesh-UI/agentmesh-ui
npm run dev
```

### Problem: No "View Code" Buttons

**Cause**: Workflow created before backend update

**Solutions**:
1. **Quick**: Submit a new workflow (2 minutes)
2. **Alternative**: Test API endpoints directly to verify backend works

### Problem: Export Page Shows No Artifacts

**Cause**: Workflow doesn't have `codeArtifactIds`

**Check**:
```bash
curl -s http://localhost:8080/api/workflows/{id} | jq '.codeArtifactIds'
```

**Solutions**:
- If `null`: Workflow created before update → Submit new workflow
- If `[]`: Code generation didn't complete → Check workflow status
- If populated: Frontend issue → Check browser console

### Problem: Download Doesn't Work

**Cause**: Browser blocking download or JavaScript error

**Check**:
1. Open browser console (F12)
2. Look for errors
3. Try different browser

**Solution**:
```javascript
// Manual download in browser console:
const config = await fetch('http://localhost:8080/api/workflows/{id}/export-vscode-workspace').then(r => r.json());
const blob = new Blob([JSON.stringify(config.workspace, null, 2)], {type: 'application/json'});
const url = URL.createObjectURL(blob);
const a = document.createElement('a');
a.href = url;
a.download = config.workspaceFile;
a.click();
```

### Problem: VS Code Doesn't Recognize Workspace

**Cause**: File extension or format issue

**Check**:
1. File has `.code-workspace` extension
2. File is valid JSON (open in text editor)
3. Contains required fields: `folders`, `settings`

**Solution**:
```bash
# Validate JSON
cat ~/Downloads/agentmesh-*.code-workspace | jq '.'

# Should show formatted JSON without errors
```

---

## 📊 Expected Test Results

### Successful Test Run:

```
Timeline:
0:00 - Start testing
0:30 - Services verified running
2:30 - Workflow submitted and completed
3:00 - "View Code" buttons clicked, Monaco editor loaded
3:30 - "Open in VS Code" clicked, export page loaded
4:00 - Workspace file downloaded
4:30 - File opened in VS Code
5:00 - Extensions installed, IntelliSense active

Result: ✅ ALL FEATURES WORKING
```

### Workflow State After Successful Generation:

```json
{
  "id": "abc123...",
  "status": "COMPLETED",
  "businessIdea": "Build a simple todo list application...",
  "codeArtifactIds": ["7", "8", "9", "10", "11", "12", "13"],
  "codeGenerationTasks": [
    {
      "name": "Generate Backend Code",
      "status": "COMPLETED",
      "artifactGenerated": true,
      "artifactId": "7",
      "artifactSize": 1234
    },
    {
      "name": "Generate Frontend Code",
      "status": "COMPLETED",
      "artifactGenerated": true,
      "artifactId": "8",
      "artifactSize": 2345
    }
    // ... more tasks
  ]
}
```

---

## 🎯 Quick Commands Reference

```bash
# Navigate to backend
cd /Users/univers/projects/agentmesh/AgentMesh

# Rebuild backend (if needed)
mvn clean package -DskipTests

# Restart backend
docker-compose restart agentmesh-app

# View backend logs
docker logs agentmesh-app --tail 50

# Navigate to frontend
cd /Users/univers/projects/agentmesh/AgentMesh-UI/agentmesh-ui

# Start frontend dev server
npm run dev

# Open in browser
open http://localhost:3000

# Test backend health
curl http://localhost:8080/actuator/health

# Test workflow endpoint
curl http://localhost:8080/api/workflows/{id}

# Test export endpoint
curl http://localhost:8080/api/workflows/{id}/export-vscode-workspace
```

---

## 📁 File Locations

```
Project Files:
├─ /Users/univers/projects/agentmesh/
│  ├─ AgentMesh/
│  │  ├─ src/main/java/.../api/WorkflowController.java  ← Backend changes
│  │  └─ docker-compose.yml
│  └─ AgentMesh-UI/agentmesh-ui/
│     └─ app/workflows/[workflowId]/
│        ├─ page.tsx                                     ← View Code buttons
│        └─ vscode-export/page.tsx                       ← Export page

Documentation:
├─ VSCODE_INTEGRATION_COMPLETE.md       ← Full implementation guide
├─ VSCODE_INTEGRATION_VISUAL_GUIDE.md   ← UI mockups and visuals
└─ VSCODE_INTEGRATION_TEST_GUIDE.md     ← This file (quick testing)
```

---

## 🎉 Success Criteria

You'll know the implementation is working when:

1. ✅ **Workflow Details Page**:
   - Shows purple "Open in VS Code" button
   - Shows blue "View Generated Code" buttons
   - Buttons work when clicked

2. ✅ **VS Code Export Page**:
   - Loads without errors
   - Shows artifact cards
   - Download button works
   - File downloads successfully

3. ✅ **Monaco Editor**:
   - Opens in new tab
   - Shows syntax highlighting
   - Copy/download works

4. ✅ **VS Code Desktop**:
   - Workspace file opens
   - Extensions recommended
   - Tasks available
   - IntelliSense works

5. ✅ **API Endpoints**:
   - Return 200 OK
   - Include artifact IDs
   - Generate valid JSON
   - Complete configuration

---

## 🚀 Next Steps After Testing

### If Everything Works:
1. ✅ Mark implementation complete
2. 📝 Document findings
3. 🎯 Enable real code generation (OpenAI)
4. 🌐 Deploy to production

### If Issues Found:
1. 🐛 Check troubleshooting section
2. 📋 Run API tests directly
3. 🔍 Check browser console
4. 📞 Review implementation docs

---

## 📚 Related Documentation

- **VSCODE_INTEGRATION_COMPLETE.md** - Full implementation details
- **VSCODE_INTEGRATION_VISUAL_GUIDE.md** - UI mockups and design
- **ENABLE_REAL_CODE_GENERATION.md** - Configure OpenAI
- **CODE_EDITOR_INTEGRATION.md** - Monaco Editor setup
- **CODE_GENERATION_QUICK_START.md** - Getting started guide

---

*Last Updated*: November 17, 2025  
*Estimated Test Time*: 5 minutes  
*Difficulty*: Easy - Just follow the steps!

**Ready to test?** Start with Step 1! 🚀
