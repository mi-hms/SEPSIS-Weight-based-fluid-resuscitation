version 18.5
set more off
cap log close
clear all
set linesize 80

cd ""

local c_date = c(current_date)
local date = subinstr("`c_date'", " ", "", .)

log using "", replace 

********************************************************************************
* HMS Sepsis - Fluid Analysis Project 
* Author: Sarah Seelye
*
* Date Created: 2025 Apr 25
* Last Updated: 2025 Nov 17
********************************************************************************

* import dataset from Emily
import sas using "Data\sample_wgts_06nov2025.sas7bdat", case(lower) clear
save "Data\sample_wgts_06nov2025.dta", replace	
	
* open dataset 
use "Data\sample_wgts_06nov2025.dta", clear


********************************************************************************
********************************************************************************

						*** TAILORED APPROACH ***

********************************************************************************
********************************************************************************
				

******************************
* Hypoperfused - Tailored
******************************

*--------------------------------------------------
* spline analysis & no specific comorbidities
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if hypoperfused==1 & specificcomorbid==0

sum tailoredsix, de

* fit model with different number of knots
mkspline sp_fluid_3nk = tailoredsix, cubic nknots(3)
mkspline sp_fluid_4nk = tailoredsix, cubic nknots(4)
mkspline sp_fluid_5nk = tailoredsix, cubic nknots(5)
				
logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_th]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_th]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_th]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*--------------------------------------------------
* spline analysis & specific comorbidities
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if hypoperfused==1 & specificcomorbid==1

sum tailoredsix, de

* fit model with different number of knots
mkspline sp_fluid_3nk = tailoredsix, cubic nknots(3)
mkspline sp_fluid_4nk = tailoredsix, cubic nknots(4)
mkspline sp_fluid_5nk = tailoredsix, cubic nknots(5)
		

logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_thc]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_thc]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_thc]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*---------------------------
* descriptive statistics  
*---------------------------

preserve

	keep if hypoperfused==1 & specificcomorbid==0

	svyset hosp [pweight=ps_weight_th]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 

preserve

	keep if hypoperfused==1 & specificcomorbid==1

	svyset hosp [pweight=ps_weight_thc]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 


*---------------------------------
* create twoway line graph 
*---------------------------------

preserve 

keep if hypoperfused==1

* no specific comorbidities
mkspline sp_fluid_noc = tailoredsix if specificcomorbid==0, cubic nknots(3)

_pctile tailoredsix if specificcomorbid==0, p(10 50 90)
display "10th percentile: " %9.3f r(r1)
display "50th percentile: " %9.3f r(r2)
display "90th percentile: " %9.3f r(r3)

svyset hosp [pweight=ps_weight_th]


local covar		age male postacutecare priorhosp kidneydisease 			///
				liverdisease chf malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_noc? `covar' if specificcomorbid==0

replace age = 69.6 if specificcomorbid==0
replace male=0.48 if specificcomorbid==0
replace postacutecare=0.17 if specificcomorbid==0
replace priorhosp=0.34 if specificcomorbid==0
replace kidneydisease=0.30 if specificcomorbid==0			
replace liverdisease=0.05 if specificcomorbid==0
replace chf=0.24 if specificcomorbid==0
replace malignancy=0.28 if specificcomorbid==0
replace mortality_predicted=0.29 if specificcomorbid==0	
replace bmi_calculated=28.49 if specificcomorbid==0
replace lactatemax_draw=4.53 if specificcomorbid==0
replace creatinine_high=2.12 if specificcomorbid==0			
replace ratio_min=291.19 if specificcomorbid==0
replace mechvent_6hr=0.14 if specificcomorbid==0
replace vaso_6hrs=0.30 if specificcomorbid==0
replace alter_mental_status=0.56 if specificcomorbid==0
replace charlson = 3.29 if specificcomorbid==0
replace max_temp = 2.48 if specificcomorbid==0
replace min_sysbp = 1.55 if specificcomorbid==0
replace max_rr = 3.33 if specificcomorbid==0
replace max_hr = 3.76 if specificcomorbid==0
replace wbc_high = 16.23 if specificcomorbid==0
replace bilirubin_high = 1.28 if specificcomorbid==0
replace platelets_low = 248.44 if specificcomorbid==0

predict pr_mort_noco if e(sample)==1
predict xb_noco if e(sample)==1, xb 
predict error_noco if e(sample)==1, stdp 

gen lb_noco = xb_noco - invnormal(0.975)*error_noco
gen ub_noco = xb_noco + invnormal(0.975)*error_noco
gen plb_noco = invlogit(lb_noco)
gen pub_noco = invlogit(ub_noco)


* with comorbidities
mkspline sp_fluid_c = tailoredsix if specificcomorbid==1, cubic nknots(3)

_pctile tailoredsix if specificcomorbid==1, p(10 50 90)
display "10th percentile: " %9.3f r(r1)
display "50th percentile: " %9.3f r(r2)
display "90th percentile: " %9.3f r(r3)

svyset hosp [pweight=ps_weight_thc]

local covar		age male postacutecare priorhosp kidneydisease 			///
				liverdisease chf malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_c? `covar' if specificcomorbid==1

replace age = 71.0 if specificcomorbid==1
replace male=0.58 if specificcomorbid==1
replace postacutecare=0.25 if specificcomorbid==1
replace priorhosp=0.56 if specificcomorbid==1
replace kidneydisease=0.69 if specificcomorbid==1			
replace liverdisease=0.05 if specificcomorbid==1
replace chf=0.67 if specificcomorbid==1
replace malignancy=0.26 if specificcomorbid==1
replace mortality_predicted=0.36 if specificcomorbid==1	
replace bmi_calculated=28.77 if specificcomorbid==1
replace lactatemax_draw=4.31 if specificcomorbid==1
replace creatinine_high=3.90 if specificcomorbid==1			
replace ratio_min=283.68 if specificcomorbid==1
replace mechvent_6hr=0.14 if specificcomorbid==1
replace vaso_6hrs=0.36 if specificcomorbid==1
replace alter_mental_status=0.58 if specificcomorbid==1
replace charlson = 4.71 if specificcomorbid==1
replace max_temp = 2.41 if specificcomorbid==1
replace min_sysbp = 1.48 if specificcomorbid==1
replace max_rr = 3.35 if specificcomorbid==1
replace max_hr = 3.50 if specificcomorbid==1
replace wbc_high = 15.18 if specificcomorbid==1
replace bilirubin_high = 1.28 if specificcomorbid==1
replace platelets_low = 226.6 if specificcomorbid==1

predict pr_mort_co if e(sample)==1
predict xb_co if e(sample)==1, xb 
predict error_co if e(sample)==1, stdp 

gen lb_co = xb_co - invnormal(0.975)*error_co
gen ub_co = xb_co + invnormal(0.975)*error_co
gen plb_co = invlogit(lb_co)
gen pub_co = invlogit(ub_co)

rename plb_co plb1 
rename pub_co pub1
rename pr_mort_co pr_mort1 
rename plb_noco plb0
rename pub_noco pub0 
rename pr_mort_noco pr_mort0
							   
foreach var in plb1 pub1 pr_mort1 plb0 pub0 pr_mort0 {
	gen `var'_pct = `var'*100
}

gen byte include = tailoredsix <= 80						   				   
sort tailoredsix	
graph twoway (rarea plb1_pct pub1_pct tailoredsix if include, fcolor("0 114 178*0.80") lwidth(none)) ///
				(line pr_mort1_pct tailoredsix if include,			///
						title("Hypoperfused", size(medlarge))	///
						xtitle("Fluid in first 6 hrs (ml/kg)", size(med) margin(medium)) ///
						ytitle("Probability 30-day mortality (%)", size(med) margin(medium)) ///
						yscale(range(0 40)) ylabel(0(10)40) ///
						lcolor("0 114 178*1.25"))  	///						
			 || (rarea plb0_pct pub0_pct tailoredsix if include, fcolor("230 159 0*0.70") lwidth(none)) ///
					(line pr_mort0_pct tailoredsix if include, lcolor("230 159 0*1.5") lpattern(dash))	///
			 || , legend(order(2 "with" "specified" "comorbidities" 4 "without" "specified" "comorbidities" )	///
					symysize (6) size(small)) name("hypo", replace)			
				
restore


********************************************************************************


******************************************
* Intermediate Lactate - Tailored
******************************************

*--------------------------------------------------
* spline analysis & no specific comorbidities
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if intermediate_lactate==1 & specificcomorbid==0

sum tailoredsix, de

* fit model with different number of knots
mkspline sp_fluid_3nk = tailoredsix, cubic nknots(3)
mkspline sp_fluid_4nk = tailoredsix, cubic nknots(4)
mkspline sp_fluid_5nk = tailoredsix, cubic nknots(5)
				
logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_ti]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_ti]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_ti]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*--------------------------------------------------
* spline analysis & specific comorbidities
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if intermediate_lactate==1 & specificcomorbid==1

sum tailoredsix, de

* fit model with different number of knots
mkspline sp_fluid_3nk = tailoredsix, cubic nknots(3)
mkspline sp_fluid_4nk = tailoredsix, cubic nknots(4)
mkspline sp_fluid_5nk = tailoredsix, cubic nknots(5)
		
logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_tic]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_tic]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_tic]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) //4 knots w/ lowest AIC/BIC

restore 

*---------------------------
* descriptive statistics  
*---------------------------

preserve

	keep if intermediate_lactate==1 & specificcomorbid==0

	svyset hosp [pweight=ps_weight_ti]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 

preserve

	keep if intermediate_lactate==1 & specificcomorbid==1

	svyset hosp [pweight=ps_weight_tic]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 


*---------------------------------
* create twoway line graph 
*---------------------------------

preserve 

keep if intermediate_lactate==1

* no specific comorbidities
mkspline sp_fluid_noc = tailoredsix if specificcomorbid==0, cubic nknots(3)

_pctile tailoredsix if specificcomorbid==0, p(10 50 90)
display "10th percentile: " %9.3f r(r1)
display "50th percentile: " %9.3f r(r2)
display "90th percentile: " %9.3f r(r3)

svyset hosp [pweight=ps_weight_ti]


