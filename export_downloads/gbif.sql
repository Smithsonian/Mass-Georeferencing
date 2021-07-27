
select 
    g.decimallongitude as decimallongitude,
    g.decimallatitude as decimallatitude,
    g.gbifid,
    msc.data_source,
    mo.mg_occurrenceid, 
    mo.occurrenceid, 
    mo.gbifid, 
    mo.datasetid, 
    mo.datasetname, 
    mo.basisofrecord, 
    mo.eventdate, 
    mo.eventtime, 
    mo.highergeography, 
    mo.stateprovince, 
    mo.county, 
    mo.locality, 
    mo.hasgeospatialissues, 
    mo.species, 
    mo.acceptedscientificname, 
    mo.recordedby, 
    mo.countrycode
from 
    mg_selected_candidates msc,
    mg_candidates mc,
    gbif g,
    mg_records mr,
    mg_occurrences mo
WHERE 
    msc.candidate_id = mc.candidate_id AND
    msc.collex_id = 'db686d34-f1c8-4b22-846c-a39a12d2f075' AND
    msc.recgroup_id = mr.recgroup_id AND
    msc.data_source = 'gbif' AND
    g.species = 'Dipsosaurus dorsalis' AND
    mc.feature_id = g.gbifid AND
    mr.mg_occurrenceid = mo.mg_occurrenceid
;
