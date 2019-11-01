/*

The goal of this do file is to calculate multiple number of neighbors within X meters

*/

// clear STATA
clear

// file path
global s "/Users/san/Dropbox/sao_paulo_tickets_project/data/tickets_v2/"
global t "/Users/san/Dropbox/sao_paulo_tickets_project/gis/"

// change working directory
cd "$s"

// open tickets file
use "tickets_nearest_neighbors.dta"

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

// save completed file
save "camera_location_nn.dta", replace
