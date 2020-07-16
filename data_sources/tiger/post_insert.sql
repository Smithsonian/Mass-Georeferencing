
CREATE INDEX tiger_arealm_name_idx ON tiger_arealm USING gin (fullname gin_trgm_ops);
CREATE INDEX tiger_areawater_name_idx ON tiger_areawater USING gin (fullname gin_trgm_ops);
CREATE INDEX tiger_counties_name_idx ON tiger_counties USING gin (name gin_trgm_ops);
CREATE INDEX tiger_roads_name_idx ON tiger_roads USING gin (fullname gin_trgm_ops);

CREATE INDEX tiger_arealm_geom_idx ON tiger_arealm USING gist (the_geom);
CREATE INDEX tiger_areawater_geom_idx ON tiger_areawater USING gist (the_geom);
CREATE INDEX tiger_counties_geom_idx ON tiger_counties USING gist (the_geom);
CREATE INDEX tiger_roads_geom_idx ON tiger_roads USING gist (the_geom);




--tiger_arealm
--Add UUID
ALTER TABLE tiger_arealm add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX tiger_arealm_uid_idx ON tiger_arealm USING btree(uid);

--Add SRID
UPDATE tiger_arealm SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE tiger_arealm SET the_geom = ST_MULTI(ST_SETSRID(the_geom, 4326));

ALTER TABLE tiger_arealm ADD COLUMN centroid geometry;
UPDATE tiger_arealm SET centroid = ST_Centroid(the_geom);

ALTER TABLE tiger_arealm ADD COLUMN the_geom_webmercator geometry;
UPDATE tiger_arealm SET the_geom_webmercator = ST_transform(the_geom, 3857);
CREATE INDEX tiger_arealm_the_geomw_idx ON tiger_arealm USING gist (the_geom_webmercator);



--tiger_areawater
--Add UUID
ALTER TABLE tiger_areawater add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX tiger_areawater_uid_idx ON tiger_areawater USING btree(uid);

--Add SRID
UPDATE tiger_areawater SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE tiger_areawater SET the_geom = ST_MULTI(ST_SETSRID(the_geom, 4326));

ALTER TABLE tiger_areawater ADD COLUMN centroid geometry;
UPDATE tiger_areawater SET centroid = ST_Centroid(the_geom);

ALTER TABLE tiger_areawater ADD COLUMN the_geom_webmercator geometry;
UPDATE tiger_areawater SET the_geom_webmercator = ST_transform(the_geom, 3857);
CREATE INDEX tiger_areawater_the_geomw_idx ON tiger_areawater USING gist (the_geom_webmercator);



--tiger_counties
ALTER TABLE tiger_counties add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX tiger_counties_uid_idx ON tiger_counties USING btree(uid);

--Add SRID
UPDATE tiger_counties SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';
UPDATE tiger_counties SET the_geom = ST_MULTI(ST_SETSRID(the_geom, 4326));

ALTER TABLE tiger_counties ADD COLUMN centroid geometry;
UPDATE tiger_counties SET centroid = ST_Centroid(the_geom);

ALTER TABLE tiger_counties ADD COLUMN the_geom_webmercator geometry;
UPDATE tiger_counties SET the_geom_webmercator = ST_transform(the_geom, 3857);
CREATE INDEX tiger_counties_the_geomw_idx ON tiger_counties USING gist (the_geom_webmercator);


--tiger_roads
ALTER TABLE tiger_roads add column uid uuid DEFAULT uuid_generate_v4();
CREATE INDEX tiger_roads_uid_idx ON tiger_roads USING btree(uid);

--Add SRID
UPDATE tiger_roads SET the_geom = ST_SETSRID(the_geom, 4326);
UPDATE tiger_roads SET the_geom = ST_MAKEVALID(the_geom) WHERE ST_ISVALID(the_geom) = 'F';

