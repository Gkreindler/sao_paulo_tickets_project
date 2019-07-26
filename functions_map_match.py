import copy
import math
from pprint import pprint
import operator
import fiona
#import utils2
from utils2 import utils as ut

# average horiz/vertical
COORD2METERS_SCALE = (108811.8 + 110622.9) / 2.0
COORD2METERS_SCALE_SQ = COORD2METERS_SCALE * COORD2METERS_SCALE


def simpledist(coord1, coord2):
    delta0 = coord1[0] - coord2[0]
    delta1 = coord1[1] - coord2[1]
    return math.sqrt(delta0 * delta0 + delta1 * delta1) * COORD2METERS_SCALE


def pnt2line(pnt, start, end):
    seg0 = end[0] - start[0]
    seg1 = end[1] - start[1]
    line_len_sq = seg0 * seg0 + seg1 * seg1

    # if the line is degenerate
    if line_len_sq * COORD2METERS_SCALE_SQ < 4:
        delta0 = pnt[0] - start[0]
        delta1 = pnt[1] - start[1]
        dist = math.sqrt(delta0 * delta0 + delta1 * delta1) * COORD2METERS_SCALE
        return dist, start, -1

    line_unitvec = (seg0, seg1)
    pnt_vec_scaled = ((pnt[0] - start[0]) , (pnt[1] - start[1]))
    t = (line_unitvec[0] * pnt_vec_scaled[0] + line_unitvec[1] * pnt_vec_scaled[1]) / line_len_sq
    if t < 0.0: t = 0.0
    elif t > 1.0: t = 1.0

    nearest = (start[0] + t * seg0, start[1] + t * seg1)
    delta0 = nearest[0] - pnt[0]
    delta1 = nearest[1] - pnt[1]
    dist = math.sqrt(delta0 * delta0 + delta1 * delta1) * COORD2METERS_SCALE

    return dist, nearest, t


def dist_pt2route(point, route, route_seg_lengths, route_cum_lengths):
    """
    Distance from point to route
    Return
    (1) closest point on the route
    (2) distance from (in meters)
    (3) position of the closest point on the route: segment id
    (4) position of the closest point on the route: % of segment
    (5) position of the closest point on the route: cumulative length on the polyline
    """

    # get closest point and distance from point to each segments in the route
    segments = [(route[idx], route[idx + 1]) for idx in range(len(route) - 1)]
    dist_and_closest_pts = [pnt2line(point, start, end) for start, end in segments]
    # [0] - distance
    # [1] - point
    # [2] - t or fraction of the segment (from start to end) where closest point lies

    # distances only
    distances = [value[0] for value in dist_and_closest_pts]

    # find minimum
    min_index, min_value = min(enumerate(distances), key=operator.itemgetter(1))

    # position of the closest point on the path
    pos_on_route_meters = route_cum_lengths[min_index] + \
                          route_seg_lengths[min_index] * dist_and_closest_pts[min_index][2]

    return dist_and_closest_pts[min_index][1], \
            min_value, \
            min_index, \
            dist_and_closest_pts[min_index][2], \
            pos_on_route_meters


def csv2dictlist(csvfile):
    '''reads in csv file and converts it into a list of dictionaries
    (one dictionary per row).
    Keys to the dictionary are column names.
    Warning- this function does not preserve the order of the column names!
    '''
    reader = csv.DictReader(open(csvfile,'rb'))
    info = [i for i in reader]
    return info


if __name__ == '__main__':

    ROOT_PATH = "C:/Users/felip/Box/Summer 2019/Sao Paulo/"

    """ Read the shape file with Marginais """
    # key parts: the polyline saved as a list of coordinates
#    data/marg_mod/marg_mod.shp
    marg_roads= fiona.open(ROOT_PATH + "data/marg_mod/marg_mod.shp")
    print(marg_roads.schema)

    for marg_part in marg_roads:
        pprint(marg_part)

    # there are 4 segments in marg_roads: east, west, north, south
    # to add manually:
    # EAST  :
    # WEST  :
    # NORTH :
    # SOUTH :

    # convert to list
    marg_roads = [marg_part for marg_part in marg_roads]
    for marg_part in marg_roads:
        road_direction = marg_part['properties']['Direction']
        road_polyline = marg_part['geometry']['coordinates']

        # compute the cumulative length in meters until the N-th segment of the polyline
        seg_lengths = [simpledist(road_polyline[idx], road_polyline[idx + 1]) for idx in range(len(road_polyline) - 1)]

        # cumulative length up to a certain segment
        cum_lengths = [0]
        for idx in range(0, len(road_polyline)-1):
            cum_lengths.append(cum_lengths[-1] + seg_lengths[idx])
        marg_part['seg_lengths'] = seg_lengths
        marg_part['cum_lengths'] = cum_lengths

    """ Read camera locations """
    camera_locations = ut.csv2dict(ROOT_PATH + "data\cameras\cameras.csv")


    """ snap each camera to each of the 2 marginais segments """
    camera_locations_map_matched = []
    for camera in camera_locations:

        camera_location = float(camera['long']), float(camera['lat'])

        for marg_part in marg_roads:
            road_direction = marg_part['properties']['Direction']
            road_polyline = marg_part['geometry']['coordinates']

            closest_point, \
                distance2route, \
                seg_idx, \
                seg_loc, \
                pos_on_route = dist_pt2route(camera_location,
                                             route=road_polyline,
                                             route_cum_lengths=marg_part['cum_lengths'],
                                             route_seg_lengths=marg_part['seg_lengths'])

            # save result
            camera_new = copy.deepcopy(camera)
            camera_new['direction'] = road_direction
            camera_new['mm_lat'] = closest_point[1]
            camera_new['mm_long'] = closest_point[0]
            camera_new['mm_pos_on_route'] = pos_on_route
            camera_new['mm_dist2route'] = distance2route
            camera_locations_map_matched.append(camera_new)

    # save
    camera_locations_map_matched_file = ROOT_PATH + "data\cameras\cameras_map_matched_mod.csv"
    ut.dictlist2csv(camera_locations_map_matched, camera_locations_map_matched_file)

