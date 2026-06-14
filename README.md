# NLCSP Research Project - Data Requirements Assessment, EMR & REDCap Extraction, and Reporting Workflow
---
## Research Question

> Among NLCSP participants referred to Peter MacCallum Cancer Centre following
> a Lung-RADS 4B or 4X screen result, what is the median time from screen
> detection to commencement of first-line chemotherapy and does this differ
> between Lung-RADS 4B and 4X?

---

## Project Purpose

This project simulates the end-to-end research health data analyst workflow.
It was developed to demonstrate applied understanding of how clinical and
research data are used to support health services research, reporting, and
service improvement in a cancer centre.

**This project does not use real patient data. All datasets were random manual entries.**

---

## Clinical Context

The National Lung Cancer Screening Program (NLCSP) uses low-dose CT (LDCT)
to screen high-risk Australians aged 50–74. As a radiographer, I routinely scan 
these high-risk patients, following strict eligibility requirements.

| Lung-RADS | Meaning | Action |
|---|---|---|
| 1–2 | Negative / Benign | Routine annual screening |
| 3 | Probably benign | 6-month follow-up CT |
| 4A | Suspicious (5–15% malignancy risk) | 3-month follow-up CT |
| 4B | Highly suspicious (>15% risk, nodule ≥15mm) |
| 4X | Very suspicious (alarming features any size) |

Not all referred patients proceed to chemotherapy. The clinical pathway is:
**Screen → Referral → Biopsy → Confirmed malignancy → Treatment decision → Chemotherapy**

---

## Project Files

| # | File | Description | Job Ad Responsibility |
|---|---|---|---|
| 1 | `artefact1_data_request.md` | Data request and requirements document | Assessing data requirements |
| 2 | `nlcsp_redcap.csv` | Simulated REDCap NLCSP dataset (n=100 screened) | REDCap data extraction |
| 3 | `nlcsp_epic.csv` | Simulated Epic EMR extract (n=10 referred) | Epic data extraction |
| 4 | `nlcsp_integrated.csv` | Linked analytical cohort (n=7 chemo patients) | Data integration |
| 5 | `artefact2_extraction_script.sql` | SQL extraction, JOIN, quality checks, analysis | Analytical workflow design |
| 6 | `artefact3_report_output.png` | Reporting dashboard (3 panels) | Reporting outputs |
| 7 | `artefact3_process_log.md` | Data process log and findings summary | Documenting data processes |
| 8 | `README.md` | This file | Project overview |

---

## Workflow Summary

### Step 1 — Data Requirements Assessment (Artefact 1)
Defined the research question, mapped required variables to their REDCap
fields and Epic sources (with HL7 FHIR R4 resource mapping), documented
the expected clinical pathway funnel, and completed the governance checklist
before any data was touched.

### Step 2 — REDCap Extraction (nlcsp_redcap.csv)
Simulated a REDCap Data Export of the full NLCSP screened cohort (n=100).
Contains all Lung-RADS scores (1 through 4X) and referral status.
SQL filter: `lung_rads_score IN ('4B','4X') AND referred_to_petmac = 'Yes'`
reduces cohort to 10 referred participants.

### Step 3 — Epic Extraction (nlcsp_epic.csv)
Simulated an Epic EMR extract for the 10 referred patients only.
Variables mapped to FHIR resources (Patient, Condition, Procedure,
MedicationAdministration). Includes biopsy date, malignancy confirmation,
and first chemotherapy date — making the full clinical pathway visible.

### Step 4 — Data Integration (nlcsp_integrated.csv)
INNER JOIN on pseudonymised `patient_id`. Derived primary outcome variable
`screen_to_treatment_days`. Applied analytical cohort filter:
confirmed malignant AND commenced chemotherapy → n=7.

### Step 5 — SQL Analytical Workflow (artefact2_extraction_script.sql)
Structured in 6 steps: REDCap extract → Epic extract → JOIN → clinical
pathway funnel → data quality checks → primary analysis by Lung-RADS
subcategory. Each Epic field annotated with its FHIR resource and element.

### Step 6 — Reporting Output (artefact3_report_output.png)
Three-panel dashboard:
- Panel 1: Full Lung-RADS distribution across 100 screened participants
- Panel 2: Clinical pathway funnel (100 → 10 → 8 → 7)
- Panel 3: Median screen-to-chemo time by Lung-RADS subcategory (4B vs 4X)

### Step 7 — Process Log (artefact3_process_log.md)
Documents extraction methods, FHIR mappings used, linkage approach, data
quality findings, decisions made during analysis, governance confirmation,
and learnings for future requests — to document data processes to support 
sustainable, collaborative models of clinical data use.

---

## Key Findings (Simulated Data)

- **100 participants screened** → 10 Lung-RADS 4B/4X → 8 confirmed malignant
  → **7 commenced first-line chemotherapy**
- **Overall median screen-to-chemotherapy: 59 days**
- **Lung-RADS 4X: median 49 days** vs **Lung-RADS 4B: median 59 days**
- 4X patients reach treatment faster, consistent with clinical urgency of
  their imaging findings

---

## Technologies Used

- **Python** (csv, datetime, pandas, matplotlib) — data generation,
  analysis, visualisation
- **SQL** — data extraction, integration, quality checks, summary analytics
- **HL7 FHIR R4** — variable mapping to Epic data structures
- **Markdown** — documentation, data request, process log

---

## Overview

Designed and executed a simulated end-to-end research data analyst 
workflow based on a National Lung Cancer Screening Program (NLCSP) research 
question at a cancer centre context. Produced a formal data request and 
requirements document mapping variables to their Epic EMR sources using HL7/FHIR 
resource notation. Simulated extraction from REDCap (n=100 screened 
participants, Lung-RADS scoring) and Epic EMR (n=10 referred patients), 
linked datasets via pseudonymised patient ID using SQL, and applied clinical 
pathway filters to derive an analytical cohort. Documented data quality checks, 
extraction decisions, and reusable process learnings consistent with research 
data governance and ethics frameworks. Produced a three-panel reporting dashboard 
communicating screening funnel attrition and median screen-to-chemotherapy 
intervals by Lung-RADS subcategory (4B vs 4X).
