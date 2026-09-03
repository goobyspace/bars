local _, core = ...

if core.isClassicEra then return end

function core:GetPlayerInterruptSpellID()
    local specIndex = GetSpecialization()
    if not specIndex then return nil end

    local specID = GetSpecializationInfo(specIndex)
    if not specID then return nil end

    local specInterrupts = {
        -- DEATH KNIGHT
        [250]  = 47528, -- Blood (Mind Freeze)
        [251]  = 47528, -- Frost (Mind Freeze)
        [252]  = 47528, -- Unholy (Mind Freeze)

        -- DEMON HUNTER
        [577]  = 183752, -- Havoc (Consume Magic)
        [581]  = 183752, -- Vengeance (Consume Magic)

        -- DRUID
        [102]  = 78675,  -- Balance (Solar Beam)
        [103]  = 106839, -- Feral (Skull Bash)
        [104]  = 106839, -- Guardian (Skull Bash)
        [105]  = nil,    -- Restoration :(

        -- EVOKER
        [1467] = 351338, -- Devastation (Quell)
        [1468] = 351338, -- Preservation (Healer - No Kick)
        [1469] = 351338, -- Augmentation (Quell)

        -- HUNTER
        [253]  = 147362, -- Beast Mastery (Counter Shot)
        [254]  = 147362, -- Marksmanship (Counter Shot)
        [255]  = 187707, -- Survival (Muzzle)

        -- MAGE
        [62]   = 2139, -- Arcane (Counterspell)
        [63]   = 2139, -- Fire (Counterspell)
        [64]   = 2139, -- Frost (Counterspell)

        -- MONK
        [268]  = 116705, -- Brewmaster (Spear Hand Strike)
        [270]  = nil,    -- Mistweaver :(
        [269]  = 116705, -- Windwalker (Spear Hand Strike)

        -- PALADIN
        [65]   = nil,   -- Holy :(
        [66]   = 96231, -- Protection (Rebuke)
        [70]   = 96231, -- Retribution (Rebuke)

        -- PRIEST
        -- added death for priest since this info is basically the same as knowing if you can kick or not in pvp
        -- its not too important on a lightning bolt or smth but nice on a poly cast
        [256]  = 32379, -- Discipline (Death)
        [257]  = 32379, -- Holy (Death)
        [258]  = 15487, -- Shadow (Silence)

        -- ROGUE
        [259]  = 1766, -- Assassination (Kick)
        [260]  = 1766, -- Outlaw (Kick)
        [261]  = 1766, -- Subtlety (Kick)

        -- SHAMAN
        [262]  = 57994, -- Elemental (Wind Shear)
        [263]  = 57994, -- Enhancement (Wind Shear)
        [264]  = 57994, -- Restoration (Healer EXCEPTION - Has Wind Shear!)

        -- WARLOCK
        [265]  = 19647, -- Affliction (Spell Lock)
        [266]  = 19647, -- Demonology (Spell Lock)
        [267]  = 19647, -- Destruction (Spell Lock)

        -- WARRIOR
        [71]   = 6552, -- Arms (Pummel)
        [72]   = 6552, -- Fury (Pummel)
        [73]   = 6552, -- Protection (Pummel)
    }

    return specInterrupts[specID]
end
