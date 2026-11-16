local _, core = ...;

if core.hasAuraContainer then return; end;

local debuffFilterString = AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Harmful,
    AuraUtil.AuraFilters.Player, AuraUtil.AuraFilters.IncludeNameplateOnly);
local crowdControlFilter = AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Harmful, AuraUtil.AuraFilters.CrowdControl);

local maxDebuffs = 8;

local function updateDuration(button)
    local remaining = button.expirationTime and button.expirationTime - GetTime() or 0;
    if remaining > 0 then
        button.durationText:SetText(string.format("%d", math.floor(remaining)));
    else
        button.durationText:SetText("");
    end;
end;

local function initializeButton(button)
    button.borders = core:InitializeTrackedDebuffButton(button);
    local elapsedSinceUpdate = 0;
    button:SetScript("OnUpdate", function(self, elapsed)
        elapsedSinceUpdate = elapsedSinceUpdate + elapsed;
        if elapsedSinceUpdate < 0.1 then return; end;
        elapsedSinceUpdate = 0;
        updateDuration(self);
    end);
end;

local function updateButton(button, auraData)
    core:UpdateAuraCooldown(button, auraData);
    button.expirationTime = auraData.duration and auraData.duration > 0 and auraData.expirationTime or nil;
    updateDuration(button);

    for _, border in ipairs(button.borders) do
        local dispelName = auraData.dispelName;
        if not dispelName or dispelName == "" or dispelName == "None" or dispelName == "Physical" then
            border:SetVertexColor(0, 0, 0, 1);
        else
            AuraUtil.SetAuraBorderColor(border, dispelName);
        end;
    end;
end;

function core:CreateNormalDebuffsFrame(parent)
    local frame = CreateFrame("Frame", "TargetNormalDebuffAuraContainer", parent);
    local layout = core.auraTrackerLayout;
    local spacing = math.max(layout.iconWidth + layout.minIconSpacing,
        (core.width - layout.iconWidth) / (maxDebuffs - 1)) - layout.iconWidth;
    core:SetPixelSize(frame, core.width, layout.iconHeight);

    local container = core:CreateAuraContainer(frame, {
        unit = "target",
        iconSize = layout.iconWidth,
        iconHeight = layout.iconHeight,
        spacing = spacing,
        maxLineSize = core.width + spacing,
        anchorPoint = "BOTTOMLEFT",
        growX = 1,
        growY = 1,
    });

    container:AddGroup("PlayerDebuffs", debuffFilterString, {
        initializeFrame = initializeButton,
        updateFrame = updateButton,
        filterFunc = function(auraData)
            return C_UnitAuras.IsAuraFilteredOutByInstanceID("target", auraData.auraInstanceID, crowdControlFilter);
        end,
        maxFrameCount = maxDebuffs,
    });

    container:Update();

    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
    eventFrame:RegisterUnitEvent("UNIT_AURA", "target");
    eventFrame:SetScript("OnEvent", function()
        container:Update();
    end);

    return frame;
end;
