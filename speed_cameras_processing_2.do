// this do file takes observations in which lat_long pair identify
// multiple locations and checks if missing lat_lon data can be filled in - no

// clear STATA
clear

// open file of cases where lat_long pairs identify multiple locations
use "tickets_sample_temp.dta"

// reduce sample to lat_long pairs identify multiple locations
keep if nvals > 1

// we have locations with missing locations, check to see if the locations can
// be identified, otherwise delete
gsort lat_lon

// check if the locations with missing lat_lon have any non missing lat_lon 
levelsof location if nvals == 59, local(missing_lat_lon)

clear
use "tickets_sample_temp.dta"

foreach location of local missing_lat_lon {
	clear
	use "tickets_sample_temp.dta"
	keep if location == `location'
	keep if lat_lon != ""
	save "tickets_sample_temp_`location'.dta", replace
}

clear
foreach location of local missing_lat_lon {
	append using "tickets_sample_temp_`location'.dta"
}

// result is no locations with missing lat_lon can be matched to a lat_long, so delete




