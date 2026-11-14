local _, core = ...;

if not core.isForever then return; end;

-- icons only show while on cooldown, packed from the left in list order
-- {
--     spell = 22812, -- spell ID or spell name in the client's locale
--     spell = { 8921, 8924, 8925 }, -- list of ranks, tracks the highest one you know
--     item = 5512, -- item ID, use instead of spell
--     slot = "TRINKET1", -- equipped item in a gear slot, no ID needed. HEAD NECK SHOULDER BODY CHEST WAIST LEGS
--                        -- FEET WRIST HANDS FINGER1 FINGER2 TRINKET1 TRINKET2 BACK MAINHAND OFFHAND RANGED,
--                        -- or the numeric slot ID
--     displayText = false, -- hide the countdown numbers
-- },

-- spells that show while you lack the resource (mana, rage, energy) to cast them
-- spell entries only, same format as above, shown after the cooldown icons
-- a spell name or any rank's ID automatically tracks its highest learned rank
core.foreverResourceTracker = {
    ALL = {},
    DRUID = {
        { spell = "Wrath" },
        { spell = "Insect Swarm" },
        { spell = "Starfire" },
        { spell = "Moonfire" },
        { spell = "Hurricane" },
    },
};

-- keyed by class token, ALL applies to every class
core.foreverCooldownTracker = {
    ALL = {
        { item = 6149 }, -- Greater Mana Potion
        { slot = "TRINKET1" },
        { slot = "TRINKET2" },
        { slot = "HEAD" },
        { slot = "NECK" },
        { slot = "SHOULDER" },
        { slot = "BACK" },
        { slot = "CHEST" },
        { slot = "WRIST" },
        { slot = "HANDS" },
        { slot = "WAIST" },
        { slot = "LEGS" },
        { slot = "FEET" },
        { slot = "FINGER1" },
        { slot = "FINGER2" },
        { slot = "MAINHAND" },
        { slot = "OFFHAND" },
        { slot = "RANGED" },
        -- racials
        { spell = 1259799 },
        { spell = 20580 },
    },
    DRUID = {
        { spell = 22812 }, -- Barkskin
        { spell = 29166 }, -- Innervate
        { spell = 20742 },
        { spell = 8918 },
        { spell = 5211 },
        { spell = 1850 },
        { spell = 5229 },
        { spell = 6795 },
        { spell = 16812 },
        { spell = 5215 },
    },
};
