-- ============================================================
-- Extraction & Integration Script

-- Research Question:
--   Among NLCSP participants referred to Peter Mac following
--   a Lung-RADS 4B or 4X screen result who received a
--   confirmed malignant diagnosis, what is the median time
--   from screen detection to commencement of first-line
--   chemotherapy — and does this differ between 4B and 4X?
--
-- Data Sources:
--   nlcsp_redcap  — REDCap NLCSP screening dataset (n=100)
--   nlcsp_epic    — Epic EMR extract (n=10 referred patients)
-- ============================================================


-- ============================================================
-- STEP 1: EXTRACT FROM REDCAP
-- Source: NLCSP REDCap project
--
-- Filter to Lung-RADS 4B and 4X only:
--   4B = Highly suspicious (malignancy risk >15%, nodule ≥15mm)
--   4X = Very suspicious (concerning features regardless of size)
--   4A excluded — these patients receive follow-up CT first,
--   not immediate referral
--
-- FHIR note: The NLCSP screen result would be transmitted as
-- a FHIR DiagnosticReport resource, with Lung-RADS score as
-- an Observation (Observation.valueCodeableConcept).
-- ============================================================

CREATE VIEW IF NOT EXISTS vw_redcap_extract AS
SELECT
    patient_id,
    screen_date,
    lung_rads_score,
    referred_to_petmac
FROM nlcsp_redcap
WHERE lung_rads_score IN ('4B', '4X')
  AND referred_to_petmac = 'Yes';


-- ============================================================
-- STEP 2: EXTRACT FROM EPIC
-- Source: Epic EMR — approved data extract
--
-- Variables mapped to HL7 FHIR R4 resources:
--   confirmed_malignant → Condition.verificationStatus
--                         (value: 'confirmed')
--   diagnosis_date      → Condition.onsetDateTime
--   first_chemo_date    → MedicationAdministration.effective
--   treatment_type      → MedicationRequest.medicationCodeableConcept
--   age_group           → derived from Patient.birthDate
--
-- In Epic, chemotherapy administration records sit in the
-- Medication Administration Record (MAR) module, accessible
-- via Reporting Workbench or Clarity.
-- ============================================================

CREATE VIEW IF NOT EXISTS vw_epic_extract AS
SELECT
    patient_id,
    lung_rads_score,
    age_group,
    biopsy_date,
    confirmed_malignant,
    diagnosis_date,
    commenced_chemo,
    first_chemo_date
FROM nlcsp_epic;


-- ============================================================
-- STEP 3: INTEGRATE - JOIN REDCAP + EPIC
-- Link on pseudonymised patient_id.
-- INNER JOIN retains only patients present in both systems.
-- ============================================================

CREATE VIEW IF NOT EXISTS vw_referred_cohort AS
SELECT
    r.patient_id,
    r.screen_date,
    r.lung_rads_score,
    e.age_group,
    e.biopsy_date,
    e.confirmed_malignant,
    e.diagnosis_date,
    e.commenced_chemo,
    e.first_chemo_date,

    -- Derived: days from screen to biopsy
    CAST(JULIANDAY(e.biopsy_date) - JULIANDAY(r.screen_date) AS INTEGER)
        AS screen_to_biopsy_days,

    -- Derived: days from screen to confirmed diagnosis
    CASE WHEN e.confirmed_malignant = 'Yes'
         THEN CAST(JULIANDAY(e.diagnosis_date) - JULIANDAY(r.screen_date) AS INTEGER)
         ELSE NULL END AS screen_to_diagnosis_days,

    -- Derived: primary outcome — screen to first chemotherapy
    CASE WHEN e.commenced_chemo = 'Yes'
         THEN CAST(JULIANDAY(e.first_chemo_date) - JULIANDAY(r.screen_date) AS INTEGER)
         ELSE NULL END AS screen_to_treatment_days

FROM vw_redcap_extract r
INNER JOIN vw_epic_extract e
    ON r.patient_id = e.patient_id;


-- ============================================================
-- STEP 4: CLINICAL PATHWAY FUNNEL
-- Summarise patient flow through the screening-to-treatment
-- pathway. Documents at each step.
-- ============================================================

SELECT
    COUNT(*)                                                AS referred_n,
    SUM(CASE WHEN confirmed_malignant = 'Yes' THEN 1 END)  AS confirmed_malignant_n,
    SUM(CASE WHEN commenced_chemo     = 'Yes' THEN 1 END)  AS commenced_chemo_n
FROM vw_referred_cohort;


-- ============================================================
-- STEP 5: DATA QUALITY CHECKS
-- Flag chronological anomalies before analysis.
-- ============================================================

SELECT
    patient_id,
    screen_date,
    biopsy_date,
    diagnosis_date,
    first_chemo_date,
    CASE
        WHEN biopsy_date < screen_date
            THEN 'ERROR: Biopsy before screen'
        WHEN confirmed_malignant = 'Yes' AND diagnosis_date < biopsy_date
            THEN 'ERROR: Diagnosis before biopsy'
        WHEN commenced_chemo = 'Yes' AND first_chemo_date < diagnosis_date
            THEN 'ERROR: Chemo before diagnosis'
        WHEN confirmed_malignant = 'Yes' AND diagnosis_date IS NULL
            THEN 'MISSING: Diagnosis date'
        WHEN commenced_chemo = 'Yes' AND first_chemo_date IS NULL
            THEN 'MISSING: Chemo date'
        ELSE 'OK'
    END AS quality_flag
FROM vw_referred_cohort
WHERE quality_flag != 'OK';


-- ============================================================
-- STEP 6: PRIMARY ANALYSIS
-- Analytical cohort: confirmed malignant AND commenced chemo
-- ============================================================

-- Overall median screen-to-treatment time
SELECT
    COUNT(*)                                        AS n,
    ROUND(AVG(screen_to_treatment_days), 1)         AS mean_days,
    ROUND(MIN(screen_to_treatment_days), 1)         AS min_days,
    ROUND(MAX(screen_to_treatment_days), 1)         AS max_days
FROM vw_referred_cohort
WHERE confirmed_malignant = 'Yes'
  AND commenced_chemo = 'Yes';


-- Breakdown by Lung-RADS subcategory (4B vs 4X)
-- Hypothesis: 4X patients (most aggressive findings)
-- move faster to treatment than 4B patients
SELECT
    lung_rads_score,
    COUNT(*)                                        AS n,
    ROUND(AVG(screen_to_treatment_days), 1)         AS mean_days
FROM vw_referred_cohort
WHERE confirmed_malignant = 'Yes'
  AND commenced_chemo = 'Yes'
GROUP BY lung_rads_score
ORDER BY lung_rads_score;
