clear
local PROJ "/Users/sampassey/Library/CloudStorage/Box-Box/Sam Passey/major_choice/major_choice_project/code"
use "`PROJ'/data/cond_probabilities_all.dta",clear
merge m:1 occ1990dd year using "`PROJ'/data/smoothed_wage_series.dta"
gen exp_wg_sm_v1 = sm_l_rel_wg*pr_occ_given_major
gen exp_wg_sm_v2 = sm_l_rel_wg*pr_occ_given_major_dynamic
gen exp_wg_raw_v1 = l_rel_wg*pr_occ_given_major
gen exp_wg_raw_v2 = l_rel_wg*pr_occ_given_major_dynamic
collapse (sum) exp_wg_sm_v1 exp_wg_sm_v2 exp_wg_raw_v1 exp_wg_raw_v2, by(year major)
save "`PROJ'/data/wages_by_major_v4.dta",replace







 

