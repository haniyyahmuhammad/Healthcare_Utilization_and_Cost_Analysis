-- ============================================================
-- Project: Healthcare SQL Analysis
-- Patient Utilization and Cost Analysis
-- Tool: PostgreSQL
--
-- Objective:
-- Analyze the relationship between patient encounter utilization
-- and cumulative healthcare claim costs.
--
-- Analyses:
-- 5.1 Patient-level utilization and cost
-- 5.2 Cost comparison across utilization groups
-- 5.3 Correlation analysis between encounter frequency and costs
-- ============================================================

-- 5.1 Patient-Level Utilization and Costs

SELECT 
	patient,
	COUNT (*) num_of_encounters,
	SUM(total_claim_cost) as total_claim_cost,
	ROUND(AVG (total_claim_cost),2) as avg_claim_cost,
	SUM (payer_coverage) as total_coverage
FROM encounters
GROUP BY patient
ORDER BY total_claim_cost DESC
LIMIT 10;


-- 5.2 Cost Comparison by Utilization Group
-- LOW: 1-20 | MODERATE: 21-60 | HIGH: 61+ encounters

WITH patient_utilization AS(
	SELECT patient,
		COUNT (*) num_of_encounters,
		SUM(total_claim_cost) as total_claim_cost,
		ROUND(AVG(total_claim_cost),2) as avg_claim_cost,
		SUM (payer_coverage) as total_coverage,
		CASE
			WHEN COUNT(*) <= 20 THEN 'LOW'
			WHEN COUNT(*) <= 60 THEN 'MODERATE'
			ELSE 'HIGH'
		END AS utilization_group
	FROM encounters
	GROUP BY patient
	)

SELECT 
	utilization_group,
	COUNT(*) as patient_count,
	ROUND(AVG(num_of_encounters),2) as avg_encounters_per_patient,
	ROUND(AVG(total_claim_cost),2) as avg_claim_cost_per_patient
FROM patient_utilization
GROUP BY utilization_group
ORDER BY avg_encounters_per_patient;


-- 5.3 Correlation Between Encounter Frequency and Cost

WITH patient_cost AS(
	SELECT patient,
		COUNT (*) num_of_encounters,
		SUM(total_claim_cost) as total_claim_cost
	FROM encounters
	GROUP BY patient
	)

SELECT 
	ROUND(CORR(num_of_encounters, total_claim_cost)::numeric,3)
			AS utilization_cost_correlation
FROM patient_cost;


-------KEY FINDING----
-- Encounter frequency and cumulative claim costs
-- showed a moderate positve correlation (r=0.454).
-- Correlation does not prove causation. 

-- ==============================================================

	
