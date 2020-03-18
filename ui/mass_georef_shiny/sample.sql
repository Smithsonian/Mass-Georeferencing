--create empty table
create table gbif_si_sample as select * from gbif_si where 1=2;

--plants
insert int gbif_si_sample (select * from gbif_si where species in (SELECT species FROM gbif_si WHERE phylum = 'Tracheophyta' AND species IN (SELECT species FROM gbif_si_matches GROUP BY species) ORDER BY random() LIMIT 100));

--class = 'Aves' AND
insert into gbif_si_sample (select * from gbif_si where species in (SELECT species FROM gbif_si WHERE class = 'Aves' AND species IN (SELECT species FROM gbif_si_matches GROUP BY species) ORDER BY random() LIMIT 100));

--class = 'Mammalia'
insert into gbif_si_sample (select * from gbif_si where species in (SELECT species FROM gbif_si WHERE class = 'Mammalia' AND species IN (SELECT species FROM gbif_si_matches GROUP BY species) ORDER BY random() LIMIT 100));

--class = 'Reptilia'
insert into gbif_si_sample (select * from gbif_si where species in (SELECT species FROM gbif_si WHERE class = 'Reptilia' AND species IN (SELECT species FROM gbif_si_matches GROUP BY species) ORDER BY random() LIMIT 100));

--class = 'Amphibia'
insert into gbif_si_sample (select * from gbif_si where species in (SELECT species FROM gbif_si WHERE class = 'Amphibia' AND species IN (SELECT species FROM gbif_si_matches GROUP BY species) ORDER BY random() LIMIT 100));

--basisofrecord = 'FOSSIL_SPECIMEN' 
--class = 'Malacostraca'
insert into gbif_si_sample (select * from gbif_si where species in (SELECT species FROM gbif_si WHERE basisofrecord = 'FOSSIL_SPECIMEN' AND class = 'Malacostraca' ORDER BY random() LIMIT 100));

--class = 'Echinoidea'
insert into gbif_si_sample (select * from gbif_si where species in (SELECT species FROM gbif_si WHERE basisofrecord = 'FOSSIL_SPECIMEN' AND class = 'Echinoidea' ORDER BY random() LIMIT 100));

--class = 'Bivalvia'
insert into gbif_si_sample (select * from gbif_si where species in (SELECT species FROM gbif_si WHERE basisofrecord = 'FOSSIL_SPECIMEN' AND class = 'Bivalvia' ORDER BY random() LIMIT 100));

--class = 'Gastropoda'
insert into gbif_si_sample (select * from gbif_si where species in (SELECT species FROM gbif_si WHERE basisofrecord = 'FOSSIL_SPECIMEN' AND class = 'Gastropoda' ORDER BY random() LIMIT 100));


--Unionidae
insert into gbif_si_sample (select * from gbif_si where species in (SELECT species FROM gbif_si WHERE family = 'Unionidae' ORDER BY random() LIMIT 100));
