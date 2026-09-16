# Alternatives and Trade-offs

## Selected approach

ADF + Azure SQL is selected because the case explicitly permits it, the data is representative relational data, governance/audit state is naturally relational, and the prototype can be implemented and defended without a paid analytics capacity or Spark platform.

| Approach | Strengths | Weaknesses | Best fit |
|---|---|---|---|
| ADF + Azure SQL | Native orchestration, parameterization, managed identity, strong SQL transactions, low conceptual overhead | Schema evolution needs deliberate SQL logic; ADF JSON can be verbose | This case and conventional relational ingestion |
| Microsoft Fabric | OneLake, integrated Data Factory, notebooks, lakehouse/warehouse, Power BI integration | Capacity/licensing dependency; more platform surface than this prototype needs | Organizations already committed to Fabric and shared SaaS analytics |
| Databricks | Scalable Spark, Delta schema controls, streaming, complex transformations | Higher operational/skill/cost overhead for a small SQL-to-SQL case | Large, complex, semi-structured, ML, or streaming workloads |
| Stored-procedure-heavy ETL | Strong transactions, close to relational data, easy unit testing | SQL server bears transformation load; orchestration/lineage weaker if used alone | Moderate relational transforms with ADF orchestration |

## Metadata-driven vs table-specific

Metadata-driven uses one framework and makes `Load='Yes'` operationally meaningful. It reduces duplicated pipelines and centralizes controls. The trade-off is framework complexity and the need to constrain source-specific exceptions. Table-specific pipelines are easier for one or two irregular sources but become expensive and inconsistent at scale.

## Full vs incremental

Full load is simplest and correct without source change metadata, but reads and writes more. Watermark incremental is efficient, but correctness depends on a reliable monotonic/last-modified value and does not inherently capture hard deletes. CDC/change tracking is preferable where supported and justified.

## Automatic vs approval-controlled schema evolution

Approval-controlled evolution matches the supplied flow and prevents a technically additive column from silently changing downstream meaning. It creates manual delay. A future policy may auto-accept nullable additive columns with compatible types, while still requiring approval for removal, rename, type change, nullability tightening, or incompatible conversions.

## When alternatives win

- Choose Fabric when OneLake, Direct Lake, shared capacity, and unified governance are existing client standards.
- Choose Databricks for high-volume lakehouse processing, complex transformations, streaming, or data-science workloads.
- Choose table-specific logic only for exceptional sources whose rules cannot be expressed safely in the metadata contract.
- Choose private networking immediately when client policy prohibits public service endpoints; the prototype cost choice is not a production security recommendation.
