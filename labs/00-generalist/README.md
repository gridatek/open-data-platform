# 00 Generalist → CDP Generalist (CDP-0011)

Platform concepts and the **SDX model**: how interchangeable engines all read and
write *one* governed data layer. This is the idea the whole platform exists to
teach — the engines are commodities; the governed shared data is the product.

## Labs

| # | Lab | What you'll see |
|---|-----|-----------------|
| 01 | [The SDX model — one table, many engines](lab-01-the-sdx-model.md) | Spark writes a table; Trino and Superset read it; Ranger masks a column; Atlas shows lineage — all over the same Iceberg table. |

## Concepts covered

- The two layers of modern CDP: the **shared data + governance layer** (SDX) and
  the **containerized data services** that operate on it.
- Why a table format (**Iceberg**) + a shared catalog (**REST catalog**) +
  shared governance (**Ranger/Atlas**) is the differentiator.
- How a single policy is enforced no matter which engine runs the query.

> **On real CDP:** this is exactly the mental model the Generalist exam tests —
> SDX as the common substrate beneath CDE, CDW, CDF, CML and the Operational DB.
