local _, core = ...;

core.isClassicEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC;
core.isForever = false;
core.isClassicRules = core.isClassicEra or core.isForever;
core.hasAuraContainer = C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate") ~= nil;

function core:CheckKnowsPurge()
    if core.isClassicRules then
        for _, spellID in ipairs(core.purgeSpellIDs.classic) do
            if C_SpellBook.IsSpellKnown(spellID) then
                return true;
            end;
        end;
        for _, spellID in ipairs(core.purgeSpellIDs.classicPet) do
            if C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Pet) then
                return true;
            end;
        end;
        return false;
    else
        for _, spellID in ipairs(core.purgeSpellIDs.retail) do
            if C_SpellBook.IsSpellKnown(spellID) then
                return true;
            end;
        end;
        return false;
    end;
end;

function core:SafeRegisterEvent(frame, event, unit)
    if unit then
        return pcall(frame.RegisterUnitEvent, frame, event, unit);
    end;
    return pcall(frame.RegisterEvent, frame, event);
end;
