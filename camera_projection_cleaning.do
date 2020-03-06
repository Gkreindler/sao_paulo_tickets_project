/*

*/

clear all

global s "/Users/san/Dropbox/sao_paulo_tickets_project/data/cameras_v2/"

cd "$s"

import delimited "cameras_map_matched.csv", encoding(utf-8)

rename v5 lon

bysort id: egen dist_min = min(mm_dist2route)
bysort id: egen dist_max = max(mm_dist2route)

keep direction id mm*

gsort id mm_dist2route

bysort id: keep if _n == 1

save "camera_projections.dta", replace
