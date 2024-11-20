WITH stroke_related AS (
    SELECT DISTINCT
        admissions.subject_id,
        admissions.hadm_id,
        admissions.admittime,
        d_icd_diagnoses.ICD9_Code
    FROM mimiciii.admissions
    INNER JOIN mimiciii.diagnoses_icd
        ON admissions.hadm_id = diagnoses_icd.hadm_id
    INNER JOIN mimiciii.d_icd_diagnoses
        ON diagnoses_icd.ICD9_Code = d_icd_diagnoses.ICD9_Code
    WHERE d_icd_diagnoses.ICD9_Code IN ('433', '434', '436', '430', '431', '432') -- stroke-related codes
),

first_admission AS (
    SELECT 
        subject_id,
        hadm_id,
        admittime,
        RANK() OVER (PARTITION BY subject_id ORDER BY admittime) AS ad_order
    FROM stroke_related
),

pers_infos AS (
	SELECT 
		first_admission.subject_id, 
		patients.gender,
		patients.dob,
		first_admission.admittime, --use first admission
		--((admissions.admittime -patients.dob)) as Age_interval,
		EXTRACT(YEAR FROM age(first_admission.admittime, dob)) AS age
	From mimiciii.patients
	INNER JOIN first_admission
		ON patients.subject_id = first_admission.subject_id
	WHERE first_admission.ad_order = 1
	--ORDER BY RANDOM() LIMIT 1000
	
)

,died AS (
    SELECT 
        first_admission.subject_id,
        first_admission.hadm_id,
        first_admission.admittime,
        patients.dod,
		patients.expire_flag as death,
        EXTRACT(EPOCH FROM patients.dod - first_admission.admittime)/60.0/60.0/24.0 AS days_before_death
    	
	FROM mimiciii.patients
    INNER JOIN first_admission
        ON patients.subject_id = first_admission.subject_id
	WHERE first_admission.ad_order = 1

	
 )

  


SELECT
  pers_infos.subject_id, 
  pers_infos.gender, 
  pers_infos.age,
  STRING_AGG(DISTINCT stroke_related.icd9_code, ', ') AS icd9_codes,
  --died.days_before_death,
  --died.admittime,
  --pers_infos.dob,
  /*CASE
	  WHEN pers_infos.age >= 18 THEN 1
	  ELSE 0 
  END AS exclusion_age,
  CASE
	  WHEN died.death = 1 THEN 1
	  ELSE 0 
  END AS exclusion_death,*/
  CASE
	  WHEN died.days_before_death <= 30 AND died.days_before_death > 1 THEN 1
	  ELSE 0 
  END AS death_before_1Month
FROM pers_infos
INNER JOIN stroke_related
	ON pers_infos.subject_id = stroke_related.subject_id
INNER JOIN died
	ON pers_infos.subject_id = died.subject_id
INNER JOIN Inputevents_mv.
Where 
	(CASE
        WHEN pers_infos.age >= 18 THEN 1
        ELSE 0 
    END) = 1
--AND exclusion_death = 1
--AND exclusion_death_before_1Month = 1
GROUP BY 
    pers_infos.subject_id, 
    pers_infos.gender, 
    pers_infos.age, 
    pers_infos.dob, 
    died.days_before_death, 
    died.admittime
Order by icd9_codes
--LIMIT 80
; 

/*SELECT DISTINCT
    stroke_related.subject_id,
    stroke_related.hadm_id,
    STRING_AGG(DISTINCT stroke_related.icd9_code, ', ') AS icd9_codes,
    first_admission.admittime
FROM stroke_related
JOIN first_admission
ON stroke_related.subject_id = first_admission.subject_id
AND stroke_related.hadm_id = first_admission.hadm_id
WHERE stroke_related.subject_id = 8394
GROUP BY stroke_related.subject_id, stroke_related.hadm_id, first_admission.admittime

*/