local covar		age male postacutecare priorhosp kidneydisease 			///
				liverdisease chf malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_noc? `covar' if specificcomorbid==0

replace age = 68.9 if specificcomorbid==0
replace male=0.51 if specificcomorbid==0
replace postacutecare=0.11 if specificcomorbid==0
replace priorhosp=0.30 if specificcomorbid==0
replace kidneydisease=0.25 if specificcomorbid==0			
replace liverdisease=0.03 if specificcomorbid==0
replace chf=0.22 if specificcomorbid==0
replace malignancy=0.26 if specificcomorbid==0
replace mortality_predicted=0.14 if specificcomorbid==0	
replace bmi_calculated=29.7 if specificcomorbid==0
replace lactatemax_draw=2.81 if specificcomorbid==0
replace creatinine_high=1.37 if specificcomorbid==0			
replace ratio_min=327.49 if specificcomorbid==0
replace mechvent_6hr=0.03 if specificcomorbid==0
replace vaso_6hrs=0.01 if specificcomorbid==0
replace alter_mental_status=0.36 if specificcomorbid==0
replace charlson = 2.97 if specificcomorbid==0
replace max_temp = 2.90 if specificcomorbid==0
replace min_sysbp = 2.83 if specificcomorbid==0
replace max_rr = 3.00 if specificcomorbid==0
replace max_hr = 3.89 if specificcomorbid==0
replace wbc_high = 15.40 if specificcomorbid==0
replace bilirubin_high = 1.04 if specificcomorbid==0
replace platelets_low = 256.66 if specificcomorbid==0

predict pr_mort_noco if e(sample)==1
predict xb_noco if e(sample)==1, xb 
predict error_noco if e(sample)==1, stdp 

gen lb_noco = xb_noco - invnormal(0.975)*error_noco
gen ub_noco = xb_noco + invnormal(0.975)*error_noco
gen plb_noco = invlogit(lb_noco)
gen pub_noco = invlogit(ub_noco)


* with comorbidities
mkspline sp_fluid_c = tailoredsix if specificcomorbid==1, cubic nknots(3)

_pctile tailoredsix if specificcomorbid==1, p(10 50 90)
display "10th percentile: " %9.3f r(r1)
display "50th percentile: " %9.3f r(r2)
display "90th percentile: " %9.3f r(r3)

svyset hosp [pweight=ps_weight_tic]

local covar		age male postacutecare priorhosp kidneydisease 			///
				liverdisease chf malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_c? `covar' if specificcomorbid==1

replace age = 70.46 if specificcomorbid==1
replace male=0.59 if specificcomorbid==1
replace postacutecare=0.14 if specificcomorbid==1
replace priorhosp=0.49 if specificcomorbid==1
replace kidneydisease=0.67 if specificcomorbid==1			
replace liverdisease=0.02 if specificcomorbid==1
replace chf=0.60 if specificcomorbid==1
replace malignancy=0.24 if specificcomorbid==1
replace mortality_predicted=0.20 if specificcomorbid==1	
replace bmi_calculated=28.58 if specificcomorbid==1
replace lactatemax_draw=2.81 if specificcomorbid==1
replace creatinine_high=4.88 if specificcomorbid==1			
replace ratio_min=312.21 if specificcomorbid==1
replace mechvent_6hr=0.03 if specificcomorbid==1
replace vaso_6hrs=0.02 if specificcomorbid==1
replace alter_mental_status=0.43 if specificcomorbid==1
replace charlson = 4.59 if specificcomorbid==1
replace max_temp = 2.83 if specificcomorbid==1
replace min_sysbp = 2.83 if specificcomorbid==1
replace max_rr = 3.10 if specificcomorbid==1
replace max_hr = 3.69 if specificcomorbid==1
replace wbc_high = 14.56 if specificcomorbid==1
replace bilirubin_high = 0.99 if specificcomorbid==1
replace platelets_low = 239.81 if specificcomorbid==1

predict pr_mort_co if e(sample)==1
predict xb_co if e(sample)==1, xb 
predict error_co if e(sample)==1, stdp 

gen lb_co = xb_co - invnormal(0.975)*error_co
gen ub_co = xb_co + invnormal(0.975)*error_co
gen plb_co = invlogit(lb_co)
gen pub_co = invlogit(ub_co)

rename plb_co plb1 
rename pub_co pub1
rename pr_mort_co pr_mort1 
rename plb_noco plb0
rename pub_noco pub0 
rename pr_mort_noco pr_mort0
							   
foreach var in plb1 pub1 pr_mort1 plb0 pub0 pr_mort0 {
	gen `var'_pct = `var'*100
}

gen byte include = tailoredsix <= 80						   				   
sort tailoredsix	
graph twoway (rarea plb1_pct pub1_pct tailoredsix if include, fcolor("0 114 178*0.80") lwidth(none)) ///
				(line pr_mort1_pct tailoredsix if include,			///
						title("Intermediate Lactate", size(medlarge))	///
						xtitle("Fluid in first 6 hrs (ml/kg)", size(med) margin(medium)) ///
						ytitle("Probability 30-day mortality (%)", size(med) margin(medium)) ///
						yscale(range(0 40)) ylabel(0(10)40) ///
						lcolor("0 114 178*1.25"))  	///						
			 || (rarea plb0_pct pub0_pct tailoredsix if include, fcolor("230 159 0*0.70") lwidth(none)) ///
					(line pr_mort0_pct tailoredsix if include, lcolor("230 159 0*1.5") lpattern(dash))	///
			 || , legend(order(2 "with" "specified" "comorbidities" 4 "without" "specified" "comorbidities" )	///
					symysize (6) size(small)) name("lactate", replace)			
					
restore



********************************************************************************
********************************************************************************

						*** SEP-1 APPROACH ***

********************************************************************************
********************************************************************************


******************************
* Hypoperfused - SEP-1
******************************

*--------------------------------------------------
* spline analysis & no specific comorbidities
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if hypoperfused==1 & specificcomorbid==0

sum sep1six, de

* fit model with different number of knots
mkspline sp_fluid_3nk = sep1six, cubic nknots(3)
mkspline sp_fluid_4nk = sep1six, cubic nknots(4)
mkspline sp_fluid_5nk = sep1six, cubic nknots(5)
				
logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_sh]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_sh]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_sh]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*--------------------------------------------------
* spline analysis & specific comorbidities
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if hypoperfused==1 & specificcomorbid==1

sum sep1six, de

* fit model with different number of knots
mkspline sp_fluid_3nk = sep1six, cubic nknots(3)
mkspline sp_fluid_4nk = sep1six, cubic nknots(4)
mkspline sp_fluid_5nk = sep1six, cubic nknots(5)
		

logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_shc]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_shc]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_shc]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*---------------------------
* descriptive statistics  
*---------------------------

preserve

	keep if hypoperfused==1 & specificcomorbid==0

	svyset hosp [pweight=ps_weight_sh]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 

preserve

	keep if hypoperfused==1 & specificcomorbid==1

	svyset hosp [pweight=ps_weight_shc]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 


*---------------------------------
* create twoway line graph 
*---------------------------------

preserve 

keep if hypoperfused==1

* no specific comorbidities
mkspline sp_fluid_noc = sep1six if specificcomorbid==0, cubic nknots(3)

svyset hosp [pweight=ps_weight_sh]


local covar		age male postacutecare priorhosp kidneydisease 			///
				liverdisease chf malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_noc? `covar' if specificcomorbid==0

replace age = 69.6 if specificcomorbid==0
replace male=0.48 if specificcomorbid==0
replace postacutecare=0.17 if specificcomorbid==0
replace priorhosp=0.34 if specificcomorbid==0
replace kidneydisease=0.30 if specificcomorbid==0			
replace liverdisease=0.05 if specificcomorbid==0
replace chf=0.24 if specificcomorbid==0
replace malignancy=0.28 if specificcomorbid==0
replace mortality_predicted=0.29 if specificcomorbid==0	
replace bmi_calculated=28.56 if specificcomorbid==0
replace lactatemax_draw=4.50 if specificcomorbid==0
replace creatinine_high=2.11 if specificcomorbid==0			
replace ratio_min=291.30 if specificcomorbid==0
replace mechvent_6hr=0.14 if specificcomorbid==0
replace vaso_6hrs=0.30 if specificcomorbid==0
replace alter_mental_status=0.55 if specificcomorbid==0
replace charlson = 3.29 if specificcomorbid==0
replace max_temp = 2.48 if specificcomorbid==0
replace min_sysbp = 1.56 if specificcomorbid==0
replace max_rr = 3.34 if specificcomorbid==0
replace max_hr = 3.76 if specificcomorbid==0
replace wbc_high = 16.55 if specificcomorbid==0
replace bilirubin_high = 1.29 if specificcomorbid==0
replace platelets_low = 248.30 if specificcomorbid==0

predict pr_mort_noco if e(sample)==1
predict xb_noco if e(sample)==1, xb 
predict error_noco if e(sample)==1, stdp 

gen lb_noco = xb_noco - invnormal(0.975)*error_noco
gen ub_noco = xb_noco + invnormal(0.975)*error_noco
gen plb_noco = invlogit(lb_noco)
gen pub_noco = invlogit(ub_noco)


* with comorbidities
mkspline sp_fluid_c = sep1six if specificcomorbid==1, cubic nknots(3)

svyset hosp [pweight=ps_weight_shc]

local covar		age male postacutecare priorhosp kidneydisease 			///
				liverdisease chf malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_c? `covar' if specificcomorbid==1

replace age = 71.0 if specificcomorbid==1
replace male=0.59 if specificcomorbid==1
replace postacutecare=0.24 if specificcomorbid==1
replace priorhosp=0.56 if specificcomorbid==1
replace kidneydisease=0.69 if specificcomorbid==1			
replace liverdisease=0.05 if specificcomorbid==1
replace chf=0.67 if specificcomorbid==1
replace malignancy=0.26 if specificcomorbid==1
replace mortality_predicted=0.35 if specificcomorbid==1	
replace bmi_calculated=28.75 if specificcomorbid==1
replace lactatemax_draw=4.22 if specificcomorbid==1
replace creatinine_high=3.96 if specificcomorbid==1			
replace ratio_min=285.75 if specificcomorbid==1
replace mechvent_6hr=0.14 if specificcomorbid==1
replace vaso_6hrs=0.35 if specificcomorbid==1
replace alter_mental_status=0.57 if specificcomorbid==1
replace charlson = 4.71 if specificcomorbid==1
replace max_temp = 2.40 if specificcomorbid==1
replace min_sysbp = 1.48 if specificcomorbid==1
replace max_rr = 3.33 if specificcomorbid==1
replace max_hr = 3.49 if specificcomorbid==1
replace wbc_high = 15.13 if specificcomorbid==1
replace bilirubin_high = 1.27 if specificcomorbid==1
replace platelets_low = 224.4 if specificcomorbid==1

predict pr_mort_co if e(sample)==1
predict xb_co if e(sample)==1, xb 
predict error_co if e(sample)==1, stdp 

gen lb_co = xb_co - invnormal(0.975)*error_co
gen ub_co = xb_co + invnormal(0.975)*error_co
gen plb_co = invlogit(lb_co)
gen pub_co = invlogit(ub_co)

rename plb_co plb1 
rename pub_co pub1
rename pr_mort_co pr_mort1 
rename plb_noco plb0
rename pub_noco pub0 
rename pr_mort_noco pr_mort0
							   
foreach var in plb1 pub1 pr_mort1 plb0 pub0 pr_mort0 {
	gen `var'_pct = `var'*100
}

