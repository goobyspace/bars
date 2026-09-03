local _, core = ...

if not core.isClassicEra then return end

-- Overwrite everything that doesn't exist
core.resources.primary["DEATHKNIGHT"] = nil;
core.resources.primary["DEMONHUNTER"] = nil;
core.resources.primary["EVOKER"] = nil;
core.resources.primary["HUNTER"] = Enum.PowerType.Mana;
core.resources.primary["MONK"] = nil;
core.resources.primary["PRIEST"] = Enum.PowerType.Mana;
core.resources.primary["SHAMAN"] = Enum.PowerType.Mana;
core.resources.primary["DRUID"] = {
    [0]         = Enum.PowerType.Mana,
    ["BEAR"]    = Enum.PowerType.Rage,
    ["CAT"]     = Enum.PowerType.Energy,
    ["TRAVEL"]  = Enum.PowerType.Mana,
    ["AQUATIC"] = Enum.PowerType.Mana,
    ["MOONKIN"] = Enum.PowerType.Mana,
};

core.resources.secondary["DEATHKNIGHT"] = nil;
core.resources.secondary["DEMONHUNTER"] = nil;
core.resources.secondary["EVOKER"] = nil;
core.resources.secondary["MONK"] = nil;
core.resources.secondary["PALADIN"] = nil;
core.resources.secondary["SHAMAN"] = nil;
core.resources.secondary["WARLOCK"] = nil;
core.resources.secondary["WARRIOR"] = nil;
core.resources.secondary["DRUID"] = {
    ["CAT"] = Enum.PowerType.ComboPoints,
};

core.resources.tertiary = {};
