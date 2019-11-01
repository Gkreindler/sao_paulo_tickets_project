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

local neighborhoods 0.01 0.015 0.02 // 0.025 0.03 0.035 0.04 0.045 0.05

foreach neighborhood in `neighborhoods' {

	// clear STATA
	clear

	// open tickets file
	use "tickets_nearest_neighbors_loop.dta"

	// rename lat_lon to lat_lon0 because geonear requires that identifiers be different
	rename lat_lon lat_lon0

	// calculate neighbors 
	geonear lat_lon0 lat lon using "tickets_nearest_neighbors.dta", n(lat_lon lat lon) ignoreself within(`neighborhood') long ellipsoid near(0)
	
	// for collapse
	generate count = 1
	
	// collapse by lat_lon0, calculate number of nearest neighbors
	collapse (sum) count, by(lat_lon0)
	
	// rename variables
	rename lat_lon0 lat_lon
	
	// create local name to convert from ie 0.01 to 10, etc
	local name = `neighborhood' * 1000
	rename count nn_`name'
	
	// save file
	save "nearest_neighbors_within_x_meters.dta", replace

	// clear STATA
	clear

	// open 
	use "tickets_nearest_neighbors.dta"

	// merge with nearest neighbors dataset
	merge 1:1 lat_lon using "nearest_neighbors_within_x_meters.dta"

	// replace missing values with 0 to indicate no nearest neighbors within X meters
	replace nn_`name' = 0 if nn_`name' == .

	// drop merge variable
	drop _merge
	
	// save
	save "tickets_nearest_neighbors_loop.dta", replace
	
}

