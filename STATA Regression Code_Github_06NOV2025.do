/* Project Name: Hallie - Fluid by Weight
	Written by: Emily Walzl
	Date: November 6, 2025 */
	
	
/* Mortality Regression Models for Primary and Sensitivity Analyses */
/* Outcome of Interest: 30-day Mortality */
/* Predictor of Interest: Fluid by weight (using various methods - Sep-1 Approach, Pragmatic Approach, and Tailored Approach) */
/* Model Adjustment Variables: 
								Age
								Sex  
								BMI 
								Admission from SNF/SAR/LTAC
								Hospitalization in prior 90-days
								Mod/Severe kidney disease   
								Mod/Severe liver disease
								CHF
								Malignancy 
								Predicted mortality continuous
								Initial lactatea
								Initial creatinineb
								PaO2: FiO2 ratioc,
								Mechanical ventilation in 6 hours
								Vasopressors in 6 hours 
								AMS on presentation
								Charlson score  continuous or categorical; leave up to Emily
								Highest Temp first 3 hours categorical 
								Lowest SBP first 3 hours  categorical
								Highest RR first 3 hours  categorical
								Highest HR first 3 hours  categorical
								Highest WBC 
								Highest bilirubind
								Lowest plateletsd */
/* Random Effect for Hospital Used */
/* IPTW (calculated in SAS for each model) used for weighting */


/****************************************************************************************************/
/***************************************** Primary Analyses *****************************************/	
/****************************************************************************************************/
log using "Regression Output_05Nov2025"

/******************************** Hypoperfused without Comorbidities ********************************/
/* Load in dataset */
import sas using "sample_wgts_04nov2025.sas7bdat", clear
keep if (hypo_woutcomorb == 1) /* Keep only hypoperfused without comorbidities cohort */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PH] || hosp_PH: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_04Nov2025.xlsx", sheet(Prag Hypowout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Pragmaticfluidmeasure] - _b[0.Pragmaticfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SH] || hosp_SH: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_04Nov2025.xlsx", sheet(Sep1 Hypowout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.SEP1fluidmeasure] - _b[0.SEP1fluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_TH] || hosp_TH: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_04Nov2025.xlsx", sheet(Tailor Hypowout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Tailoredfluidmeasure] - _b[0.Tailoredfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 
 /******************************** Hypoperfused with Comorbidities ********************************/
/* Load in dataset */
import sas using "sample_wgts_04nov2025.sas7bdat", clear
keep if (hypo_wcomorb == 1) /* Keep only hypoperfused with comorbidities cohort */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PHC] || hosp_PHC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_04Nov2025.xlsx", sheet(Prag Hypow) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Pragmaticfluidmeasure] - _b[0.Pragmaticfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SHC] || hosp_SHC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_04Nov2025.xlsx", sheet(Sep1 Hypow) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.SEP1fluidmeasure] - _b[0.SEP1fluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_THC] || hosp_THC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_04Nov2025.xlsx", sheet(Tailor Hypow) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Tailoredfluidmeasure] - _b[0.Tailoredfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 
 /******************************** Intermediate Lactate without Comorbidities ********************************/
/* Load in dataset */
import sas using "sample_wgts_04nov2025.sas7bdat", clear
keep if (interlact_woutcomorb == 1) /* Keep only Intermediate lactate without comorbidities cohort */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PI] || hosp_PI: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_04Nov2025.xlsx", sheet(Prag Interwout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Pragmaticfluidmeasure] - _b[0.Pragmaticfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SI] || hosp_SI: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_04Nov2025.xlsx", sheet(Sep1 Interwout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.SEP1fluidmeasure] - _b[0.SEP1fluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_TI] || hosp_TI: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_04Nov2025.xlsx", sheet(Tailor Interwout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Tailoredfluidmeasure] - _b[0.Tailoredfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 
 /******************************** Intermediate Lactate with Comorbidities ********************************/
