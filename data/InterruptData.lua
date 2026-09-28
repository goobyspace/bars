local _, core = ...;

core.interrupts = {
    retail = {
        [250]  = 47528,  -- Blood (Mind Freeze)
        [251]  = 47528,  -- Frost (Mind Freeze)
        [252]  = 47528,  -- Unholy (Mind Freeze)

        [577]  = 183752, -- Havoc (Consume Magic)
        [581]  = 183752, -- Vengeance (Consume Magic)

        [102]  = 78675,  -- Balance (Solar Beam)
        [103]  = 106839, -- Feral (Skull Bash)
        [104]  = 106839, -- Guardian (Skull Bash)

        [1467] = 351338, -- Devastation (Quell)
        [1468] = 351338, -- Preservation (Healer - No Kick)
        [1469] = 351338, -- Augmentation (Quell)

        [253]  = 147362, -- Beast Mastery (Counter Shot)
        [254]  = 147362, -- Marksmanship (Counter Shot)
        [255]  = 187707, -- Survival (Muzzle)

        [62]   = 2139,   -- Arcane (Counterspell)
        [63]   = 2139,   -- Fire (Counterspell)
        [64]   = 2139,   -- Frost (Counterspell)

        [268]  = 116705, -- Brewmaster (Spear Hand Strike)
        [269]  = 116705, -- Windwalker (Spear Hand Strike)

        [66]   = 96231,  -- Protection (Rebuke)
        [70]   = 96231,  -- Retribution (Rebuke)

        [256]  = 32379,  -- Discipline (Death)
        [257]  = 32379,  -- Holy (Death)
        [258]  = 15487,  -- Shadow (Silence)

        [259]  = 1766,   -- Assassination (Kick)
        [260]  = 1766,   -- Outlaw (Kick)
        [261]  = 1766,   -- Subtlety (Kick)

        [262]  = 57994,  -- Elemental (Wind Shear)
        [263]  = 57994,  -- Enhancement (Wind Shear)
        [264]  = 57994,  -- Restoration (Healer exception: has Wind Shear)

        [265]  = 19647,  -- Affliction (Spell Lock)
        [266]  = 19647,  -- Demonology (Spell Lock)
        [267]  = 19647,  -- Destruction (Spell Lock)

        [71]   = 6552,   -- Arms (Pummel)
        [72]   = 6552,   -- Fury (Pummel)
        [73]   = 6552,   -- Protection (Pummel)
    },

    classic = {
        ["ROGUE"] = {
            { spellIDs = { 1769, 1766 } }, -- Kick (rank 2, rank 1)
        },
        ["WARRIOR"] = {
            { spellIDs = { 7355, 7354, 72 }, requiredFormIDs = { 2457, 71 } }, -- Shield Bash, Battle or Defensive Stance
            { spellIDs = { 6554, 6552 },     requiredFormIDs = { 2458 } },     -- Pummel, Berserker Stance
        },
        ["MAGE"] = {
            { spellIDs = { 2139 } }, -- Counterspell
        },
        ["SHAMAN"] = {
            { spellIDs = { 10414, 10413, 10412, 8046, 8045, 8044, 8042 } }, -- Earth Shock (rank 7 to rank 1)
        },
        ["DRUID"] = {
            { spellIDs = { 16979 }, requiredFormIDs = { 5487, 9634 } }, -- Feral Charge, Bear Form
        },
    },

    classicPet = {
        ["WARLOCK"] = { 19647, 19244 }, -- Spell Lock (rank 2, rank 1)
    },
};
