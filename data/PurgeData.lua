local _, core = ...;

core.purgeSpellIDs = {
    classic = {
        527,  -- priest: dispel magic
        370,  -- shaman: purge (rank 1)
        8012, -- shaman: purge (rank 2)
    },
    classicPet = {
        19505, -- warlock felhunter: devour magic (rank 1)
        19731, -- rank 2
        19734, -- rank 3
        19736, -- rank 4
    },
    retail = {
        528,    -- dispel magic
        370,    -- purge
        30449,  -- spellsteal
        378438, -- scouring flame
    },
};
