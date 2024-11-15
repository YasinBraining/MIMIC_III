WITH first_admission AS (
    SELECT 
        admissions.subject_id,
        admissions.hadm_id,
        admissions.admittime,
        patients.dod,
        (patients.dod - admissions.admittime) AS time_before_death,
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
      AND (patients.dod - admissions.admittime) < '5 days 00:00:00'
      AND (patients.dod - admissions.admittime) > '1 days 00:00:00'
)

SELECT 
   -- Count(subject_id)
   subject_id
	,admittime,
    dod,
    time_before_death
FROM first_admission
WHERE admission_rank = 1
order by time_before_death

--order by subject_id desc


-- Death date - admit time <=3 , admit time has to be from the right admission corresponding to the stroke