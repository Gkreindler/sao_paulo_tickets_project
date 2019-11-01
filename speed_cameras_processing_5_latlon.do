/*

The goal of this do file is to take the complete n = 44mm dataset of tickets, 
record number of tickets per camera, record first and last ticket, then collapse
into observations for each camera

This file clusters by lat_lon

*/

// clear STATA
clear

// file path
global s "/Users/san/Dropbox/sao_paulo_tickets_project/data/tickets_v2/"
global t "/Users/san/Dropbox/sao_paulo_tickets_project/gis/"

// change working directory
cd "$s"

// open file of cases where lat_long pairs identify multiple locations
use "tickets_sample_temp.dta"

// drop observations with missing location information
drop if lat_lon == ""

// filter out unnecessary columns
keep location year month day hour lat lon lat_lon nvals

// sort by lat_lon and date
gsort lat_lon year month day hour

// collapse by lat_lon, keep first and last observation
bysort lat_lon : keep if _n == 1 | _n == _N

// save temp file to save on processing time
save "collapsed_tickets.dta", replace

// clear STATA
clear

// use temp file
use "collapsed_tickets.dta"

// label start and end dates for each observation
by lat_lon: generate start_year = year[1]
by lat_lon: generate start_month = month[1]
by lat_lon: generate start_day = day[1]
by lat_lon: generate start_hour = hour[1]

by lat_lon: generate end_year = year[2]
by lat_lon: generate end_month = month[2]
by lat_lon: generate end_day = day[2]
by lat_lon: generate end_hour = hour[2]

// drop date
drop year month day hour

// collapse to lat_lon unit of observation
bysort lat_lon: keep if _n == 1

// save this new nearest neighbors dataset for use with geonear
save "tickets_nearest_neighbors.dta", replace

// rename lat_lon to lat_lon0 because geonear requires that identifiers be different
rename lat_lon lat_lon0

// calculate neighbors 
geonear lat_lon0 lat lon using "tickets_nearest_neighbors.dta", n(lat_lon lat lon) ignoreself within(0.01) long ellipsoid near(0)

// create nearest neighbor distance and convert to meters
rename km_to_lat_lon nn_distance
replace nn_distance = nn_distance * 1000

// for collapse
generate count = 1

// collapse by lat_lon0, calculate smallest nearest neighbor distance and number of nearest neighbors
collapse (min) nn_distance (sum) count, by(lat_lon0)

// rename variables
rename lat_lon0 lat_lon
rename count nn_10

// save file
save "nearest_neighbors_within_x_meters.dta", replace

// clear STATA
clear

// open 
use "tickets_nearest_neighbors.dta"

// merge with nearest neighbors dataset
merge 1:1 lat_lon using "nearest_neighbors_within_x_meters.dta"

// replace missing values with 0 to indicate no nearest neighbors within 10 meters
replace nn_10 = 0 if nn_10 == .

// drop merge variable
drop _merge

// save file
save "camera_nn10_full.dta", replace

// prepare QGIS csv file
keep location lat_lon lat lon nn_10 start_* end_*

// change working directory
cd "$t"

// save as CSV
export delimited "camera_locations2/camera_nn10.csv", replace