gen byte include = sep1six <= 80						   				   
sort sep1six	
graph twoway (rarea plb1_pct pub1_pct sep1six if include, fcolor("0 114 178*0.80") lwidth(none)) ///
				(line pr_mort1_pct sep1six if include,			///
						title("Hypoperfused", size(medlarge))	///
						xtitle("Fluid in first 6 hrs (ml/kg)", size(med) margin(medium)) ///
						ytitle("Probability 30-day mortality (%)", size(med) margin(medium)) ///
						yscale(range(0 40)) ylabel(0(10)60) ///
						lcolor("0 114 178*1.25"))  	///						
			 || (rarea plb0_pct pub0_pct sep1six if include, fcolor("230 159 0*0.70") lwidth(none)) ///
					(line pr_mort0_pct sep1six if include, lcolor("230 159 0*1.5") lpattern(dash))	///
			 || , legend(order(2 "with" "specified" "comorbidities" 4 "without" "specified" "comorbidities" )	///
					symysize (6) size(small)) name("hyposep1", replace)			
				
restore


********************************************************************************


******************************************
* Intermediate Lactate - SEP-1
******************************************

*--------------------------------------------------
* spline analysis & no specific comorbidities
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if intermediate_lactate==1 & specificcomorbid==0

sum sep1six, de

* fit model with different number of knots
mkspline sp_fluid_3nk = sep1six, cubic nknots(3)
mkspline sp_fluid_4nk = sep1six, cubic nknots(4)
mkspline sp_fluid_5nk = sep1six, cubic nknots(5)
				
logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_si]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_si]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_si]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*--------------------------------------------------
* spline analysis & specific comorbidities
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if intermediate_lactate==1 & specificcomorbid==1

sum sep1six, de

* fit model with different number of knots
mkspline sp_fluid_3nk = sep1six, cubic nknots(3)
mkspline sp_fluid_4nk = sep1six, cubic nknots(4)
mkspline sp_fluid_5nk = sep1six, cubic nknots(5)
		
logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_sic]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_sic]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_sic]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*---------------------------
* descriptive statistics  
*---------------------------

preserve

	keep if intermediate_lactate==1 & specificcomorbid==0

	svyset hosp [pweight=ps_weight_si]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 

preserve

	keep if intermediate_lactate==1 & specificcomorbid==1

	svyset hosp [pweight=ps_weight_sic]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 


*---------------------------------
* create twoway line graph 
*---------------------------------

preserve 

keep if intermediate_lactate==1

* no specific comorbidities
mkspline sp_fluid_noc = sep1six if specificcomorbid==0, cubic nknots(3)

svyset hosp [pweight=ps_weight_si]


local covar		age male postacutecare priorhosp kidneydisease 			///
				liverdisease chf malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_noc? `covar' if specificcomorbid==0

replace age = 68.9 if specificcomorbid==0
replace male=0.51 if specificcomorbid==0
replace postacutecare=0.11 if specificcomorbid==0
replace priorhosp=0.30 if specificcomorbid==0
replace kidneydisease=0.25 if specificcomorbid==0			
replace liverdisease=0.03 if specificcomorbid==0
replace chf=0.22 if specificcomorbid==0
replace malignancy=0.26 if specificcomorbid==0
replace mortality_predicted=0.14 if specificcomorbid==0	
replace bmi_calculated=29.6 if specificcomorbid==0
replace lactatemax_draw=2.80 if specificcomorbid==0
replace creatinine_high=1.37 if specificcomorbid==0			
replace ratio_min=328.20 if specificcomorbid==0
replace mechvent_6hr=0.03 if specificcomorbid==0
replace vaso_6hrs=0.01 if specificcomorbid==0
replace alter_mental_status=0.36 if specificcomorbid==0
replace charlson = 2.97 if specificcomorbid==0
replace max_temp = 2.91 if specificcomorbid==0
replace min_sysbp = 2.83 if specificcomorbid==0
replace max_rr = 3.00 if specificcomorbid==0
replace max_hr = 3.89 if specificcomorbid==0
replace wbc_high = 15.45 if specificcomorbid==0
replace bilirubin_high = 1.04 if specificcomorbid==0
replace platelets_low = 257.37 if specificcomorbid==0

predict pr_mort_noco if e(sample)==1
predict xb_noco if e(sample)==1, xb 
predict error_noco if e(sample)==1, stdp 

gen lb_noco = xb_noco - invnormal(0.975)*error_noco
gen ub_noco = xb_noco + invnormal(0.975)*error_noco
gen plb_noco = invlogit(lb_noco)
gen pub_noco = invlogit(ub_noco)


* with comorbidities
mkspline sp_fluid_c = sep1six if specificcomorbid==1, cubic nknots(3)

svyset hosp [pweight=ps_weight_sic]

local covar		age male postacutecare priorhosp kidneydisease 			///
				liverdisease chf malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_c? `covar' if specificcomorbid==1

replace age = 70.9 if specificcomorbid==1
replace male=0.58 if specificcomorbid==1
replace postacutecare=0.14 if specificcomorbid==1
replace priorhosp=0.47 if specificcomorbid==1
replace kidneydisease=0.67 if specificcomorbid==1			
replace liverdisease=0.02 if specificcomorbid==1
replace chf=0.62 if specificcomorbid==1
replace malignancy=0.24 if specificcomorbid==1
replace mortality_predicted=0.20 if specificcomorbid==1	
replace bmi_calculated=28.6 if specificcomorbid==1
replace lactatemax_draw=2.81 if specificcomorbid==1
replace creatinine_high=4.88 if specificcomorbid==1			
replace ratio_min=314.19 if specificcomorbid==1
replace mechvent_6hr=0.03 if specificcomorbid==1
replace vaso_6hrs=0.03 if specificcomorbid==1
replace alter_mental_status=0.42 if specificcomorbid==1
replace charlson = 4.56 if specificcomorbid==1
replace max_temp = 2.81 if specificcomorbid==1
replace min_sysbp = 2.82 if specificcomorbid==1
replace max_rr = 3.10 if specificcomorbid==1
replace max_hr = 3.69 if specificcomorbid==1
replace wbc_high = 14.57 if specificcomorbid==1
replace bilirubin_high = 1.00 if specificcomorbid==1
replace platelets_low = 241.20 if specificcomorbid==1

predict pr_mort_co if e(sample)==1
predict xb_co if e(sample)==1, xb 
predict error_co if e(sample)==1, stdp 

gen lb_co = xb_co - invnormal(0.975)*error_co
gen ub_co = xb_co + invnormal(0.975)*error_co
gen plb_co = invlogit(lb_co)
gen pub_co = invlogit(ub_co)

rename plb_co plb1 
rename pub_co pub1
rename pr_mort_co pr_mort1 
rename plb_noco plb0
rename pub_noco pub0 
rename pr_mort_noco pr_mort0
							   
foreach var in plb1 pub1 pr_mort1 plb0 pub0 pr_mort0 {
	gen `var'_pct = `var'*100
}

gen byte include = sep1six <= 80						   				   
sort sep1six	
graph twoway (rarea plb1_pct pub1_pct sep1six if include, fcolor("0 114 178*0.80") lwidth(none)) ///
				(line pr_mort1_pct sep1six if include,			///
						title("Intermediate Lactate", size(medlarge))	///
						xtitle("Fluid in first 6 hrs (ml/kg)", size(med) margin(medium)) ///
						ytitle("Probability 30-day mortality (%)", size(med) margin(medium)) ///
						yscale(range(0 40)) ylabel(0(10)60) ///
						lcolor("0 114 178*1.25"))  	///						
			 || (rarea plb0_pct pub0_pct sep1six if include, fcolor("230 159 0*0.70") lwidth(none)) ///
					(line pr_mort0_pct sep1six if include, lcolor("230 159 0*1.5") lpattern(dash))	///
			 || , legend(order(2 "with" "specified" "comorbidities" 4 "without" "specified" "comorbidities" )	///
					symysize (6) size(small)) name("lactatesep1", replace)			
						
restore

				


********************************************************************************
********************************************************************************

						*** PRAGMATIC APPROACH ***

********************************************************************************
********************************************************************************


******************************
* Hypoperfused - PRAGMATIC
******************************

*--------------------------------------------------
* spline analysis & no specific comorbidities
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if hypoperfused==1 & specificcomorbid==0

sum pragmaticsix, de

* fit model with different number of knots
mkspline sp_fluid_3nk = pragmaticsix, cubic nknots(3)
mkspline sp_fluid_4nk = pragmaticsix, cubic nknots(4)
mkspline sp_fluid_5nk = pragmaticsix, cubic nknots(5)
				
logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_ph]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_ph]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_ph]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2))  

restore 

*--------------------------------------------------
* spline analysis & specific comorbidities
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if hypoperfused==1 & specificcomorbid==1

sum pragmaticsix, de

* fit model with different number of knots
mkspline sp_fluid_3nk = pragmaticsix, cubic nknots(3)
mkspline sp_fluid_4nk = pragmaticsix, cubic nknots(4)
mkspline sp_fluid_5nk = pragmaticsix, cubic nknots(5)
		

logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_phc]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_phc]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_phc]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*---------------------------
* descriptive statistics  
*---------------------------

preserve

	keep if hypoperfused==1 & specificcomorbid==0

	svyset hosp [pweight=ps_weight_ph]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 

preserve

	keep if hypoperfused==1 & specificcomorbid==1

	svyset hosp [pweight=ps_weight_phc]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 


*---------------------------------
* create twoway line graph 
*---------------------------------

preserve 

keep if hypoperfused==1

* no specific comorbidities
mkspline sp_fluid_noc = pragmaticsix if specificcomorbid==0, cubic nknots(3)

svyset hosp [pweight=ps_weight_ph]


local covar		age male postacutecare priorhosp kidneydisease 			///
				liverdisease chf malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_noc? `covar' if specificcomorbid==0

replace age = 69.6 if specificcomorbid==0
replace male=0.48 if specificcomorbid==0
replace postacutecare=0.17 if specificcomorbid==0
replace priorhosp=0.34 if specificcomorbid==0
replace kidneydisease=0.30 if specificcomorbid==0			
replace liverdisease=0.05 if specificcomorbid==0
replace chf=0.24 if specificcomorbid==0
replace malignancy=0.28 if specificcomorbid==0
replace mortality_predicted=0.29 if specificcomorbid==0	
replace bmi_calculated=28.6 if specificcomorbid==0
replace lactatemax_draw=4.5 if specificcomorbid==0
replace creatinine_high=2.1 if specificcomorbid==0			
replace ratio_min=291.6 if specificcomorbid==0
replace mechvent_6hr=0.14 if specificcomorbid==0
replace vaso_6hrs=0.30 if specificcomorbid==0
replace alter_mental_status=0.56 if specificcomorbid==0
replace charlson = 3.29 if specificcomorbid==0
replace max_temp = 2.49 if specificcomorbid==0
replace min_sysbp = 1.56 if specificcomorbid==0
replace max_rr = 3.33 if specificcomorbid==0
replace max_hr = 3.75 if specificcomorbid==0
replace wbc_high = 16.29 if specificcomorbid==0
replace bilirubin_high = 1.28 if specificcomorbid==0
replace platelets_low = 248.4 if specificcomorbid==0

predict pr_mort_noco if e(sample)==1
predict xb_noco if e(sample)==1, xb 
predict error_noco if e(sample)==1, stdp 

gen lb_noco = xb_noco - invnormal(0.975)*error_noco
gen ub_noco = xb_noco + invnormal(0.975)*error_noco
gen plb_noco = invlogit(lb_noco)
gen pub_noco = invlogit(ub_noco)


* with comorbidities
mkspline sp_fluid_c = pragmaticsix if specificcomorbid==1, cubic nknots(3)

svyset hosp [pweight=ps_weight_phc]

local covar		age male postacutecare priorhosp kidneydisease 			///
				liverdisease chf malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_c? `covar' if specificcomorbid==1

