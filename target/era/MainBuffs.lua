local _, core = ...;
local colours = core.colours;

if core.hasAuraContainer then return; end;

local knowsPurge = false;
local maxBuffs = 16;

local function initializeButton(button)
    core:InitializeAuraButtonBase(button);

    button.BlackBorder = button:CreateTexture(nil, "BORDER");
    button.BlackBorder:SetDrawLayer("BORDER", 1);
    core:SetPixelPoint(button.BlackBorder, "TOPLEFT", button, "TOPLEFT", -core.pixel, core.pixel);
    core:SetPixelPoint(button.BlackBorder, "BOTTOMRIGHT", button, "BOTTOMRIGHT", core.pixel, -core.pixel);
    button.BlackBorder:SetColorTexture(0, 0, 0, 1);

    button.PurgeBorder = button:CreateTexture(nil, "OVERLAY");
    button.PurgeBorder:SetDrawLayer("OVERLAY", 7);
    button.PurgeBorder:SetPoint("TOPLEFT");
    button.PurgeBorder:SetPoint("BOTTOMRIGHT");
    button.PurgeBorder:SetColorTexture(colours.white.r, colours.white.g, colours.white.b, colours.white.a);
end;

local function updateButton(button, auraData)
    core:UpdateAuraCooldown(button, auraData);
    button.PurgeBorder:SetShown(knowsPurge and auraData.isStealable);
end;

function core:CreateMainBuffsFrame(parent)
    local frame = CreateFrame("Frame", "TargetMainBuffAuraContainer", parent);
    core:SetPixelSize(frame, 14, 14);

    local container = core:CreateAuraContainer(frame, {
        unit = "target",
        iconSize = 16,
        spacing = 2,
        maxLineSize = 126,
        anchorPoint = "TOPLEFT",
        growX = 1,
        growY = -1,
    });

    container:AddGroup("Buffs", AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Helpful), {
        initializeFrame = initializeButton,
        updateFrame = updateButton,
        maxFrameCount = maxBuffs,
    });

    knowsPurge = core:CheckKnowsPurge();

    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE");
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
    eventFrame:RegisterEvent("UNIT_PET");
    eventFrame:RegisterUnitEvent("UNIT_AURA", "target");
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_TALENT_UPDATE" or event == "UNIT_PET" then
            knowsPurge = core:CheckKnowsPurge();
        end;
        container:Update();
    end);

    return frame;
end;
