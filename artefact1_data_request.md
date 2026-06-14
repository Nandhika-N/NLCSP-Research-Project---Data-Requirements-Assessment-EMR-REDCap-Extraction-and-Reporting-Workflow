# Data Request & Requirements Document

---

**Date Submitted:** June 2026
**Prepared by:** Research Data Analyst
**Status:** Approved — data extraction in progress

---

## 1. Research Question

> Among NLCSP participants referred to Peter MacCallum Cancer Centre following a
> Lung-RADS 4B or 4X screen result, what is the median time from screen detection
> to commencement of first-line chemotherapy — and does this differ between
> Lung-RADS 4B and 4X?

---

## 2. Background

Peter MacCallum Cancer Centre is a participating site in Australia's National Lung
Cancer Screening Program (NLCSP). The NLCSP uses low-dose CT (LDCT) to screen
high-risk individuals aged 50–74 who are current or former smokers.

Screening results are reported using the Lung-RADS system (American College
of Radiology). Participants scoring Lung-RADS 4B or 4X are referred immediately
for tissue diagnosis and oncology workup:

- **Lung-RADS 4B** — Highly suspicious. Malignancy risk >15%. Solid nodules ≥15mm.
  Referred for PET/CT and tissue sampling.
- **Lung-RADS 4X** — Very suspicious. Concerning features (e.g. spiculated margins,
  lymphadenopathy) regardless of nodule size. Referred for immediate diagnostic
  evaluation.
- **Lung-RADS 4A** — Suspicious but lower risk (5–15%). These patients receive a
  follow-up LDCT in 3 months and are NOT included in this cohort.

This analysis quantifies the median screen-to-chemotherapy interval to support
internal service planning and NLCSP program outcome reporting.

---

## 3. Data Requirements

### 3.1 Source 1 — REDCap (NLCSP Research Dataset)

REDCap is used to capture NLCSP participant screening data as part
of the study protocol. The data dictionary was reviewed prior to this request
to confirm field availability and coding.

| Variable              | REDCap Field Name    | Type   | Description                               |
| --------------------- | -------------------- | ------ | ----------------------------------------- |
| Patient ID            | `patient_id`         | Text   | De-identified pseudonymised study ID      |
| Screen date           | `screen_date`        | Date   | Date of LDCT screen                       |
| Lung-RADS score       | `lung_rads_score`    | Text   | ACR Lung-RADS score (1, 2, 3, 4A, 4B, 4X) |
| Referred to Peter Mac | `referred_to_petmac` | Yes/No | Whether participant was referred          |

**Inclusion filter:** `lung_rads_score IN ('4B','4X')` AND `referred_to_petmac = 'Yes'`

**Export method:** REDCap Data Export tool → CSV format, labelled fields,
de-identified option selected. Data dictionary reviewed prior to export to
confirm field validation rules and coding.

---

### 3.2 Source 2 — Epic EMR (Mapped to HL7 FHIR R4 Resources)

Epic is the main EMR system used. Data is accessed via
an approved extraction through a data request pathway, using
Reporting Workbench for the initial cohort pull and the Clarity data warehouse
(SQL) for detailed variable extraction.

| Variable            | Epic Source               | FHIR R4 Resource           | FHIR Element                         |
| ------------------- | ------------------------- | -------------------------- | ------------------------------------ |
| Patient ID          | MRN (pseudonymised)       | `Patient`                  | `Patient.identifier`                 |
| Age group           | Date of birth (derived)   | `Patient`                  | `Patient.birthDate`                  |
| Lung-RADS score     | Referral reason           | `ServiceRequest`           | `ServiceRequest.reasonCode`          |
| Biopsy date         | Procedure record          | `Procedure`                | `Procedure.performedDateTime`        |
| Confirmed malignant | Problem list / pathology  | `Condition`                | `Condition.verificationStatus`       |
| Diagnosis date      | Problem list              | `Condition`                | `Condition.onsetDateTime`            |
| Commenced chemo     | Medication administration | `MedicationAdministration` | `MedicationAdministration.status`    |
| First chemo date    | Medication administration | `MedicationAdministration` | `MedicationAdministration.effective` |

**Extraction method:** Reporting Workbench (initial cohort); Clarity MAR_ADMIN
and PROBLEM_LIST tables (detailed variable extraction via SQL).

---

### 3.3 Derived Variable

| Variable                   | Derivation                         | Purpose             |
| -------------------------- | ---------------------------------- | ------------------- |
| `screen_to_biopsy_days`    | `biopsy_date` − `screen_date`      | Pathway interval    |
| `screen_to_diagnosis_days` | `diagnosis_date` − `screen_date`   | Pathway interval    |
| `screen_to_treatment_days` | `first_chemo_date` − `screen_date` | **Primary outcome** |

---

## 4. Clinical Pathway & Expected Cohort Attrition

Not all referred patients will progress to chemotherapy. The expected pathway is:

```
100 screened
  └─ 10 Lung-RADS 4B or 4X → referred to Peter Mac
       └─ 8 confirmed malignant on biopsy
            └─ 7 commenced first-line chemotherapy
                 (1 malignant patient proceeded to surgery instead)
```

This will be documented in the process log and the SQL filter
will be applied at each step.

---

## 5. Data Linkage

The two datasets are linked on `patient_id` (pseudonymised study ID).
The mapping between this ID and the real Peter Mac MRN is held by the
data custodian and is not accessible to the analyst.

**Linkage type:** INNER JOIN on `patient_id`.

---

## 6. Governance & Ethics Checklist

| Item                     | Status                                                                               | Notes                                     |
| ------------------------ | ------------------------------------------------------------------------------------ | ----------------------------------------- |
| HREC approval            | ✓ Approved                                                                           | Peter Mac HREC — Protocol                 |
| Site governance approval | ✓ Approved                                                                           | Research Governance Office                |
| Patient consent          | ✓ Obtained                                                                           | NLCSP participants consented at enrolment |
| De-identification        | ✓ Applied                                                                            | Name, exact DOB, full MRN not extracted   |
| Data access tier         | Analyst-level                                                                        | De-identified dataset only                |
| Storage                  | Peter Mac research data repository                                                   | Access-controlled; not stored locally     |
| Applicable frameworks    | Privacy Act 1988 (Cth), Health Records Act 2001 (Vic), NHMRC National Statement 2023 |                                           |

---

## 7. Data Quality Flags

The following will be checked on extraction and documented in the process log:

- Biopsy date before screen date (chronological error)
- Diagnosis date before biopsy date (data entry anomaly)
- First chemo date before diagnosis date (data entry anomaly)
- Confirmed malignant = Yes but diagnosis date missing
- Commenced chemo = Yes but first chemo date missing
- Lung-RADS score not recorded in REDCap

---

_All data is synthetic. No real patient records or Peter Mac systems were accessed._