ALTER TABLE tiger_roads ADD COLUMN centroid geometry;
UPDATE tiger_roads SET centroid = ST_Centroid(the_geom);

ALTER TABLE tiger_roads ADD COLUMN the_geom_webmercator geometry;
UPDATE tiger_roads SET the_geom_webmercator = ST_transform(the_geom, 3857);
CREATE INDEX tiger_roads_the_geomw_idx ON tiger_roads USING gist (the_geom_webmercator);





--Add gamd2
ALTER TABLE tiger_arealm ADD COLUMN gadm2 text;
ALTER TABLE tiger_areawater ADD COLUMN gadm2 text;
ALTER TABLE tiger_counties ADD COLUMN gadm2 text;
ALTER TABLE tiger_roads ADD COLUMN gadm2 text;

--tiger_arealm
WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        tiger_arealm w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE tiger_arealm g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;

--tiger_areawater
WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        tiger_areawater w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE tiger_areawater g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;

--tiger_counties
WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        tiger_counties w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE tiger_counties g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;

--tiger_roads
WITH data AS (
    SELECT 
        w.uid,
        string_agg(g.name_2 || ', ' || g.name_1 || ', ' || g.name_0, '; ') as loc
    FROM 
        tiger_roads w,
        gadm2 g
    WHERE 
        ST_INTERSECTS(w.the_geom, g.the_geom)
    GROUP BY 
        w.uid
)
UPDATE tiger_roads g SET gadm2 = d.loc FROM data d WHERE g.uid = d.uid;




--tiger_counties add type
ALTER TABLE tiger_counties ADD column type text;
CREATE INDEX tiger_counties_lsad_idx ON tiger_counties USING btree(lsad);
UPDATE tiger_counties SET type = '' WHERE lsad = '00';
UPDATE tiger_counties SET type = 'City and Borough' WHERE lsad = '03';
UPDATE tiger_counties SET type = 'Borough' WHERE lsad = '04';
UPDATE tiger_counties SET type = 'Census Area' WHERE lsad = '05';
UPDATE tiger_counties SET type = 'County' WHERE lsad = '06';
UPDATE tiger_counties SET type = 'District' WHERE lsad = '07';
UPDATE tiger_counties SET type = 'Island' WHERE lsad = '10';
UPDATE tiger_counties SET type = 'Municipality' WHERE lsad = '12';
UPDATE tiger_counties SET type = 'Municipio' WHERE lsad = '13';
UPDATE tiger_counties SET type = 'Parish' WHERE lsad = '15';
UPDATE tiger_counties SET type = 'City' WHERE lsad = '25';


