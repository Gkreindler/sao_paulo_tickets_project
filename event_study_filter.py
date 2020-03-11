'''
The purpose of this script is to identify valid cluster pairs for the event study.

(1) We check c1 and c0 conditions:
    a) c1 is too close to c0
    b) c1 and c0 operate at the same time

    If a and b hold, then c1 is not valid.

(2) We create a list of potential c2 cameras that fit the following criteria:

    a) range criteria of falling within 50 to 1500 meters downstream of c1
    b) c2 must be a permanent camera
    c) c2 must start before c1 starts ticketing or is seen in google maps

(3) Our goal is to then check for the c' conditions for every potential c2. We sort the
c2 list by position along route and loop over them. We populate
a list of c' cameras for each c2 camera by identifying all intermediate cameras between
c1 and c2 by position on route. Then we check to ensure that the c' camera start_date
either ends before c1 starts or begins after c1 starts plus a 3 month grace period on
either end. If the c' cameras pass these tests, then we have a valid (c1, c2) pair.
'''

from pprint import pprint
import utils_misc as ut
from datetime import datetime, timedelta

'''
INPUT_FILE is the csv contains our clustered camera data
C0_C1_DIST is the distance between c0 and c1
EVENT_PERIOD is the +- amount of time allowed for the event study to occur, used in date comparisons
C2_MIN_DIST is the minimum distance allowed between c1 and c2
C2_MAX_DIST is the maximum distance allowed between c1 and c2
'''

INPUT_FILE = '/Users/san/Dropbox/sao_paulo_tickets_project/gis/camera_locations2/event_study_data.csv'
C0_C1_DIST = 100
EVENT_PERIOD = timedelta(days=90)
C2_MIN_DIST = 50
C2_MAX_DIST = 1500

# import csv as list of dictionaries
cameras = ut.csv2dict(INPUT_FILE)

# convert dictionary strings to correct data types
for i in range(len(cameras)):
    cameras[i]['cluster'] = int(cameras[i]['cluster'])
    cameras[i]['cluster_size'] = int(cameras[i]['cluster_size'])
    cameras[i]['mm_pos_on_route'] = float(cameras[i]['mm_pos_on_route'])

    cameras[i]['cluster_start_date'] = datetime.strptime(cameras[i]['cluster_start_date'], '%d-%b-%y')
    cameras[i]['cluster_end_date'] = datetime.strptime(cameras[i]['cluster_end_date'], '%d-%b-%y')

    if cameras[i]['cluster_gmaps_seen'] != '':
        cameras[i]['cluster_gmaps_seen'] = datetime.strptime(cameras[i]['cluster_gmaps_seen'], '%d-%b-%y')
        cameras[i]['cluster_gmaps_unseen'] = datetime.strptime(cameras[i]['cluster_gmaps_unseen'], '%d-%b-%y')

directions = ['Northeast', 'Southwest']
event_study_pairs = []

# loop over cameras in each direction along the marginais separately
for direction in directions:

    cameras_direction = [camera for camera in cameras if camera['direction'] == direction]

    # sort cameras_direction by position on route
    cameras_direction = sorted(cameras_direction, key = lambda i: i['mm_pos_on_route'])

    # loop over all c1 cameras_direction
    for i in range(len(cameras_direction)):
        c1_pos_on_route = cameras_direction[i]['mm_pos_on_route']
        c1_start_date = cameras_direction[i]['cluster_start_date']
        c1_gmaps_seen = cameras_direction[i]['cluster_gmaps_seen']

        if cameras_direction[i]['cluster_gmaps_seen'] == '':
            c1_earliest_date = c1_start_date
        else:
            c1_earliest_date = min(c1_start_date, c1_gmaps_seen)

        # Step 1 : Check c1 and c0 conditions
        current_c1_is_good = True

        # loop over potential c0 cameras that occur before c1 along the marginais
        for h in range(0, i):
            c0_pos_on_route = cameras_direction[h]['mm_pos_on_route']
            c0_start_date = cameras_direction[h]['cluster_start_date']
            c0_end_date = cameras_direction[h]['cluster_end_date']

            # since the first c1 has no c0 camera before, it, it automatically passes to step 2
            if i == 0:
                break

            # If c1 is too close to c0 and c1 and c0 operates at the same time as c1, then c1 is not valid.
            if (c1_pos_on_route - c0_pos_on_route < C0_C1_DIST) and not \
                ((c0_end_date < c1_earliest_date - EVENT_PERIOD) or
                (c0_start_date > c1_earliest_date + EVENT_PERIOD)):

                current_c1_is_good = False

        # if c1 is disqualified by a c0, terminate the current iteration of the c1 loop and continue to the next iteration
        if not current_c1_is_good:
            continue

        # Step 2 : Create a list of potential c2 cameras
        c2_list = []

        # loop over all cameras
        for j in range(len(cameras_direction)):
            c2_pos_on_route = cameras_direction[j]['mm_pos_on_route']
            c2_temp = cameras_direction[j]['temp']
            c2_start_date = cameras_direction[j]['cluster_start_date']

            # Check c2 conditions for every single possible c2, c2 must be an appropriate distance away
            # from c1, c2 must be a permanent camera, and c2 must start before c1 plus the event period
            if (C2_MIN_DIST < c2_pos_on_route - c1_pos_on_route < C2_MAX_DIST) and \
                (c2_temp == '0') and \
                (c2_start_date + EVENT_PERIOD < c1_earliest_date):

                assert j > i
                c2_list.append(j)

        # check to see if the nearest c2 camera for c1 is directly next to it with not intermediates, if so then
        # we already have our valid (c1, c2) pair with no need to check for intermediates
        if c2_list != [] and c2_list[0] - i == 1:
            event_study_pairs.append([i, c2_list[0], direction])
            continue

        # Step 3 : Check c' conditions for each c2

        # if c2_list is empty, move onto the next c1 camera
        if c2_list == []:
            continue

        # loop over each c2 in c2_list and check all intermediary points
        for k in c2_list:

            current_c2_is_good = True

            # loop over c' cameras, ie cameras between c1 and c2
            for j in range(i + 1, k):
                cprime_start_date = cameras_direction[j]['cluster_start_date']
                cprime_end_date = cameras_direction[j]['cluster_end_date']
                cprime_gmaps_seen = cameras_direction[j]['cluster_gmaps_seen']

                if cameras_direction[j]['cluster_gmaps_seen'] == '':
                    cprime_earliest_date = cprime_start_date
                else:
                    cprime_earliest_date = min(cprime_start_date, cprime_gmaps_seen)

                # the bad condition
                if not ((cprime_end_date < c1_start_date - EVENT_PERIOD) or
                        (cprime_start_date > c1_start_date + EVENT_PERIOD)):
                    current_c2_is_good = False

            # survived all intermediary c'
            if current_c2_is_good:
                event_study_pairs.append([i, k, direction])

pprint(event_study_pairs)
