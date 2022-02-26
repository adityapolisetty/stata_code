
* OLS - 1950-60 data 
// use "$out_files/Final_dataset.dta"

* RDD - 1940-2000 data 
// use "$out_files/Final_dataset_rdd.dta"

/* =========================================================================== */
/*  						SUMMARY STATS 			 		   				   */
/* =========================================================================== */

log using summstats_cond1only
* Nutrition Summary Stats Table 
foreach x in age sex Energykcal Fatg Proteing Carbohydrateg Englystfibreg Totalsugarsg FreeSugarsg recommended10 recommended5 lintrin_lactose_excl_calc lNonmilkextrinsicsugarsg any_fruit any_veggies any_sweets {

	sum `x' if condition_usual_2==1 & Sep_cutoff==0 
	sum `x' if condition_usual_2==1 & Sep_cutoff==1
}

eststo clear
estpost summarize age sex Energykcal Fatg Proteing Carbohydrateg Englystfibreg Nonmilkextrinsicsugarsg FreeSugarsg intrin_lactose_excl_calc recommended10 recommended5 any_fruit any_veggies any_sweets any_meat any_dairy if condition_usual_2==1  & Sep_cutoff==0, 
esttab using  "$tables/nutrition_sum_1.tex", label title(Summary Statistics for Adults Born in 1950-1960.) cells(" mean(fmt(2) label (Mean)) sd(fmt(2) label (SD)) ") replace nomtitle nonum noobs 

eststo clear
estpost summarize  age sex Energykcal Fatg Proteing Carbohydrateg Englystfibreg Nonmilkextrinsicsugarsg FreeSugarsg intrin_lactose_excl_calc recommended10 recommended5 any_fruit any_veggies any_sweets any_meat any_dairy if condition_usual_2==1 & Sep_cutoff==1
esttab using  "$tables/nutrition_sum_2.tex", label title(Summary Statistics for Adults Born in 1950-1960.) cells(" mean(fmt(2) label (Mean)) sd(fmt(2) label (SD)) ")replace nomtitle nonum noobs 


distinct ISerialB if condition_usual_2==1  & Sep_cutoff==0 
distinct ISerialB if condition_usual_2==1 & Sep_cutoff==1

log close

translate summstats_cond1only.smcl summstats_cond1only.pdf

/* =========================================================================== */
/*    		 				OLS REGRESSIONS - NUTRITION 		 		   	   */
/* =========================================================================== */


* 1950 - 60 window - *** Used in final results *** 

eststo clear

foreach z in condition_usual_2 {

	eststo:  areg lEnergykcal i.Sep_cutoff dev i.eth i.sex i.DayofWeek i.diarymth if  `z' == 1  , a(SurveyYear) cluster(ISerialB) 


	foreach x in lFatg lProteing lCarbohydrateg recommended5 lFreeSugarsg lintrin_lactose_excl_calc lEnglystfibreg      ///
	  any_veggies any_fruit  any_sweets_2 any_meat {

		eststo:  areg `x' i.Sep_cutoff dev lEnergykcal i.eth i.sex i.DayofWeek i.diarymth if `z' == 1 , a(SurveyYear) cluster(ISerialB)

	}

}

estout using "$tables/dietoutcomes_OLS.tex", replace label   ///
cells(b(star fmt(3)) se(par fmt(3)) p( fmt(3)))  ///
stats( /*ci_rb*/ /*kernel bwselect N se_tau_cl*/ /*pv_cl*/ /* se_tau_rb*/ /*pv_rb*/ /* p q h_r b_r*/, ///
labels(/*"Robust 95\% CI"*/ /*"Kernel Type" "BW Type" "Observations"  "Conventional Std. Error"*/ /*"Conventional p-value"*/ ///
/* "Robust Std. Error"*/ /* "Robust p-value"*/ /* "Order Loc. Poly. (p)" "Order Bias (q)" "BW Loc. Poly. (h)" "BW Bias (b)"*/) ///
fmt( /*%9.2f*/ /* %9.2f %9.2f*/ %9.0f /*%9.3f*/ %9.2f /*%9.3f*/ %9.2f /* %9.3f %9.3f %9.3f*/)) ///
starlevels(* 0.1 ** 0.05 *** 0.01) varwidth(15) mlabels(, none) collabels(, none) ///
prefoot("\midrule") substitute(_ \_) style(tex)


