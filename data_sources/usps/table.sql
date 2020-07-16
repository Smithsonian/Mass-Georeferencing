create table us_state_abbreviations 
    (
        state text, 
        yr_from int, 
        yr_to int, 
        abbreviation text
    ); 

create index us_state_abbreviations_st_idx on us_state_abbreviations USING BTREE(state);
create index us_state_abbreviations_fr_idx on us_state_abbreviations USING BTREE(yr_from);
create index us_state_abbreviations_to_idx on us_state_abbreviations USING BTREE(yr_to);
