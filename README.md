# Healthcare-Readmission-Analysis
A data analysis project exploring hospital readmission patterns using Advanced SQL &amp; Tableau.
## Project Context

Hospital readmissions are one of the most critical measures of healthcare quality. High readmission rates signal potential gaps in care, poor treatment effectiveness, or inadequate patient follow-up—leading to increased costs and operational strain. This project applies SQL, Excel, and Power BI to analyze hospital data, uncover drivers of readmissions, and provide data-driven insights that can guide better patient management, optimize resources, and strengthen hospital performance.

## Problem / Objective

- **Identify the patient groups most vulnerable to readmission to guide targeted care interventions.**
- **Uncover which clinical departments experience the highest readmission pressure to improve resource planning and follow-up strategies.**
- **Assess whether hospital stay patterns reveal early warning signs for patients likely to return.**
- **Evaluate how treatment intensity and medication adjustments influence the chances of patients being readmitted.**
- **Develop a clear risk-tier framework that classifies patients into high, medium, and low likelihood of readmission for proactive care management.**

## Dataset Overview

- **Total Rows:** 25,000
- **Total Columns:** 17
- **Dataset Type:** Patient-level hospital visit records
- **Key Fields Include:**
    - **Demographics:** Age
    - **Hospitalization metrics:** Time in hospital, number of procedures, number of medications, number of lab procedures
    - **Visit history:** Outpatient, inpatient, and emergency visits
    - **Clinical indicators:** Glucose test results, A1C test results, diagnoses
    - **Outcome variable:** Whether the patient was readmitted
- **Purpose:** Supports analysis of medication behavior patterns, testing combinations, patient groups, and operational hospital insights.

## Approach / Methods

## SQL Queries

### Creation of New Columns for Analysis

```sql
ALTER TABLE dbo.healthcare_readmission_analysis
ADD bins_for_age VARCHAR(20),
    risk_score FLOAT,
    risk_segment VARCHAR(20),
    medication_impact_group VARCHAR(40);

ALTER TABLE dbo.healthcare_readmission_analysis
ADD stay_length VARCHAR(20)
```

### Age group **Analysis**

```sql
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
    
    SELECT 
    bins_for_age,
    COUNT(*) AS total_readmitted
FROM dbo.healthcare_readmission_analysis
WHERE readmitted = 1
GROUP BY bins_for_age
ORDER BY bins_for_age;

```

### Departmental Analysis

```sql
SELECT 
    medical_specialty,
    COUNT(*) AS ReadmissionCount
FROM HRA
WHERE readmitted = 1
GROUP BY medical_specialty
ORDER BY ReadmissionCount DESC;
```

### Stay Pattern **Analysis**

```sql
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
```

### Risk Segmentation

```sql
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
    risk_segment,
    ROUND(
        (COUNT(*) * 100.0) /
        (SELECT COUNT(*) FROM hra WHERE readmitted = 1),
    2) AS percentage_readmitted
FROM dbo.healthcare_readmission_analysis
WHERE readmitted = 1
GROUP BY risk_segment
ORDER BY percentage_readmitted DESC;
```

### Medication Impact

```sql
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
```

### Tableau Dashboard

!![Dashboard](Healthcare Dashboard.png)


**Live Dashboard:** [*Click to Explore*](https://public.tableau.com/views/Readmission_17631105789020/ReadmissionDashboard?:language=en-GB&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

## Insights & Recommendations

### Overall Readmission Snapshot

- **Readmission Rate:** 25.1% — 1 in 4 patients return, highlighting a significant opportunity to reduce hospital churn.
- **Average Length of Stay:** 7 days — longer stays correlate with higher readmission rates.

### Patient Vulnerability (Age Focus)

- Highest readmission rates are in the **75–89 age group**, followed by **60–74**.
- Targeted interventions for elderly patients could substantially reduce readmissions.

### Department Pressure Points (Medical Specialty)

- **Cardiology (646), General Surgery (644), Pediatrics (611)** have the highest readmissions.
- These departments need stronger discharge planning and follow-up protocols to reduce strain.

### Early Warning from Hospital Stay Duration

- Patients staying **7+ days** have the highest readmissions (**3,397** cases).
- Long stays are a strong predictor of return; enhanced monitoring for these patients is critical.

### Primary Drivers (Diagnosis)

- **Heart Failure, Asthma, Stroke** top the list for readmitted patients.
- These conditions require careful post-discharge management to lower recurrence.

### Risk Segmentation

- Patients are classified into **High, Medium, and Low risk** tiers.
- Focus on high-risk patients for proactive interventions (e.g., follow-up calls, home visits).

### Medication Impact

- Adjustments in medication influence readmission:
    - **DB med change:** 35% of readmitted patients
    - **Change only:** 15%
    - **Diabetes meds:** 35%
- Medication review programs could help reduce readmissions for patients with complex drug regimens.

## Data Files

[healthcare_readmission_analysis.csv](attachment:1e3eb0b3-dde3-485b-b6b9-f23eda4dd364:healthcare_readmission_analysis.csv)
