
-- =========================================================
-- Phase 6.2: Medication Utilization and Affordability Analysis
-- =========================================================


-- =========================================================
-- 1. Data Cleaning
-- =========================================================

CREATE TABLE medications AS
SELECT
    m.start_date,
    m.stop_date,
    m.patient,
    m.payer,
    m.encounter,
    m.code,
    m.description,
    m.base_cost,
    m.payer_coverage,
    m.dispenses,
    m.totalcost,
    m.reasoncode,

    -- Recover verified missing reason description
    CASE
        WHEN m.reasoncode = '271737000'
             AND m.reasondescription IS NULL
        THEN 'Anemia (disorder)'
        ELSE m.reasondescription
    END AS reasondescription,

    -- Validate patient reference
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM patients p
            WHERE p.id = m.patient
        )
        THEN 'matched'
        ELSE 'unmatched'
    END AS patient_match_status,

    -- Validate encounter reference
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM encounters e
            WHERE e.id = m.encounter
        )
        THEN 'matched'
        ELSE 'unmatched'
    END AS encounter_match_status

FROM medications_raw m;


-- =========================================================
-- 2. Data Validation
-- =========================================================

-- Confirm total medication records
SELECT COUNT(*) AS total_medication_records
FROM medications;


-- Check patient reference matches
SELECT
    patient_match_status,
    COUNT(*) AS medication_records
FROM medications
GROUP BY patient_match_status;


-- Check encounter reference matches
SELECT
    encounter_match_status,
    COUNT(*) AS medication_records
FROM medications
GROUP BY encounter_match_status;


-- Check for duplicate medication records
SELECT
    COUNT(*) AS duplicate_records
FROM (
    SELECT
        start_date,
        stop_date,
        patient,
        payer,
        encounter,
        code,
        description,
        base_cost,
        payer_coverage,
        dispenses,
        totalcost,
        reasoncode,
        reasondescription
    FROM medications
    GROUP BY
        start_date,
        stop_date,
        patient,
        payer,
        encounter,
        code,
        description,
        base_cost,
        payer_coverage,
        dispenses,
        totalcost,
        reasoncode,
        reasondescription
    HAVING COUNT(*) > 1
) AS duplicates;


-- Check missing values in important fields
SELECT
    COUNT(*) FILTER (WHERE start_date IS NULL) AS missing_start_dates,
    COUNT(*) FILTER (WHERE patient IS NULL) AS missing_patient_ids,
    COUNT(*) FILTER (WHERE code IS NULL) AS missing_medication_codes,
    COUNT(*) FILTER (WHERE description IS NULL) AS missing_descriptions,
    COUNT(*) FILTER (WHERE base_cost IS NULL) AS missing_base_costs,
    COUNT(*) FILTER (WHERE payer_coverage IS NULL) AS missing_payer_coverage,
    COUNT(*) FILTER (WHERE dispenses IS NULL) AS missing_dispenses,
    COUNT(*) FILTER (WHERE totalcost IS NULL) AS missing_total_costs
FROM medications;


-- Validate medication cost calculations
SELECT COUNT(*) AS cost_mismatches
FROM medications
WHERE ROUND(base_cost * dispenses, 2)
      <> ROUND(totalcost, 2);


-- Check whether payer coverage exceeds base cost
SELECT COUNT(*) AS coverage_exceeds_base_cost
FROM medications
WHERE payer_coverage > base_cost;


-- =========================================================
-- 3. Top Medications and Patient Distribution
-- =========================================================

SELECT
    description,
    COUNT(*) AS medication_records,

    COUNT(DISTINCT patient) FILTER (
        WHERE patient_match_status = 'matched'
    ) AS unique_patients,

    ROUND(
        COUNT(DISTINCT patient) FILTER (
            WHERE patient_match_status = 'matched'
        ) * 100.0 /
        (SELECT COUNT(*) FROM patients),
        2
    ) AS percentage_of_patients

FROM medications
GROUP BY description
ORDER BY medication_records DESC
LIMIT 15;


-- =========================================================
-- 4. Distribution of Payer Coverage
-- =========================================================

SELECT
    CASE
        WHEN payer_coverage = 0
            THEN 'Zero Coverage'
        WHEN payer_coverage >= base_cost
            THEN 'Full Coverage'
        ELSE 'Partial Coverage'
    END AS coverage_category,

    COUNT(*) AS medication_records,

    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM medications),
        2
    ) AS percentage_of_medication_records

FROM medications
GROUP BY coverage_category
ORDER BY medication_records DESC;


-- =========================================================
-- 5. Medication Costs and Payer Coverage Analysis
-- =========================================================

SELECT
    description,
    COUNT(*) AS medication_records,

    ROUND(AVG(base_cost), 2) AS avg_base_cost,

    ROUND(AVG(payer_coverage), 2) AS avg_payer_coverage,

    ROUND(
        AVG(base_cost - payer_coverage),
        2
    ) AS avg_uncovered_cost

FROM medications
GROUP BY description
ORDER BY avg_uncovered_cost DESC;


-- =========================================================
-- 6. Total Uncovered Costs per Medication 
-- =========================================================

SELECT
    description,
    COUNT(*) AS medication_records,

    ROUND(
        AVG(base_cost - payer_coverage),
        2
    ) AS avg_uncovered_cost,

    ROUND(
        SUM(base_cost - payer_coverage),
        2
    ) AS total_uncovered_cost

FROM medications
GROUP BY description
ORDER BY total_uncovered_cost DESC
LIMIT 10;


-- =========================================================
-- 7. Patient Reach vs. Medication Cost
-- =========================================================

SELECT
    description,
    COUNT(*) AS medication_records,

    COUNT(DISTINCT patient) FILTER (
        WHERE patient_match_status = 'matched'
    ) AS unique_patients,

    ROUND(
        COUNT(DISTINCT patient) FILTER (
            WHERE patient_match_status = 'matched'
        ) * 100.0 /
        (SELECT COUNT(*) FROM patients),
        2
    ) AS percentage_of_population,

    ROUND(
        AVG(base_cost - payer_coverage),
        2
    ) AS avg_uncovered_cost,

    ROUND(
        SUM(base_cost - payer_coverage),
        2
    ) AS total_uncovered_cost

FROM medications
GROUP BY description
ORDER BY total_uncovered_cost DESC
LIMIT 10;

	