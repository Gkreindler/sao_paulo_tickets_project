// clear STATA
clear

// file path
global s "/Users/san/Dropbox/sao_paulo_tickets_project/data/tickets_v2/"

// change working directory
cd "$s"

// open tickets sample file
use "tickets.dta"

// long is not a valid name in STATA, so longitude is lon
rename long lon

// reformat location for easier reading
format %40.0f location
format %20.0g lat
format %20.0g lon

// convert from factor to numeric
decode year, generate(year2)
decode month, generate(month2)
decode day, generate(day2)
decode hour, generate(hour2)
decode lat, generate(lat2)
decode lon, generate(lon2)

// create lat lon pair
generate lat_lon = lat2 + lon2

destring year2, replace
destring month2, replace
destring day2, replace
destring lat2, replace
destring lon2, replace

drop year month day lat lon

rename year2 year
rename month2 month
rename day2 day
rename lat2 lat
rename lon2 lon

// reformat location for easier reading
format %40.0f location
format %12.0g lat
format %12.0g lon

// convert hour from string to numeric type
generate hour_a = .
replace hour_a = 0 if hour2 == "00:00"
replace hour_a = 1 if hour2 == "01:00"
replace hour_a = 2 if hour2 == "02:00"
replace hour_a = 3 if hour2 == "03:00"
replace hour_a = 4 if hour2 == "04:00"
replace hour_a = 5 if hour2 == "05:00"
replace hour_a = 6 if hour2 == "06:00"
replace hour_a = 7 if hour2 == "07:00"
replace hour_a = 8 if hour2 == "08:00"
replace hour_a = 9 if hour2 == "09:00"
replace hour_a = 10 if hour2 == "10:00"
replace hour_a = 11 if hour2 == "11:00"
replace hour_a = 12 if hour2 == "12:00"
replace hour_a = 13 if hour2 == "13:00"
replace hour_a = 14 if hour2 == "14:00"
replace hour_a = 15 if hour2 == "15:00"
replace hour_a = 16 if hour2 == "16:00"
replace hour_a = 17 if hour2 == "17:00"
replace hour_a = 18 if hour2 == "18:00"
replace hour_a = 19 if hour2 == "19:00"
replace hour_a = 20 if hour2 == "20:00"
replace hour_a = 21 if hour2 == "21:00"
replace hour_a = 22 if hour2 == "22:00"
replace hour_a = 23 if hour2 == "23:00"

drop hour hour2

rename hour_a hour

order vehicle location type issuer vehicle_type year month day hour lat lon 

// sort by time
gsort year month day hour

// keep tickets issued by cameras
keep if issuer == 1

// create a ticket identifier
generate ticket_id = _n

// sort by location
gsort location

// note the syntax for refering a value's label
drop if location == "-":`: value label location'

// generate standard deviation of lat and lon within each location group
bysort location: egen lat_sd = sd(lat)
bysort location: egen lon_sd = sd(lon)

// generate a proxy of variance for lat and lon combined
generate lat_lon_var = sqrt( (lat_sd * lat_sd) + (lon_sd * lon_sd) )

// count number of unique lat_lon observations per location group
by location lat_lon, sort: gen nvals = _n == 1
by location: replace nvals = sum(nvals)
by location: replace nvals = nvals[_N]

drop nvals

// count number of unique lat_lon observations per location group
by lat_lon location, sort: gen nvals = _n == 1
by lat_lon: replace nvals = sum(nvals)
by lat_lon: replace nvals = nvals[_N]

save "tickets_sample_temp.dta", replace
































