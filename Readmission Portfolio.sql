CREATE VIEW HRA AS
SELECT *
FROM healthcare_readmission_analysis;

SELECT * FROM HRA
//convert to 2 dp.
SELECT 
    ROUND(
        (COUNT(*) * 100.0) / (SELECT COUNT(*) FROM HRA), 
        2
    ) AS ReadmissionRatePercent
FROM HRA
WHERE readmitted = 1;

SELECT 
    ROUND(AVG(CAST(time_in_hospital AS FLOAT)), 2) AS AvgTimeInHospital
FROM HRA
WHERE readmitted = 1;


SELECT Top 1 diag_1, COUNT(*) AS PatientCount
FROM HRA
GROUP BY diag_1
ORDER BY PatientCount DESC;

SELECT Top 1 diag_2 As Secondary_diagnosis, COUNT(*) AS PatientCount
FROM HRA
GROUP BY diag_2
ORDER BY PatientCount DESC;

CREATE SYNONYM hra FOR dbo.healthcare_readmission_analysis;

ALTER TABLE dbo.healthcare_readmission_analysis
ADD bins_for_age VARCHAR(20),
    risk_score FLOAT,
    risk_segment VARCHAR(20),
    medication_impact_group VARCHAR(40);

ALTER TABLE dbo.healthcare_readmission_analysis
ADD stay_length VARCHAR(20)

UPDATE dbo.healthcare_readmission_analysis
SET stay_length =
	CASE 
        WHEN time_in_hospital BETWEEN 1 AND 3 THEN '1–3 days'
        WHEN time_in_hospital BETWEEN 4 AND 6 THEN '4–6 days'
        WHEN time_in_hospital >= 7 THEN '7+ days'
    END


SELECT 
    stay_length,
    COUNT(*) AS readmissions
FROM dbo.healthcare_readmission_analysis
WHERE readmitted = 1
GROUP BY stay_length
ORDER BY stay_length ASC;

UPDATE dbo.healthcare_readmission_analysis
SET bins_for_age =
    CASE 
        WHEN age BETWEEN 18 AND 29 THEN '18-29'
        WHEN age BETWEEN 30 AND 44 THEN '30-44'
        WHEN age BETWEEN 45 AND 59 THEN '45-59'
        WHEN age BETWEEN 60 AND 74 THEN '60-74'
        WHEN age BETWEEN 75 AND 89 THEN '75-89'
        ELSE 'Other'
    END;



UPDATE dbo.healthcare_readmission_analysis
SET risk_score =
    ROUND(
        (time_in_hospital * 0.4) +
        (n_medications * 0.3) +
        (n_procedures * 0.15) +
        (n_lab_procedures * 0.15), 
    2);

UPDATE dbo.healthcare_readmission_analysis
SET risk_segment =
    CASE 
        WHEN risk_score >= 15 THEN 'High-Risk'
        WHEN risk_score >= 8 THEN 'Medium-Risk'
        ELSE 'Low-Risk'
    END;

SELECT 
    bins_for_age,
    COUNT(*) AS total_readmitted
FROM dbo.healthcare_readmission_analysis
WHERE readmitted = 1
GROUP BY bins_for_age
ORDER BY bins_for_age;

SELECT 
    medication_impact_group,
    COUNT(*) AS readmissions
FROM dbo.healthcare_readmission_analysis
WHERE readmitted = 1
GROUP BY medication_impact_group
ORDER BY readmissions DESC;

EXEC sp_rename 'dbo.healthcare_readmission_analysis.[test_chnage]', 'test_change', 'COLUMN';

ALTER TABLE dbo.healthcare_readmission_analysis
ALTER COLUMN medication_impact_group VARCHAR(50);

UPDATE dbo.healthcare_readmission_analysis
SET medication_impact_group =
    CASE
        WHEN test_change = 1 AND diabetes_med = 1 THEN 'Change & Diabetes Meds'
        WHEN test_change = 1 AND diabetes_med = 0 THEN 'Change Only'
        WHEN test_change = 0 AND diabetes_med = 1 THEN 'Diabetes Meds Only'
        ELSE 'Neither'
    END;


UPDATE dbo.healthcare_readmission_analysis
SET risk_score = ROUND(
    (ISNULL(time_in_hospital,0) * 0.4) +
    (ISNULL(n_medications,0) * 0.3) +
    (ISNULL(n_procedures,0) * 0.15) +
    (ISNULL(n_lab_procedures,0) * 0.15),
2);

SELECT 
    medication_impact_group,
    ROUND(
        (COUNT(*) * 100.0) /
        (SELECT COUNT(*) FROM hra WHERE readmitted = 1),
    2) AS percentage_readmitted
FROM dbo.healthcare_readmission_analysis
WHERE readmitted = 1
GROUP BY medication_impact_group
ORDER BY percentage_readmitted DESC;

SELECT 
    risk_segment,
    ROUND(
        (COUNT(*) * 100.0) /
        (SELECT COUNT(*) FROM hra WHERE readmitted = 1),
    2) AS percentage_readmitted
FROM dbo.healthcare_readmission_analysis
WHERE readmitted = 1
GROUP BY risk_segment
ORDER BY percentage_readmitted DESC;


SELECT 
    medical_specialty,
    COUNT(*) AS ReadmissionCount
FROM HRA
WHERE readmitted = 1
GROUP BY medical_specialty
ORDER BY ReadmissionCount DESC;

