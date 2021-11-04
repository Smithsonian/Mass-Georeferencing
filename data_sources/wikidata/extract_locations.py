#!/usr/bin/env python3
#
# Get Wikidata dump records as a JSON stream (one JSON object per line) and save the data to a Postgres database.
#
# Modified script copied from:
#   https://www.reddit.com/r/LanguageTechnology/comments/7wc2oi/does_anyone_know_a_good_python_library_code/dtzsh2j/
#   and based on script at https://akbaritabar.netlify.com/how_to_use_a_wikidata_dump
# 
# v. 2021-03-11
#

import json
import pydash
import sys
import psycopg2
import bz2
from pathlib import Path
#To measure how long it takes
import time
# For parallel
from joblib import Parallel, delayed

#Get postgres creds
import settings


def wikidata(filename):
    """
    Function that reads the data dump and streams line by line, to avoid trying to 
    load a huge file into memory. Can use either the bz2 compressed version or the
    JSON uncompressed file.
    """
    #Get file extension
    ext = Path(filename).suffix.lower()
    if ext == '.json':
        #Uncompressed JSON
        with open(filename, mode='rt') as f:
            f.read(2) # skip first two bytes: "{\n"
            for line in f:
                try:
                    yield json.loads(line.rstrip(',\n'))
                except json.decoder.JSONDecodeError:
                    continue
    elif ext == '.bz2':
        #Compressed bz2
        with bz2.open(filename, mode='rt') as f:
            f.read(2) # skip first two bytes: "{\n"
            for line in f:
                try:
                    yield json.loads(line.rstrip(',\n'))
                except json.decoder.JSONDecodeError:
                    continue
    else:
        print("ERROR: Unknown format.")
        return False
    

def process_record(record):
    # only extract items with geographical coordinates (P625)
    if pydash.has(record, 'claims.P625'):
        #Exclude astronomical locations
        if pydash.has(record, 'claims.P376'):
            #Although P376 doesn't explicitly (?) exclude Earth, it is not used, with 
            # a few exceptions, 20 as of June 2019: https://www.wikidata.org/wiki/Property_talk:P376
            # https://petscan.wmflabs.org/?psid=5844683
            # SELECT ?item WHERE {?item wdt:P376 wd:Q2 . }
            print('Skipping P376')
            return
        else:
            latitude = pydash.get(record, 'claims.P625[0].mainsnak.datavalue.value.latitude')
            longitude = pydash.get(record, 'claims.P625[0].mainsnak.datavalue.value.longitude')
            #Ignore empty or invalid coords
            if latitude == None or longitude == None:
                print('Skipping entry without coords')
                return
            if abs(latitude) > 90 or abs(longitude) > 180:
                print('Skipping entry with invalid coords')
                return
            conn = psycopg2.connect(
                host=settings.host,
                database=settings.db,
                user=settings.user,
                password=settings.password
            )
            conn.autocommit = True
            cur = conn.cursor()
            english_label = pydash.get(record, 'labels.en.value')
            print(' {} ({})'.format(english_label, record['id']))
            item_id = pydash.get(record, 'id')
            item_type = pydash.get(record, 'type')
            #Get labels in multiple languages
            langs = pydash.get(record, 'labels')
            for lang in langs:
                cur.execute("""
                    INSERT INTO wikidata_names (source_id, language, name)
                    VALUES (%s, %s, %s);
                    """,
                    (item_id, langs[lang]['language'], langs[lang]['value']))
            #Get descriptions in multiple languages
            langs = pydash.get(record, 'descriptions')
            for lang in langs:
                cur.execute("""
                    INSERT INTO wikidata_descrip (source_id, language, description)
                    VALUES (%s, %s, %s);
                    """,
                    (item_id, langs[lang]['language'], langs[lang]['value']))
            if english_label != None:
                cur.execute("""
                    INSERT INTO wikidata_records (source_id, type, name, latitude, longitude, the_geom, gadm1)
                    (
                        SELECT 
                            %(id)s, %(type)s, %(name)s, %(latitude)s, %(longitude)s, 
                            ST_SETSRID(ST_POINT(%(longitude)s, %(latitude)s), 4326), 
                            g.name_1 || ', ' || g.name_0 
                        FROM
                            gadm1 g 
                        WHERE 
                            ST_INTERSECTS(g.the_geom, ST_SETSRID(ST_POINT(%(longitude)s, %(latitude)s), 4326))
                    );
                    """,
                    {'id': item_id, 'type': item_type, 'name': english_label, 'latitude': latitude, 'longitude': longitude})
            cur.close()
            conn.close()
    return None


