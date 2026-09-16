# Challenges and Optimization

## Challenges faced

| Problem | Root cause | Solution | Lesson |
|---|---|---|---|
| Key Vault deployment failed | Vault name exceeded Azure's limit | Shortened deterministic name | Validate provider naming limits before deployment |
| Key Vault Bicep validation failed | Unsupported explicit `enablePurgeProtection: false` | Removed the property | Omit unsupported/default properties instead of forcing them |
| ADF SQL connection initially failed | Explicit AutoResolve IR binding conflicted with artifact shape | Removed unnecessary `connectVia` | Keep linked-service definitions minimal |
| Logic App callback was initially truncated | Windows `az.cmd` interpreted callback URL ampersands | Stored the complete value through a protected file/value path and replaced the secret | Never pass signed URLs through unsafe shell parsing; never log them |
| Rejected schema created repeat risk | Procedure checked only any PENDING RFC, not the same detected hash | Reused the latest decision for the exact schema hash | Idempotency applies to governance state too |
| Retry totals overstated failures | Every retry attempt was counted as another table | Summarized latest attempt per `ConfigId` with `ROW_NUMBER()` | Separate attempt-level telemetry from entity-level outcomes |
| ADF master appeared successful on partial failure | Failure was handled so finalization could run | Finalize audit, then throw when the latest table outcome includes failure | Orchestration status and audit status must tell the same operational story |
| Power BI opened without imported rows | Credentials are intentionally absent and model was not refreshed | Keep PBIP credential-free; user refreshes with Entra organizational account | Secure artifacts should not embed developer credentials |

## Optimization opportunities

| Area | Current approach | Improved approach | Benefit | Trade-off |
|---|---|---|---|---|
| Performance | Stored-procedure loads and small concurrency | Bulk staging, partitioned copy, indexed staging, tuned batches | Higher throughput | More moving parts and compute |
| Scalability | Batch count 2 in one master | Workload groups, schedule sharding, concurrency quotas | Predictable scaling to hundreds/thousands of tables | More operational policy |
| Incremental capture | Timestamp watermark | SQL Change Tracking/CDC or source-native log capture | Captures deletes and avoids timestamp gaps | Source support, retention, complexity |
| Schema approvals | Human approval for every change | Policy-based auto-approval for safe additive nullable columns | Less manual delay | Governance must accept automated decisions |
| Cost | Serverless free-limit SQL and Consumption services | Schedule-aware pause/resume, retention controls, reserved capacity only at steady utilization | Lower unit cost | More cost governance effort |
| Reliability | SQL audit plus ADF monitor | Azure Monitor/Log Analytics alerts, action groups, ITSM integration | Centralized operations | Ingestion and integration cost |
| Maintainability | SQL procedure contains generic load rules | Modular rule catalog and versioned migration handlers | Easier extension | More framework code and testing |
| Security | Public endpoints with narrow firewalls | Private endpoints, private DNS, hub/spoke network, VPN/ExpressRoute | Reduced public exposure | Direct service/network cost |
| Identity | Two-day client secret for demonstration | Federated workload identity or certificate | Better rotation and lower secret risk | Platform/client setup |
| Observability | Row counts and rule results | Checksums, freshness SLAs, distribution/anomaly checks, lineage | Faster detection of subtle defects | More compute and false-positive tuning |
