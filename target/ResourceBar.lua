local _, core = ...

local frame = nil;

local function updateBar()
    if not frame or not frame:IsShown() then return end;

    frame.bar:SetValue(UnitPowerPercent("target", nil, true), Enum.StatusBarInterpolation.ExponentialEaseOut);
end

local function updateColour()
    -- this is always a bar so we only need to worry about colour
    if not frame or not frame:IsShown() then return end;
    local enum, _, r, g, b = UnitPowerType("target")
    local color = core.resources.resourceColours[enum]

    frame.bar:SetStatusBarColor(r or color and color.r / 255 or 0, g or color and color.g / 255 or 0, b or color and color.b / 255 or 0)
end

function core:CreateTargetResourceBar(parent)
    frame = CreateFrame("Frame", "TargetResourceContainer", parent)
    frame:SetSize(core.width, 10);

    frame.bg = frame:CreateTexture();
    frame.bg:SetPoint("CENTER");
    frame.bg:SetTexture(134532)
    frame.bg:SetColorTexture(0, 0, 0);
    frame.bg:SetSize(core.width/3 * 2, 4);
    frame.bg:SetDrawLayer("OVERLAY", -1);

    frame.bar = CreateFrame("StatusBar", nil, frame);
    frame.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    frame.bar:SetPoint("CENTER");
    frame.bar:SetSize(core.width /3 * 2 -2, 2);
    frame.bar:SetMinMaxValues(0, 1, Enum.StatusBarInterpolation.ExponentialEaseOut);

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "target")
    frame:RegisterEvent("UNIT_POWER_FREQUENT")
    frame:RegisterUnitEvent("UNIT_MAXPOWER", "target")
    frame:RegisterEvent("PET_BATTLE_OPENING_START")
    frame:RegisterEvent("PET_BATTLE_CLOSE")
    frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "target")
    frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "target")
    frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")


    frame:SetScript("OnEvent", function(_, _, _)
        updateColour();
        updateBar();
    end)

    return frame;
end
