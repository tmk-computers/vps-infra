# 14 AI FEATURE INVENTORY & OPERATIONAL CLASSIFICATION

**Document ID**: `REMED-P0-14`  
**Phase**: Phase 0 — Current-State Reconciliation & Architecture Freeze  
**Author**: Antigravity Conversation 1 — Developer  
**Baseline Date**: 2026-09-29  
**Review Status**: PENDING INDEPENDENT REVIEW & CODEX AUDIT GATE  

---

## 1. AI Governance & Gate-A Dependency Policy

> [!CRITICAL]
> **Core Safety Principle**:
> Artificial Intelligence (AI) and Large Language Model (LLM) features MUST NOT become a dependency for core infrastructure operations, container deployments, database backups, disaster recovery, or health verification.
> 
> All infrastructure safety guarantees must be 100% deterministic, verifiable, and executable without AI.

---

## 2. Inventory & Classification of AI Subsystems

| AI Feature / Subsystem | Primary Code Location | Implementation Nature | Technical Reality | Classification Tier | Pilot Gate A Role | Remediation Path |
| :--- | :--- | :---: | :--- | :---: | :---: | :--- |
| **Interactive Copilot** | [`InteractiveCopilotService.cs:126`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/AI/InteractiveCopilotService.cs#L126) | Regex / String Matching | Uses hardcoded keyword matching with simulated typewriter streaming delays (`Task.Delay(50)`). Does NOT call external or local LLM. | **DETERMINISTIC / EXPERIMENTAL** | Excluded from Pilot Core (Optional Beta Widget) | Truthfully document as regex assistant; remove fake token streaming (MR-21). |
| **Build Failure Diagnosis** | [`BuildFailureAnalysisAgentService.cs`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/AI/BuildFailureAnalysisAgentService.cs) | Heuristic Regex Rule Engine | Scans build log text for known strings (`CS1002`, `TS2304`, `OutOfMemory`). Assembles static Markdown advice. | **DETERMINISTIC / PRODUCTION CANDIDATE** | Non-blocking Advisor Only | Retain deterministic log parsing; label explicitly as static rule diagnosis. |
| **Daily DevOps Digest** | [`DevopsIntelligenceAgentService.cs`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/AI/DevopsIntelligenceAgentService.cs) | In-Memory Aggregate Heuristics | Aggregates 24h deployment and backup stats; global in-memory cache ignores tenant IDs (F22). | **DETERMINISTIC / EXPERIMENTAL** | Excluded from Pilot Core | Fix cache key tenant isolation (MR-08); present as statistical digest. |
| **Human-in-the-Loop (HITL) Approvals** | [`HitlApprovalService.cs:247`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/AI/HitlApprovalService.cs#L247) | State Token Generator | Computes SHA-256 state hashes; lacks atomic concurrency lock (F15). | **DETERMINISTIC / EXPERIMENTAL** | Excluded from Gate A | Add optimistic concurrency and idempotency tokens before enabling. |
| **Model Gateway & Providers** | [`ModelGatewayService.cs`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/AI/ModelGatewayService.cs) | HTTP Proxy Adapter | Connects to Ollama, OpenAI, Anthropic; API keys stored in plaintext (F16). Injected `_modelGateway` fields in agents are unreferenced. | **MODEL-BACKED / EXPERIMENTAL** | Disabled in Gate A Default Profile | Encrypt API keys in DB (MR-07); enforce strict spend caps and tenant rate limits. |
| **Tool Registry & Execution** | [`ToolRegistryService.cs`](file:///d:/company/products/vps-infra/vps-infra-server/devops-manager/api/Infrastructure/Services/AI/ToolRegistryService.cs) | Deterministic C# Tools | Contains 7 C# tools for inspecting Docker containers, restarts, DB backups. Backup tool returns stats, not execution. | **DETERMINISTIC / EXPERIMENTAL** | Internal Testing Only | Ensure tools cannot bypass RBAC or trigger unverified destructive actions. |
| **Agency Agents Catalog (63 Agents)** | [`docs/06-AI-AGENT-PLATFORM-BRD/04_...`](file:///d:/company/products/vps-infra/vps-infra-server/docs/06-AI-AGENT-PLATFORM-BRD/04_AGENCY_AGENT_INVENTORY.md) | Markdown Personas | Catalog of 63 specialized system prompt personas. Zero runtime execution engine implemented. | **UNSUPPORTED / SPECIFICATION ONLY** | Excluded from Pilot | Clearly document as roadmap concept, not active code. |

---

## 3. Commercial Truthfulness Rules for AI

1. **No Simulated Intelligence**:
   - Simulated token streaming (`Task.Delay`) and fake thinking animations are strictly prohibited in the production UI.
2. **Explicit Labeling**:
   - The UI must clearly indicate: `"Deterministic Rule Engine (No LLM active)"` when running heuristic analysis.
   - When a customer connects an LLM via `ModelGateway`, the UI must state: `"LLM-Assisted Analysis (Experimental — verify commands before execution)"`.
3. **Decoupled Architecture**:
   - If local Ollama or cloud OpenAI is offline or unreachable, 100% of deployment, monitoring, backup, and upgrade operations must function flawlessly.
