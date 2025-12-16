clear
local PROJ "/Users/sampassey/Library/CloudStorage/Box-Box/Sam Passey/major_choice/major_choice_project/code"
use "`PROJ'/data/acs_raw.dta"
drop if year >2017

/*
First, we map all ACS occ codes back to their 2005 vintage using Pascual Restrepo's scheme.
This code is copied straight from their do file:
*/
do "`PROJ'/data/recode_acs.do"

*Then we map the remapped 2005 vintage ACS codes to OCC1990dd using David Dorn's crosswalk.
replace occ = occ/10
																																								
merge m:1 occ using "`PROJ'/data/occ2005_occ1990dd/occ2005_occ1990dd.dta"
drop if _m !=3
drop _m


*Then we need to revise the OCC1990dd scheme to account for some of the updates:
do "`PROJ'/data/create_occ1990dd_acs.do"


*Some additional filtering

keep if year < 2018
keep if educd >= 101 & educd < 999
keep if inlist(classwkrd, 20, 21, 22, 23, 24, 25, 27, 28)
keep if wkswork2 > 3 // 3 = 27-39 weeks
keep if uhrswork >= 35
replace occ1990dd_acs = 159 if inlist(occ1990dd_acs, 155, 156,157,158)
replace occ1990dd_acs = 64 if occ1990dd_acs == 229
drop occ1990dd
rename occ1990dd_acs occ1990dd
save "`PROJ'/data/acs_1990_recoded_dd.dta", replace

															