--tiger_arealm add type
ALTER TABLE tiger_arealm ADD column type text;
CREATE INDEX tiger_arealm_mtfcc_idx ON tiger_arealm USING btree(mtfcc);
UPDATE tiger_arealm SET type = 'Island' WHERE mtfcc = 'C3023';
UPDATE tiger_arealm SET type = 'Levee' WHERE mtfcc = 'C3024';
UPDATE tiger_arealm SET type = 'Quarry, Open Pit Mine, or Mine' WHERE mtfcc = 'C3026';
UPDATE tiger_arealm SET type = 'Dam' WHERE mtfcc = 'C3027';
UPDATE tiger_arealm SET type = 'Tower/Beacon' WHERE mtfcc = 'C3070';
UPDATE tiger_arealm SET type = 'Transmission Tower' WHERE mtfcc = 'C3072';
UPDATE tiger_arealm SET type = 'Water Tower' WHERE mtfcc = 'C3073';
UPDATE tiger_arealm SET type = 'Tank/Tank Farm' WHERE mtfcc = 'C3075';
UPDATE tiger_arealm SET type = 'Windmill Farm' WHERE mtfcc = 'C3076';
UPDATE tiger_arealm SET type = 'Solar Farm' WHERE mtfcc = 'C3077';
UPDATE tiger_arealm SET type = 'Landfill' WHERE mtfcc = 'C3088';
UPDATE tiger_arealm SET type = 'Apartment Building or Complex' WHERE mtfcc = 'K1121';
UPDATE tiger_arealm SET type = 'Trailer Court' WHERE mtfcc = 'K1223';
UPDATE tiger_arealm SET type = 'Crew-of-Vessel Location' WHERE mtfcc = 'K1225';
UPDATE tiger_arealm SET type = 'Housing Facility/Dormitory for Workers' WHERE mtfcc = 'K1226';
UPDATE tiger_arealm SET type = 'Hotel, Motel, Resort, Spa, Hostel, YMCA, or YWCA' WHERE mtfcc = 'K1227';
UPDATE tiger_arealm SET type = 'Campground' WHERE mtfcc = 'K1228';
UPDATE tiger_arealm SET type = 'Shelter or Mission' WHERE mtfcc = 'K1229';
UPDATE tiger_arealm SET type = 'Hospital/Hospice/Urgent Care Facility' WHERE mtfcc = 'K1231';
UPDATE tiger_arealm SET type = 'Nursing Home, Retirement Home, or Home for the Aged' WHERE mtfcc = 'K1233';
UPDATE tiger_arealm SET type = 'County Home or Poor Farm' WHERE mtfcc = 'K1234';
UPDATE tiger_arealm SET type = 'Juvenile Institution' WHERE mtfcc = 'K1235';
UPDATE tiger_arealm SET type = 'Local Jail or Detention Center' WHERE mtfcc = 'K1236';
UPDATE tiger_arealm SET type = 'Federal Penitentiary, State Prison, or Prison Farm' WHERE mtfcc = 'K1237';
UPDATE tiger_arealm SET type = 'Other Correctional Institution' WHERE mtfcc = 'K1238';
UPDATE tiger_arealm SET type = 'Convent, Monastery, Rectory, Other Religious Group Quarters' WHERE mtfcc = 'K1239';
UPDATE tiger_arealm SET type = 'Sorority, Fraternity, or College Dormitory' WHERE mtfcc = 'K1241';
UPDATE tiger_arealm SET type = 'Governmental Workplaces' WHERE mtfcc = 'K2100';
UPDATE tiger_arealm SET type = 'Community Center' WHERE mtfcc = 'K2146';
UPDATE tiger_arealm SET type = 'Government Center' WHERE mtfcc = 'K2165';
UPDATE tiger_arealm SET type = 'Convention Center' WHERE mtfcc = 'K2167';
UPDATE tiger_arealm SET type = 'Park' WHERE mtfcc = 'K2180';
UPDATE tiger_arealm SET type = 'National Park Service Land' WHERE mtfcc = 'K2181';
UPDATE tiger_arealm SET type = 'National Forest or Other Federal Land' WHERE mtfcc = 'K2182';
UPDATE tiger_arealm SET type = 'Tribal Park, Forest, or Recreation Area' WHERE mtfcc = 'K2183';
UPDATE tiger_arealm SET type = 'State Park, Forest, or Recreation Area' WHERE mtfcc = 'K2184';
UPDATE tiger_arealm SET type = 'Regional Park, Forest, or Recreation Area' WHERE mtfcc = 'K2185';
UPDATE tiger_arealm SET type = 'County Park, Forest, or Recreation Area' WHERE mtfcc = 'K2186';
UPDATE tiger_arealm SET type = 'County Subdivision Park, Forest, or Recreation Area' WHERE mtfcc = 'K2187';
UPDATE tiger_arealm SET type = 'Incorporated Place Park, Forest, or Recreation Area' WHERE mtfcc = 'K2188';
UPDATE tiger_arealm SET type = 'Private Park, Forest, or Recreation Area' WHERE mtfcc = 'K2189';
UPDATE tiger_arealm SET type = 'Other Park, Forest, or Recreation Area' WHERE mtfcc = 'K2190';
UPDATE tiger_arealm SET type = 'Commercial Workplace' WHERE mtfcc = 'K2300';
UPDATE tiger_arealm SET type = 'Shopping Center or Major Retail Center' WHERE mtfcc = 'K2361';
UPDATE tiger_arealm SET type = 'Industrial Building or Industrial Park' WHERE mtfcc = 'K2362';
UPDATE tiger_arealm SET type = 'Office Building or Office Park' WHERE mtfcc = 'K2363';
UPDATE tiger_arealm SET type = 'Farm/Vineyard/Winery/Orchard' WHERE mtfcc = 'K2364';
UPDATE tiger_arealm SET type = 'Other Employment Center' WHERE mtfcc = 'K2366';
UPDATE tiger_arealm SET type = 'Transportation Terminal' WHERE mtfcc = 'K2400';
UPDATE tiger_arealm SET type = 'Marina' WHERE mtfcc = 'K2424';
UPDATE tiger_arealm SET type = 'Pier/Dock' WHERE mtfcc = 'K2432';
UPDATE tiger_arealm SET type = 'Airport or Airfield' WHERE mtfcc = 'K2451';
UPDATE tiger_arealm SET type = 'Train Station, Trolley or Mass Transit Rail Station' WHERE mtfcc = 'K2452';
UPDATE tiger_arealm SET type = 'Bus Terminal' WHERE mtfcc = 'K2453';
UPDATE tiger_arealm SET type = 'Marine Terminal' WHERE mtfcc = 'K2454';
UPDATE tiger_arealm SET type = 'Seaplane Anchorage' WHERE mtfcc = 'K2455';
UPDATE tiger_arealm SET type = 'Airport-Intermodal Transportation Hub/Terminal' WHERE mtfcc = 'K2456';
UPDATE tiger_arealm SET type = 'Airport-Statistical Representation' WHERE mtfcc = 'K2457';
UPDATE tiger_arealm SET type = 'Park and Ride Facility/Parking Lot' WHERE mtfcc = 'K2458';
UPDATE tiger_arealm SET type = 'Runway/Taxiway' WHERE mtfcc = 'K2459';
UPDATE tiger_arealm SET type = 'Helicopter Landing Pad' WHERE mtfcc = 'K2460';
UPDATE tiger_arealm SET type = 'University or College' WHERE mtfcc = 'K2540';
UPDATE tiger_arealm SET type = 'School or Academy' WHERE mtfcc = 'K2543';
UPDATE tiger_arealm SET type = 'Museum, Visitor Center, Cultural Center, or Tourist Attraction' WHERE mtfcc = 'K2545';
UPDATE tiger_arealm SET type = 'Golf Course' WHERE mtfcc = 'K2561';
UPDATE tiger_arealm SET type = 'Amusement Center' WHERE mtfcc = 'K2564';
UPDATE tiger_arealm SET type = 'Cemetery' WHERE mtfcc = 'K2582';
UPDATE tiger_arealm SET type = 'Zoo' WHERE mtfcc = 'K2586';
UPDATE tiger_arealm SET type = 'Place of Worship' WHERE mtfcc = 'K3544';






