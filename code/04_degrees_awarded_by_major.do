local PROJ "/Users/sampassey/Library/CloudStorage/Box-Box/Sam Passey/major_choice/major_choice_project/code"
use "`PROJ'/data/cip1990sp_panel.dta",clear
keep degree_name start_year sex degree_type degree_count
preserve
tempfile totals
keep if degree_name == "total"
drop degree_name
rename degree_count total_degree_count
keep start_year degree_type sex total_degree_count
save `totals' 
restore
merge m:1 degree_name using "`PROJ'/data/cip1990sp_to_major.dta"
keep if _merge == 3
drop _merge

collapse (sum) degree_count, by(major start_year degree_type sex)
merge m:1 start_year degree_type sex using `totals'
drop _merge
gen degree_share = degree_count/total_degree_count
rename start_year year
order major year degree_type sex degree_count total_degree_count degree_share
// you will notice that these totals do not always exactly add up to equal the totals from cip1990sp. This is because cip1990sp includes the major "not classified by field of study" and these do not. After removing this major, the totals are exactly the same.
save "`PROJ'/data/degree_shares_by_major.dta",replace
