# Documentation and Artifact Inventory

[Start with the interview master guide](INTERVIEW_MASTER_GUIDE.md)

This inventory reflects local branch `feature/kpmg-data-pipeline` at `d39154e` plus the documentation updates in this working tree. It distinguishes implementation artifacts from explanatory material.

| Topic | Existing source | Coverage | Keep? | Update / gap | Best study source |
|---|---|---:|---|---|---|
| Case requirements | `tmp/pdfs/kpmg-page-1.png`–`4.png` | Authoritative | Yes | Never distribute beyond the permitted interview context | Case pages + `REQUIREMENTS_TRACEABILITY_MATRIX.md` |
| Executive overview | `README.md` | Strong | Yes | Corrected notification, firewall and reporting-access wording | `README.md` |
| Architecture | `ARCHITECTURE.md` | Strong | Yes | Corrected live resources, historical cost and group-access claims | `ARCHITECTURE.md` |
| Design choices | `DESIGN_DECISIONS.md` | Strong | Yes | Added implementation gaps found in code audit | `DESIGN_DECISIONS.md` |
| Requirement mapping | `REQUIREMENTS_TRACEABILITY_MATRIX.md` | Strong | Yes | Group-only SQL access remains partial | `REQUIREMENTS_TRACEABILITY_MATRIX.md` |
| Live evidence | `EVIDENCE.md`, `screenshots/` | Strong | Yes | ADF→Logic App and Gmail are separate proofs | `EVIDENCE.md` |
| CI/CD | `CICD_PROMOTION.md`, `.github/workflows/ci.yml` | Good | Yes | Production CD is design only | `CICD_PROMOTION.md` |
| Metadata model | `sql/001_create_framework.sql` | Authoritative | Yes | Per-row retry/connection fields are not consumed dynamically | Master guide Part 4 + SQL |
| Source/demo data | `sql/002_sample_source.sql`, `sql/demo/` | Authoritative | Yes | Synthetic; no KPMG business data supplied | Master guide Parts 5, 6, 16, 23 |
| Processing logic | `sql/003_stored_procedures.sql` | Authoritative | Yes | Gate 2 failure path code-reviewed but not forced live | Master guide Parts 5–12, 22 |
| SQL security | `sql/004_security_template.sql`, `005_reporting_identity.sql` | Good | Yes | Reporting script grants the service principal, not the Entra group | Master guide Part 14 |
| Reporting views | `sql/006_powerbi_reporting_views.sql` | Strong | Yes | Several views exist but are not imported into the one-page report | Master guide Part 15 |
| ADF orchestration | `adf/*.json` | Authoritative | Yes | Fixed linked service; retry is hard-coded | Master guide Parts 4, 11, 30 |
| Infrastructure | `infra/*.bicep`, `azure.yaml` | Strong | Yes | Gmail extension is separate; some identity setup was manual | Master guide Parts 18, 21 |
| Deployment scripts | `scripts/` | Strong | Yes | Developer-login prototype workflow, not production OIDC CD | Master guide Parts 17, 18 |
| Static tests | `tests/Test-StaticImplementation.ps1` | Good | Yes | No automated live data assertions in CI | Master guide Parts 17, 20 |
| Scenario checks | `tests/scenario_checks.sql` | Basic | Yes | Read-only evidence query, not a full automated test suite | Master guide Parts 8, 23 |
| Power BI | `powerbi/` PBIP/PBIR/TMDL | Authoritative | Yes | Import mode, one `Overview` page, three imported reporting views | Master guide Part 15 |
| Screenshots | `screenshots/` | Strong | Yes | Historical evidence captured 2026-09-16 | `EVIDENCE.md` |
| Interview learning | No single entry point previously | Missing | Create | Added master guide, cheat sheet, question bank and runbook | `INTERVIEW_MASTER_GUIDE.md` |

## Repository facts worth remembering

- Two ADF pipelines: `MasterMetadataDriven` and `ProcessConfiguredTable`.
- Three configuration rows: two enabled and one disabled in the sample.
- Two load types: `FULL` and `WATERMARK`.
- Seven SQL schemas: `src`, `ctl`, `stg`, `curated`, `audit`, `rfc`, `reporting`.
- One implemented Power BI page: `Overview`.
- CI validates ADF JSON, builds Bicep, runs static checks and scans secrets. It does not deploy.
- Production networking, separate environments, Log Analytics and enterprise ITSM are recommendations, not deployed features.

## What was intentionally not duplicated

- Architecture diagrams stay in `README.md` and `ARCHITECTURE.md`.
- Exact run IDs and screenshots stay in `EVIDENCE.md`.
- The detailed case-to-evidence table stays in `REQUIREMENTS_TRACEABILITY_MATRIX.md`.
- Deployment topology stays in `CICD_PROMOTION.md`.
- The master guide teaches concepts and links to those sources rather than copying every table and screenshot.
