
clear all

cd "D:\uber-sp\"

*** Clean the geometry all segments 
	// import delimited using "geometry\road-segs-2018.csv", clear
	// count if osmwayid == .
	// drop if osmwayid == .
	// gisid osmwayid osmstartnodeid osmendnodeid
	// gduplicates report osmwayid osmstartnodeid osmendnodeid
	// format %20.0g osmstartnodeid osmendnodeid
	// order osmwayid osmstartnodeid osmendnodeid osmhighway osmname
	// save "geometry\road-segs-2018.dta", replace 


*** Load data for January
	import delimited using "data-raw\movement-speeds-hourly-sao-paulo-2018-1.csv", clear

	rename osm_way_id osmwayid
	rename osm_start_node_id osmstartnodeid
	rename osm_end_node_id osmendnodeid

	merge m:1 osmwayid osmstartnodeid osmendnodeid using "geometry\road-segs-2018.dta"


	tab osmhighway _m, m
