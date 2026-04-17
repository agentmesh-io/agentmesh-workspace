# Code Generation & Viewing - Quick Start

## Problem Identified ✅

**Your code generation was producing mock templates instead of real code.**

### Root Cause
```yaml
# AgentMesh/src/main/resources/application.yml
agentmesh:
  llm:
    openai:
      enabled: false  # ← MockLLMClient is active
```

The `MockLLMClient` (marked `@Primary`) generates templates like:
```java
public class MockGeneratedCode {
    private final Repository repository;
    public void execute() {
        repository.save(new Entity());
    }
}
```

### Evidence
- **Artifact 10 (Tests)**: ✅ Real JUnit code
- **Artifacts 6-9, 11-13**: ❌ Mock templates

---

## Solution 1: Enable Real Code Generation

### Quick Setup (5 minutes)

1. **Get OpenAI API Key**
   ```bash
   # Visit https://platform.openai.com/api-keys
   # Create new key, copy it
   ```

2. **Set Environment Variable**
   ```bash
   export OPENAI_API_KEY="sk-your-actual-key-here"
   ```

3. **Enable OpenAI**
   ```bash
   cd /Users/univers/projects/agentmesh/AgentMesh
   
   # Edit application.yml
   vim src/main/resources/application.yml
   
   # Change:
   agentmesh:
     llm:
       openai:
         enabled: true  # ← Change from false to true
         model: gpt-3.5-turbo  # Cheaper option
   ```

4. **Rebuild & Restart**
   ```bash
   mvn clean package -DskipTests
   docker-compose down
   docker-compose up -d agentmesh
   docker logs -f agentmesh
   ```

5. **Verify**
   ```bash
   # Look for:
   # "Calling OpenAI API with model: gpt-3.5-turbo"
   ```

### Expected Cost
- **GPT-4**: $1.60 - $4.00 per workflow (8 tasks)
- **GPT-3.5-Turbo**: $0.16 - $0.40 per workflow (90% cheaper)

### What You'll Get
- ✅ Real Spring Boot entities, repositories, services, controllers
- ✅ Real React components with TypeScript
- ✅ Real SQL migration scripts
- ✅ Real GitHub Actions workflows
- ✅ Real API documentation

---

## Solution 2: Code Editor (Already Implemented ✅)

### What Was Added

1. **Monaco Editor Integration**
   - VS Code's editor component
   - Syntax highlighting for all languages
   - Line numbers, folding, minimap
   - Copy/download functionality

2. **New Routes**
   - `/artifacts/[id]` - View individual code artifact
   - Example: http://localhost:3000/artifacts/7

3. **New Components**
   - `app/components/CodeViewer.tsx` - Monaco editor wrapper
   - `app/components/CodeArtifactsSection.tsx` - Code artifacts list
   - `app/artifacts/[id]/page.tsx` - Full artifact viewer

### How to Use

1. **Start AgentMesh UI**
   ```bash
   cd /Users/univers/projects/agentmesh/AgentMesh-UI/agentmesh-ui
   npm run dev
   ```

2. **View Generated Code**
   ```bash
   # Visit any artifact directly:
   open http://localhost:3000/artifacts/7
   open http://localhost:3000/artifacts/10
   ```

3. **Features Available**
   - **Syntax Highlighting**: Auto-detects language (Java, TypeScript, SQL, etc.)
   - **Copy to Clipboard**: One-click copy
   - **Download**: Save as file
   - **Metadata**: Agent ID, timestamp, entry type

### Testing

```bash
# Test artifact viewer with existing mock code
curl http://localhost:8080/api/blackboard/entries/7 | jq -r '.content'

# Then view in browser
open http://localhost:3000/artifacts/7
```

---

## Complete Workflow

### Before (Mock Code)
```
Submit Idea → Workflow Runs → Code Generated
                              ↓
                         MockLLMClient
                              ↓
                    "MockGeneratedCode" templates
                              ↓
                         ❌ Generic, not useful
```

### After (Real Code + Editor)
```
Submit Idea → Workflow Runs → Code Generated
                              ↓
                        OpenAI GPT-3.5
                              ↓
                    Real implementation code
                              ↓
                         Monaco Editor
                              ↓
                ✅ View, copy, download real code
```

---

## Files Modified/Created

### Backend (No changes needed)
- ✅ `AgentActivityImpl.java` - Already has LLM integration
- ✅ `OpenAIClient.java` - Already implemented
- ✅ `BlackboardController.java` - Already has REST API

### Frontend (New files created)
```
AgentMesh-UI/agentmesh-ui/
  app/
    components/
      CodeViewer.tsx              ← New: Monaco editor wrapper
      CodeArtifactsSection.tsx    ← New: Artifacts list
    artifacts/
      [id]/
        page.tsx                  ← New: Artifact viewer page
  package.json                    ← Updated: Added @monaco-editor/react
```

---

## Testing Checklist

### Phase 1: Test Code Editor (Now)
- [ ] Start AgentMesh UI: `npm run dev`
- [ ] Visit http://localhost:3000/artifacts/7
- [ ] Verify Monaco editor loads
- [ ] Test copy button
- [ ] Test download button
- [ ] Check syntax highlighting

### Phase 2: Enable OpenAI (After setting API key)
- [ ] Set `OPENAI_API_KEY` environment variable
- [ ] Edit `application.yml`: `openai.enabled: true`
- [ ] Rebuild: `mvn clean package -DskipTests`
- [ ] Restart: `docker-compose up -d --force-recreate agentmesh`
- [ ] Check logs: `docker logs -f agentmesh | grep "OpenAI"`

