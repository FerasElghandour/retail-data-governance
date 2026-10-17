# Retail Data Governance and Master-Data Matching

**Feras Elghandour**

Create a consistent metadata and matching design across fragmented retail user, listing, order, inventory, and support systems.

## Implementation

A conceptual enterprise data model, an eight-table metadata dictionary, four candidate-matching rules, quality controls, governance ownership, and a consolidation-style master-data design. PostgreSQL rules are retained alongside a runnable SQLite fixture adapter.

```mermaid
flowchart LR
 A[Five source systems] --> B[Catalog and quality rules]
 B --> C[Consolidation hub]
 C --> D[Candidate matching]
 D --> E[Steward review and golden records]
```

## Evidence and results

The design spans **five source systems, eight tables, and four matching rules**. Five fixture tests validate normalized email candidates, rejection of blank-email matches, shared-email ambiguity, missing-email name fallback, and the 45-day temporal boundary. The dashboard in the original design was a mockup; no operating enterprise deployment or measured data-quality improvement is claimed.

## Run locally

Python 3.11 or later; use an isolated environment.

```sh
python -m unittest discover -s tests -v
```

Read `catalog/data_dictionary.csv`, `DESIGN.md`, and `sql/postgresql_matching.sql`. The tests execute the four corresponding SQLite SELECT rules on synthetic records. PostgreSQL statements require source schemas and a separately provisioned MDM schema; a PostgreSQL server was not exercised in this release.

## Scope and limitations

Matching outputs are candidate links for review, not automatic golden-record merges. Email addresses can be shared or reassigned; sellers can own identical items. Operational uptime, retention periods, and remediation targets are design assumptions requiring organizational review.

[Validation record](VALIDATION.md) · [Inputs and applicable notices](DATA.md)
