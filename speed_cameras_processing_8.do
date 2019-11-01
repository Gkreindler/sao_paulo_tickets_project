/*

The goal of this do file is to calculate tickets per timeframe and per month and merge this data with the processed dataset

*/

// clear STATA
clear

// file path
global s "/Users/san/Dropbox/sao_paulo_tickets_project/data/tickets_v2/"
global t "/Users/san/Dropbox/sao_paulo_tickets_project/gis/"
global u "/Users/san/Dropbox/sao_paulo_tickets_project/data/cameras/"

// change working directory
cd "$s"

// open the large tickets dataset
use "tickets_sample_temp.dta"

// for collapse
generate count = 1

// collapse to count tickets per total time period
gcollapse (sum) count, by(location)

// save tickets file
save "number_of_tickets.dta", replace

// clear STATA
clear

// open processed dataset
use "camera_location_nn_marginais.dta"

// merge with tickets data
merge 1:1 location using "number_of_tickets.dta"

// keep matches
keep if _merge == 3

// drop merge status
drop _merge

// rename to make variable better
rename count tickets_total

// calculate total number of days camera was active
generate time_span = end - start

// calculate tickets per day
generate tickets_per_day = tickets_total / time_span

// calculate tickets per month
generate ticket_per_month = tickets_per_day * 30

// save processed dataset
save "camera_location_nn_marginais.dta", replace

// keep selected variables for QGIS
keep location lat lon start_date end_date nn_10 nn_50 nn_100 tickets_total time_span

// change working directory
cd "$t"

// export to QGIS
export delimited "camera_locations2/camera_processed.csv", replace