### Phase 3: Test End-to-End (After OpenAI enabled)
- [ ] Submit new business idea via UI
- [ ] Wait for workflow to complete
- [ ] Check generated code artifacts
- [ ] Verify code is NOT "MockGeneratedCode"
- [ ] Verify code contains real implementations
- [ ] View code in Monaco editor
- [ ] Download code files

---

## Quick Commands Reference

### Check Current LLM Client
```bash
docker logs agentmesh 2>&1 | grep -i "llm" | tail -10

# If using Mock:
# "MockLLM.chat called with X messages"

# If using OpenAI:
# "Calling OpenAI API with model: gpt-3.5-turbo"
```

### View Generated Code (CLI)
```bash
# List all artifacts
curl http://localhost:8080/api/blackboard/entries | jq -r '.[] | "\(.id): \(.title)"'

# View specific artifact
curl http://localhost:8080/api/blackboard/entries/7 | jq -r '.content'
```

### View Generated Code (Browser)
```bash
# Open artifact in Monaco editor
open http://localhost:3000/artifacts/7
open http://localhost:3000/artifacts/10
```

### Rebuild After Config Change
```bash
cd /Users/univers/projects/agentmesh/AgentMesh

# Full rebuild
mvn clean package -DskipTests

# Restart container
docker-compose down
docker-compose up -d agentmesh

# Watch logs
docker logs -f agentmesh
```

---

## Cost Optimization

### Use GPT-3.5-Turbo (Recommended)
```yaml
agentmesh:
  llm:
    openai:
      enabled: true
      model: gpt-3.5-turbo  # 90% cheaper than GPT-4
```

### Reduce Self-Correction Iterations
```yaml
agentmesh:
  selfcorrection:
    max-iterations: 3  # Default is 5
```

### Expected Monthly Cost
- **Light usage** (10 workflows/month): $2 - $5
- **Medium usage** (50 workflows/month): $10 - $25
- **Heavy usage** (200 workflows/month): $40 - $100

---

## Troubleshooting

### Issue: "Failed to fetch artifact"
**Solution**: Ensure AgentMesh is running
```bash
docker ps | grep agentmesh
curl http://localhost:8080/actuator/health
```

### Issue: "Loading editor..." never completes
**Solution**: Check browser console for errors
```bash
# Ensure Monaco is installed
cd AgentMesh-UI/agentmesh-ui
npm list @monaco-editor/react
```

### Issue: Still getting mock code after enabling OpenAI
**Solution**: Force rebuild
```bash
docker-compose down
docker system prune -f
mvn clean package -DskipTests
docker-compose up --build -d
```

### Issue: "OpenAI API error: 401"
**Solution**: Verify API key
```bash
echo $OPENAI_API_KEY  # Should start with sk-
docker-compose down
OPENAI_API_KEY="sk-your-key" docker-compose up -d
```

---

## Next Steps

### Immediate (You can do now)
1. ✅ Test code editor with existing artifacts
2. ✅ View artifacts at http://localhost:3000/artifacts/7
3. ✅ Copy/download code

### Short Term (After getting API key)
1. Get OpenAI API key
2. Enable OpenAI in `application.yml`
3. Rebuild and restart AgentMesh
4. Submit new idea and verify real code generation

### Long Term (Future enhancements)
1. Add code diff viewer (compare iterations)
2. Implement ZIP download for all artifacts
3. Add GitHub export functionality
4. Integrate code search across artifacts
5. Add code quality metrics display

---

## Documentation

### Detailed Guides
- **`ENABLE_REAL_CODE_GENERATION.md`** - Complete OpenAI setup guide
- **`CODE_EDITOR_INTEGRATION.md`** - Monaco editor implementation details

### API Documentation
- **Blackboard API**: http://localhost:8080/swagger-ui.html
- **GET** `/api/blackboard/entries/{id}` - Get artifact
- **GET** `/api/blackboard/entries` - List all artifacts
- **GET** `/api/blackboard/entries/type/{type}` - Filter by type

---

## Summary

### ✅ Completed
1. **Identified root cause**: MockLLMClient is active instead of OpenAI
2. **Created comprehensive guides**: OpenAI setup + Code editor integration
3. **Implemented code editor**: Monaco editor with syntax highlighting
4. **Created artifact viewer**: Full page to view/copy/download code
5. **Built code browser**: Component to list all generated artifacts

### 🎯 Next Actions for You
1. **Test the code editor** (works with current mock code):
   ```bash
   cd AgentMesh-UI/agentmesh-ui
   npm run dev
   open http://localhost:3000/artifacts/7
   ```

2. **Enable real code generation** (requires OpenAI API key):
   - Get API key from https://platform.openai.com/api-keys
   - Set environment variable: `export OPENAI_API_KEY="sk-..."`
   - Edit `application.yml`: `openai.enabled: true`
   - Rebuild: `mvn clean package -DskipTests`
   - Restart: `docker-compose up -d --force-recreate`

3. **Generate real code**:
   - Submit new business idea
   - Wait for workflow completion
   - View real code in Monaco editor

---

## Support

If you encounter issues:
1. Check logs: `docker logs -f agentmesh`
2. Verify services: `docker ps`
3. Review guides: `ENABLE_REAL_CODE_GENERATION.md`
4. Test endpoints: `curl http://localhost:8080/actuator/health`

The code editor is **ready to use now** with existing mock code. To get **real code generation**, you just need to:
1. Get OpenAI API key
2. Enable it in config
3. Rebuild/restart

That's it! 🚀
