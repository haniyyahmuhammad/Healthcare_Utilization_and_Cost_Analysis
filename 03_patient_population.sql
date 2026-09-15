-- ============================================
-- Healthcare Utilization & Cost Analysis
-- Patient Population Analysis
-- ============================================
	
	
	--Gender Distribution
SELECT 
  CASE
	WHEN GENDER ='M' THEN 'M'
	WHEN GENDER ='F' THEN 'F'
	ELSE 'UNKNOWN'
	  END AS GENDER,
	  COUNT (*) AS PATIENT_COUNT,
	 ROUND(
	  COUNT (*):: NUMERIC / (SELECT COUNT (*) FROM PATIENTS) * 100, 2 ) 
	  || '%' AS PERCENTAGE_OF_PTS
FROM PATIENTS
GROUP BY GENDER
ORDER BY PATIENT_COUNT DESC;


	--Race Distribution
SELECT RACE, COUNT(*) AS PATIENT_COUNT,
	ROUND(
	  COUNT (*):: NUMERIC / (SELECT COUNT (*) FROM PATIENTS) * 100, 2 ) 
	  || '%' AS PERCENTAGE_OF_PTS
FROM PATIENTS 
GROUP BY RACE
ORDER BY PATIENT_COUNT DESC;