replace age = 71.2 if specificcomorbid==1
replace male=0.58 if specificcomorbid==1
replace postacutecare=0.24 if specificcomorbid==1
replace priorhosp=0.56 if specificcomorbid==1
replace kidneydisease=0.69 if specificcomorbid==1			
replace liverdisease=0.04 if specificcomorbid==1
replace chf=0.66 if specificcomorbid==1
replace malignancy=0.26 if specificcomorbid==1
replace mortality_predicted=0.36 if specificcomorbid==1	
replace bmi_calculated=28.7 if specificcomorbid==1
replace lactatemax_draw=4.3 if specificcomorbid==1
replace creatinine_high=3.9 if specificcomorbid==1			
replace ratio_min=283.9 if specificcomorbid==1
replace mechvent_6hr=0.14 if specificcomorbid==1
replace vaso_6hrs=0.36 if specificcomorbid==1
replace alter_mental_status=0.57 if specificcomorbid==1
replace charlson = 4.7 if specificcomorbid==1
replace max_temp = 2.4 if specificcomorbid==1
replace min_sysbp = 1.48 if specificcomorbid==1
replace max_rr = 3.35 if specificcomorbid==1
replace max_hr = 3.5 if specificcomorbid==1
replace wbc_high = 15.3 if specificcomorbid==1
replace bilirubin_high = 1.28 if specificcomorbid==1
replace platelets_low = 225.6 if specificcomorbid==1

predict pr_mort_co if e(sample)==1
predict xb_co if e(sample)==1, xb 
predict error_co if e(sample)==1, stdp 

gen lb_co = xb_co - invnormal(0.975)*error_co
gen ub_co = xb_co + invnormal(0.975)*error_co
gen plb_co = invlogit(lb_co)
gen pub_co = invlogit(ub_co)

rename plb_co plb1 
rename pub_co pub1
rename pr_mort_co pr_mort1 
rename plb_noco plb0
rename pub_noco pub0 
rename pr_mort_noco pr_mort0
							   
foreach var in plb1 pub1 pr_mort1 plb0 pub0 pr_mort0 {
	gen `var'_pct = `var'*100
}

gen byte include = pragmaticsix <= 80						   				   
sort pragmaticsix	
graph twoway (rarea plb1_pct pub1_pct pragmaticsix if include, fcolor("0 114 178*0.80") lwidth(none)) ///
				(line pr_mort1_pct pragmaticsix if include,			///
						title("Hypoperfused", size(medlarge))	///
						xtitle("Fluid in first 6 hrs (ml/kg)", size(med) margin(medium)) ///
						ytitle("Probability 30-day mortality (%)", size(med) margin(medium)) ///
						yscale(range(0 40)) ylabel(0(10)70) ///
						lcolor("0 114 178*1.25"))  	///						
			 || (rarea plb0_pct pub0_pct pragmaticsix if include, fcolor("230 159 0*0.70") lwidth(none)) ///
					(line pr_mort0_pct pragmaticsix if include, lcolor("230 159 0*1.5") lpattern(dash))	///
			 || , legend(order(2 "with" "specified" "comorbidities" 4 "without" "specified" "comorbidities" )	///
					symysize (6) size(small)) name("hypoprag", replace)			
				
restore


********************************************************************************


******************************************
* Intermediate Lactate - PRAGMATIC
******************************************

*--------------------------------------------------
* spline analysis & no specific comorbidities
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if intermediate_lactate==1 & specificcomorbid==0

sum pragmaticsix, de

* fit model with different number of knots
mkspline sp_fluid_3nk = pragmaticsix, cubic nknots(3)
mkspline sp_fluid_4nk = pragmaticsix, cubic nknots(4)
mkspline sp_fluid_5nk = pragmaticsix, cubic nknots(5)
				
logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_pi]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_pi]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_pi]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*--------------------------------------------------
* spline analysis & specific comorbidities
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if intermediate_lactate==1 & specificcomorbid==1

sum pragmaticsix, de

* fit model with different number of knots
mkspline sp_fluid_3nk = pragmaticsix, cubic nknots(3)
mkspline sp_fluid_4nk = pragmaticsix, cubic nknots(4)
mkspline sp_fluid_5nk = pragmaticsix, cubic nknots(5)
		
logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_pic]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_pic]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_pic]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2))  

restore 


*---------------------------
* descriptive statistics  
*---------------------------

preserve

	keep if intermediate_lactate==1 & specificcomorbid==0

	svyset hosp [pweight=ps_weight_pi]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 



preserve

	keep if intermediate_lactate==1 & specificcomorbid==1

	svyset hosp [pweight=ps_weight_pic]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 


*---------------------------------
* create twoway line graph 
*---------------------------------

preserve 

keep if intermediate_lactate==1

* no specific comorbidities
mkspline sp_fluid_noc = pragmaticsix if specificcomorbid==0, cubic nknots(3)

svyset hosp [pweight=ps_weight_pi]


local covar		age male postacutecare priorhosp kidneydisease 			///
				liverdisease chf malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_noc? `covar' if specificcomorbid==0

replace age = 69.0 if specificcomorbid==0
replace male=0.51 if specificcomorbid==0
replace postacutecare=0.11 if specificcomorbid==0
replace priorhosp=0.30 if specificcomorbid==0
replace kidneydisease=0.25 if specificcomorbid==0			
replace liverdisease=0.03 if specificcomorbid==0
replace chf=0.22 if specificcomorbid==0
replace malignancy=0.26 if specificcomorbid==0
replace mortality_predicted=0.14 if specificcomorbid==0	
replace bmi_calculated=29.7 if specificcomorbid==0
replace lactatemax_draw=2.8 if specificcomorbid==0
replace creatinine_high=1.36 if specificcomorbid==0			
replace ratio_min=327.16 if specificcomorbid==0
replace mechvent_6hr=0.03 if specificcomorbid==0
replace vaso_6hrs=0.02 if specificcomorbid==0
replace alter_mental_status=0.36 if specificcomorbid==0
replace charlson = 2.97 if specificcomorbid==0
replace max_temp = 2.90 if specificcomorbid==0
replace min_sysbp = 2.83 if specificcomorbid==0
replace max_rr = 3.00 if specificcomorbid==0
replace max_hr = 3.89 if specificcomorbid==0
replace wbc_high = 15.45 if specificcomorbid==0
replace bilirubin_high = 1.04 if specificcomorbid==0
replace platelets_low = 256.84 if specificcomorbid==0

predict pr_mort_noco if e(sample)==1
predict xb_noco if e(sample)==1, xb 
predict error_noco if e(sample)==1, stdp 

gen lb_noco = xb_noco - invnormal(0.975)*error_noco
gen ub_noco = xb_noco + invnormal(0.975)*error_noco
gen plb_noco = invlogit(lb_noco)
gen pub_noco = invlogit(ub_noco)


* with comorbidities
mkspline sp_fluid_c = pragmaticsix if specificcomorbid==1, cubic nknots(3)

svyset hosp [pweight=ps_weight_pic]

local covar		age male postacutecare priorhosp kidneydisease 			///
				liverdisease chf malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_c? `covar' if specificcomorbid==1

replace age = 70.6 if specificcomorbid==1
replace male=0.59 if specificcomorbid==1
replace postacutecare=0.14 if specificcomorbid==1
replace priorhosp=0.48 if specificcomorbid==1
replace kidneydisease=0.66 if specificcomorbid==1			
replace liverdisease=0.02 if specificcomorbid==1
replace chf=0.61 if specificcomorbid==1
replace malignancy=0.24 if specificcomorbid==1
replace mortality_predicted=0.20 if specificcomorbid==1	
replace bmi_calculated=28.5 if specificcomorbid==1
replace lactatemax_draw=2.80 if specificcomorbid==1
replace creatinine_high=4.91 if specificcomorbid==1			
replace ratio_min=313.4 if specificcomorbid==1
replace mechvent_6hr=0.03 if specificcomorbid==1
replace vaso_6hrs=0.03 if specificcomorbid==1
replace alter_mental_status=0.43 if specificcomorbid==1
replace charlson = 4.56 if specificcomorbid==1
replace max_temp = 2.81 if specificcomorbid==1
replace min_sysbp = 2.83 if specificcomorbid==1
replace max_rr = 3.11 if specificcomorbid==1
replace max_hr = 3.68 if specificcomorbid==1
replace wbc_high = 14.61 if specificcomorbid==1
replace bilirubin_high = 0.99 if specificcomorbid==1
replace platelets_low = 239.7 if specificcomorbid==1

predict pr_mort_co if e(sample)==1
predict xb_co if e(sample)==1, xb 
predict error_co if e(sample)==1, stdp 

gen lb_co = xb_co - invnormal(0.975)*error_co
gen ub_co = xb_co + invnormal(0.975)*error_co
gen plb_co = invlogit(lb_co)
gen pub_co = invlogit(ub_co)

rename plb_co plb1 
rename pub_co pub1
rename pr_mort_co pr_mort1 
rename plb_noco plb0
rename pub_noco pub0 
rename pr_mort_noco pr_mort0
							   
foreach var in plb1 pub1 pr_mort1 plb0 pub0 pr_mort0 {
	gen `var'_pct = `var'*100
}

gen byte include = pragmaticsix <= 80						   				   
sort pragmaticsix	
graph twoway (rarea plb1_pct pub1_pct pragmaticsix if include, fcolor("0 114 178*0.80") lwidth(none)) ///
				(line pr_mort1_pct pragmaticsix if include,			///
						title("Intermediate Lactate", size(medlarge))	///
						xtitle("Fluid in first 6 hrs (ml/kg)", size(med) margin(medium)) ///
						ytitle("Probability 30-day mortality (%)", size(med) margin(medium)) ///
						yscale(range(0 40)) ylabel(0(10)70) ///
						lcolor("0 114 178*1.25"))  	///						
			 || (rarea plb0_pct pub0_pct pragmaticsix if include, fcolor("230 159 0*0.70") lwidth(none)) ///
					(line pr_mort0_pct pragmaticsix if include, lcolor("230 159 0*1.5") lpattern(dash))	///
			 || , legend(order(2 "with" "specified" "comorbidities" 4 "without" "specified" "comorbidities" )	///
					symysize (6) size(small)) name("lactateprag", replace)			
					
