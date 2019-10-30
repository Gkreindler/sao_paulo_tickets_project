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
