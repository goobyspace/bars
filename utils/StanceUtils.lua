local _, core = ...;

local classicFormKeys = {
    [5487]  = "BEAR",      -- Bear Form
    [9634]  = "BEAR",      -- Dire Bear Form
    [1066]  = "AQUATIC",   -- Aquatic Form
    [768]   = "CAT",       -- Cat Form
    [783]   = "TRAVEL",    -- Travel Form
    [24858] = "MOONKIN",   -- Moonkin Form
    [2457]  = "BATTLE",    -- Battle Stance
    [71]    = "DEFENSIVE", -- Defensive Stance
    [2458]  = "BERSERKER", -- Berserker Stance
};

function core:GetActiveStanceID()
    if not core.isClassicRules then
        return GetShapeshiftFormID() or 0;
    end;

    for i = 1, GetNumShapeshiftForms() do
        local _, isActive, _, spellID = GetShapeshiftFormInfo(i);
        if isActive then
            return spellID;
        end;
    end;
    return 0;
end;

function core:GetShapeshiftFormKey()
    if not core.isClassicRules then
        return core:GetActiveStanceID();
    end;

    return classicFormKeys[core:GetActiveStanceID()] or 0;
end;
