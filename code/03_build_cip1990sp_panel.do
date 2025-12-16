local PROJ "/Users/sampassey/Library/CloudStorage/Box-Box/Sam Passey/major_choice/major_choice_project/code"
* read in processed data from nces
use "`PROJ'/data/nces_data_conistent.dta",clear
* concatenate on the stuff from the pdf
append using "`PROJ'/data/pdf_data_consistent.dta"
* one more join with cip1990sp framework. 
* some detail is lost, but these categories are much better bc there is less noise with categorical reclassification
joinby degree_name_sp using "`PROJ'/data/cip1990sp_v1_to_cip1990sp_v2.dta"
collapse (sum) degree_count, by(degree_name_sp_revised start_year sex degree_type)
rename degree_name_sp_revised degree_name
merge m:1 degree_name using "`PROJ'/data/cip1990sp_v2_taxonomy.dta"
keep if _merge == 3 // we have exceptions because I ended up tossing out the detailed agriculture degrees.  Maybe redo crosswalk?
* (This is Sam from 12/4/2025 - This is not something to worry about, I don't think. It doesn't cause any double counting. The only reason to redo the crosswalk would be to make it more professional.)
drop _merge
order degree_name start_year degree_type sex degree_count parent taxonomical_depth other small_two_digit
save "`PROJ'/data/cip1990sp_panel.dta",replace
