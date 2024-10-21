SET GLOBAL innodb_buffer_pool_size = 1024*1024*1024;
SET @endDate := '2024-10-02';
SET @artStartDate :='';
SET @dateConfirmed :='';
DROP TABLE  IF EXISTS full_line_list;
DROP TABLE  IF EXISTS  IPT_list;
DROP TABLE  IF EXISTS  presumtive_tb_list;
DROP TABLE IF EXISTS OTZ_list;
DROP TEMPORARY TABLE IF EXISTS  final_line_list;

DELIMITER $$
DROP FUNCTION IF EXISTS `getdatevalueobsid`$$
CREATE FUNCTION `getdatevalueobsid`(`obsid` INT) RETURNS DATE
BEGIN
    DECLARE val DATE;
    SELECT  obs.value_datetime INTO val FROM obs WHERE  obs.obs_id=obsid;
	RETURN val;
END$$
DROP FUNCTION IF EXISTS gettextvalueobsid;$$
CREATE  FUNCTION `gettextvalueobsid`(`obsid` INT) RETURNS TEXT CHARSET utf8
BEGIN
    DECLARE val TEXT;
    SELECT  obs.value_text INTO val FROM obs WHERE  obs.obs_id=obsid;
	RETURN val;
END$$
DROP FUNCTION IF EXISTS `getendofquarter`$$
CREATE FUNCTION `getendofquarter`(`date_val` DATE) RETURNS DATE
BEGIN
	DECLARE fyear INT;
	DECLARE fquarter INT;
	DECLARE start_date DATE;
	DECLARE end_date DATE;
	DECLARE month_val INT;
	SET fyear=IF(QUARTER(date_val)=4,YEAR(date_val),YEAR(date_val));
	SET fquarter=IF(QUARTER(date_val)=4,MOD(QUARTER(date_val)+1,4),QUARTER(date_val)+1);
	SELECT CASE
	WHEN fquarter=1 THEN 12
	WHEN fquarter=2 THEN 3
	WHEN fquarter=3 THEN 6
	WHEN fquarter=4 THEN 9
	END INTO month_val;
	SELECT STR_TO_DATE(CONCAT(fyear,"-",month_val,"-",1),'%Y-%c-%e') INTO start_date;
	SELECT LAST_DAY(start_date) INTO end_date;
	RETURN end_date;
END $$
DROP FUNCTION IF EXISTS `getdatevalueobsid`$$
CREATE FUNCTION `getdatevalueobsid`(`obsid` INT) RETURNS DATE
BEGIN
    DECLARE val DATE;
    SELECT  obs.value_datetime INTO val FROM obs WHERE  obs.obs_id=obsid;
	RETURN val;
END$$
DROP FUNCTION IF EXISTS `getmaxconceptobsid`$$
CREATE  FUNCTION `getmaxconceptobsid`(`patientid` INT,`conceptid` INT, `cutoffdate` DATE) RETURNS DECIMAL(10,0)
BEGIN
    DECLARE value_num INT;
    SELECT  obs.obs_id INTO value_num FROM obs WHERE  obs.person_id=patientid AND obs.concept_id=conceptid AND obs.voided=0 AND
	obs.obs_datetime<=cutoffdate ORDER BY obs.obs_datetime DESC LIMIT 1;
	RETURN value_num;
END $$
DROP FUNCTION IF EXISTS `getmaxconceptobsidwithformid`$$
CREATE  FUNCTION `getmaxconceptobsidwithformid`(`patientid` INT,`conceptid` INT, `formid` INT,`cutoffdate` DATE) RETURNS DECIMAL(10,0)
BEGIN
    DECLARE value_num INT;
    SELECT  obs.obs_id INTO value_num FROM obs INNER JOIN encounter ON(encounter.encounter_id=obs.encounter_id AND encounter.voided=0) WHERE  encounter.form_id=formid AND obs.person_id=patientid
		AND obs.concept_id=conceptid AND obs.voided=0 AND obs.obs_datetime<=cutoffdate ORDER BY obs.obs_datetime DESC LIMIT 1;
	RETURN value_num;
END $$
DROP FUNCTION IF EXISTS `getcodedvalueobsid`$$
CREATE FUNCTION `getcodedvalueobsid`(`obsid` INT) RETURNS TEXT CHARSET utf8
BEGIN
    DECLARE val TEXT;
    SELECT  cn.name INTO val FROM
		obs
		INNER JOIN concept_name cn ON(obs.value_coded=cn.concept_id AND cn.locale='en' AND cn.locale_preferred=1) WHERE obs.obs_id=obsid;
	RETURN val;
END $$
DROP FUNCTION IF EXISTS `getoutcome`$$
CREATE FUNCTION `getoutcome`(`lastpickupdate` DATE,`daysofarvrefill` NUMERIC,`ltfudays` NUMERIC, `enddate` DATE) RETURNS TEXT CHARSET utf8
BEGIN
        DECLARE  ltfudate DATE;
        DECLARE  ltfunumber NUMERIC;
        DECLARE  daysdiff NUMERIC;
        DECLARE outcome TEXT;
        SET ltfunumber=daysofarvrefill+ltfudays;
        SELECT DATE_ADD(lastpickupdate, INTERVAL ltfunumber DAY) INTO ltfudate;
        SELECT DATEDIFF(ltfudate,enddate) INTO daysdiff;
        SELECT IF(daysdiff >=0,"Active","LTFU") INTO outcome;
        RETURN outcome;
