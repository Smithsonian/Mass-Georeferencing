--bhl_creator
CREATE TABLE bhl_creator (
    titleid text,
    creatorid text,
    creatortype text,
    creatorname text,
    creationdate text
);
\COPY bhl_creator FROM 'Data/creator.txt' DELIMITER E'\t';
CREATE INDEX bhl_creator_titleid_idx ON bhl_creator USING BTREE(titleid);
CREATE INDEX bhl_creator_creatorid_idx ON bhl_creator USING BTREE(creatorid);


--bhl_doi
CREATE TABLE bhl_doi (
    entitytype text,
    entityid text,
    doi text,
    creationdate text
);
\COPY bhl_doi FROM 'Data/doi.txt';
CREATE INDEX bhl_doi_entityid_idx ON bhl_doi USING BTREE(entityid);


--bhl_item
CREATE TABLE bhl_item (
    ﻿itemid text,
    titleid text,
    thumbnailpageid text,
    barcode text,
    marcitemid text,
    callnumber text,
    volumeinfo text,
    itemurl text,
    itemtexturl text,
    itempdfurl text,
    itemimagesurl text,
    localid text,
    year text,
    institutionname text,
    zquery text,
    creationdate text
);
\COPY bhl_item FROM 'Data/item.txt';
CREATE INDEX bhl_item_itemid_idx ON bhl_item USING BTREE(﻿itemid);
CREATE INDEX bhl_item_titleid_idx ON bhl_item USING BTREE(titleid);
CREATE INDEX bhl_item_thumbnailpageid_idx ON bhl_item USING BTREE(thumbnailpageid);


--bhl_page
CREATE TABLE bhl_page (
    pageid text,
    itemid text,
    sequenceorder text,
    year text,
    volume text,
    issue text,
    pageprefix text,
    pagenumber text,
    pagetypename text,
    creationdate text
);
\COPY bhl_page FROM 'Data/page.txt';
CREATE INDEX bhl_page_pageid_idx ON bhl_page USING BTREE(pageid);
CREATE INDEX bhl_page_itemid_idx ON bhl_page USING BTREE(itemid);


--bhl_pagename
CREATE TABLE bhl_pagename (
    ﻿namebankid text,
    nameconfirmed text,
    pageid text,
    creationdate text
);
\COPY bhl_pagename FROM 'Data/pagename.txt';
CREATE INDEX bhl_pagename_namebankid_idx ON bhl_pagename USING BTREE(﻿namebankid);
CREATE INDEX bhl_pagename_pageid_idx ON bhl_pagename USING BTREE(pageid);


--bhl_part
CREATE TABLE bhl_part (
    ﻿partid text,
    itemid text,
    contributorname text,
    sequenceorder text,
    segmenttype text,
    title text,
    containertitle text,
    publicationdetails text,
    volume text,
    series text,
    issue text,
    date text,
    pagerange text,
    startpageid text,
    languagename text,
    segmenturl text,
    externalurl text,
    downloadurl text,
    rightsstatus text,
    rightsstatement text,
    licensename text,
    licenseurl text
);
\COPY bhl_part FROM 'Data/part.txt';
CREATE INDEX bhl_part_partid_idx ON bhl_part USING BTREE(﻿partid);
CREATE INDEX bhl_part_itemid_idx ON bhl_part USING BTREE(itemid);


--bhl_partcreator
CREATE TABLE bhl_partcreator (
    ﻿partid text,
    creatorid text,
    creatorname text,
    creationdate text
);
\COPY bhl_partcreator FROM 'partcreator.txt';
CREATE INDEX bhl_partcreator_partid_idx ON bhl_partcreator USING BTREE(﻿partid);
CREATE INDEX bhl_partcreator_creatorid_idx ON bhl_partcreator USING BTREE(creatorid);


--bhl_subject
CREATE TABLE bhl_subject (
    titleid text,
    subject text,
    creationdate text
);
\COPY bhl_subject FROM 'Data/subject.txt';
CREATE INDEX bhl_subject_titleid_idx ON bhl_subject USING BTREE(titleid);


--bhl_title
CREATE TABLE bhl_title (
    titleid text,
    marcbibid text,
    marcleader text,
    fulltitle text,
    shorttitle text,
    publicationdetails text,
    callnumber text,
    startyear text,
    endyear text,
    languagecode text,
    tl2author text,
    titleurl text,
    creationdate text
);
\COPY bhl_title FROM 'Data/title.txt';
CREATE INDEX bhl_title_titleid_idx ON bhl_title USING BTREE(titleid);
CREATE INDEX bhl_title_marcbibid_idx ON bhl_title USING BTREE(marcbibid);


--bhl_titleidentifier
CREATE TABLE bhl_titleidentifier (
    titleid text,
    identifiername text,
    identifiervalue text,
    creationdate text
);
\COPY bhl_titleidentifier FROM 'Data/titleidentifier.txt';
CREATE INDEX bhl_titleidentifier_titleid_idx ON bhl_titleidentifier USING BTREE(titleid);
