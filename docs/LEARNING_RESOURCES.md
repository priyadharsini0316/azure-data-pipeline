# Learning Resources

Official Microsoft material to study after the implementation. Read in this order.

## Azure Data Factory

- [Metadata-driven copy at scale](https://learn.microsoft.com/en-us/azure/data-factory/copy-data-tool-metadata-driven) — compare Microsoft's control-table pattern with this repository's Lookup/ForEach/procedure framework.
- [Lookup activity](https://learn.microsoft.com/en-us/azure/data-factory/control-flow-lookup-activity) — learn output shape, first-row behavior, limits, and how Lookup feeds ForEach.
- [ForEach activity](https://learn.microsoft.com/en-us/azure/data-factory/control-flow-for-each-activity) — understand concurrency, batch count, nested activities, and operational limits.
- [Parameterized linked services](https://learn.microsoft.com/en-us/azure/data-factory/parameterize-linked-services) — learn when connection metadata can and cannot be parameterized.
- [Incrementally copy multiple tables](https://learn.microsoft.com/en-us/azure/data-factory/tutorial-incremental-copy-multiple-tables-portal) — study old/new watermark handling and the moment state is updated.
- [Schema and type mapping](https://learn.microsoft.com/en-us/azure/data-factory/copy-activity-schema-and-type-mapping) — understand explicit mapping, type conversion, and drift limitations.
- [Managed identity for ADF](https://learn.microsoft.com/en-us/azure/data-factory/data-factory-service-identity) — learn identity lifecycle and supported authentication patterns.
- [Store credentials in Key Vault](https://learn.microsoft.com/en-us/azure/data-factory/store-credentials-in-key-vault) — learn secret references and managed-identity authorization.
- [Monitor ADF visually](https://learn.microsoft.com/en-us/azure/data-factory/monitor-visually) — learn pipeline/activity run diagnostics and rerun behavior.
- [Pipeline failure and error handling](https://learn.microsoft.com/en-us/azure/data-factory/tutorial-pipeline-failure-error-handling) — compare dependency conditions, logging, and intentional failure propagation.

## Azure SQL and identity

- [Azure SQL authentication with Microsoft Entra ID](https://learn.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-overview) — understand Entra-only authentication and contained users.
- [Service principals with Azure SQL](https://learn.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-service-principal) — learn application authentication, directory permissions, and operational caveats.
- [Azure SQL security overview](https://learn.microsoft.com/en-us/azure/azure-sql/database/security-overview) — place firewall, encryption, auditing, threat protection, and database permissions in layers.
- [Azure RBAC overview](https://learn.microsoft.com/en-us/azure/role-based-access-control/overview) — distinguish Azure control-plane roles from SQL database roles.
- [Key Vault RBAC guide](https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-guide) — learn vault-scope and secret-scope authorization and least privilege.
- [Private endpoint overview](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-overview) — understand private IP, private DNS, routing, and why Private Link is a production/cost decision.

## Power BI and Fabric

- [Power BI Desktop projects](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-overview) — learn PBIP source-control structure, supported external edits, and deployment options.
- [TMDL view](https://learn.microsoft.com/en-us/power-bi/transform-model/desktop-tmdl-view) — understand text-based semantic model definitions and validation.
- [Power BI semantic model folder](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-dataset) — learn `definition.pbism`, TMDL folders, and local settings/cache files.
- [Microsoft Fabric decision guide](https://learn.microsoft.com/en-us/fabric/get-started/microsoft-fabric-overview) — understand when OneLake, Fabric Data Factory, Warehouse/Lakehouse, and capacity justify a platform choice.

## Suggested study exercise

Rebuild one configured table manually in ADF, then compare it to this metadata-driven framework. Next, change one source column at a time and predict the hash/RFC/load outcome before running it. Finally, explain the difference between Azure RBAC, an Azure SQL database role, and Power BI workspace permissions without using notes.
