local _, core = ...;

if core.isClassicRules then return; end;

-- entries are keyed by class and then by specialization id, each spec gets its own set of icons
-- {
--     name = "Example",
--     slot = 1, -- 1 to 8, left to right
--     spellIDs = { 123 }, -- base spell ids, the last known one is used and overrides (e.g. bloodbath) are followed
--     knownSpellIDs = { 123 }, -- what has to be known for the icon to show, defaults to spellIDs
--     hideIfKnownSpellIDs = { 123 }, -- hides the icon if any of these are known, e.g. whirlwind when thunder clap is
--     iconSpellID = 123, -- fixed spell for the icon and tooltip, skips override lookups
--     auraSpellIDs = { 123 }, -- shows the player's matching buff on top of the icon whilst active
--     rangeCheck = true, -- tints the icon red when the target is out of range
--     spellCooldown = true,
--     usability = true, -- icon is greyed out until the spell is usable
--     usableGlow = true, -- glows whilst usable, or whilst off cooldown if usability isnt set
--     procGlow = true, -- glows whilst the spell has a blizzard proc overlay, e.g. when its cooldown resets
--     auraGlow = true,
--     displayCharges = true, -- shows the buff's stack count
--     displayTextSize = 14,
--     chargesText = true, -- spell charges in the bottom right of the icon
--     chargesTextSize = 10,
-- },

core.retailAuraTracker = {
    WARRIOR = {
        [71] = {}, -- arms
        [72] = {   -- fury
            {
                name = "Bloodthirst",
                slot = 1,
                spellIDs = { 23881 },
                rangeCheck = true,
                spellCooldown = true,
                procGlow = true,
            },
            {
                name = "Execute",
                slot = 2,
                spellIDs = { 5308 },
                usability = true,
                spellCooldown = true,
                usableGlow = true,
                procGlow = true,
            },
            {
                name = "Raging Blow",
                slot = 3,
                spellIDs = { 85288 },
                rangeCheck = true,
                spellCooldown = true,
                procGlow = true,
                chargesText = true,
            },
            {
                name = "Thunder Clap",
                slot = 4,
                spellIDs = { 6343 },
                spellCooldown = true,
                procGlow = true,
            },
            {
                name = "Berserk",
                slot = 5,
                knownSpellIDs = { 1269308 },
                iconSpellID = 1269349,
                auraSpellIDs = { 1269349 },
                auraGlow = true,
                displayCharges = true,
            },
            {
                name = "Odyn's Fury",
                slot = 6,
                spellIDs = { 385059 },
                spellCooldown = true,
                usability = true,
                usableGlow = true,
            },
            {
                name = "Recklessness",
                slot = 7,
                spellIDs = { 1719 },
                auraSpellIDs = { 1719 },
                spellCooldown = true,
                usability = true,
                auraGlow = true,
                usableGlow = true,
            },
            {
                name = "Avatar",
                slot = 8,
                spellIDs = { 107574 },
                auraSpellIDs = { 107574 },
                spellCooldown = true,
                usability = true,
                auraGlow = true,
                usableGlow = true,
            },
        },
        [73] = {}, -- protection
    },
};