/* Load in dataset */
import sas using "sample_wgts_04nov2025.sas7bdat", clear
keep if (interlact_wcomorb == 1) /* Keep only Intermediate lactate with comorbidities cohort */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PIC] || hosp_PIC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_04Nov2025.xlsx", sheet(Prag Interw) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Pragmaticfluidmeasure] - _b[0.Pragmaticfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SIC] || hosp_SIC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_04Nov2025.xlsx", sheet(Sep1 Interw) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.SEP1fluidmeasure] - _b[0.SEP1fluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_TIC] || hosp_TIC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_04Nov2025.xlsx", sheet(Tailor Interw) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Tailoredfluidmeasure] - _b[0.Tailoredfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 /**************************************************************************************************************************************/
/***************************************** Primary Analyses - with Fluid measure in increments *****************************************/
/************************************************ 0-10, 11-20, 21-30, 31-40, 41-50, 60+ ************************************************/
/**************************************************************************************************************************************/
log using "Regression Output_Cat_05Nov2025"

/******************************** Hypoperfused without Comorbidities ********************************/
/* Load in dataset */
import sas using "sample_wgts_04nov2025.sas7bdat", clear
keep if (hypo_woutcomorb == 1) /* Keep only hypoperfused without comorbidities cohort */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure_cat c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PH] || hosp_PH: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Cat_05Nov2025.xlsx", sheet(Prag Hypowout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure_cat, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[2.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
putexcel A30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[3.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
 putexcel D30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[4.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
 putexcel G30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[5.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
 putexcel J30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[6.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
 putexcel M30=matrix(r(table)), names /* Output results to excel */
 
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure_cat c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SH] || hosp_SH: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Cat_05Nov2025.xlsx", sheet(SEP1 Hypowout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure_cat, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[2.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
putexcel A30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[3.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
 putexcel D30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[4.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
 putexcel G30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[5.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
 putexcel J30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[6.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
 putexcel M30=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure_cat c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_TH] || hosp_TH: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Cat_05Nov2025.xlsx", sheet(Tail Hypowout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure_cat, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[2.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
putexcel A30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[3.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
 putexcel D30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[4.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
 putexcel G30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[5.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
 putexcel J30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[6.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
 putexcel M30=matrix(r(table)), names /* Output results to excel */
 
 
 
 /******************************** Hypoperfused with Comorbidities ********************************/
/* Load in dataset */
import sas using "sample_wgts_04nov2025.sas7bdat", clear
keep if (hypo_wcomorb == 1) /* Keep only hypoperfused with comorbidities cohort */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure_cat c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PHC] || hosp_PHC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Cat_05Nov2025.xlsx", sheet(Prag Hypow) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure_cat, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 /* Calculate Risk Differences */
 nlcom _b[2.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
putexcel A30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[3.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
 putexcel D30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[4.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
 putexcel G30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[5.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
 putexcel J30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[6.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
 putexcel M30=matrix(r(table)), names /* Output results to excel */
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure_cat c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SHC] || hosp_SHC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Cat_05Nov2025.xlsx", sheet(SEP1 Hypow) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure_cat, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[2.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
putexcel A30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[3.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
 putexcel D30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[4.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
 putexcel G30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[5.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
 putexcel J30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[6.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
 putexcel M30=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure_cat c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_THC] || hosp_THC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Cat_05Nov2025.xlsx", sheet(Tailor Hypow) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure_cat, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[2.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
putexcel A30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[3.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
 putexcel D30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[4.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
 putexcel G30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[5.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
 putexcel J30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[6.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
 putexcel M30=matrix(r(table)), names /* Output results to excel */
 
 
 
 /******************************** Intermediate Lactate without Comorbidities ********************************/
/* Load in dataset */
import sas using "sample_wgts_04nov2025.sas7bdat", clear
keep if (interlact_woutcomorb == 1) /* Keep only Intermediate lactate without comorbidities cohort */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure_cat c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PI] || hosp_PI: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Cat_05Nov2025.xlsx", sheet(Prag Interwout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure_cat, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[2.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
putexcel A30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[3.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
 putexcel D30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[4.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
 putexcel G30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[5.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
 putexcel J30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[6.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
 putexcel M30=matrix(r(table)), names /* Output results to excel */
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure_cat c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SI] || hosp_SI: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Cat_05Nov2025.xlsx", sheet(Sep1 Interwout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure_cat, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[2.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
putexcel A30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[3.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
 putexcel D30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[4.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
 putexcel G30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[5.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
 putexcel J30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[6.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
 putexcel M30=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure_cat c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_TI] || hosp_TI: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Cat_05Nov2025.xlsx", sheet(Tailor Interwout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure_cat, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[2.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
putexcel A30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[3.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
 putexcel D30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[4.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
 putexcel G30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[5.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
 putexcel J30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[6.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
 putexcel M30=matrix(r(table)), names /* Output results to excel */
 
 
 
 /******************************** Intermediate Lactate with Comorbidities ********************************/
/* Load in dataset */
import sas using "sample_wgts_04nov2025.sas7bdat", clear
keep if (interlact_wcomorb == 1) /* Keep only Intermediate lactate with comorbidities cohort */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure_cat c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PIC] || hosp_PIC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen2_05Nov2025.xlsx", sheet(Prag Interw) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure_cat, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[2.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
putexcel A30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[3.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
 putexcel D30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[4.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
 putexcel G30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[5.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
 putexcel J30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[6.Pragmaticfluidmeasure_cat] - _b[1.Pragmaticfluidmeasure_cat]
 putexcel M30=matrix(r(table)), names /* Output results to excel */
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure_cat c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SIC] || hosp_SIC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen2_05Nov2025.xlsx", sheet(Sep1 Interw) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure_cat, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[2.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
putexcel A30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[3.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
 putexcel D30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[4.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
 putexcel G30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[5.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
 putexcel J30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[6.SEP1fluidmeasure_cat] - _b[1.SEP1fluidmeasure_cat]
 putexcel M30=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure_cat c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_TIC] || hosp_TIC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen2_05Nov2025.xlsx", sheet(Tailor Interw) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure_cat, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[2.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
putexcel A30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[3.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
 putexcel D30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[4.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
 putexcel G30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[5.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
 putexcel J30=matrix(r(table)), names /* Output results to excel */
 
 nlcom _b[6.Tailoredfluidmeasure_cat] - _b[1.Tailoredfluidmeasure_cat]
 putexcel M30=matrix(r(table)), names /* Output results to excel */
 
 
 
/**********************************************************************************************************/
/***************************************** Sensitivity Analysis 1 *****************************************/
/**************************** Sensitivity analysis Population 5: History of CHF ***************************/
/**************************** Sensitivity analysis Population 6: History of CKD ***************************/
/**********************************************************************************************************/

log using "Regression Output_Sen_06Nov2025"

/******************************** Hypoperfused without Comorbidities ********************************/
/* Load in dataset */
import sas using "sample_wgts_sen_06nov2025.sas7bdat", clear
keep if (hypo_CHF == 1) /* Keep only hypoperfused with histoary of CHF cohort */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PHCHF] || hosp_PHCHF: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Sen_06Nov2025.xlsx", sheet(Prag HCHF) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Pragmaticfluidmeasure] - _b[0.Pragmaticfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SHCHF] || hosp_SHCHF: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Sen_06Nov2025.xlsx", sheet(Sep1 HCHF) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.SEP1fluidmeasure] - _b[0.SEP1fluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_THCHF] || hosp_THCHF: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Sen_06Nov2025.xlsx", sheet(Tailor Hypowout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Tailoredfluidmeasure] - _b[0.Tailoredfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 
 /******************************** Intermediate Lactate with Histoary of CHF ********************************/
/* Load in dataset */
import sas using "sample_wgts_sen_06nov2025.sas7bdat", clear
keep if (interlact_CHF == 1) /* Keep only Intermediate Lactate with Histoary of CHF */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PICHF] || hosp_PICHF: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Sen_06Nov2025.xlsx", sheet(Prag ICHF) modify
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Pragmaticfluidmeasure] - _b[0.Pragmaticfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SICHF] || hosp_SICHF: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Sen_06Nov2025.xlsx", sheet(Sep1 ICHF) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.SEP1fluidmeasure] - _b[0.SEP1fluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_TICHF] || hosp_TICHF: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Sen_06Nov2025.xlsx", sheet(Tailor ICHF) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Tailoredfluidmeasure] - _b[0.Tailoredfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 
 /******************************** Hypoperfused with History of CKD ********************************/
/* Load in dataset */
import sas using "sample_wgts_sen_06nov2025.sas7bdat", clear
keep if (hypo_CKD  == 1) /* Keep only hypoperfused with history of CKD */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure c.spl_age? male postacutecare priorhosp LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PHCKD] || hosp_PHCKD: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Sen_06Nov2025.xlsx", sheet(Prag HCKD) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Pragmaticfluidmeasure] - _b[0.Pragmaticfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure c.spl_age? male postacutecare priorhosp LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SHCKD] || hosp_SHCKD: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Sen_06Nov2025.xlsx", sheet(Sep1 HCKD) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.SEP1fluidmeasure] - _b[0.SEP1fluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure c.spl_age? male postacutecare priorhosp LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_THCKD] || hosp_THCKD: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Sen_06Nov2025.xlsx", sheet(Tailor HCKD) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Tailoredfluidmeasure] - _b[0.Tailoredfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 
 /******************************** Intermediate Lactate with History of CKD ********************************/
/* Load in dataset */
import sas using "sample_wgts_sen_06nov2025.sas7bdat", clear
keep if (interlact_CKD  == 1) /* Keep only Intermediate Lactate with History of CKD */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure c.spl_age? male postacutecare priorhosp LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PICKD] || hosp_PICKD: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Sen_06Nov2025.xlsx", sheet(Prag ICKD) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Pragmaticfluidmeasure] - _b[0.Pragmaticfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure c.spl_age? male postacutecare priorhosp LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SICKD] || hosp_SICKD: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Sen_06Nov2025.xlsx", sheet(Sep1 ICKD) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.SEP1fluidmeasure] - _b[0.SEP1fluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure c.spl_age? male postacutecare priorhosp LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_TICKD] || hosp_TICKD: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Sen_06Nov2025.xlsx", sheet(Tailor ICKD) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Tailoredfluidmeasure] - _b[0.Tailoredfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 
 
 
/**********************************************************************************************************/
/***************************************** Sensitivity Analysis 2 *****************************************/	
/********************************* Dropping patients with missing weights *********************************/
/**********************************************************************************************************/

log using "Regression Output_Sen2_05Nov2025"

/******************************** Hypoperfused without Comorbidities ********************************/
/* Load in dataset */
import sas using "sample_wgts_sen2_05nov2025.sas7bdat", clear
keep if (hypo_woutcomorb == 1) /* Keep only hypoperfused without comorbidities cohort */
keep if (impute_weight == 0) /* Drop patients who had missing values for their weights */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PH] || hosp_PH: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen2_05Nov2025.xlsx", sheet(Prag Hypowout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Pragmaticfluidmeasure] - _b[0.Pragmaticfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SH] || hosp_SH: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen2_05Nov2025.xlsx", sheet(Sep1 Hypowout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.SEP1fluidmeasure] - _b[0.SEP1fluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_TH] || hosp_TH: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen2_05Nov2025.xlsx", sheet(Tailor Hypowout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Tailoredfluidmeasure] - _b[0.Tailoredfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 
 /******************************** Hypoperfused with Comorbidities ********************************/
/* Load in dataset */
import sas using "sample_wgts_sen2_05nov2025.sas7bdat", clear
keep if (hypo_wcomorb == 1) /* Keep only hypoperfused with comorbidities cohort */
keep if (impute_weight == 0) /* Drop patients who had missing values for their weights */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PHC] || hosp_PHC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen2_05Nov2025.xlsx", sheet(Prag Hypow) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Pragmaticfluidmeasure] - _b[0.Pragmaticfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SHC] || hosp_SHC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen2_05Nov2025.xlsx", sheet(Sep1 Hypow) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.SEP1fluidmeasure] - _b[0.SEP1fluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_THC] || hosp_THC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen2_05Nov2025.xlsx", sheet(Tailor Hypow) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Tailoredfluidmeasure] - _b[0.Tailoredfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 
 /******************************** Intermediate Lactate without Comorbidities ********************************/
/* Load in dataset */
import sas using "sample_wgts_sen2_05nov2025.sas7bdat", clear
keep if (interlact_woutcomorb == 1) /* Keep only Intermediate lactate without comorbidities cohort */
keep if (impute_weight == 0) /* Drop patients who had missing values for their weights */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PI] || hosp_PI: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen2_05Nov2025.xlsx", sheet(Prag Interwout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Pragmaticfluidmeasure] - _b[0.Pragmaticfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SI] || hosp_SI: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen2_05Nov2025.xlsx", sheet(Sep1 Interwout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.SEP1fluidmeasure] - _b[0.SEP1fluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_TI] || hosp_TI: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen2_05Nov2025.xlsx", sheet(Tailor Interwout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Tailoredfluidmeasure] - _b[0.Tailoredfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 
 /******************************** Intermediate Lactate with Comorbidities ********************************/
/* Load in dataset */
import sas using "sample_wgts_sen2_05nov2025.sas7bdat", clear
keep if (interlact_wcomorb == 1) /* Keep only Intermediate lactate with comorbidities cohort */
keep if (impute_weight == 0) /* Drop patients who had missing values for their weights */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PIC] || hosp_PIC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen2_05Nov2025.xlsx", sheet(Prag Interw) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Pragmaticfluidmeasure] - _b[0.Pragmaticfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SIC] || hosp_SIC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen2_05Nov2025.xlsx", sheet(Sep1 Interw) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.SEP1fluidmeasure] - _b[0.SEP1fluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_TIC] || hosp_TIC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen2_05Nov2025.xlsx", sheet(Tailor Interw) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Tailoredfluidmeasure] - _b[0.Tailoredfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 
/**********************************************************************************************************/
/***************************************** Sensitivity Analysis 3 *****************************************/	
/************************************* Dropping death within 6 hours **************************************/
/**********************************************************************************************************/

log using "Regression Output_Sen3_05Nov2025"

/******************************** Hypoperfused without Comorbidities ********************************/
/* Load in dataset */
import sas using "sample_wgts_sen3_05nov2025.sas7bdat", clear
keep if (hypo_woutcomorb == 1) /* Keep only hypoperfused without comorbidities cohort */
keep if (deathin6 == 0) /* Drop patients who had died within 6 hours of hospitalization */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PH] || hosp_PH: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen3_05Nov2025.xlsx", sheet(Prag Hypowout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Pragmaticfluidmeasure] - _b[0.Pragmaticfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SH] || hosp_SH: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen3_05Nov2025.xlsx", sheet(Sep1 Hypowout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.SEP1fluidmeasure] - _b[0.SEP1fluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_TH] || hosp_TH: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen3_05Nov2025.xlsx", sheet(Tailor Hypowout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Tailoredfluidmeasure] - _b[0.Tailoredfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 
 /******************************** Hypoperfused with Comorbidities ********************************/
/* Load in dataset */
import sas using "sample_wgts_sen3_05nov2025.sas7bdat", clear
keep if (hypo_wcomorb == 1) /* Keep only hypoperfused with comorbidities cohort */
keep if (deathin6 == 0) /* Drop patients who had died within 6 hours of hospitalization */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PHC] || hosp_PHC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen3_05Nov2025.xlsx", sheet(Prag Hypow) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Pragmaticfluidmeasure] - _b[0.Pragmaticfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SHC] || hosp_SHC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen3_05Nov2025.xlsx", sheet(Sep1 Hypow) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.SEP1fluidmeasure] - _b[0.SEP1fluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_THC] || hosp_THC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen3_05Nov2025.xlsx", sheet(Tailor Hypow) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Tailoredfluidmeasure] - _b[0.Tailoredfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 
 /******************************** Intermediate Lactate without Comorbidities ********************************/
/* Load in dataset */
import sas using "sample_wgts_sen3_05nov2025.sas7bdat", clear
keep if (interlact_woutcomorb == 1) /* Keep only Intermediate lactate without comorbidities cohort */
keep if (deathin6 == 0) /* Drop patients who had died within 6 hours of hospitalization */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PI] || hosp_PI: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen3_05Nov2025.xlsx", sheet(Prag Interwout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Pragmaticfluidmeasure] - _b[0.Pragmaticfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SI] || hosp_SI: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen3_05Nov2025.xlsx", sheet(Sep1 Interwout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.SEP1fluidmeasure] - _b[0.SEP1fluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_TI] || hosp_TI: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen3_05Nov2025.xlsx", sheet(Tailor Interwout) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Tailoredfluidmeasure] - _b[0.Tailoredfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 
 /******************************** Intermediate Lactate with Comorbidities ********************************/
/* Load in dataset */
import sas using "sample_wgts_sen3_05nov2025.sas7bdat", clear
keep if (interlact_wcomorb == 1) /* Keep only Intermediate lactate with comorbidities cohort */
keep if (deathin6 == 0) /* Drop patients who had died within 6 hours of hospitalization */

/* Create splines for cohort for models */
	mkspline spl_creatinine 5 = creatinine_high, pctile displayknots /* Creatinine Spline - 5 nodes */
	mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots /* Lactate Spline - 5 nodes */
	mkspline spl_platelet 5 = platelets_low, pctile displayknots /* Platelets Spline - 5 nodes */
	mkspline spl_ratiomin 4 = ratio_min, pctile displayknots /* PaO2/FIO2 Spline - 4 nodes */
	mkspline spl_age 4 = age, pctile displayknots /* Age Spline - 4 nodes */
	mkspline spl_BMI 5 = BMI_calculated, pctile displayknots /* BMI Spline - 5 nodes */
	mkspline spl_WBCday3 5 = WBC_high, pctile displayknots /* White Blood Cell Count Spline - 5 nodes */
	
	
	
/* Pragmatic Approach */
 melogit mortality_30day ib0.Pragmaticfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PIC] || hosp_PIC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen3_05Nov2025.xlsx", sheet(Prag Interw) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Pragmaticfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Pragmaticfluidmeasure] - _b[0.Pragmaticfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
 /* Sep-1 Approach */
 melogit mortality_30day ib0.SEP1fluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_SIC] || hosp_SIC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen3_05Nov2025.xlsx", sheet(Sep1 Interw) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins SEP1fluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.SEP1fluidmeasure] - _b[0.SEP1fluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */
 
 
  /* Tailored Approach */
 melogit mortality_30day ib0.Tailoredfluidmeasure c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_TIC] || hosp_TIC: , or

 /* Print Output to Excel File */
 putexcel set "Regression_Output_Primary_Sen3_05Nov2025.xlsx", sheet(Tailor Interw) modify
 putexcel A1=matrix(r(table)), names /* Output Model OR Table */
 
/* Calculate Marginal Probabilites (Risks) */
 margins Tailoredfluidmeasure, post 
 putexcel A20=matrix(r(table)), names /* Output results to excel */
 
 /* Calculate Risk Differences */
 nlcom _b[1.Tailoredfluidmeasure] - _b[0.Tailoredfluidmeasure]

 putexcel G20=matrix(r(table)), names /* Output results to excel */