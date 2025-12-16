clear
local PROJ "/Users/sampassey/Library/CloudStorage/Box-Box/Sam Passey/major_choice/major_choice_project/code"
use "`PROJ'/data/acs_1990_recoded_dd.dta",clear
merge m:1 degfieldd using "`PROJ'/data/degfieldd2major"
drop _merge
keep major occ1990dd perwt
collapse (sum) perwt, by(occ1990dd major)
tempfile major_occ_totals
save `major_occ_totals'

preserve
tempfile observed_majors
keep major
duplicates drop
save `observed_majors'
restore

preserve 
tempfile observed_occs
keep occ1990dd
duplicates drop
save `observed_occs'
restore

preserve
use `observed_occs',clear
tempfile occs_x_majors
cross using `observed_majors'
save `occs_x_majors'
restore

use `occs_x_majors',clear
merge 1:1 occ1990dd major using `major_occ_totals'
replace perwt = 0 if missing(perwt) 
drop _merge
rename perwt n_occ_major
egen n_major = sum(n_occ_major), by(major)
egen n_occ = sum(n_occ_major), by(occ1990dd)
egen N = sum(n_occ_major)
gen pr_occ_given_major = n_occ_major/n_major
gen pr_occ_given_not_major = (n_occ - n_occ_major)/(N - n_major)
gen stereotype_ratio = pr_occ_given_major/pr_occ_given_not_major
egen stereotype_rank = rank(-stereotype_ratio), by(major) // ranks a major's occs by stereotype. top stereotype occupation = 1st 
save "`PROJ'/data/cond_probabilities.dta",replace