if __name__ == '__main__':
    start_time = time.time()
    import argparse
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description=__doc__
    )
    parser.add_argument(
        'dumpfile',
        help=(
            'a Wikidata dumpfile from: '
            'https://dumps.wikimedia.org/wikidatawiki/entities/'
            'latest-all.json.bz2'
        )
    )
    args = parser.parse_args()
    #Connect to Postgres
    conn = psycopg2.connect(
        host=settings.host,
        database=settings.db,
        user=settings.user,
        password=settings.password
    )
    conn.autocommit = True
    cur = conn.cursor()
    cur.execute("UPDATE data_sources SET is_online = 'f' WHERE datasource_id = 'wikidata'")
    #Delete indices for bulk loading
    cur.execute("DROP INDEX IF EXISTS wikidata_records_id_idx")
    cur.execute("DROP INDEX IF EXISTS wikidata_records_name_trgm_idx")
    cur.execute("DROP INDEX IF EXISTS wikidata_records_the_geom_idx")
    cur.execute("DROP INDEX IF EXISTS wikidata_records_uid_idx")
    cur.execute("DROP INDEX IF EXISTS wikidata_records_gadm2_idx")
    cur.execute("DROP INDEX IF EXISTS wikidata_names_name_idx")
    cur.execute("DROP INDEX IF EXISTS wikidata_names_name_trgm_idx")
    cur.execute("DROP INDEX IF EXISTS wikidata_names_id_idx")
    cur.execute("DROP INDEX IF EXISTS wikidata_names_lang_idx")
    cur.execute("DROP INDEX IF EXISTS wikidata_descrip_descr_idx")
    cur.execute("DROP INDEX IF EXISTS wikidata_descrip_descr_trgm_idx")
    cur.execute("DROP INDEX IF EXISTS wikidata_descrip_id_idx")
    cur.execute("DROP INDEX IF EXISTS wikidata_descrip_lang_idx")
    #Empty tables
    cur.execute("TRUNCATE wikidata_names")
    cur.execute("VACUUM wikidata_names")
    cur.execute("TRUNCATE wikidata_descrip")
    cur.execute("VACUUM wikidata_descrip")
    cur.execute("TRUNCATE wikidata_records")
    cur.execute("VACUUM wikidata_records")
    #for record in tqdm(wikidata(args.dumpfile)):
    #    process_record(record)
    Parallel(n_jobs=settings.parallel_workers, prefer="threads")(delayed(process_record)(record) for record in wikidata(args.dumpfile))
    cur.execute("CREATE INDEX wikidata_records_id_idx ON wikidata_records USING BTREE(source_id);")
    cur.execute("CREATE INDEX wikidata_records_uid_idx ON wikidata_records USING BTREE(uid);")
    cur.execute("CREATE INDEX wikidata_records_name_trgm_idx ON wikidata_records USING gin (name gin_trgm_ops);")
    cur.execute("CREATE INDEX wikidata_records_gadm2_idx ON wikidata_records USING gin (gadm2 gin_trgm_ops);")
    cur.execute("CREATE INDEX wikidata_records_the_geom_idx ON wikidata_records USING gist(the_geom);")

    cur.execute("CREATE INDEX wikidata_names_name_trgm_idx ON wikidata_names USING gin (name gin_trgm_ops);")
    cur.execute("CREATE INDEX wikidata_names_id_idx ON wikidata_names USING btree (source_id);")
    cur.execute("CREATE INDEX wikidata_names_lang_idx ON wikidata_names USING btree (language);")

    cur.execute("CREATE INDEX wikidata_descrip_descr_trgm_idx ON wikidata_descrip USING gin (description gin_trgm_ops);")
    cur.execute("CREATE INDEX wikidata_descrip_id_idx ON wikidata_descrip USING btree (source_id);")
    cur.execute("CREATE INDEX wikidata_descrip_lang_idx ON wikidata_descrip USING btree (language);")
    cur.execute("UPDATE data_sources SET is_online = 'T', source_date = CURRENT_DATE WHERE datasource_id = 'wikidata'")
    cur.execute("UPDATE data_sources SET no_features = w.no_feats FROM (select count(*) as no_feats from wikidata_names) w WHERE datasource_id = 'wikidata'")
    cur.close()
    conn.close()
    end_time = time.time()
    total_time = end_time - start_time


#Display how many hours it took to run
print("\nScript took {} hrs to complete.\n".format(round(total_time / 3600, 2)))

sys.exit(0)
