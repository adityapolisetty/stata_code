
*------------------------------------------------------------------------------
*PREFERENCES
*------------------------------------------------------------------------------ 
clear all
capture log close
set more off
set seed 1302
set matsize 11000

*------------------------------------------------------------------------------
*DIRECTORIES
*------------------------------------------------------------------------------

* change your local and global accordingly 
// cd "C:\Users\K2149424\OneDrive - King's College London\Gracner_&_Bai\ra_work\health"

local TG "OneDrive - King's College London\Gracner_&_Bai\ra_work\health"

* add your locals here and change it below (eg., local AD or MS) 

global in_files "~/`TG'/Data/In"
global out_files "~/`TG'/Data/Out"
global tables "~/`TG'/tables"
global figures "~/`TG'/figures"
global tex "~/`TG'/tex"
global dos "~/`TG'/dos"
global logs "~/`TG'/log"
global manuscripts "~`TG'/Manuscripts"

/* =========================================================================== */
/*  							CLEANING DATASETS 							   */
/* =========================================================================== */

**************************** Day nutrient level data - 22 Oct 2020 ****************************

use "$in_files/NDNS_Y1Y9_Gracner\NDNS_Y1Y9_DOBflags_Gracner_DayNutrientLevel_DELIVERED.dta", clear
	duplicates tag ISerialB SurveyYear DayofWeek, gen(tag)

	format SurveyYear %12.0g
	format ISerialB %12.0g
	drop if tag == 1
	destring Sex, replace 
	encode Country, gen(country)
	drop Country
	rename country Country
	rename Age age
	rename Sex sex
	
	
	save "$out_files/NDNS_Y1Y9_DOBflags_Gracner_DayNutrientLevel_EDITED.dta", replace
	
**************************** Individual data -  22 Oct 2020 ****************************

use "$in_files/NDNS_Y1Y9_Gracner/NDNS_Y1Y9_DOBflags_Gracner_Individual_DELIVERED.dta", clear
	
	duplicates tag ISerialB age Sex, gen(tag)
	drop if tag == 1
	rename surveyyr SurveyYear
	rename Sex sex
	
	save "$out_files/NDNS_Y1Y9_DOBflags_Gracner_Individual_EDITED.dta", replace

**************************** Day level food -  22 Oct 2020 ****************************
use "$in_files/NDNS_Y1Y9_Gracner/NDNS_Y1Y9_DOBflags_Gracner_DayFoodLevel_DELIVERED.dta", clear
	
// 	destring SurveyYear, replace
	
	format SurveyYear %12.0g
	format ISerialB %12.0g
	encode Country, gen(country)
	drop Country
	rename country Country
	duplicates tag ISerialB DayofWeek SurveyYear, gen(tag)
	drop if tag == 1
	
	save "$out_files/NDNS_Y1Y9_DOBflags_Gracner_DayFoodLevel_EDITED.dta", replace

/* =========================================================================== */
/* 					MERGING DAY FOOD, INVID & NUTRIENT DATASETS				   */
/* =========================================================================== */

use "$out_files/NDNS_Y1Y9_DOBflags_Gracner_DayFoodLevel_EDITED.dta"
		
merge m:1 ISerialB SurveyYear DayofWeek using "$out_files/NDNS_Y1Y9_DOBflags_Gracner_DayNutrientLevel_EDITED.dta" 
drop _merge
	
merge m:1 ISerialB using "$out_files/NDNS_Y1Y9_DOBflags_Gracner_Individual_EDITED.dta"
drop _merge

/* =========================================================================== */
/*  						CREATING NEW FLAGS 			 			       	   */
/* =========================================================================== */

****** Creating new flags********

* Flag for people born 9 months after Sep 1953
gen Sep_cutoff=0
replace Sep_cutoff = 1 if BirthYear==1954 & BirthQuarter>2
replace Sep_cutoff=1 if BirthYear>1954 

* Flag for people born between 1950-1960 = 1, 0 otherwise
gen bw195060=0
replace bw195060=1 if (BirthYear>=1950 & BirthYear<=1960)
label var bw195060 "Birth date between 1950 & 1960"

