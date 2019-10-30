// the goal of this do file is to identify the nearest neighbor lat_lon and distance
// for each lat_lon

// clear STATA
clear

// file path
global s "/Users/san/Dropbox/sao_paulo_tickets_project/data/tickets_v2/"

// change working directory
cd "$s"

// open file of cases where lat_long pairs identify multiple locations
use "tickets_sample_temp.dta"

// drop observations with missing location information
drop if lat_lon == ""

// clear dataset of clutter
drop vehicle type issuer vehicle_type lat_sd lon_sd lat_lon_var

// collapse by lat_lon
bysort lat_lon: keep if _n == 1

// reformat ticket id for better readability
format ticket_id %12.0g

// save this new nearest neighbors dataset for use with geonear
save "tickets_nearest_neighbors.dta", replace

// keep this varlist, since geonear adds variables this lets you rerun script
keep location year month day hour lat lon lat_lon ticket_id nvals

// calculates nearest neighbor not including self
// geonear location lat lon using "tickets_nearest_neighbors.dta", n(location lat lon) ignoreself

// rename location to location0 because geonear requires that identifiers be different
rename location location0

// calculates number of neighbors within X meters
geonear location0 lat lon using "tickets_nearest_neighbors.dta", n(location lat lon) ignoreself within(0.2) long ellipsoid near(0)

// using ellipsoid option might take slightly longer and produces almost identical results,
// leaving it in for now but take out if operations are too slow

// create nearest neighbor distance and convert to meters
rename km_to_location nn_distance
replace nn_distance = nn_distance * 1000

// sort dataset by nearest neighbor distance and location
sort nn_distance location0

// keep even observations
keep if mod(_n, 2) == 0





