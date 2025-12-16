clear
local PROJ "/Users/sampassey/Library/CloudStorage/Box-Box/Sam Passey/major_choice/major_choice_project/code"

/// Census 1970: 1971-1982
/// Census 1980: 1983-1991
/// Census 1990: 1992-2002 
/// Census 2000: 2003-2010 CPS 4 digit OCC1990dd 3 digit
/// Census 2010: 2011-2019 CPS 4 digit OCC1990dd 4 digit
/// Census 2020: 2020-Present

tempfile missing_codes_2010
input occ occ1990dd
1510 59
9330 829
6750 599
325 19
1815 166
3257 95
1660 83
3235 105
8960 779
8160 653
end
save `missing_codes_2010'

clear
tempfile missing_codes_2000
input occ occ1990dd
1965 235
end
save `missing_codes_2000'

tempfile occ1990dd_crosswalk
use "occ1970_occ1990dd/occ1970_occ1990dd.dta", clear
gen scheme = 1970

append using "occ1980_occ1990dd/occ1980_occ1990dd.dta"
replace scheme = 1980 if missing(scheme)

append using "occ1990_occ1990dd/occ1990_occ1990dd.dta"
replace scheme = 1990 if missing(scheme)

append using "occ2000_occ1990dd/occ2000_occ1990dd.dta"
replace scheme = 2000 if missing(scheme)
replace occ = occ*10 if scheme ==2000
append using `missing_codes_2000'
replace scheme = 2000 if missing(scheme)

append using "occ2010_occ1990dd/occ2010_occ1990dd.dta"
replace scheme = 2010 if missing(scheme)

append using `missing_codes_2010'
replace scheme = 2010 if missing(scheme)
save `occ1990dd_crosswalk'


use "cps_00024.dta",clear
rename occly occ
keep if year<=2018


replace occ=1240 if year>2002 & (occ==1230 | occ==1210)
replace occ=1520 if year>2002 & occ==1500
replace occ=1530 if year>2002 & (occ==1330 | occ==1340)
replace occ=1860 if year>2002 & occ==1830
replace occ=1965 if year>2002 & occ==1940
replace occ=2900 if year>2002 & occ==2960
replace occ=3840 if year>2002 & occ==3830
replace occ=3850 if year>2002 & occ==3860
replace occ=4130 if year>2002 & occ==4160
replace occ=5350 if year>2002 & occ==5210
replace occ=6050 if year>2002 & occ==6020
replace occ=6100 if year>2002 & occ==6110
replace occ=6320 if year>2002 & occ==6310
replace occ=6530 if year>2002 & occ==6500
replace occ=6940 if year>2002 & (occ==6910 | occ ==6930)
replace occ=6800 if year>2002 & occ==6920
replace occ=7100 if year>2002 & occ==7050
replace occ=7620 if year>2002 & (occ==7520 | occ==7600)
replace occ=8220 if year>2002 & (occ==8020 | occ==8120)
replace occ=8460 if year>2002 & (occ==8430 | occ==8440)
replace occ=8550 if year>2002 & (occ==8520)
replace occ=8960 if year>2002 & (occ==8840 | occ==8900)
replace occ=9150 if year>2002 & occ==9110
replace occ=9420 if year>2002 & occ==9340
replace occ=9750 if year>2002 & (occ==9500 | occ==9740 | occ==9730)


gen scheme = .
replace scheme = 1970 if year>=1971 & year<= 1982
replace scheme = 1980 if year>=1983 & year<= 1991
replace scheme = 1990 if year >= 1992 & year<= 2002
replace scheme = 2000 if year >= 2003 & year<= 2010
replace scheme = 2010 if year >= 2011 & year<= 2019

drop if occ == 0
keep if inlist(classwly, 20, 21, 22, 23, 24, 25, 27, 28)
keep if wkswork1 >= 35
keep if uhrsworkly >= 35
keep if educ >= 111
merge m:1 occ scheme using `occ1990dd_crosswalk'
tab occ scheme if _merge == 1
drop if _merge != 3
drop _merge
* treating all teachers as one occupation
replace occ1990dd = 159 if inlist(occ1990dd, 155,156,157,158)
* Lumping the two computer occupations together
replace occ1990dd = 64 if occ1990dd == 229


* Run the Pascual Restrepo adjustments to further harmonize OCC1990dd codes.
do "`PROJ'/data/create_occ1990dd_acs"
drop occ1990dd
rename occ1990dd_acs occ1990dd
drop scheme
* Since everything is on a "last year" basis
replace year = year-1

