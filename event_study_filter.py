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

(3) We sort the c2 list by position along route and loop over them.

(4) Our goal is to then check for the c' conditions for every potential c2. We populate
a list of c' cameras for each c2 camera by identifying all intermediate cameras between
c1 and c2 by position on route. Then we check to ensure that the c' camera start_date
either ends before c1 starts or begins after c1 starts plus a 3 month grace period on
either end. If the c' cameras pass these tests, then nothing happens. But if the c'
cameras fail these tests, then the c2 is removed from the c2 list.

(5) Now our c2 list contains only valid c2 sensing cameras according to our criteria.
Our c2 list should now either be empty or have a single element given the date restrictions
we are using. There can't be multiple valid c2 cameras since the closer of the c2 cameras
would be considered a c' camera of the further away c2 camera, and the date criteria for
c2 and c' cameras are mutually exclusive. But I've coded this as three cases just in case
for whatever reason our criteria shift, not sure if this is a good idea though.

    Case 1 : c2 list is empty. Then there is no valid (c1, c2) pair.

    Case 2 : c2 list has a single element. This is our valid (c1, c2) pair!

    Case 3 : c2 list has more than 1 element. Then choose our valid (c1, c2) pair to be
        (c1, min(c2_list pos_on_route)).
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

for direction in directions:

    # identify (c1, c2) pairs along each direction of cameras
    cameras_direction = [cameras[i] for i in range(len(cameras)) if cameras[i]['direction'] == direction]

    # sort cameras_direction by position on route
    cameras_direction = sorted(cameras_direction, key = lambda i: i['mm_pos_on_route'])

    event_study_pairs = []

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
        # If c1 is too close to c0 and c1 and c0 operates at the same time as, then c1 is not valid.
        for h in range(0, i):
            c0_pos_on_route = cameras_direction[h]['mm_pos_on_route']
            c0_start_date = cameras_direction[h]['cluster_start_date']
            c0_end_date = cameras_direction[h]['cluster_end_date']

            if (i == 0):
                continue

            elif (c1_pos_on_route - c0_pos_on_route < C0_C1_DIST) and \
                (c1_earliest_date < c0_end_date + EVENT_PERIOD) and \
                (c1_earliest_date > c0_start_date - EVENT_PERIOD):

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
            event_study_pairs.append([i, c2_list[0]])
            continue
        print(i, c2_list)
        print(event_study_pairs)
        print(len(event_study_pairs))

        # Step 3 : Check c' conditions for each c2

        # if c2_list is empty, move onto the next c1 camera
        if c2_list == []:
            continue

        # loop over each c2 in c2_list
        for k in c2_list:

            # create a list of c' cameras, ie cameras between c1 and c2
            cprime_list = [l for l in range(i+1, k)]

            for m in cprime_list:
                cprime_start_date = cameras_direction[m]['cluster_start_date']
                cprime_end_date = cameras_direction[m]['cluster_end_date']

                # check if c' either ended before c1 started or started after c1 started, in either case c' would not
                # be an issue for the event study between (c1, c2)
                if (cprime_end_date + EVENT_PERIOD < c1_start_date) or \
                    (cprime_start_date - EVENT_PERIOD > c1_start_date):
                    pass

                # if c' fails these checks, ie c' is present during event study period, then remove c2 from consideration
                else:
                    break

                print(i, k, c2_list)
                event_study_pairs.append([i, k])

    #print(event_study_pairs)
    #print(len(event_study_pairs))



#cameras_south = [cameras[i] for i in range(len(cameras)) if cameras[i]['direction'] == 'Southwest']
#cameras_north = [cameras[i] for i in range(len(cameras)) if cameras[i]['direction'] == 'Northeast']












