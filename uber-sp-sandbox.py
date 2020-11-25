import json
import codecs
import utils_misc
import collections
from pprint import pprint

if __name__ == '__main__':

    ROOT = "D:/uber-sp/geometry/"

    with codecs.open(ROOT + 'geo-2018.geojson', encoding="utf8") as myfile:
        mydata = json.load(myfile)

    # {'geometry': {'coordinates': [[-46.61093960370216,
    #                                -23.61689684432902],
    #                               [-46.61099548050672,
    #                                -23.616853043814984],
    #                               [-46.61101762872492,
    #                                -23.616818251594815],
    #                               [-46.61102177785983,
    #                                -23.616776760245703],
    #                               [-46.6109763089327,
    #                                -23.616658347550352]],
    #               'type': 'LineString'},
    #  'properties': {'osmendnodeid': 468674649,
    #                 'osmhighway': 'residential',
    #                 'osmname': 'Rua Luis Augusto Pereira de Queiroz',
    #                 'osmstartnodeid': 468674334,
    #                 'osmwayid': 238566826},
    #  'type': 'Feature'},

    print("done reading")
    # pprint(mydata)

    road_segments_table = [road_seg['properties'] for road_seg in mydata['features']]
    # for road_seg in mydata['features']:
    #     print(road_seg['properties'])
    #     exit(999)

    utils_misc.dictlist2csv(road_segments_table, ROOT + "road-segs-2018.csv")

    """ frequency table with types """
    # all_types = [road_seg['properties']['osmhighway'] for road_seg in mydata['features']]
    # ctr = collections.Counter(all_types)
    # print("Frequency of the elements in the List : ", ctr)

    # 'residential': 539188,
    # 'service': 55908,
    # 'secondary': 54238,
    # 'tertiary': 53474,
    # 'primary': 31012,
    # 'unclassified': 20454,
    # 'trunk': 9286,
    # 'living_street': 7772,
    # 'primary_link': 5678,
    # 'motorway': 5250,
    # 'secondary_link': 5178,
    # 'motorway_link': 3528,
    # 'tertiary_link': 3102,
    # 'trunk_link': 2906,
    # 'road': 146
    # pprint(all_types)