restore




********************************************************************************
********************************************************************************

						*** CHRONIC HEART FAILURE ***

********************************************************************************
********************************************************************************


import sas using "Data\sample_wgts_sen_06nov2025.sas7bdat", case(lower) clear
save "Data\sample_wgts_sen_06nov2025.dta", replace	
	
* open dataset 
use "Data\sample_wgts_sen_06nov2025.dta", clear

				
************
* Tailored *
************

*--------------------------------------------------
* spline analysis for hypoperfused
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if hypoperfused==1 & chf==1

sum tailoredsix, de

* fit model with different number of knots
mkspline sp_fluid_3nk = tailoredsix, cubic nknots(3)
mkspline sp_fluid_4nk = tailoredsix, cubic nknots(4)
mkspline sp_fluid_5nk = tailoredsix, cubic nknots(5)
				
logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_thchf]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_thchf]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_thchf]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*--------------------------------------------------
* spline analysis for intermediate lactate
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if intermediate_lactate==1 & chf==1

sum tailoredsix, de

* fit model with different number of knots
mkspline sp_fluid_3nk = tailoredsix, cubic nknots(3)
mkspline sp_fluid_4nk = tailoredsix, cubic nknots(4)
mkspline sp_fluid_5nk = tailoredsix, cubic nknots(5)
		

logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_tichf]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_tichf]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_tichf]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*---------------------------
* descriptive statistics  
*---------------------------

preserve

	keep if hypoperfused==1 & chf==1

	svyset hosp [pweight=ps_weight_thchf]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 

preserve

	keep if intermediate_lactate==1 & chf==1

	svyset hosp [pweight=ps_weight_tichf]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 


*---------------------------------
* create twoway line graph 
*---------------------------------

preserve 

keep if chf==1

* hypoperfused
mkspline sp_fluid_h = tailoredsix if hypoperfused==1, cubic nknots(3)

svyset hosp [pweight=ps_weight_thchf]


local covar		age male postacutecare priorhosp kidneydisease 			///
				liverdiseas  malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_h? `covar' if hypoperfused==1

replace age = 74.1 if hypoperfused==1
replace male=0.50 if hypoperfused==1
replace postacutecare=0.23 if hypoperfused==1
replace priorhosp=0.47 if hypoperfused==1
replace kidneydisease=0.50 if hypoperfused==1			
replace liverdisease=0.04 if hypoperfused==1
replace malignancy=0.26 if hypoperfused==1
replace mortality_predicted=0.36 if hypoperfused==1	
replace bmi_calculated=30.19 if hypoperfused==1
replace lactatemax_draw=4.26 if hypoperfused==1
replace creatinine_high=2.46 if hypoperfused==1			
replace ratio_min=267.32 if hypoperfused==1
replace mechvent_6hr=0.16 if hypoperfused==1
replace vaso_6hrs=0.35 if hypoperfused==1
replace alter_mental_status=0.58 if hypoperfused==1
replace charlson = 4.67 if hypoperfused==1
replace max_temp = 2.44 if hypoperfused==1
replace min_sysbp = 1.50 if hypoperfused==1
replace max_rr = 3.44 if hypoperfused==1
replace max_hr = 3.56 if hypoperfused==1
replace wbc_high = 15.41 if hypoperfused==1
replace bilirubin_high = 1.16 if hypoperfused==1
replace platelets_low = 238.25 if hypoperfused==1

predict pr_mort_hypo if e(sample)==1
predict xb_hypo if e(sample)==1, xb 
predict error_hypo if e(sample)==1, stdp 

gen lb_hypo = xb_hypo - invnormal(0.975)*error_hypo
gen ub_hypo = xb_hypo + invnormal(0.975)*error_hypo
gen plb_hypo = invlogit(lb_hypo)
gen pub_hypo = invlogit(ub_hypo)

* intermediate lactate
mkspline sp_fluid_i = tailoredsix if intermediate_lactate==1, cubic nknots(3)

svyset hosp [pweight=ps_weight_tichf]

local covar		age male postacutecare priorhosp kidneydisease 			///
				liverdisease malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_i? `covar' if intermediate_lactate==1

replace age = 74.6 if intermediate_lactate==1
replace male=0.51 if intermediate_lactate==1
replace postacutecare=0.14 if intermediate_lactate==1
replace priorhosp=0.39 if intermediate_lactate==1
replace kidneydisease=0.46 if intermediate_lactate==1			
replace liverdisease=0.03 if intermediate_lactate==1
replace malignancy=0.26 if intermediate_lactate==1
replace mortality_predicted=0.19 if intermediate_lactate==1	
replace bmi_calculated=30.85 if intermediate_lactate==1
replace lactatemax_draw=2.78 if intermediate_lactate==1
replace creatinine_high=2.22 if intermediate_lactate==1			
replace ratio_min=294.99 if intermediate_lactate==1
replace mechvent_6hr=0.03 if intermediate_lactate==1
replace vaso_6hrs=0.02 if intermediate_lactate==1
replace alter_mental_status=0.43 if intermediate_lactate==1
replace charlson = 4.53 if intermediate_lactate==1
replace max_temp = 2.81 if intermediate_lactate==1
replace min_sysbp = 2.81 if intermediate_lactate==1
replace max_rr = 3.24 if intermediate_lactate==1
replace max_hr = 3.68 if intermediate_lactate==1
replace wbc_high = 15.35 if intermediate_lactate==1
replace bilirubin_high = 1.03 if intermediate_lactate==1
replace platelets_low = 243.41 if intermediate_lactate==1

predict pr_mort_il if e(sample)==1
predict xb_il if e(sample)==1, xb 
predict error_il if e(sample)==1, stdp 

gen lb_il = xb_il - invnormal(0.975)*error_il
gen ub_il = xb_il + invnormal(0.975)*error_il
gen plb_il = invlogit(lb_il)
gen pub_il = invlogit(ub_il)

rename plb_il plb1 
rename pub_il pub1
rename pr_mort_il pr_mort1 
rename plb_hypo plb0
rename pub_hypo pub0 
rename pr_mort_hypo pr_mort0
							   
foreach var in plb1 pub1 pr_mort1 plb0 pub0 pr_mort0 {
	gen `var'_pct = `var'*100
}

sum tailoredsix
gen byte include = tailoredsix <= 80						   				   
sort tailoredsix	
graph twoway (rarea plb1_pct pub1_pct tailoredsix if include, fcolor("0 114 178*0.80") lwidth(none)) ///
				(line pr_mort1_pct tailoredsix if include,			///
						title("Tailored", size(medlarge))	///
						xtitle("Fluid in first 6 hrs (ml/kg)", size(med) margin(medium)) ///
						ytitle("Probability 30-day mortality (%)", size(med) margin(medium)) ///
						yscale(range(0 40)) ylabel(0(10)40) ///
						lcolor("0 114 178*1.25"))  	///						
			 || (rarea plb0_pct pub0_pct tailoredsix if include, fcolor("230 159 0*0.70") lwidth(none)) ///
					(line pr_mort0_pct tailoredsix if include, lcolor("230 159 0*1.5") lpattern(dash))	///
			 || , legend(order(4 "Hypoperfused" 2 "Intermediate Lactate" )	///
					symysize (6) size(small)) name("chftailor", replace)			

			
restore


				
*********
* Sep-1 *
*********

*--------------------------------------------------
* spline analysis for hypoperfused
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if hypoperfused==1 & chf==1

sum sep1six, de

* fit model with different number of knots
mkspline sp_fluid_3nk = sep1six, cubic nknots(3)
mkspline sp_fluid_4nk = sep1six, cubic nknots(4)
mkspline sp_fluid_5nk = sep1six, cubic nknots(5)
				
logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_shchf]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_shchf]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_shchf]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*--------------------------------------------------
* spline analysis for intermediate lactate
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if intermediate_lactate==1 & chf==1

sum sep1six, de

* fit model with different number of knots
mkspline sp_fluid_3nk = sep1six, cubic nknots(3)
mkspline sp_fluid_4nk = sep1six, cubic nknots(4)
mkspline sp_fluid_5nk = sep1six, cubic nknots(5)
		

logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_sichf]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_sichf]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_sichf]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*---------------------------
* descriptive statistics  
*---------------------------

preserve

	keep if hypoperfused==1 & chf==1

	svyset hosp [pweight=ps_weight_shchf]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 

preserve

	keep if intermediate_lactate==1 & chf==1

	svyset hosp [pweight=ps_weight_sichf]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 


*---------------------------------
* create twoway line graph 
*---------------------------------

preserve 

keep if chf==1

* hypoperfused
mkspline sp_fluid_h = sep1six if hypoperfused==1, cubic nknots(3)

svyset hosp [pweight=ps_weight_shchf]


local covar		age male postacutecare priorhosp kidneydisease 			///
				liverdiseas  malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_h? `covar' if hypoperfused==1

replace age = 74.0 if hypoperfused==1
replace male=0.51 if hypoperfused==1
replace postacutecare=0.23 if hypoperfused==1
replace priorhosp=0.46 if hypoperfused==1
replace kidneydisease=0.51 if hypoperfused==1			
replace liverdisease=0.04 if hypoperfused==1
replace malignancy=0.26 if hypoperfused==1
replace mortality_predicted=0.35 if hypoperfused==1	
replace bmi_calculated=30.19 if hypoperfused==1
replace lactatemax_draw=4.23 if hypoperfused==1
replace creatinine_high=2.39 if hypoperfused==1			
replace ratio_min=267.09 if hypoperfused==1
replace mechvent_6hr=0.16 if hypoperfused==1
replace vaso_6hrs=0.35 if hypoperfused==1
replace alter_mental_status=0.57 if hypoperfused==1
replace charlson = 4.67 if hypoperfused==1
replace max_temp = 2.43 if hypoperfused==1
replace min_sysbp = 1.51 if hypoperfused==1
replace max_rr = 3.43 if hypoperfused==1
replace max_hr = 3.54 if hypoperfused==1
replace wbc_high = 15.32 if hypoperfused==1
replace bilirubin_high = 1.16 if hypoperfused==1
replace platelets_low = 236.81 if hypoperfused==1

predict pr_mort_hypo if e(sample)==1
predict xb_hypo if e(sample)==1, xb 
predict error_hypo if e(sample)==1, stdp 

gen lb_hypo = xb_hypo - invnormal(0.975)*error_hypo
gen ub_hypo = xb_hypo + invnormal(0.975)*error_hypo
gen plb_hypo = invlogit(lb_hypo)
gen pub_hypo = invlogit(ub_hypo)

* intermediate lactate
mkspline sp_fluid_i = sep1six if intermediate_lactate==1, cubic nknots(3)

svyset hosp [pweight=ps_weight_sichf]

local covar		age male postacutecare priorhosp kidneydisease 			///
				liverdisease malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_i? `covar' if intermediate_lactate==1

