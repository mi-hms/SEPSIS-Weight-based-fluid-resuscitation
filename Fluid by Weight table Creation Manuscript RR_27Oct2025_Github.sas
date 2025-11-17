*************************************************************************
Project Name: Hallie - Fluid by Weight
Written by: Emily Walzl
Date: November 6th, 2025
 
Goal: examine the impact of these different approaches on (1) measure pass rate, and (2) association of measure pass with outcome. 
    Methods:
    1. Pragmatic Approach - 30ml/kg actual body weight, with weight capped at BMI = 30
    2. SEP-1 Approach - 30ml/kg actual body weight for BMI up to 30.0
                        30ml/kg ideal body weight for BMI >30.0
    3. Tailored Approach -  ABW < IBW                -> ABW
                            ABW > IBW AND BMI ≤ 30.0 -> IBW
                            BMI > 30                 -> AdjBW
            Adjusted body weight (AdjBW) = 0.4 (ABW-IBW) + IBW

Variable Codebook:

Order of code:
- Creating/Cleaning Variables for Predictors and Outcomes 
- Creating macros for IPTW
- Create cohort datasets
- Run code for IPTW/SMD tables and figures for primary Analyses
    - Run code for IPTW/SMD tables and figures for Sensitivity Analyses 1 (History of CHF or History of CKD)
    - Run code for IPTW/SMD tables and figures for Sensitivity Analyses 2 (Dropping patients with missing weights )
    - Run code for IPTW/SMD tables and figures for Sensitivity Analyses 3 (Dropping death within 6 hours )
- Create tables for paper (basic summary statistics)
- Run regression analyses in STATA

***************************************************************************/;

/* save log file to review */
/* Sarah - you will either want to comment out or change the file */
proc printto log="[Log File Folder]" new;
run;

libname out "[Compiled Dataset Folder]"; 
libname sepsis "[Compiled Dataset Folder]"; 