* Pre-cutoff means
eststo clear
estpost tabstat Energykcal Fatg Proteing Carbohydrateg recommended5 FreeSugarsg intrin_lactose_excl_calc Englystfibreg any_veggies any_fruit  any_sweets_2   any_meat if condition_usual_2==1 & Sep_cutoff==0, statistics(N mean)

esttab using "$tables/dietoutcomes_OLS_mean.tex", cells("Energykcal(fmt(2)) Fatg(fmt(2)) Proteing(fmt(2)) Carbohydrateg(fmt(2)) recommended5(fmt(2)) FreeSugarsg(fmt(2)) intrin_lactose_excl_calc(fmt(2)) Englystfibreg(fmt(2)) any_veggies(fmt(2)) any_fruit(fmt(2)) any_sweets_2(fmt(2)) any_meat(fmt(2))") nomtitle nonumber replace

/* =========================================================================== */
/*  						RDD REGRESSIONS - NUTRITION 		 		   	   */
/* =========================================================================== */

* RDD
eststo clear
foreach z in condition_usual_2 {	

	foreach x in lEnergykcal {

		eststo: rdrobust `x' birthqtr_rdd if `z'== 1 & birthqtr_rdd>80 &   birthqtr_rdd<321  , c(136) vce(cluster ISerialB) kernel(uniform) bwselect(msecomb2)

	}
	
		foreach x in lFatg lProteing lCarbohydrateg recommended5 lFreeSugarsg  lintrin_lactose_excl_calc lEnglystfibreg {

		eststo: rdrobust `x'   birthqtr_rdd if `z'== 1 & birthqtr_rdd>80 &   birthqtr_rdd<321 , c(136) vce(cluster ISerialB) kernel(uniform) bwselect(msecomb2)

	}

	foreach x in   any_veggies any_fruit  any_sweets recommended10 any_meat any_dairy {

		eststo: rdrobust `x'   birthqtr_rdd if `z'== 1 & birthqtr_rdd>80 &   birthqtr_rdd<321  , c(136) vce(cluster ISerialB) kernel(uniform) bwselect(msecomb2)
	
	}
}
estout using "$tables/dietoutcomes_RDD.tex", replace label   ///
cells(b(star fmt(3)) se(par fmt(3))) ///
stats( /*ci_rb*/ /*kernel bwselect N se_tau_cl*/ /*pv_cl*/ /* se_tau_rb*/ /*pv_rb*/ /* p q h_r b_r*/, ///
labels(/*"Robust 95\% CI"*/ /*"Kernel Type" "BW Type" "Observations"  "Conventional Std. Error"*/ /*"Conventional p-value"*/ ///
/* "Robust Std. Error"*/ /* "Robust p-value"*/ /* "Order Loc. Poly. (p)" "Order Bias (q)" "BW Loc. Poly. (h)" "BW Bias (b)"*/) ///
fmt( /*%9.2f*/ /* %9.2f %9.2f*/ %9.0f /*%9.3f*/ %9.2f /*%9.3f*/ %9.2f /* %9.3f %9.3f %9.3f*/)) ///
starlevels(* 0.1 ** 0.05 *** 0.01) varwidth(15) mlabels(, none) collabels(, none) ///
prefoot("\midrule") substitute(_ \_) style(tex)


// Mean before cutoffs

