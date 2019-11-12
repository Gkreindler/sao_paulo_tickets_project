/*

This do file takes the cluster notes excel spreadsheet and generates some simple summary statistics from the data.

*/

// clear STATA
clear

// file paths
global s "/Users/san/Dropbox/sao_paulo_tickets_project/data/tickets_v2/"
global t "/Users/san/Google Drive/Academics/Harvard RA/Sao Paolo Speed Cameras/sao_paulo_tickets_project/"

// clear STATA
clear

// change working directory
cd "$t"

// imports the excel file, uses first row as variable names
import excel "cluster_notes.xlsx", first

// drops empty rows
drop if location == ""

// drop unnecessary variables
drop picture notes

// create parsed location variable for merging, without vowels due to special characters
egen location_parsed = sieve(location), char(0123456789bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ)

// save file
save "cluster_notes.dta", replace

// clear STATA
clear

// import QGIS data
import delimited "/Users/san/Dropbox/sao_paulo_tickets_project/gis/camera_locations2/camera_processed.csv"

// create parsed location variable for merging, without vowels due to special characters
egen location_parsed = sieve(location), char(0123456789bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ)

drop if location == "Av Morvan Dias De Figueiredo (As/Cb),  A Menos 36m Rua  Dr. Vidal Reis"

// save as .dta
save "/Users/san/Dropbox/sao_paulo_tickets_project/gis/camera_locations2/camera_processed.dta", replace
 
// clear STATA
clear

// use cluster file
use "cluster_notes.dta"

// merge files
merge 1:1 location_parsed using "/Users/san/Dropbox/sao_paulo_tickets_project/gis/camera_locations2/camera_processed.dta"

// keep successful merges
keep if _merge == 3

// keep selected variables
keep location cluster start end present lat lon start_date end_date tickets_total time_span