/****************************************************************************************************************************/
/*********************************************** Variable Creation for tables ***********************************************/
/****************************************************************************************************************************/
data sample1;
    set sepsis.sample_allvars_29OCT2025;

    /* Format time varaibles to be the same format for getting differences between dates */
    FORMAT deathtime vasoadmin hospenc sixhourcutoff firstlactate secondlactate DATETIME19.;


    /* Only want to consider cases who were measured on these variables - started measuring at the end of 21 */
    if discharge_date > mdy(12,25,21); 

    /*********************** Baseline Patient level Characteristics ***********************/
        /* Age - Median (IQR)*/
        if age >= 18; 

        /* Sex - N (%) */
        if gender="Male" then male=1;
        else male=0; 

        /* Standardizing heights and weights - height in cm and weight in kg */
        if HeightUnit_496257 = 'Inches' then do;
            height = (HeightNum_496257*2.54);
        end;
        else if HeightUnit_496257 = 'Centimeters' then do;
            height = HeightNum_496257;
        end;

        if WeightUnit_496257 = 'Pounds' then do;
            weight = WeightNum_496257*0.45359237;
        end;
        else if WeightUnit_496257 = 'Kilograms' then do;
            weight = WeightNum_496257;
        end;

        /* Patients who have missing heights/weights - impute CDC averages */
            /* Male - 90.7kg and 175.26cm*/
            impute_height = 0;
            impute_weight = 0;
            if gender = 'Male' and (height = . or height < 121.92) then do;
                height =  175.26;
                impute_height = 1; *patient missing height;
            end;
            if gender = 'Male' and weight = . then do;
                weight = 90.7;
                impute_weight = 1; *patient missing weight;
            end;

            /* Female - 77.5kg and 161.29cm*/
            if gender ~= 'Male' and (height = . or height < 121.92) then do;
                height = 161.29;
                impute_height = 1; *patient missing height;
            end;
            if gender ~= 'Male' and weight = . then do;
                weight = 77.5;
                impute_weight = 1; *patient missing weight;
            end;

        /* Create variable for height in meters - used in tailored approach */
		height_meters = height/100;

		imputed_HW = max(impute_height, impute_weight); *mark if patients were missing height OR weight missing;

        /* BMI (kg/m^2) */
        BMI_calculated = (weight)/(height_meters**2);

        /* Creating specific variables for each bmi grouping - underweight, normal, overweight, obese */
		if 0<= BMI_calculated < 18.5 then BMI_underweight = 1; else BMI_underweight = 0;
        if 18.5 <= bmi_calculated and bmi_calculated <= 30 then BMI_normaltooverweight = 1; else BMI_normaltooverweight = 0;
		if BMI_Calculated > 30 then BMI_Obese =1 ; else BMI_Obese = 0;
		if BMI_calculated > 40  then BMI_sevObese = 1; else BMI_sevObese = 0;

        /* Admitted from LTAC/SNF/SAR/AR - N (%)*/
        if PlaceResidence_496257 in ("Long Term Acute Care Hospital (LTACH)", "Skilled Nursing Facility", "Sub-acute Rehabilitation Facility","Inpatient Rehab") then postacutecare = 1;
        else postacutecare = 0;

        /* Hospitalized in prior 90 days - N (%)*/
        if priorhosp_496257="Yes" then priorhosp=1;
	    else priorhosp=0;

        /* Comorbidities - N (%): 
        - Kidney Disease (moderate or severe) 
        - liver disease 
        - Cogestive heart failure 
        - Malignancy (Solid tumors w/ and w/out metastasis, Leukemia, and Lymphoma) */
        if ComorbidCond20_496257='Y' then KidneyDisease=1; else KidneyDisease=0; * Kidney Disease (moderate/severe);
        if ComorbidCond19_496257='Y' then LiverDisease=1; else LiverDisease=0; * Liver disease (moderate/severe);
        if ComorbidCond6_496257='Y' then CHF=1;	else 	CHF=0; * Congestive Heart Failure;
        if ComorbidCond16_496257='Y' or ComorbidCond14_496257='Y' or ComorbidCond15_496257='Y' or ComorbidCond17_496257='Y' then Malignancy=1; else Malignancy=0; * Malignancy;

        /* Predicted Mortality - Variables: mortality_predicted mortality_predicted_LCL mortality_predicted_UCL (calculated in nightly run) */

    /* Illness severity on presentation */

        /* Lactate (mmol/L - max lactate within 6 hours of hospital arrival) - Median (IQR) */
            /* Use mmol/L (if provided in mg/dL, then must convert to mmol/L)
                Use lactate values from “Early Management – Labs” Form
                Use highest lactate value measured within 6 hours of encounter start time.
                If none available, then impute normal value (1.0) 
                Use time to lacate DRAW, not result time

                Note on units: mEq/L = mmol/L
                            mg/dL = mmol/L*18.0182
                            mmol/L = mg/dL/18.0182
                            "Value in mg/dL (mmol/L to mg/dL) = value in mmol/L x 18.0182"
            ************************/
            /* Create hospital encounter varaible with specific date/time of arrival */
             hospenc = input(VVALUE(hosp_enc_date) 
                            || ':' || STRIP(HospEncTime_HH_496257) 
                            || ':' || STRIP(HospEncTime_MM_496257) 
                            || ':00', anydtdtm.);

            /* Mark lactate levels as missing if 999 or 9999 input by abstractors */
            IF FirstLacateLevel_319671 IN (999, 9999) THEN first_lactate = .;
            IF SecondLactateLevel_319671 IN (999, 9999) THEN second_lactate = .;

            invalid_date = input("01-01-1900:00:00:00", anydtdtm.); *missing date/time - invalid date input;
            FORMAT invalid_date datetime19.; *formatting to match other date/time variables;

            /* Lactate draw times are invalid then mark as missing so values are not calculated for these patients */
            IF FirstLactateDate_319671 eq invalid_date OR FirstLactateTime_HH_319671 = "99" 
            OR FirstLactateTime_MM_319671 = "99" THEN DO;
                FirstLactateDate_319671 = .;
                FirstLactateTime_HH_319671 = "";
                FirstLactateTime_MM_319671 = "";
            END;

            IF SecondLactateDate_319671 eq invalid_date OR SecondLactateTime_HH_319671 = "99" 
            OR SecondLactateTime_MM_319671 = "99" THEN DO;
                SecondLactateDate_319671 = .;
                SecondLactateTime_HH_319671 = "";
                SecondLactateTime_MM_319671 = "";
            END;

            /* Creating consistent date/time variables for non-missing/valid lactate draw times to match with hospital encounter variable */
            IF FirstLactateDate_319671 NOT = . AND FirstLactateTime_HH_319671 NOT = "" AND FirstLactateTime_MM_319671 NOT = "" THEN
            firstlactate = input(VVALUE(FirstLactateDate_319671) 
                        || ":" || STRIP(FirstLactateTime_HH_319671) 
                        || ":" || STRIP(FirstLactateTime_MM_319671) 
                        || ":00", anydtdtm.);

            IF SecondLactateDate_319671 NOT = . AND SecondLactateTime_HH_319671 NOT = "" AND SecondLactateTime_MM_319671 NOT = "" THEN
            secondlactate = input(VVALUE(SecondLactateDate_319671)
                        || ":" || STRIP(SecondLactateTime_HH_319671) 
                        || ":" || STRIP(SecondLactateTime_MM_319671) 
                        || ":00", anydtdtm.);

            /* Calculate the number of hours to first and second lactate draws */
            first_lactate_hrs = (firstlactate - hospenc)/3600;
            second_lactate_hrs = (secondlactate - hospenc)/3600;


            /* convert mg/dL to mmol/L */
            IF FirstLactateUnit_319671 = "mEq/L" THEN first_lactate = FirstLacateLevel_319671;
            ELSE IF FirstLactateUnit_319671 = "mg/dL" THEN first_lactate = FirstLacateLevel_319671 * 0.0555;
            ELSE IF FirstLactateUnit_319671 = "mmol/L" THEN first_lactate = FirstLacateLevel_319671;
            ELSE IF FirstLactateUnit_319671 = "Not available" THEN first_lactate = .;
            ELSE first_lactate = .;

            IF SecondLactateUnit_319671 = "mEq/L" THEN second_lactate = SecondLactateLevel_319671;
            ELSE IF SecondLactateUnit_319671 = "mg/dL" THEN second_lactate = SecondLactateLevel_319671 * 0.0555;
            ELSE IF SecondLactateUnit_319671 = "mmol/L" THEN second_lactate = SecondLactateLevel_319671;
            ELSE IF SecondLactateUnit_319671 = "Not available" THEN second_lactate = .;
            ELSE second_lactate = .;


            /* Identify lactate level if the draw was within 6 hours
                note: some "missing" entries are entered as 99, 999 or 9999 
            */
            if 0<FirstLacateLevel_319671<99 and first_lactate_hrs<=6 then first_lactate_draw = first_lactate;
            else first_lactate_draw = -1; /* set all missing entries to -1 for the maximum function */

            if 0<SecondLactateLevel_319671<99 and second_lactate_hrs<=6 then second_lactate_draw = second_lactate;
            else second_lactate_draw = -1; /* set all missing entries to -1 for the maximum function */

            /* take the maximum of the two first lactates */
            lactatemax_draw = max(first_lactate_draw,second_lactate_draw);

            /* impute missing values = 1 */
            if lactatemax_draw = -1 then lactatemax_draw = 1;

            /* Elevated lactate (≥4mmol/L) during first 3 hours */
            if (first_lactate >= 4 and 0 <= first_lactate_hrs <= 3) or 
                (second_lactate >= 4 and 0 <= second_lactate_hrs <= 3) then elevateLact4_3 = 1; else elevateLact4_3 = 0;

            /* Elevated lactate (≥2mmol/L) during first 3 hours */
            if (4 > first_lactate >= 2 and 0 <= first_lactate_hrs <= 3) or 
                (4 > second_lactate >= 2 and 0 <= second_lactate_hrs <= 3) then  elevateLact2_3 = 1; else elevateLact2_3 = 0;

        /* Creatinine (mg/dL - Max creatinine on day 1, if patient arrived after 6pm and had no day 1 labs, day 2 labs were used) - Median (IQR) */
            /* Day 1 value */
            if creat_day1 ne . then do;
                creatinine_high = creat_day1;
                creatinine_high_unit = creatunit_day1;
            end;
            /* If missing day 1 and admission time is after 6 pm, then use day 2 value */
            if creat_day1 = . and HospEncTime_HH_496257 in(18,19,20,21,22,23,24) then do;
                creatinine_high = creat_day2;
                creatinine_high_unit = creatunit_day2;
            end;

            /* convert units */
            if creatinine_high_unit = "mol/L" then creatinine_high = creatinine_high*88.42;

            /* Impute missing values */
            if creatinine_high = . then creatinine_high = 1;

        /* SBP < 90 during hours 1, 2, or 3 */
            /***************************
            Minimum blood pressure in first 3 hours
            ***************************/
            /* systolic BP */
            if FirstSysBP_319671 eq "Abnormal (Less than 90 mmHg)" or
                SecondSysBP_319671 eq "Abnormal (Less than 90 mmHg)" or
                ThirdSysBP_319671 eq "Abornaml (Less than 90 mmHg)" or
            0 < FirstSysBPNum_319671 < 90 OR 0 < SecondSysBPNum_319671 < 90 OR 0 < ThirdSysBPNum_319671 < 90 then SBP90 = 1; 
            else if FirstSysBP_319671 in ('Abnormal (90mmHg to 100 mmHg)', 'Normal (101 mmHg or greater)') or
                SecondSysBP_319671 in ('Abnormal (90mmHg to 100 mmHg)', 'Normal (101 mmHg or greater)') or
                ThirdSysBP_319671 eq in ('Abnormal (90mmHg to 100 mmHg)', 'Normal (101 mmHg or greater)') or
            FirstSysBPNum_319671 >= 90 OR SecondSysBPNum_319671>= 90 OR ThirdSysBPNum_319671 >= 90 then SBP90 = 2;
            else SBP90 = 0;

        /* PaO2:FiO2 ratioc  (with imputation used for mortality model - Minimum PaO2:FiO2 ratio within 3 hours of hospital arrival ) - Median (IQR)  */
        
            /**************************** HOUR 1 ****************************/
            /* Step 1a: Standardize oxygen support to FIO2 (21% when no supplemental oxygen) for hours 1, 2, 3 
                (Amount of oxygen administered (in liters) – variable name FirstPOSuppLiters_319671) */
            if firstPOSuppLiters_319671 = "<1L" then nfio1=0.21;
            else if firstPOSuppLiters_319671 = "1L" then nfio1=0.24;
            else if firstPOSuppLiters_319671 = "2L" then nfio1=0.28;
            else if firstPOSuppLiters_319671 = "3L" then nfio1=0.32;
            else if firstPOSuppLiters_319671 = "4L" then nfio1=0.36;
            else if firstPOSuppLiters_319671 = "5L" then nfio1=0.40;
            else if firstPOSuppLiters_319671 = "6L" then nfio1=0.44;
            else if firstPOSuppLiters_319671 = "7L" then nfio1=0.48;
            else if firstPOSuppLiters_319671 = "8L" then nfio1=0.52;
            else if firstPOSuppLiters_319671 = "9L" then nfio1=0.55;
            else if firstPOSuppLiters_319671 = "10L" then nfio1=0.60;
            else if firstPOSuppLiters_319671 = "11L" then nfio1=0.65;
            else if firstPOSuppLiters_319671 = "12L" then nfio1=0.70;
            else if firstPOSuppLiters_319671 = "13L" then nfio1=0.80;
            else if firstPOSuppLiters_319671 = "14L" then nfio1=0.90;
            else if firstPOSuppLiters_319671 = "15L" then nfio1=1.00;
            else if firstPOSuppLiters_319671 = ">15L" then nfio1=1.00;
            * else if firstPOSuppLiters_319671 = "Not available" then nfio1=0.2;

            /* Step 1b: Standardize oxygen support to FIO2 (21% when no supplemental oxygen) for hours 1, 2, 3 
                (Amount of oxygen administered (in percent) – variable name FirstPOSuppPercent_319671) */
            if firstPOSuppPercent_319671="21 (Room Air)" then nfio1=0.21;
            else if firstPOSuppPercent_319671="22-30" then nfio1=0.26;
            else if firstPOSuppPercent_319671="31-40" then nfio1=0.355;
            else if firstPOSuppPercent_319671="41-50" then nfio1=0.455;
            else if firstPOSuppPercent_319671="51-60" then nfio1=0.555;
            else if firstPOSuppPercent_319671="61-70" then nfio1=0.655;
            else if firstPOSuppPercent_319671="71-80" then nfio1=0.755;
            else if firstPOSuppPercent_319671="81-90" then nfio1=0.855;
            else if firstPOSuppPercent_319671="91-100" then nfio1=0.955;
            * else if firstPOSuppPercent_319671="Not available" then nfio1=0.21;

            /* Impute = 21% for all patients not on supplemental oxygen */
            if nfio1 =. and FirstPOSupp_319671 = "No" then nfio1=0.21;

            /* Step 2: Convert Pulse Oximetry to PaO2 for hours 1, 2, 3
                (based on oxygen-hemoglobin dissociation curve) 
                (variable name FirstPO_319671) */
            if FirstPO_319671 = "70 or less" then npao1=40;
            else if  FirstPO_319671 = "71-80" then npao1=44;
            else if FirstPO_319671 = "81-90" then npao1=55;
            else if  FirstPO_319671 = "91-95" then npao1=65;
            else if FirstPO_319671 = "96-100" then npao1=100;
            * else npao1=100; 

            /* Step 4: Calculate PaO2/FIO2  (ie, “P/F ratio”) for hour 1 */
            P_F_ratio1=npao1/nfio1;

            /* Step 3: EXCLUDE Pulse Ox measurements WHERE: Pulse Ox=96%+ AND FIO2>0.21 */
            if npao1 = 100 and nfio1 > .21 then P_F_ratio1 = 9999;
            if npao1 = . or nfio1 = . then P_F_ratio1 = 99999;

            /**************************** HOUR 2 ****************************/

            /* Step 1a: Standardize oxygen support to FIO2 (21% when no supplemental oxygen) for hours 1, 2, 3 
                (Amount of oxygen administered (in liters) – variable name secondPOSuppLiters_319671) */
            if secondPOSuppLiters_319671 = "<1L" then nfio2=0.21;
            else if secondPOSuppLiters_319671 = "1L" then nfio2=0.24;
            else if secondPOSuppLiters_319671 = "2L" then nfio2=0.28;
            else if secondPOSuppLiters_319671 = "3L" then nfio2=0.32;
            else if secondPOSuppLiters_319671 = "4L" then nfio2=0.36;
            else if secondPOSuppLiters_319671 = "5L" then nfio2=0.40;
            else if secondPOSuppLiters_319671 = "6L" then nfio2=0.44;
            else if secondPOSuppLiters_319671 = "7L" then nfio2=0.48;
            else if secondPOSuppLiters_319671 = "8L" then nfio2=0.52;
            else if secondPOSuppLiters_319671 = "9L" then nfio2=0.55;
            else if secondPOSuppLiters_319671 = "10L" then nfio2=0.60;
            else if secondPOSuppLiters_319671 = "11L" then nfio2=0.65;
            else if secondPOSuppLiters_319671 = "12L" then nfio2=0.70;
            else if secondPOSuppLiters_319671 = "13L" then nfio2=0.80;
            else if secondPOSuppLiters_319671 = "14L" then nfio2=0.90;
            else if secondPOSuppLiters_319671 = "15L" then nfio2=1.00;
            else if secondPOSuppLiters_319671 = ">15L" then nfio2=1.00;
            * else if secondPOSuppLiters_319671 = "Not available" then nfio2=0.2;

            /* Step 1b: Standardize oxygen support to FIO2 (21% when no supplemental oxygen) for hours 1, 2, 3 
                (Amount of oxygen administered (in percent) – variable name secondPOSuppPercent_319671) */
            if secondPOSuppPercent_319671="21 (Room Air)" then nfio2=0.21;
            else if secondPOSuppPercent_319671="22-30" then nfio2=0.26;
            else if secondPOSuppPercent_319671="31-40" then nfio2=0.355;
            else if secondPOSuppPercent_319671="41-50" then nfio2=0.455;
            else if secondPOSuppPercent_319671="51-60" then nfio2=0.555;
            else if secondPOSuppPercent_319671="61-70" then nfio2=0.655;
            else if secondPOSuppPercent_319671="71-80" then nfio2=0.755;
            else if secondPOSuppPercent_319671="81-90" then nfio2=0.855;
            else if secondPOSuppPercent_319671="91-100" then nfio2=0.955;
            * else if secondPOSuppPercent_319671="Not available" then nfio2=0.21;
            * if nfio2 =. then nfio2=0.21;

            /* Impute = 21% for all patients not on supplemental oxygen */
            if nfio2 =. and SecondPOSupp_319671 = "No" then nfio1=0.21;

            /* Step 2: Convert Pulse Oximetry to PaO2 for hours 1, 2, 3
                (based on oxygen-hemoglobin dissociation curve) 
                (variable name secondPO_319671) */
            if secondPO_319671 = "70 or less" then npao2=40;
            else if  secondPO_319671 = "71-80" then npao2=44;
            else if secondPO_319671 = "81-90" then npao2=55;
            else if  secondPO_319671 = "91-95" then npao2=65;
            else if secondPO_319671 = "96-100" then npao2=100;
            * else npao2=100; 


            /* Step 4: Calculate PaO2/FIO2  (ie, “P/F ratio”) for hour 1 */
            P_F_ratio2=npao2/nfio2;

            /* Step 3: EXCLUDE Pulse Ox measurements WHERE: Pulse Ox=96%+ AND FIO2>0.21
                Note - since we need to do a minimum function and we also want to know the
                number that will be imputed under this step, I will set = 9999 for now */
            if npao2 = 100 and nfio2 > .21 then P_F_ratio2 = 9999;
            if npao2 = . or nfio2 = . then P_F_ratio2 = 99999;

            /**************************** HOUR 3 ****************************/

            /* Step 1a: Standardize oxygen support to FIO2 (21% when no supplemental oxygen) for hours 1, 2, 3 
                (Amount of oxygen administered (in liters) – variable name thirdPOSuppLiters_319671) */
            if thirdPOSuppLiters_319671 = "<1L" then nfio3=0.21;
            else if thirdPOSuppLiters_319671 = "1L" then nfio3=0.24;
            else if thirdPOSuppLiters_319671 = "2L" then nfio3=0.28;
            else if thirdPOSuppLiters_319671 = "3L" then nfio3=0.32;
            else if thirdPOSuppLiters_319671 = "4L" then nfio3=0.36;
            else if thirdPOSuppLiters_319671 = "5L" then nfio3=0.40;
            else if thirdPOSuppLiters_319671 = "6L" then nfio3=0.44;
            else if thirdPOSuppLiters_319671 = "7L" then nfio3=0.48;
            else if thirdPOSuppLiters_319671 = "8L" then nfio3=0.52;
            else if thirdPOSuppLiters_319671 = "9L" then nfio3=0.55;
            else if thirdPOSuppLiters_319671 = "10L" then nfio3=0.60;
            else if thirdPOSuppLiters_319671 = "11L" then nfio3=0.65;
            else if thirdPOSuppLiters_319671 = "12L" then nfio3=0.70;
            else if thirdPOSuppLiters_319671 = "13L" then nfio3=0.80;
            else if thirdPOSuppLiters_319671 = "14L" then nfio3=0.90;
            else if thirdPOSuppLiters_319671 = "15L" then nfio3=1.00;
            else if thirdPOSuppLiters_319671 = ">15L" then nfio3=1.00;
            * else if thirdPOSuppLiters_319671 = "Not available" then nfio3=0.2;

            /* Step 1b: Standardize oxygen support to FIO2 (21% when no supplemental oxygen) for hours 1, 2, 3 
                (Amount of oxygen administered (in percent) – variable name thirdPOSuppPercent_319671) */
            if thirdPOSuppPercent_319671="21 (Room Air)" then nfio3=0.21;
            else if thirdPOSuppPercent_319671="22-30" then nfio3=0.26;
            else if thirdPOSuppPercent_319671="31-40" then nfio3=0.355;
            else if thirdPOSuppPercent_319671="41-50" then nfio3=0.455;
            else if thirdPOSuppPercent_319671="51-60" then nfio3=0.555;
            else if thirdPOSuppPercent_319671="61-70" then nfio3=0.655;
            else if thirdPOSuppPercent_319671="71-80" then nfio3=0.755;
            else if thirdPOSuppPercent_319671="81-90" then nfio3=0.855;
            else if thirdPOSuppPercent_319671="91-100" then nfio3=0.955;
            * else if thirdPOSuppPercent_319671="Not available" then nfio3=0.21;
            * if nfio3 =. then nfio3=0.21;

            /* Impute = 21% for all patients not on supplemental oxygen */
            if nfio3 =. and ThirdPOSupp_319671 = "No" then nfio1=0.21;

            /* Step 2: Convert Pulse Oximetry to PaO2 for hours 1, 2, 3
                (based on oxygen-hemoglobin dissociation curve) 
                (variable name thirdPO_319671) */
            if thirdPO_319671 = "70 or less" then npao3=40;
            else if  thirdPO_319671 = "71-80" then npao3=44;
            else if thirdPO_319671 = "81-90" then npao3=55;
            else if  thirdPO_319671 = "91-95" then npao3=65;
            else if thirdPO_319671 = "96-100" then npao3=100;
            * else npao3=100; 


            /* Step 4: Calculate PaO2/FIO2  (ie, “P/F ratio”) for hour 1 */
            P_F_ratio3=npao3/nfio3; 

            /* Step 3: EXCLUDE Pulse Ox measurements WHERE: Pulse Ox=96%+ AND FIO2>0.21
                Note - since we need to do a minimum function and we also want to know the
                number that will be imputed under this step, I will set = 9999 for now */
            if npao3 = 100 and nfio3 > .21 then P_F_ratio3 = 9999;
            if npao3 = . or nfio3 = . then P_F_ratio3 = 99999;

            /*********************** FINAL STEPS ****************************/

            /* Step 5: Select the lowest eligible P/F ratio from hour 1, 2, 3  */
            ratio_min=min(P_F_ratio3,P_F_ratio2,P_F_ratio1);

            /* Step 6: For patients with no P/F ratio from hour 1, 2, 3 
            (because Pulse Ox=96+ AND FIO2=0.21) for hour 1, hour 2, AND hour 3: 
            impute  P/F ratio =300 */
            ratio_imputed = 0;
            if ratio_min = 9999 then do;
                ratio_min = 300;
                ratio_imputed = 1;
            end;
            if ratio_min = 99999 then do;
                ratio_min = 476;
                ratio_imputed = 2;
            end;



        /* Mechanical Ventilation within 6 hours - N (%)*/
            if mechvent_319671 IN ('', 'No') THEN mechvent=0; else mechvent=1; * if mechanical ventilation was not marked as being used then mech vent is 'no';

            /*************************** 
            Mechanical ventilation in first 6 hours 
            ***************************/

            /* Putting mechanical ventilation date/time in same format as hospital encounter */
            mechdate = input(VVALUE(datemechvent_319671) 
                            || ':' || STRIP(timemechvent_HH_319671) 
                            || ':' || STRIP(timemechvent_MM_319671) 
                            || ':00', anydtdtm.);

            timeto_mech = (mechdate-hospenc)/3600; * time (in hours) to use of mechanical ventilation;

            /* Mark if patient received mechanical ventilation within 6 hours of hospital encounter */
            if mechvent=1 and timeto_mech <=6 then mechvent_6hr=1;
            else mechvent_6hr=0;

        /* Altered Mental Status - N (%)*/
        if PrimDiag_688217 ne "Sepsis" and MentalSymptoms_496257 = "Yes" and MentalStatusDoc_496257 = "Yes" then alter_mental_status = 1;
        else if PrimDiag_688217 = "Sepsis" and AlteredMentalStatus_688217 = "Y" then alter_mental_status = 1;
        else alter_mental_status = 0;

        /* Vasopressors Initiated within 6 Hours (excluding midodrine) */
        /* ie Treated with an IV vasopressor within 3 hours of arrival (angiotensin II, dopamine, epinephrine, norepinephrine, phenylephrine, vasopressin) */
        /* Vasopressor within 3 hours */
			invalid_date = input('01-01-1900:00:00:00', anydtdtm.); *missing date/time - invalid date input;
            FORMAT invalid_date datetime19.; *formatting to match other date/time variables;
            
            /* Vasopressor administration times are invalid then mark as missing so values are not calculated for these patients */
            IF VasoAdminDate_319671 eq invalid_date OR VasoAdminTime_HH_319671 = '99' 
                OR VasoAdminTime_MM_319671 = '99' THEN DO;
                    VasoAdminDate_319671 = .;
                    VasoAdminTime_HH_319671 = .;
                    VasoAdminTime_MM_319671 = .;
                END;

            IF SecondVasoAdminDate_319671 eq invalid_date OR SecondVasoAdminTime_HH_319671 = '99' 
                OR SecondVasoAdminTime_MM_319671 = '99' THEN DO;
                    SecondVasoAdminDate_319671 = .;
                    SecondVasoAdminTime_HH_319671 = .;
                    SecondVasoAdminTime_MM_319671 = .;
                END;

                /* Creating consistent date/time variables for non-missing/valid Vasopressor administration times to match with hospital encounter variable */
                vasoadmin1 = input(VVALUE(VasoAdminDate_319671) 
                            || ':' || STRIP(VasoAdminTime_HH_319671) 
                            || ':' || STRIP(VasoAdminTime_MM_319671) 
                            || ':00', anydtdtm.);
            

                vasoadmin2 = input(VVALUE(SecondVasoAdminDate_319671) 
                            || ':' || STRIP(SecondVasoAdminTime_HH_319671) 
                            || ':' || STRIP(SecondVasoAdminTime_MM_319671) 
                            || ':00', anydtdtm.);
                
            /** ===== time for first and second vasopressors (in hours) ======== **/
                vasotime1 = (vasoadmin1 - hospenc)/3600;
                vasotime2 = (vasoadmin2 - hospenc)/3600;

            /* Vasopressors administered within 3 hours (excluding midorine) */
            if (0 < vasotime1 <= 3 AND VasoAdminName_319671 ne 'Midodrine')or (0 < vasotime2 <= 3 AND SecondVasoAdminName_319671 ne 'Midodrine')
            then vaso_3hrs=1; else vaso_3hrs=0;

            /* Vasopressors administered within 6 hours (excluding midorine) */
            if (0 < vasotime1 <= 6 AND VasoAdminName_319671 ne 'Midodrine')or (0 < vasotime2 <= 6 AND SecondVasoAdminName_319671 ne 'Midodrine')
            then vaso_6hrs=1; else vaso_6hrs=0;

    /* 30 day mortality - Variable: mortality_30day */
    /* mark invalid death dates as missing */
    IF DeathDate_471893 = mdy(1, 1, 1900) THEN DeathDate_471893=.;
                IF DateofDeath_471893 = mdy(1, 1, 1900) THEN DateofDeath_471893=.;
                IF DeathDate_547147 = mdy(1, 1, 1900) THEN DeathDate_547147=.;
                IF DeathDate_471893 ne . THEN numdeath_471893 = DATEPART(DeathDate_471893);
                IF DateofDeath_471893 ne . THEN numdeath_471893 = DATEPART(DateofDeath_471893);
                IF DeathDate_547147 ne . THEN numdeath_547147 = DATEPART(DeathDate_547147);

    /* Reformat death date variable to be in the same format as hospital encounter date to get difference */
    if DeathDate_471893 ~= . then newdeathdate = divide (DeathDate_471893, 86400) ; 
            if DateofDeath_471893 ~= . then newdeathdate = divide (DateofDeath_471893, 86400) ; 
            if DeathDate_547147 ~= . then newdeathdate = divide (DeathDate_547147, 86400) ; 
    format newdeathdate DATE9.;

    /* if the 30 day mortality was not loaded in previously then check to see if it falls in 30 day time frame for 30 day mortality */
	if mortality_30day = . then do;
		mortality_30day = 0;
        if EndStatus_547147='Death' and 0<=INT(DATDIF(hosp_enc_date, numdeath_547147, 'ACTUAL'))<=30 then mortality_30day = 1;
        if 0<=INT(DATDIF(hosp_enc_date, numdeath_471893, 'ACTUAL'))<=30 then mortality_30day = 1;
	end;

    /* Time to death - sensitivity excluding those who died within 6 hours */
    deathin6 = 0; * set all to 0;
    /* reformat death date to match with date/time hospital encounter varaible */
    if DeathDate_547147 ~= . and DeathTime_HH_547147 ~= . and DeathTime_MM_547147 ~= . then do;
        deathtime = input(VVALUE(DeathDate_547147) 
                            || ":" || STRIP(DeathTime_HH_547147) 
                            || ":" || STRIP(DeathTime_MM_547147) 
                            || ":00", anydtdtm.);

        timetodeath = (deathtime - hospenc)/3600; * put time to death in hours;
        /* Mark patient if they died within 6 hours of hospital encounter */
        if . < timetodeath <= 6 then do;
            deathin6 = 1;
            groupa = 1;
            end;
        end;

    /* Also marked as early mortality (died within 6 hours ) if:
        no time stamp available for death date: use DeathDate_547147 and 
            a.	If encounter start before 18:00 (ie, 6pm), exclude if date of death is on encounter day 1
            b.	If encounter start after 18:00 (ie, 6pm), exclude if date of death is on encounter days 1 or 2 */
    if newdeathdate ~= . and (DeathTime_HH_547147 = . or DeathTime_MM_547147 = .) then do;
        if . < HospEncTime_HH_496257 and HospEncTime_HH_496257 not in (18,19,20,21,22,23,24) and newdeathdate = hosp_enc_date then do;
            deathin6 = 1;
            group2a = 1;
        end;
        else if HospEncTime_HH_496257 in (18,19,20,21,22,23,24) and newdeathdate - hosp_enc_date in (0,1) then do;
            deathin6 = 1;
            group2b = 1;
        end;
    end;

    /*********************** Creating Cohort Variables ***********************/
        /* MAP < 65 */
        if 0 < FirstMAP_319671 < 65 OR 0 < SecondMAP_319671 < 65 OR 0 < ThirdMAP_319671 < 65 then MAP65 = 1; 
        else if FirstMAP_319671 >= 65 OR SecondMAP_319671 >= 65 OR ThirdMAP_319671 >= 65 then MAP65 = 2;
        else MAP65 = 0;

        /* Ejectionfraction <= 39% */
        if EjecFrac_496257 = "Yes" and EjecFracPerc_496257 in ("35 - 39", "Less than 35") then VentEjeFrac = 1; else VentEjeFrac = 0;

        /* moderate/severe critical aortic stenosis */
        if AortSten_496257 = "Yes" and AortStenSev_496257 in ("Severe", "Critical") then aortstenosis=1; else aortstenosis=0;

        /* ESRD or Stage 5 CKD */
        if ESRDDiag_688217 = 'Y' or ComorbidCKDStage_496257 = 'Stage 5' then renal_disease = 1; else renal_disease = 0;

        /*********** Cohorts ***********/
        /* Email from Hallie (file: Email Confirming Cohort Selection_23Apr2025) says to match with dashboard cohorts for elements hypoperfused should match element 8 and the total should equal element 9 */
            /* Hypoperfused - MAP<65, vasopressor, 0 < SBP < 90 or lactate>=4 */
            if map65 = 1 or vaso_3hrs = 1 or elevateLact4_3 = 1 or SBP90 = 1 then hypoperfused = 1; else hypoperfused = 0;

            /* Intermediate lactate - MAP≥65, no vasopressors, SBP >= 90, and 4 > lactate >=2 */
            if map65 = 2 and vaso_3hrs = 0 and elevateLact2_3 = 1 and SBP90 = 2 and hypoperfused ~= 1 then intermediate_lactate = 1; else intermediate_lactate = 0;

            /* Without specified comorbidities - No ESRD, reduced LVEF,  severe/critical aortic stenosis */
            if renal_disease = 0 and VentEjeFrac = 0 and aortstenosis = 0 then nospecificcomorbid = 1; else nospecificcomorbid = 0;

            /* With specified comorbidity - ESRD, reduced LVEF, or severe/critical aortic stenosis */
            if renal_disease = 1 or VentEjeFrac = 1 or aortstenosis = 1 then specificcomorbid = 1; else specificcomorbid = 0;

            /* creating variables for each combo */
                /* Primary Cohorts */
                if hypoperfused = 1 and specificcomorbid = 0 then hypo_woutcomorb = 1; else hypo_woutcomorb = 0; * Hypoperfused without specific comorbidities; 
                if hypoperfused = 1 and specificcomorbid = 1 then hypo_wcomorb = 1; else hypo_wcomorb = 0; * Hypoperfused with specific comorbidities;
                if intermediate_lactate = 1 and specificcomorbid = 0 then interlact_woutcomorb = 1; else interlact_woutcomorb = 0; * Intermediate lactate without specific comorbidities;
                if intermediate_lactate = 1 and specificcomorbid = 1 then interlact_wcomorb = 1; else interlact_wcomorb = 0; *Intermediate lactate with specific comorbidities;
                if hypoperfused = 1 or intermediate_lactate = 1 then total_cohort = 1; else total_cohort = 0;/* Variable for total cohort */

                /* Sensitivity Cohorts */
                if hypoperfused = 1 and CHF = 1 then hypo_CHF = 1; else hypo_CHF = 0; * CHF with hypoperfusion; 
                if hypoperfused = 1 and KidneyDisease = 1 then hypo_CKD = 1; else hypo_CKD = 0; * CHF with intermediate lactate;
                if intermediate_lactate = 1 and CHF = 1 then interlact_CHF = 1; else interlact_CHF = 0; * CKD with hypofusion;
                if intermediate_lactate = 1 and KidneyDisease = 1 then interlact_CKD = 1; else interlact_CKD = 0; * CKD with intermediate lactate;




        /* RR updates - adding SOFA variables to models 15Oct2025 (see Annals IM Comments document) */
            /* Charlson */
                if ComorbidCond21_496257 in ('Y', 'Yes') then CMI1=1; else CMI1=0; /* Prior myocardial infarction */
                if ComorbidCond6_496257 in ('Y', 'Yes') then CMI2=1; else CMI2=0; /* Congestive heart failure */   /******************/
                if ComorbidCond24_496257 in ('Y', 'Yes') then CMI3=1; else CMI3=0; /* Peripheral Vascular disease */
                if ComorbidCond4_496257 in ('Y', 'Yes') then CMI4=1; else CMI4=0; /* Cerebrovascular disease */
                if ComorbidCond8_496257 in ('Y', 'Yes') then CMI5=1; else CMI5=0; /* Dementia */   /******************/
                if ComorbidCond7_496257 in ('Y', 'Yes') then CMI6=1; else CMI6=0; /* Chronic pulmonary disease */   /******************/
                if ComorbidCond25_496257 in ('Y', 'Yes') then CMI7=1; else CMI7=0; /* Rheumatologic disease */
                if ComorbidCond23_496257 in ('Y', 'Yes') then CMI8=1; else CMI8=0; /* Peptic Ulcer disease */
                if ComorbidCond18_496257 in ('Y', 'Yes') then CMI9=1; else CMI9=0; /* Mild liver disease */   /******************/
                if ComorbidCond10_496257 in ('Y', 'Yes') then CMI10=1; else CMI10=0; /* Diabetes uncomplicated */
                if ComorbidCond12_496257 in ('Y', 'Yes') then CMI11=2; else CMI11=0; /* Cerebrovascular (hemiplegia) event */
                if ComorbidCond20_496257 in ('Y', 'Yes') then CMI12=2; else CMI12=0; /* Moderate-to-severe renal disease */   /******************/
                if ComorbidCond9_496257 in ('Y', 'Yes') then CMI13=2; else CMI13=0; /* Diabetes with chronic complications */
                if ComorbidCond16_496257 in ('Y', 'Yes') then CMI14=2; else CMI14=0; /* Cancer without metastases */   /******************/
                if ComorbidCond14_496257 in ('Y', 'Yes') then CMI15=2; else CMI15=0; /* Leukemia */   /******************/
                if ComorbidCond15_496257 in ('Y', 'Yes') then CMI16=2; else CMI16=0; /* Lymphoma */   /******************/
                if ComorbidCond19_496257 in ('Y', 'Yes') then CMI17=3; else CMI17=0; /* Moderate or severe liver disease */   /******************/
                if ComorbidCond17_496257 in ('Y', 'Yes') then CMI18=6; else CMI18=0; /* Metastatic solid tumor */   /******************/
                if ComorbidCond1_496257 in ('Y', 'Yes') then CMI19=6; else CMI19=0; /* AIDS */
                Charlson = sum(of CMI1-CMI19);

            /* Highest temp (first 3 hours) */
                max_temp = 999;
                array temp FirstTemp_319671 SecondTemp_319671 ThirdTemp_319671;
                do over temp;
                    if temp = "Abnormal (Less than 35 C)" and (max_temp<=0 or max_temp = 999) then max_temp = 0;
                    if temp = "Abnormal (35 C to 36 C)" and (max_temp<=1 or max_temp = 999) then max_temp = 1;
                    if temp = "Normal (36.1 C to 37.8 C)" and (max_temp<=2 or max_temp = 999) then max_temp = 2; /* Normal Temp */
                    if temp = "Abnormal (37.9 C to 38 C)" and (max_temp<=3 or max_temp = 999) then max_temp = 3;
                    if temp = "Abnormal (38.1 C to 38.3 C)" and (max_temp<=4 or max_temp = 999) then max_temp = 4;
                    if temp = "Abnormal (38.4 C to 39.9 C)" and (max_temp<=5 or max_temp = 999) then max_temp = 5;
                    if temp = "Abnormal (40 C or greater)" and (max_temp<=6 or max_temp = 999) then max_temp = 6;
                end;

                array tempp FirstTempNum_319671 SecondTempNum_319671 ThirdTempNum_319671;
                do over tempp;
                    if .<tempp<35 and (max_temp<=0 or max_temp = 999) then max_temp = 0;
                    if 35<=tempp<=36 and (max_temp<=1 or max_temp = 999) then max_temp = 1;
                    if 36<tempp<=37.8 and (max_temp<=2 or max_temp = 999) then max_temp = 2; /* Normal Temp */
                    if 37.8<tempp<=38 and (max_temp<=3 or max_temp = 999) then max_temp = 3;
                    if 38<tempp<=38.3 and (max_temp<=4 or max_temp = 999) then max_temp = 4;
                    if 38.3<tempp<=39.9 and (max_temp<=5 or max_temp = 999) then max_temp = 5;
                    if 39.9<tempp<999 and (max_temp<=6 or max_temp = 999) then max_temp = 6;
                end;

                if max_temp = 999 then max_temp = 2; /* Impute normal temp if misiing */
            
            /* Lowest SBP (first 3 hours) */
                if FirstSysBP_319671 ="Abnormal (Less than 90 mmHg)" or 0<=FirstSysBPNum_319671<90 then sysBP1 = 1;
                else if FirstSysBP_319671 ="Abnormal (90mmHg to 100 mmHg)" or 90<=FirstSysBPNum_319671<=100 then sysBP1 = 2;
                else if FirstSysBP_319671 ="Normal (101 mmHg or greater)" or 100<FirstSysBPNum_319671 then sysBP1 = 3;
                else sysBP1 = 3;

                if SecondSysBP_319671 ="Abnormal (Less than 90 mmHg)" or 0<=SecondSysBPNum_319671<90 then sysBP2 = 1;
                else if SecondSysBP_319671 ="Abnormal (90mmHg to 100 mmHg)" or 90<=SecondSysBPNum_319671<=100 then sysBP2 = 2;
                else if SecondSysBP_319671 ="Normal (101 mmHg or greater)" or 100<SecondSysBPNum_319671 then sysBP2 = 3;
                else sysBP2 = 3;

                if ThirdSysBP_319671 ="Abnormal (Less than 90 mmHg)" or 0<=ThirdSysBPNum_319671<90 then sysBP3 = 1;
                else if ThirdSysBP_319671 ="Abnormal (90mmHg to 100 mmHg)" or 90<=ThirdSysBPNum_319671<=100 then sysBP3 = 2;
                else if ThirdSysBP_319671 ="Normal (101 mmHg or greater)" or 100<ThirdSysBPNum_319671 then sysBP3 = 3;
                else sysBP3 = 3;

                /* Get lowest of the first 3 systolic blood pressure values */
                min_sysBP = min(sysBP1,sysBP2,sysBP3);
            
            /* Highest RR (first 3 hours) */
                if FirstRR_319671 in("Not available","Normal (less than 20)",'') then FirstRR_N=1;
                else if FirstRR_319671 in("Abnormal (20)","Abnormal (21)") then FirstRR_N=2;
                else if FirstRR_319671 in("Abnormal (22-24)" ) then FirstRR_N=3;
                else if FirstRR_319671 in("Abnormal (25-30)") then FirstRR_N=4;
                else if FirstRR_319671 in("Abnormal (greater than 30)") then FirstRR_N=5; 
                else FirstRR_N=1; 

                if secondRR_319671 in("Not available","Normal (less than 20)",'') then secondRR_N=1;
                else if secondRR_319671 in("Abnormal (20)","Abnormal (21)") then secondRR_N=2;
                else if secondRR_319671 in("Abnormal (22-24)" ) then secondRR_N=3;
                else if secondRR_319671 in("Abnormal (25-30)") then secondRR_N=4;
                else if secondRR_319671 in("Abnormal (greater than 30)") then secondRR_N=5; 
                else secondRR_N=1;

                if thirdRR_319671 in("Not available","Normal (less than 20)",'') then thirdRR_N=1;
                else if thirdRR_319671 in("Abnormal (20)","Abnormal (21)") then thirdRR_N=2;
                else if thirdRR_319671 in("Abnormal (22-24)" ) then thirdRR_N=3;
                else if thirdRR_319671 in("Abnormal (25-30)") then thirdRR_N=4;
                else if thirdRR_319671 in("Abnormal (greater than 30)") then thirdRR_N=5; 
                else thirdRR_N=1; 

                /* Get highest of the first 3 respiratory rate values */
                max_RR = max(FirstRR_N,secondRR_N,thirdRR_N);
            
            /* Highest HR (first 3 hours) */
                if FirstHR_319671 in("Less than 60 BPM") then mHR_first = 1;
                else if FirstHR_319671 in("60 - 89 BPM", "Normal (less than 90 BPM)") then mHR_first=2;
                else if FirstHR_319671 in("90 - 100 BPM" , "Abnormal (91 - 100 BPM)" , "Abnormal (90 BPM)") then mHR_first=3;
                else if FirstHR_319671 in("101 - 124 BPM" , "Abnormal (101 - 124 BPM)") then mHR_first=4;
                else if FirstHR_319671 in("Abnormal (greater than 124 BPM)", "Greater than 124 BPM") then mHR_first=5;
                else mHR_first=0;

                if secondHR_319671 in("Less than 60 BPM") then mHR_second = 1;
                else if secondHR_319671 in("60 - 89 BPM", "Normal (less than 90 BPM)") then mHR_second=2;
                else if secondHR_319671 in("90 - 100 BPM" , "Abnormal (91 - 100 BPM)" , "Abnormal (90 BPM)") then mHR_second=3;
                else if secondHR_319671 in("101 - 124 BPM" , "Abnormal (101 - 124 BPM)") then mHR_second=4;
                else if secondHR_319671 in("Abnormal (greater than 124 BPM)", "Greater than 124 BPM") then mHR_second=5;
                else mHR_second=0;

                if thirdHR_319671 in("Less than 60 BPM") then mHR_third = 1;
                else if thirdHR_319671 in("60 - 89 BPM", "Normal (less than 90 BPM)") then mHR_third=2;
                else if thirdHR_319671 in("90 - 100 BPM" , "Abnormal (91 - 100 BPM)" , "Abnormal (90 BPM)") then mHR_third=3;
                else if thirdHR_319671 in("101 - 124 BPM" , "Abnormal (101 - 124 BPM)") then mHR_third=4;
                else if thirdHR_319671 in("Abnormal (greater than 124 BPM)", "Greater than 124 BPM") then mHR_third=5;
                else mHR_third=0;

                /** ============= using the maximum values =================== **/
                max_HR=max(mHR_third, mHR_second, mHR_first);
                if max_HR = 0 then max_HR = 2; /* if missing variable, inputted as 60 - 89 BPM (normal)*/
            
            /* Highest WBC (first measured … same methods as HMS-Sepsis mortality model) */
                /* Day 1 value */
                if WBC_day1 ne . then WBC_high = WBC_day1;
                /* If missing day 1 and admission time is after 6 pm, then use day 2 value */
                if WBC_day1 = . and HospEncTime_HH_496257 in(18,19,20,21,22,23,24) then	WBC_high = WBC_day2;    
            
            /* Highest bilirubin (first measured … same methods as HMS-Sepsis mortality model) */
                /* Day 1 value */
                if bili_day1 ne . then do;
                    bilirubin_high = bili_day1;
                    bilirubin_high_unit = biliunit_day1;
                end;
                /* If missing day 1 and admission time is after 6 pm, then use day 2 value */
                if bili_day1 = . and HospEncTime_HH_496257 in(18,19,20,21,22,23,24) then do;
                    bilirubin_high = bili_day2;
                    bilirubin_high_unit = biliunit_day2;
                end;
                /* convert units */
                if bilirubin_high_unit = "mol/L" then bilirubin_high = bilirubin_high*17;
                /* Flag extreme values */
                if bilirubin_high<0.1 or bilirubin_high>40 then do;
                    bilirubin_high = .;
                    bilirubin_high_flag = 1;
                end;
                /* Impute missing values */
                if bilirubin_high = . then do;
                    bilirubin_imputed = 1;
                    bilirubin_high = 1;
                end;

                /* Functional Form */
                bilirubin_sq = bilirubin_high*bilirubin_high;
            
            /* Lowest platelet (first measured … same methods as HMS-Sepsis mortality model) */
                /* Day 1 value */
                if platlow_day1 ne . then do;
                    platelets_low = platlow_day1;
                end;
                /* If missing day 1 and admission time is after 6 pm, then use day 2 value */
                if platlow_day1 = . and HospEncTime_HH_496257 in(18,19,20,21,22,23,24) then do;
                    platelets_low = platlow_day2;
                end;

                /* Impute missing values */
                if platelets_low in(.,9999) then do;
                    platelets_imputed = 1;
                    platelets_low = 300;
                end;
       