save "`PROJ'/data/cps_data_revised_occ1990dd.dta",replace


/*
COMPUTES AN ESTIMATE OF THE PROBABILITY OF AN OCCUPATION (reharmonized to OCC1990dd–the restrepo version) IN EACH YEAR
*/

* Dynamically compute each occupation's relative frequency by year and save that as a file too.
use cps_data_revised_occ1990dd,clear
collapse (sum) wt = asecwt, by(year occ1990dd)

preserve
tempfile totals
collapse (sum) total_wt = wt, by(year)
save `totals'
restore
merge m:1 year using `totals'
drop _merge
gen pr_occ = wt/total_wt
keep year occ1990dd pr_occ

tempfile observed_occs
preserve
keep occ1990dd
duplicates drop
save `observed_occs'
restore

tempfile observed_yrs
preserve
keep year
duplicates drop
save `observed_yrs'
restore

tempfile occ_x_yrs
preserve
use `observed_occs',clear
cross using `observed_yrs'
save `occ_x_yrs'
restore


merge 1:1 occ1990dd year using `occ_x_yrs'
drop _merge
sort occ1990dd year

bysort occ1990dd (year): ipolate pr_occ year, gen(pr_occ_ip) // interpolating missing values

* Going to backfill and forward fill for occs that weren't observed
gen pr_occ_ip_copy = pr_occ_ip
bysort occ1990dd (year): replace pr_occ_ip_copy = pr_occ_ip_copy[_n-1] if missing(pr_occ_ip_copy) 
gsort occ1990dd -year
by occ1990dd: replace pr_occ_ip_copy = pr_occ_ip_copy[_n - 1] if missing(pr_occ_ip_copy)
sort occ1990dd year
drop pr_occ pr_occ_ip
bysort year: egen pr_occ_ip_total = total(pr_occ_ip_copy)
gen pr_occ = pr_occ_ip_copy/pr_occ_ip_total
drop pr_occ_ip_copy pr_occ_ip_total
save "`PROJ'/data/pr_occ_by_year.dta",replace


/*
This section is going to create wages by occupation
*/

use "`PROJ'/data/cps_data_revised_occ1990dd.dta"
tempfile grand_mean
preserve
gen inc = asecwt*incwage
gen hours = asecwt*uhrsworkly*wkswork1
collapse (sum) inc hours, by(year)
gen avg_hourly_earnings_all = inc/hours
drop inc hours
save `grand_mean'
restore

gen inc = asecwt*incwage
gen hours = asecwt*uhrsworkly*wkswork1
collapse (sum) inc hours, by(occ1990dd year)
gen avg_hourly_earnings = inc/hours
drop inc hours

merge m:1 year using `grand_mean'
drop _merge

gen l_rel_wg = ln(avg_hourly_earnings/avg_hourly_earnings_all)
drop avg_hourly_earnings avg_hourly_earnings_all
save l_rel_wg_by_year.dta,replace


tempfile observed_occs
preserve
keep occ1990dd
duplicates drop
save `observed_occs'
restore

tempfile observed_yrs
preserve
keep year
duplicates drop
save `observed_yrs'
restore

tempfile occ_x_yrs
preserve
use `observed_occs',clear
cross using `observed_yrs'
save `occ_x_yrs'
restore


merge 1:1 occ1990dd year using `occ_x_yrs'
drop _merge
sort occ1990dd year

bysort occ1990dd (year): ipolate l_rel_wg year, gen(l_rel_wg_ip) // interpolating missing values

* Going to backfill and forward fill for occs that weren't observed
gen l_rel_wg_ip_copy = l_rel_wg_ip
bysort occ1990dd (year): replace l_rel_wg_ip_copy = l_rel_wg_ip_copy[_n-1] if missing(l_rel_wg_ip_copy) 
gsort occ1990dd -year
by occ1990dd: replace l_rel_wg_ip_copy = l_rel_wg_ip_copy[_n - 1] if missing(l_rel_wg_ip_copy)
sort occ1990dd year

drop l_rel_wg l_rel_wg_ip
rename l_rel_wg_ip_copy l_rel_wg

gen sm_l_rel_wg = .
quietly levelsof occ1990dd, local(occs)
foreach o of local occs{
	quietly lowess l_rel_wg year if occ1990dd == `o', bwidth(0.2) nograph gen(s)
	quietly replace sm_l_rel_wg = s if occ1990dd == `o'
	drop s
}
save "`PROJ'/data/smoothed_wage_series",replace