* Flag for people in each quarter of years 1953 and 1954
gen exclude1953q2 =1 if BirthYear==1953 & BirthQuarter==2
gen exclude1953q3 =1 if BirthYear==1953 & BirthQuarter==3
gen exclude1953q4 =1 if BirthYear==1953 & BirthQuarter==4
gen exclude1954q1 =1 if BirthYear==1954 & BirthQuarter==1
gen exclude1954q2 =1 if BirthYear==1954 & BirthQuarter==2
gen exclude1954q3 =1 if BirthYear==1954 & BirthQuarter==3
gen exclude1954q4 =1 if BirthYear==1954 & BirthQuarter==4

/* =========================================================================== */
/*  						CREATING/CLEANING VARIABLES 			 		   */
/* =========================================================================== */

************************ New individual level variables *************************

gen DV = 0
bysort ISerialB: replace DV = 1 if _n == 1

gen dev = (BirthYear - 1954)
label var dev "(Byear - 1954)"

replace sex = 0 if sex == 2

encode DayofWeek, gen(dow)
drop DayofWeek
rename dow DayofWeek

gen eth = (ethgr5 == 1) // ethnicity (white vs other) 

gen year = 2008 if SurveyYear == 1
replace year = 2009 if SurveyYear == 2
replace year = 2010 if SurveyYear == 3
replace year = 2011 if SurveyYear == 4
replace year = 2012 if SurveyYear == 5
replace year = 2013 if SurveyYear == 6
replace year = 2014 if SurveyYear == 7
replace year = 2015 if SurveyYear == 8
replace year = 2016 if SurveyYear == 9

replace dnoft=. if dnoft==-1

************************ New health outcome variables  *************************

* Height and Weight
replace htval =0 if htval==-1
replace wtval =0 if wtval==-1

* BMI
gen bmi_valid = bmival
replace bmi_valid = . if bmival<16
gen lbmi_valid = ln(bmi_valid)
gen oweight_valid = (bmi_valid>=25) if !missing(bmi_valid)
gen obese_valid = (bmi_valid>=30) if !missing(bmi_valid)
gen sobese_valid = (bmi_valid>=35) if !missing(bmi_valid)

* Cigarette smoking
replace cigsta3 =4 if cigsta3==-1
replace cigsta3 =5 if cigsta3==-8
replace cigsta3 =6 if cigsta3==-9


* Waist measurements
replace wstval = . if wstval<=0
gen wstval_m = wstval if sex==1
gen wstval_f = wstval if sex==0
gen lwaist = ln(wstval)
label var lwaist "Log(Waist Circumference(cm))"

gen obese_waist_1 = (wstval>=102) if !missing(wstval) & sex==1
replace obese_waist_1 = (wstval>=88) if !missing(wstval) & sex==0

gen obese_waist_2 = (wstval>=90) if !missing(wstval) & sex==1
replace obese_waist_2 = (wstval>=80) if !missing(wstval) & sex==0

gen obese_waist_3 = (wstval>=94) if !missing(wstval) & sex==1
replace obese_waist_3 = (wstval>=80) if !missing(wstval) & sex==0

* Waist-Hip Ratio

replace whval = . if whval<=0
gen whval_m = whval if sex==1
gen whval_f = whval if sex==0
gen lwaisthip = ln(whval)
label var lwaisthip "Log(Waist-Hip ratio)"

gen obese_whr_1 = (whval>=0.95) if !missing(whval) & sex==1
replace obese_whr_1 = (whval>=0.85) if !missing(whval) & sex==0

gen obese_whr_2 = (whval>=0.90) if !missing(whval) & sex==1
replace obese_whr_2 = (whval>=0.85) if !missing(whval) & sex==0

* Obese - 3 Criteria
gen obese_any=(obese_valid==1 | obese_waist_3==1 | obese_whr_2 ==1)

* Glucose
gen lglucose = ln(Glucoseg)
label var lglucose "Log(Glucose (mmol/L)" 