END$$
DROP FUNCTION IF EXISTS `getobsdatetime`$$
CREATE FUNCTION `getobsdatetime`(`obsid` INT) RETURNS DATE
BEGIN
    DECLARE val DATE;
    SELECT  obs.obs_datetime INTO val FROM obs WHERE  obs.obs_id=obsid;
	RETURN val;
END$$
DELIMITER ;

CREATE TABLE full_line_list AS (
SELECT
"APIN" AS "IP",
   (SELECT `state_province`  FROM  `location` WHERE `location_id` = 8 LIMIT 1) AS State,
   (SELECT `city_village`  FROM  `location` WHERE `location_id` = 8 LIMIT 1) LGA,
   (SELECT `address1`  FROM  `location` WHERE `location_id` = 8 LIMIT 1) Datim_Code,
   (SELECT `name`  FROM  `location` WHERE `location_id` = 8 LIMIT 1) FacilityName,
  pid1.`patient_id` AS `patient_id`,
  pid1.identifier AS `PepID`,
  pid2.identifier AS  `PatientHospitalNo`,
  "" AS PreviousID,
  person.gender AS `Sex`,
  ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166369)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`obs_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=14
     AND `value_coded` IN (160578,166285,166286,166287,162277)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `KPType`,
  ( SELECT
IF(TIMESTAMPDIFF(YEAR,person.birthdate,ob.value_datetime)>=5,@ageAtStart:=TIMESTAMPDIFF(YEAR,person.birthdate,ob.value_datetime),@ageAtStart:=0)
  FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (159599)
     AND ob.`value_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=25
     AND ob.voided=0
     AND e.voided=0
     LIMIT 1) AS `Ageatstartofart`,
   ( SELECT
IF(
  TIMESTAMPDIFF(
    YEAR,
    person.birthdate,
    ob.value_datetime
  ) < 5,
  TIMESTAMPDIFF(
    MONTH,
    person.birthdate,
    ob.value_datetime
  ),
  NULL
)
  FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (159599)
     AND ob.`value_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=25
     AND ob.voided=0
     AND e.voided=0
     LIMIT 1) AS `Ageinmonths`,
DATE_FORMAT(@artStartDate := ( SELECT  DATE(`value_datetime`) FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (159599)
     AND ob.`value_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=25
     AND ob.voided=0
     AND e.voided=0
     LIMIT 1),'%d/%m/%Y') AS `ARTStartDate`,