foreach x in Energykcal Fatg Proteing Carbohydrateg recommended5 FreeSugarsg intrin_lactose_excl_calc Englystfibreg any_veggies any_fruit  any_sweets recommended10 any_meat any_dairy {

	sum `x' if condition_usual_2==1 & birthqtr_rdd<136 & birthqtr_rdd>80

}

/* =========================================================================== */
/* 						ROMANO-WOLF MULTI-HYPO TEST 			 		   	   */
/* =========================================================================== */

rename lintrin_lactose_excl_calc intrin

*** OLS 
local depvars  " lFatg lProteing lCarbohydrateg recommended5 lFreeSugarsg  intrin lEnglystfibreg any_veggies any_fruit  any_sweets_2 any_meat "

rwolf `depvars' if condition_usual_2 == 1  , indepvar(Sep_cutoff) method(areg) ///
controls(lEnergykcal dev i.eth i.sex i.DayofWeek i.diarymth)  seed(1) reps(3500) verbose vce(cluster ISerialB)  a(SurveyYear)
rename  intrin lintrin_lactose_excl_calc

/* =========================================================================== */
/*  						  BINS SCATTER - NUTRITION 		 		   		   */
/* =========================================================================== */

binscatter lFreeSugarsg BirthYear if condition_usual_2 == 1 , /// 
rd(1954) controls(lEnergykcal) ytitle(Log(Free Sugars [g])) ylabel(3(0.1)4, nogrid) xtitle(Birth Year) ///
xlabel(1950(1)1960, valuelabel nogrid) legend(off)   /// 
mcolors(black) lcolors(black) msymbols(O) ///
linetype(lfit) nquantiles(20) scheme(plotplain) xsize(5.5) ysize(4)
graph export "$figures/lFreeSugarsg_v1.png", width(900) height(600) replace

binscatter any_sweets_2  BirthYear if condition_usual_2 == 1  , ///
rd(1954) controls(lEnergykcal) ytitle(Any Sweets [g]) ylabel(0(0.1)0.7, nogrid) xtitle(Birth Year) ///
xlabel(1950(1)1960, valuelabel nogrid) legend(off)   /// 
mcolors(black) lcolors(black) msymbols(O) ///
linetype(lfit) nquantiles(20) scheme(plotplain) xsize(5.5) ysize(4)
graph export "$figures/any_sweets_v1.png", width(900) height(600) replace

binscatter lEnergykcal  BirthYear if condition_usual_2 == 1 , /// 
rd(1954) ytitle(Log(Total Kcal)) ylabel(7(0.1)8, nogrid) xtitle(Birth Year) ///
xlabel(1950(1)1960, valuelabel nogrid) legend(off)  /// 
mcolors(black) lcolors(black) msymbols(O) ///
linetype(lfit) nquantiles(20) scheme(plotplain) xsize(5.5) ysize(4)
graph export "$figures/lEnergykcal_v1.png", width(900) height(600) replace

binscatter lFatg  BirthYear if condition_usual_2 == 1 , ///
rd(1954) controls(lEnergykcal ) ytitle(Log(Fats [g])) ylabel(3.5(0.1)4.5, nogrid) xtitle(Birth Year) ///
xlabel(1950(1)1960, valuelabel nogrid) legend(off)   /// 
mcolors(black) lcolors(black) msymbols(O) ///
linetype(lfit) nquantiles(20) scheme(plotplain) xsize(5.5) ysize(4)
graph export "$figures/lFatg_v1.png", width(900) height(600)replace

binscatter lProteing BirthYear if condition_usual_2 == 1 , ///
rd(1954) controls(lEnergykcal ) ytitle(Log(Protein [g])) ylabel(4(0.1)5, nogrid) xtitle(Birth Year) ///
xlabel(1950(1)1960, valuelabel nogrid) legend(off)  /// 
mcolors(black) lcolors(black) msymbols(O) ///
linetype(lfit) nquantiles(20) scheme(plotplain) xsize(5.5) ysize(4)
graph export "$figures/lProteing_v1.png", width(900) height(600)replace

 
binscatter recommended5  BirthYear if condition_usual_2 == 1 , ///
rd(1954) controls(lEnergykcal ) ytitle(Share with >=5% of free sugars in TEI) ylabel(0.4(0.1)1, nogrid) xtitle(Birth Year) ///
xlabel(1950(1)1960, valuelabel nogrid) legend(off)   /// 
mcolors(black) lcolors(black) msymbols(O) ///
linetype(lfit) nquantiles(20) scheme(plotplain) xsize(5.5) ysize(4)
graph export "$figures/recommended5_v1.png", width(900) height(600)replace
 

binscatter any_fruit  BirthYear if condition_usual_2 == 1  , ///
rd(1954)  controls(lEnergykcal) ytitle(Any Fruits) ylabel(0.3(0.1)1, nogrid) xtitle(Birth Year) ///
xlabel(1950(1)1960, valuelabel nogrid) legend(off)  /// 
mcolors(black) lcolors(black) msymbols(O) ///
linetype(lfit) nquantiles(20) scheme(plotplain) xsize(5.5) ysize(4)
graph export "$figures/any_fruit_v1.png", width(900) height(600)replace

binscatter any_veggies  BirthYear if condition_usual_2 == 1 , ///
rd(1954) controls(lEnergykcal) ytitle(Any Vegetables) ylabel(0(0.1)1, nogrid) xtitle(Birth Year) ///
xlabel(1950(1)1960, valuelabel nogrid) legend(off)   /// 
mcolors(black) lcolors(black) msymbols(O) ///
linetype(lfit) nquantiles(20) scheme(plotplain) xsize(5.5) ysize(4)
graph export "$figures/any_veggies_v1.png", width(900) height(600) replace

binscatter any_meat  BirthYear if condition_usual_2 == 1 , ///
rd(1954) controls(lEnergykcal) ytitle(Any Meat) ylabel(0(0.1)1, nogrid) xtitle(Birth Year) ///
xlabel(1950(1)1960, valuelabel nogrid) legend(off)   /// 
mcolors(black) lcolors(black) msymbols(O) ///
linetype(lfit) nquantiles(20) scheme(plotplain) xsize(5.5) ysize(4)
graph export "$figures/any_meat_v1.png", width(900) height(600) replace
 

binscatter lintrin_lactose_excl_calc  BirthYear if condition_usual_2 == 1 , ///
rd(1954)   controls(lEnergykcal) ytitle( Log(Intrinsic Sugars [g]) ) ylabel(2.5(0.1)3.5, nogrid) xtitle(Birth Year) ///
xlabel(1950(1)1960, valuelabel nogrid) legend(off) /// 
mcolors(black) lcolors(black) msymbols(O) ///
linetype(lfit) nquantiles(20) scheme(plotplain) xsize(5.5) ysize(4)
graph export "$figures/lintrin_lactose_excl_calc_v1.png", width(900) height(600) replace

binscatter lEnglystfibreg  BirthYear if condition_usual_2 == 1  , ///
rd(1954) controls(lEnergykcal) ytitle( Log(Fibre [g]) ) ylabel(2(0.1)3, nogrid) xtitle(Birth Year) ///
xlabel(1950(1)1960, valuelabel nogrid) legend(off)   /// 
mcolors(black) lcolors(black) msymbols(O) ///
linetype(lfit) nquantiles(20) scheme(plotplain) xsize(5.5) ysize(4)
graph export "$figures/lEnglystfibreg_v1.png", width(900) height(600) replace

binscatter lCarbohydrateg  BirthYear if condition_usual_2 == 1 , ///
rd(1954) controls(lEnergykcal) ytitle(Log(Carbohydrate [g])) ylabel(4.5(0.1)5.5, nogrid) xtitle(Birth Year) ///
xlabel(1950(1)1960, valuelabel nogrid) legend(off)   /// 
mcolors(black) lcolors(black) msymbols(O) ///
linetype(lfit) nquantiles(20) scheme(plotplain) xsize(5.5) ysize(4)
graph export "$figures/lCarbohydrateg_v1.png", width(900) height(600) replace

/* =========================================================================== */
/* 						SUMMARY STATS - HEALTH 			 		   			   */
/* =========================================================================== */

* Health Summary Stats Table 

foreach x in obese_valid obese_waist_3 obese_whr_2 obese_any {

	sum `x' if condition_usual_health==1 & DV==1 & Sep_cutoff==0 
	sum `x' if condition_usual_health==1 & DV==1 & Sep_cutoff==1 
	
}
eststo clear
estpost summarize obese_valid obese_waist_3  obese_whr_2 obese_any if condition_usual_health==1 & DV==1 & Sep_cutoff==0 
esttab using  "$tables/health_sum_1.tex", label title(Summary Statistics for Adults Born in 1950-1960.) cells(" mean(fmt(3) label (Mean)) sd(fmt(3) label (SD)) ")replace nomtitle nonum noobs
				

eststo clear
estpost summarize obese_valid obese_waist_3 obese_whr_2 obese_any if condition_usual_health==1 & DV==1 & Sep_cutoff==1 
esttab using  "$tables/health_sum_2.tex", label title(Summary Statistics for Adults Born in 1950-1960.) cells(" mean(fmt(3) label (Mean)) sd(fmt(3) label (SD)) ")replace nomtitle nonum noobs 

distinct ISerialB if condition_usual_health==1 & DV==1 & Sep_cutoff==0
distinct ISerialB if condition_usual_health==1 & DV==1 & Sep_cutoff==1


foreach x in obese_valid obese_waist_3 obese_whr_2 obese_any {

	sum `x' if condition_usual_health==1 & DV==1 & Sep_cutoff==0 & BirthYear>1951  & BirthYear<1959
	sum `x' if condition_usual_health==1 & DV==1 & Sep_cutoff==1 & BirthYear>1951  & BirthYear<1959
	
}

distinct ISerialB if condition_usual_health==1 & DV==1 & Sep_cutoff==0 & BirthYear>1951  & BirthYear<1959
distinct ISerialB if condition_usual_health==1 & DV==1 & Sep_cutoff==1 & BirthYear>1951  & BirthYear<1959

/* =========================================================================== */
/*    		 				OLS REGRESSIONS - HEALTH	 		 		   	   */
/* =========================================================================== */

*** Regressions

* 1952-58 window - **** used for final results **** 
foreach x in lbmi_valid lwaist obese_valid obese_waist_3  obese_whr_2 obese_any {

	eststo: areg `x' i.Sep_cutoff dev Sep_cutoffXdev i.sex i.age_cat2 if condition_usual_health==1 & DV==1 & BirthYear>1951  & BirthYear<1959, robust a(SurveyYear)

}
estout using "$tables/healthoutcomes_ols.tex", replace label ///
					  cells(b(star fmt(3) vacant({--})) se(par fmt(3))) ///
					  stats( /*ci_rb*/ /*kernel bwselect*/ N /*se_tau_cl*/ /*pv_cl*/ /* se_tau_rb*/ /*pv_rb*/ /* p q h_r b_r*/, ///
							labels(/*"Robust 95\% CI"*/ /*"Kernel Type" "BW Type"*/ "Observations" /* "Conventional Std. Error"*/ /*"Conventional p-value"*/ ///
								   /* "Robust Std. Error"*/ /* "Robust p-value"*/ /* "Order Loc. Poly. (p)" "Order Bias (q)" "BW Loc. Poly. (h)" "BW Bias (b)"*/) ///
							fmt( /*%9.2f*/ /* %9.2f %9.2f*/ %9.0f /*%9.3f*/ %9.2f /*%9.3f*/ %9.2f /* %9.3f %9.3f %9.3f*/)) ///
					  starlevels(* 0.1 ** 0.05 *** 0.01) varwidth(15)  ///
					  mlabels(, none) collabels(, none) ///
					  prefoot("\midrule") ///
					  substitute(_ \_) style(tex)


* Pre-cutoff means - 1952-58 window 
foreach x in bmi_valid wstval obese_valid obese_waist_1 obese_waist_2 obese_waist_3 obese_whr_1 obese_whr_2 obese_any {

	sum `x' if condition_usual_health==1 & DV==1 & Sep_cutoff==0 & BirthYear>1951  & BirthYear<1959
}

/* =========================================================================== */
/*  						RDD REGRESSIONS - HEALTH 		  	 		   	   */
/* =========================================================================== */

* No bandwidth selected - used in results 
eststo clear 

foreach x in  obese_valid obese_waist_3  obese_whr_2 obese_any {

	eststo:	rdrobust `x'   birthqtr_rdd if condition_usual_health== 1 & birthqtr_rdd>80 & birthqtr_rdd<321 & DV==1 , covs(age_cat2 sex) c(136) kernel(tri) bwselect(msecomb2)
	
}

estout using "$tables/healthoutcomes_rdd.tex", replace label ///
					  cells(b(star fmt(3) vacant({--})) se(par fmt(3))) ///
					  stats( /*ci_rb*/ /*kernel bwselect*/ N /*se_tau_cl*/ /*pv_cl*/ /* se_tau_rb*/ /*pv_rb*/ /* p q h_r b_r*/, ///
							labels(/*"Robust 95\% CI"*/ /*"Kernel Type" "BW Type"*/ "Observations" /* "Conventional Std. Error"*/ /*"Conventional p-value"*/ ///
								   /* "Robust Std. Error"*/ /* "Robust p-value"*/ /* "Order Loc. Poly. (p)" "Order Bias (q)" "BW Loc. Poly. (h)" "BW Bias (b)"*/) ///
							fmt( /*%9.2f*/ /* %9.2f %9.2f*/ %9.0f /*%9.3f*/ %9.2f /*%9.3f*/ %9.2f /* %9.3f %9.3f %9.3f*/)) ///
					  starlevels(* 0.1 ** 0.05 *** 0.01) varwidth(15)  ///
					  mlabels(, none) collabels(, none) ///
					  prefoot("\midrule") ///
					  substitute(_ \_) style(tex)


// Mean before cutoffs
foreach x in  obese_valid obese_waist_3  obese_whr_2 obese_any {

		sum `x' if condition_usual_health==1    & birthqtr_rdd<136

}
