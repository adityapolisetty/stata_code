


*** PROJECT: PUTTY CLAY AUTOMATION
*** AUTHOR : ADITYA POLISETTY



/* =========================================================================== */
/* 								CLEANING 									 */
/* =========================================================================== */

*********************************   SES DATA   *********************************
 
*PREFERENCES
 
clear all
capture log close
set more off
set seed 1302
set matsize 10000

*DIRECTORIES
* change your local and global accordingly 

local JM "C:\Eurostat\SES\SES 2002-2014 full set\SES 2014 full set original"


 
* Executing cleaning-do-files for countries with odd data

foreach cty in BG CY DK HR HU LT MT NL PT SE UK{
	
	cd "C:\Eurostat\SES_scripts\cleaning"
	do `cty'.do 
}

* For the rest of the countries the cleaning will be done by main.do here

foreach cty in CZ EE EL ES FR LU LV NO PL RO SK CY HU LT NL PT SE UK FI EE EL ES FR LV NO PL RO SK  {
	
	clear all
	
	cd "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original/`cty'"
	shell rmdir "analysis" /s
	mkdir "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original/`cty'\analysis"
	mkdir "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original/`cty'\analysis\line_plots"
	mkdir "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original/`cty'\analysis\scatter_plots"
	mkdir "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original/`cty'\analysis\scatter_plots\avg_hourly_wage"
	mkdir "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original/`cty'\analysis\scatter_plots\avg_hourly_wage\alt_measure"
	mkdir "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original/`cty'\analysis\scatter_plots\avg_hourly_wage\main_measure"
	
	forvalues i= 2002(4)2018{
			
		import delimited "SES_`cty'_`i'_ANONYM_CD.csv" 
		if `i'==2002{
			gen index = _n  
			drop if index==2   
			export excel "SES_`cty'_`i'_ANONYM_CD.xlsx"  , replace
			clear all
			import excel "SES_`cty'_`i'_ANONYM_CD.xlsx" , firstrow
			cap rename SES 2006 names country  

		}
		
		rename *, lower
		destring key_e year key_l b23 b52 b43 b32 b42, replace
		
		save "SES_`cty'_`i'_ANONYM_CD.dta", replace
		clear all
	}

append using  "SES_`cty'_2002_ANONYM_CD.dta"  "SES_`cty'_2006_ANONYM_CD.dta"  "SES_`cty'_2010_ANONYM_CD.dta" "SES_`cty'_2014_ANONYM_CD.dta" "SES_`cty'_2018_ANONYM_CD.dta", force


* Harmonise the NACE variable 
foreach var in C D E F G H I J K L M N O{
	
	replace nace = "X`var'" if nace=="`var'"
}

drop if nace== "XB"  
drop if nace== "XP" 
drop if nace=="XQ" 
drop if nace=="XR" 
drop if nace=="XS"
drop if nace=="XM" 
drop if nace=="XN" 
drop if nace=="XO" 
drop if nace=="XL"


keep year country key_e key_l b23 b52 b43 b42 b32 nace a13
replace country="`cty'" 

save "SES_master.dta", replace

}

foreach cty in BE BG  CZ  DE EL EE  ES   FR  HU HR  LT  LV NL NO PL PT RO SK  SE    {

append using "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original/`cty'\SES_master.dta" , force
}

destring key_e year key_l b23 b52 b43 b32 b42, replace
drop if country=="GR"
keep year country key_e key_l b23 b52 b43 b42 b32 nace a13

save "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original\master_all.dta", replace

* Restricted to Manufacturing
clear all
use "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original\master_all.dta"

replace nace = "XC" if nace=="C"
drop if nace!="XC" 

* Manual share 
bysort country key_l year: egen tot_emp = count(key_l)

gen manual = .

// MT CY DK EL EE  NL

foreach cty in BE BG  CZ  DE ES   FR  HU HR  LT   LV NO PL RO SK PT SE  EL EE  NL {
	levelsof year if country=="`cty'", local(levels)

	foreach i of local levels {

		replace b23=99 if b23 ==999  
		su b23 if year ==`i' & country=="`cty'"
		replace manual =1 if b23>=70 & b23<=90  & year ==`i' & r(max)<100 & country=="`cty'"
		replace manual =1 if b23>=700 & b23<=900 & year ==`i' &  r(max)>100 & country=="`cty'"

	}
}