DATE_FORMAT(@dateConfirmed := ( SELECT  DATE(`value_datetime`) FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (160554)
     AND ob.`value_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=14
     AND ob.voided=0
     AND e.voided=0
     LIMIT 1),'%d/%m/%Y') AS `HIVConfirmedDate`,
     DATEDIFF(@endDate,@artStartDate) AS DaysOnART,
 MAX(IF(obs.concept_id=165708,DATE_FORMAT(@Pharmacy_LastPickupdate:=e2.encounter_datetime,'%d/%m/%Y'),NULL)) AS `Pharmacy_LastPickupdate`,
 DATE_FORMAT(getobsdatetime(getmaxconceptobsidwithformid(patient.patient_id,162240,27,getendofquarter(DATE_SUB(@endDate,INTERVAL 3 MONTH)))),'%d/%m/%Y') AS `Pharmacy_LastPickupdate_PreviousQuarter`,
 MAX(IF(obs.concept_id=165708,DATE_FORMAT(@Clinic_Visit_Lastdate:=sinner.last_date,'%d/%m/%Y'),NULL)) AS `Clinic_Visit_Lastdate`,
MAX(IF(obs.concept_id=165708,DATE_FORMAT(@LastPickupDateCal:=sinner.last_date,'%d/%m/%Y'),NULL)) AS `LastPickupDateCal`,
-- MAX(IF(obs.concept_id=159368,@daysOfRefil:=obs.value_numeric,NULL)) AS `DaysOfARVRefill`,
getconceptval(getmaxconceptobsidwithformid(patient.patient_id,162240,27,@endDate),159368,patient.patient_id) AS `DaysOfARVRefill`,
getconceptval(getmaxconceptobsidwithformid(patient.patient_id,162240,27,getendofquarter(DATE_SUB(@endDate,INTERVAL 3 MONTH))),159368,patient.patient_id) AS `DaysofARVRefillPreviousQuarter`,
 MAX(IF(obs2.concept_id=165708,cn2.name,NULL)) AS `RegimenLineAtARTStart`,
MAX(
   IF(obs2.concept_id=164506,cn2.`name`,
   IF(obs2.concept_id=164513,cn2.`name`,
   IF(obs2.concept_id=164507,cn2.name,
   IF(obs2.concept_id=164514,cn2.name,
   IF(obs2.concept_id=165702,cn2.name,
   IF(obs2.concept_id=165703,cn2.name,NULL
   ))))))) AS `RegimenAtARTStart`,
MAX(IF(obs.concept_id=165708,cn1.name,NULL) ) AS `CurrentRegimenLine`,
( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (164506,164513,165702,164507,164514,165703)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`obs_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=13
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `CurrentARTRegimen`,
     
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (165727)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`obs_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=13
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `CurrentOIDrug`,
     
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166148)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`obs_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND value_coded IN (166276,166363)
     AND e.encounter_type=13
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `DSD_Model`,
     
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166276,166363)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND e.`encounter_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     -- AND value_coded IN (166276,166363)
     AND e.encounter_type=13
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `DSD_Model_Type`,
     
MAX(IF(obs.concept_id=165050,cn1.name,NULL)) AS `CurrentPregnancyStatus`,
-- MAX(IF(obs.concept_id=856,obs.value_numeric,NULL)) AS `CurrentViralLoad`,
( SELECT  ob.value_numeric FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (856)
     AND e.`encounter_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=11
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `CurrentViralLoad`,
-- MAX(IF(obs.concept_id=856,DATE_FORMAT(obs.obs_datetime,'%d/%m/%Y'),NULL)) AS `DateofCurrentViralLoad`,
( SELECT  DATE_FORMAT(MAX(e.encounter_datetime),'%d/%m/%Y') FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (856)
     AND e.`encounter_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=11
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `DateofCurrentViralLoad`,
     ( SELECT  DATE_FORMAT(MAX(ob.value_datetime),'%d/%m/%Y') FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (165987)
     AND e.`encounter_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=11
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `DateResultReceivedFacility`,
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166422)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND e.`encounter_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=11
     AND ob.voided=0
     AND e.voided=0
     ORDER BY e.`encounter_datetime` DESC LIMIT 1) AS `Alphanumeric_Viral_Load_Result`,
	 
       ( SELECT  DATE_FORMAT(MAX(ob.obs_datetime),'%d/%m/%Y') FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (159951)
     AND ob.`obs_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=11
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `LastDateOfSampleCollection`,
MAX(IF(obs.concept_id=164980,cn1.name,NULL) ) AS `ViralLoadIndication`,
/*
CASE
WHEN MAX(IF(obs.concept_id=165470,cn1.name,IF(obs.concept_id=165708,IF(TIMESTAMPDIFF(DAY,sinner.last_date,@endDate)< @daysOfRefil + 28,"",""),NULL))) <> ''
THEN MAX(IF(obs.concept_id=165470,cn1.name,IF(obs.concept_id=165708,IF(TIMESTAMPDIFF(DAY,sinner.last_date,@endDate)< @daysOfRefil + 28,"",""),NULL)))
ELSE IF(e.`encounter_datetime` IS NULL, NULL,'Transferred Out')
END AS `Outcomes`,
CASE
WHEN
( SELECT  DATE_FORMAT(ob.value_datetime,'%d/%m/%Y') FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` = 165469
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=15
     AND ob.voided=0
     AND e.voided=0
     LIMIT 1) <> ''
THEN
( SELECT  DATE_FORMAT(ob.value_datetime,'%d/%m/%Y') FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` = 165469
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=15
     AND ob.voided=0
     AND e.voided=0
     LIMIT 1)
ELSE IF(e.`encounter_datetime` IS NULL, NULL,DATE_FORMAT(e.`encounter_datetime`,'%d/%m/%Y'))
END AS `Outcomes_Date`,*/
getcodedvalueobsid(getmaxconceptobsidwithformid(patient.patient_id,165470,13,@endDate)) AS Outcomes,
DATE_FORMAT(getobsdatetime(getmaxconceptobsidwithformid(patient.patient_id,165470,13,@endDate)),'%d/%m/%Y') AS Outcomes_Date,
CASE
WHEN MAX(IF(obs.concept_id=165470,cn1.name,IF(obs.concept_id=165708,IF(TIMESTAMPDIFF(DAY,sinner.last_date,@endDate)< @daysOfRefil + 28,"",""),NULL))) <> ''
AND MAX(IF(obs.concept_id=165470,cn1.name,IF(obs.concept_id=165708,IF(TIMESTAMPDIFF(DAY,sinner.last_date,@endDate)< @daysOfRefil + 28,"",""),NULL))) = 'Death'
THEN ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (165889)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND e.`encounter_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=15
     AND ob.voided=0
     AND e.voided=0
     ORDER BY e.`encounter_datetime` DESC LIMIT 1)
END AS `cause_of_death`,
CASE
WHEN ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166349)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     -- AND e.`encounter_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=15
     AND ob.voided=0
     AND e.voided=0
     ORDER BY e.`encounter_datetime` DESC LIMIT 1) <> '' AND (( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166348)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     -- AND e.`encounter_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=15
     AND ob.voided=0
     AND e.voided=0
     ORDER BY e.`encounter_datetime` DESC LIMIT 1) <> '')
THEN ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166348)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     -- AND e.`encounter_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=15
     AND ob.voided=0
     AND e.voided=0
     ORDER BY e.`encounter_datetime` DESC LIMIT 1)
     ELSE ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166347)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     -- AND e.`encounter_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=15
     AND ob.voided=0
     AND e.voided=0
     ORDER BY e.`encounter_datetime` DESC LIMIT 1)
     END AS `VA_Cause_of_Death`,
-- IF(DATE_ADD(MAX(IF(obs.concept_id=165708,DATE_FORMAT(e2.encounter_datetime,'%Y-%m-%d'),NULL)) ,INTERVAL (MAX(IF(obs.concept_id=159368,obs.value_numeric,NULL)) + 28) DAY) >= @endDate ,"Active","LTFU") AS `CurrentARTStatus_Pharmacy`,
IFNULL (getcodedvalueobsid(getmaxconceptobsidwithformid(patient.patient_id,165470,13,@endDate)),getoutcome(getobsdatetime(getmaxconceptobsidwithformid(patient.patient_id,162240,27,@endDate)),getconceptval(getmaxconceptobsidwithformid(patient.patient_id,162240,27,@endDate),159368,patient.patient_id) ,28,IF(@endDate IS NULL OR @endDate = '', CURDATE(),@endDate)))  AS `CurrentARTStatus_Pharmacy`,
IFNULL(getcodedvalueobsid(getmaxconceptobsidwithformid(patient.patient_id,165470,13,DATE_SUB(@endDate,INTERVAL 3 MONTH))),getoutcome(getobsdatetime(getmaxconceptobsidwithformid(patient.patient_id,162240,27,getendofquarter(DATE_SUB(@endDate,INTERVAL 3 MONTH)))),getconceptval(getmaxconceptobsidwithformid(patient.patient_id,162240,27,getendofquarter(DATE_SUB(@endDate,INTERVAL 3 MONTH))),159368,patient.patient_id),
28,IF(@endDate IS NULL OR @endDate = "", CURDATE(),getendofquarter(DATE_SUB(@endDate,INTERVAL 3 MONTH)))))  AS `ARTStatus_PreviousQuarter`,
IF(DATE_ADD(MAX(IF(obs.concept_id=165708,DATE_FORMAT(sinner.last_date,'%Y-%m-%d'),NULL)) ,INTERVAL (MAX(IF(obs.concept_id=159368,obs.value_numeric,NULL)) + 28) DAY) >= @endDate ,"Active","LTFU") AS `CurrentARTStatus_Visit`,
 
DATE_FORMAT(person.birthdate,'%d/%m/%Y') AS `DOB`,
IF(TIMESTAMPDIFF(YEAR,person.birthdate,CURDATE())>=5,TIMESTAMPDIFF(YEAR,person.birthdate,CURDATE()),NULL) AS `Current_Age`,
IF(TIMESTAMPDIFF(YEAR,person.birthdate,CURDATE())<5,TIMESTAMPDIFF(MONTH,person.birthdate,CURDATE()),NULL) AS `CurrentAge_Months`,
CASE
WHEN
MAX(IF(obs.concept_id=160540,cn1.name, NULL)) = 'Transfer in'
OR MAX(IF(obs.concept_id=165242,cn1.name, NULL)) = 'Transfer in with records'
THEN "Yes"
ELSE "No"
END AS  `TI`,
CASE WHEN
MAX(IF(obs.concept_id=160540,cn1.name, NULL)) = 'Transfer in'
OR MAX(IF(obs.concept_id=165242,cn1.name, NULL)) = 'Transfer in with records'
THEN
( SELECT  DATE_FORMAT(ob.value_datetime,'%d/%m/%Y') FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` = 160534
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=14
     AND ob.value_datetime <= @endDate
     AND ob.voided=0
     AND e.voided=0
     LIMIT 1) END AS Date_Transfered_In,
