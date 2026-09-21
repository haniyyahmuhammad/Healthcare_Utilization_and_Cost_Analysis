-- ============================================================
-- Healthcare Utilization Analysis
-- Utilization Analysis
--
-- Questions:
-- 1. How many encounters does the average patient have?
-- 2. What types of encounters are most common?
-- 3. How has encounter volume changed over time?
-- 4. Who are the highest-utilization patients?
-- 5. What types of encounters do the top 20 utilizers use the most?
-- 6. How does the encounter type distribution of the top 20 compare
--    with the overall patient population?
-- ============================================================



	--Encounters per Patient


SELECT 
	MIN(encounter_count) as min_encounters,
	MAX(encounter_count) as max_encounters,
	PERCENTILE_CONT(0.5)
		WITHIN GROUP (ORDER BY encounter_count) AS median_encounters,
	AVG(encounter_count) as avg_encounters
FROM (
	SELECT
	patient,
	COUNT(*) AS ENCOUNTER_COUNT
	FROM ENCOUNTERS
	GROUP BY PATIENT
	) AS PATIENT_ENCOUNTERS;



	--Encounter Type Distribution

SELECT
    encounterclass,
    COUNT(*) AS total_encounters,
    ROUND(
        COUNT(*)::NUMERIC /
        (SELECT COUNT(*) FROM encounters) * 100,
        2
    ) AS percentage_of_encounters
FROM encounters
GROUP BY encounterclass
ORDER BY total_encounters DESC;



	--Encounter Volume Over Time
	
SELECT
    CASE
        WHEN start_time >= '1980-01-01' AND start_time < '1990-01-01'
            THEN '1980-1989'
        WHEN start_time >= '1990-01-01' AND start_time < '2000-01-01'
            THEN '1990-1999'
        WHEN start_time >= '2000-01-01' AND start_time < '2010-01-01'
            THEN '2000-2009'
        WHEN start_time >= '2010-01-01' AND start_time < '2020-01-01'
            THEN '2010-2019'
        WHEN start_time >= '2020-01-01' AND start_time < '2027-01-01'
            THEN '2020-2026'
    END AS date_range,
    COUNT(*) AS total_encounters
FROM encounters
WHERE start_time >= '1980-01-01'
GROUP BY date_range
ORDER BY date_range;


  --Highest-Utilization Patients (20)

SELECT 
	p.id,
	p.gender,
	p.birthdate,
	p.race,
	COUNT (e.id) AS ENCOUNTER_COUNT 
FROM patients p
JOIN encounters e
	ON p.id= e.patient
GROUP BY 
	p.id,
	p.gender,
	p.birthdate,
	p.race
ORDER BY ENCOUNTER_COUNT DESC
LIMIT 20;



	--Encounter Distribution Among Top 20 Utilizers
	
WITH top_utilizers AS(
	SELECT 
		patient,
	COUNT(*) AS encounter_count
	FROM encounters
	GROUP BY patient
	ORDER BY encounter_count DESC
	LIMIT 20
),

	top_utilizer_encounters AS (
	SELECT 
		e.encounterclass
	FROM encounters e
	JOIN top_utilizers t
	ON e.patient = t.patient
	)

SELECT encounterclass,
	COUNT (*) as total_encounters,
	ROUND (
		COUNT(*)::NUMERIC /(SELECT COUNT(*) FROM top_utilizer_encounters)*100,2
	) ||'%' AS percentage_of_top_utilizer_encounters

FROM top_utilizer_encounters
GROUP by encounterclass
ORDER BY percentage_of_top_utilizer_encounters DESC;



	--Top 20 vs. Population Encounter Distribution

WITH top_utilizers AS (
    SELECT
        patient,
        COUNT(*) AS encounter_count
    FROM encounters
    GROUP BY patient
    ORDER BY encounter_count DESC
    LIMIT 20
),

top_utilizer_encounters AS (
    SELECT
        e.encounterclass,
        COUNT(*) AS total_encounters
    FROM encounters e
    JOIN top_utilizers t
        ON e.patient = t.patient
    GROUP BY e.encounterclass
),

overall_encounters AS (
    SELECT
        encounterclass,
        COUNT(*) AS total_encounters
    FROM encounters
    GROUP BY encounterclass
)

SELECT
    t.encounterclass,

    ROUND(
        t.total_encounters::NUMERIC /
        (SELECT SUM(total_encounters)
         FROM top_utilizer_encounters) * 100,
        2
    ) ||'%' AS top_20_percentage,

    ROUND(
        o.total_encounters::NUMERIC /
        (SELECT SUM(total_encounters)
         FROM overall_encounters) * 100,
        2
    )||'%' AS overall_percentage,

    ROUND(
        (
            t.total_encounters::NUMERIC /
            (SELECT SUM(total_encounters)
             FROM top_utilizer_encounters) * 100
        ) -
        (
            o.total_encounters::NUMERIC /
            (SELECT SUM(total_encounters)
             FROM overall_encounters) * 100
        ),
        2
    ) AS difference_percentage_points

FROM top_utilizer_encounters t
JOIN overall_encounters o
    ON t.encounterclass = o.encounterclass

ORDER BY difference_percentage_points DESC;