bysort country key_l year: egen manual_count = count(manual)
gen manual_share = manual_count/tot_emp

bysort country key_l year: egen manual_weights = sum(b52) if manual==1
bysort country key_l year: egen tot_weight = sum(b52)
gen manual_share_2 = manual_weights/tot_weight

save "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original\reg_1.dta", replace

clear all
use  "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original\reg_1.dta"

gen manual_share_ind_75 =.
gen manual_share_ind_25 =.
gen manual_share_ind_mean = .

gen manual_share_ind_75_alt =.
gen manual_share_ind_25_alt =.
gen manual_share_ind_mean_alt=.
				
foreach cty in  BE BG  CZ  DE EL EE  ES   FR  HU HR  LT  LV NL NO PL PT RO SK  SE    {
	
	forvalues k=2002(4)2018{
		
		sum manual_share if nace=="XC" & year==`k' & country=="`cty'" , d
		replace manual_share_ind_75 = r(p75) if nace=="XC"  & year==`k' & country=="`cty'"

		sum manual_share if nace=="XC" & year==`k' & country=="`cty'", d
		replace manual_share_ind_25 = r(p25) if nace=="XC"  & year==`k'  & country=="`cty'"

		sum manual_share if nace=="XC" & year==`k'& country=="`cty'" , d
		replace manual_share_ind_mean = r(mean) if nace=="XC"  & year==`k' & country=="`cty'"
	
		sum manual_share_2 if nace=="XC" & year==`k' & country=="`cty'", d
		replace manual_share_ind_75_alt = r(p75) if nace=="XC"  & year==`k' & country=="`cty'"

		sum manual_share_2 if nace=="XC" & year==`k'& country=="`cty'" , d
		replace manual_share_ind_25_alt = r(p25) if nace=="XC"  & year==`k' & country=="`cty'"
		
		sum manual_share_2 if nace=="XC" & year==`k'& country=="`cty'" , d
		replace manual_share_ind_mean_alt = r(mean) if nace=="XC"  & year==`k' & country=="`cty'"
	}
}

gen manual_share_gap = manual_share_ind_75 - manual_share_ind_25 
gen manual_share_gap_alt = manual_share_ind_75_alt - manual_share_ind_25_alt  


save "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original\reg_all.dta", replace

*******************************   KLEMS DATA   *********************************

clear all
cd "C:\Eurostat\KLEMS_revised"


foreach cty in BE BG CY DE DK CZ EE EL ES FR FI HU HR IT LT NL LU LV MT SE PL RO SK PT SI {
	
	clear all 
	import excel "C:\Eurostat\KLEMS_revised/`cty'.xlsx", sheet("VA_CP") firstrow 
	foreach v of varlist F-AD {
		local x : variable label `v'
		rename `v' year`x'
	}
	drop if nace_r2_name !="Manufacturing"
	xpose, clear varname
	rename v1 VA
	rename _varname year
	replace year = substr(year,5 , 4) 
	drop if VA==.
	gen Year = real(year) 
	drop year
	save "C:\Eurostat\KLEMS_revised/`cty'_1.dta", replace
	
	clear all
	import excel "C:\Eurostat\KLEMS_revised/`cty'.xlsx", sheet("COMP") firstrow
	foreach v of varlist F-AD {
		local x : variable label `v'
		rename `v' year`x'
	}
	drop if nace_r2_name !="Manufacturing"
	xpose, clear varname
	rename v1 COMP
	rename _varname year
	replace year = substr(year,5 , 4) 
	drop if COMP==.
	gen Year = real(year) 
	drop year
 	merge  1:1 Year using "C:\Eurostat\KLEMS_revised/`cty'_1.dta"
	rename Year year
	drop _merge
	gen country= "`cty'"
	save "C:\Eurostat\KLEMS_revised/`cty'_2.dta", replace 


}

* Merge all countries
clear all
foreach cty in BE BG CY DE DK CZ EE EL ES FR FI HU HR IT LT NL LU LV MT SE PL RO SK PT SI {
	append using "C:\Eurostat\KLEMS_revised/`cty'_2.dta"
}

order country year, first
sort country year

gen comp_va = COMP/VA

