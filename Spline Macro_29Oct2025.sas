/* Calculate splines for model */
/* Creatinine - 5 nodes */
proc univariate data=reg_sample1 noprint;
   var creatinine_high;
   output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;

data _null5_deriv_creat;
set pctls5_deriv_creat;
call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Lactate - 5 nodes */
proc univariate data=reg_sample1 noprint;
   var lactatemax_draw;
   output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_lact;
set pctls5_deriv_lact;
call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Platelets - 5 nodes */                  
proc univariate data=reg_sample1 noprint;
   var platelets_low;
   output out=pctls5_deriv_plate pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;

data _null5_deriv_plate;
set pctls5_deriv_plate;
call symput("pctls5_plate_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* BMI - 5 nodes */
proc univariate data=reg_sample1 noprint;
   var bmi_calculated;
   output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_bmi;
set pctls5_deriv_bmi;
call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* PF Ratio - 4 nodes */
proc univariate data=reg_sample1 noprint;
   var ratio_min;
   output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null4_deriv_ratio;
set pctls4_deriv_ratio;
call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Age - 4 nodes */
proc univariate data=reg_sample1 noprint;
   var age;
   output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null4_deriv_age;
set pctls4_deriv_age;
call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Highest WBC on day 3 - 5 nodes */
proc univariate data=reg_sample1 noprint;
   var WBC_high;
   output out=pctls5_deriv_WBC pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_WBC;
set pctls5_deriv_WBC;
call symput("pctls5_WBC_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;


/* Calculate splines for model 2*/
/* Creatinine - 5 nodes */
proc univariate data=reg_sample2 noprint;
   var creatinine_high;
   output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;

data _null5_deriv_creat;
set pctls5_deriv_creat;
call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Lactate - 5 nodes */
proc univariate data=reg_sample2 noprint;
   var lactatemax_draw;
   output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_lact;
set pctls5_deriv_lact;
call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Platelets - 5 nodes */                  
proc univariate data=reg_sample2 noprint;
   var platelets_low;
   output out=pctls5_deriv_plate pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;

data _null5_deriv_plate;
set pctls5_deriv_plate;
call symput("pctls5_plate_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* BMI - 5 nodes */
proc univariate data=reg_sample2 noprint;
   var bmi_calculated;
   output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_bmi;
set pctls5_deriv_bmi;
call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* PF Ratio - 4 nodes */
proc univariate data=reg_sample2 noprint;
   var ratio_min;
   output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null4_deriv_ratio;
set pctls4_deriv_ratio;
call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Age - 4 nodes */
proc univariate data=reg_sample2 noprint;
   var age;
   output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null4_deriv_age;
set pctls4_deriv_age;
call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Highest WBC on day 3 - 5 nodes */
proc univariate data=reg_sample2 noprint;
   var WBC_high;
   output out=pctls5_deriv_WBC pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_WBC;
set pctls5_deriv_WBC;
call symput("pctls5_WBC_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;


/* Calculate splines for model 3*/
/* Creatinine - 5 nodes */
proc univariate data=reg_sample3 noprint;
   var creatinine_high;
   output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;

data _null5_deriv_creat;
set pctls5_deriv_creat;
call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Lactate - 5 nodes */
proc univariate data=reg_sample3 noprint;
   var lactatemax_draw;
   output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_lact;
set pctls5_deriv_lact;
call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Platelets - 5 nodes */                  
proc univariate data=reg_sample3 noprint;
   var platelets_low;
   output out=pctls5_deriv_plate pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;

data _null5_deriv_plate;
set pctls5_deriv_plate;
call symput("pctls5_plate_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* BMI - 5 nodes */
proc univariate data=reg_sample3 noprint;
   var bmi_calculated;
   output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_bmi;
set pctls5_deriv_bmi;
call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* PF Ratio - 4 nodes */
proc univariate data=reg_sample3 noprint;
   var ratio_min;
   output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null4_deriv_ratio;
set pctls4_deriv_ratio;
call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Age - 4 nodes */
proc univariate data=reg_sample3 noprint;
   var age;
   output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null4_deriv_age;
set pctls4_deriv_age;
call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Highest WBC on day 3 - 5 nodes */
proc univariate data=reg_sample3 noprint;
   var WBC_high;
   output out=pctls5_deriv_WBC pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_WBC;
set pctls5_deriv_WBC;
call symput("pctls5_WBC_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;


/* Calculate splines for model 4*/
/* Creatinine - 5 nodes */
proc univariate data=reg_sample4 noprint;
   var creatinine_high;
   output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;

data _null5_deriv_creat;
set pctls5_deriv_creat;
call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Lactate - 5 nodes */
proc univariate data=reg_sample4 noprint;
   var lactatemax_draw;
   output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_lact;
set pctls5_deriv_lact;
call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Platelets - 5 nodes */                  
proc univariate data=reg_sample4 noprint;
   var platelets_low;
   output out=pctls5_deriv_plate pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;

data _null5_deriv_plate;
set pctls5_deriv_plate;
call symput("pctls5_plate_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* BMI - 5 nodes */
proc univariate data=reg_sample4 noprint;
   var bmi_calculated;
   output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_bmi;
set pctls5_deriv_bmi;
call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* PF Ratio - 4 nodes */
proc univariate data=reg_sample4 noprint;
   var ratio_min;
   output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null4_deriv_ratio;
set pctls4_deriv_ratio;
call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Age - 4 nodes */
proc univariate data=reg_sample4 noprint;
   var age;
   output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null4_deriv_age;
set pctls4_deriv_age;
call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Highest WBC on day 3 - 5 nodes */
proc univariate data=reg_sample4 noprint;
   var WBC_high;
   output out=pctls5_deriv_WBC pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_WBC;
set pctls5_deriv_WBC;
call symput("pctls5_WBC_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Sensitivity 1 */

/* Calculate splines for model 5*/
/* Creatinine - 5 nodes */
proc univariate data=reg_sample5 noprint;
   var creatinine_high;
   output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;

data _null5_deriv_creat;
set pctls5_deriv_creat;
call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Lactate - 5 nodes */
proc univariate data=reg_sample5 noprint;
   var lactatemax_draw;
   output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_lact;
set pctls5_deriv_lact;
call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Platelets - 5 nodes */                  
proc univariate data=reg_sample5 noprint;
   var platelets_low;
   output out=pctls5_deriv_plate pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;

data _null5_deriv_plate;
set pctls5_deriv_plate;
call symput("pctls5_plate_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* BMI - 5 nodes */
proc univariate data=reg_sample5 noprint;
   var bmi_calculated;
   output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_bmi;
set pctls5_deriv_bmi;
call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* PF Ratio - 4 nodes */
proc univariate data=reg_sample5 noprint;
   var ratio_min;
   output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null4_deriv_ratio;
set pctls4_deriv_ratio;
call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Age - 4 nodes */
proc univariate data=reg_sample5 noprint;
   var age;
   output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null4_deriv_age;
set pctls4_deriv_age;
call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Highest WBC on day 3 - 5 nodes */
proc univariate data=reg_sample5 noprint;
   var WBC_high;
   output out=pctls5_deriv_WBC pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_WBC;
set pctls5_deriv_WBC;
call symput("pctls5_WBC_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;



/* Calculate splines for model 6*/
/* Creatinine - 5 nodes */
proc univariate data=reg_sample6 noprint;
   var creatinine_high;
   output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;

data _null5_deriv_creat;
set pctls5_deriv_creat;
call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Lactate - 5 nodes */
proc univariate data=reg_sample6 noprint;
   var lactatemax_draw;
   output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_lact;
set pctls5_deriv_lact;
call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Platelets - 5 nodes */                  
proc univariate data=reg_sample6 noprint;
   var platelets_low;
   output out=pctls5_deriv_plate pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;

data _null5_deriv_plate;
set pctls5_deriv_plate;
call symput("pctls5_plate_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* BMI - 5 nodes */
proc univariate data=reg_sample6 noprint;
   var bmi_calculated;
   output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_bmi;
set pctls5_deriv_bmi;
call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* PF Ratio - 4 nodes */
proc univariate data=reg_sample6 noprint;
   var ratio_min;
   output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null4_deriv_ratio;
set pctls4_deriv_ratio;
call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Age - 4 nodes */
proc univariate data=reg_sample6 noprint;
   var age;
   output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null4_deriv_age;
set pctls4_deriv_age;
call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Highest WBC on day 3 - 5 nodes */
proc univariate data=reg_sample6 noprint;
   var WBC_high;
   output out=pctls5_deriv_WBC pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_WBC;
set pctls5_deriv_WBC;
call symput("pctls5_WBC_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;



/* Calculate splines for model 7*/
/* Creatinine - 5 nodes */
proc univariate data=reg_sample7 noprint;
   var creatinine_high;
   output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;

data _null5_deriv_creat;
set pctls5_deriv_creat;
call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Lactate - 5 nodes */
proc univariate data=reg_sample7 noprint;
   var lactatemax_draw;
   output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_lact;
set pctls5_deriv_lact;
call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Platelets - 5 nodes */                  
proc univariate data=reg_sample7 noprint;
   var platelets_low;
   output out=pctls5_deriv_plate pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;

data _null5_deriv_plate;
set pctls5_deriv_plate;
call symput("pctls5_plate_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* BMI - 5 nodes */
proc univariate data=reg_sample7 noprint;
   var bmi_calculated;
   output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_bmi;
set pctls5_deriv_bmi;
call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* PF Ratio - 4 nodes */
proc univariate data=reg_sample7 noprint;
   var ratio_min;
   output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null4_deriv_ratio;
set pctls4_deriv_ratio;
call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Age - 4 nodes */
proc univariate data=reg_sample7 noprint;
   var age;
   output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null4_deriv_age;
set pctls4_deriv_age;
call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Highest WBC on day 3 - 5 nodes */
proc univariate data=reg_sample7 noprint;
   var WBC_high;
   output out=pctls5_deriv_WBC pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_WBC;
set pctls5_deriv_WBC;
call symput("pctls5_WBC_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;



/* Calculate splines for model 8*/
/* Creatinine - 5 nodes */
proc univariate data=reg_sample8 noprint;
   var creatinine_high;
   output out=pctls5_deriv_creat pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;

data _null5_deriv_creat;
set pctls5_deriv_creat;
call symput('pctls5_creat_D',catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Lactate - 5 nodes */
proc univariate data=reg_sample8 noprint;
   var lactatemax_draw;
   output out=pctls5_deriv_lact pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_lact;
set pctls5_deriv_lact;
call symput("pctls5_lact_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Platelets - 5 nodes */                  
proc univariate data=reg_sample8 noprint;
   var platelets_low;
   output out=pctls5_deriv_plate pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;

data _null5_deriv_plate;
set pctls5_deriv_plate;
call symput("pctls5_plate_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* BMI - 5 nodes */
proc univariate data=reg_sample8 noprint;
   var bmi_calculated;
   output out=pctls5_deriv_bmi pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_bmi;
set pctls5_deriv_bmi;
call symput("pctls5_bmi_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* PF Ratio - 4 nodes */
proc univariate data=reg_sample8 noprint;
   var ratio_min;
   output out=pctls4_deriv_ratio pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null4_deriv_ratio;
set pctls4_deriv_ratio;
call symput("pctls4_ratio_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Age - 4 nodes */
proc univariate data=reg_sample8 noprint;
   var age;
   output out=pctls4_deriv_age pctlpts=5 35 65 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null4_deriv_age;
set pctls4_deriv_age;
call symput("pctls4_age_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

/* Highest WBC on day 3 - 5 nodes */
proc univariate data=reg_sample8 noprint;
   var WBC_high;
   output out=pctls5_deriv_WBC pctlpts=5 27.5 50 72.5 95 pctlpre=p_; /* specify the percentiles */

run;
 
data _null5_deriv_WBC;
set pctls5_deriv_WBC;
call symput("pctls5_WBC_D",catx(',', of _numeric_));   /* put all values into a comma-separated list */

run;

