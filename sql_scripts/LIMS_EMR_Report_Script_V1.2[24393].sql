
# Please Edit start and end dates (e.g @startDate ='2021-11-01'  and @endDate = '2021-11-31') in this format YYYY-MM-DD;

SET @startDate := '';
SET @endDate := '2024-10-05';


DROP TABLE  IF EXISTS `lims_sam`;
DROP TABLE  IF EXISTS `lims_res`;
DROP TABLE IF EXISTS `lims_final_report`;
DROP TABLE IF EXISTS `lims_final_report2`;
DROP TABLE IF EXISTS `lims_final_report3`;

CREATE TABLE lims_sam AS(
	SELECT lms.manifest_id, lms.encounter_id, lms.date_created AS Manifest_Generation_Date, lms.sample_id, lms.patient_id->"$[*].idNumber" 
	AS Patient_Id, lms.firstname, lms.surname, lms.sex, 
	lms.sample_ordered_date, lms.sample_collected_date, lms.date_sample_sent 
	FROM `lims_manifest_samples` lms
);
 

CREATE TABLE lims_res AS(
	SELECT lmr.manifest_id, lmr.sample_id, lmr.patient_id->"$[*].idNumber" 
	AS Patient_Id, lmr.date_sample_receieved_at_pcrlab, lmr.assay_date, lmr.test_result, lmr.result_date, lmr.approval_date, date_result_dispatched 
	FROM `lims_manifest_result` lmr
);

CREATE TABLE lims_final_report AS(
	SELECT lms.manifest_id, lms.encounter_id, lms.Manifest_Generation_Date, lms.sample_id, lms.patient_id 
	AS Patient_Id, lms.firstname, lms.surname, lms.sex, 
	   lms.sample_ordered_date, lms.sample_collected_date, lms.date_sample_sent, 
	   lmr.date_sample_receieved_at_pcrlab, lmr.assay_date, lmr.test_result, 
	   lmr.result_date, lmr.approval_date, lmr.date_result_dispatched 
	FROM `lims_sam` lms 
	LEFT JOIN `lims_res` lmr 
	ON((lms.patient_id->"$[0]" = lmr.patient_id->"$[2]" 
	OR lms.patient_id->"$[1]" = lmr.patient_id->"$[2]" 
	OR lms.patient_id->"$[2]" = lmr.patient_id->"$[2]") 
	AND (lms.`sample_id`=lmr.`sample_id`) 
	AND (lms.`sample_id`=lmr.`sample_id`))
);


CREATE TABLE lims_final_report2 AS(
     SELECT 
	(SELECT `state_province`  FROM  `location` WHERE `location_id` = 8 LIMIT 1) AS State,
	(SELECT `city_village`  FROM  `location` WHERE `location_id` = 8 LIMIT 1) LGA,
	(SELECT `name`  FROM  `location` WHERE `location_id` = 8 LIMIT 1) FacilityName,
	(SELECT `address1`  FROM  `location` WHERE `location_id` = 8 LIMIT 1) Datim_Code,
        lfr.*
     FROM lims_final_report lfr GROUP BY lfr.manifest_id, lfr.sample_id
);


CREATE TABLE lims_final_report3 AS(	
	SELECT  lfr2.State, lfr2.LGA, lfr2.FacilityName, lfr2.Datim_Code, lfr2.manifest_id,
		lfr2.Manifest_Generation_Date, lfr2.sample_id, lfr2.Patient_Id AS All_Patient_Identifiers, pid.identifier AS PepID,
		lfr2.firstname, lfr2.surname, lfr2.sex, lfr2.sample_ordered_date, lfr2.sample_collected_date,
		lfr2.date_sample_sent, lfr2.date_sample_receieved_at_pcrlab, lfr2.assay_date, lfr2.test_result,
		lfr2.approval_date, lfr2.date_result_dispatched 
	FROM lims_final_report2 lfr2 
	LEFT JOIN `encounter` en 
	ON (lfr2.encounter_id = en.`encounter_id`)
	LEFT JOIN `patient_identifier` pid 
	ON (pid.`patient_id` = en.`patient_id` AND pid.`identifier_type`= 4)
);	

SELECT * FROM `lims_final_report3` WHERE Manifest_Generation_Date BETWEEN @startDate AND @endDate ORDER BY Manifest_Generation_Date ASC LIMIT 100000;
	
DROP TABLE  IF EXISTS `lims_sam`;
DROP TABLE  IF EXISTS `lims_res`;
DROP TABLE IF EXISTS `lims_final_report`;
DROP TABLE IF EXISTS `lims_final_report2`;
DROP TABLE IF EXISTS `lims_final_report3`;

