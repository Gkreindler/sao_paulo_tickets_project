// this do file takes observations in which lat_long pair identify
// multiple locations and confirms that all repeat lat_lon pairs represent 
// camera pairs in opposite directions

// clear STATA
clear

// open file of cases where lat_long pairs identify multiple locations
use "tickets_sample_temp.dta"

// reduce sample to lat_long pairs that identify multiple locations
keep if nvals > 1

// drop observations with missing data
drop if lat_lon == ""

// sort by location, then date
gsort location year month day hour

// keep first and last observation of each location
by location: keep if _n==1 | _n==_N

// sort again
gsort lat_lon location year month day hour

// keep one observation per location
bysort location: keep if _n == 1

// sort again
gsort lat_lon location year month day hour

// all nvals == 2 are pairs with different directions, now examine greater
keep if nvals > 2

// nvals == 4 are all paired as well
