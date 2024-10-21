SET @startDate := '';
SET @endDate := '2024-10-02';
SELECT  
"APIN" AS "IP", 
   (SELECT `state_province`  FROM  `location` WHERE `location_id` = 8 LIMIT 1) AS State,
   (SELECT `city_village`  FROM  `location` WHERE `location_id` = 8 LIMIT 1) LGA,
   (SELECT `address1`  FROM  `location` WHERE `location_id` = 8 LIMIT 1) Datim_Code,
   (SELECT `name`  FROM  `location` WHERE `location_id` = 8 LIMIT 1) FacilityName, 
   encounter.`encounter_id` AS id,
   pid1.identifier AS HTSClientCode,
   pid3.identifier AS PepID,
   person.gender AS `Sex`,
   DATE_FORMAT(person.birthdate,'%d/%m/%Y') AS `DOB`,
   IF(TIMESTAMPDIFF(YEAR,person.birthdate,CURDATE())>=5,TIMESTAMPDIFF(YEAR,person.birthdate,CURDATE()),NULL) AS `Current_Age`,
   DATE_FORMAT(encounter.encounter_datetime,'%d/%m/%Y') AS VisitDate,
   pname.`given_name` Firstname,
   pname.`family_name` Surname,
   CASE 
   WHEN MAX(IF(obs.concept_id= 165839, cn1.name, NULL)) = 'Blood Bank' THEN 'Outreach program'
   ELSE MAX(IF(obs.concept_id= 165839, cn1.name, NULL)) 
   END AS 'Settings',
   MAX(IF(obs.concept_id= 165966, cn1.name, NULL)) AS 'Settingsothersspecify',
   MAX(IF(obs.concept_id= 165790, cn1.name, NULL)) AS 'FirtTimeVisit',
   MAX(IF(obs.concept_id= 165793, cn1.name, NULL)) AS 'TypeofSession',
   MAX(IF(obs.concept_id= 165480, cn1.name, NULL)) AS 'ReferredFrom',
   MAX(IF(obs.concept_id= 1054, cn1.name, NULL)) AS 'CivilStatus',
   MAX(IF(obs.concept_id= 160312, obs.value_numeric, NULL)) AS 'Noofchildren5yrsoldslept',
   MAX(IF(obs.concept_id= 5557, obs.value_numeric, NULL)) AS 'NoofWives',
   MAX(IF(obs.concept_id= 165794, cn1.name, NULL)) AS 'Clientidentifiedfromindexclient',
   MAX(IF(obs.concept_id= 165798, cn1.name, NULL)) AS 'IndexType',
   MAX(IF(obs.concept_id= 165859, cn1.name, NULL)) AS 'IndexClientID',
   MAX(IF(obs.concept_id= 165976, cn1.name, NULL)) AS 'HIVRetestingForVerification',
   MAX(IF(obs.concept_id= 165799, cn1.name, NULL)) AS 'PreviouslytestedHIVnegative',
   MAX(IF(obs.concept_id= 165800, cn1.name, NULL)) AS 'Everhadsexualintercourse',
   ( SELECT  CASE 
   WHEN ob.value_coded = 2 THEN "No" 
   WHEN ob.value_coded = 1 THEN "Yes"
   ELSE ''
   END 
   FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (1434) 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2)
     AND ob.voided=0
     AND e.voided=0
     LIMIT 1) AS 'CURRENTLYPREGNANT',
   ( SELECT  CASE 
   WHEN ob.value_coded = 2 THEN "No" 
   WHEN ob.value_coded = 1 THEN "Yes"
   ELSE ''
   END 
   FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (1063) 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2)
     AND ob.voided=0
     AND e.voided=0
     LIMIT 1) AS 'Bloodtransfusion',
   MAX(IF(obs.concept_id=65801, cn1.name, NULL)) AS 'ClientinformedaboutHIVtransmissionroutes',
   MAX(IF(obs.concept_id= 159218, cn1.name, NULL)) AS 'Unprotectedsexualintercourse',
   MAX(IF(obs.concept_id= 165802, cn1.name, NULL)) AS 'ClientinformedaboutriskfactorsforHIVtransmission',
   MAX(IF(obs.concept_id= 165803, cn1.name, NULL)) AS 'Unprotectedsexwithregularpartnerinthelast3months',	
   MAX(IF(obs.concept_id= 165804, cn1.name, NULL)) AS 'ClientinformedonpreventingHIVtransmissionmethods',
   MAX(IF(obs.concept_id= 164809, cn1.name, NULL)) AS 'Sexuallytransmittedgenitaltractinfectionswithinthelast3monthsorotherchronicSTI',
   MAX(IF(obs.concept_id= 165884, cn1.name, NULL)) AS 'Clientinformedaboutpossibletestresults',
   MAX(IF(obs.concept_id= 165806, cn1.name, NULL)) AS 'Morethan1sexpartnerduringlast3months',
   ( SELECT  CASE 
   WHEN ob.value_coded = 2 THEN "No" 
   WHEN ob.value_coded = 1 THEN "Yes"
   ELSE ''
   END 
   FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (1710) 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2)
     AND ob.voided=0
     AND e.voided=0
     LIMIT 1) AS 'INFORMEDCONSENT',
   MAX(IF(obs.concept_id= 143264, cn1.name, NULL)) AS 'Cough',
   MAX(IF(obs.concept_id= 165809, cn1.name, NULL)) AS 'Complaintsofvaginaldischargeorburningwhenurinating',
   ( SELECT  CASE 
   WHEN ob.value_coded = 2 THEN "No" 
   WHEN ob.value_coded = 1 THEN "Yes"
   ELSE ''
   END 
   FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (832) 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2)
     AND ob.voided=0
     AND e.voided=0
     LIMIT 1) AS 'Weightloss', 
   MAX(IF(obs.concept_id= 165810, cn1.name, NULL)) AS 'Complaintsoflowerabdominalpainswithorwithoutvaginaldischarge',   
   MAX(IF(obs.concept_id= 140238, cn1.name, NULL)) AS 'Fever',
   ( SELECT  CASE 
   WHEN ob.value_coded = 2 THEN "No" 
   WHEN ob.value_coded = 1 THEN "Yes"
   ELSE ''
   END 
   FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (133027) 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2)
     AND ob.voided=0
     AND e.voided=0
     LIMIT 1) AS 'Nightsweats',
   MAX(IF(obs.concept_id= 124068, cn1.name, NULL)) AS 'TuberculosisContact',
   MAX(IF(obs.concept_id= 165813, cn1.name, NULL)) AS 'Complaintsofgenitalsore(s)orswolleninguinallymphnodeswithorwithoutpains',   
   MAX(IF(obs.concept_id= 165840, cn1.name, NULL)) AS 'HIVScreeningTest',
   MAX(IF(obs.concept_id= 165841, cn1.name, NULL)) AS 'HIVConfirmatoryTest',
   MAX(IF(obs.concept_id= 165842, cn1.name, NULL)) AS 'TieBreaker',
   MAX(IF(obs.concept_id= 165844, DATE_FORMAT(obs.`value_datetime`,'%d/%m/%Y'), NULL)) AS 'HIVScreeningTestDate',
   MAX(IF(obs.concept_id= 165845, DATE_FORMAT(obs.`value_datetime`,'%d/%m/%Y'), NULL)) AS 'HIVConfirmatoryTestDate',
   MAX(IF(obs.concept_id= 165846, DATE_FORMAT(obs.`value_datetime`,'%d/%m/%Y'), NULL)) AS 'TieBreakerDate',
   MAX(IF(obs.concept_id= 165843, cn1.name, NULL)) AS 'HIVFinalResult',
   MAX(IF(obs.concept_id= 165881, cn1.name, NULL)) AS 'HaveyoubeentestedforHIVbeforewithinthisyear',  		
   MAX(IF(obs.concept_id= 165820, cn1.name, NULL)) AS 'Riskreductionplandeveloped',
   MAX(IF(obs.concept_id= 165818, cn1.name, NULL)) AS 'HIVRequestandResultformsignedbytester',   
   MAX(IF(obs.concept_id= 165821, cn1.name, NULL)) AS 'Posttestdisclosureplandeveloped',
   MAX(IF(obs.concept_id= 165819, cn1.name, NULL)) AS 'HIVRequestandResultformfilledwithCTIntakeForm',
   MAX(IF(obs.concept_id= 165822, cn1.name, NULL)) AS 'WillbringpartnersforHIVtesting',
   MAX(IF(obs.concept_id= 164848, cn1.name, NULL)) AS 'ReceivedHIVtestresult',
   MAX(IF(obs.concept_id= 165823, cn1.name, NULL)) AS 'Willbringownchildrenlessthan5yearsforHIVtesting',
   MAX(IF(obs.concept_id= 159382, cn1.name, NULL)) AS 'PostHIVtestcounseling',
   MAX(IF(obs.concept_id= 1382, cn1.name, NULL)) AS 'FAMILYPLANNINGCOUNSELING',
   MAX(IF(obs.concept_id= 165883, cn1.name, NULL)) AS 'ClientorPartnerUseFamilyPlanningMethodotherthancondoms',
   MAX(IF(obs.concept_id= 165823, cn1.name, NULL)) AS 'Willbringownchildrenlessthan5yearsforHIVtesting',
   ( SELECT  CASE 
   WHEN ob.value_coded = 2 THEN "No" 
   WHEN ob.value_coded = 1 THEN "Yes"
   ELSE ''
   END 
   FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (5571) 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2)
     AND ob.voided=0
     AND e.voided=0
     LIMIT 1) AS 'FAMILYPLANNINGVIACONDOMS',
   MAX(IF(obs.concept_id= 159777, cn1.name, NULL)) AS 'Condomsgivenduringthevisit',
   ( SELECT  CASE 
   WHEN ob.value_coded = 2 THEN "No" 
   WHEN ob.value_coded = 1 THEN "Yes"
   ELSE ''
   END 
   FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (1648) 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2)
     AND ob.voided=0
     AND e.voided=0
     LIMIT 1) AS 'PATIENTREFERRED',
   MAX(IF(obs.concept_id= 165045, obs.`value_text`, NULL)) AS 'AdditionalComments',   
   MAX(IF(obs.concept_id= 159430, cn1.name, NULL)) AS 'HepatitisBSurfaceAntigenTest', 
   MAX(IF(obs.concept_id= 161471, cn1.name, NULL)) AS 'HepatitisCantibodyspottest',
  IF(Opt.value_coded= 1066 IS NOT NULL , MAX(IF(Opt.value_coded= 1066, 'No', 'Yes')), NULL) AS 'OptOutofRTRI',
  
  
  ( SELECT  cn.name FROM `obs` ob JOIN concept_name cn ON cn.concept_id = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166216) AND cn.locale = 'en' AND cn.locale_preferred =1
     AND e.encounter_datetime <= @endDate 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2 OR e.encounter_type = 39)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `HIVRecencyTestName`,
    
  
   (SELECT DATE_FORMAT(MAX(obs.`value_datetime`),'%d/%m/%Y') FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
   WHERE ob.`concept_id` IN (165850)
   AND e.encounter_datetime <= @endDate 
   AND ob.person_id = patient.`patient_id`
   AND (e.encounter_type = 20 OR e.encounter_type = 39 OR e.encounter_type = 2)
   AND ob.voided = 0 AND e.voided = 0
   ORDER BY ob.obs_datetime DESC LIMIT 1
   ) AS 'HIVRecencyTestDate',
   
   pid2.identifier AS 'recency_number',
   
   ( SELECT  cn.name FROM `obs` ob JOIN concept_name cn ON cn.concept_id = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166212) AND cn.locale = 'en' AND cn.locale_preferred =1
     AND e.encounter_datetime <= @endDate 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2 OR e.encounter_type = 39)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `Control_line`,
     
     ( SELECT  cn.name FROM `obs` ob JOIN concept_name cn ON cn.concept_id = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166243) AND cn.locale = 'en' AND cn.locale_preferred =1
     AND e.encounter_datetime <= @endDate 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2 OR e.encounter_type = 39)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `Verification_line`,
     
     ( SELECT  cn.name FROM `obs` ob JOIN concept_name cn ON cn.concept_id = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166211) AND cn.locale = 'en' AND cn.locale_preferred =1
     AND e.encounter_datetime <= @endDate 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2 OR e.encounter_type = 39)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `long_term_line`,
     
     ( SELECT  cn.name FROM `obs` ob JOIN concept_name cn ON cn.concept_id = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166213) AND cn.locale = 'en' AND cn.locale_preferred =1
     AND e.encounter_datetime <= @endDate 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2 OR e.encounter_type = 39)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `HIVRecencyInterpretation`,
     
     ( SELECT  cn.name FROM `obs` ob JOIN concept_name cn ON cn.concept_id = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166244) AND cn.locale = 'en' AND cn.locale_preferred =1
     AND e.encounter_datetime <= @endDate 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2 OR e.encounter_type = 39)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `viral_load_request`,
     
     ( SELECT  DATE_FORMAT(ob.value_datetime,'%d/%m/%Y') FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (159951)
     AND e.encounter_datetime <= @endDate 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2 OR e.encounter_type = 39)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `SampleCollectionDate`,
     
      (SELECT  DATE_FORMAT(ob.value_datetime,'%d/%m/%Y') FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (165988)
     AND e.encounter_datetime <= @endDate 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2 OR e.encounter_type = 39)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `SampleCollectionSentDate`,
     
     ( SELECT  cn.name FROM `obs` ob JOIN concept_name cn ON cn.concept_id = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166241) AND cn.locale = 'en' AND cn.locale_preferred =1
     AND e.encounter_datetime <= @endDate 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2 OR e.encounter_type = 39)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `VL_Result_Classification`,
     
     ( SELECT  ob.value_numeric FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (856)
     AND e.encounter_datetime <= @endDate 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2 OR e.encounter_type = 39)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `viral_load_result`,  
     
   
     ( SELECT  DATE_FORMAT(ob.value_datetime,'%d/%m/%Y') FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166423) 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2 OR e.encounter_type = 39)
     AND ob.voided=0
     AND e.voided=0
     LIMIT 1) AS `viral_load_result_date`,
     
     (SELECT  DATE_FORMAT(ob.value_datetime,'%d/%m/%Y') FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (165987)
     AND e.encounter_datetime <= @endDate 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2 OR e.encounter_type = 39)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `DateResultRecievedFacility`,
     
     
     ( SELECT  cn.name FROM `obs` ob JOIN concept_name cn ON cn.concept_id = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166214) AND cn.locale = 'en' AND cn.locale_preferred =1
     AND e.encounter_datetime <= @endDate 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2 OR e.encounter_type = 39)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `FinalRecencyResult`,
     
     ( SELECT  cn.name FROM `obs` ob JOIN concept_name cn ON cn.concept_id = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166938) AND cn.locale = 'en' AND cn.locale_preferred =1
     AND e.encounter_datetime <= @endDate 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2 OR e.encounter_type = 39)
     AND `value_coded` IN (1065,1066)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS 'client_linked_to HIVcare?',
     
     (SELECT  DATE_FORMAT(ob.value_datetime,'%d/%m/%Y') FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166939)
     -- AND e.encounter_datetime <= @endDate 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type = 39)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `DateLinkedToCare`,
     
     ( SELECT  cn.name FROM `obs` ob JOIN concept_name cn ON cn.concept_id = ob.value_coded JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166940) AND cn.locale = 'en' AND cn.locale_preferred =1
     AND e.encounter_datetime <= @endDate 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type=20 OR e.encounter_type=2 OR e.encounter_type = 39)
     AND `value_coded` IN (1065,1066)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS 'initiated_on_ART?',
     
     (SELECT  DATE_FORMAT(ob.value_datetime,'%d/%m/%Y') FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166941)
     -- AND e.encounter_datetime <= @endDate 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type = 39)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `DateInitiated`,
     
     (SELECT  ob.`value_text` FROM `obs` ob JOIN encounter e ON ob.encounter_id=e.encounter_id
     WHERE ob.`concept_id` IN (166905)
     AND e.encounter_datetime <= @endDate 
     AND ob.`person_id` =  patient.`patient_id` 
     AND (e.encounter_type = 39)
     AND ob.voided=0
     AND e.voided=0
     ORDER BY ob.obs_datetime DESC LIMIT 1) AS `Art_Number`
     
    
  FROM  encounter 
  LEFT JOIN patient ON(encounter.patient_id=patient.patient_id AND patient.voided=0 AND encounter.voided=0)
  LEFT JOIN `person` ON(encounter.patient_id=person.`person_id` AND person.voided=0 AND encounter.voided=0)
  LEFT JOIN  obs ON(obs.encounter_id=encounter.encounter_id)
  LEFT JOIN  obs ob2 ON(ob2.encounter_id=encounter.encounter_id) AND ob2.concept_id IN(165858)
  LEFT JOIN  obs ob3 ON(ob3.encounter_id=encounter.encounter_id) AND ob3.concept_id IN(165857)	
  LEFT JOIN patient_identifier pid1 ON(pid1.patient_id=encounter.patient_id AND pid1.identifier_type=8 AND pid1.voided=0)
  LEFT JOIN patient_identifier pid2 ON(pid2.patient_id=encounter.patient_id AND pid2.identifier_type=10 AND pid2.voided=0)
  LEFT JOIN patient_identifier pid3 ON(pid3.patient_id=encounter.patient_id AND pid3.identifier_type=4 AND pid3.voided=0)
  LEFT JOIN `person_name` pname ON(pname.`person_id`=encounter.patient_id)
  LEFT JOIN form ON(encounter.form_id=form.form_id AND encounter.voided=0)
  LEFT JOIN users ON(encounter.creator=users.user_id)
  LEFT JOIN concept_name cn1 ON(cn1.concept_id=obs.value_coded AND cn1.locale='en' AND cn1.locale_preferred=1)
  LEFT JOIN  obs Opt ON(Opt.encounter_id=encounter.encounter_id) AND Opt.concept_id IN(165805)
  WHERE encounter.form_id IN(10) AND encounter.voided=0 AND encounter.encounter_datetime BETWEEN @startDate AND @endDate
  GROUP BY patient.patient_id,encounter.encounter_id,DATE(encounter.encounter_datetime);

