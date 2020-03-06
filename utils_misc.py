def print_json(json_list):
    """
    # Look up an address with reverse geocoding
    :param json_list:
    :return:
    """
    import requests.packages.urllib3
    requests.packages.urllib3.disable_warnings()
    import json

    parsed = json.loads(json.dumps(json_list))
    print(json.dumps(parsed, indent=4, sort_keys=True))
    print(len(json_list))

    try:
        print([p["types"] for p in json_list])
        for point in json_list:
            print(point["types"])
    except:
        pass


def get_nbhd(client, lat, lng, debug=0):

    # define output dictionary
    nf = 'Not found'
    output_dict = {'adm': nf, 'loc': nf, 'subloc1': nf, 'subloc2': nf, 'full': nf}

    result_type = ["administrative_area_level_3",
                   "administrative_area_level_4",
                   "administrative_area_level_5",
                   "sublocality"]

    res = client.reverse_geocode(latlng=(float(lat), float(lng)), result_type=result_type)
    output_dict['full'] = res

    # parse - select 'sublocality_level_2' if possible
    address_list = [p for p in res if 'sublocality_level_2' in p["types"]]

    # parse - select 'sublocality_level_1' if _2 not available
    if not address_list:
        address_list = [p for p in res if 'sublocality_level_1' in p["types"]]

    # list of address components
    try:
        comps = address_list[0]['address_components']
    except:
        pass

    # get admin
    try:
        output_dict['adm'] = [comp['short_name'] for comp in comps if 'administrative_area_level_2' in comp['types']][0]
    except:
        pass

    # get locality
    try:
        output_dict['loc'] = [comp['short_name'] for comp in comps if 'locality' in comp['types']][0]
    except:
        pass

    # get sub-locality-1
    try:
        output_dict['subloc1'] = [comp['short_name'] for comp in comps if 'sublocality_level_1' in comp['types']][0]
    except:
        pass

    # get sub-locality-2
    try:
        output_dict['subloc2'] = [comp['short_name'] for comp in comps if 'sublocality_level_2' in comp['types']][0]
    except:
        pass

    if not debug:
        output_dict.pop('full', None)
    return output_dict


def read_parameters():
    """
    # Read parameters from file
    :return:
    """
    import csv
    import sys
    # os.chdir(osdir)
    with open('input\parameters.csv', 'r') as csvfile:
        file_contents = csv.reader(csvfile, delimiter=',')

        params = {}
        for row in list(file_contents):
            params[str(row[0])] = row[1]

    for p in ['fname', 'oname_live', 'oname_predicted', 'mykey', 'delta_time', 'offset_time', \
              'recipient', 'subject', 'body', 'osdir', 'local_start_time']:
        try:
            assert p in params
        except:
            sys.exit('Cannot read parameters. Parameter ' + p + ' not found in input\parameters.csv')

    return params


def send_email(user, pwd, recipient, subject, body):
    """
    Send email
    :param user:
    :param pwd:
    :param recipient:
    :param subject:
    :param body:
    :return:
    """
    import smtplib
    import logging

    gmail_user = user
    gmail_pwd = pwd
    FROM = user
    TO = recipient if type(recipient) is list else [recipient]
    SUBJECT = subject
    TEXT = body

    # Prepare actual message
    message = """\From: %s\nTo: %s\nSubject: %s\n\n%s
    """ % (FROM, ", ".join(TO), SUBJECT, TEXT)
    try:
        server = smtplib.SMTP("smtp.gmail.com", 587)
        server.ehlo()
        server.starttls()
        server.login(gmail_user, gmail_pwd)
        server.sendmail(FROM, TO, message)
        server.close()
        print('successfully sent the mail')
        logging.warning('successfully sent the mail')
    except Exception as e:
        print("failed to send mail")
        print(e)
        logging.warning("failed to send mail")
        logging.warning(e)


def write_to_csv(results, oname):
    """
    # Write a list of dictionaries as table to csv
    # This function first creates the union of all keys, which will be the csv table header.
    # For each dictionary in the list, it then writes a line in the csv file,
    # with the dictionary entries in the right columns, and missing values elsewhere.
    :param results:
    :param oname:
    :return:
    """

    # TODO: try catch directly here

    import codecs
    # take union of all keys to create header
    n = len(results)
    keyset = set()
    for d in results:
        keyset = set.union(keyset, set(d.keys()))
    keyset = list(keyset)

    with codecs.open(oname, "w", encoding='utf-8') as myfile:
        # write header
        for k in keyset:
            myfile.write(str(k) + ',')
        myfile.write('\n')
        # write rows
        for d in results:
            for k in keyset:
                if k in d:
                    myfile.write("\"" + var2str(d[k], "%d %b %Y %H:%M:%S") + '\",')
                else:
                    myfile.write(',')
            myfile.write('\n')


def var2str(variable, time_format="%d %b %Y %H:%M:%S"):
    import datetime
    if isinstance(variable, datetime.datetime):
        return variable.strftime(time_format)
    else:
        return str(variable)


