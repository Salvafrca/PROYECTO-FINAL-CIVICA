# 🏁 RC Car Set-ups · Data Engineering Final Project

**Finding the optimal set-up for a 1/8 off-road buggy using data.**

Final project of the **Cívica** *Data Engineer* course.
Author: **Salvador Franco Castilla**

`Snowflake` · `dbt` · `Power BI`

---

## 📌 Table of contents

1. [The problem](#-the-problem)
2. [The data](#-the-data)
3. [Data modeling](#-data-modeling)
4. [Medallion architecture](#-medallion-architecture)
5. [Incremental models and snapshots](#-incremental-models-and-snapshots)
6. [Results](#-results)
7. [Repository structure](#-repository-structure)
8. [How to run it](#-how-to-run-it)

---

## 🎯 The problem

In RC car racing, the **set-up** is the full set of adjustments made to the car: tyres, springs and shock absorbers, wings, differentials, steering and the electronic settings on the transmitter. The optimal set-up depends on the track and the weather.

Professionals find the set-up; amateurs copy it. This project proposes **applying engineering** instead: analysing race results and data to tune the car so it goes as fast as possible.

The project answers two questions:

| Case | Question |
|---|---|
| **1** | Which tyre is best for being fast on a **dirt track in the rain**? |
| **2** | What matters more for reaching the **podium**: having a mechanic or having a car that is not old? |

---

## 📊 The data

A **synthetic** dataset simulating a realistic season, delivered as a single denormalised CSV table (1 row = one driver's set-up in one race):

- 100 tracks (one per club) × 10 races per track × 25 drivers per race = **25,000 set-ups**
- 100 drivers and 1,000 races

**Assumptions:** no ties; a driver never owns two cars of the same model; a club never hosts two races on the same day; some drivers belong to no club.

**Errors introduced on purpose** to practise data cleaning (the CSV has **25,250 rows**):

- 249 duplicated set-ups (identical or with conflicting values)
- Nulls in mandatory columns
- Values outside the allowed list (typos such as «Usdo», abbreviations such as «B»)
- Out-of-range values and wrong units (999 °C, wings at 360°)
- Dates in three different formats → unified to `YYYY-MM-DD`

> In bronze everything is loaded as text: the load never fails and cleaning happens in dbt.

---

## 🧩 Data modeling

**Conceptual.** Entities: Driver, Car, Model, Result, Club and Race.

- 1:N → Driver–Car · Club–Driver · Club–Race
- N:1 → Car–Model (the model lives in its own table to satisfy 3NF)
- N:M → Car–Race, resolved with the **Result** bridge table

**Logical and physical.** All tables in **3NF**, with primary keys, foreign keys and candidate keys (for example, the driver's racing licence). Each table has a natural key and a surrogate key (hash). Since Snowflake declares PKs and FKs but does not enforce them, **integrity is guaranteed with dbt tests**.

**Dimensional.** Silver in 3NF → gold as **star schemas**, one star per use case.
Grain: the result of one car in one race (24,943 facts; the 57 set-ups with no total time are excluded).

| Prefix | Content |
|---|---|
| `dim_` | Dimensions |
| `fct_` | Facts |
| `agg_` | The answer pre-computed for Power BI |

---

## 🥉🥈🥇 Medallion architecture

| Layer | Content | Tool | Rows |
|---|---|---|---|
| **Bronze** | Raw data as received, all text + `_loaded_at` | Snowflake | 25,250 |
| **Silver** | Clean, typed and in 3NF (6 `slv_` tables) | dbt | 25,000 |
| **Gold** | Ready for analysis: two star schemas | dbt → Power BI | 24,943 facts |

**Snowflake environment** (`CREACION_ENTORNO.sql`): warehouse, 6 databases (`DEV_` and `PRO_` × bronze, silver and gold), roles and grants. The PRO bronze database is created as a *zero-copy clone* of DEV. **dbt never writes to bronze: it only reads it as a source.**

**Silver in 3 steps:**

1. **Staging** (`stg_set_up__tabla_cruda`): 1:1 view over bronze; data types, dates to `DATE`, formats and closed value lists.
2. **Intermediate** (`int_set_up__limpio`): row-level rules (typos, ranges, units) and deduplication, keeping the most complete version of each set-up (Jinja loop).
3. **Six `slv_` tables**, one per entity: each attribute takes the most frequent value for its entity.

Staging `warn` tests become `error` in silver, with tests on PKs, candidate keys and FKs.

**Full build: 0 errors.**

---

## 🔄 Incremental models and snapshots

- **`slv_resultado`**: incremental model with the `merge` strategy, driven by bronze's `_loaded_at`.
- **Gold fact tables**: incremental with `delete+insert`.
- **`piloto_snapshot`**: keeps driver history (SCD type 2), surfaced in gold as `dim_caso02_piloto_historia`.
- `RECORRIDO_INCREMENTAL_PRO.sql`: repeatable script that demonstrates the full cycle (bronze → silver merge → snapshot → gold → Power BI) and restores the original state.

---

## 🏆 Results

### Case 1 · Tyre on dirt in the rain

A driver is **fast** when their average lap time is lower than the average lap time of their race.

| Tyre | Fast drivers | Drivers on that tyre | % fast |
|---|---|---|---|
| **Soft** | **607** | 916 | **66.3 %** |
| Medium | 68 | 209 | 32.5 % |
| Hard | 18 | 198 | 9.1 % |

➡️ **The soft tyre** is the best choice: it wins both on number of fast drivers and on effectiveness.

### Case 2 · Mechanic or a car that is not old?

**Podium** = position ≤ 3 by total time in each race. A 2×2 table measures each factor while holding the other fixed, as in a physics experiment:

| Podium rate | Car not old | Old car |
|---|---|---|
| **With mechanic** | **20.82 %** | 7.82 % |
| **Without mechanic** | 10.35 % | 4.35 % |

| With the other factor… | Effect of the mechanic | Effect of a car not old |
|---|---|---|
| present | +10.47 pp | **+13.00 pp** |
| absent | +3.47 pp | **+6.00 pp** |

➡️ **What matters most for reaching the podium is having a car that is not old.** Taken separately the two factors were tied; holding the other fixed, the car wins in every comparison. On top of that, a mechanic only makes the most of a car in good condition.

---

## 📁 Repository structure

```
PROYECTO-FINAL-CIVICA/
├── README.md
├── snowflake/          # SQL scripts: environment, bronze ingestion and incremental walkthrough
├── dbt/                # dbt project
│   ├── models/
│   │   ├── staging/set_up/
│   │   ├── silver/     # int_set_up__limpio + 6 slv_ tables
│   │   └── gold/
│   │       ├── caso_01/
│   │       └── caso_02/
│   ├── snapshots/      # piloto_snapshot
│   ├── macros/         # limpieza_staging.sql, generate_schema_name.sql
│   ├── dbt_project.yml
│   └── packages.yml    # dbt_utils
├── data/               # Source CSV
├── powerbi/            # Power BI report (.pbix)
└── docs/               # Project presentation and documentation
```

---

## ▶️ How to run it

1. In Snowflake, run `snowflake/CREACION_ENTORNO.sql` and then `snowflake/INGESTA_BRONCE.sql`.
2. Set up the dbt connection to Snowflake (DEV and PRO environments).
3. From the `dbt/` folder:
   ```bash
   dbt deps
   dbt build
   ```
4. Open the report in `powerbi/` with Power BI Desktop and refresh the data.

---

*Next season: applying it to my own race data.* 🏎️
