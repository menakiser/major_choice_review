local PROJ "/Users/sampassey/Library/CloudStorage/Box-Box/Sam Passey/major_choice/major_choice_project/code"
local NCES_FILES   "`PROJ'/data/nces_files"

cd "`NCES_FILES'"

tempfile master
local built = 0


forvalues year = 1985/2022 {
	tempfile nces_`year'
    di as txt "Processing `year'"

    * We have different file naming schemes for each year
    local fname
    if inrange(`year',1985,1989) {
        local fname `"`PROJ'/data/nces_files/1985-1989/Data/c`year'_cip.csv"'
    }
    else if `year'==1990 {
        local fname `"`PROJ'/data/nces_files/1990-1999/Data/c8990cip.csv"'
    }
    else if inrange(`year',1991,1994) {
        local fname `"`PROJ'/data/nces_files/1990-1999/Data/c`year'_cip.csv"'
    }
    else if inrange(`year',1995,1999) {
        local last  = mod(`year',100)
        local prev  = `last' - 1
        local last2 : display %02.0f `last'
        local prev2 : display %02.0f `prev'
        local fname `"`PROJ'/data/nces_files/1990-1999/Data/c`prev2'`last2'_a.csv"'
    }
    else if inrange(`year',2000,2009) {
        local fname `"`PROJ'/data/nces_files/2000-2009/Data/c`year'_a.csv"'
    }
    else if inrange(`year',2010,2019) {
        local fname `"`PROJ'/data/nces_files/2010-2019/Data/c`year'_a.csv"'
    }
    else if inrange(`year',2020,2022) {
        local fname `"`PROJ'/data/nces_files/2020-Present/Data/c`year'_a.csv"'
    }
	* It is crucial that cipcode gets read as a string. Sometimes it shows up in the third column instead of the 2nd.
	if inlist(`year', 1995, 1996, 1997, 2001) {
    import delimited using "`fname'", varnames(1) stringcols(3) case(lower) clear
	}
	else {
		import delimited using "`fname'", varnames(1) stringcols(2) case(lower) clear
	}
	
	* Variable names change slightly across the dataset. We have to standardize them
	capture confirm variable crace16
	if !_rc {
		rename crace16 degree_countwomen
	}

	capture confirm variable ctotalw
	if !_rc {
		rename ctotalw degree_countwomen
	}

	capture confirm variable crace15
	if !_rc {
		rename crace15 degree_countmen
	}

	capture confirm variable ctotalm
	if !_rc {
		rename ctotalm degree_countmen
	}
	gen degree_counttotal = degree_countwomen+degree_countmen
	
	

	* If we have info on if it is a first or second major, drop second majors, then drop the majornum column.
	capture confirm variable majornum
	if !_rc {
		drop if majornum != 1
		drop majornum
	}
	* Keep only the columns we care about
	keep cipcode awlevel degree_countmen degree_countwomen degree_counttotal
	gen start_year = `year' - 1
	* 1985 and 1986 have weird cipcode formatting
	if inrange(`year',1985,1986) {
        replace cipcode = ///
            cond(strlen(cipcode)==5, "0"+substr(cipcode,1,1)+"."+substr(cipcode,2,.), ///
            cond(strlen(cipcode)==6, substr(cipcode,1,2)+"."+substr(cipcode,3,.), "error"))
    }
	
	
	
	* Append into master
    if !`built' {
        save `master', replace
        local built = 1
    }
    else {
        append using `master'
        save `master', replace
    }
	
    }
* Collapse by cipcode, year, and degree type
collapse (sum) degree_countmen degree_countwomen degree_counttotal, by(cipcode start_year awlevel)

* Code in cip scheme for later crosswalking
gen cip_scheme = ""
replace cip_scheme = "cip_1980" if (start_year>= 1980) & (start_year <= 1985)
replace cip_scheme = "cip_1985" if (start_year>= 1986) & (start_year <= 1990 )
replace cip_scheme = "cip_1990" if (start_year>=1991) & (start_year <= 2001)
replace cip_scheme = "cip_2000" if (start_year>= 2002) & (start_year <= 2008)
replace cip_scheme = "cip_2010" if (start_year>= 2009) & (start_year <= 2018)
replace cip_scheme = "cip_2020" if (start_year>= 2019) & (start_year <= 2021)
drop if strpos(cipcode, "99") == 1
reshape long degree_count, i(cipcode start_year awlevel) j(sex) string

* Crosswalk awlevel codes to readable ones
preserve
clear all
tempfile awlevel_mapping
input awlevel str12 degree_type
5 bachelors
7 masters
9 doctorate
17 doctorate
end
save `awlevel_mapping'
restore
merge m:1 awlevel using `awlevel_mapping'
drop if _merge != 3 // tossing out all degree types that aren't bachelors, masters, or doctorates
drop _merge awlevel

* Final polishing steps
order cipcode start_year cip_scheme degree_type sex degree_count
sort cipcode start_year degree_type sex
save `master',replace

use `master', clear
joinby cipcode cip_scheme using "`PROJ'/data/cipcode_to_cip_1990sp_with_other.dta"
collapse (sum) degree_count, by(degree_name_sp start_year sex degree_type)
keep if start_year>=1995 // chop off everything pre-1995
save "`PROJ'/data/nces_data_conistent.dta",replace



