local _, core = ...

core.isClassicEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC;
core.isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE;
core.hasAuraContainer = C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate") ~= nil;

local classicPurgeSpellIDs = {
    527,  -- priest: dispel magic
    370,  -- shaman: purge (rank 1)
    8012, -- shaman: purge (rank 2)
};

local classicPetPurgeSpellIDs = {
    19505, -- warlock felhunter: devour magic (rank 1)
    19731, -- rank 2
    19734, -- rank 3
    19736, -- rank 4
};

local retailPurgeSpellIDs = {
    528,    -- dispel magic
    370,    -- purge
    30449,  -- spellsteal
    378438, -- scouring flame
};

function core:CheckKnowsPurge()
    if core.isClassicEra then
        for _, spellID in ipairs(classicPurgeSpellIDs) do
            if C_SpellBook.IsSpellKnown(spellID) then
                return true;
            end
        end
        for _, spellID in ipairs(classicPetPurgeSpellIDs) do
            if C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Pet) then
                return true;
            end
        end
        return false;
    else
        for _, spellID in ipairs(retailPurgeSpellIDs) do
            if C_SpellBook.IsSpellKnown(spellID) then
                return true;
            end
        end
        return false;
    end
end

function core:SafeRegisterEvent(frame, event, unit)
    if unit then
        return pcall(frame.RegisterUnitEvent, frame, event, unit);
    end
    return pcall(frame.RegisterEvent, frame, event);
end