* Pre-diabetes
gen pre_diabetes = (Glucoseg>=7.8) if !missing(Glucoseg)
label var pre_diabetes "Pre-diabetes and diabetes"
replace pre_diabetes = 1 if AntidiabM2 == 1	

* Diabetes
gen diabetes = (Glucoseg>=11) if !missing(Glucoseg)
label var diabetes "Diabetes"
				
* Cholestrol
gen cholesterol = Chol if CholRes == 1
gen high_chol = (Atccholratio>=5) if Atccholratio>0
replace high_chol = 1 if lipid2 == 1 | lipid == 1

* Hypertension
gen hypertensive = (highbp1_2 == 1) if !missing(highbp1_2)
replace hypertensive = . if highbp1_2 == .  | highbp1_2<0
replace hypertensive = 1 if highbp1 == 1 & hypertensive == .

* Regular Drinking 
gen reg_drink=0 
replace reg_drink = 1 if (dnoft==1 | dnoft==2 | dnoft==3 | dnoft==4)

* Smoking
gen cig = 0
replace cig =1 if cigsta3==1 |cigsta3==2



************************ New nutrition level variables *************************

gen sweetspres = SUGARSPRESERVESANDSWEETSPREADS
gen sweetsconf = SUGARCONFECTIONERY
gen chokoconf = CHOCOLATECONFECTIONERY
egen sweetsall = rowtotal(sweetspres sweetsconf chokoconf), missing

egen milk = rowtotal(WHOLEMILK SKIMMEDMILK SEMISKIMMEDMILK OTHERMILKANDCREAM ONEPERCENTMILK), missing
gen yoghurt = YOGURTFROMAGEFRAISANDDAIRYDESSER
egen dairy = rowtotal(milk yoghurt), missing
gen ldairy = ln(dairy+1)
label var ldairy "Log(Dairy)"

gen tot_sugar_cat =1
replace tot_sugar_cat=2 if (Totalsugarsg >=25 & Totalsugarsg <50)
replace tot_sugar_cat =3 if (Totalsugarsg >=50 & Totalsugarsg<100)
replace tot_sugar_cat= 4 if Totalsugarsg >=100

gen sugar_cal = FreeSugarsg*4
gen sugar_share = sugar_cal/Energykcal

gen intr_cal = Intrinsicandmilksugarsg*4
gen extr_cal = Nonmilkextrinsicsugarsg*4

gen intr_share = intr_cal/Energykcal
gen extr_share = extr_cal/Energykcal

gen sugar_share2 = FreeSugarsg/Totalsugarsg
gen intri_share2 = Intrinsicandmilksugarsg/Totalsugarsg
gen extr_share2 = Nonmilkextrinsicsugarsg/Totalsugarsg


gen recommended5 = sugar_share>0.05
gen recommended10 = sugar_share>0.1

egen age_cat2 = cut(age), at(40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 72)

* Flag for people in the top in the top 1% of sugar consumption
su Totalsugarsg, d
gen flag_sug = 1 if Totalsugarsg<r(p99) 

egen veggies = rowtotal(VEGETABLESNOTRAW SALADANDOTHERRAWVEGETABLES), missing
gen any_fruit = (FRUIT>0) if !missing(FRUIT)
gen any_veggies = (veggies>0) if !missing(veggies)
gen any_sweets = (sweetsall>0)  if !missing(sweetsall)
egen meats = rowtotal(ProcessedRedMeatg Poultryg), missing
gen any_meat = (meats>0) if !missing(meats)
 
egen sweets_2 = rowtotal(sweetsconf chokoconf), missing
gen any_sweets_2 = (sweets_2>0) if !missing(sweets_2)

