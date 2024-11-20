with pers_infos AS (
	SELECT patients.subject_id, 
	patients.gender,
	patients.dob,
	admissions.admittime,
	((admissions.admittime -patients.dob)) as Age_interval,
	EXTRACT(EPOCH FROM admittime - dob)/60.0/60.0/24.0/365 as age
	from mimiciii.patients
	INNER JOIN mimiciii.admissions
	ON patients.subject_id = admissions.subject_id
	ORDER BY RANDOM() LIMIT 1000
	
)

, stroke_related AS (
	SELECT
		admissions.subject_id,
        admissions.hadm_id,
		d_icd_diagnoses.ICD9_Code
	FROM mimiciii.admissions
	INNER JOIN mimiciii.diagnoses_icd
        ON admissions.subject_id = diagnoses_icd.subject_id
    INNER JOIN mimiciii.d_icd_diagnoses
        ON diagnoses_icd.ICD9_CODE = d_icd_diagnoses.ICD9_Code  
	
)	

, first_admission AS (
    SELECT 
        admissions.subject_id,
        admissions.hadm_id,
        admissions.admittime,
        patients.dod,
        EXTRACT(EPOCH FROM patients.dod - admissions.admittime)/60.0/60.0/24.0 AS days_before_death,
        ROW_NUMBER() OVER (PARTITION BY admissions.subject_id ORDER BY admissions.admittime) AS admission_rank
    	
	FROM mimiciii.admissions
    INNER JOIN mimiciii.diagnoses_icd
        ON admissions.subject_id = diagnoses_icd.subject_id
    INNER JOIN mimiciii.d_icd_diagnoses
        ON diagnoses_icd.ICD9_CODE = d_icd_diagnoses.ICD9_Code
    INNER JOIN mimiciii.patients
        ON admissions.subject_id = patients.subject_id
    WHERE diagnoses_icd.ICD9_CODE IN ('433', '434', '436', '430', '431', '423')
      AND admissions.hadm_id = diagnoses_icd.hadm_id
      AND patients.expire_flag = '1'
      AND (patients.dod - admissions.admittime) < '1000 days 00:00:00'
      AND (patients.dod - admissions.admittime) > '1 days 00:00:00'
)


SELECT
  pers_infos.subject_id, 
  pers_infos.gender, 
  --pers_infos.dob,
  pers_infos.age,
  stroke_related.ICD9_Code,
  CASE
  	WHEN ICD9_CODE IN ('433', '434', '436', '430', '431', '423') then 1
  ELSE 0 END
  	as exclusion_stroke
  , CASE
        WHEN pers_infos.age >= 18 then 1
    ELSE 0 END
        as exclusion_age
FROM pers_infos
INNER JOIN stroke_related
	ON pers_infos.subject_id = stroke_related.subject_id
--Order by RANDOM() LIMIT 100