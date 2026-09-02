local _, core = ...

local frame = nil;

local PURGE_SPELL_IDS = {
    528,    -- dispel magic
    370,    -- purge
    30449,  -- spellsteal
    378438, -- scouring flame
};

local buffButtons = {};
local knowsPurge = false;

local function CheckKnowsPurge()
    for _, spellID in ipairs(PURGE_SPELL_IDS) do
        if C_SpellBook.IsSpellKnown(spellID) then
            return true;
        end
    end
    return false;
end

local function ApplyPurgeBorder(button)
    if knowsPurge then
        if not button.purgeBorderIndex then
            button.purgeBorderIndex = button:AddDispelTypeTexture(button.PurgeBorder, {
                style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
                showWhenHelpful = true,
                showWhenHarmful = false,
                showWithoutDispelType = true,
                stealableFilter = Enum.CustomAuraButtonDispelTypeStealableFilter.Stealable,
            });
        end
    elseif button.purgeBorderIndex then
        button:RemoveDispelTypeTexture(button.purgeBorderIndex);
        button.purgeBorderIndex = nil;
    end
end

local function UpdateKnowsPurge()
    local updated = CheckKnowsPurge();
    if updated ~= knowsPurge then
        knowsPurge = updated;
        for _, button in ipairs(buffButtons) do
            ApplyPurgeBorder(button);
        end
    end
end

local MAX_BUFFS = 16

function core:CreateMainBuffsFrame(parent)
    frame = CreateFrame("AuraContainer", "TargetMainBuffAuraContainer", parent, "CustomAuraContainerTemplate")
    frame:SetSize(14, 14)
    frame:SetUnit("target")
    frame:SetFlowLayoutMaximumLineSize(126)

    local function initializeFrame(button)
        local icon = button:CreateTexture(nil, "OVERLAY")
        icon:SetAllPoints()
        button:SetIcon(icon)
        button:SetSize(14, 14)

        local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        cooldown:SetAllPoints()
        cooldown:SetHideCountdownNumbers(true)
        button:SetDurationCooldown(cooldown)

        button.PurgeBorder = button:CreateTexture(nil, "OVERLAY")
        button.PurgeBorder:SetPoint("TOPLEFT")
        button.PurgeBorder:SetPoint("BOTTOMRIGHT")
        button.PurgeBorder:SetColorTexture(1, 1, 1, 1)

        table.insert(buffButtons, button)
        ApplyPurgeBorder(button)
    end

    -- this gives an unknown error i think its the vscode thing being out of date but idk man i copied this code
    frame:SetAuraProcessingPolicy(CustomAuraContainerAuraProcessingPolicy.ProcessAura, { ignoreDebuffs = true })

    frame:AddAuraGroup("Buffs", AuraUtil.AuraFilters.Helpful, {
        initializeFrame = initializeFrame,
        sortMethod = AuraContainerSortMethod.Default,
        maxFrameCount = MAX_BUFFS,
        layout = { elementSpacing = 2 },
    })

    knowsPurge = CheckKnowsPurge();

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterUnitEvent("UNIT_AURA", "target")
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_TALENT_UPDATE" or event == "TRAIT_CONFIG_UPDATED" then
            UpdateKnowsPurge()
        else
            frame:UpdateAllAuras()
        end
    end)

    return frame
end
