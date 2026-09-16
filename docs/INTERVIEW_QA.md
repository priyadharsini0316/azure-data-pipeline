# Interview Q&A

## Architecture and choices

**Walk me through your architecture.**  
ADF reads enabled Azure SQL configuration rows and calls one reusable child pipeline per table. SQL procedures handle approved-schema loading, watermark state, reconciliation, RFC state, and audit. Managed identity secures runtime access, Logic Apps receives notifications, and Power BI reads narrow reporting views.

**Why ADF + Azure SQL?**  
It is the simplest fit for KPMG's requested Azure SQL/Data Factory direction and a relational metadata-driven prototype. It is quick to explain, inexpensive at this scale, and needs no Spark platform.

**Why not Fabric?**  
Fabric is a good fit when the client already standardizes on capacities, OneLake, and end-to-end SaaS analytics. For this case it adds capacity/licensing dependency without improving the small SQL-to-SQL prototype enough.

**Why not Databricks?**  
Databricks is stronger for very large data, complex transformations, streaming, and lakehouse engineering. This workload is orchestration-heavy, relational, and small, so it would add operational and learning overhead.

**What makes it dynamic?**  
The pipeline is driven by rows in `PipelineConfiguration`; datasets and procedures receive schema/table/config parameters. There is no separate ADF pipeline per source table.

**How do I add a table?**  
Create a valid config row with source/target metadata, key, strategy, and `Load='Yes'`. The next lookup includes it.

**What happens when Load = No?**  
The lookup excludes the row, so ADF never calls the child pipeline for it.

## Schema and approval

**How do you detect schema changes?**  
I build deterministic ordered column metadata and hash it. A different hash from the approved version creates or reuses an RFC.

**What happens when a column is added?**  
It becomes PENDING. The table loads only approved columns. After approval, a new schema version is recorded and the target adopts it on the next run.

**What if a column is removed or renamed?**  
That is breaking because the approved projection no longer exists. The table fails safely, retries, logs the RFC, and does not corrupt the target.

**What about datatype changes?**  
All require approval here. Widening may be safe after validation; narrowing or incompatible conversion needs remediation and a controlled target migration.

**Why not auto-accept additive changes?**  
The supplied KPMG flow requires approval for detected changes. Auto-accepting explicitly safe additions is documented as a future efficiency improvement.

## Loads and recovery

**How does first load work?**  
No approved hash means first load. The source schema becomes version 1, the target is created from approved columns, then loaded and reconciled.

**How does incremental load work?**  
Rows above the last successful watermark form the delta. Matching target keys are replaced transactionally, then the watermark advances only after PASS.

**What if there is no reliable watermark?**  
Use a full load for correctness, or introduce source change tracking/CDC. I would not invent an unsafe timestamp.

**How do you prevent duplicates?**  
The delta key set deletes matching target rows before insert in one transaction, and duplicate/null-key checks gate the commit.

**What happens halfway through a failure?**  
The transaction rolls back, the watermark stays unchanged, and the audit records FAILURE. A rerun starts from the last committed state.

**What if one table fails?**  
Other ForEach items continue. The audit is PARTIAL_SUCCESS, and the master ADF run is deliberately Failed so monitoring cannot miss it.

**How do retries work?**  
The child activity retries three times after the initial failure. Audit keeps each attempt, while summary counts only the latest result per table.

## Quality, scale, and cost

**How do you reconcile?**  
Row count, source/target key completeness, duplicate/null keys, and approved-schema checks. These are explicit prototype assumptions because KPMG did not define exact rules.

**How would this scale to 100 or 1,000 tables?**  
Partition configuration into controlled batches, tune ADF concurrency and SQL capacity, separate schedules by SLA, index audit/config tables, and move heavy transformations to the appropriate compute engine.

**How would you improve performance?**  
Use source-side predicates, partitioned copy where justified, bulk staging/merge, fewer repeated metadata queries, and workload-specific concurrency.

**How would you reduce cost?**  
Keep serverless auto-pause for intermittent workloads, avoid idle integration runtimes/capacities, batch orchestration, monitor activity runs, and add private/network services only when security requirements justify them.

## Security

**How are credentials secured?**  
ADF uses managed identity. Secrets needed only for demonstrations/integrations live in Key Vault and never in configuration or Git.

**Managed identity vs service principal?**  
Managed identity is best for Azure-hosted runtime because Azure manages its credential. A service principal is useful for external applications or CI/CD, but its certificate/secret must be rotated.

**How do external users access data?**  
The prototype assumption is controlled Power BI consumption. The case did not define an external-user API or direct SQL pattern.

**How do you implement least privilege?**  
Custom database roles by workload, schema-level grants, Entra groups for humans, RBAC for Azure resources, MFA, and periodic access reviews. The demo reporting identity is denied curated-table access.

## Production posture

**What would you change for production?**  
Separate Dev/Test/Integration/Prod, CI/CD parameterization, private endpoints and private DNS, client-approved VPN/ExpressRoute, enterprise ITSM approval integration, centralized monitoring, secretless federation/certificates, and source-native CDC where available.

**What are the prototype limitations?**  
Representative Azure SQL source, synthetic data, no hard-delete capture, one low-cost environment, public endpoints with narrow firewalls, local Power BI only, SQL-backed RFC instead of ITSM, and limited business-specific quality rules.
