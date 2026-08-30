local _, core = ...

local frame = nil;

local function updateBar()
    if not frame then return end;
    local name, text, texture, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    local isChanneled = false

    if not name then
        name, text, texture, _, _, _, notInterruptible = UnitChannelInfo("target")
        isChanneled = true
        if not name then
            return frame:Hide();
        end
    end

    frame:Show();

    frame.name:SetText(text)
    frame.icon:SetTexture(texture)

    if isChanneled then
        frame.bar:SetTimerDuration(UnitChannelDuration("target"), Enum.StatusBarInterpolation.ExponentialEaseOut, Enum.StatusBarTimerDirection.RemainingTime)
    else
        frame.bar:SetTimerDuration(UnitCastingDuration("target"), Enum.StatusBarInterpolation.ExponentialEaseOut, Enum.StatusBarTimerDirection.ElapsedTime)
    end

    if notInterruptible then
        frame.bar:SetStatusBarColor(0.5, 0.5, 0.5);
    else
        frame.bar:SetStatusBarColor(0.1, 1, 0.1);
    end
end

function core:CreateTargetCastbar(parent)
    frame = CreateFrame("Frame", "TargetCastbar", parent)
    frame:SetSize(core.width/4, 16);

    frame.bg = frame:CreateTexture();
    frame.bg:SetPoint("CENTER");
    frame.bg:SetTexture(134532)
    frame.bg:SetColorTexture(0, 0, 0);
    frame.bg:SetSize(core.width/4, 16);
    frame.bg:SetDrawLayer("OVERLAY", -1);

    frame.bar = CreateFrame("StatusBar", nil, frame);
    frame.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    frame.bar:SetPoint("CENTER");
    frame.bar:SetSize(core.width /4 -2, 14);
    frame.bar:SetMinMaxValues(0, 1, Enum.StatusBarInterpolation.ExponentialEaseOut);

    frame.icon = frame:CreateTexture();
    frame.icon:SetPoint("LEFT", -16, 0);
    frame.icon:SetSize(16, 16);

    frame.name = frame.bar:CreateFontString("PrimaryText");
    frame.name:SetDrawLayer("OVERLAY", 1);
    frame.name:SetPoint("LEFT", 0, 0);
    frame.name:SetSize(core.width/4, 16);
    frame.name:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_UPDATE", "target")

    frame:SetScript("OnEvent", function(_, _, _)
        updateBar();
    end)

    return frame;
end
