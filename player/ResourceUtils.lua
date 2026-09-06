local _, core = ...

local classicDruidFormKeys = {
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
            return classicDruidFormKeys[spellID] or 0;
        end
    end
    return 0;
end