replace age = 74.7 if intermediate_lactate==1
replace male=0.51 if intermediate_lactate==1
replace postacutecare=0.14 if intermediate_lactate==1
replace priorhosp=0.39 if intermediate_lactate==1
replace kidneydisease=0.46 if intermediate_lactate==1			
replace liverdisease=0.02 if intermediate_lactate==1
replace malignancy=0.26 if intermediate_lactate==1
replace mortality_predicted=0.19 if intermediate_lactate==1	
replace bmi_calculated=30.87 if intermediate_lactate==1
replace lactatemax_draw=2.78 if intermediate_lactate==1
replace creatinine_high=2.27 if intermediate_lactate==1			
replace ratio_min=294.6 if intermediate_lactate==1
replace mechvent_6hr=0.03 if intermediate_lactate==1
replace vaso_6hrs=0.02 if intermediate_lactate==1
replace alter_mental_status=0.42 if intermediate_lactate==1
replace charlson = 4.52 if intermediate_lactate==1
replace max_temp = 2.79 if intermediate_lactate==1
replace min_sysbp = 2.80 if intermediate_lactate==1
replace max_rr = 3.25 if intermediate_lactate==1
replace max_hr = 3.70 if intermediate_lactate==1
replace wbc_high = 15.39 if intermediate_lactate==1
replace bilirubin_high = 1.04 if intermediate_lactate==1
replace platelets_low = 244.83 if intermediate_lactate==1

predict pr_mort_il if e(sample)==1
predict xb_il if e(sample)==1, xb 
predict error_il if e(sample)==1, stdp 

gen lb_il = xb_il - invnormal(0.975)*error_il
gen ub_il = xb_il + invnormal(0.975)*error_il
gen plb_il = invlogit(lb_il)
gen pub_il = invlogit(ub_il)

sum pr_mort_hypo pr_mort_il

rename plb_il plb1 
rename pub_il pub1
rename pr_mort_il pr_mort1 
rename plb_hypo plb0
rename pub_hypo pub0 
rename pr_mort_hypo pr_mort0
							   
foreach var in plb1 pub1 pr_mort1 plb0 pub0 pr_mort0 {
	gen `var'_pct = `var'*100
}

sum sep1six
gen byte include = sep1six <= 80						   				   
sort sep1six	
graph twoway (rarea plb1_pct pub1_pct sep1six if include, fcolor("0 114 178*0.80") lwidth(none)) ///
				(line pr_mort1_pct sep1six if include,			///
						title("Sep-1", size(medlarge))	///
						xtitle("Fluid in first 6 hrs (ml/kg)", size(med) margin(medium)) ///
						ytitle("Probability 30-day mortality (%)", size(med) margin(medium)) ///
						yscale(range(0 40)) ylabel(0(10)40) ///
						lcolor("0 114 178*1.25"))  	///						
			 || (rarea plb0_pct pub0_pct sep1six if include, fcolor("230 159 0*0.70") lwidth(none)) ///
					(line pr_mort0_pct sep1six if include, lcolor("230 159 0*1.5") lpattern(dash))	///
			 || , legend(order(4 "Hypoperfused" 2 "Intermediate Lactate" )	///
					symysize (6) size(small)) name("chfsep1", replace)			
			
restore

				
*************
* Pragmatic *
*************

*--------------------------------------------------
* spline analysis for hypoperfused
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if hypoperfused==1 & chf==1

sum pragmaticsix, de

* fit model with different number of knots
mkspline sp_fluid_3nk = pragmaticsix, cubic nknots(3)
mkspline sp_fluid_4nk = pragmaticsix, cubic nknots(4)
mkspline sp_fluid_5nk = pragmaticsix, cubic nknots(5)
				
logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_phchf]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_phchf]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_phchf]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2))

restore 

*--------------------------------------------------
* spline analysis for intermediate lactate
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if intermediate_lactate==1 & chf==1

sum pragmaticsix, de

* fit model with different number of knots
mkspline sp_fluid_3nk = pragmaticsix, cubic nknots(3)
mkspline sp_fluid_4nk = pragmaticsix, cubic nknots(4)
mkspline sp_fluid_5nk = pragmaticsix, cubic nknots(5)
		

logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_pichf]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_pichf]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_pichf]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*---------------------------
* descriptive statistics  
*---------------------------

preserve

	keep if hypoperfused==1 & chf==1

	svyset hosp [pweight=ps_weight_phchf]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 

preserve

	keep if intermediate_lactate==1 & chf==1

	svyset hosp [pweight=ps_weight_pichf]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 


*---------------------------------
* create twoway line graph 
*---------------------------------

preserve 

keep if chf==1

* hypoperfused
mkspline sp_fluid_h = pragmaticsix if hypoperfused==1, cubic nknots(3)

svyset hosp [pweight=ps_weight_phchf]


local covar		age male postacutecare priorhosp kidneydisease 			///
				liverdiseas  malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_h? `covar' if hypoperfused==1

replace age = 74.1 if hypoperfused==1
replace male=0.50 if hypoperfused==1
replace postacutecare=0.23 if hypoperfused==1
replace priorhosp=0.46 if hypoperfused==1
replace kidneydisease=0.51 if hypoperfused==1			
replace liverdisease=0.04 if hypoperfused==1
replace malignancy=0.26 if hypoperfused==1
replace mortality_predicted=0.35 if hypoperfused==1	
replace bmi_calculated=30.25 if hypoperfused==1
replace lactatemax_draw=4.24 if hypoperfused==1
replace creatinine_high=2.37 if hypoperfused==1			
replace ratio_min=266.84 if hypoperfused==1
replace mechvent_6hr=0.16 if hypoperfused==1
replace vaso_6hrs=0.35 if hypoperfused==1
replace alter_mental_status=0.57 if hypoperfused==1
replace charlson = 4.66 if hypoperfused==1
replace max_temp = 2.44 if hypoperfused==1
replace min_sysbp = 1.50 if hypoperfused==1
replace max_rr = 3.44 if hypoperfused==1
replace max_hr = 3.56 if hypoperfused==1
replace wbc_high = 15.38 if hypoperfused==1
replace bilirubin_high = 1.16 if hypoperfused==1
replace platelets_low = 237.73 if hypoperfused==1

predict pr_mort_hypo if e(sample)==1
predict xb_hypo if e(sample)==1, xb 
predict error_hypo if e(sample)==1, stdp 

gen lb_hypo = xb_hypo - invnormal(0.975)*error_hypo
gen ub_hypo = xb_hypo + invnormal(0.975)*error_hypo
gen plb_hypo = invlogit(lb_hypo)
gen pub_hypo = invlogit(ub_hypo)

* intermediate lactate
mkspline sp_fluid_i = pragmaticsix if intermediate_lactate==1, cubic nknots(3)

svyset hosp [pweight=ps_weight_pichf]

local covar		age male postacutecare priorhosp kidneydisease 			///
				liverdisease malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_i? `covar' if intermediate_lactate==1

replace age = 74.6 if intermediate_lactate==1
replace male=0.51 if intermediate_lactate==1
replace postacutecare=0.14 if intermediate_lactate==1
replace priorhosp=0.39 if intermediate_lactate==1
replace kidneydisease=0.46 if intermediate_lactate==1			
replace liverdisease=0.02 if intermediate_lactate==1
replace malignancy=0.26 if intermediate_lactate==1
replace mortality_predicted=0.19 if intermediate_lactate==1	
replace bmi_calculated=30.84 if intermediate_lactate==1
replace lactatemax_draw=2.79 if intermediate_lactate==1
replace creatinine_high=2.25 if intermediate_lactate==1			
replace ratio_min=294.6 if intermediate_lactate==1
replace mechvent_6hr=0.03 if intermediate_lactate==1
replace vaso_6hrs=0.03 if intermediate_lactate==1
replace alter_mental_status=0.43 if intermediate_lactate==1
replace charlson = 4.52 if intermediate_lactate==1
replace max_temp = 2.78 if intermediate_lactate==1
replace min_sysbp = 2.81 if intermediate_lactate==1
replace max_rr = 3.25 if intermediate_lactate==1
replace max_hr = 3.69 if intermediate_lactate==1
replace wbc_high = 15.44 if intermediate_lactate==1
replace bilirubin_high = 1.03 if intermediate_lactate==1
replace platelets_low = 244.13 if intermediate_lactate==1

predict pr_mort_il if e(sample)==1
predict xb_il if e(sample)==1, xb 
predict error_il if e(sample)==1, stdp 

gen lb_il = xb_il - invnormal(0.975)*error_il
gen ub_il = xb_il + invnormal(0.975)*error_il
gen plb_il = invlogit(lb_il)
gen pub_il = invlogit(ub_il)

sum pr_mort_hypo pr_mort_il

rename plb_il plb1 
rename pub_il pub1
rename pr_mort_il pr_mort1 
rename plb_hypo plb0
rename pub_hypo pub0 
rename pr_mort_hypo pr_mort0
							   
foreach var in plb1 pub1 pr_mort1 plb0 pub0 pr_mort0 {
	gen `var'_pct = `var'*100
}

sum pragmaticsix
gen byte include = pragmaticsix <= 80						   				   
sort pragmaticsix	
graph twoway (rarea plb1_pct pub1_pct pragmaticsix if include, fcolor("0 114 178*0.80") lwidth(none)) ///
				(line pr_mort1_pct pragmaticsix if include,			///
						title("Pragmatic", size(medlarge))	///
						xtitle("Fluid in first 6 hrs (ml/kg)", size(med) margin(medium)) ///
						ytitle("Probability 30-day mortality (%)", size(med) margin(medium)) ///
						yscale(range(0 40)) ylabel(0(10)40) ///
						lcolor("0 114 178*1.25"))  	///						
			 || (rarea plb0_pct pub0_pct pragmaticsix if include, fcolor("230 159 0*0.70") lwidth(none)) ///
					(line pr_mort0_pct pragmaticsix if include, lcolor("230 159 0*1.5") lpattern(dash))	///
			 || , legend(order(4 "Hypoperfused" 2 "Intermediate Lactate" )	///
					symysize (6) size(small)) name("chfprag", replace)			
		
restore




********************************************************************************
********************************************************************************

					   *** CHRONIC KIDNEY DISEASE ***

********************************************************************************
********************************************************************************

			
************
* Tailored *
************

*--------------------------------------------------
* spline analysis for hypoperfused
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if hypoperfused==1 & kidneydisease==1

sum tailoredsix, de

* fit model with different number of knots
mkspline sp_fluid_3nk = tailoredsix, cubic nknots(3)
mkspline sp_fluid_4nk = tailoredsix, cubic nknots(4)
mkspline sp_fluid_5nk = tailoredsix, cubic nknots(5)
				
logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_thckd]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_thckd]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_thckd]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*--------------------------------------------------
* spline analysis for intermediate lactate
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if intermediate_lactate==1 & kidneydisease==1

sum tailoredsix, de

* fit model with different number of knots
mkspline sp_fluid_3nk = tailoredsix, cubic nknots(3)
mkspline sp_fluid_4nk = tailoredsix, cubic nknots(4)
mkspline sp_fluid_5nk = tailoredsix, cubic nknots(5)
		

logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_tickd]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_tickd]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_tickd]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*---------------------------
* descriptive statistics  
*---------------------------

preserve

	keep if hypoperfused==1 & kidneydisease==1

	svyset hosp [pweight=ps_weight_thckd]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 

preserve

	keep if intermediate_lactate==1 & kidneydisease==1

	svyset hosp [pweight=ps_weight_tickd]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 


*---------------------------------
* create twoway line graph 
*---------------------------------

preserve 

keep if kidneydisease==1

* hypoperfused
mkspline sp_fluid_h = tailoredsix if hypoperfused==1, cubic nknots(3)

svyset hosp [pweight=ps_weight_thckd]


local covar		age male postacutecare priorhosp  			///
				liverdiseas chf  malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_h? `covar' if hypoperfused==1

replace age = 73.0 if hypoperfused==1
replace male=0.51 if hypoperfused==1
replace postacutecare=0.21 if hypoperfused==1
replace priorhosp=0.41 if hypoperfused==1
replace liverdisease=0.05 if hypoperfused==1
replace chf=0.42 if hypoperfused==1
replace malignancy=0.27 if hypoperfused==1
replace mortality_predicted=0.33 if hypoperfused==1	
replace bmi_calculated=29.3 if hypoperfused==1
replace lactatemax_draw=4.32 if hypoperfused==1
replace creatinine_high=3.38 if hypoperfused==1			
replace ratio_min=291.01 if hypoperfused==1
replace mechvent_6hr=0.13 if hypoperfused==1
replace vaso_6hrs=0.33 if hypoperfused==1
replace alter_mental_status=0.59 if hypoperfused==1
replace charlson = 5.10 if hypoperfused==1
replace max_temp = 2.39 if hypoperfused==1
replace min_sysbp = 1.48 if hypoperfused==1
replace max_rr = 3.32 if hypoperfused==1
replace max_hr = 3.53 if hypoperfused==1
replace wbc_high = 15.66 if hypoperfused==1
replace bilirubin_high = 1.20 if hypoperfused==1
replace platelets_low = 234.33 if hypoperfused==1

predict pr_mort_hypo if e(sample)==1
predict xb_hypo if e(sample)==1, xb 
predict error_hypo if e(sample)==1, stdp 

gen lb_hypo = xb_hypo - invnormal(0.975)*error_hypo
gen ub_hypo = xb_hypo + invnormal(0.975)*error_hypo
gen plb_hypo = invlogit(lb_hypo)
gen pub_hypo = invlogit(ub_hypo)

* intermediate lactate
mkspline sp_fluid_i = tailoredsix if intermediate_lactate==1, cubic nknots(3)

svyset hosp [pweight=ps_weight_tickd]

local covar		age male postacutecare priorhosp chf 			///
				liverdisease malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_i? `covar' if intermediate_lactate==1

replace age = 73.7 if intermediate_lactate==1
replace male=0.54 if intermediate_lactate==1
replace postacutecare=0.14 if intermediate_lactate==1
replace priorhosp=0.39 if intermediate_lactate==1
replace liverdisease=0.03 if intermediate_lactate==1
replace chf=0.41 if intermediate_lactate==1
replace malignancy=0.29 if intermediate_lactate==1
replace mortality_predicted=0.18 if intermediate_lactate==1	
replace bmi_calculated=29.8 if intermediate_lactate==1
replace lactatemax_draw=2.80 if intermediate_lactate==1
replace creatinine_high=2.63 if intermediate_lactate==1			
replace ratio_min=326.29 if intermediate_lactate==1
replace mechvent_6hr=0.03 if intermediate_lactate==1
replace vaso_6hrs=0.02 if intermediate_lactate==1
replace alter_mental_status=0.45 if intermediate_lactate==1
replace charlson = 5.18 if intermediate_lactate==1
replace max_temp = 2.85 if intermediate_lactate==1
replace min_sysbp = 2.81 if intermediate_lactate==1
replace max_rr = 3.03 if intermediate_lactate==1
replace max_hr = 3.68 if intermediate_lactate==1
replace wbc_high = 15.24 if intermediate_lactate==1
replace bilirubin_high = 0.99 if intermediate_lactate==1
replace platelets_low = 242.47 if intermediate_lactate==1

predict pr_mort_il if e(sample)==1
predict xb_il if e(sample)==1, xb 
predict error_il if e(sample)==1, stdp 

gen lb_il = xb_il - invnormal(0.975)*error_il
gen ub_il = xb_il + invnormal(0.975)*error_il
gen plb_il = invlogit(lb_il)
gen pub_il = invlogit(ub_il)

rename plb_il plb1 
rename pub_il pub1
rename pr_mort_il pr_mort1 
rename plb_hypo plb0
rename pub_hypo pub0 
rename pr_mort_hypo pr_mort0
							   
foreach var in plb1 pub1 pr_mort1 plb0 pub0 pr_mort0 {
	gen `var'_pct = `var'*100
}

sum tailoredsix
gen byte include = tailoredsix <= 80						   				   
sort tailoredsix	
graph twoway (rarea plb1_pct pub1_pct tailoredsix if include, fcolor("0 114 178*0.80") lwidth(none)) ///
				(line pr_mort1_pct tailoredsix if include,			///
						title("Tailored", size(medlarge))	///
						xtitle("Fluid in first 6 hrs (ml/kg)", size(med) margin(medium)) ///
						ytitle("Probability 30-day mortality (%)", size(med) margin(medium)) ///
						yscale(range(0 40)) ylabel(0(10)40) ///
						lcolor("0 114 178*1.25"))  	///						
			 || (rarea plb0_pct pub0_pct tailoredsix if include, fcolor("230 159 0*0.70") lwidth(none)) ///
					(line pr_mort0_pct tailoredsix if include, lcolor("230 159 0*1.5") lpattern(dash))	///
			 || , legend(order(4 "Hypoperfused" 2 "Intermediate Lactate" )	///
					symysize (6) size(small)) name("ckdtailor", replace)			

restore


				
*********
* Sep-1 *
*********

*--------------------------------------------------
* spline analysis for hypoperfused
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if hypoperfused==1 & kidneydisease==1

sum sep1six, de

* fit model with different number of knots
mkspline sp_fluid_3nk = sep1six, cubic nknots(3)
mkspline sp_fluid_4nk = sep1six, cubic nknots(4)
mkspline sp_fluid_5nk = sep1six, cubic nknots(5)
				
logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_shckd]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_shckd]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_shckd]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*--------------------------------------------------
* spline analysis for intermediate lactate
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if intermediate_lactate==1 & kidneydisease==1

sum sep1six, de

* fit model with different number of knots
mkspline sp_fluid_3nk = sep1six, cubic nknots(3)
mkspline sp_fluid_4nk = sep1six, cubic nknots(4)
mkspline sp_fluid_5nk = sep1six, cubic nknots(5)
		

logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_sickd]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_sickd]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_sickd]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*---------------------------
* descriptive statistics  
*---------------------------

preserve

	keep if hypoperfused==1 & kidneydisease==1

	svyset hosp [pweight=ps_weight_shckd]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 

preserve

	keep if intermediate_lactate==1 & kidneydisease==1

	svyset hosp [pweight=ps_weight_sickd]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 


*---------------------------------
* create twoway line graph 
*---------------------------------

preserve 

keep if kidneydisease==1

* hypoperfused
mkspline sp_fluid_h = sep1six if hypoperfused==1, cubic nknots(3)

svyset hosp [pweight=ps_weight_shckd]


local covar		age male postacutecare priorhosp chf 			///
				liverdiseas  malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_h? `covar' if hypoperfused==1

replace age = 72.9 if hypoperfused==1
replace male=0.51 if hypoperfused==1
replace postacutecare=0.22 if hypoperfused==1
replace priorhosp=0.42 if hypoperfused==1
replace liverdisease=0.05 if hypoperfused==1
replace chf=0.42 if hypoperfused==1
replace malignancy=0.27 if hypoperfused==1
replace mortality_predicted=0.33 if hypoperfused==1	
replace bmi_calculated=29.43 if hypoperfused==1
replace lactatemax_draw=4.29 if hypoperfused==1
replace creatinine_high=3.34 if hypoperfused==1			
replace ratio_min=290.99 if hypoperfused==1
replace mechvent_6hr=0.13 if hypoperfused==1
replace vaso_6hrs=0.32 if hypoperfused==1
replace alter_mental_status=0.58 if hypoperfused==1
replace charlson = 5.10 if hypoperfused==1
replace max_temp = 2.39 if hypoperfused==1
replace min_sysbp = 1.49 if hypoperfused==1
replace max_rr = 3.31 if hypoperfused==1
replace max_hr = 3.53 if hypoperfused==1
replace wbc_high = 15.66 if hypoperfused==1
replace bilirubin_high = 1.22 if hypoperfused==1
replace platelets_low = 233.27 if hypoperfused==1

predict pr_mort_hypo if e(sample)==1
predict xb_hypo if e(sample)==1, xb 
predict error_hypo if e(sample)==1, stdp 

gen lb_hypo = xb_hypo - invnormal(0.975)*error_hypo
gen ub_hypo = xb_hypo + invnormal(0.975)*error_hypo
gen plb_hypo = invlogit(lb_hypo)
gen pub_hypo = invlogit(ub_hypo)

* intermediate lactate
mkspline sp_fluid_i = sep1six if intermediate_lactate==1, cubic nknots(3)

svyset hosp [pweight=ps_weight_sickd]

local covar		age male postacutecare priorhosp chf 			///
				liverdisease malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_i? `covar' if intermediate_lactate==1

replace age = 73.9 if intermediate_lactate==1
replace male=0.54 if intermediate_lactate==1
replace postacutecare=0.14 if intermediate_lactate==1
replace priorhosp=0.39 if intermediate_lactate==1
replace liverdisease=0.03 if intermediate_lactate==1
replace chf=0.41 if intermediate_lactate==1
replace malignancy=0.29 if intermediate_lactate==1
replace mortality_predicted=0.18 if intermediate_lactate==1	
replace bmi_calculated=29.8 if intermediate_lactate==1
replace lactatemax_draw=2.79 if intermediate_lactate==1
replace creatinine_high=2.78 if intermediate_lactate==1			
replace ratio_min=324.44 if intermediate_lactate==1
replace mechvent_6hr=0.03 if intermediate_lactate==1
replace vaso_6hrs=0.02 if intermediate_lactate==1
replace alter_mental_status=0.44 if intermediate_lactate==1
replace charlson = 5.15 if intermediate_lactate==1
replace max_temp = 2.86 if intermediate_lactate==1
replace min_sysbp = 2.81 if intermediate_lactate==1
replace max_rr = 3.04 if intermediate_lactate==1
replace max_hr = 3.68 if intermediate_lactate==1
replace wbc_high = 15.24 if intermediate_lactate==1
replace bilirubin_high = 0.99 if intermediate_lactate==1
replace platelets_low = 244.63 if intermediate_lactate==1