--tiger_areawater add type
ALTER TABLE tiger_areawater ADD column type text;
CREATE INDEX tiger_areawater_mtfcc_idx ON tiger_areawater USING btree(mtfcc);
UPDATE tiger_areawater SET type = 'Connector' WHERE mtfcc = 'H1100';
UPDATE tiger_areawater SET type = 'Swamp/Marsh' WHERE mtfcc = 'H2025';
UPDATE tiger_areawater SET type = 'Lake/Pond' WHERE mtfcc = 'H2030';
UPDATE tiger_areawater SET type = 'Reservoir' WHERE mtfcc = 'H2040';
UPDATE tiger_areawater SET type = 'Treatment Pond' WHERE mtfcc = 'H2041';
UPDATE tiger_areawater SET type = 'Bay/Estuary/Gulf/Sound' WHERE mtfcc = 'H2051';
UPDATE tiger_areawater SET type = 'Ocean/Sea' WHERE mtfcc = 'H2053';
UPDATE tiger_areawater SET type = 'Gravel Pit/Quarry filled with water' WHERE mtfcc = 'H2060';
UPDATE tiger_areawater SET type = 'Glacier' WHERE mtfcc = 'H2081';
UPDATE tiger_areawater SET type = 'Stream/River' WHERE mtfcc = 'H3010';
UPDATE tiger_areawater SET type = 'Braided Stream' WHERE mtfcc = 'H3013';
UPDATE tiger_areawater SET type = 'Canal, Ditch or Aqueduct' WHERE mtfcc = 'H3020';



