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
--     chargeCooldown = true, -- edge-only cooldown for the charge recharge, needs spellCooldown
--     usability = true, -- icon is greyed out until the spell is usable
--     usableGlow = true, -- glows whilst usable, or whilst off cooldown and in combat if usability isnt set
--     procGlow = true, -- glows whilst the spell has a blizzard proc overlay, e.g. when its cooldown resets
--     auraGlow = true,
--     keepSpellIcon = true, -- the aura only adds its stack text and glow on top, the spell icon stays as is
--     maxStacksGlow = 20, -- glows once the buff reaches this many stacks, works in combat
--     displayCharges = true, -- shows the buff's stack count
--     displayTextSize = 14,
--     chargesText = true, -- spell charges in the bottom right of the icon
--     chargesTextSize = 10,
--     castCountText = true, -- shows the spell's cast count instead of its charges, needs chargesText
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
                auraGlow = true,
                usableGlow = true,
            },
            {
                name = "Avatar",
                slot = 8,
                spellIDs = { 107574 },
                auraSpellIDs = { 107574 },
                spellCooldown = true,
                auraGlow = true,
                usableGlow = true,
            },
        },
        [73] = {}, -- protection
    },
    MONK = {
        [268] = {}, -- brewmaster
        [270] = {   -- mistweaver
            {
                name = "Thunder Focus Tea",
                slot = 1,
                spellIDs = { 116680 },
                auraSpellIDs = { 116680 },
                spellCooldown = true,
                chargeCooldown = true,
                auraGlow = true,
                displayCharges = true,
                chargesText = true,
            },
            {
                name = "Rising Sun Kick",
                slot = 2,
                spellIDs = { 107428 },
                rangeCheck = true,
                spellCooldown = true,
                procGlow = true,
                usableGlow = true,
            },
            {
                name = "Blackout Kick",
                slot = 3,
                spellIDs = { 100784 },
                rangeCheck = true,
                spellCooldown = true,
            },
            {
                name = "Vivify",
                slot = 4,
                spellIDs = { 116670 },
                auraSpellIDs = { 392883 }, -- vivacious vivification
                spellCooldown = true,
                auraGlow = true,
                chargesText = true,
                castCountText = true, -- renewing mists up
                chargesTextSize = 12,
            },
            {
                name = "Dance of Chi-Ji",
                slot = 5,
                knownSpellIDs = { 438439 },
                iconSpellID = 438443,
                auraSpellIDs = { 438443 },
                auraGlow = true,
            },
            {
                name = "Mana Tea",
                slot = 6,
                knownSpellIDs = { 115294 },
                iconSpellID = 115294,
                auraSpellIDs = { 115867 },
                keepSpellIcon = true,
                maxStacksGlow = 20,
                displayCharges = true,
            },
            {
                name = "Dance of the Wind",
                slot = 7,
                knownSpellIDs = { 432181 },
                iconSpellID = 432180,
                auraSpellIDs = { 432180 },
                displayCharges = true,
            },
            {
                name = "Spiritfont",
                slot = 8,
                knownSpellIDs = { 1260511 },
                iconSpellID = 1260565,
                displayCharges = true,
                auraSpellIDs = { 1260565, 1260670 },
            },
        },
        [269] = {}, -- windwalker
    },
    EVOKER = {
        [1467] = {}, -- devastation
        [1468] = {   -- preservation
            {
                name = "Essence Burst",
                slot = 1,
                knownSpellIDs = { 369297 },
                iconSpellID = 369299,
                auraSpellIDs = { 369299 },
                auraGlow = true,
                displayCharges = true,
            },
            {
                name = "Lifespark",
                slot = 2,
                knownSpellIDs = { 443177 },
                iconSpellID = 443176,
                auraSpellIDs = { 443176 },
                auraGlow = true,
                displayCharges = true,
            },
            {
                name = "Lifebind",
                slot = 3,
                knownSpellIDs = { 373270 },
                iconSpellID = 373267,
                auraSpellIDs = { 373267 },
            },
            {
                name = "Temporal Compression",
                slot = 4,
                knownSpellIDs = { 362874 },
                iconSpellID = 362877,
                auraSpellIDs = { 362877 },
                displayCharges = true,
            },
            {
                name = "Merithra's Blessing",
                slot = 5,
                knownSpellIDs = { 1256577 },
                iconSpellID = 1256579,
                auraSpellIDs = { 1256579 },
            },
            {
                name = "Hover",
                slot = 6,
                knownSpellIDs = { 358267 },
                iconSpellID = 358267,
                auraSpellIDs = { 358267 },
            },
            {
                name = "Stasis",
                slot = 7,
                knownSpellIDs = { 370537 },
                iconSpellID = 370537,
                auraSpellIDs = { 370537, 370562 }, -- stacks count down, then the ready buff takes over
                displayCharges = true,
            },
            {
                name = "Obsidian Scales",
                slot = 8,
                knownSpellIDs = { 363916 },
                iconSpellID = 363916,
                auraSpellIDs = { 363916 },
            },
        },
        [1473] = {}, -- augmentation
    },
};
