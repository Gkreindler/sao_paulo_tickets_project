/*

The goal of this do file is to convert date format and merge with marginais

*/

// clear STATA
clear

// file path
global s "/Users/san/Dropbox/sao_paulo_tickets_project/data/tickets_v2/"
global t "/Users/san/Dropbox/sao_paulo_tickets_project/gis/"
global u "/Users/san/Dropbox/sao_paulo_tickets_project/data/cameras/"

// change working directory
cd "$s"

// open camera location nearest neighbor dataset
use "camera_location_nn.dta"

// create correctly formatted start date
generate start_date = mdy(start_month, start_day, start_year)
format %td start_date

// create correctly formatted end date
generate end_date = mdy(end_month, end_day, end_year)
format %td end_date

// save temp file
save "camera_location_nn_temp.dta", replace

// clear STATA
clear

// change working directory
cd "$u"

// import manual cameras along marginais
import delimited "cameras_map_matched_manual.csv"

// observation is location
gsort id direction location
bysort id: keep if _n == 1

// STATA doesn't like long as a variable name
rename v6 lon

// change working directory
cd "$s"

// save csv as dta
save "cameras_map_matched_manual.dta", replace

// convert dates to STATA mdy format
split start, p("/")
destring start1 start2 start3, replace
generate start_date = mdy(start1, start2, start3)
format %td start_date

split end, p("/")
destring end1 end2 end3, replace
generate end_date = mdy(end1, end2, end3)
format %td end_date

// prune unneeded variables
keep lat lon location start_date end_date

// reorder variables
order location lat lon start_date end_date

// format lat lon
format lat %11.0g
format lon %11.0g

// for comparing lat lon before and after merge
rename lat lat_merge
rename lon lon_merge

// create parsed location variable for merging, without vowels due to special characters
egen location_parsed = sieve(location), char(0123456789bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ)

bysort location_parsed: keep if _n == _N

// save csv as dta
save "cameras_map_matched_manual_processed.dta", replace

// open full camera location dataset
use "camera_location_nn_temp.dta"

// create location variable in string format for merging
decode location, generate(location0)
rename location location_coded
rename location0 location

// create parsed location variable for merging, without vowels due to special characters
egen location_parsed = sieve(location), char(0123456789bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ)

// merge complete camera dataset with manually processed camera dataset
merge m:1 location_parsed using "cameras_map_matched_manual_processed.dta"

save "cameras_merged_temp.dta", replace

// keep matched entries
keep if _merge == 3

// drop location
drop location
rename location_coded location

/*

// keep just necessities
keep location _merge

// avoid naming conflict with future merge
rename _merge match

// drop any duplicates
duplicates drop

// save matches file
save "location_matched_key.dta", replace

// clear STATA
clear

// open full camera location dataset
use "camera_location_nn_temp.dta"

// merge main dataset with created key
merge m:1 location using "location_matched_key.dta"

// keep successful matches
keep if match == 3 & _merge == 3

// necessary to do this merge once again to avoid losing duplicate lat_lon
keep lat_lon

// save key
save "lat_lon_key.dta", replace

// clear STATA
clear

// open full camera location dataset
use "camera_location_nn_temp.dta"

// merge main dataset with created key
merge m:1 lat_lon using "lat_lon_key.dta"

// keep successful matches
keep if _merge == 3

*/

// need to recalculate nearest neighbors with this modified set
keep location lat lon lat_lon nvals start_date end_date

// save
save "tickets_nearest_neighbors_loop.dta", replace

local neighborhoods 0.001 0.005 0.01 0.015 0.02 0.025 0.03 0.035 0.04 0.045 0.05 0.055 0.06 0.065 0.07 0.075 0.08 0.085 0.09 0.095 0.1

foreach neighborhood in `neighborhoods' {

	// clear STATA
	clear

	// open tickets file
	use "tickets_nearest_neighbors_loop.dta"

	// rename location to location0 because geonear requires that identifiers be different
	rename location location0

	// calculate neighbors 
	geonear location0 lat lon using "tickets_nearest_neighbors_loop.dta", n(location lat lon) ignoreself within(`neighborhood') long ellipsoid near(0)

	// create nearest neighbor distance and convert to meters
	rename km_to_location nn_distance
	replace nn_distance = nn_distance * 1000

	// for collapse
	generate count = 1
	
	// collapse by location0, calculate number of nearest neighbors
	collapse (sum) count, by(location0)
	
	// rename variables
	rename location0 location
	
	// create local name to convert from ie 0.01 to 10, etc
	local name = `neighborhood' * 1000
	rename count nn_`name'
	
	// save file
	save "nearest_neighbors_within_x_meters.dta", replace

	// clear STATA
	clear

	// open 
	use "tickets_nearest_neighbors_loop.dta"

	// merge with nearest neighbors dataset
	merge 1:1 location using "nearest_neighbors_within_x_meters.dta"

	// replace missing values with 0 to indicate no nearest neighbors within X meters
	replace nn_`name' = 0 if nn_`name' == .

	// drop merge variable
	drop _merge
	
	// save
	save "tickets_nearest_neighbors_loop.dta", replace
	
}

// rename nvals to be more easily understood
rename nvals multiple_locations

// save completed file
save "camera_location_nn_marginais.dta", replace

*/

