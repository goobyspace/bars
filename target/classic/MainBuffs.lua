local _, core = ...
local colours = core.colours

if core.hasAuraContainer then return end

local knowsPurge = false;
local maxBuffs = 16

local function InitializeButton(button)
    core:InitializeAuraButtonBase(button)

    button.PurgeBorder = button:CreateTexture(nil, "OVERLAY")
    button.PurgeBorder:SetPoint("TOPLEFT")
    button.PurgeBorder:SetPoint("BOTTOMRIGHT")
    button.PurgeBorder:SetColorTexture(colours.white.r, colours.white.g, colours.white.b, colours.white.a)
end

local function UpdateButton(button, auraData)
    core:UpdateAuraCooldown(button, auraData)
    button.PurgeBorder:SetShown(knowsPurge and auraData.isStealable);
end

function core:CreateMainBuffsFrame(parent)
    local frame = CreateFrame("Frame", "TargetMainBuffAuraContainer", parent)
    frame:SetSize(14, 14)

    local container = core:CreateAuraContainer(frame, {
        unit = "target",
        iconSize = 14,
        spacing = 2,
        maxLineSize = 126,
        anchorPoint = "TOPLEFT",
        growX = 1,
        growY = -1,
    })

    container:AddGroup("Buffs", AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Helpful), {
        initializeFrame = InitializeButton,
        updateFrame = UpdateButton,
        maxFrameCount = maxBuffs,
    })

    knowsPurge = core:CheckKnowsPurge();

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("UNIT_PET")
    eventFrame:RegisterUnitEvent("UNIT_AURA", "target")
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_TALENT_UPDATE" or event == "UNIT_PET" then
            knowsPurge = core:CheckKnowsPurge();
        end
        container:Update()
    end)

    return frame
end
