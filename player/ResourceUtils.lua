local _, core = ...

-- ResourceUtils loads first, so these are set early enough for every other file to read them
core.isClassicEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC;
core.hasAuraContainer = C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate") ~= nil;

-- these form-ID globals don't exist on Classic Era; fall back to unique sentinels so the table
-- literals below never get a nil key (which would hard-error and abort this whole file)
local DRUID_BEAR_FORM = DRUID_BEAR_FORM or -1;
local DRUID_TREE_FORM = DRUID_TREE_FORM or -2;
local DRUID_CAT_FORM = DRUID_CAT_FORM or -3;
local DRUID_TRAVEL_FORM = DRUID_TRAVEL_FORM or -4;
local DRUID_ACQUATIC_FORM = DRUID_ACQUATIC_FORM or -5;
local DRUID_FLIGHT_FORM = DRUID_FLIGHT_FORM or -6;
local DRUID_MOONKIN_FORM_1 = DRUID_MOONKIN_FORM_1 or -7;
local DRUID_MOONKIN_FORM_2 = DRUID_MOONKIN_FORM_2 or -8;

-- Classic Era's GetShapeshiftFormID() is a bar-position index (shifts depending on which forms
-- are known), not a stable ID like retail's DRUID_BEAR_FORM etc., so it can't be used as a table
-- key directly there; resolve the active form by its (stable) spellID instead.
local CLASSIC_DRUID_FORM_KEYS = {
    [5487]  = "BEAR",    -- Bear Form
    [9634]  = "BEAR",    -- Dire Bear Form
    [1066]  = "AQUATIC", -- Aquatic Form
    [768]   = "CAT",     -- Cat Form
    [783]   = "TRAVEL",  -- Travel Form
    [24858] = "MOONKIN", -- Moonkin Form
};

function core:GetShapeshiftFormKey()
    if not core.isClassicEra then
        return GetShapeshiftFormID() or 0;
    end

    for i = 1, GetNumShapeshiftForms() do
        local _, isActive, _, spellID = GetShapeshiftFormInfo(i)
        if isActive then
            return CLASSIC_DRUID_FORM_KEYS[spellID] or 0;
        end
    end
    return 0;
end

-- CLASS_EVENTS tables mix in events that don't exist on every flavor (eg. UNIT_POWER_POINT_CHARGE
-- is retail-only); registering an unknown event throws, so do it defensively instead of assuming
function core:SafeRegisterEvent(frame, event, unit)
    if unit then
        return pcall(frame.RegisterUnitEvent, frame, event, unit);
    end
    return pcall(frame.RegisterEvent, frame, event);
end

core.resources = {}

-- using our own instead of the blizz one
-- because i like having slightly different colours :3
core.resources.resourceColours = {
    [Enum.PowerType.Mana] = { r = 20, g = 90, b = 205 },
    [Enum.PowerType.Rage] = { r = 255, g = 20, b = 60 },
    [Enum.PowerType.Focus] = { r = 255, g = 128, b = 64 },
    [Enum.PowerType.Energy] = { r = 255, g = 255, b = 60 },
    [Enum.PowerType.ComboPoints] = { r = 255, g = 245, b = 105 },
    [Enum.PowerType.Runes] = { r = 120, g = 65, b = 110 },
    [Enum.PowerType.RunicPower] = { r = 0, g = 209, b = 255 },
    [Enum.PowerType.SoulShards] = { r = 220, g = 65, b = 247 },
    [Enum.PowerType.LunarPower] = { r = 77, g = 133, b = 230 },
    [Enum.PowerType.HolyPower] = { r = 242, g = 230, b = 153 },
    [Enum.PowerType.Maelstrom] = { r = 0, g = 128, b = 255 },
    [Enum.PowerType.Insanity] = { r = 102, g = 0, b = 204 },
    [Enum.PowerType.Chi] = { r = 133, g = 255, b = 133 },
    [Enum.PowerType.ArcaneCharges] = { r = 26, g = 26, b = 250 },
    [Enum.PowerType.Fury] = { r = 201, g = 66, b = 253 },
    [Enum.PowerType.Pain] = { r = 201, g = 66, b = 253 },
    [Enum.PowerType.Essence] = { r = 172, g = 80, b = 222 },
    ["SOUL_FRAGMENTS_VENGEANCE"] = { r = 157, g = 98, b = 209 },
    ["SOUL_FRAGMENTS"] = { r = 157, g = 98, b = 209 },
    ["MAELSTROM_WEAPON"] = { r = 70, g = 178, b = 255 },
    ["EBON_MIGHT"] = { r = 239, g = 158, b = 78 },
    ["WHIRLWIND"] = { r = 252, g = 205, b = 53 },
    ["ENRAGE"] = { r = 242, g = 106, b = 33 },
    ["TEACHINGS"] = { r = 255, g = 41, b = 135 },
    ["RENEWING_MIST"] = { r = 2, g = 255, b = 127 },
    ["STAGGER"] = {
        light = { r = 133, g = 255, b = 133 },
        medium = { r = 255, g = 250, b = 184 },
        high = { r = 255, g = 107, b = 107 }
    },
}

core.resources.primary = {
    ["DEATHKNIGHT"] = Enum.PowerType.RunicPower,
    ["DEMONHUNTER"] = Enum.PowerType.Fury,
    ["DRUID"]       = {
        [0]                    = {
            [102] = Enum.PowerType.LunarPower, -- Balance
            [103] = Enum.PowerType.Mana,       -- Feral
            [104] = Enum.PowerType.Mana,       -- Guardian
            [105] = Enum.PowerType.Mana,       -- Restoration
        },
        [DRUID_BEAR_FORM]      = Enum.PowerType.Rage,
        [DRUID_TREE_FORM]      = Enum.PowerType.Mana,
        [36]                   = Enum.PowerType.Mana, -- Tome of the Wilds: Treant Form
        [DRUID_CAT_FORM]       = Enum.PowerType.Energy,
        [DRUID_TRAVEL_FORM]    = Enum.PowerType.Mana,
        [DRUID_ACQUATIC_FORM]  = Enum.PowerType.Mana,
        [DRUID_FLIGHT_FORM]    = Enum.PowerType.Mana,
        [DRUID_MOONKIN_FORM_1] = Enum.PowerType.LunarPower,
        [DRUID_MOONKIN_FORM_2] = Enum.PowerType.LunarPower,
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
        [DRUID_CAT_FORM] = Enum.PowerType.ComboPoints,
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
        [0]                    = {
            [102] = Enum.PowerType.Mana, -- Balance
        },
        [DRUID_MOONKIN_FORM_1] = Enum.PowerType.Mana,
        [DRUID_MOONKIN_FORM_2] = Enum.PowerType.Mana,
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
