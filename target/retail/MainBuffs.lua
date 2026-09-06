---@diagnostic disable: undefined-global

local _, core = ...
local colours = core.colours

if not core.hasAuraContainer then return end

local knowsPurge = false;
local maxBuffs = 16

function core:CreateMainBuffsFrame(parent)
    local buffButtons = {};

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
        local updated = core:CheckKnowsPurge();
        if updated ~= knowsPurge then
            knowsPurge = updated;
            for _, button in ipairs(buffButtons) do
                ApplyPurgeBorder(button);
            end
        end
    end

    local frame = CreateFrame("AuraContainer", "TargetMainBuffAuraContainer", parent, "CustomAuraContainerTemplate")
    frame:SetSize(14, 14)
    frame:SetUnit("target")
    frame:SetFlowLayoutMaximumLineSize(126)

    local function initializeFrame(button)
        core:InitializeAuraButtonBase(button, 14)

        button.PurgeBorder = button:CreateTexture(nil, "OVERLAY")
        button.PurgeBorder:SetPoint("TOPLEFT")
        button.PurgeBorder:SetPoint("BOTTOMRIGHT")
        button.PurgeBorder:SetColorTexture(colours.white.r, colours.white.g, colours.white.b, colours.white.a)

        table.insert(buffButtons, button)
        ApplyPurgeBorder(button)
    end

    local auraProcessingPolicy = 1
    local defaultSortMethod = 1

    frame:SetAuraProcessingPolicy(auraProcessingPolicy, { ignoreDebuffs = true })

    frame:AddAuraGroup("Buffs", AuraUtil.AuraFilters.Helpful, {
        initializeFrame = initializeFrame,
        sortMethod = defaultSortMethod,
        maxFrameCount = maxBuffs,
        layout = { elementSpacing = 2 },
    })

    knowsPurge = core:CheckKnowsPurge();

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
