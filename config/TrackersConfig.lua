local _, core = ...;

-- separate right-hand row, using the entry format from each client's AuraTrackerConfig.lua
-- slots start at 1 and grow rightwards with no eight-slot limit
-- retail entries are keyed by class then specialization id, era and forever by class
core.trackers = {
    -- shared reminders follow the client-specific slots and match active buff names, not spell ids
    reminders = {
        {
            auraName = "Well Fed",
            icon = "Interface\\Icons\\INV_Misc_Food_15",
        },
    },
    retail = {},
    era = {},
    forever = {},
};