# def csv2dict(pathin):
#     """
#     Self explanatory
#     :param pathin:
#     :return:
#     """
#     from csv import DictReader
#     dicts = []
#     with open(pathin, 'r') as csvfile:
#         for d in DictReader(csvfile):
#             dicts.append(d)
#     return dicts


def csv2dict(pathin, key_name=''):
    """
    Self explanatory
    :param pathin:
    :param key_name:
    :return:
    """
    from csv import DictReader
    import os
    import codecs
    dicts = []

    if not os.path.isfile(pathin):
        return []

    with codecs.open(pathin, 'r', encoding='utf-8-sig') as csvfile:
        dicts = [d for d in DictReader(csvfile)]
        # for d in DictReader(csvfile): todo: does this work?
        #     dicts.append(d)

    if key_name:
        try:
            mydict = {}
            for line in dicts:
                # make sure that key_name is indeed a unique key within the file
                assert line[key_name] not in mydict
                mydict[line[key_name]] = line
        except Exception as e:
            print('duplicate keys (' + key_name + ' in file ' + pathin)
            print(line)
            raise e

        return mydict
    else:
        return dicts


def str2hr(time_str, time_format):
    from time import strptime
    temp = strptime(time_str, time_format)
    hours = temp.tm_hour + temp.tm_min / 60 + temp.tm_sec / 3600
    return hours


def dictlist2csv(dictlist, pathout, header='', append=False, na_replace='', debug=False):
    """
    Write a list of dictionaries to csv, (optionally) using an ordered list as headers.
    :param dictlist:
    :param pathout:
    :param header: when provided, it can be a subset of all keys in the dictionaries (union)
    :param append:
    :param na_replace:
    :param debug:
    :return:
    """
    from codecs import open

    if append:
        file_mode = 'a'
    else:
        file_mode = 'w'

    try:
        # If we're given a header, write in that order, and only those fields
        if header:
            rows_list = []
            if not append:
                rows_list.append(','.join(header) + '\n')
            for d in dictlist:
                row = [var2str4csv(d.get(field, na_replace)) for field in header]
                rows_list.append(','.join(row) + '\n')
            with open(pathout, file_mode, encoding='utf-8') as myfile:
                myfile.write(''.join(rows_list))

        else:  # If there is no header, write all keys (union) but not in order
            if debug:
                print("dictlist2csv: no header provided, using union of all headers, sorted alphabetically")
            keyset = set()
            for d in dictlist:
                keyset = set.union(keyset, set(d.keys()))
            keyset = sorted(list(keyset))

            if debug:
                print("dictlist2csv: finished preparing header")

            rows_list = []
            # write header
            if not append:
                rows_list.append(','.join([var2str4csv(k) for k in keyset]) + '\n')
            # write rows
            i = 0
            for d in dictlist:
                i += 1
                if i % 10000 == 1 and debug:
                    print("writing line + " + str(i))
                rows_list.append(','.join([var2str4csv(d.get(k, '')) for k in keyset]) + '\n')

            if debug:
                print("dictlist2csv: finished writing to variable, now writing to file:")

            with open(pathout, file_mode, encoding='utf-8') as myfile:
                myfile.write(''.join(rows_list))

        return True
    except Exception as e:
        print("dictlist2csv: Error printing to file " + pathout)
        print(e)
        return False


def json2dict(pathin, debug=False):
    from json import load
    from pprint import pprint
    from os.path import isfile

    if not isfile(pathin):
        return []

    with open(pathin) as data_file:
        data = load(data_file)

    if debug:
        pprint(data)

    return data


def stuff2json(dictlist, pathout):
    """
    write list of dictionaries to json file
    :param pathout:
    :return:
    """
    from json import dump
    if not dictlist:
        print("Empty json. No log file written.")
        return True
    try:
        with open(pathout, 'w') as fout:
            dump(dictlist, fout)
            print("Success saving json to file " + pathout)
            return True
    except Exception as e:
        print("error writing json to file " + pathout)
        print(e)
        return False


def var2str4csv(variable, time_format="%Y-%m-%d %H:%M:%S"):
    # "%d %b %Y %H:%M:%S"
    import datetime
    if variable == '':
        return ''
    if isinstance(variable, datetime.datetime):
        return "\"D " + variable.strftime(time_format) + "\""
    else:
        return "\"" + str(variable) + "\""


def assure_path_exists(path):
    import os
    dir = os.path.dirname(path)
    if not os.path.exists(dir):
        os.makedirs(dir)
        print("Created " + str(dir))

if __name__ == '__main__':
    # path = "C:/Users/Gabriel K/Dropbox (MIT)/0Re Projects/commoncode/googletimequeries/input_live/fsdfsd.csv"
    # assure_path_exists(path)

    send_email(user='fms.chennai2@gmail.com', pwd='fms1_%%%', recipient='sansingh0100@gmail.com', subject='error in script', body='error')