--tiger_roads
ALTER TABLE tiger_roads ADD column type text;
CREATE INDEX tiger_roads_mtfcc_idx ON tiger_roads USING btree(mtfcc);
UPDATE tiger_roads SET type = 'Primary Road' WHERE mtfcc = 'S1100';
UPDATE tiger_roads SET type = 'Secondary Road' WHERE mtfcc = 'S1200';
UPDATE tiger_roads SET type = 'Local Neighborhood Road, Rural Road, City Street' WHERE mtfcc = 'S1400';
UPDATE tiger_roads SET type = 'Vehicular Trail (4WD)' WHERE mtfcc = 'S1500';
UPDATE tiger_roads SET type = 'Ramp' WHERE mtfcc = 'S1630';
UPDATE tiger_roads SET type = 'Service Drive usually along a limited access highway' WHERE mtfcc = 'S1640';
UPDATE tiger_roads SET type = 'Walkway/Pedestrian Trail' WHERE mtfcc = 'S1710';
UPDATE tiger_roads SET type = 'Stairway' WHERE mtfcc = 'S1720';
UPDATE tiger_roads SET type = 'Alley' WHERE mtfcc = 'S1730';
UPDATE tiger_roads SET type = 'Private Road for service vehicles (logging, oil fields, ranches, etc.)' WHERE mtfcc = 'S1740';
UPDATE tiger_roads SET type = 'Parking Lot Road' WHERE mtfcc = 'S1780';
UPDATE tiger_roads SET type = 'Bike Path or Trail' WHERE mtfcc = 'S1820';
UPDATE tiger_roads SET type = 'Bridle Path' WHERE mtfcc = 'S1830';
UPDATE tiger_roads SET type = 'Road Median' WHERE mtfcc = 'S2000';




--View
DROP VIEW tiger;
CREATE MATERIALIZED VIEW tiger AS 
    SELECT 
        uid, fullname AS name, gadm2 AS stateprovince, type, 'tiger' AS data_source, the_geom 
    FROM 
        tiger_arealm 
    UNION 
    SELECT 
        uid, fullname AS name, gadm2 AS stateprovince, type, 'tiger' AS data_source, the_geom
    FROM 
        tiger_areawater 
    UNION 
    SELECT 
        uid, namelsad AS name, gadm2 AS stateprovince, type, 'tiger' AS data_source, the_geom 
    FROM 
        tiger_counties 
    UNION 
    SELECT 
        uid, fullname AS name, gadm2 AS stateprovince, type, 'tiger' AS data_source, the_geom 
    FROM 
        tiger_roads;
CREATE INDEX tiger_v_uid_idx ON tiger USING BTREE(uid);
CREATE INDEX tiger_v_name_idx ON tiger USING gin (name gin_trgm_ops);
CREATE INDEX tiger_v_gadm2_idx ON tiger USING gin (gadm2 gin_trgm_ops);
CREATE INDEX tiger_v_type_idx ON tiger USING BTREE(type);
CREATE INDEX tiger_v_geom_idx ON tiger USING GIST(the_geom);