pn.`family_name` AS Surname,
pn.`given_name` AS Firstname,
MAX(IF(sinner2.concept_id=1712,sinner2.concept_value,NULL)) AS `Educationallevel`,
MAX(IF(sinner2.concept_id=1054,sinner2.concept_value,NULL)) AS `MaritalStatus`,
MAX(IF(sinner2.concept_id=1542,sinner2.concept_value,NULL)) AS `JobStatus`,
part.`value` AS PhoneNo,
CASE WHEN
pa.`address2` IS NOT NULL
AND pa.`address2` <> ''
THEN pa.`address2`
ELSE pa.`address1`
END AS Address,
pa.`state_province` AS State_of_Residence,
pa.`city_village` AS LGA_of_Residence,
-- MAX(IF(sinner2.concept_id=5089,sinner2.value_numeric,NULL)) AS `LastWeight`,
( SELECT  ob.value_numeric FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (5089)
     AND ob.`obs_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=12
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `LastWeight`,
MAX(IF(sinner2.concept_id=5089,DATE_FORMAT(DATE(sinner2.last_date),'%d/%m/%Y'),NULL)) AS `LastWeightDate`,
CONCAT(
(SELECT ob.value_numeric FROM `obs` ob JOIN encounter e ON ob.`encounter_id`=e.`encounter_id`
WHERE ob.`concept_id` IN (5085)
AND ob.`obs_datetime` <= @endDate
AND ob.`person_id` = patient.`patient_id`
AND e.`encounter_type` = 12
AND ob.`voided` = 0
ORDER BY ob.`obs_datetime` DESC LIMIT 1),
"/",
(SELECT ob.value_numeric FROM `obs` ob JOIN encounter e ON ob.`encounter_id`=e.`encounter_id`
WHERE ob.`concept_id` IN (5086)
AND ob.`obs_datetime` <= @endDate
AND ob.`person_id` = patient.`patient_id`
AND e.`encounter_type` = 12
AND ob.`voided` = 0
ORDER BY ob.`obs_datetime` DESC LIMIT 1)) AS `CurrentBP`,
MAX(IF(sinner2.concept_id=5356,sinner2.concept_value,NULL)) AS `Whostage`,
( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (164506,164507)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`obs_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=13
     AND `value_coded` IN (165681,165682,165691,165692)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `FirstTLD_Pickup`,
DATE_FORMAT(( SELECT  MIN(DATE(`obs_datetime`)) FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (164506,164507)
     AND ob.`obs_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=13
     AND `value_coded` IN (165681,165682,165691,165692)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1),'%d/%m/%Y') AS `DateofFirstTLD_Pickup`,
     (SELECT  ob.`value_numeric` FROM `obs` ob
	JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (5497)
     AND ob.`person_id` = patient.`patient_id`
     AND e.encounter_type=11
     AND ob.voided=0
     AND e.voided=0
     ORDER BY e.`encounter_datetime` DESC LIMIT 1) AS `FirstCD4`,
     DATE((SELECT  e.`encounter_datetime` FROM `obs` ob
	JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (5497)
     AND ob.`person_id` = patient.`patient_id`
     AND e.encounter_type=11
     AND ob.voided=0
     AND e.voided=0
     ORDER BY e.`encounter_datetime` DESC LIMIT 1)) AS `FirstCD4Date`,
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (167079)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND e.`encounter_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=11
     AND ob.voided=0
     AND e.voided=0
     ORDER BY e.`encounter_datetime` DESC LIMIT 1) AS 'Indication_AHD',
     
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (167088) AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND e.`encounter_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=11
     AND ob.voided=0
     AND e.voided=0
     ORDER BY e.`encounter_datetime` DESC LIMIT 1) AS 'CD4_LFA_Result',
     
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166697) AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND e.`encounter_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=11
     AND ob.voided=0
     AND e.voided=0
     ORDER BY e.`encounter_datetime` DESC LIMIT 1) AS 'Other_Test_(TB-LAM_LF-LAM_etc)',
     
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (167090) AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND e.`encounter_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=11
     AND ob.voided=0
     AND e.voided=0
     ORDER BY e.`encounter_datetime` DESC LIMIT 1) AS 'Serology_for_CrAg_Result',
     
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (167082) AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND e.`encounter_datetime` <= @endDate
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=11
     AND ob.voided=0
     AND e.voided=0
     ORDER BY e.`encounter_datetime` DESC LIMIT 1) AS 'CSF_for_CrAg_Result',
     /*
     DATE(careCard.nextAppointment) AS EstimatedNextAppointmentPharmacy,
     DATE(careCardA.nextAppointmentA) AS NextAppointmentCareCard, 
     */
     (SELECT ob.value_text FROM `obs` ob JOIN encounter e ON ob.encounter_id = e.encounter_id 
     WHERE ob.`concept_id` IN (166406) 
     AND e.`encounter_datetime` <= @endDate 
     AND ob.`person_id` = patient.`patient_id` 
     AND e.encounter_type = 13 
     AND ob.voided = 0 
     AND e.voided = 0 
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS 'PillBalance',
     
     (SELECT ob.value_text FROM `obs` ob JOIN concept e ON ob.concept_id = e.concept_id 
     WHERE ob.`concept_id` IN (162169) 
     AND DATE(ob.`obs_datetime`) <= @endDate 
     AND ob.`person_id` = patient.`patient_id`
     AND ob.voided = 0  
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS 'Notes',
     -- DATE_FORMAT(getdatevalueobsid(getmaxconceptobsidwithformid(patient.patient_id,5096,27,@endDate)),'%d/%m/%Y') as `EstimatedNextAppointmentPharmacy`,
     DATE_FORMAT((SELECT ob.value_datetime FROM `obs` ob JOIN encounter e ON ob.encounter_id = e.encounter_id 
     WHERE ob.`concept_id` IN (5096) 
     -- AND e.`encounter_datetime` <= @endDate 
     AND ob.`person_id` = patient.`patient_id`  
     AND e.encounter_type = 13 
     AND ob.voided = 0 
     AND e.voided = 0 
     ORDER BY ob.obs_datetime DESC LIMIT 1),'%d/%m/%Y') AS 'EstimatedNextAppointmentPharmacy',

     DATE_FORMAT((SELECT ob.value_datetime FROM `obs` ob JOIN encounter e ON ob.encounter_id = e.encounter_id 
     WHERE ob.`concept_id` IN (5096) 
     -- AND e.`encounter_datetime` <= @endDate 
     AND ob.`person_id` = patient.`patient_id`  
     AND e.encounter_type = 12 
     AND ob.voided = 0 
     AND e.voided = 0 
     ORDER BY ob.obs_datetime DESC LIMIT 1),'%d/%m/%Y') AS `NextAppointmentCareCard`
   -- DATE_FORMAT(getdatevalueobsid(getmaxconceptobsidwithformid(patient.patient_id,5096,14,@endDate)),'%d/%m/%Y') as `NextAppointmentCareCard`
  FROM patient
  LEFT JOIN patient_identifier pid1 ON(pid1.patient_id=patient.patient_id AND patient.voided=0 AND pid1.identifier_type=4)
  LEFT JOIN patient_identifier pid2 ON(pid2.patient_id=patient.patient_id AND patient.voided=0 AND pid2.identifier_type=5)
  LEFT JOIN `person_name` pn ON(pn.`person_id`=patient.patient_id AND patient.voided=0 AND pn.`preferred`=1)
  LEFT JOIN `person_address` pa ON(pa.`person_id`=patient.patient_id AND patient.voided=0 AND pa.`preferred`=1)
  LEFT JOIN `person_attribute` part ON(part.`person_id`=patient.patient_id AND patient.voided=0 AND part.voided=0 AND part.`person_attribute_type_id`=8)
  INNER JOIN
  (SELECT
obs.person_id,
obs.concept_id,
 MAX(obs.obs_datetime) AS last_date,
MIN(obs.obs_datetime) AS first_date
FROM obs WHERE obs.voided=0 AND obs.obs_datetime<=@endDate AND concept_id IN(159599,165708,159368,164506,164513,164507,164514,165702,165703,165050,
856,164980,165470,160540,165242,165469,166043,164505,1652,161364,630,103166) GROUP BY obs.person_id,obs.concept_id ) AS sinner
ON (sinner.person_id=patient.patient_id )


LEFT JOIN
  (SELECT
obs.person_id,
obs.value_numeric,
obs.concept_id,
(SELECT `name` FROM concept_name WHERE (concept_name.`concept_id` = `obs`.`value_coded` AND `locale` = 'en' AND `locale_preferred` =1) LIMIT 1) AS concept_value,
MAX(obs.obs_datetime) AS last_date
FROM obs WHERE obs.voided=0 AND obs.obs_datetime<=@endDate AND concept_id IN(5356,5089,5085,5086, 1542, 1054, 1712) GROUP BY obs.person_id,obs.concept_id ) AS sinner2
ON (sinner2.person_id=patient.patient_id )

INNER JOIN obs ON(obs.person_id=patient.patient_id AND obs.concept_id=sinner.concept_id AND obs.obs_datetime=sinner.last_date AND obs.voided=0 )
INNER JOIN obs obs2 ON(obs2.person_id=patient.patient_id AND obs2.concept_id=sinner.concept_id AND obs2.obs_datetime=sinner.first_date AND obs2.voided=0 )
INNER JOIN encounter ON(encounter.patient_id=patient.patient_id AND encounter.form_id=23 AND encounter.voided=0)
LEFT JOIN encounter e ON(e.patient_id=patient.patient_id AND e.form_id=30 AND e.voided=0)
INNER JOIN person ON(person.person_id=patient.patient_id)
LEFT JOIN concept_name cn1 ON(obs.value_coded=cn1.concept_id AND cn1.locale='en' AND cn1.locale_preferred=1)
LEFT JOIN concept_name cn2 ON(obs2.value_coded=cn2.concept_id AND cn2.locale='en' AND cn2.locale_preferred=1)
LEFT JOIN
(SELECT patient_id,form_id,encounter_type,voided,MAX(encounter_datetime) AS encounter_datetime FROM encounter WHERE form_id=27 AND encounter_type=13 AND voided=0 AND DATE(`encounter_datetime`) <= @endDate  GROUP BY patient_id) e2 ON(e2.patient_id=patient.patient_id)
WHERE patient.voided=0 AND obs.concept_id IN(159599,165708,159368,164506,164513,164507,164514,165702,165703,165050,856,164980,165470,160540,165242) AND obs2.concept_id IN(159599,165708,159368,164506,164513,164507,164514,165702,165703,165050,856,164980,165470,160540,165242) GROUP BY patient.patient_id,pid1.identifier);

CREATE TABLE IPT_list AS (
SELECT
  pid1.identifier AS `PepID`,
   MAX(IF(obs1.concept_id=165727 AND obs1.value_coded= 1679,cn3.name,NULL)) AS `CurrentINHReceived`,
     MIN(IF(obs1.concept_id=165727 AND obs1.value_coded= 1679,DATE(e3.encounter_datetime),NULL)) AS `First_INH_Pickupdate`,
     MAX(IF(obs1.concept_id=165727 AND obs1.value_coded= 1679,DATE(e3.encounter_datetime),NULL)) AS `Last_INH_Pickupdate`,
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (1659)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=12
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `Current_TB_Status`,
     MAX(IF(obs1.concept_id=1659,DATE(e3.encounter_datetime),NULL)) AS `DateofCurrent_TBStatus`,
     DATE_FORMAT(getdatevalueobsid(getmaxconceptobsid(patient.patient_id,1113,@endDate)),'%d/%m/%Y') AS `TBTreatmentStartDate`
  FROM patient
  INNER JOIN patient_identifier pid1 ON(pid1.patient_id=patient.patient_id AND patient.voided=0 AND pid1.identifier_type=4)
  INNER JOIN encounter e3 ON(e3.patient_id=patient.patient_id AND e3.voided=0 AND e3.encounter_type=13 OR e3.encounter_type=12)
INNER JOIN obs obs1 ON(obs1.person_id=patient.patient_id AND obs1.concept_id IN(165727,1659) AND obs1.encounter_id=e3.encounter_id AND obs1.voided=0 )
INNER JOIN person ON(person.person_id=patient.patient_id)
LEFT JOIN concept_name cn3 ON(obs1.value_coded=cn3.concept_id AND cn3.locale='en' AND cn3.locale_preferred=1)
WHERE patient.voided=0 GROUP BY patient.patient_id,pid1.identifier);

CREATE TABLE presumtive_tb_list AS (
SELECT
pid1.identifier AS `PepID`,
( SELECT  DATE_FORMAT(MAX(e.encounter_datetime),'%d/%m/%Y') FROM  encounter e
     WHERE e.`encounter_datetime` <= @endDate
     AND e.`patient_id` =  patient.`patient_id`
     AND e.encounter_type=23
     AND e.voided=0
     ORDER BY e.`encounter_datetime` DESC LIMIT 1) AS `IPT_Screening_Date`,
   ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (143264)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=23
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS "Are_you_coughing_currently",
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (140238)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=23
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS "Do_you_have_fever",
     ( SELECT  CASE
   WHEN ob.value_coded = 2 THEN "No"
   WHEN ob.value_coded = 1 THEN "Yes"
   ELSE ''
   END
   FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (832)
     AND ob.`person_id` =  patient.`patient_id`
     AND (e.encounter_type=23)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS "Are_you_losing_weight",
     ( SELECT  CASE
   WHEN ob.value_coded = 2 THEN "No"
   WHEN ob.value_coded = 1 THEN "Yes"
   ELSE ''
   END
   FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (133027)
     AND ob.`person_id` =  patient.`patient_id`
     AND (e.encounter_type=23)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS "Are_you_having_night_sweats",
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (165967)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=23
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS "History_of_contacts_with_TB_patients",
( SELECT  CASE
   WHEN ob.value_coded = 1 THEN "Yes"
   ELSE ''
   END
   FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166141)
     AND ob.`person_id` =  patient.`patient_id`
     AND (e.encounter_type=23)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS "Sputum_AFB",
      ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (165968)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=23
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS  "Sputum_AFB_Result",
     ( SELECT  CASE
   WHEN ob.value_coded = 1 THEN "Yes"
   ELSE ''
   END
   FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166142)
     AND ob.`person_id` =  patient.`patient_id`
     AND (e.encounter_type=23)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS "GeneXpert",
      ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (165975)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=23
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS  "GeneXpert_Result",
     ( SELECT  CASE
   WHEN ob.value_coded = 1 THEN "Yes"
   ELSE ''
   END
   FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166143)
     AND ob.`person_id` =  patient.`patient_id`
     AND (e.encounter_type=23)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS "Chest_Xray",
      ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (165972)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=23
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS  "Chest_Xray_Result",
     ( SELECT  CASE
   WHEN ob.value_coded = 1 THEN "Yes"
   ELSE ''
   END
   FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166144)
     AND ob.`person_id` =  patient.`patient_id`
     AND (e.encounter_type=23)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS "Culture",
      ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (165969)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=23
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS  "Culture_Result",
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (165986)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=23
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `Is_Patient_Eligible_For_IPT`,
	 ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166007)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=23
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `IPTOutcome`,
     
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166012)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=23
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `ReasonforstoppingIPT`,
     
     DATE_FORMAT((SELECT ob.value_datetime FROM `obs` ob JOIN encounter e ON ob.encounter_id = e.encounter_id 
     WHERE ob.`concept_id` IN (166008) 
     AND e.`encounter_datetime` <= @endDate 
     AND ob.`person_id` = patient.`patient_id`  
     AND e.encounter_type = 13 
     AND ob.voided = 0 
     AND e.voided = 0 
     ORDER BY ob.obs_datetime DESC LIMIT 1),'%d/%m/%Y') AS 'IPTOutcomeDate'
  FROM patient
  INNER JOIN patient_identifier pid1 ON(pid1.patient_id=patient.patient_id AND patient.voided=0 AND pid1.identifier_type=4)
WHERE patient.voided=0 GROUP BY patient.patient_id,pid1.identifier

);

CREATE TABLE OTZ_list AS (
SELECT
pid1.identifier AS `PepID`,
     DATE_FORMAT(pprg.date_enrolled,'%d/%m/%Y') AS Date_Enrolled_Into_OTZ,
   (SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166256)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=36
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `Positive_living`,
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166257)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=36
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `Treatment_Literacy`,
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166258)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=36
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `Adolescents_participation`,
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166259)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=36
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `Leadership_training`,
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166260)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=36
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `Peer_To_Peer_Mentoship`,
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166255)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=36
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `Role_of_OTZ`,
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166267)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=36
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `OTZ_Champion_Oreintation`,
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166272)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=36
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `Transitioned_Adult_Clinic`,
     ( SELECT  cn.`name` FROM `obs` ob  JOIN `concept_name` cn ON cn.`concept_id` = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166275)  AND cn.`locale` = 'en' AND cn.`locale_preferred` = 1
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=36
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `OTZ_Outcome`,
     ( SELECT  DATE_FORMAT(ob.value_datetime,'%d/%m/%Y') FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` = 166008
     AND ob.`person_id` =  patient.`patient_id`
     AND e.encounter_type=36
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `OTZ_Outcome_Date`
FROM
  encounter
  LEFT JOIN patient
    ON (
      encounter.patient_id = patient.patient_id
      AND patient.voided = 0
      AND encounter.voided = 0
    )
  LEFT JOIN `person`
    ON (
      encounter.patient_id = person.`person_id`
      AND person.voided = 0
      AND encounter.voided = 0
    )
  LEFT JOIN obs
    ON (
      obs.encounter_id = encounter.encounter_id
    )
  LEFT JOIN patient_identifier pid1
    ON (
      pid1.patient_id = encounter.patient_id
      AND pid1.identifier_type = 4
      AND pid1.voided = 0
    )
  LEFT JOIN patient_identifier pid2
    ON (
      pid2.patient_id = encounter.patient_id
      AND pid2.identifier_type = 10
      AND pid2.voided = 0
    )
  LEFT JOIN patient_identifier pid3
    ON (
      pid3.patient_id = encounter.patient_id
      AND pid3.identifier_type = 4
      AND pid3.voided = 0
    )
  LEFT JOIN `person_name` pname
    ON (
      pname.`person_id` = encounter.patient_id
    )
  LEFT JOIN form
    ON (
      encounter.form_id = form.form_id
      AND encounter.voided = 0
    )
  LEFT JOIN users
    ON (
      encounter.creator = users.user_id
    )
  LEFT JOIN concept_name cn1
    ON (
      cn1.concept_id = obs.value_coded
      AND cn1.locale = 'en'
      AND cn1.locale_preferred = 1
    )
    INNER JOIN (SELECT DISTINCT encounter.patient_id FROM encounter WHERE encounter.form_id=73 AND encounter.voided=0) AS innerquery ON(innerquery.patient_id=patient.patient_id AND patient.voided=0)
    LEFT JOIN patient_program pprg ON(pprg.patient_id=patient.patient_id AND pprg.program_id=5 AND pprg.voided=0)

  AND encounter.voided = 0
GROUP BY patient.patient_id);