run;

proc freq data = sample1;
    tables elevateLact2_3 elevateLact4_3;
run;

Data sample;
    set sample1;
    /*********************** Creating Method Variables ***********************/
    
    /* Ideal Body Weight */
        IF gender = 'Male' AND height ne . THEN ibw = 50 + (0.91 * (height - 152.4));
        ELSE IF gender = 'Female' AND height ne . THEN ibw = 45.5 + (0.91 * (height - 152.4));
        /* gender = "unknown" or blank */
        ELSE ibw = 50 + (0.91 * (height - 152.4));


    /* Fluids Given */
    IF prehospfluid ne . THEN six_hr_fluid = (prehospfluid + Fluid6_30mlkg);
    ELSE six_hr_fluid = Fluid6_30mlkg;

    /* Pragmatic Approach (previously HMS Approach) - 30ml/kg actual body weight, with weight capped at BMI = 30 */
        if 0 < BMI_calculated <= 30 then Pragmatic_Weight = weight;
            else if BMI_calculated > 30 then Pragmatic_Weight = 30 * (height_meters * height_meters); /* bmi > 30 */
        

        IF Pragmatic_Weight ne 0 THEN Pragmaticsix = six_hr_fluid / Pragmatic_Weight; 
        
        /* Base 30ml/kg measure */
        IF Pragmaticsix >= 30 THEN Pragmaticfluidmeasure = 1;
            else Pragmaticfluidmeasure = 0;

            /* Groupings in 10ml/kg increments */
                IF  Pragmaticsix < 11 THEN Pragmaticfluidmeasure_cat = 1;/* 0-10ml/kg */
                else IF 11 <= Pragmaticsix < 21 THEN Pragmaticfluidmeasure_cat = 2;/* 11-20ml/kg */
                else IF 21 <= Pragmaticsix < 31 THEN Pragmaticfluidmeasure_cat = 3;/* 21-30ml/kg */
                else IF 31 <= Pragmaticsix < 41 THEN Pragmaticfluidmeasure_cat = 4;/* 31-40ml/kg */
                else IF 41 <= Pragmaticsix < 51 THEN Pragmaticfluidmeasure_cat = 5;/* 41-50ml/kg */
                else IF Pragmaticsix >= 51 THEN Pragmaticfluidmeasure_cat = 6;/* 51+ ml/kg */
                else Pragmaticfluidmeasure_cat = .;

    /* SEP-1 Approach */
        /* 30ml/kg actual body weight for BMI up to 30.0 */
        /* 30ml/kg ideal body weight for BMI >30.0 */
        if 0 < BMI_calculated <= 30 then SEP1_weight = weight;
            else if BMI_calculated > 30 then SEP1_Weight = IBW;

        IF SEP1_weight ne 0 THEN SEP1six = six_hr_fluid / SEP1_weight; 

        /* Base 30ml/kg measure */
        IF SEP1six >= 30 THEN SEP1fluidmeasure = 1;
            else SEP1fluidmeasure = 0;

        /* Groupings in 10ml/kg increments */
                IF SEP1six < 11 THEN SEP1fluidmeasure_cat = 1;/* 0-10ml/kg */
                else IF 11 <= SEP1six < 21 THEN SEP1fluidmeasure_cat = 2;/* 11-20ml/kg */
                else IF 21 <= SEP1six < 31 THEN SEP1fluidmeasure_cat = 3;/* 21-30ml/kg */
                else IF 31 <= SEP1six < 41 THEN SEP1fluidmeasure_cat = 4;/* 31-40ml/kg */
                else IF 41 <= SEP1six < 51 THEN SEP1fluidmeasure_cat = 5;/* 41-50ml/kg */
                else IF SEP1six >= 51 THEN SEP1fluidmeasure_cat = 6;/* 51+ ml/kg */
                else SEP1fluidmeasure_cat = .;

    /* Tailored Approach (Previously Pharmacy Approach) */
        /* ABW < IBW -> ABW */
        /* ABW > IBW AND BMI ≤ 30.0 -> IBW */
        /* BMI > 30 -> AdjBW  - Adjusted body weight (AdjBW) = 0.4 (ABW-IBW) + IBW */
        if Weight <= IBW then Tailored_weight = Weight;
            else if Weight > IBW and 0 < BMI_calculated <= 30 then Tailored_weight = IBW;
            else if BMI_calculated > 30 then Tailored_weight = 0.4*(weight-IBW)+IBW;

        IF Tailored_weight ne 0 THEN Tailoredsix = six_hr_fluid / Tailored_weight; 
        
        /* Base 30ml/kg measure */
        IF Tailoredsix >= 30 THEN Tailoredfluidmeasure = 1;
            else Tailoredfluidmeasure = 0;

        /* Groupings in 10ml/kg increments */
                IF Tailoredsix < 11 THEN Tailoredfluidmeasure_cat = 1;/* 0-10ml/kg */
                else IF 11 <= Tailoredsix < 21 THEN Tailoredfluidmeasure_cat = 2;/* 11-20ml/kg */
                else IF 21 <= Tailoredsix < 31 THEN Tailoredfluidmeasure_cat = 3;/* 21-30ml/kg */
                else IF 31 <= Tailoredsix < 41 THEN Tailoredfluidmeasure_cat = 4;/* 31-40ml/kg */
                else IF 41 <= Tailoredsix < 51 THEN Tailoredfluidmeasure_cat = 5;/* 41-50ml/kg */
                else IF Tailoredsix >= 51 THEN Tailoredfluidmeasure_cat = 6;/* 51+ ml/kg */
                else Tailoredfluidmeasure_cat = .;


    /* Patients whos BMI were over 100 and unable to verify values from abstractors */
    if nid in (123763, 147353, 151256) then delete;

run;

/* Double Checking cohort counts */
proc freq data = sample;
	table  specificcomorbid*hypoperfused specificcomorbid*intermediate_lactate specificcomorbid;
run;

proc freq data = sample;
    tables Pragmaticfluidmeasure_cat SEP1fluidmeasure_cat Tailoredfluidmeasure_cat;
run;


/********************************************************************************************************************************************************************/
/***********************************************************************Table Creation*******************************************************************************/
/********************************************************************************************************************************************************************/


