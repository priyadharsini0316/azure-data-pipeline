# KPMG Requirements Traceability - Design Stage

Status: Documentation plan only. No implementation evidence exists yet. `PLANNED` means the item is part of the approved-design candidate, not that it has been built. `DOCUMENTED ONLY` means it will be explained but not provisioned in the reduced-cost prototype.

Classification legend:

- **[A - KPMG REQUIRED]** Explicit KPMG requirement or visible process step.
- **[B - KPMG RECOMMENDED]** Recommendation/example rather than mandatory technology.
- **[C - PROPOSED DESIGN]** Implementation choice that satisfies or strengthens the requirement.
- **[D - PROTOTYPE ASSUMPTION]** Detail not prescribed by KPMG.

| KPMG page | requirement | mandatory? | design section | implementation task | demo/evidence | screenshot needed (Y/N) | status (PLANNED / DOCUMENTED ONLY) |
|---|---|---|---|---|---|---|---|
| 1 | **[A]** Dynamic pipeline adapts to source-model changes | Yes | Sections 3.C, 3.F/G/H, 5 | Schema discovery/hash/diff, RFC state, approved projection | Add column, pending old projection, approval and adoption; incompatible change safe failure | Y | PLANNED |
| 1, 3 | **[A]** Any configured table with `Load = Yes` is eligible | Yes | Sections 3.B, 5, 6 | Literal `Load` CHECK constraint; Lookup query; parameterized ForEach | Two `Yes` tables processed; one `No` table absent from table-run audits | Y | PLANNED |
| 3 | **[A]** Configuration contains Tables, Columns, Load, Connection Parameters | Yes | Section 3.B | Map table/column/load/connection fields; seed KPMG-named rows | SQL result shows names, approved columns, literal Yes/No, safe connection refs | Y | PLANNED |
| 1 | **[A]** Handle first and subsequent loads | Yes | Sections 3.D, 3.E | Durable first-load state; full and watermark paths | First full load, later watermark update, rerun idempotency | Y | PLANNED |
| 1 | **[A]** Handle success and failure | Yes | Sections 3.I, 3.K/L, 3.S | Audit states, table isolation, retry, rollback, notifications | Successful run and controlled failure/recovery | Y | PLANNED |
| 1 | **[B]** Retry failed loads or alert after a number of failures | Recommended example made concrete | Sections 3.K/L, 9 | Configurable default three retries; Until loop; failure notification | Initial attempt + 3 retries, final alert, unchanged watermark | Y | PLANNED |
| 1 | **[A]** Explain architecture in non-technical language | Yes | Section 2 plain-English explanation | Include analogy in final documentation/learning guide | Panel-ready explanation reviewed by Priya | N | PLANNED |
| 1 | **[A]** Screenshots of each setup step | Yes | Section 11 | Follow ordered evidence checklist; redact secrets | Genuine portal/tool/run evidence only | Y | PLANNED |
| 1 | **[B]** Fabric recommended but not mandatory | No | Sections 2, 8 | Document trade-off; implement selected ADF + Azure SQL | Architecture decision/trade-off table | N | PLANNED |
| 2 step 1/1.1 | **[A]** Detect first load, create schema, load Dev/Test | Yes | Sections 3.D, 5 | Initial approved schema, staging creation, full copy | First-load branch and gate-1 evidence | Y | PLANNED |
| 2 step 2 | **[A]** Source Prod vs Dev/Test data match | Yes | Sections 3.I, 5 | `usp_Gate1Reconcile`; `GATE_1_PRE_PUBLISH` results | Count/key/null/duplicate/schema PASS and induced FAIL gap report | Y | PLANNED |
| 2 step 2.1 | **[A]** Load Integration/Production after gate 1 | Yes | Sections 3.C, 3.I, 5 | Transactional publish/merge to `curated` | Target publish occurs only after gate 1 PASS | Y | PLANNED |
| 2 step 3 | **[A]** Dev/Test vs Integration/Production data match | Yes | Sections 3.I, 5 | `usp_PublishAndGate2`; `GATE_2_POST_PUBLISH` | PASS plus induced failure/rollback and retained staging | Y | PLANNED |
| 2 step 3 failure | **[A]** Review data-quality/gap report and return to step 3 | Yes | Sections 3.I, 9 | Gap view + `pl_ReconcileAndFinalize` by `TableRunId` | Remediate failure and rerun gate 2 without stale evidence | Y | PLANNED |
| 2 step 3.1 | **[A]** Send success-load message | Yes | Required notification contract, sections 3.S, 9 | Logic App + `Web_NotifySuccess` + notification audit | Received success message correlated to run | Y | PLANNED |
| 2 step 4 | **[A]** Detect schema change since last load | Yes | Sections 3.F/G/H, 5 | Normalize metadata, hash, detailed diff | SchemaHistory/RFC created on change | Y | PLANNED |
| 2 step 4.2 | **[A]** Send schema-change alert and get approval | Yes | Sections 3.F/G/H, notification contract | SQL RFC PENDING + `Web_NotifySchemaChange` | Received alert plus durable PENDING row | Y | PLANNED |
| 2 step 5 | **[A]** Approval decision; old approved schema when pending/rejected per Priya clarification | Yes | Step-5 interpretation, sections 5, 9 | Asynchronous SQL approval; compatible old projection; safety guard | PENDING warning; APPROVED adoption; REJECTED non-adoption | Y | PLANNED |
| 2 step 5.1 | **[A]** Pipeline schema-change message on rejection | Yes | Required notification contract | `Web_NotifySchemaRejected` + notification audit | Received rejection message includes compatibility result | Y | PLANNED |
| 2 RFC lane | **[A]** Business change, development/test, deploy, rerun | Yes at process-design level | Sections 3.F/G/H, 7 | SQL RFC workflow; versioned artifacts; later authorized run | RFC state/history and approved rerun | Y | PLANNED |
| 2 / page-1 inset | **[C]** Map KPMG physical environments to reduced prototype | Prototype choice | Environment mapping, sections 4, 7 | Logical `src`/`stg`/`curated`; CI/CD documentation | Gate evidence in one environment; topology explanation | Y | PLANNED |
| 2 / page-1 inset | **[C]** Separate Dev/Test/Integration/Prod physical environments | Production recommendation | Sections 4, 7, 10 | Document promotion, parameters, release gates | Architecture/CI-CD documentation only | N | DOCUMENTED ONLY |
| 4 | **[A]** Secure on-premises-to-cloud connectivity and routing | Yes | Security production topology, IP plan | Document SHIR + VPN/ExpressRoute/private routing | Production network design; no fabricated portal evidence | N | DOCUMENTED ONLY |
| 4 | **[A]** Non-overlapping private IP plan and scalable subnetting | Yes | Production IP address plan | Document hub/on-prem/spoke ranges; no prototype VNet/subnets | Production network design only; no fabricated portal evidence | N | DOCUMENTED ONLY |
| 4 | **[A]** Firewalls/security groups allow only necessary traffic | Yes | Security/access matrix, firewall governance | Prototype SQL/Key Vault public firewall controls; document production NSG/private endpoints/Firewall | SQL/Key Vault firewall and access evidence; production controls documented only | Y | PLANNED |
| 4 | **[A]** Regular rule updates based on threat intelligence | Yes | Access lifecycle/firewall governance | Review prototype public firewall rules; document Defender/Azure Firewall TI for production | Review procedure; paid production controls not claimed | Y | PLANNED |
| 4 | **[A]** RBAC, least privilege, regular access review | Yes | Group access matrix/lifecycle | Group assignments, custom SQL roles, access review/PIM if licensed | Role assignments and review evidence or explicit limitation | Y | PLANNED |
| 4 | **[A]** IAM with MFA and provisioning/de-provisioning | Yes | Access lifecycle | Joiner/mover/leaver, guest expiry, Conditional Access/PIM subject to licence | Policies/reviews if tenant permits; otherwise limitation | Y | PLANNED |
| 4 | **[A]** Developer/Admin/Support security groups and group permissions | Yes | Group access matrix | Create named Entra groups and assign scoped roles | Groups and group-based assignments | Y | PLANNED |
| 4 | **[A]** App registration/service principal, secret, permissions, non-user authentication | Yes | Prototype service-principal plan, section 9 | App registration, short secret in Key Vault, contained SQL user, read-only test | Allowed reporting read and denied curated read | Y | PLANNED |
| 4 | **[C]** Managed identity for Azure runtime | Proposed stronger control | Security identity comparison | ADF managed identity -> SQL/Key Vault/Logic App | Identity and contained permission evidence | Y | PLANNED |
| 4 | **[D]** External users consume through Power BI B2B/RLS | Prototype assumption | Section 3.N and group matrix | Viewer/app audience and RLS if licence/test guest available | Guest-viewer proof or accurate PARTIAL/NOT IMPLEMENTED | Y | PLANNED |
| N/A | **[C]** Power BI pipeline-health report | Proposed evidence | Section 3.N | Build three report pages over reporting views | KPI overview, run detail, schema/RFC detail | Y | PLANNED |

## Status discipline

- Before implementation approval, every live item remains `PLANNED`.
- During implementation, this design-stage matrix will be superseded by `REQUIREMENTS_TRACEABILITY_MATRIX.md` using `COMPLETE`, `PARTIAL`, `NOT IMPLEMENTED`, and `ASSUMPTION` with direct evidence paths.
- Azure SQL Private Endpoint, Key Vault Private Endpoint, Private DNS, paid Power BI/Fabric capacity, VNet/NSG, VPN Gateway, ExpressRoute, Azure Firewall, and on-premises SHIR must never be shown as implemented unless later explicitly authorized and actually provisioned. The first five are hard exclusions for this prototype.
