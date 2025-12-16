clear
local PROJ "/Users/sampassey/Library/CloudStorage/Box-Box/Sam Passey/major_choice/major_choice_project/code"

cd "`PROJ'"
use "`PROJ'/data/pdf_data.dta",clear
joinby degree_name using "`PROJ'/data/degree_name2degree_name_sp.dta"
collapse (sum) degree_count, by(degree_name_sp start_year sex degree_type)
tempfile degree_panel
save `degree_panel'

tempfile degree_panel_with_taxonomy
use `degree_panel',clear
merge m:1 degree_name_sp using "`PROJ'/data/cip1990sp_taxonomy_v1.dta"
drop _merge
save `degree_panel_with_taxonomy'
* get totals for parents and for children

* first, create a file with a list of the parent categories:

tempfile parent_list
use "`PROJ'/data/cip1990sp_taxonomy_v1.dta",clear
keep parent_sp
duplicates drop parent_sp, force
save `parent_list'

* now compute totals for the children of each parent groupings
tempfile child_totals
use `degree_panel_with_taxonomy', clear
collapse (sum) degree_count, by(parent_sp start_year sex degree_type)
rename degree_count degree_count_child
save `child_totals'
* get totals for parents
tempfile parent_totals
use `degree_panel_with_taxonomy',clear
drop parent_sp
rename degree_name_sp parent_sp
merge m:1 parent_sp using `parent_list'
keep if _merge == 3
drop _merge
rename degree_count degree_count_parent
save `parent_totals'
* adding the "other" categories
use `parent_totals',clear
tempfile degree_panel_other cip1990sp_taxonomy_v1_other
merge 1:1 parent_sp start_year sex degree_type using `child_totals'
keep if _merge == 3
gen degree_count = degree_count_parent-degree_count_child
drop _merge degree_count_parent degree_count_child
gen degree_name_sp = parent_sp
replace taxonomical_depth = taxonomical_depth + 1
replace degree_name_sp = degree_name_sp + " other"
drop parent_sp taxonomical_depth
order degree_name_sp start_year sex degree_type
save `degree_panel_other'
tempfile degree_panel_consistent
use `degree_panel',clear
append using `degree_panel_other'
save `degree_panel_consistent'
use `degree_panel_consistent',clear
save "`PROJ'/data/pdf_data_consistent.dta",replace
