-- ============================================
-- Healthcare Utilization & Cost Analysis
-- Data Quality Checks
-- ============================================

-- Patient count
SELECT COUNT(*) AS patient_count
FROM patients;

-- Raw encounter count
SELECT COUNT(*) AS raw_encounter_count
FROM encounters_raw;

-- Valid encounters with matching patients
SELECT COUNT(*) AS valid_encounter_count
FROM encounters_raw e
INNER JOIN patients p
    ON e.patient = p.id;

-- Encounters without a matching patient
SELECT COUNT(*) AS unmatched_encounters
FROM encounters_raw e
LEFT JOIN patients p
    ON e.patient = p.id
WHERE p.id IS NULL;

-- Check for duplicate patient IDs
SELECT id, COUNT(*)
FROM patients
GROUP BY id
HAVING COUNT(*) > 1;

-- Check for duplicate encounter IDs
SELECT id, COUNT(*)
FROM encounters
GROUP BY id
HAVING COUNT(*) > 1;