CREATE TEMPORARY TABLE final_line_list AS (
SELECT
f.* ,
ip.`First_INH_Pickupdate`,
ip.`Last_INH_Pickupdate`,
ip.`CurrentINHReceived`,
ip.`Current_TB_Status`,
ip.`DateofCurrent_TBStatus`,
ip.`TBTreatmentStartDate`,
IF(b.`patient_Id` IS NOT NULL, "Yes", "No" ) AS "PBS",
IF(b.`patient_Id` IS NOT NULL, IF(invalidbio.patient_Id IS NOT NULL,"No","Yes"),"") AS "ValidBiometric",
DATE_FORMAT(b.`date_created`,'%d/%m/%Y') AS PBSDateCreated,
IF(c.`patient_Id` IS NOT NULL, "Yes", "No" ) AS "PBS_Recaptured",
DATE_FORMAT(c.`date_created`,'%d/%m/%Y') AS RecapturedDate,
c.`recapture_count` AS "Recapture_count",
ptb.`IPT_Screening_Date`,
ptb.`Are_you_coughing_currently`,
ptb.`Do_you_have_fever`,
ptb.`Are_you_losing_weight`,
ptb.`Are_you_having_night_sweats`,
ptb.`History_of_contacts_with_TB_patients`,
ptb.`Sputum_AFB`,
ptb.`Sputum_AFB_Result`,
ptb.`GeneXpert`,
ptb.`GeneXpert_Result`,
ptb.`Chest_Xray`,
ptb.`Chest_Xray_Result`,
ptb.`Culture`,
ptb.`Culture_Result`,
ptb.`Is_Patient_Eligible_For_IPT`,
ptb.`IPTOutcome`,
ptb.`ReasonforstoppingIPT`,
ptb.`IPTOutcomeDate`,
otz.`Date_Enrolled_Into_OTZ`,
otz.`Transitioned_Adult_Clinic`,
otz.`OTZ_Outcome`,
otz.`OTZ_Outcome_Date`,
otz.`Positive_living`,
otz.`Treatment_Literacy`,
otz.`Adolescents_participation`,
otz.`Leadership_training`,
otz.`Peer_To_Peer_Mentoship`,
otz.`Role_of_OTZ`,
otz.`OTZ_Champion_Oreintation`
FROM full_line_list  AS f
LEFT JOIN (SELECT  DISTINCT `patient_Id`,`date_created` FROM `biometricinfo` GROUP BY `patient_Id`) AS b ON (f.patient_id = b.patient_id)
LEFT JOIN (SELECT DISTINCT biometricinfo.patient_Id, biometricinfo.date_created FROM biometricinfo WHERE  template NOT LIKE 'Rk1S%' OR CONVERT(new_template USING utf8) NOT LIKE 'Rk1S%' GROUP BY patient_Id) AS invalidbio ON(f.patient_id=invalidbio.patient_Id)
LEFT JOIN (SELECT  DISTINCT `patient_Id`,`date_created`,`recapture_count` FROM `biometricverificationinfo` GROUP BY `patient_Id`) AS c ON (f.patient_id = c.patient_id)
LEFT JOIN IPT_list AS IP ON (CONCAT(f.`PepID`, f.`Datim_Code`) =  CONCAT(IP.`PepID`, f.`Datim_Code`))
LEFT JOIN presumtive_tb_list AS ptb ON (CONCAT(f.`PepID`, f.`Datim_Code`) =  CONCAT(ptb.`PepID`, f.`Datim_Code`))
LEFT JOIN OTZ_list AS otz ON (CONCAT(f.`PepID`, f.`Datim_Code`) =  CONCAT(otz.`PepID`, f.`Datim_Code`))
);

DROP TABLE  IF EXISTS  full_line_list;
DROP TABLE  IF EXISTS  IPT_list;
DROP TABLE IF EXISTS presumtive_tb_list;
DROP TABLE IF EXISTS OTZ_list;
SELECT * FROM final_line_list;