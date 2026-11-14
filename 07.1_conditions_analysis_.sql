
-- ============================================================
-- Phase 6.1: Conditions Analysis
-- ============================================================


-- ============================================================
-- 6.1.1 Create Raw Conditions Table
-- ============================================================

CREATE TABLE conditions_raw (
    start_date DATE,
    stop_date DATE,
    patient VARCHAR(50),
    encounter VARCHAR(50),
    system VARCHAR(100),
    code VARCHAR(50),
    description TEXT
);


-- ============================================================
-- 6.1.2 Data Quality Checks
-- ============================================================

-- Check total records and missing values
SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (WHERE start_date IS NULL) AS missing_start_dates,
    COUNT(*) FILTER (WHERE patient IS NULL) AS missing_patients,
    COUNT(*) FILTER (WHERE encounter IS NULL) AS missing_encounters,
    COUNT(*) FILTER (WHERE code IS NULL) AS missing_codes,
    COUNT(*) FILTER (WHERE description IS NULL) AS missing_descriptions
FROM conditions_raw;


-- Check date ranges
SELECT
    MIN(start_date) AS earliest_condition,
    MAX(start_date) AS latest_condition,
    MIN(stop_date) AS earliest_stop_date,
    MAX(stop_date) AS latest_stop_date
FROM conditions_raw;


-- Identify duplicate condition records
SELECT
    patient,
    encounter,
    code,
    description,
    COUNT(*) AS duplicate_count
FROM conditions_raw
GROUP BY patient, encounter, code, description
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- ============================================================
-- 6.1.3 Check Patient and Encounter Relationships
-- ============================================================

-- Find condition records with unmatched patient IDs
SELECT COUNT(*) AS unmatched_patient_records
FROM conditions_raw c
LEFT JOIN patients p ON c.patient = p.id
WHERE p.id IS NULL;


-- Count distinct unmatched patients
SELECT COUNT(DISTINCT c.patient) AS unmatched_patients
FROM conditions_raw c
LEFT JOIN patients p ON c.patient = p.id
WHERE p.id IS NULL;


-- Check whether unmatched patients exist in patients_raw
SELECT COUNT(DISTINCT c.patient) AS patients_found_in_raw
FROM conditions_raw c
JOIN patients_raw p ON c.patient = p.id
LEFT JOIN patients clean ON c.patient = clean.id
WHERE clean.id IS NULL;


-- Find condition records with unmatched encounter IDs
SELECT COUNT(*) AS unmatched_encounter_records
FROM conditions_raw c
JOIN patients p ON c.patient = p.id
LEFT JOIN encounters e ON c.encounter = e.id
WHERE e.id IS NULL;


-- Distinguish missing encounter IDs from unmatched IDs
SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE c.encounter IS NULL
    ) AS missing_encounter_ids,
    COUNT(*) FILTER (
        WHERE c.encounter IS NOT NULL AND e.id IS NULL
    ) AS encounter_ids_not_found
FROM conditions_raw c
JOIN patients p ON c.patient = p.id
LEFT JOIN encounters e ON c.encounter = e.id
WHERE e.id IS NULL;


-- Check whether unmatched encounters exist in encounters_raw
SELECT COUNT(*) AS encounters_found_in_raw
FROM conditions_raw c
JOIN patients p ON c.patient = p.id
JOIN encounters_raw er ON c.encounter = er.id
LEFT JOIN encounters e ON c.encounter = e.id
WHERE e.id IS NULL;


-- Check patient and encounter consistency
SELECT COUNT(*) AS patient_encounter_mismatches
FROM conditions_raw c
JOIN patients p ON c.patient = p.id
JOIN encounters e ON c.encounter = e.id
WHERE e.patient <> c.patient;


-- ============================================================
-- 6.1.4 Create and Populate Cleaned Conditions Table
-- ============================================================

CREATE TABLE conditions (
    condition_id BIGSERIAL PRIMARY KEY,
    start_date DATE,
    stop_date DATE,
    patient VARCHAR(50) NOT NULL,
    encounter VARCHAR(50),
    system VARCHAR(100),
    code VARCHAR(50),
    description TEXT,
    FOREIGN KEY (patient) REFERENCES patients(id),
    FOREIGN KEY (encounter) REFERENCES encounters(id)
);


-- Insert valid patient records and handle unmatched encounters
INSERT INTO conditions (
    start_date,
    stop_date,
    patient,
    encounter,
    system,
    code,
    description
)
SELECT
    c.start_date,
    c.stop_date,
    c.patient,
    CASE
        WHEN e.id IS NOT NULL THEN c.encounter
        ELSE NULL
    END AS encounter,
    c.system,
    c.code,
    c.description
FROM conditions_raw c
JOIN patients p ON c.patient = p.id
LEFT JOIN encounters e ON c.encounter = e.id;


-- ============================================================
-- 6.1.5 Most Common Conditions
-- ============================================================

SELECT
    description,
    COUNT(*) AS num_of_records,
    COUNT(DISTINCT patient) AS num_of_patients
FROM conditions
GROUP BY description
ORDER BY num_of_records DESC
LIMIT 20;


-- ============================================================
-- 6.1.6 Most Common Disorders
-- ============================================================

SELECT
    description,
    COUNT(*) AS total_records,
    COUNT(DISTINCT patient) AS num_of_patients
FROM conditions
WHERE description LIKE '%(disorder)'
GROUP BY description
ORDER BY total_records DESC
LIMIT 15;


-- ============================================================
-- 6.1.7 Patients with the Most Disorders
-- ============================================================

SELECT
    patient,
    COUNT(DISTINCT code) AS number_of_disorders
FROM conditions
WHERE description LIKE '%(disorder)'
GROUP BY patient
ORDER BY number_of_disorders DESC
LIMIT 20;


-- ============================================================
-- 6.1.8 Disorders vs. Healthcare Utilization
-- ============================================================

WITH patient_disorder AS (
    SELECT
        patient,
        COUNT(DISTINCT code) AS number_of_disorders
    FROM conditions
    WHERE description LIKE '%(disorder)'
    GROUP BY patient
),
patient_utilization AS (
    SELECT
        patient,
        COUNT(*) AS number_of_encounters
    FROM encounters
    GROUP BY patient
)
SELECT
    pd.patient,
    pd.number_of_disorders,
    pu.number_of_encounters
FROM patient_disorder pd
JOIN patient_utilization pu
    ON pd.patient = pu.patient
ORDER BY pd.number_of_disorders DESC
LIMIT 20;


-- ============================================================
-- 6.1.9 Disorder Counts vs. Utilization Correlation (r=0.632)
-- ============================================================

WITH patient_disorder AS (
    SELECT
        patient,
        COUNT(DISTINCT code) AS number_of_disorders
    FROM conditions
    WHERE description LIKE '%(disorder)'
    GROUP BY patient
),
patient_utilization AS (
    SELECT
        patient,
        COUNT(*) AS number_of_encounters
    FROM encounters
    GROUP BY patient
)
SELECT
    ROUND(
        CORR(
            pd.number_of_disorders,
            pu.number_of_encounters
        )::numeric,
        3
    ) AS utilization_disorder_correlation
FROM patient_disorder pd
JOIN patient_utilization pu
    ON pd.patient = pu.patient;