predict pr_mort_il if e(sample)==1
predict xb_il if e(sample)==1, xb 
predict error_il if e(sample)==1, stdp 

gen lb_il = xb_il - invnormal(0.975)*error_il
gen ub_il = xb_il + invnormal(0.975)*error_il
gen plb_il = invlogit(lb_il)
gen pub_il = invlogit(ub_il)

sum pr_mort_hypo pr_mort_il

rename plb_il plb1 
rename pub_il pub1
rename pr_mort_il pr_mort1 
rename plb_hypo plb0
rename pub_hypo pub0 
rename pr_mort_hypo pr_mort0
							   
foreach var in plb1 pub1 pr_mort1 plb0 pub0 pr_mort0 {
	gen `var'_pct = `var'*100
}

sum sep1six
gen byte include = sep1six <= 80						   				   
sort sep1six	
graph twoway (rarea plb1_pct pub1_pct sep1six if include, fcolor("0 114 178*0.80") lwidth(none)) ///
				(line pr_mort1_pct sep1six if include,			///
						title("Sep-1", size(medlarge))	///
						xtitle("Fluid in first 6 hrs (ml/kg)", size(med) margin(medium)) ///
						ytitle("Probability 30-day mortality (%)", size(med) margin(medium)) ///
						yscale(range(0 40)) ylabel(0(10)40) ///
						lcolor("0 114 178*1.25"))  	///						
			 || (rarea plb0_pct pub0_pct sep1six if include, fcolor("230 159 0*0.70") lwidth(none)) ///
					(line pr_mort0_pct sep1six if include, lcolor("230 159 0*1.5") lpattern(dash))	///
			 || , legend(order(4 "Hypoperfused" 2 "Intermediate Lactate" )	///
					symysize (6) size(small)) name("ckdsep1", replace)			
				
restore

				
*************
* Pragmatic *
*************

*--------------------------------------------------
* spline analysis for hypoperfused
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if hypoperfused==1 & kidneydisease==1

sum pragmaticsix, de

* fit model with different number of knots
mkspline sp_fluid_3nk = pragmaticsix, cubic nknots(3)
mkspline sp_fluid_4nk = pragmaticsix, cubic nknots(4)
mkspline sp_fluid_5nk = pragmaticsix, cubic nknots(5)
				
logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_phckd]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_phckd]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_phckd]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*--------------------------------------------------
* spline analysis for intermediate lactate
*--------------------------------------------------

* first compare AIC/BIC of models to select number of splines to use
preserve

keep if intermediate_lactate==1 & kidneydisease==1

sum pragmaticsix, de

* fit model with different number of knots
mkspline sp_fluid_3nk = pragmaticsix, cubic nknots(3)
mkspline sp_fluid_4nk = pragmaticsix, cubic nknots(4)
mkspline sp_fluid_5nk = pragmaticsix, cubic nknots(5)
		

logit mortality_30day c.sp_fluid_3nk? [pweight=ps_weight_pickd]
est store model3nk
estat ic

logit mortality_30day c.sp_fluid_4nk? [pweight=ps_weight_pickd]
est store model4nk
estat ic

logit mortality_30day c.sp_fluid_5nk? [pweight=ps_weight_pickd]
est store model5nk
estat ic

esttab model3nk model4nk model5nk, stats(aic bic, fmt(2 2)) 

restore 

*---------------------------
* descriptive statistics  
*---------------------------

preserve

	keep if hypoperfused==1 & kidneydisease==1

	svyset hosp [pweight=ps_weight_phckd]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 

preserve

	keep if intermediate_lactate==1 & kidneydisease==1

	svyset hosp [pweight=ps_weight_pickd]

	svy: mean age
	svy: tab male
	svy: tab postacutecare
	svy: tab priorhosp
	svy: tab kidneydisease
	svy: tab liverdisease
	svy: tab chf
	svy: tab malignancy
	svy: mean mortality_predicted
	svy: mean bmi_calculated
	svy: mean lactatemax_draw
	svy: mean creatinine_high
	svy: mean ratio_min
	svy: tab mechvent_6hr
	svy: tab vaso_6hrs
	svy: tab alter_mental_status
	svy: mean charlson
	svy: mean max_temp
	svy: mean min_sysbp
	svy: mean max_rr
	svy: mean max_hr
	svy: mean wbc_high
	svy: mean bilirubin_high
	svy: mean platelets_low

restore 


*---------------------------------
* create twoway line graph 
*---------------------------------

preserve 

keep if kidneydisease==1

* hypoperfused
mkspline sp_fluid_h = pragmaticsix if hypoperfused==1, cubic nknots(3)

svyset hosp [pweight=ps_weight_phckd]


local covar		age male postacutecare priorhosp chf 			///
				liverdiseas  malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_h? `covar' if hypoperfused==1

replace age = 73.1 if hypoperfused==1
replace male=0.51 if hypoperfused==1
replace postacutecare=0.21 if hypoperfused==1
replace priorhosp=0.41 if hypoperfused==1
replace liverdisease=0.05 if hypoperfused==1
replace chf=0.42 if hypoperfused==1
replace malignancy=0.27 if hypoperfused==1
replace mortality_predicted=0.33 if hypoperfused==1	
replace bmi_calculated=29.4 if hypoperfused==1
replace lactatemax_draw=4.30 if hypoperfused==1
replace creatinine_high=3.30 if hypoperfused==1			
replace ratio_min=290.85 if hypoperfused==1
replace mechvent_6hr=0.13 if hypoperfused==1
replace vaso_6hrs=0.32 if hypoperfused==1
replace alter_mental_status=0.58 if hypoperfused==1
replace charlson = 5.10 if hypoperfused==1
replace max_temp = 2.39 if hypoperfused==1
replace min_sysbp = 1.49 if hypoperfused==1
replace max_rr = 3.31 if hypoperfused==1
replace max_hr = 3.52 if hypoperfused==1
replace wbc_high = 15.68 if hypoperfused==1
replace bilirubin_high = 1.20 if hypoperfused==1
replace platelets_low = 233.84 if hypoperfused==1


predict pr_mort_hypo if e(sample)==1
predict xb_hypo if e(sample)==1, xb 
predict error_hypo if e(sample)==1, stdp 

gen lb_hypo = xb_hypo - invnormal(0.975)*error_hypo
gen ub_hypo = xb_hypo + invnormal(0.975)*error_hypo
gen plb_hypo = invlogit(lb_hypo)
gen pub_hypo = invlogit(ub_hypo)

* intermediate lactate
mkspline sp_fluid_i = pragmaticsix if intermediate_lactate==1, cubic nknots(3)

svyset hosp [pweight=ps_weight_pickd]

local covar		age male postacutecare priorhosp chf 			///
				liverdisease malignancy mortality_predicted 		///
				bmi_calculated lactatemax_draw creatinine_high 			///
				ratio_min mechvent_6hr vaso_6hrs alter_mental_status	///
				charlson max_temp min_sysbp max_rr max_hr wbc_high		///
				bilirubin_high platelets_low

				
svy: logit mortality_30day c.sp_fluid_i? `covar' if intermediate_lactate==1

replace age = 73.7 if intermediate_lactate==1
replace male=0.54 if intermediate_lactate==1
replace postacutecare=0.14 if intermediate_lactate==1
replace priorhosp=0.39 if intermediate_lactate==1
replace liverdisease=0.03 if intermediate_lactate==1
replace chf=0.41 if intermediate_lactate==1
replace malignancy=0.28 if intermediate_lactate==1
replace mortality_predicted=0.18 if intermediate_lactate==1	
replace bmi_calculated=29.8 if intermediate_lactate==1
replace lactatemax_draw=2.79 if intermediate_lactate==1
replace creatinine_high=2.66 if intermediate_lactate==1			
replace ratio_min=325.20 if intermediate_lactate==1
replace mechvent_6hr=0.03 if intermediate_lactate==1
replace vaso_6hrs=0.02 if intermediate_lactate==1
replace alter_mental_status=0.45 if intermediate_lactate==1
replace charlson = 5.15 if intermediate_lactate==1
replace max_temp = 2.85 if intermediate_lactate==1
replace min_sysbp = 2.81 if intermediate_lactate==1
replace max_rr = 3.04 if intermediate_lactate==1
replace max_hr = 3.68 if intermediate_lactate==1
replace wbc_high = 15.23 if intermediate_lactate==1
replace bilirubin_high = 0.98 if intermediate_lactate==1
replace platelets_low = 245.16 if intermediate_lactate==1

predict pr_mort_il if e(sample)==1
predict xb_il if e(sample)==1, xb 
predict error_il if e(sample)==1, stdp 

gen lb_il = xb_il - invnormal(0.975)*error_il
gen ub_il = xb_il + invnormal(0.975)*error_il
gen plb_il = invlogit(lb_il)
gen pub_il = invlogit(ub_il)

sum pr_mort_hypo pr_mort_il

rename plb_il plb1 
rename pub_il pub1
rename pr_mort_il pr_mort1 
rename plb_hypo plb0
rename pub_hypo pub0 
rename pr_mort_hypo pr_mort0
							   
foreach var in plb1 pub1 pr_mort1 plb0 pub0 pr_mort0 {
	gen `var'_pct = `var'*100
}

sum pragmaticsix
gen byte include = pragmaticsix <= 80						   				   
sort pragmaticsix	
graph twoway (rarea plb1_pct pub1_pct pragmaticsix if include, fcolor("0 114 178*0.80") lwidth(none)) ///
				(line pr_mort1_pct pragmaticsix if include,			///
						title("Pragmatic", size(medlarge))	///
						xtitle("Fluid in first 6 hrs (ml/kg)", size(med) margin(medium)) ///
						ytitle("Probability 30-day mortality (%)", size(med) margin(medium)) ///
						yscale(range(0 40)) ylabel(0(10)40) ///
						lcolor("0 114 178*1.25"))  	///						
			 || (rarea plb0_pct pub0_pct pragmaticsix if include, fcolor("230 159 0*0.70") lwidth(none)) ///
					(line pr_mort0_pct pragmaticsix if include, lcolor("230 159 0*1.5") lpattern(dash))	///
			 || , legend(order(4 "Hypoperfused" 2 "Intermediate Lactate" )	///
					symysize (6) size(small)) name("ckdprag", replace)			
	
restore

