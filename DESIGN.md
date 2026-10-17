# Governance design and matching decisions

The conceptual catalog covers user, listing, order, inventory, and support systems across eight tables. A consolidation hub supports metadata discovery, standardized terms, data-quality reporting, and steward-reviewed candidate matches while leaving source-system operation separate.

## Quality controls

Minimize payment information and use a payment-provider token rather than storing a full card number. Standardize order-status vocabulary. Resolve duplicate customer attributes through explicit ownership and source priority. Monitor orphan listings and inventory associations. Retention periods, access policies, service-level targets and compliance assertions require organization-specific review; this design does not certify them.

## Matching and ambiguity

Four rules generate candidates: normalized nonempty email, full-name fallback where support email is absent, seller-plus-item attributes, and seller/type/gender within a 45-day listing window. None of these proves unique identity. Shared or reassigned emails, common names, duplicate physical items, and competing candidate links require stewardship. Do not merge or overwrite source records automatically.

The public dictionary omits original example values. The PostgreSQL script expresses the proposed source-schema joins. A SQLite adapter and five synthetic tests verify SELECT behavior and boundary cases; they do not establish PostgreSQL deployment or production-scale matching accuracy.
