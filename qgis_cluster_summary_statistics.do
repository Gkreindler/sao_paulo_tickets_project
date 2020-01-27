/*

The goal of this do file is to generate summary statistics from my manual clustering
of speed cameras along the marginais in QGIS:

(1) merge raw QGIS layer csv with manually selected links to Google Street View camera displays

(2) generate camera level statistics, count, lead times and distribution

(3) cluster count, distriution of cluster size, generate cluster level variables

(4) generate cluster level variables and merge back into camera level dataset

(5) display cluster level statistics for all cluster, single camera cluster

*/

{ // (1) open data, define path, merge links file, clean up date formatting

	clear all

	global s "/Users/san/Dropbox/sao_paulo_tickets_project/gis/camera_locations2/"

	cd "$s"

	// import csv files and save as .dta
	import delimited "qgis_clustered_raw.csv"
	save "qgis_clustered_raw.dta", replace
	import delimited "qgis_camera_links.csv", clear
	rename ïfid fid // can't figure out why this text encoding error happens on import
	save "qgis_camera_links.dta", replace
	use "qgis_clustered_raw.dta", clear

	// merge with links data
	merge 1:1 fid using "qgis_camera_links.dta"
	drop _merge

	// drop empty observations with missing lat
	drop if lat == .

	// clean up date formatting
	generate start_date2 = date(start_date, "DM20Y")
	generate end_date2 = date(end_date, "DM20Y")
	generate gmaps_unseen2 = date(gmaps_unseen, "MY")
	generate gmaps_seen2 = date(gmaps_seen, "MY")
	
	format start_date2 %dM_d,_CY
	format end_date2 %dM_d,_CY
	format gmaps_unseen2 %dM_d,_CY
	format gmaps_seen2 %dM_d,_CY
	
	drop start_date end_date gmaps_seen gmaps_unseen
	
	rename start_date2 start_date
	rename end_date2 end_date
	rename gmaps_unseen2 gmaps_unseen
	rename gmaps_seen2 gmaps_seen

}

// comment this line out if you want to run stats on just gmaps present cameras
// keep if gmaps_seen != .

{ // (2) camera level stats, count, distribution of lead times

	// The number of cameras
	count

	gsort cluster start_date

	// gmaps lead time is difference between nothing in google and something in google
	generate gmaps_lead_time = gmaps_seen - gmaps_unseen
	
	// there are many zero values that occur because cameras appeared in the beginning of 
	// gmaps street view history, this variable filters these default zeroes out
	generate gmaps_lead_time_without_zeroes = gmaps_lead_time if gmaps_lead_time > 0 & gmaps_lead_time != .

	// camera lead time is difference between camera showing up on google and camera ticketing
	generate camera_lead_time = start_date - gmaps_seen	
	
	/* if camera lead time is negative, it means the camera was seen in gmaps after the camera began ticketing, which could be due to a lack of fine gmaps history dataset
	
	However, if camera lead time is positive, it means that the camera was seen in gmaps before the camera began ticketing, which is of interest for the validity of the event study
	
	Therefore, camera_lead_time_conditional is created to count the average of the positive values of camera lead time only. */
	generate camera_lead_time_conditional = camera_lead_time if camera_lead_time > 0 & camera_lead_time != .
	
	// summarize lead time variables
	summarize gmaps_lead_time, detail
	summarize gmaps_lead_time_without_zeroes, detail
	summarize camera_lead_time, detail
	summarize camera_lead_time_conditional, detail

}

{ // (3) cluster count, distriution of cluster size

	// The number of clusters
	distinct cluster

	// cluster size counts the size of each cluster
	bysort cluster: generate cluster_size = _N

	// collapse to cluster level to show distribution of cluster size
	preserve
	bysort cluster: keep if _n == 1
	tab cluster_size
	restore

	save "qgis_clustered.dta", replace

}

{ // (4) generate cluster level variables and merge back into camera level dataset

	// collapse to identify minimum start date across clusters
	collapse (min) start_date gmaps_seen gmaps_unseen, by(cluster)

	// generate cluster level variables
	generate cluster_start_date = start_date
	generate cluster_gmaps_seen = gmaps_seen
	generate cluster_gmaps_unseen = gmaps_unseen
	generate cluster_gmaps_lead_time = cluster_gmaps_seen - cluster_gmaps_unseen

	// format cluster level date variables
	format cluster_start_date %dM_d,_CY
	format cluster_gmaps_seen %dM_d,_CY
	format cluster_gmaps_unseen %dM_d,_CY

	keep cluster*

	// merge cluster level variables into camera level dataset
	save "qgis_clustered_temp.dta", replace
	use "qgis_clustered.dta", clear
	merge m:1 cluster using "qgis_clustered_temp.dta"
	drop _merge

	// OK if cluster starts after unseen but before seen
	generate OK = .
	replace OK = (cluster_start_date > cluster_gmaps_unseen & cluster_start_date < cluster_gmaps_seen)

	// STARTS_EARLIER if maps starts before tickets
	generate GM_STARTS_EARLIER = .
	replace GM_STARTS_EARLIER = (cluster_start_date > cluster_gmaps_seen)

	// STARTS_LATER	if maps starts after ticketing
	generate GM_STARTS_LATER = .
	replace GM_STARTS_LATER = (cluster_start_date < cluster_gmaps_unseen & cluster_gmaps_unseen != .)

	// NODATA is no maps data in cluster
	generate GM_NODATA = .
	replace GM_NODATA = (cluster_gmaps_seen == . | cluster_gmaps_unseen == .)

	save "qgis_clustered.dta", replace
	
	/* 
	For cameras that I was able to identify in Google Maps where Google Maps data was detected
	before the cameras began ticketing, we want to identify the gap between the start_date
	date inferred by Google Maps with the start date inferred by ticketing. The Google Maps start
	date comes from two measures: 1) the latest month a camera is not seen and 2) the earliest
	month a camera is seen. We compute two measures here: 1) lower_bound_gap : an 
	"optimistic" lower bound gap and 2) upper_bound_gap : "pessimistic" upper bound gap.
	Both measures are calculated at the camera and cluster level.
	*/
	
	generate lower_bound_gap = .
	replace lower_bound_gap = start_date - gmaps_seen if start_date > gmaps_seen
	
	generate upper_bound_gap = .
	replace upper_bound_gap = start_date - gmaps_unseen if start_date > gmaps_seen
	
	generate cluster_lower_bound_gap = .
	replace cluster_lower_bound_gap = cluster_start_date - cluster_gmaps_seen if GM_STARTS_EARLIER
	
	generate cluster_upper_bound_gap = .
	replace cluster_upper_bound_gap = cluster_start_date - cluster_gmaps_unseen if GM_STARTS_EARLIER

}

{ // (5) display cluster level statistics for all cluster, single camera cluster

	// collapse by cluster
	bysort cluster: keep if _n == 1

	// display tabbed results
	tab OK
	tab GM_STARTS_EARLIER
	tab GM_STARTS_LATER
	tab GM_NODATA
	summarize cluster_lower_bound_gap, detail
	summarize cluster_upper_bound_gap, detail

	// show tabbed results for single camera clusters
	keep if cluster_size == 1
	tab OK
	tab GM_STARTS_EARLIER
	tab GM_STARTS_LATER
	tab GM_NODATA

}