save "C:\Eurostat\KLEMS_revised/master.dta", replace

clear all
use "C:\Eurostat\KLEMS_revised/master.dta"

drop if (year!= 2002 & year!=2006 & year!=2010 & year!=2014 & year!=2018)
 
keep year country COMP VA   comp_va   
save "C:\Eurostat\KLEMS_revised/master_SES_analysis_revised.dta", replace

///* =========================================================================== */
///* 								ANALYSIS									 */
///* =========================================================================== */

************************   LFS MANUAL SHARE TABLES   *************************** 

clear all
use "C:\Eurostat\LFS\data\LFS_master"
 
bysort country year: egen tot_emp = count(country)

gen manual = .
foreach cty in BE BG CZ DE EE EL ES FR HU HR  LT   LV NL NO PL RO SE SK PT  {

		replace manual=1 if occ>=700 & occ<=900 & country=="`cty'"

}

bysort country year : egen manual_weights = sum(coeff) if manual==1
bysort country year: egen tot_weight = sum(coeff)
gen manual_share = manual_weights/tot_weight

gen ses_sample = .
foreach x in BG CY CZ DE DK  EE EL ES FR HU HR  LT   LV NL NO PL RO SE SK PT{
	
	forvalues i = 2002(4)2018{
		
		replace ses_sample=1 if year==`i' & country=="`x'"
	}
}

keep if ses_sample==1
save "C:\Eurostat\LFS\data\LFS_master_ses_sample.dta", replace

clear all 
use "C:\Eurostat\LFS\data\LFS_master_ses_sample.dta"

drop if country=="BE"
drop if country=="DE"
drop if country=="CY"
drop if country=="DK" 

gen manual_share_dec = floor(manual_share*1000)/1000

xtable year country, c(mean manual_share) 
version 14.0
putexcel A1 = matrix(r(xtable), names) using LFS_mean.xlsx, replace

xtable year country, c(p25 manual_share) 
version 14.0
putexcel A1 = matrix(r(xtable), names) using LFS_p25.xlsx, replace

xtable year country, c(p50 manual_share) 
version 14.0
putexcel A1 = matrix(r(xtable), names) using LFS_p50.xlsx, replace

xtable year country, c(p75 manual_share) 
version 14.0
putexcel A1 = matrix(r(xtable), names) using LFS_p75.xlsx, replace
 

***********************   SES - MANUAL SHARE TABLES   **************************

clear all
use "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original\SES_tables.dta"

cd "C:\Eurostat\SES_scripts\analysis"
drop if country=="BE"
drop if country=="DE"

gen manual_share_2_dec = floor(manual_share_2*1000)/1000

xtable year country , c(p25 manual_share_2_dec) format(%9.3f) noput
version 14.0
putexcel A1 = matrix(r(xtable), names) using p25.xlsx, replace

xtable year country, c(p50 manual_share_2_dec) format(%9.3f) noput
version 14.0
putexcel A1 = matrix(r(xtable), names) using p50.xlsx, replace

xtable year country, c(p75 manual_share_2_dec) format(%9.3f) noput
version 14.0
putexcel A1 = matrix(r(xtable), names) using p75.xlsx, replace

xtable year country, c(mean manual_share_2_dec) format(%9.3f) noput
version 14.0
putexcel A1 = matrix(r(xtable), names) using avg.xlsx, replace

***********************   SES - WAGE DISTRIBUTION TABLES   *********************

putexcel set "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original\analysis\wage_moments.xlsx", replace