/***************************************************************************************************************************************************************/
/*********************************************************************** Table 1 *******************************************************************************/
/***************************************************************************************************************************************************************/
ods excel file="Table 1 Counts &sysdate9..xlsx" style=HTMLblue;
ods excel options(sheet_name='Table 1 Pass Raw' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc freq data = sample;
    tables specificcomorbid*hypoperfused specificcomorbid*intermediate_lactate;
run;
ods excel close;
/***************************************************************************************************************************************************************/


/***************************************************************************************************************************************************************/
/*********************************************************************** Table 2 *******************************************************************************/
/***************************************************************************************************************************************************************/

/**************************** Variable Counts ****************************/
ods excel file="Table 2 Counts &sysdate9..xlsx" style=HTMLblue;
ods excel options(sheet_name='Table 2 Raw' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc tabulate data = sample out = Table_2 missing;
	class male BMI_underweight BMI_normaltooverweight BMI_Obese BMI_sevObese postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mechvent_6hr alter_mental_status vaso_6hrs VentEjeFrac aortstenosis renal_disease total_cohort hypo_woutcomorb hypo_wcomorb interlact_woutcomorb interlact_wcomorb;
	table /*Row Variables */
            male = 'Male sex, N(%)'
            BMI_underweight = 'BMI <18.5, N(%)'
            BMI_normaltooverweight = 'BMI 18.5-30, N(%)'
            BMI_Obese = 'BMI >30, N(%)'
            BMI_sevObese = 'BMI >40, N(%)'
            postacutecare = 'Admission from post-acute care, N(%)'
            priorhosp = 'Hospitalization in prior 90-days, N(%)'
            KidneyDisease = 'Kidney disease (moderate/severe), N(%)'
            LiverDisease = 'Liver disease (moderate/severe), N(%)'
            CHF = 'Congestive heart failure, N(%)'
            Malignancy = 'Malignancy, N(%)'
            mechvent_6hr = 'Mecahnical ventilation in 6 hours, N(%)'
            alter_mental_status = 'Altered Mental status on day 1, N(%)'
            vaso_6hrs = 'Vasopressors in 6 hours, N(%)'
            /* Specific Comorbidities */
            VentEjeFrac = 'EF <40% '
            aortstenosis = 'Severe AS '
            renal_disease = 'ESRD '

    	   
           ,
		   /* Getting the values within each rows subgroup */ 
           N*(total_cohort = 'Total'
              hypo_woutcomorb = 'Hypoperfused without specific comorbidities'
              hypo_wcomorb = 'Hypoperfused with specific comorbidities'
              interlact_woutcomorb = 'Intermediate lactate without specific comorbidities '
              interlact_wcomorb = 'Intermediate lactate with specific comorbidities');
		   title 'Table 2. Patient characteristics by patient subpopulation';
         
run;

/* Values for Continuous Variables - for each cohort */

proc means data = sample median p25 p75 NMISS;
    class total_cohort;
    var age mortality_predicted lactatemax_draw creatinine_high ratio_min charlson max_temp min_sysBP max_RR max_HR WBC_high bilirubin_high platelets_low;
run;

proc means data = sample median p25 p75 NMISS;
    class hypo_woutcomorb;
    var age mortality_predicted lactatemax_draw creatinine_high ratio_min charlson max_temp min_sysBP max_RR max_HR WBC_high bilirubin_high platelets_low;
run;

proc means data = sample median p25 p75 NMISS;
    class hypo_wcomorb;
    var age mortality_predicted lactatemax_draw creatinine_high ratio_min charlson max_temp min_sysBP max_RR max_HR WBC_high bilirubin_high platelets_low;
run;

proc means data = sample median p25 p75 NMISS;
    class interlact_woutcomorb;
    var age mortality_predicted lactatemax_draw creatinine_high ratio_min charlson max_temp min_sysBP max_RR max_HR WBC_high bilirubin_high platelets_low;
run;

proc means data = sample median p25 p75 NMISS;
    class interlact_wcomorb;
    var age mortality_predicted lactatemax_draw creatinine_high ratio_min charlson max_temp min_sysBP max_RR max_HR WBC_high bilirubin_high platelets_low;
run;
ods excel close;

/***************************************************************************************************************************************************************/

/****************************************************************************************************************************************************************/
/************************************************************************* IPTW *********************************************************************************/
/****************************************************************************************************************************************************************/



/*********************************************************************************************** MACROS MACROS MACROS ***********************************************************************************************/

/* Macro to get mean differences for unweighted variables */
    /* Non categorical varaibles */
         %macro covbal2_unw(var, approach, subgroup, df);
            proc means data = &df mean median std p25 p75;
                where &subgroup =1;
               class &approach;
               var &var;
               output out = temp mean = _mean_  std = _std_ median = _median_ p25 = _p25_ p75 = _p75_;
            run;

            data temp; 
               set temp;
               where _type_ = 1;
            run;

            proc sort data = temp;
               by &approach;
            run;
            /* calculate stddiff */   
            proc sql; 
               create table &var as select 
               a._median_ as  Pass_med, a._p25_ as Pass_p25, a._p75_ as  Pass_p75, b._median_ as noPass_med, b._p25_ as noPass_p25, b._p75_ as noPass_p75, a._mean_ as Pass_mean, b._mean_ as noPass_mean, (a._mean_ - b._mean_)/sqrt((a._std_**2 + b._std_**2)/2) as d 
               from temp(where = (&approach = 1)) as a, temp(where = (&approach = 0)) as b;
            quit; 

            data &var; 
				set &var; 
				format var $20.;
				var="&var.";  
            run;
         %mend covbal2_unw;

         /* Categorical varaibles */
         %macro covbal2_unw_cat(var, approach, subgroup, df);
            proc means data = &df mean median std p25 p75;
                where &subgroup =1;
               class &approach;
               var &var;
               output out = temp mean = p  std = _std_ median = _median_ p25 = _p25_ p75 = _p75_;
            run;

            data temp; 
               set temp;
               where _type_ = 1;
            run;

            proc sort data = temp;
               by &approach;
            run;
            /* calculate stddiff */  
             proc sql; 
               create table &var as select 
               a._median_ as  Pass_med, a._p25_ as Pass_p25, a._p75_ as  Pass_p75, b._median_ as noPass_med, b._p25_ as noPass_p25, b._p75_ as noPass_p75, a.p as Pass_mean, b.p as noPass_mean, (a.p - b.p)/sqrt((a.p*(1-a.p) + b.p*(1-b.p))/2) as d  
               from temp(where = (&approach = 1)) as a, temp(where = (&approach = 0)) as b;
            quit; 

            data &var; 
               set &var; 
			   format var $20.;
			   var="&var."; 
            run;
         %mend covbal2_unw_cat;


/* Macro to get mean differences for weighted variables */
    /* Non categorical varaibles */
    %macro covbal2(var, approach, subgroup, df_weight2);
       proc means data = &df_weight2 mean median std p25 p75;
        where &subgroup =1;
			class &approach;
			var &var;
			weight ps_weight;
			output out = temp mean = _mean_  std = _std_ median =_median_ p25=_p25_ p75=_p75_;
       run;

       data temp; 
          set temp;
          where _type_ = 1;
       run;

       proc sort data = temp;
          by &approach;
       run;
       /* calculate stddiff */   
       proc sql; 
          create table &var as select 
           a._median_ as Pass_med, a._p25_ as Pass_p25, a._p75_ as Pass_p75, b._median_ as noPass_med, b._p25_ as noPass_p25, b._p75_ as noPass_p75, a._mean_ as Pass_mean, b._mean_ as noPass_mean, (a._mean_ - b._mean_)/sqrt((a._std_**2 + b._std_**2)/2) as d 
          from temp(where = (&approach = 1)) as a, temp(where = (&approach = 0)) as b; 
       quit; 

       data &var; 
		set &var; 
		format var $20.;
		var="&var."; 
       run;
    %mend covbal2;

    /* Categorical varaibles */
    %macro covbal2_cat(var, approach, subgroup, df_weight2);
        proc means data = &df_weight2 mean median std p25 p75;
            where &subgroup =1;
           class &approach;
           var &var;
           weight ps_weight;
           output out = temp mean = p  std = _std_ median = _median_ p25 = _p25_ p75 = _p75_;
        run;

        data temp; 
           set temp;
           where _type_ = 1;
        run;

        proc sort data = temp;
           by &approach;
        run;
        /* calculate stddiff */  
         proc sql; 
           create table &var as select 
           a._median_ as  Pass_med, a._p25_ as Pass_p25, a._p75_ as  Pass_p75, b._median_ as noPass_med, b._p25_ as noPass_p25, b._p75_ as noPass_p75, a.p as Pass_mean, b.p as noPass_mean, (a.p - b.p)/sqrt((a.p*(1-a.p) + b.p*(1-b.p))/2) as d  
           from temp(where = (&approach = 1)) as a, temp(where = (&approach = 0)) as b;
        quit; 

        data &var; 
           set &var; 
           format var $20.;
           var="&var."; 
        run;
     %mend covbal2_cat;
 

/* Macro to run Macros for SMD tables and figures */
%Macro MacroPollo(Approach, Subgroup, Name, df_wgt);
	
    /* Calculate Unweighted SMD values */
    %covbal2_unw(age, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw_cat(male, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw_cat(postacutecare, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw_cat(priorhosp, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw_cat(kidneydisease, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw_cat(liverdisease, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw_cat(CHF, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw_cat(malignancy, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw(mortality_predicted, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw(BMI_calculated, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw(lactatemax_draw, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw(creatinine_high, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw(ratio_min, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw_cat(mechvent_6hr, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw_cat(vaso_6hrs, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw_cat(alter_mental_status, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw(Charlson, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw(max_temp, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw(min_sysBP, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw(max_RR, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw(max_HR, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw(WBC_high, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw(bilirubin_high, &Approach , &Subgroup, &df_wgt);
    %covbal2_unw(platelets_low, &Approach , &Subgroup, &df_wgt);

        /* Combine each variables SMD values into one table to output */
		data unweighted_balance_&name.; 
			set age male BMI_calculated postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted  lactatemax_draw creatinine_high ratio_min mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR WBC_high bilirubin_high platelets_low;
            if d = . then delete;
            run; 

        /* Clear individual unweighted SMDs to reuse variable names for weighted */
        proc datasets library=work;
            delete age male BMI_calculated postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted  lactatemax_draw creatinine_high ratio_min mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR WBC_high bilirubin_high platelets_low;
		run; 

	/* Calculate Weighted SMD values */
    %covbal2(age, &Approach , &Subgroup, &df_wgt);
    %covbal2_cat(male, &Approach , &Subgroup, &df_wgt);
    %covbal2_cat(postacutecare, &Approach , &Subgroup, &df_wgt);
    %covbal2_cat(priorhosp, &Approach , &Subgroup, &df_wgt);
    %covbal2_cat(kidneydisease, &Approach , &Subgroup, &df_wgt);
    %covbal2_cat(liverdisease, &Approach , &Subgroup, &df_wgt);
    %covbal2_cat(CHF, &Approach , &Subgroup, &df_wgt);
    %covbal2_cat(malignancy, &Approach , &Subgroup, &df_wgt);
    %covbal2(mortality_predicted, &Approach , &Subgroup, &df_wgt);
    %covbal2(BMI_calculated, &Approach , &Subgroup, &df_wgt);
    %covbal2(lactatemax_draw, &Approach , &Subgroup, &df_wgt);
    %covbal2(creatinine_high, &Approach , &Subgroup, &df_wgt);
    %covbal2(ratio_min, &Approach , &Subgroup, &df_wgt);
    %covbal2_cat(mechvent_6hr, &Approach , &Subgroup, &df_wgt);
    %covbal2_cat(vaso_6hrs, &Approach , &Subgroup, &df_wgt);
    %covbal2_cat(alter_mental_status, &Approach , &Subgroup, &df_wgt);
    %covbal2(Charlson, &Approach , &Subgroup, &df_wgt);
    %covbal2(max_temp, &Approach , &Subgroup, &df_wgt);
    %covbal2(min_sysBP, &Approach , &Subgroup, &df_wgt);
    %covbal2(max_RR, &Approach , &Subgroup, &df_wgt);
    %covbal2(max_HR, &Approach , &Subgroup, &df_wgt);
    %covbal2(WBC_high, &Approach , &Subgroup, &df_wgt);
    %covbal2(bilirubin_high, &Approach , &Subgroup, &df_wgt);
    %covbal2(platelets_low, &Approach , &Subgroup, &df_wgt);

        /* Combine individual variable weighted SMD values into one table */
		data weighted_balance_&name.; 
			set age male BMI_calculated postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted  lactatemax_draw creatinine_high ratio_min mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR WBC_high bilirubin_high platelets_low;
            if d = . then delete;		
        run; 

    /* Clear individual variable SMD datasets to clear up space/reuse dataset names for next run of macro */
    proc datasets library=work;
        delete age male BMI_calculated postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted  lactatemax_draw creatinine_high ratio_min mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR WBC_high bilirubin_high platelets_low;
	run; 

    /* Create dataset to combine Unweight SMD and Weighted SMD for SMD figures */
    proc sql;
        create table PrePost_SMD_&name as select
        a.var, a.d as pre_weightD,
        b.d as post_weightD
        from unweighted_balance_&name. a 
        left join weighted_balance_&name. b on a.var=b.var;
    quit;

    /* Create nicer variable name labels for the variables for SMD figure */
    data PrePost_SMD_&name;
        set PrePost_SMD_&name;
        format var_name $40.;

        if var = 'age' then do;
            Var_name = 'Age';
            order = 1;
        end;
            else if var = 'male' then do;
                var_name = 'Sex';
                order = 2;
            end;
            else if var = 'BMI_calculated' then do;
                var_name = 'BMI';
                order = 3;
            end;
            else if var = 'postacutecare' then do;
                var_name = 'Admission from SNF/SAR/LTAC';
                order = 4;
            end;
            else if var = 'priorhosp' then do;
                var_name = 'Hospitalization in prior 90-days';
                order = 5;
            end;
            else if var = 'kidneydisease' then do;
                var_name = 'Mod/Severe kidney disease';   
                order = 6;
            end;
            else if var = 'liverdisease' then do;
                var_name = 'Mod/Severe liver disease';
                order = 7;
            end;
            else if var = 'CHF' then do;
                var_name = 'CHF';
                order = 8;
            end;
            else if var = 'malignancy' then do;
                var_name = 'Malignancy'; 
                order = 9;
            end;
            else if var = 'mortality_predicted' then do;
                var_name = 'Predicted mortality continuous';
                order = 10;
            end;
            else if var = 'lactatemax_draw' then do;
                var_name = 'Initial lactatea';
                order = 11;
            end;
            else if var = 'creatinine_high' then do;
                var_name = 'Initial creatinine';
                order = 12;
            end;
            else if var = 'ratio_min' then do;
                var_name = 'PaO2: FiO2 ratio';
                order = 13;
            end;
            else if var = 'mechvent_6hr' then do;
                var_name = 'Mechanical ventilation in 6 hours';
                order = 14;
            end;
            else if var = 'vaso_6hrs' then do;
                var_name = 'Vasopressors in 6 hours'; 
                order = 15;
            end;
            else if var = 'alter_mental_status' then do;
                var_name = 'AMS on presentation';
                order = 16;
            end;
            else if var = 'Charlson' then do;
                var_name = 'Charlson score';
                order = 17;
            end;
            else if var = 'max_temp' then do;
                var_name = 'Highest Temp first 3 hours categorical';
                order = 18;
            end; 
            else if var = 'min_sysBP' then do;
                var_name = 'Lowest SBP first 3 hours categorical';
                order = 19;
            end;
            else if var = 'max_RR' then do;
                var_name = 'Highest RR first 3 hours categorical';
                order = 20;
            end;
            else if var = 'max_HR' then do;
                var_name = 'Highest HR first 3 hours categorical';
                order = 21;
            end;
            else if var = 'WBC_high' then do;
                var_name = 'Highest WBC'; 
                order = 22;
            end;
            else if var = 'bilirubin_high' then do;
                var_name = 'Highest bilirubind';
                order = 23;
            end;
            else if var = 'platelets_low' then do;
                var_name = 'Lowest plateletsd';
                order = 24;
            end;
    run;

    /* Order to keep consistent with SMD tables */
    proc sort data = PrePost_SMD_&name;
        by order;
    run;


%Mend MacroPollo; /* End of Macro to run macros for SMD tables and Figures */ 

/* Macro for Creating SMD figures */
%Macro SMD_PrePost_Fig(df, title);
    ods graphics / width=5in height=7in;

    title &title;
    proc sgplot data=&df noborder;
        refline -0.1 0.1 / name="reflines" legendlabel = "Thresholds" axis=x lineattrs=(pattern=dot color=black);
        refline 0 / axis=x lineattrs=(color=black);    
        scatter y=var_name x=pre_weightD / name="scatter1" legendlabel="Pre weight" markerattrs=(symbol=circlefilled color= "Medium Orange");
        scatter y=var_name x=post_weightD / name="scatter2" legendlabel="Post weight" markerattrs=(symbol=circlefilled color="Dark Blue");
        yaxistable var_name / location=Inside position=left valuejustify=left valueattrs=(size=7) nolabel labelattrs=(size=8);
        xaxis min=-0.4 max=0.4 values=(-0.4 to 0.4 by .1) label='Standardized mean difference' ;      
        yaxis  fitpolicy=none valueattrs=(size=7) reverse display=none;
        run;

%mend;

/* Macro to create datasets for specific cohorts */
/* For each cohort hospitals with fewer than 10 observations were grouped together into single hospital varaible */
%Macro Model_sample(df, Subgroup, Num);
    /* Specify Cohort Dataset */
    data &df._&num;
        set &df ;
        if &Subgroup = 1;
    run;

    /* Get the number of observation by hospital */
	proc sql;
		create table hsp_cnt as select
		hosp, count(nid) as count
		from &df._&num
		group by hosp;
	quit;

    /* Group hospitals together if they have fewer than 10 observations in the cohort dataset */
	data hsp_cnt;
		set hsp_cnt;
		if count < 10 then new_hosp = 100;
		else new_hosp = hosp;
	run;

    /* Append the adjusted hospital identifiers for the regression dataset */
	proc sql;
		create table reg_sample&num as select
		a.*,
		b.new_hosp
		from &df._&num a 
		left join hsp_cnt b on a.hosp=b.hosp;
	quit;


%mend;

/****************************************************************************************** End of MACROS MACROS MACROS  ******************************************************************************************/

/* Creating Cohort Datasets */
/* Primary Analyses */
%Model_Sample(sample, hypo_woutcomorb, 1); * Hypoperfused without comorbidities ;
%Model_Sample(sample, hypo_wcomorb, 2); * Hypoperfused with comorbidities;
%Model_Sample(sample, interlact_woutcomorb, 3); * Intermediate lactate without comorbidities;
%Model_Sample(sample, interlact_wcomorb, 4); * Intermediate lactate with comorbidities;

/* Sensitivity Analyses 1 */
%Model_Sample(sample, hypo_CHF, 5); * Hypoperfused with history of CHF;
%Model_Sample(sample, hypo_CKD, 6); * Hypoperfused with history of CKD;
%Model_Sample(sample, interlact_CHF, 7); * Intermediate lactate with history of CHF;
%Model_Sample(sample, interlact_CKD, 8); * Intermediate lactate with history of CKD;

/* Code to create splines for the subsetted datasets - doesnt seem to work if using include just copy and paste into sas editior and run right now */
*%include "Spline Macro_29Oct2025.sas";


/****************************************************************************************************************************************************************/
/************************************************************************* Primary Analyses *********************************************************************************/
/****************************************************************************************************************************************************************/
/************* Pragmatic Approach *************/
/* Model that creates the propensity scores for weights */

/* Hypoperfused without specific comorbidities */
    proc glimmix data=reg_sample1 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Pragmaticfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;


    /* Create weights from propensity scores */
    data ps_weight2_PragHypo; 
    set ps_p; 
    if Pragmaticfluidmeasure= 1 then ps_weight = 0.5503/ps_pred; else  ps_weight = 0.4497/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_PragHypo n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Pragmaticfluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(Pragmaticfluidmeasure, hypo_woutcomorb, PragHypo, ps_weight2_PragHypo);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;

/* Hypoperfused with specific comorbidities */
    proc glimmix data=reg_sample2 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Pragmaticfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_PragHypoCom; 
    set ps_p; 
    if Pragmaticfluidmeasure= 1 then ps_weight = 0.2665/ps_pred; else  ps_weight = 0.7335/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_PragHypoCom n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Pragmaticfluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(Pragmaticfluidmeasure, hypo_wcomorb, PragHypoCom, ps_weight2_PragHypoCom);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;

/* Intermediate lactate without specific comorbidities */
    proc glimmix data=reg_sample3 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Pragmaticfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_PragInter; 
    set ps_p; 
    if Pragmaticfluidmeasure= 1 then ps_weight = 0.3322/ps_pred; else  ps_weight = 0.6678/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_PragInter n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Pragmaticfluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(Pragmaticfluidmeasure, interlact_woutcomorb, PragInter, ps_weight2_PragInter);
    
    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;

/* Intermediate lactate with specific comorbidities */
    proc glimmix data=reg_sample4 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Pragmaticfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/   CL CovB DIST=BINARY LINK=LOGIT SOLUTION; 
        random int / sub=new_hosp ;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_PragInterCom; 
    set ps_p; 
    if Pragmaticfluidmeasure= 1 then ps_weight = 0.1337/ps_pred; else  ps_weight = 0.8663/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_PragInterCom n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Pragmaticfluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(Pragmaticfluidmeasure, interlact_wcomorb, PragInterCom, ps_weight2_PragInterCom);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;

/************* Sep-1 Approach *************/
/* SEP1fluidmeasure */
/* Model that creates the propensity scores for weights */

/* Hypoperfused without specific comorbidities */
    proc glimmix data=reg_sample1 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model SEP1fluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_Sep1Hypo; 
    set ps_p; 
    if SEP1fluidmeasure= 1 then ps_weight = 0.6276/ps_pred; else  ps_weight = 0.3724/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_Sep1Hypo n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class SEP1fluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(SEP1fluidmeasure, hypo_woutcomorb, Sep1Hypo, ps_weight2_Sep1Hypo);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Hypoperfused with specific comorbidities */
    proc glimmix data=reg_sample2 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model SEP1fluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_Sep1HypoCom; 
    set ps_p; 
    if SEP1fluidmeasure= 1 then ps_weight = 0.3280/ps_pred; else  ps_weight = 0.6720/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_Sep1HypoCom n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class SEP1fluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(SEP1fluidmeasure, hypo_wcomorb, Sep1HypoCom, ps_weight2_Sep1HypoCom);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Intermediate lactate without specific comorbidities */
    proc glimmix data=reg_sample3 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model SEP1fluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_Sep1Inter; 
    set ps_p; 
    if SEP1fluidmeasure= 1 then ps_weight = 0.4202/ps_pred; else  ps_weight = 0.5798/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_Sep1Inter n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class SEP1fluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(SEP1fluidmeasure, interlact_woutcomorb, Sep1Inter, ps_weight2_Sep1Inter);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    
/* Intermediate lactate with specific comorbidities */
    proc glimmix data=reg_sample4 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model SEP1fluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION; 
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_Sep1InterCom; 
    set ps_p; 
    if SEP1fluidmeasure= 1 then ps_weight = 0.1677/ps_pred; else  ps_weight = 0.8323/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_Sep1InterCom n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class SEP1fluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(SEP1fluidmeasure, interlact_wcomorb, Sep1InterCom, ps_weight2_Sep1InterCom);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/************* Tailored Approach *************/
/* Tailoredfluidmeasure */
/* Model that creates the propensity scores for weights */
/* Hypoperfused without specific comorbidities */
    proc glimmix data=reg_sample1 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Tailoredfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_TailorHypo; 
    set ps_p; 
    if Tailoredfluidmeasure= 1 then ps_weight = 0.6118/ps_pred; else  ps_weight = 0.3882/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_TailorHypo n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Tailoredfluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(Tailoredfluidmeasure, hypo_woutcomorb, TailorHypo, ps_weight2_TailorHypo);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Hypoperfused with specific comorbidities */
    proc glimmix data=reg_sample2 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Tailoredfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_TailorHypoCom; 
    set ps_p; 
    if Tailoredfluidmeasure= 1 then ps_weight = 0.3240/ps_pred; else  ps_weight = 0.6760/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_TailorHypoCom n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Tailoredfluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(Tailoredfluidmeasure, hypo_wcomorb, TailorHypoCom, ps_weight2_TailorHypoCom);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Intermediate lactate without specific comorbidities */
    proc glimmix data=reg_sample3 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Tailoredfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_TailorInter; 
    set ps_p; 
    if Tailoredfluidmeasure= 1 then ps_weight = 0.3947/ps_pred; else  ps_weight = 0.6053/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_TailorInter n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Tailoredfluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(Tailoredfluidmeasure, interlact_woutcomorb, TailorInter, ps_weight2_TailorInter);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Intermediate lactate with specific comorbidities */
    proc glimmix data=reg_sample4 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Tailoredfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION; 
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_TailorInterCom; 
    set ps_p; 
    if Tailoredfluidmeasure= 1 then ps_weight = 0.1652/ps_pred; else  ps_weight = 0.8348/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_TailorInterCom n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Tailoredfluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(Tailoredfluidmeasure, interlact_wcomorb, TailorInterC, ps_weight2_TailorInterCom);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    


/* Tables 1-4 - Pre and post weight SMDS for the primary analyses cohorts/fluid measure methods */

ods excel file="SMD Tables &sysdate9..xlsx" style=HTMLblue;
/* Hypoperfused without Comorbidities Cohort */
ods excel options(sheet_name='Hypo wo Reg Pragmatic' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_PragHypo label; run;
proc print data = weighted_balance_PragHypo label; run;
%SMD_PrePost_Fig(PrePost_SMD_PragHypo, "Hypoperfused without Comorbidities (Pragmatic)");

ods excel options(sheet_name='Hypo wo Reg SEP-1' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_Sep1Hypo label; run;
proc print data = weighted_balance_Sep1Hypo label; run;
%SMD_PrePost_Fig(PrePost_SMD_Sep1Hypo, "Hypoperfused without Comorbidities (Sep-1)");

ods excel options(sheet_name='Hypo wo Reg Tailored' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_TailorHypo label; run;
proc print data = weighted_balance_TailorHypo label; run;
%SMD_PrePost_Fig(PrePost_SMD_TailorHypo, "Hypoperfused without Comorbidities (Tailored)");

/* Hypoperfused with Comorbidities Cohort */
ods excel options(sheet_name='Hypo w Reg Pragmatic' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_PragHypoCom label; run;
proc print data = weighted_balance_PragHypoCom label; run;
%SMD_PrePost_Fig(PrePost_SMD_PragHypoCom, "Hypoperfused with Comorbidities (Pragmatic)");

ods excel options(sheet_name='Hypo w Reg SEP-1' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_Sep1HypoCom label; run;
proc print data = weighted_balance_Sep1HypoCom label; run;
%SMD_PrePost_Fig(PrePost_SMD_Sep1HypoCom, "Hypoperfused with Comorbidities (Sep-1)");

ods excel options(sheet_name='Hypo w Reg Tailored' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_TailorHypoCom label; run;
proc print data = weighted_balance_TailorHypoCom label; run;
%SMD_PrePost_Fig(PrePost_SMD_TailorHypoCom, "Hypoperfused with Comorbidities (Tailored)");

/* Intermediate Lactate without Comorbidities Cohort */
ods excel options(sheet_name='InterLact wo Reg Pragmatic' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_PragInter label; run;
proc print data = weighted_balance_PragInter label; run;
%SMD_PrePost_Fig(PrePost_SMD_PragInter, "Intermediate Lactate without Comorbidities (Pragmatic)");

ods excel options(sheet_name='InterLact wo Reg SEP-1' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_Sep1Inter label; run;
proc print data = weighted_balance_Sep1Inter label; run;
%SMD_PrePost_Fig(PrePost_SMD_Sep1Inter, "Intermediate Lactate without Comorbidities (Sep-1)");

ods excel options(sheet_name='InterLact wo Reg Tailored' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_TailorInter label; run;
proc print data = weighted_balance_TailorInter label; run;
%SMD_PrePost_Fig(PrePost_SMD_TailorInter, "Intermediate Lactate without Comorbidities (Tailored)");

/* Intermediate Lactate with Comorbidities Cohort */
ods excel options(sheet_name='InterLact w Reg Pragmatic' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_PragInterCom label; run;
proc print data = weighted_balance_PragInterCom label; run;
%SMD_PrePost_Fig(PrePost_SMD_PragInterCom, "Intermediate Lactate with Comorbidities (Pragmatic)");

ods excel options(sheet_name='InterLact w Reg SEP-1' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_Sep1InterCom label; run;
proc print data = weighted_balance_Sep1InterCom label; run;
%SMD_PrePost_Fig(PrePost_SMD_Sep1InterCom, "Intermediate Lactate with Comorbidities (Sep-1)");

ods excel options(sheet_name='InterLact w Reg Tailored' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_TailorInterC label; run;
proc print data = weighted_balance_TailorInterC label; run;
%SMD_PrePost_Fig(PrePost_SMD_TailorInterC, "Intermediate Lactate with Comorbidities (Tailored)");

ods excel close; 

/* Output data for analyses in STATA and for Sarah S to create spline plots */
proc sql;
    create table Sample_WGTS as select
    a.*,
    b.ps_weight as ps_weight_PH,  b.ps_pred as ps_pred_PH,  b.new_hosp as hosp_PH, /* Hypoperfused w/out Comorbidities - Pragmatic Approach */
    c.ps_weight as ps_weight_PHC, c.ps_pred as ps_pred_PHC, c.new_hosp as hosp_PHC, /* Hypoperfused w/ Comorbidities - Pragmatic Approach */
    d.ps_weight as ps_weight_PI,  d.ps_pred as ps_pred_PI,  d.new_hosp as hosp_PI, /* Intermediate Lactate w/out Comorbidities - Pragmatic Approach */
    e.ps_weight as ps_weight_PIC, e.ps_pred as ps_pred_PIC, e.new_hosp as hosp_PIC, /* Intermediate Lactate w/ Comorbidities - Pragmatic Approach */
    f.ps_weight as ps_weight_SH,  f.ps_pred as ps_pred_SH,  f.new_hosp as hosp_SH, /* Hypoperfused w/out Comorbidities - SEP-1 Approach */
    g.ps_weight as ps_weight_SHC, g.ps_pred as ps_pred_SHC, g.new_hosp as hosp_SHC, /* Hypoperfused w/ Comorbidities - SEP-1 Approach */
    h.ps_weight as ps_weight_SI,  h.ps_pred as ps_pred_SI,  h.new_hosp as hosp_SI, /* Intermediate Lactate w/out Comorbidities - SEP-1 Approach */
    i.ps_weight as ps_weight_SIC, i.ps_pred as ps_pred_SIC, i.new_hosp as hosp_SIC, /* Intermediate Lactate w/ Comorbidities - SEP-1 Approach */
    j.ps_weight as ps_weight_TH,  j.ps_pred as ps_pred_TH,  j.new_hosp as hosp_TH, /* Hypoperfused w/out Comorbidities - Tailored Approach */
    k.ps_weight as ps_weight_THC, k.ps_pred as ps_pred_THC, k.new_hosp as hosp_THC, /* Hypoperfused w/ Comorbidities - Tailored Approach */
    l.ps_weight as ps_weight_TI,  l.ps_pred as ps_pred_TI,  l.new_hosp as hosp_TI, /* Intermediate Lactate w/out Comorbidities - Tailored Approach */
    m.ps_weight as ps_weight_TIC, m.ps_pred as ps_pred_TIC, m.new_hosp as hosp_TIC /* Intermediate Lactate w/ Comorbidities - Tailored Approach */
    from sample a 
    left join ps_weight2_PragHypo b on a.nid=b.nid
    left join ps_weight2_PragHypoCom c on a.nid=c.nid 
    left join ps_weight2_PragInter d on a.nid=d.nid
    left join ps_weight2_PragInterCom e on a.nid=e.nid
    left join ps_weight2_Sep1Hypo f on a.nid=f.nid
    left join ps_weight2_Sep1HypoCom g on a.nid=g.nid
    left join ps_weight2_Sep1Inter h on a.nid=h.nid
    left join ps_weight2_Sep1InterCom i on a.nid=i.nid
    left join ps_weight2_TailorHypo j on a.nid=j.nid
    left join ps_weight2_TailorHypoCom k on a.nid=k.nid
    left join ps_weight2_TailorInter l on a.nid=l.nid
    left join ps_weight2_TailorInterCom m on a.nid=m.nid;
quit;

data out.Sample_WGTS_&sysdate9.;
    set Sample_WGTS;
run;

/* Clear out weighted dataset and SMD data - freeing up space in SAS since code is so long */
proc datasets library=work;
        delete ps_weight2_: unweighted_balance_: weighted_balance_: PrePost_SMD_:;
    run;    
/****************************************************************************************************************************************************************/

 
/****************************************************************************************************************************************************************/
/************************************************************************* Sensitivity Analyses *********************************************************************************/
/****************************************************************************************************************************************************************/


/************************************************ Sensitivity Analyses  - History of Congestive Heart Failure or History of moderate/severe kidney disease ********************************************************/

/************* Pragmatic Approach *************/
/* Model that creates the propensity scores for weights */

/* Hypoperfused without specific comorbidities */
    proc glimmix data=reg_sample5 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Pragmaticfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease /* CHF */ malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_PragHCHF; 
    set ps_p; 
    if Pragmaticfluidmeasure= 1 then ps_weight = 0.3655/ps_pred; else  ps_weight = 0.6345/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_PragHCHF n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Pragmaticfluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(Pragmaticfluidmeasure, hypo_CHF, PragHCHF, ps_weight2_PragHCHF);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;

/* Hypoperfused with specific comorbidities */
    proc glimmix data=reg_sample6 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Pragmaticfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp /* kidneydisease */ liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_PragHCKD; 
    set ps_p; 
    if Pragmaticfluidmeasure= 1 then ps_weight = 0.4591/ps_pred; else  ps_weight = 0.5409/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_PragHCKD n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Pragmaticfluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(Pragmaticfluidmeasure, hypo_CKD, PragHCKD, ps_weight2_PragHCKD);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;

/* Intermediate lactate without specific comorbidities */
    proc glimmix data=reg_sample7 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Pragmaticfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease /* CHF */ malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_PragICHF; 
    set ps_p; 
    if Pragmaticfluidmeasure= 1 then ps_weight = 0.1837/ps_pred; else  ps_weight = 0.8163/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_PragICHF n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Pragmaticfluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(Pragmaticfluidmeasure, interlact_CHF, PragICHF, ps_weight2_PragICHF);
    
    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;

/* Intermediate lactate with specific comorbidities */
    proc glimmix data=reg_sample8 order=data method=quad empirical; 
        CLASS max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Pragmaticfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp /* kidneydisease */ liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/    CL CovB DIST=BINARY LINK=LOGIT SOLUTION; 
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_PragICKD; 
    set ps_p; 
    if Pragmaticfluidmeasure= 1 then ps_weight = 0.2591/ps_pred; else  ps_weight = 0.7409/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_PragICKD n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Pragmaticfluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(Pragmaticfluidmeasure, interlact_CKD, PragICKD, ps_weight2_PragICKD);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;

/************* Sep-1 Approach *************/
/* SEP1fluidmeasure */
/* Model that creates the propensity scores for weights */

/* Hypoperfused without specific comorbidities */
    proc glimmix data=reg_sample5 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model SEP1fluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease /* CHF */ malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_Sep1HCHF; 
    set ps_p; 
    if SEP1fluidmeasure= 1 then ps_weight = 0.4495/ps_pred; else  ps_weight = 0.5505/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_Sep1HCHF n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class SEP1fluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(SEP1fluidmeasure, hypo_CHF, Sep1HCHF, ps_weight2_Sep1HCHF);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Hypoperfused with specific comorbidities */
    proc glimmix data=reg_sample6 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model SEP1fluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp /* kidneydisease */ liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_Sep1HCKD; 
    set ps_p; 
    if SEP1fluidmeasure= 1 then ps_weight = 0.5362/ps_pred; else  ps_weight = 0.4638/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_Sep1HCKD n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class SEP1fluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(SEP1fluidmeasure, hypo_CKD, Sep1HCKD, ps_weight2_Sep1HCKD);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Intermediate lactate without specific comorbidities */
    proc glimmix data=reg_sample7 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model SEP1fluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease /* CHF */ malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_Sep1ICHF; 
    set ps_p; 
    if SEP1fluidmeasure= 1 then ps_weight = 0.2465/ps_pred; else  ps_weight = 0.7535/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_Sep1ICHF n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class SEP1fluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(SEP1fluidmeasure, interlact_CHF, Sep1ICHF, ps_weight2_Sep1ICHF);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    
/* Intermediate lactate with specific comorbidities */
    proc glimmix data=reg_sample8 order=data method=quad empirical; 
        CLASS max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));
        model SEP1fluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp /* kidneydisease */ liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION; 
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_Sep1ICKD; 
    set ps_p; 
    if SEP1fluidmeasure= 1 then ps_weight = 0.3338/ps_pred; else  ps_weight = 0.6662/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_Sep1ICKD n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class SEP1fluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(SEP1fluidmeasure, interlact_CKD, Sep1ICKD, ps_weight2_Sep1ICKD);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/************* Tailored Approach *************/
/* Tailoredfluidmeasure */
/* Model that creates the propensity scores for weights */
/* Hypoperfused without specific comorbidities */
    proc glimmix data=reg_sample5 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Tailoredfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease /* CHF */ malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_TailorHCHF; 
    set ps_p; 
    if Tailoredfluidmeasure= 1 then ps_weight = 0.4285/ps_pred; else  ps_weight = 0.5834/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_TailorHCHF n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Tailoredfluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(Tailoredfluidmeasure, hypo_CHF, TailorHCHF, ps_weight2_TailorHCHF);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Hypoperfused with specific comorbidities */
    proc glimmix data=reg_sample6 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Tailoredfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp /* kidneydisease */ liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_TailorHCKD; 
    set ps_p; 
    if Tailoredfluidmeasure= 1 then ps_weight = 0.5173/ps_pred; else  ps_weight = 0.4827/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_TailorHCKD n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Tailoredfluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(Tailoredfluidmeasure, hypo_CKD, TailorHCKD, ps_weight2_TailorHCKD);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Intermediate lactate without specific comorbidities */
    proc glimmix data=reg_sample7 order=data method=quad empirical; 
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Tailoredfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease /* CHF */ malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_TailorICHF; 
    set ps_p; 
    if Tailoredfluidmeasure= 1 then ps_weight = 0.2204/ps_pred; else  ps_weight = 0.7796/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_TailorICHF n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Tailoredfluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(Tailoredfluidmeasure, interlact_CHF, TailorICHF, ps_weight2_TailorICHF);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Intermediate lactate with specific comorbidities */
    proc glimmix data=reg_sample8 order=data method=quad empirical; 
        CLASS max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Tailoredfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp /* kidneydisease */ liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION; 
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_TailorICKD; 
    set ps_p; 
    if Tailoredfluidmeasure= 1 then ps_weight = 0.3170/ps_pred; else  ps_weight = 0.8348/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_TailorICKD n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Tailoredfluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(Tailoredfluidmeasure, interlact_CKD, TailorICKD, ps_weight2_TailorICKD);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    


/* Tables 5-8 - Pre and post weight SMDS for the primary analyses cohorts/fluid measure methods */

ods excel file="SMD Tables Sens &sysdate9..xlsx" style=HTMLblue;
/* Hypoperfused with CHF Cohort */
ods excel options(sheet_name='Hypo w CHF Pragmatic' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_PragHCHF label; run;
proc print data = weighted_balance_PragHCHF label; run;
%SMD_PrePost_Fig(PrePost_SMD_PragHCHF, "Hypoperfused with CHF (Pragmatic)");

ods excel options(sheet_name='Hypo w CHF SEP-1' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_Sep1HCHF label; run;
proc print data = weighted_balance_Sep1HCHF label; run;
%SMD_PrePost_Fig(PrePost_SMD_Sep1HCHF, "Hypoperfused with CHF (Sep-1)");

ods excel options(sheet_name='Hypo w CHF Tailored' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_TailorHCHF label; run;
proc print data = weighted_balance_TailorHCHF label; run;
%SMD_PrePost_Fig(PrePost_SMD_TailorHCHF, "Hypoperfused with CHF (Tailored)");

/* Hypoperfused with CKD Cohort */
ods excel options(sheet_name='Hypo w CKD Pragmatic' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_PragHCKD label; run;
proc print data = weighted_balance_PragHCKD label; run;
%SMD_PrePost_Fig(PrePost_SMD_PragHCKD, "Hypoperfused with CKD (Pragmatic)");

ods excel options(sheet_name='Hypo w CKD SEP-1' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_Sep1HCKD label; run;
proc print data = weighted_balance_Sep1HCKD label; run;
%SMD_PrePost_Fig(PrePost_SMD_Sep1HCKD, "Hypoperfused with CKD (Sep-1)");

ods excel options(sheet_name='Hypo w CKD Tailored' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_TailorHCKD label; run;
proc print data = weighted_balance_TailorHCKD label; run;
%SMD_PrePost_Fig(PrePost_SMD_TailorHCKD, "Hypoperfused with CKD (Tailored)");

/* Intermediate Lactate with CHF Cohort */
ods excel options(sheet_name='InterLact w CHF Pragmatic' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_PragICHF label; run;
proc print data = weighted_balance_PragICHF label; run;
%SMD_PrePost_Fig(PrePost_SMD_PragICHF, "Intermediate Lactate with CHF (Pragmatic)");

ods excel options(sheet_name='InterLact w CHF SEP-1' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_Sep1ICHF label; run;
proc print data = weighted_balance_Sep1ICHF label; run;
%SMD_PrePost_Fig(PrePost_SMD_Sep1ICHF, "Intermediate Lactate with CHF (Sep-1)");

ods excel options(sheet_name='InterLact w CHF Tailored' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_TailorICHF label; run;
proc print data = weighted_balance_TailorICHF label; run;
%SMD_PrePost_Fig(PrePost_SMD_TailorICHF, "Intermediate Lactate with CHF (Tailored)");

/* Intermediate Lactate with CKD Cohort */
ods excel options(sheet_name='InterLact w CKD Pragmatic' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_PragICKD label; run;
proc print data = weighted_balance_PragICKD label; run;
%SMD_PrePost_Fig(PrePost_SMD_PragICKD, "Intermediate Lactate with CKD (Pragmatic)");

ods excel options(sheet_name='InterLact w CKD SEP-1' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_Sep1ICKD label; run;
proc print data = weighted_balance_Sep1ICKD label; run;
%SMD_PrePost_Fig(PrePost_SMD_Sep1ICKD, "Intermediate Lactate with CKD (Sep-1)");

ods excel options(sheet_name='InterLact w CKD Tailored' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_TailorICKD label; run;
proc print data = weighted_balance_TailorICKD label; run;
%SMD_PrePost_Fig(PrePost_SMD_TailorICKD, "Intermediate Lactate with CKD (Tailored)");

ods excel close; 


/* Output data for analyses in STATA and for Sarah S to create spline plots - Sensitivity 1 */
proc sql; 
    create table Sample_WGTS_Sen as select
    a.*,
    b.ps_weight as ps_weight_PHCHF, b.ps_pred as ps_pred_PHCHF, b.new_hosp as hosp_PHCHF,
    c.ps_weight as ps_weight_PHCKD, c.ps_pred as ps_pred_PHCKD, c.new_hosp as hosp_PHCKD,
    d.ps_weight as ps_weight_PICHF, d.ps_pred as ps_pred_PICHF, d.new_hosp as hosp_PICHF,
    e.ps_weight as ps_weight_PICKD, e.ps_pred as ps_pred_PICKD, e.new_hosp as hosp_PICKD,
    f.ps_weight as ps_weight_SHCHF, f.ps_pred as ps_pred_SHCHF, f.new_hosp as hosp_SHCHF,
    g.ps_weight as ps_weight_SHCKD, g.ps_pred as ps_pred_SHCKD, g.new_hosp as hosp_SHCKD,
    h.ps_weight as ps_weight_SICHF, h.ps_pred as ps_pred_SICHF, h.new_hosp as hosp_SICHF,
    i.ps_weight as ps_weight_SICKD, i.ps_pred as ps_pred_SICKD, i.new_hosp as hosp_SICKD,
    j.ps_weight as ps_weight_THCHF, j.ps_pred as ps_pred_THCHF, j.new_hosp as hosp_THCHF,
    k.ps_weight as ps_weight_THCKD, k.ps_pred as ps_pred_THCKD, k.new_hosp as hosp_THCKD,
    l.ps_weight as ps_weight_TICHF, l.ps_pred as ps_pred_TICHF, l.new_hosp as hosp_TICHF,
    m.ps_weight as ps_weight_TICKD, m.ps_pred as ps_pred_TICKD, m.new_hosp as hosp_TICKD
    from sample a 
    left join ps_weight2_PragHCHF b on a.nid=b.nid
    left join ps_weight2_PragHCKD c on a.nid=c.nid
    left join ps_weight2_PragICHF d on a.nid=d.nid
    left join ps_weight2_PragICKD e on a.nid=e.nid
    left join ps_weight2_Sep1HCHF f on a.nid=f.nid
    left join ps_weight2_Sep1HCKD g on a.nid=g.nid
    left join ps_weight2_Sep1ICHF h on a.nid=h.nid
    left join ps_weight2_Sep1ICKD i on a.nid=i.nid
    left join ps_weight2_TailorHCHF j on a.nid=j.nid
    left join ps_weight2_TailorHCKD k on a.nid=k.nid
    left join ps_weight2_TailorICHF l on a.nid=l.nid
    left join ps_weight2_TailorICKD m on a.nid=m.nid;
quit;

data out.Sample_WGTS_Sen_&sysdate9.;
    set Sample_WGTS_Sen;
run;

/* Clear out weighted dataset and SMD data - freeing up space in SAS since code is so long */
proc datasets library=work;
        delete ps_weight2_: unweighted_balance_: weighted_balance_: PrePost_SMD_:;
    run;       
/****************************************************************************************************************************************************************/


/************************************************ Sensitivity Analyses  - Dropping patients who had missing weights ********************************************************/

/************* Pragmatic Approach *************/
/* Model that creates the propensity scores for weights */

/* Hypoperfused without specific comorbidities */
    proc glimmix data=reg_sample1 order=data method=quad empirical; 
        where impute_weight = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Pragmaticfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_PragHypo; 
    set ps_p; 
    if Pragmaticfluidmeasure= 1 then ps_weight = 0.5555/ps_pred; else  ps_weight = 0.4445/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_PragHypo n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Pragmaticfluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(Pragmaticfluidmeasure, hypo_woutcomorb, PragHypo, ps_weight2_PragHypo);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;

/* Hypoperfused with specific comorbidities */
    proc glimmix data=reg_sample2 order=data method=quad empirical; 
        where impute_weight = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Pragmaticfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_PragHypoCom; 
    set ps_p; 
    if Pragmaticfluidmeasure= 1 then ps_weight = 0.2686/ps_pred; else  ps_weight = 0.7314/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_PragHypoCom n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Pragmaticfluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(Pragmaticfluidmeasure, hypo_wcomorb, PragHypoCom, ps_weight2_PragHypoCom);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;

/* Intermediate lactate without specific comorbidities */
    proc glimmix data=reg_sample3 order=data method=quad empirical; 
        where impute_weight = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Pragmaticfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_PragInter; 
    set ps_p; 
    if Pragmaticfluidmeasure= 1 then ps_weight = 0.3344/ps_pred; else  ps_weight = 0.6656/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_PragInter n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Pragmaticfluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(Pragmaticfluidmeasure, interlact_woutcomorb, PragInter, ps_weight2_PragInter);
    
    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;

/* Intermediate lactate with specific comorbidities */
    proc glimmix data=reg_sample4 order=data method=quad empirical; 
        where impute_weight = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Pragmaticfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_PragInterCom; 
    set ps_p; 
    if Pragmaticfluidmeasure= 1 then ps_weight = 0.1343/ps_pred; else  ps_weight = 0.8657/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_PragInterCom n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Pragmaticfluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(Pragmaticfluidmeasure, interlact_wcomorb, PragInterCom, ps_weight2_PragInterCom);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;

/************* Sep-1 Approach *************/
/* SEP1fluidmeasure */
/* Model that creates the propensity scores for weights */

/* Hypoperfused without specific comorbidities */
    proc glimmix data=reg_sample1 order=data method=quad empirical; 
        where impute_weight = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model SEP1fluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_Sep1Hypo; 
    set ps_p; 
    if SEP1fluidmeasure= 1 then ps_weight = 0.6333/ps_pred; else  ps_weight = 0.3667/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_Sep1Hypo n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class SEP1fluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(SEP1fluidmeasure, hypo_woutcomorb, Sep1Hypo, ps_weight2_Sep1Hypo);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Hypoperfused with specific comorbidities */
    proc glimmix data=reg_sample2 order=data method=quad empirical; 
        where impute_weight = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model SEP1fluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_Sep1HypoCom; 
    set ps_p; 
    if SEP1fluidmeasure= 1 then ps_weight = 0.3296/ps_pred; else  ps_weight = 0.6704/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_Sep1HypoCom n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class SEP1fluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(SEP1fluidmeasure, hypo_wcomorb, Sep1HypoCom, ps_weight2_Sep1HypoCom);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Intermediate lactate without specific comorbidities */
    proc glimmix data=reg_sample3 order=data method=quad empirical; 
        where impute_weight = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model SEP1fluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_Sep1Inter; 
    set ps_p; 
    if SEP1fluidmeasure= 1 then ps_weight = 0.4233/ps_pred; else  ps_weight = 0.5767/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_Sep1Inter n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class SEP1fluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(SEP1fluidmeasure, interlact_woutcomorb, Sep1Inter, ps_weight2_Sep1Inter);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    
/* Intermediate lactate with specific comorbidities */
    proc glimmix data=reg_sample4 order=data method=quad empirical; 
        where impute_weight = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model SEP1fluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION; 
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_Sep1InterCom; 
    set ps_p; 
    if SEP1fluidmeasure= 1 then ps_weight = 0.1656/ps_pred; else  ps_weight = 0.8344/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_Sep1InterCom n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class SEP1fluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(SEP1fluidmeasure, interlact_wcomorb, Sep1InterCom, ps_weight2_Sep1InterCom);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/************* Tailored Approach *************/
/* Tailoredfluidmeasure */
/* Model that creates the propensity scores for weights */
/* Hypoperfused without specific comorbidities */
    proc glimmix data=reg_sample1 order=data method=quad empirical; 
        where impute_weight = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Tailoredfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_TailorHypo; 
    set ps_p; 
    if Tailoredfluidmeasure= 1 then ps_weight = 0.6141/ps_pred; else  ps_weight = 0.3859/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_TailorHypo n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Tailoredfluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(Tailoredfluidmeasure, hypo_woutcomorb, TailorHypo, ps_weight2_TailorHypo);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Hypoperfused with specific comorbidities */
    proc glimmix data=reg_sample2 order=data method=quad empirical; 
        where impute_weight = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Tailoredfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_TailorHypoCom; 
    set ps_p; 
    if Tailoredfluidmeasure= 1 then ps_weight = 0.3249/ps_pred; else  ps_weight = 0.6704/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_TailorHypoCom n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Tailoredfluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(Tailoredfluidmeasure, hypo_wcomorb, TailorHypoCom, ps_weight2_TailorHypoCom);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Intermediate lactate without specific comorbidities */
    proc glimmix data=reg_sample3 order=data method=quad empirical; 
        where impute_weight = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Tailoredfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_TailorInter; 
    set ps_p; 
    if Tailoredfluidmeasure= 1 then ps_weight = 0.3953/ps_pred; else  ps_weight = 0.6047/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_TailorInter n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Tailoredfluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(Tailoredfluidmeasure, interlact_woutcomorb, TailorInter, ps_weight2_TailorInter);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Intermediate lactate with specific comorbidities */
    proc glimmix data=reg_sample4 order=data method=quad empirical; 
        where impute_weight = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Tailoredfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION; 
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_TailorInterCom; 
    set ps_p; 
    if Tailoredfluidmeasure= 1 then ps_weight = 0.1644/ps_pred; else  ps_weight = 0.8356/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_TailorInterCom n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Tailoredfluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(Tailoredfluidmeasure, interlact_wcomorb, TailorInterC, ps_weight2_TailorInterCom);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    


/* Tables 9-12 - Pre and post weight SMDS for the sensitivity analyses cohorts/fluid measure methods (No missing weights)*/

ods excel file="SMD Tables Sens2 &sysdate9..xlsx" style=HTMLblue;
/* Hypoperfused without Comorbidities Cohort */
ods excel options(sheet_name='Hypo wo Reg Pragmatic' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_PragHypo label; run;
proc print data = weighted_balance_PragHypo label; run;
%SMD_PrePost_Fig(PrePost_SMD_PragHypo, "Hypoperfused without Comorbidities (Pragmatic)");

ods excel options(sheet_name='Hypo wo Reg SEP-1' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_Sep1Hypo label; run;
proc print data = weighted_balance_Sep1Hypo label; run;
%SMD_PrePost_Fig(PrePost_SMD_Sep1Hypo, "Hypoperfused without Comorbidities (Sep-1)");

ods excel options(sheet_name='Hypo wo Reg Tailored' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_TailorHypo label; run;
proc print data = weighted_balance_TailorHypo label; run;
%SMD_PrePost_Fig(PrePost_SMD_TailorHypo, "Hypoperfused without Comorbidities (Tailored)");

/* Hypoperfused with Comorbidities Cohort */
ods excel options(sheet_name='Hypo w Reg Pragmatic' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_PragHypoCom label; run;
proc print data = weighted_balance_PragHypoCom label; run;
%SMD_PrePost_Fig(PrePost_SMD_PragHypoCom, "Hypoperfused with Comorbidities (Pragmatic)");

ods excel options(sheet_name='Hypo w Reg SEP-1' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_Sep1HypoCom label; run;
proc print data = weighted_balance_Sep1HypoCom label; run;
%SMD_PrePost_Fig(PrePost_SMD_Sep1HypoCom, "Hypoperfused with Comorbidities (Sep-1)");

ods excel options(sheet_name='Hypo w Reg Tailored' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_TailorHypoCom label; run;
proc print data = weighted_balance_TailorHypoCom label; run;
%SMD_PrePost_Fig(PrePost_SMD_TailorHypoCom, "Hypoperfused with Comorbidities (Tailored)");

/* Intermediate Lactate without Comorbidities Cohort */
ods excel options(sheet_name='InterLact wo Reg Pragmatic' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_PragInter label; run;
proc print data = weighted_balance_PragInter label; run;
%SMD_PrePost_Fig(PrePost_SMD_PragInter, "Intermediate Lactate without Comorbidities (Pragmatic)");

ods excel options(sheet_name='InterLact wo Reg SEP-1' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_Sep1Inter label; run;
proc print data = weighted_balance_Sep1Inter label; run;
%SMD_PrePost_Fig(PrePost_SMD_Sep1Inter, "Intermediate Lactate without Comorbidities (Sep-1)");

ods excel options(sheet_name='InterLact wo Reg Tailored' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_TailorInter label; run;
proc print data = weighted_balance_TailorInter label; run;
%SMD_PrePost_Fig(PrePost_SMD_TailorInter, "Intermediate Lactate without Comorbidities (Tailored)");

/* Intermediate Lactate with Comorbidities Cohort */
ods excel options(sheet_name='InterLact w Reg Pragmatic' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_PragInterCom label; run;
proc print data = weighted_balance_PragInterCom label; run;
%SMD_PrePost_Fig(PrePost_SMD_PragInterCom, "Intermediate Lactate with Comorbidities (Pragmatic)");

ods excel options(sheet_name='InterLact w Reg SEP-1' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_Sep1InterCom label; run;
proc print data = weighted_balance_Sep1InterCom label; run;
%SMD_PrePost_Fig(PrePost_SMD_Sep1InterCom, "Intermediate Lactate with Comorbidities (Sep-1)");

ods excel options(sheet_name='InterLact w Reg Tailored' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_TailorInterC label; run;
proc print data = weighted_balance_TailorInterC label; run;
%SMD_PrePost_Fig(PrePost_SMD_TailorInterC, "Intermediate Lactate with Comorbidities (Tailored)");


ods excel close; 

/* Output data for analyses in STATA and for Sarah S to create spline plots */
proc sql;
    create table Sample_WGTS_Sen2 as select
    a.*,
    b.ps_weight as ps_weight_PH,  b.ps_pred as ps_pred_PH,  b.new_hosp as hosp_PH, /* Hypoperfused w/out Comorbidities - Pragmatic Approach */
    c.ps_weight as ps_weight_PHC, c.ps_pred as ps_pred_PHC, c.new_hosp as hosp_PHC, /* Hypoperfused w/ Comorbidities - Pragmatic Approach */
    d.ps_weight as ps_weight_PI,  d.ps_pred as ps_pred_PI,  d.new_hosp as hosp_PI, /* Intermediate Lactate w/out Comorbidities - Pragmatic Approach */
    e.ps_weight as ps_weight_PIC, e.ps_pred as ps_pred_PIC, e.new_hosp as hosp_PIC, /* Intermediate Lactate w/ Comorbidities - Pragmatic Approach */
    f.ps_weight as ps_weight_SH,  f.ps_pred as ps_pred_SH,  f.new_hosp as hosp_SH, /* Hypoperfused w/out Comorbidities - SEP-1 Approach */
    g.ps_weight as ps_weight_SHC, g.ps_pred as ps_pred_SHC, g.new_hosp as hosp_SHC, /* Hypoperfused w/ Comorbidities - SEP-1 Approach */
    h.ps_weight as ps_weight_SI,  h.ps_pred as ps_pred_SI,  h.new_hosp as hosp_SI, /* Intermediate Lactate w/out Comorbidities - SEP-1 Approach */
    i.ps_weight as ps_weight_SIC, i.ps_pred as ps_pred_SIC, i.new_hosp as hosp_SIC, /* Intermediate Lactate w/ Comorbidities - SEP-1 Approach */
    j.ps_weight as ps_weight_TH,  j.ps_pred as ps_pred_TH,  j.new_hosp as hosp_TH, /* Hypoperfused w/out Comorbidities - Tailored Approach */
    k.ps_weight as ps_weight_THC, k.ps_pred as ps_pred_THC, k.new_hosp as hosp_THC, /* Hypoperfused w/ Comorbidities - Tailored Approach */
    l.ps_weight as ps_weight_TI,  l.ps_pred as ps_pred_TI,  l.new_hosp as hosp_TI, /* Intermediate Lactate w/out Comorbidities - Tailored Approach */
    m.ps_weight as ps_weight_TIC, m.ps_pred as ps_pred_TIC, m.new_hosp as hosp_TIC /* Intermediate Lactate w/ Comorbidities - Tailored Approach */
    from sample a 
    left join ps_weight2_PragHypo b on a.nid=b.nid
    left join ps_weight2_PragHypoCom c on a.nid=c.nid 
    left join ps_weight2_PragInter d on a.nid=d.nid
    left join ps_weight2_PragInterCom e on a.nid=e.nid
    left join ps_weight2_Sep1Hypo f on a.nid=f.nid
    left join ps_weight2_Sep1HypoCom g on a.nid=g.nid
    left join ps_weight2_Sep1Inter h on a.nid=h.nid
    left join ps_weight2_Sep1InterCom i on a.nid=i.nid
    left join ps_weight2_TailorHypo j on a.nid=j.nid
    left join ps_weight2_TailorHypoCom k on a.nid=k.nid
    left join ps_weight2_TailorInter l on a.nid=l.nid
    left join ps_weight2_TailorInterCom m on a.nid=m.nid;
quit;

data out.Sample_WGTS_Sen2_&sysdate9.;
    set Sample_WGTS_Sen2;
run;

/* Clear out weighted dataset and SMD data - freeing up space in SAS since code is so long */
proc datasets library=work;
        delete ps_weight2_: unweighted_balance_: weighted_balance_: PrePost_SMD_:;
    run;       
/****************************************************************************************************************************************************************/


/************************************************ Sensitivity Analyses  - Dropping patients how had early deaths (mortality within 6 hrs of arrival) ********************************************************/

/************* Pragmatic Approach *************/
/* Model that creates the propensity scores for weights */

/* Hypoperfused without specific comorbidities */
    proc glimmix data=reg_sample1 order=data method=quad empirical; 
        where deathin6 = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Pragmaticfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_PragHypo; 
    set ps_p; 
    if Pragmaticfluidmeasure= 1 then ps_weight = 0.5496/ps_pred; else  ps_weight = 0.4504/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_PragHypo n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Pragmaticfluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(Pragmaticfluidmeasure, hypo_woutcomorb, PragHypo, ps_weight2_PragHypo);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;

/* Hypoperfused with specific comorbidities */
    proc glimmix data=reg_sample2 order=data method=quad empirical; 
        where deathin6 = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Pragmaticfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_PragHypoCom; 
    set ps_p; 
    if Pragmaticfluidmeasure= 1 then ps_weight = 0.2649/ps_pred; else  ps_weight = 0.7351/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_PragHypoCom n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Pragmaticfluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(Pragmaticfluidmeasure, hypo_wcomorb, PragHypoCom, ps_weight2_PragHypoCom);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;

/* Intermediate lactate without specific comorbidities */
    proc glimmix data=reg_sample3 order=data method=quad empirical; 
        where deathin6 = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Pragmaticfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_PragInter; 
    set ps_p; 
    if Pragmaticfluidmeasure= 1 then ps_weight = 0.3315/ps_pred; else  ps_weight = 0.6685/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_PragInter n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Pragmaticfluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(Pragmaticfluidmeasure, interlact_woutcomorb, PragInter, ps_weight2_PragInter);
    
    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;

/* Intermediate lactate with specific comorbidities */
    proc glimmix data=reg_sample4 order=data method=quad empirical; 
        where deathin6 = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Pragmaticfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_PragInterCom; 
    set ps_p; 
    if Pragmaticfluidmeasure= 1 then ps_weight = 0.1320/ps_pred; else  ps_weight = 0.8680/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_PragInterCom n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Pragmaticfluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(Pragmaticfluidmeasure, interlact_wcomorb, PragInterCom, ps_weight2_PragInterCom);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;

/************* Sep-1 Approach *************/
/* SEP1fluidmeasure */
/* Model that creates the propensity scores for weights */

/* Hypoperfused without specific comorbidities */
    proc glimmix data=reg_sample1 order=data method=quad empirical; 
        where deathin6 = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model SEP1fluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_Sep1Hypo; 
    set ps_p; 
    if SEP1fluidmeasure= 1 then ps_weight = 0.6274/ps_pred; else  ps_weight = 0.3726/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_Sep1Hypo n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class SEP1fluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(SEP1fluidmeasure, hypo_woutcomorb, Sep1Hypo, ps_weight2_Sep1Hypo);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Hypoperfused with specific comorbidities */
    proc glimmix data=reg_sample2 order=data method=quad empirical; 
        where deathin6 = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model SEP1fluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_Sep1HypoCom; 
    set ps_p; 
    if SEP1fluidmeasure= 1 then ps_weight = 0.3267/ps_pred; else  ps_weight = 0.6733/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_Sep1HypoCom n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class SEP1fluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(SEP1fluidmeasure, hypo_wcomorb, Sep1HypoCom, ps_weight2_Sep1HypoCom);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Intermediate lactate without specific comorbidities */
    proc glimmix data=reg_sample3 order=data method=quad empirical; 
        where deathin6 = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model SEP1fluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_Sep1Inter; 
    set ps_p; 
    if SEP1fluidmeasure= 1 then ps_weight = 0.4196/ps_pred; else  ps_weight = 0.5804/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_Sep1Inter n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class SEP1fluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(SEP1fluidmeasure, interlact_woutcomorb, Sep1Inter, ps_weight2_Sep1Inter);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    
/* Intermediate lactate with specific comorbidities */
    proc glimmix data=reg_sample4 order=data method=quad empirical; 
        where deathin6 = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model SEP1fluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION; 
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_Sep1InterCom; 
    set ps_p; 
    if SEP1fluidmeasure= 1 then ps_weight = 0.1650/ps_pred; else  ps_weight = 0.8350/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_Sep1InterCom n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class SEP1fluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(SEP1fluidmeasure, interlact_wcomorb, Sep1InterCom, ps_weight2_Sep1InterCom);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/************* Tailored Approach *************/
/* Tailoredfluidmeasure */
/* Model that creates the propensity scores for weights */
/* Hypoperfused without specific comorbidities */
    proc glimmix data=reg_sample1 order=data method=quad empirical; 
        where deathin6 = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Tailoredfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_TailorHypo; 
    set ps_p; 
    if Tailoredfluidmeasure= 1 then ps_weight = 0.6114/ps_pred; else  ps_weight = 0.3886/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_TailorHypo n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Tailoredfluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(Tailoredfluidmeasure, hypo_woutcomorb, TailorHypo, ps_weight2_TailorHypo);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Hypoperfused with specific comorbidities */
    proc glimmix data=reg_sample2 order=data method=quad empirical; 
        where deathin6 = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Tailoredfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_TailorHypoCom; 
    set ps_p; 
    if Tailoredfluidmeasure= 1 then ps_weight = 0.3237/ps_pred; else  ps_weight = 0.6763/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_TailorHypoCom n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Tailoredfluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(Tailoredfluidmeasure, hypo_wcomorb, TailorHypoCom, ps_weight2_TailorHypoCom);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Intermediate lactate without specific comorbidities */
    proc glimmix data=reg_sample3 order=data method=quad empirical; 
        where deathin6 = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Tailoredfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION;  
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_TailorInter; 
    set ps_p; 
    if Tailoredfluidmeasure= 1 then ps_weight = 0.3940/ps_pred; else  ps_weight = 0.6060/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_TailorInter n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Tailoredfluidmeasure; 
    var ps_weight ps_pred; 
    run;

    /* Run SMD tables code */
   %MacroPollo(Tailoredfluidmeasure, interlact_woutcomorb, TailorInter, ps_weight2_TailorInter);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    

/* Intermediate lactate with specific comorbidities */
    proc glimmix data=reg_sample4 order=data method=quad empirical; 
        where deathin6 = 0;
        CLASS new_hosp max_temp(ref = '2') max_HR(ref = '2') max_RR(ref = '1');
        /*Fucntional forms from mortality model code */
        effect 	spl_creatinine = spline(creatinine_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_creat_D));
        effect	spl_lactate = spline(lactatemax_draw/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_lact_D));
        effect	spl_platelet = spline(platelets_low/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_plate_D));
        effect	spl_ratiomin = spline(ratio_min/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_ratio_D));
        effect	spl_age = spline(age/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls4_age_D));
        effect	spl_BMI = spline(bmi_calculated/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_bmi_D));
        effect	spl_WBCday3 = spline(WBC_high/ details naturalcubic basis=tpf(noint) knotmethod=list(&pctls5_WBC_D));

        model Tailoredfluidmeasure(EVENT='1')= spl_age male postacutecare priorhosp kidneydisease liverdisease CHF malignancy mortality_predicted spl_BMI spl_lactate spl_creatinine spl_ratiomin mechvent_6hr vaso_6hrs alter_mental_status Charlson max_temp min_sysBP max_RR max_HR spl_WBCday3 bilirubin_sq spl_platelet/ CL CovB DIST=BINARY LINK=LOGIT SOLUTION; 
        random int / sub=new_hosp;
        output out=ps_p predicted(ilink)=ps_pred;
    run;

    /* Create weights from propensity scores */
    data ps_weight2_TailorInterCom; 
    set ps_p; 
    if Tailoredfluidmeasure= 1 then ps_weight = 0.1626/ps_pred; else  ps_weight = 0.8374/(1-ps_pred); 
    run; *stabilized weights;

    
   /* Double check to make sure weights are within normal range */
     proc means data=ps_weight2_TailorInterCom n nmiss mean sum std p10 p25 p50 p75 p90 min max; 
    class Tailoredfluidmeasure; 
    var ps_weight ps_pred; 
    run;
    
    /* Run SMD tables code */
   %MacroPollo(Tailoredfluidmeasure, interlact_wcomorb, TailorInterC, ps_weight2_TailorInterCom);

    
  /* Clear out propensity score from most recent model */
      proc datasets library=work;
        delete ps_p;
    run;    


/* Tables 13-16 - Pre and post weight SMDS for the primary analyses cohorts/fluid measure methods (No death within 6hrs) */

ods excel file="SMD Tables sens3 &sysdate9..xlsx" style=HTMLblue;
/* Hypoperfused without Comorbidities Cohort */
ods excel options(sheet_name='Hypo wo Reg Pragmatic' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_PragHypo label; run;
proc print data = weighted_balance_PragHypo label; run;
%SMD_PrePost_Fig(PrePost_SMD_PragHypo, "Hypoperfused without Comorbidities (Pragmatic)");

ods excel options(sheet_name='Hypo wo Reg SEP-1' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_Sep1Hypo label; run;
proc print data = weighted_balance_Sep1Hypo label; run;
%SMD_PrePost_Fig(PrePost_SMD_Sep1Hypo, "Hypoperfused without Comorbidities (Sep-1)");

ods excel options(sheet_name='Hypo wo Reg Tailored' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_TailorHypo label; run;
proc print data = weighted_balance_TailorHypo label; run;
%SMD_PrePost_Fig(PrePost_SMD_TailorHypo, "Hypoperfused without Comorbidities (Tailored)");

/* Hypoperfused with Comorbidities Cohort */
ods excel options(sheet_name='Hypo w Reg Pragmatic' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_PragHypoCom label; run;
proc print data = weighted_balance_PragHypoCom label; run;
%SMD_PrePost_Fig(PrePost_SMD_PragHypoCom, "Hypoperfused with Comorbidities (Pragmatic)");

ods excel options(sheet_name='Hypo w Reg SEP-1' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_Sep1HypoCom label; run;
proc print data = weighted_balance_Sep1HypoCom label; run;
%SMD_PrePost_Fig(PrePost_SMD_Sep1HypoCom, "Hypoperfused with Comorbidities (Sep-1)");

ods excel options(sheet_name='Hypo w Reg Tailored' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_TailorHypoCom label; run;
proc print data = weighted_balance_TailorHypoCom label; run;
%SMD_PrePost_Fig(PrePost_SMD_TailorHypoCom, "Hypoperfused with Comorbidities (Tailored)");

/* Intermediate Lactate without Comorbidities Cohort */
ods excel options(sheet_name='InterLact wo Reg Pragmatic' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_PragInter label; run;
proc print data = weighted_balance_PragInter label; run;
%SMD_PrePost_Fig(PrePost_SMD_PragInter, "Intermediate Lactate without Comorbidities (Pragmatic)");

ods excel options(sheet_name='InterLact wo Reg SEP-1' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_Sep1Inter label; run;
proc print data = weighted_balance_Sep1Inter label; run;
%SMD_PrePost_Fig(PrePost_SMD_Sep1Inter, "Intermediate Lactate without Comorbidities (Sep-1)");

ods excel options(sheet_name='InterLact wo Reg Tailored' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_TailorInter label; run;
proc print data = weighted_balance_TailorInter label; run;
%SMD_PrePost_Fig(PrePost_SMD_TailorInter, "Intermediate Lactate without Comorbidities (Tailored)");

/* Intermediate Lactate with Comorbidities Cohort */
ods excel options(sheet_name='InterLact w Reg Pragmatic' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_PragInterCom label; run;
proc print data = weighted_balance_PragInterCom label; run;
%SMD_PrePost_Fig(PrePost_SMD_PragInterCom, "Intermediate Lactate with Comorbidities (Pragmatic)");

ods excel options(sheet_name='InterLact w Reg SEP-1' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_Sep1InterCom label; run;
proc print data = weighted_balance_Sep1InterCom label; run;
%SMD_PrePost_Fig(PrePost_SMD_Sep1InterCom, "Intermediate Lactate with Comorbidities (Sep-1)");

ods excel options(sheet_name='InterLact w Reg Tailored' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc print data = unweighted_balance_TailorInterC label; run;
proc print data = weighted_balance_TailorInterC label; run;
%SMD_PrePost_Fig(PrePost_SMD_TailorInterC, "Intermediate Lactate with Comorbidities (Tailored)");


ods excel close; 

/* Output data for analyses in STATA and for Sarah S to create spline plots */
proc sql;
    create table Sample_WGTS_sen3 as select
    a.*,
    b.ps_weight as ps_weight_PH,  b.ps_pred as ps_pred_PH,  b.new_hosp as hosp_PH, /* Hypoperfused w/out Comorbidities - Pragmatic Approach */
    c.ps_weight as ps_weight_PHC, c.ps_pred as ps_pred_PHC, c.new_hosp as hosp_PHC, /* Hypoperfused w/ Comorbidities - Pragmatic Approach */
    d.ps_weight as ps_weight_PI,  d.ps_pred as ps_pred_PI,  d.new_hosp as hosp_PI, /* Intermediate Lactate w/out Comorbidities - Pragmatic Approach */
    e.ps_weight as ps_weight_PIC, e.ps_pred as ps_pred_PIC, e.new_hosp as hosp_PIC, /* Intermediate Lactate w/ Comorbidities - Pragmatic Approach */
    f.ps_weight as ps_weight_SH,  f.ps_pred as ps_pred_SH,  f.new_hosp as hosp_SH, /* Hypoperfused w/out Comorbidities - SEP-1 Approach */
    g.ps_weight as ps_weight_SHC, g.ps_pred as ps_pred_SHC, g.new_hosp as hosp_SHC, /* Hypoperfused w/ Comorbidities - SEP-1 Approach */
    h.ps_weight as ps_weight_SI,  h.ps_pred as ps_pred_SI,  h.new_hosp as hosp_SI, /* Intermediate Lactate w/out Comorbidities - SEP-1 Approach */
    i.ps_weight as ps_weight_SIC, i.ps_pred as ps_pred_SIC, i.new_hosp as hosp_SIC, /* Intermediate Lactate w/ Comorbidities - SEP-1 Approach */
    j.ps_weight as ps_weight_TH,  j.ps_pred as ps_pred_TH,  j.new_hosp as hosp_TH, /* Hypoperfused w/out Comorbidities - Tailored Approach */
    k.ps_weight as ps_weight_THC, k.ps_pred as ps_pred_THC, k.new_hosp as hosp_THC, /* Hypoperfused w/ Comorbidities - Tailored Approach */
    l.ps_weight as ps_weight_TI,  l.ps_pred as ps_pred_TI,  l.new_hosp as hosp_TI, /* Intermediate Lactate w/out Comorbidities - Tailored Approach */
    m.ps_weight as ps_weight_TIC, m.ps_pred as ps_pred_TIC, m.new_hosp as hosp_TIC /* Intermediate Lactate w/ Comorbidities - Tailored Approach */
    from sample a 
    left join ps_weight2_PragHypo b on a.nid=b.nid
    left join ps_weight2_PragHypoCom c on a.nid=c.nid 
    left join ps_weight2_PragInter d on a.nid=d.nid
    left join ps_weight2_PragInterCom e on a.nid=e.nid
    left join ps_weight2_Sep1Hypo f on a.nid=f.nid
    left join ps_weight2_Sep1HypoCom g on a.nid=g.nid
    left join ps_weight2_Sep1Inter h on a.nid=h.nid
    left join ps_weight2_Sep1InterCom i on a.nid=i.nid
    left join ps_weight2_TailorHypo j on a.nid=j.nid
    left join ps_weight2_TailorHypoCom k on a.nid=k.nid
    left join ps_weight2_TailorInter l on a.nid=l.nid
    left join ps_weight2_TailorInterCom m on a.nid=m.nid;
quit;

data out.Sample_WGTS_sen3_&sysdate9.;
    set Sample_WGTS_sen3;
run;

/* Clear out weighted dataset and SMD data - freeing up space in SAS since code is so long */
proc datasets library=work;
        delete ps_weight2_: unweighted_balance_: weighted_balance_: PrePost_SMD_:;
    run;      
/****************************************************************************************************************************************************************/

/***************************************************************************************************************************************************************/
/*********************************************************************** Table 17 *******************************************************************************/
/***************************************************************************************************************************************************************/


ods excel file="Table 17 &sysdate9..xlsx" style=HTMLblue;
ods excel options(sheet_name='Table 3 Raw' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
/* Create a table that gets the counts for the hospital demographic variables - variables where we want counts/percentages */
proc tabulate data = reg_sample1 out = Table1 missing;
	class Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure hypo_woutcomorb hypo_wcomorb interlact_woutcomorb interlact_wcomorb;
	table /*Row Variables */
            Pragmaticfluidmeasure = 'Pragmatic Approach'
            SEP1fluidmeasure = 'SEP-1 Approach'
            Tailoredfluidmeasure = 'Tailored Approach'
            ,

		   /* Subgroups - Column Variables */
		   N /* Geting the total for each Row Variable */
		   /* Getting the values within each rows subgroup */ 
           N*(hypo_woutcomorb = 'Hypoperfused without Comorbidities Cohort'
              hypo_wcomorb = 'Hypoperfused with Comorbidities Cohort'
              interlact_woutcomorb = 'Intermediate Lactate without Comorbidities Cohort'
              interlact_wcomorb = 'Intermediate Lactate with Comorbidities Cohort');
		   title 'Table 17. Association between receiving ≥30 ml/kg initial fluid and mortality among patients in each cohort, using different approaches to operationalizing the 30 ml/kg fluid volume';
         
run;

proc freq data = reg_sample1;
	tables (Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure)*(mortality_30day)/ chisq fisher;
    where hypo_woutcomorb = 1;
run;

proc freq data = reg_sample1;
	tables (Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure)*(mortality_30day)/ chisq fisher;
    where hypo_wcomorb = 1;
run;

proc freq data = reg_sample1;
	tables (Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure)*(mortality_30day)/ chisq fisher;
    where interlact_woutcomorb = 1;
run;

proc freq data = reg_sample1;
	tables (Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure)*(mortality_30day)/ chisq fisher;
    where interlact_wcomorb = 1;
run;

/* Running Models in STATA to calculate Risk differences  - General Code used below, See STATA Do file for specific code */
/* import sas using "sample_wgts_29oct2025.sas7bdat", clear */
/* keep if ([GROUP] == 1) */
/* mkspline spl_creatinine 5 = creatinine_high, pctile displayknots */
/* mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots */
/* mkspline spl_platelet 5 = platelets_low, pctile displayknots */
/* mkspline spl_ratiomin 4 = ratio_min, pctile displayknots */
/* mkspline spl_age 4 = age, pctile displayknots */
/* mkspline spl_BMI 5 = BMI_calculated, pctile displayknots */
/* mkspline spl_WBCday3 5 = WBC_high, pctile displayknots */
/* melogit mortality_30day ib0.[fluidmeasure] c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PH] || hosp_PH: , or */
/* margins SEP1fluidmeasure, post */
/* nlcom _b[1.SEP1fluidmeasure] / _b[0.SEP1fluidmeasure] */ *risk ratio;
/* nlcom _b[1.SEP1fluidmeasure] - _b[0.SEP1fluidmeasure] */ *risk difference;


ods excel close; 

/***************************************************************************************************************************************************************/
/*********************************************************************** Table 18 *******************************************************************************/
/***************************************************************************************************************************************************************/


ods excel file="Table 18 &sysdate9..xlsx" style=HTMLblue;
ods excel options(sheet_name='Table 3 Raw' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
/* Create a table that gets the counts for the hospital demographic variables - variables where we want counts/percentages */
proc tabulate data = sample out = Table1 missing;
	class Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure hypo_CHF hypo_CKD interlact_CHF interlact_CKD;
	table /*Row Variables */
            Pragmaticfluidmeasure = 'Pragmatic Approach'
            SEP1fluidmeasure = 'SEP-1 Approach'
            Tailoredfluidmeasure = 'Tailored Approach'
            ,

		   /* Subgroups - Column Variables */
		   N /* Geting the total for each Row Variable */
		   /* Getting the values within each rows subgroup */ 
           N*(hypo_CHF = 'Hypoperfused with CHF Cohort'
              hypo_CKD = 'Hypoperfused with CKD Cohort'
              interlact_CHF = 'Intermediate Lactate with CHF Cohort'
              interlact_CKD = 'Intermediate Lactate with CKD Cohort');
		   title 'Table 18. Association between receiving ≥30 ml/kg initial fluid and mortality among patients with history of heart failure (sensitivity analysis population A: History of CHF) and history of chronic kidney disease (sensitivity analysis population B: History of CKD) ';
         
run;
 
proc freq data = sample;
	tables (Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure)*(mortality_30day)/ chisq fisher;
    where hypo_CHF = 1;
run;

proc freq data = sample;
	tables (Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure)*(mortality_30day)/ chisq fisher;
    where hypo_CKD = 1;
run;

proc freq data = sample;
	tables (Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure)*(mortality_30day)/ chisq fisher;
    where interlact_CHF = 1;
run;

proc freq data = sample;
	tables (Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure)*(mortality_30day)/ chisq fisher;
    where interlact_CKD = 1;
run;

/* Running Models in STATA to calculate Risk differences  - General Code used below, See STATA Do file for specific code */
/* import sas using "sample_wgts_29oct2025.sas7bdat", clear */
/* keep if ([GROUP] == 1) */
/* mkspline spl_creatinine 5 = creatinine_high, pctile displayknots */
/* mkspline spl_lactate 5 = lactatemax_draw, pctile displayknots */
/* mkspline spl_platelet 5 = platelets_low, pctile displayknots */
/* mkspline spl_ratiomin 4 = ratio_min, pctile displayknots */
/* mkspline spl_age 4 = age, pctile displayknots */
/* mkspline spl_BMI 5 = BMI_calculated, pctile displayknots */
/* mkspline spl_WBCday3 5 = WBC_high, pctile displayknots */
/* melogit mortality_30day ib0.[fluidmeasure] c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight=ps_weight_PH] || hosp_PH: , or */
/* margins SEP1fluidmeasure, post */
/* nlcom _b[1.SEP1fluidmeasure] / _b[0.SEP1fluidmeasure] */ *risk ratio;
/* nlcom _b[1.SEP1fluidmeasure] - _b[0.SEP1fluidmeasure] */ *risk difference;


ods excel close; 

/***************************************************************************************************************************************************************/
/*********************************************************************** Table 19 *******************************************************************************/
/***************************************************************************************************************************************************************/


ods excel file="Table 19 &sysdate9..xlsx" style=HTMLblue;
ods excel options(sheet_name='Table 3 Raw' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
/* Create a table that gets the counts for the hospital demographic variables - variables where we want counts/percentages */
proc tabulate data = sample out = Table1 missing;
    where impute_weight = 0;
	class Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure hypo_woutcomorb hypo_wcomorb interlact_woutcomorb interlact_wcomorb;
	table /*Row Variables */
            Pragmaticfluidmeasure = 'Pragmatic Approach'
            SEP1fluidmeasure = 'SEP-1 Approach'
            Tailoredfluidmeasure = 'Tailored Approach'
            ,

		   /* Subgroups - Column Variables */
		   N /* Geting the total for each Row Variable */
		   /* Getting the values within each rows subgroup */ 
           N*(hypo_woutcomorb = 'Hypoperfused without Comorbidities Cohort'
              hypo_wcomorb = 'Hypoperfused with Comorbidities Cohort'
              interlact_woutcomorb = 'Intermediate Lactate without Comorbidities Cohort'
              interlact_wcomorb = 'Intermediate Lactate with Comorbidities Cohort');
		   title 'Table 17. Association between receiving ≥30 ml/kg initial fluid and mortality among patients in each cohort, using different approaches to operationalizing the 30 ml/kg fluid volume';
         
run;

proc freq data = sample;
    where impute_weight = 0 and hypo_woutcomorb = 1;
	tables (Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure)*(mortality_30day)/ chisq fisher;
run;

proc freq data = sample;
    where impute_weight = 0 and hypo_wcomorb = 1;
	tables (Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure)*(mortality_30day)/ chisq fisher;
run;

proc freq data = sample;
    where impute_weight = 0 and interlact_woutcomorb = 1;
	tables (Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure)*(mortality_30day)/ chisq fisher;
run;

proc freq data = sample;
    where impute_weight = 0 and interlact_wcomorb = 1;
	tables (Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure)*(mortality_30day)/ chisq fisher;
run;

/* Running Models in STATA to calculate Risk differences  - General Code used below, See STATA Do file for specific code */
/* import sas using "sample_wgts_29oct2025.sas7bdat", clear */
/* keep if ([GROUP] == 1) */
/* melogit mortality_30day ib0.[fluidmeasure] c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight= [WEIGHT VAR] ] || [HOSPITAL VAR]: , or */
/* margins [fluidmeasure], post */
/* nlcom _b[1.[fluidmeasure]] / _b[0.[fluidmeasure]] */ *risk ratio;
/* nlcom _b[1.[fluidmeasure]] - _b[0.[fluidmeasure]] */ *risk difference;


ods excel close; 

/***************************************************************************************************************************************************************/
/*********************************************************************** Table 20 *******************************************************************************/
/***************************************************************************************************************************************************************/


ods excel file="Table 19 &sysdate9..xlsx" style=HTMLblue;
ods excel options(sheet_name='Table 3 Raw' sheet_interval="page" embedded_titles = 'yes' embedded_footnotes = 'yes');
/* Create a table that gets the counts for the hospital demographic variables - variables where we want counts/percentages */
proc tabulate data = sample out = Table1 missing;
    where deathin6 = 0;
	class Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure hypo_woutcomorb hypo_wcomorb interlact_woutcomorb interlact_wcomorb;
	table /*Row Variables */
            Pragmaticfluidmeasure = 'Pragmatic Approach'
            SEP1fluidmeasure = 'SEP-1 Approach'
            Tailoredfluidmeasure = 'Tailored Approach'
            ,

		   /* Subgroups - Column Variables */
		   N /* Geting the total for each Row Variable */
		   /* Getting the values within each rows subgroup */ 
           N*(hypo_woutcomorb = 'Hypoperfused without Comorbidities Cohort'
              hypo_wcomorb = 'Hypoperfused with Comorbidities Cohort'
              interlact_woutcomorb = 'Intermediate Lactate without Comorbidities Cohort'
              interlact_wcomorb = 'Intermediate Lactate with Comorbidities Cohort');
		   title 'Table 17. Association between receiving ≥30 ml/kg initial fluid and mortality among patients in each cohort, using different approaches to operationalizing the 30 ml/kg fluid volume';
         
run;

proc freq data = sample;
    where deathin6 = 0 and hypo_woutcomorb = 1;
	tables (Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure)*(mortality_30day)/ chisq fisher;
run;

proc freq data = sample;
    where deathin6 = 0 and hypo_wcomorb = 1;
	tables (Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure)*(mortality_30day)/ chisq fisher;
run;

proc freq data = sample;
    where deathin6 = 0 and interlact_woutcomorb = 1;
	tables (Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure)*(mortality_30day)/ chisq fisher;
run;

proc freq data = sample;
    where deathin6 = 0 and interlact_wcomorb = 1;
	tables (Pragmaticfluidmeasure SEP1fluidmeasure Tailoredfluidmeasure)*(mortality_30day)/ chisq fisher;
run;

/* Running Models in STATA to calculate Risk differences  - General Code used below, See STATA Do file for specific code */
/* import sas using "sample_wgts_29oct2025.sas7bdat", clear */
/* keep if ([GROUP] == 1) */
/* melogit mortality_30day ib0.[fluidmeasure] c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight= [WEIGHT VAR] ] || [HOSPITAL VAR]: , or */
/* margins [fluidmeasure], post */
/* nlcom _b[1.[fluidmeasure]] / _b[0.[fluidmeasure]] */ *risk ratio;
/* nlcom _b[1.[fluidmeasure]] - _b[0.[fluidmeasure]] */ *risk difference;


ods excel close; 


/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/
/*********************************************************************** Categorical Fluids *******************************************************************************/
/***************************************************************************************************************************************************************/

/* Table 21 */
/* Running Models in STATA to calculate Risk differences  - General Code used below, See STATA Do file for specific code */
/* import sas using "sample_wgts_29oct2025.sas7bdat", clear */
/* keep if ([GROUP] == 1) */
/* melogit mortality_30day ib0.[fluidmeasure_cat] c.spl_age? male postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mortality_predicted c.spl_BMI? c.spl_lactate? c.spl_creatinine? c.spl_ratiomin? mechvent_6hr vaso_6hrs alter_mental_status Charlson ib2.max_temp min_sysBP ib1.max_RR ib2.max_HR c.spl_WBCday3? bilirubin_sq c.spl_platelet? [pweight= [WEIGHT VAR] ] || [HOSPITAL VAR]: , or */
/* margins [fluidmeasure_cat], post */
/* nlcom _b[2.[fluidmeasure_cat]] - _b[1.[fluidmeasure_cat]] */ *risk difference group 2 - group 1;
/* nlcom _b[3.[fluidmeasure_cat]] - _b[1.[fluidmeasure_cat]] */ *risk difference group 3 - group 1;
/* nlcom _b[4.[fluidmeasure_cat]] - _b[1.[fluidmeasure_cat]] */ *risk difference group 4 - group 1;
/* nlcom _b[5.[fluidmeasure_cat]] - _b[1.[fluidmeasure_cat]] */ *risk difference group 5 - group 1;
/* nlcom _b[6.[fluidmeasure_cat]] - _b[1.[fluidmeasure_cat]] */ *risk difference group 6 - group 1;



/* Table 22 */
/**************************** Variable Counts ****************************/
ods excel file="Categorical Fluids Counts &sysdate9..xlsx" style=HTMLblue;
ods excel options(sheet_name='Table 2 Raw' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc tabulate data = sample out = Table_2 missing;
    where hypo_woutcomorb = 1;
	class male KidneyDisease CHF Tailoredfluidmeasure_cat CMI13;
	table /*Row Variables */
            male = 'Male sex, N(%)'
            KidneyDisease = 'Kidney disease (moderate/severe), N(%)'
            CHF = 'Congestive heart failure, N(%)'
            CMI13 = ' Complicated Diabetes'

           ,
		   /* Getting the values within each rows subgroup */ 
           N*(Tailoredfluidmeasure_cat = 'Categorical Tailored Approach' );
		   title 'Table 14: Key patient characteristics by groups. ';
         
run;

/* Values for Continuous Variables - for each cohort */
proc means data = sample median p25 p75 NMISS;
    where hypo_woutcomorb = 1;
    class Tailoredfluidmeasure_cat;
    var age charlson mortality_predicted;
run;

ods excel close;

/***************************************************************************************************************************************************************/


/***************************************************************************************************************************************************************/
/*********************************************************************** OG Table 1 *******************************************************************************/
/***************************************************************************************************************************************************************/

/* Total cohort with tailored appraoch */

/**************************** Variable Counts ****************************/
ods excel file="Table 2 Counts &sysdate9..xlsx" style=HTMLblue;
ods excel options(sheet_name='Table 2 Raw' sheet_interval="proc" embedded_titles = 'yes' embedded_footnotes = 'yes');
proc tabulate data = sample out = Table_2 missing;
	class male BMI_underweight BMI_normaltooverweight BMI_Obese BMI_sevObese postacutecare priorhosp KidneyDisease LiverDisease CHF Malignancy mechvent_6hr alter_mental_status vaso_6hrs VentEjeFrac aortstenosis renal_disease total_cohort Tailoredfluidmeasure;
	table /*Row Variables */
            male = 'Male sex, N(%)'
            BMI_underweight = 'BMI <18.5, N(%)'
            BMI_normaltooverweight = 'BMI 18.5-30, N(%)'
            BMI_Obese = 'BMI >30, N(%)'
            BMI_sevObese = 'BMI >40, N(%)'
            postacutecare = 'Admission from post-acute care, N(%)'
            priorhosp = 'Hospitalization in prior 90-days, N(%)'
            KidneyDisease = 'Kidney disease (moderate/severe), N(%)'
            LiverDisease = 'Liver disease (moderate/severe), N(%)'
            CHF = 'Congestive heart failure, N(%)'
            Malignancy = 'Malignancy, N(%)'
            mechvent_6hr = 'Mecahnical ventilation in 6 hours, N(%)'
            alter_mental_status = 'Altered Mental status on day 1, N(%)'
            vaso_6hrs = 'Vasopressors in 6 hours, N(%)'
            /* Specific Comorbidities */
            VentEjeFrac = 'EF <40% '
            aortstenosis = 'Severe AS '
            renal_disease = 'ESRD '

    	   
           ,
		   /* Getting the values within each rows subgroup */ 
           N*(total_cohort = 'Total'
              Tailoredfluidmeasure = "Met Tailored Measure");
		   title 'Table 2. Patient characteristics by patient subpopulation';
         
run;

/* Values for Continuous Variables - for each cohort */

proc means data = sample median p25 p75 NMISS;
    where total_cohort = 1;
    class Tailoredfluidmeasure;
    var age mortality_predicted lactatemax_draw creatinine_high ratio_min charlson max_temp min_sysBP max_RR max_HR WBC_high bilirubin_high platelets_low;
run;


proc means data = sample median p25 p75 NMISS;
    where total_cohort = 1;
    var age mortality_predicted lactatemax_draw creatinine_high ratio_min charlson max_temp min_sysBP max_RR max_HR WBC_high bilirubin_high platelets_low;
run;

proc ttest data = sample;
    where total_cohort = 1;
    class Tailoredfluidmeasure;
    var age mortality_predicted lactatemax_draw creatinine_high ratio_min charlson max_temp min_sysBP max_RR max_HR WBC_high bilirubin_high platelets_low;
run;
ods excel close;