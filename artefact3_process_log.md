# Reporting Output & Data Process Log

## NLCSP Screen-to-Treatment Time Analysis

---

## Research Question

> Among NLCSP participants referred to Peter MacCallum Cancer Centre following a
> Lung-RADS 4B or 4X screen result, what is the median time from screen detection
> to commencement of first-line chemotherapy and does this differ between
> Lung-RADS 4B and 4X?

---

## Key Finding

> Among 7 NLCSP participants with confirmed malignancy who commenced
> first-line chemotherapy, the **overall median time from screen detection
> to first chemotherapy was 59 days.**
>
> Lung-RADS 4X patients reached chemotherapy faster (median 49 days) than
> Lung-RADS 4B patients (median 59 days), consistent with the clinical
> expectation that 4X findings are prioritised for urgent workup.

See attached workbook: nlcsp_reporting_dashboard.xlsx

---

## Clinical Pathway Funnel

| Step                                       | n     | Notes                                    |
| ------------------------------------------ | ----- | ---------------------------------------- |
| Total screened (NLCSP)                     | 100   | Full REDCap cohort                       |
| Lung-RADS 4B or 4X — referred to Peter Mac | 10    | SQL filter applied                       |
| Confirmed malignant on biopsy              | 8     | 2 benign biopsies excluded               |
| Commenced first-line chemotherapy          | 7     | 1 malignant patient proceeded to surgery |
| **Analytical cohort**                      | **7** | **Primary outcome calculated**           |

---

## Data Process Log

---

### Sources Extracted

| Source               | System | Records Extracted | Filter Applied                          |
| -------------------- | ------ | ----------------- | --------------------------------------- |
| NLCSP screening data | REDCap | 10 records        | Lung-RADS 4B or 4X, Referred = Yes      |
| EMR clinical data    | Epic   | 10 records        | Active oncology encounter post-referral |

**REDCap export method:** Data Export tool → CSV, labelled fields,
de-identified option selected. Data dictionary reviewed prior to export.

**Epic extraction method:** Reporting Workbench for initial cohort pull;
Clarity MAR_ADMIN and PROBLEM_LIST tables via SQL for detailed variables.
Results exported to Excel for reporting and delivered as nlcsp_reporting_dashboard.xlsx.

---

### FHIR Resource Mapping

The following FHIR R4 resource mappings were used to locate variables
within Epic's data structure:

| Variable            | FHIR Resource              | FHIR Element                         |
| ------------------- | -------------------------- | ------------------------------------ |
| Screen date         | `DiagnosticReport`         | `DiagnosticReport.effectiveDateTime` |
| Biopsy date         | `Procedure`                | `Procedure.performedDateTime`        |
| Confirmed malignant | `Condition`                | `Condition.verificationStatus`       |
| Diagnosis date      | `Condition`                | `Condition.onsetDateTime`            |
| First chemo date    | `MedicationAdministration` | `MedicationAdministration.effective` |

---

### Linkage

| Item            | Detail                                           |
| --------------- | ------------------------------------------------ |
| Method          | INNER JOIN on pseudonymised `patient_id`         |
| Records matched | 10 of 10 (100% linkage rate)                     |
| MRN mapping     | Held by data custodian — not accessed by analyst |

---

### Data Quality Findings

| Check                                           | Result    | Action             |
| ----------------------------------------------- | --------- | ------------------ |
| Biopsy date before screen date                  | 0 records | No action required |
| Diagnosis date before biopsy date               | 0 records | No action required |
| Chemo date before diagnosis date                | 0 records | No action required |
| Confirmed malignant with missing diagnosis date | 0 records | No action required |
| Commenced chemo with missing chemo date         | 0 records | No action required |

No data quality issues were identified in this simulated extract. In a real
extraction, anomalies would be queried back to the data custodian and
documented here prior to analysis proceeding.

---

### Decisions Made During Extraction

- **4A excluded from referral cohort:** Lung-RADS 4A participants receive
  a 3-month follow-up CT before referral and are not part of the
  immediate referral pathway.

- **Analytical cohort restricted to chemotherapy only:** One malignant
  patient (PM0074) proceeded to surgery rather than chemotherapy and
  was excluded from the primary outcome calculation. This is documented
  in the Epic dataset (`commenced_chemo = No`) and noted in the
  findings summary. A separate analysis of all treatment modalities
  could be conducted under a revised data request.

- **Age grouping:** Grouped as <65 and 65+ to align with NLCSP eligibility
  criteria and standard geriatric oncology reporting conventions.

---

### Governance Confirmation

- De-identified dataset only — no name, full DOB, or MRN in analytical file
- Dataset stored in research data repository (not locally)
- Analysis conducted within approved HREC scope
- Applicable frameworks: Privacy Act 1988 (Cth), Health Records Act 2001 (Vic),
  NHMRC National Statement on Ethical Conduct in Human Research (2023)

---

### Learnings for Future Requests

- REDCap NLCSP data and Epic EMR data linked cleanly on pseudonymised ID —
  this linkage pathway is reusable for future NLCSP-related research
  requests at Peter Mac.
- FHIR resource mapping documented above can be reused to accelerate
  future Epic extractions for chemotherapy-related research questions.
- The clinical pathway funnel (screened → referred → malignant → chemo)
  should be a standard template for all NLCSP outcome analyses.
- Recommend this process be added to the data request template library
  to support sustainable, collaborative models of clinical data use.

---
