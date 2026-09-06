local _, core = ...

local druidBearForm = DRUID_BEAR_FORM or -1;
local druidTreeForm = DRUID_TREE_FORM or -2;
local druidCatForm = DRUID_CAT_FORM or -3;
local druidTravelForm = DRUID_TRAVEL_FORM or -4;
local druidAcquaticForm = DRUID_ACQUATIC_FORM or -5;
local druidFlightForm = DRUID_FLIGHT_FORM or -6;
local druidMoonkinForm1 = DRUID_MOONKIN_FORM_1 or -7;
local druidMoonkinForm2 = DRUID_MOONKIN_FORM_2 or -8;

core.resources = {}
core.resources.resourceColours = core.colours.resources

core.resources.primary = {
    ["DEATHKNIGHT"] = Enum.PowerType.RunicPower,
    ["DEMONHUNTER"] = Enum.PowerType.Fury,
    ["DRUID"]       = {
        [0]                 = {
            [102] = Enum.PowerType.LunarPower, -- Balance
            [103] = Enum.PowerType.Mana,       -- Feral
            [104] = Enum.PowerType.Mana,       -- Guardian
            [105] = Enum.PowerType.Mana,       -- Restoration
        },
        [druidBearForm]     = Enum.PowerType.Rage,
        [druidTreeForm]     = Enum.PowerType.Mana,
        [36]                = Enum.PowerType.Mana, -- Tome of the Wilds: Treant Form
        [druidCatForm]      = Enum.PowerType.Energy,
        [druidTravelForm]   = Enum.PowerType.Mana,
        [druidAcquaticForm] = Enum.PowerType.Mana,
        [druidFlightForm]   = Enum.PowerType.Mana,
        [druidMoonkinForm1] = Enum.PowerType.LunarPower,
        [druidMoonkinForm2] = Enum.PowerType.LunarPower,
    },
    ["EVOKER"]      = Enum.PowerType.Mana,
    ["HUNTER"]      = Enum.PowerType.Focus,
    ["MAGE"]        = Enum.PowerType.Mana,
    ["MONK"]        = {
        [268] = Enum.PowerType.Energy, -- Brewmaster
        [269] = Enum.PowerType.Energy, -- Windwalker
        [270] = Enum.PowerType.Mana,   -- Mistweaver
    },
    ["PALADIN"]     = Enum.PowerType.Mana,
    ["PRIEST"]      = {
        [256] = Enum.PowerType.Mana,     -- Disciple
        [257] = Enum.PowerType.Mana,     -- Holy,
        [258] = Enum.PowerType.Insanity, -- Shadow,
    },
    ["ROGUE"]       = Enum.PowerType.Energy,
    ["SHAMAN"]      = {
        [262] = Enum.PowerType.Maelstrom, -- Elemental
        [263] = Enum.PowerType.Mana,      -- Enhancement
        [264] = Enum.PowerType.Mana,      -- Restoration
    },
    ["WARLOCK"]     = Enum.PowerType.Mana,
    ["WARRIOR"]     = Enum.PowerType.Rage,
}

core.resources.secondary = {
    ["DEATHKNIGHT"] = Enum.PowerType.Runes,
    ["DEMONHUNTER"] = {
        [581] = "SOUL_FRAGMENTS_VENGEANCE", -- Vengeance
        [1480] = "SOUL_FRAGMENTS",          -- Devourer
    },
    ["DRUID"]       = {
        [druidCatForm] = Enum.PowerType.ComboPoints,
    },
    ["EVOKER"]      = Enum.PowerType.Essence,
    ["HUNTER"]      = nil,
    ["MAGE"]        = nil,
    ["MONK"]        = {
        [268] = "STAGGER",          -- Brewmaster
        [269] = Enum.PowerType.Chi, -- Windwalker
        [270] = "TEACHINGS",        -- Mistweaver
    },
    ["PALADIN"]     = Enum.PowerType.HolyPower,
    ["PRIEST"]      = nil,
    ["ROGUE"]       = Enum.PowerType.ComboPoints,
    ["SHAMAN"]      = {
        [263] = "MAELSTROM_WEAPON", -- Enhancement
    },
    ["WARLOCK"]     = Enum.PowerType.SoulShards,
    ["WARRIOR"]     = {
        [72] = "ENRAGE", -- Fury
    },
}

core.resources.tertiary = {
    ["DEATHKNIGHT"] = nil,
    ["DEMONHUNTER"] = nil,
    ["DRUID"]       = {
        [0]                 = {
            [102] = Enum.PowerType.Mana, -- Balance
        },
        [druidMoonkinForm1] = Enum.PowerType.Mana,
        [druidMoonkinForm2] = Enum.PowerType.Mana,
    },
    ["EVOKER"]      = {
        [1473] = "EBON_MIGHT", -- Augmentation
    },
    ["HUNTER"]      = nil,
    ["MAGE"]        = nil,
    ["MONK"]        = {
        [270] = "RENEWING_MIST", -- Mistweaver
    },
    ["PALADIN"]     = nil,
    ["PRIEST"]      = {
        [258] = Enum.PowerType.Mana, -- Shadow
    },
    ["ROGUE"]       = nil,
    ["SHAMAN"]      = {
        [262] = Enum.PowerType.Mana, -- Elemental
    },
    ["WARLOCK"]     = nil,
    ["WARRIOR"]     = {
        [72] = "WHIRLWIND", -- Fury
    },
}