gen intrin_calc = Totalsugarsg - Nonmilkextrinsicsugarsg
gen intrin_lactose_excl_calc = Totalsugarsg - Nonmilkextrinsicsugarsg - Lactoseg
egen total_sug_excl_lact = rowtotal(intrin_lactose_excl_calc Nonmilkextrinsicsugarsg), missing
egen sweetsall_plusbuns = rowtotal(sweetsall BUNSCAKESPASTRIESFRUITPIES), missing
egen all_fruits = rowtotal(SmoothieFruitg DriedFruitg),missing 
egen fruits_veg = rowtotal(all_fruits SALADANDOTHERRAWVEGETABLES YellowRedGreeng VEGETABLESNOTRAW OtherVegg),missing 

gen total_usual_food = FoodQuantity if SurveyYear<7
replace total_usual_food = UsualFoodQuantity if SurveyYear>6

* Generate Logarithmic form of variables 
foreach x in  sweetspres sweetsconf chokoconf sweetsall{
			 
			gen l`x' = ln(`x'+1)
			label var l`x' "Ln(`x')"
}

foreach x in  Energykcal Fatg Proteing Carbohydrateg Totalsugarsg Englystfibreg FreeSugarsg Nonmilkextrinsicsugarsg ///
 Intrinsicandmilksugarsg Fruitg ProcessedRedMeatg Poultryg Lactoseg Fructoseg Sucroseg Maltoseg ///
 Glucoseg intrin_calc intrin_lactose_excl_calc total_sug_excl_lact sweetsall_plusbuns all_fruits {

	gen l`x' = ln(`x'+1)

}


*** New dev variable 
gen birth_qtr_num = 0
local v =0
forvalues i= 1950(1)1960{
	
	
	forvalues j=1(1)4{
		
		local v = `v'+1
		replace birth_qtr_num = `v' if BirthYear==`i' & BirthQuarter==`j'
	}
}

gen dev_qtr = birth_qtr_num - 18 /* 18 is 1954 quarter 2 */

gen Sep_cutoffXdev = Sep_cutoff*dev

label var age "Age"
label var sex "Sex"
label var htval "Valid height (cm)"
label var wtval "Valid weight (Kg)"
label var Energykcal "Total energy (kcal)"
label var Fatg "Fat (g)" 
label var Proteing "Protein (g)" 
label var Carbohydrateg "Carbohydrate (g)" 
label var FreeSugarsg "Free sugars (g)" 
label var Nonmilkextrinsicsugarsg "Non-milk extrinsic sugars (g)" 
label var Intrinsicandmilksugarsg "Intrinsic milk sugars (g)" 
label var Englystfibreg "Englyst fibre (g)" 
label var sweetsall "Sweets"           
label var Fruitg "Fruits (g)" 
label var YellowRedGreeng "Vegetables (g)" 
label var ProcessedRedMeatg "Processed red meat (g)"
label var Poultryg "Poultry (g)" 
label var dairy "Dairy"
label var sugar_share "Calorie share of free sugars"

  

*CONDITION USUAL - 9 months following cutoff excluded
gen condition_usual_2 = 1 if Country !=2 & Country!=3  & exclude1953q4!=1 & exclude1954q1!=1 & exclude1954q2!=1 & (NatIDUK!=6 | NatIDUK!=.) & total_usual_food=="Usual Amount" 


*CONDITION USUAL HEALTH - 9 months following cutoff excluded
gen condition_usual_health = 1 if Country !=2  & Country!=3 & exclude1953q4!=1 & exclude1954q1!=1 & exclude1954q2!=1 & (NatIDUK!=6 | NatIDUK!=.) & htval>0 & wtval>0


* Birth Quarter variable
local k=0
gen birthqtr_rdd=.
forvalues i=1920(1)2015{
	forvalues j =1(1)4{
		
		local k=`k'+1
		replace birthqtr_rdd = `k' if BirthYear==`i' & BirthQuarter==`j'	
		
	}
}

gen diary_qtr = .
replace diary_qtr=1 if diarymth<4
replace diary_qtr=2 if diarymth>3 & diarymth<7
replace diary_qtr=3 if diarymth>6 & diarymth<10
replace diary_qtr=4 if diarymth>9
 //
drop if bw195060==0
save "$out_files/Final_dataset.dta", replace

//  save "$out_files/Final_dataset_rdd.dta", replace
