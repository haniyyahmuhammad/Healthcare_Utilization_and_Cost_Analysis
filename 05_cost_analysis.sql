-- ============================================================
-- Healthcare Utilization Analysis
-- Cost Analysis
--
-- Objective: Analyze healthcare claim costs, payer coverage,
-- and patient level cost patterns using synthetic Synthea data.
-- ============================================================

-- ============================================================
-- 1. Overall Healthcare Claim Cost Summary
-- Purpose: Calculate total, average, median, and maximum
-- claim cost across all encounters.
-- ============================================================

SELECT
    SUM(total_claim_cost) AS total__claim_cost,
    ROUND(AVG(total_claim_cost), 2) AS avg_cost,
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY total_claim_cost)::NUMERIC,
        2
    ) AS median_cost,
    MAX(total_claim_cost) AS max_cost
FROM encounters;

-- ============================================================
-- 2. Claim Costs by Encounter Type
-- Purpose: Compare encounter volume and claim costs across
-- different healthcare encounter classes.
-- ============================================================

SELECT 
	encounterclass,
	COUNT (*) as num_of_encounters,
	SUM(total_claim_cost) as total_claim_costs,
	AVG (total_claim_cost) as avg_cost,
	MAX (total_claim_cost) as max_cost,
	ROUND(
		PERCENTILE_CONT(0.5)
		WITHIN GROUP (ORDER BY total_claim_cost)::NUMERIC,
		2
		) AS median_cost
FROM encounters
GROUP BY encounterclass
ORDER BY total_claim_costs DESC; 

-- ============================================================
-- 3. Payer Coverage by Encounter Type
-- Purpose: Calculate payer coverage as a percentage of total
-- recorded claim costs for each encounter class.
-- Note: This is not necessarily the percentage paid by
-- insurers or the amount owed by patients.
-- ============================================================

SELECT 
	SUM(total_claim_cost) as total_claim_costs,
	SUM(payer_coverage) as total_coverage,
	AVG (total_claim_cost) as avg_cost,
	ROUND(
		SUM(payer_coverage) ::NUMERIC /
		NULLIF(SUM(total_claim_cost),0) *100, 2
	) as percent_covered
FROM encounters;


SELECT 
	encounterclass,
	COUNT (*) as num_of_encounters,
	SUM(total_claim_cost) as total_claim_costs,
	SUM(payer_coverage) as total_coverage,
	AVG (total_claim_cost) as avg_cost,
	ROUND(
		SUM(payer_coverage) ::NUMERIC /
		NULLIF(SUM(total_claim_cost),0) *100, 2
	) as percent_covered
FROM encounters
GROUP BY encounterclass
ORDER BY percent_covered DESC; 


-- ============================================================
-- 4. Top 20 Patients by Cumulative Claim Cost
-- Purpose: Identify patients with the highest total recorded
-- claim costs and compare encounter counts, payer coverage,
-- and the difference between claim costs and coverage.
-- ============================================================

SELECT 
	patient,
	COUNT (*) as num_of_encounters,
	SUM(total_claim_cost) as total_claim_costs,
	SUM(payer_coverage) as total_coverage,
	SUM(total_claim_cost) - SUM(payer_coverage) AS cost_coverage_difference,
	ROUND(
		SUM(payer_coverage) ::NUMERIC /
		NULLIF(SUM(total_claim_cost),0) *100, 2
	) as percent_covered
FROM encounters
GROUP BY patient
ORDER BY total_claim_costs DESC
LIMIT 20; 
	