local j = 0
foreach i in p10 p25 p50 p75 p90 mean{
	local j = `j'+1
	local k = (`j')*12
	xtable year country, c(`i' b43)
	putexcel B`k' = ("`i' main hourly wage") 
	local k =`k'+1
	putexcel B`k' = matrix(r(xtable)), names
	local j = `j'+1
	local k = (`j')*12
	xtable year country, c(`i' hrly_wage_alt)
	putexcel B`k' = ("`i' alt hourly wage") 
	local k =`k'+1
	putexcel B`k' = matrix(r(xtable)), names

}


///* =========================================================================== */
///* 						SES-KLEMS 2017 REGRESSIONS							 */
///* =========================================================================== */
 
clear all 
use "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original\reg_all.dta" 

drop if country=="NO"
drop if country=="PL" & year==2002

// merge m:1 year country using "C:\Eurostat\KLEMS/master_SES_analysis.dta"
 

save "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original\reg_all_drop_none.dta", replace

clear all
use "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original\reg_all_drop_none.dta"

egen firm_count = count(key_l), by (key_l year country)
drop if firm_count<15

collapse (mean)   comp_va manual_share_2 manual_share_ind_75 manual_share_ind_75_alt manual_share_ind_25 manual_share_ind_25_alt manual_share_ind_mean manual_share_ind_mean_alt manual_share_gap_alt manual_share_gap, by (year country)

egen country_id=group(country), label
xtset country_id year

gen delta_MSG=.
gen delta_MSG_alt=.
g delta_MS = .
gen delta_MS_alt=.
g delta_man_75 = .
gen delta_man_75_alt = .
g delta_man_25= .
gen delta_man_25_alt = .

bysort country: replace delta_MSG = manual_share_gap[_n] - manual_share_gap[_n-1]
bysort country: replace delta_MS = manual_share_ind_mean[_n] - manual_share_ind_mean[_n-1]
bysort country: replace delta_man_75 = manual_share_ind_75[_n] - manual_share_ind_75[_n-1]
bysort country: replace delta_man_25 = manual_share_ind_25[_n] - manual_share_ind_25[_n-1]


bysort country: replace delta_MSG_alt = manual_share_gap_alt[_n] - manual_share_gap_alt[_n-1]
bysort country: replace delta_MS_alt = manual_share_ind_mean_alt[_n] - manual_share_ind_mean_alt[_n-1]
bysort country: replace delta_man_75_alt = manual_share_ind_75_alt[_n] - manual_share_ind_75_alt[_n-1]
bysort country: replace delta_man_25_alt = manual_share_ind_25_alt[_n] - manual_share_ind_25_alt[_n-1]

gen delta_lab_share= .

bysort country: replace delta_lab_share = comp_va[_n] - comp_va[_n-1]

label var delta_lab_share "DV: Change in Labour Share of Output"
label var delta_MSG_alt "Change in manual share gap"
label var comp_va "DV: Labour Share of Output"
label var manual_share_gap_alt "Manual share gap" 
label var delta_MS_alt "Change in mean manual share"
label var manual_share_ind_mean_alt "Mean manual share"


eststo clear 

* change in labour share in output on change in manual share gap
eststo: xtreg  delta_lab_share delta_MSG_alt  , fe vce( cluster country_id)


* change in labour share in output on change in manual share gap controlling for change in mean manual share
eststo: xtreg  delta_lab_share delta_MSG_alt delta_MS_alt  , fe vce( cluster country_id)

estout using "manual_share_lab.tex", replace label cells(b(star fmt(3))  se(par fmt(3))) starlevels(* 0.1 ** 0.05 *** 0.01) varwidth(15) mlabels(, none) collabels(,none ) prefoot("\midrule") substitute(_ \_) style(tex)   varlabels(_cons Constant)


eststo clear 
* labour share in output on manual share gap
eststo: xtreg  comp_va manual_share_gap_alt  , fe vce( cluster country_id)

* change in labour share in output on change in manual share gap controlling for mean manual share
eststo: xtreg  comp_va manual_share_gap_alt manual_share_ind_mean_alt  , fe vce( cluster country_id) 

estout using "manual_share_compva.tex", replace label cells(b(star fmt(3))  se(par fmt(3))) starlevels(* 0.1 ** 0.05 *** 0.01) varwidth(15) mlabels(, none) collabels(,none ) prefoot("\midrule") substitute(_ \_) style(tex)   varlabels(_cons Constant)


///* =========================================================================== */
///* 						SES-KLEMS 2021 REGRESSIONS							 */
///* =========================================================================== */

clear all 
use "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original\reg_all.dta" 

drop if country=="NO"
drop if country=="PL" & year==2002

merge m:1 year country using "C:\Eurostat\KLEMS_revised/master_SES_analysis_revised.dta"
 

save "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original\reg_all_drop_none.dta", replace

clear all
use "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original\reg_all_drop_none.dta"

egen firm_count = count(key_l), by (key_l year country)
drop if firm_count<15

collapse (mean)   comp_va manual_share_2 manual_share_ind_75 manual_share_ind_75_alt manual_share_ind_25 manual_share_ind_25_alt manual_share_ind_mean manual_share_ind_mean_alt manual_share_gap_alt manual_share_gap, by (year country)

egen country_id=group(country), label
xtset country_id year

gen delta_MSG=.
gen delta_MSG_alt=.
g delta_MS = .
gen delta_MS_alt=.
g delta_man_75 = .
gen delta_man_75_alt = .
g delta_man_25= .
gen delta_man_25_alt = .

bysort country: replace delta_MSG = manual_share_gap[_n] - manual_share_gap[_n-1]
bysort country: replace delta_MS = manual_share_ind_mean[_n] - manual_share_ind_mean[_n-1]
bysort country: replace delta_man_75 = manual_share_ind_75[_n] - manual_share_ind_75[_n-1]
bysort country: replace delta_man_25 = manual_share_ind_25[_n] - manual_share_ind_25[_n-1]


bysort country: replace delta_MSG_alt = manual_share_gap_alt[_n] - manual_share_gap_alt[_n-1]
bysort country: replace delta_MS_alt = manual_share_ind_mean_alt[_n] - manual_share_ind_mean_alt[_n-1]
bysort country: replace delta_man_75_alt = manual_share_ind_75_alt[_n] - manual_share_ind_75_alt[_n-1]
bysort country: replace delta_man_25_alt = manual_share_ind_25_alt[_n] - manual_share_ind_25_alt[_n-1]

gen delta_lab_share= .

bysort country: replace delta_lab_share = comp_va[_n] - comp_va[_n-1]

label var delta_lab_share "DV: Change in Labour Share of Output"
label var delta_MSG_alt "Change in manual share gap"
label var comp_va "DV: Labour Share of Output"
label var manual_share_gap_alt "Manual share gap" 
label var delta_MS_alt "Change in mean manual share"
label var manual_share_ind_mean_alt "Mean manual share"


eststo clear 

* change in labour share in output on change in manual share gap
eststo: xtreg  delta_lab_share delta_MSG_alt  , fe vce( cluster country_id)


* change in labour share in output on change in manual share gap controlling for change in mean manual share
eststo: xtreg  delta_lab_share delta_MSG_alt delta_MS_alt  , fe vce( cluster country_id)

estout using "manual_share_lab_2018.tex", replace label cells(b(star fmt(3))  se(par fmt(3))) starlevels(* 0.1 ** 0.05 *** 0.01) varwidth(15) mlabels(, none) collabels(,none ) prefoot("\midrule") substitute(_ \_) style(tex)   varlabels(_cons Constant)


eststo clear 
* labour share in output on manual share gap
eststo: xtreg  comp_va manual_share_gap_alt  , fe vce( cluster country_id)

* change in labour share in output on change in manual share gap controlling for mean manual share
eststo: xtreg  comp_va manual_share_gap_alt manual_share_ind_mean_alt  , fe vce( cluster country_id) 

estout using "manual_share_compva_2018.tex", replace label cells(b(star fmt(3))  se(par fmt(3))) starlevels(* 0.1 ** 0.05 *** 0.01) varwidth(15) mlabels(, none) collabels(,none ) prefoot("\midrule") substitute(_ \_) style(tex)   varlabels(_cons Constant)

///* =========================================================================== */
///* 							ROBOT REGRESSIONS							 	*/
///* =========================================================================== */

clear all
use "C:\Eurostat\robot_data/robot_data.dta"
merge 1:1 year country using "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original\SES_tables_collapsed_Robot.dta"
drop if _merge!=3
drop _merge

merge 1:1 year country using "C:\Eurostat\robot_data/operationalstock.dta"
drop if _merge!=3		

gen robot_worker_ratio=.
bysort country (year) : replace robot_worker_ratio = operationalstock/tot_emp

egen std_robot_worker_ratio = std(robot_worker_ratio) 

gen delta_robot_worker=.
bysort country (year) : replace delta_robot_worker = std_robot_worker_ratio[_n] - std_robot_worker_ratio[_n-1]

gen lag_delta_robot_worker=.
bysort country (year) : replace lag_delta_robot_worker = delta_robot_worker[_n-1]  

eststo clear 

eststo: xtreg  delta_manual_75_alt  std_installations_alt , fe vce(cluster country_id)
eststo: xtreg delta_manual_25_alt std_installations_alt , fe vce(cluster country_id)
eststo: xtreg delta_MS_alt std_installations_alt , fe vce(cluster country_id)

estout using "manual_share_robot_1.tex", replace label cells(b(star fmt(3))  se(par fmt(3))) starlevels(* 0.1 ** 0.05 *** 0.01) varwidth(15) mlabels(, none) collabels(,none ) prefoot("\midrule") substitute(_ \_) style(tex)   varlabels(_cons Constant)

eststo clear 

eststo: xtreg  delta_manual_75_alt  delta_robot_worker , fe vce(cluster country_id)
eststo: xtreg delta_manual_25_alt delta_robot_worker , fe vce(cluster country_id)
eststo: xtreg delta_MS_alt delta_robot_worker , fe vce(cluster country_id)

estout using "manual_share_robot_2.tex", replace label cells(b(star fmt(3))  se(par fmt(3))) starlevels(* 0.1 ** 0.05 *** 0.01) varwidth(15) mlabels(, none) collabels(,none ) prefoot("\midrule") substitute(_ \_) style(tex)   varlabels(_cons Constant)

///* =========================================================================== */
///* 							 COMPNET REGRESSIONS							 */
///* =========================================================================== */

clear all
use "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original\reg_all_drop_none.dta"

egen firm_count = count(key_l), by (key_l year country)
drop if firm_count<15
 
collapse (mean) lab_va comp_va manual_share_2 manual_share_ind_75 manual_share_ind_75_alt manual_share_ind_25 manual_share_ind_25_alt manual_share_ind_mean manual_share_ind_mean_alt manual_share_gap_alt manual_share_gap, by (year country)


egen cid=group(country), label
xtset cid year

merge m:1 year country using "C:\Compnet\JointDistributions\descriptives_manuf.dta"

rename LR01_lc_va_mn lc_va
rename LR00_lc_rev_mn lc_rev

sort country year 

gen delta_MSG_alt = .
bysort country : replace delta_MSG_alt = manual_share_gap_alt[_n] - manual_share_gap_alt[_n-1]

sort country year
gen delta_lc_va= .
bysort country : replace delta_lc_va = lc_va[_n] - lc_va[_n-1]

label var manual_share_gap_alt "Mean manual share gap"

eststo clear 

* labour share from KLEMS on manual share gap
eststo: xtreg comp_va manual_share_gap_alt , fe vce(cluster cid)

* labour share in value added from COMPNET on manual share gap
eststo: xtreg lc_va manual_share_gap_alt , fe vce(cluster cid)

* labour share in revenue from COMPNET on manual share gap
eststo: xtreg lc_rev manual_share_gap_alt , fe vce(cluster cid)

estout using "compnet.tex", replace label cells(b(star fmt(3))  se(par fmt(3))) starlevels(* 0.1 ** 0.05 *** 0.01) varwidth(15) mlabels(, none) collabels(,none ) prefoot("\midrule") substitute(_ \_) style(tex)   varlabels(_cons Constant)

///* =========================================================================== */
///* 									PLOTS									 */
///* =========================================================================== */

* Wage vs manual share
clear all
use "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original\reg_1.dta"


bysort key_l year: egen total_weight_firm = sum(b52)
gen weight_firm = b52/total_weight_firm

gen hrly_wage_alt = b42/b32
bysort key_l year: egen avg_hrly_wage_manual_alt = sum(hrly_wage_alt*weight_firm)  if manual==1

bysort key_l year: egen avg_hrly_wage_manual = sum(b43*weight_firm) if manual==1 

label var avg_hrly_wage_manual_alt "Average Hourly Wage" 
label var manual_share_2 "Manual Share" 

levelsof country, local(levels)
drop if avg_hrly_wage_manual>200

foreach i of local levels {
	
	graph twoway scatter avg_hrly_wage_manual_alt manual_share_2  if country=="`i'", mcolor(black) msize(1) graphregion(color(white)) plotregion(color(white))
	graph export "C:\Eurostat\SES2021\SES_2002-2018_full_set\SES_2002-2018_original\analysis/`i'.png", width(1920) height(1080) replace

}