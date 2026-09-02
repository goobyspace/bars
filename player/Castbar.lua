local _, core = ...

local frame = nil;
local savedIcon = nil
local savedName = nil
local kickedName = nil
local kickedClock = nil
local kickedWait = false

local function updateBar(kicked)
    if not frame then return end;
    local name, text, texture, _, _, _, _, notInterruptible = UnitCastingInfo("player")
    local isChanneled = false

    if not name then
        name, text, texture, _, _, _, notInterruptible = UnitChannelInfo("player")
        isChanneled = true
        if not name then
            if not kickedWait then
                return frame:Hide();
            end
        end
    end

    if kicked ~= nil then
        if kickedClock then kickedClock:Cancel() end
        kickedWait = true;
        kickedName = kicked
        kickedClock = C_Timer.NewTimer(1, function()
            kickedWait = false
            return frame:Hide();
        end)
    end

    frame:Show();

    if kickedWait then
        frame.name:SetText(savedName)
        frame.icon:SetTexture(savedIcon)
        if kickedName then
            frame.target:SetText(UnitNameFromGUID(kickedName))
        end
        frame.bar:SetStatusBarColor(1.0, 0.1, 0.2)
        local durationObject = C_DurationUtil.CreateDuration()
        durationObject:SetTimeFromStart(0, 0.1)
        frame.bar:SetTimerDuration(durationObject,
            Enum.StatusBarInterpolation.Immediate,
            Enum.StatusBarTimerDirection.ElapsedTime)
        return
    end

    frame.name:SetText(text)
    frame.icon:SetTexture(texture)

    savedIcon = texture;
    savedName = text;

    if isChanneled then
        frame.bar:SetTimerDuration(UnitChannelDuration("player"), Enum.StatusBarInterpolation.ExponentialEaseOut,
            Enum.StatusBarTimerDirection.RemainingTime)
    else
        frame.bar:SetTimerDuration(UnitCastingDuration("player"), Enum.StatusBarInterpolation.ExponentialEaseOut,
            Enum.StatusBarTimerDirection.ElapsedTime)
    end

    local colorKickNotReady = CreateColor(1.0, 0.8, 0.2)       -- red
    local colorBlocked      = CreateColor(0.5, 0.5, 0.5, 1.0); -- gray

    if notInterruptible ~= nil then
        local blockedCheck = C_CurveUtil.EvaluateColorFromBoolean(notInterruptible, colorBlocked, colorKickNotReady)
        frame.bar:SetStatusBarColor(blockedCheck:GetRGB())
    end
end

function core:CreatePlayerCastbar(parent)
    frame = CreateFrame("Frame", "PlayerCastBar", parent)
    frame:SetSize(core.width, 16)

    PlayerCastingBarFrame:SetScript("OnEvent", nil);
    PlayerCastingBarFrame:Hide();

    frame.bg = frame:CreateTexture()
    frame.bg:SetPoint("RIGHT")
    frame.bg:SetTexture(134532)
    frame.bg:SetColorTexture(0, 0, 0)
    frame.bg:SetSize(core.width - 16, 16)
    frame.bg:SetDrawLayer("OVERLAY", -1)

    frame.bar = CreateFrame("StatusBar", nil, frame)
    frame.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
    frame.bar:SetPoint("RIGHT", -2, 0)
    frame.bar:SetSize(core.width - 16 - 2, 14)
    frame.bar:SetMinMaxValues(0, 1, Enum.StatusBarInterpolation.ExponentialEaseOut)

    frame.icon = frame:CreateTexture()
    frame.icon:SetPoint("LEFT", 0, 0)
    frame.icon:SetSize(16, 16)

    frame.name = frame.bar:CreateFontString("PrimaryText")
    frame.name:SetDrawLayer("OVERLAY", 1)
    frame.name:SetPoint("LEFT", 0, 0)
    frame.name:SetSize(core.width / 2, 16)
    frame.name:SetJustifyH("LEFT")
    frame.name:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")

    frame.target = frame.bar:CreateFontString("PrimaryText")
    frame.target:SetDrawLayer("OVERLAY", 1)
    frame.target:SetPoint("RIGHT", 0, 0)
    frame.target:SetSize(core.width / 2, 16)
    frame.target:SetJustifyH("RIGHT")
    frame.target:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    -- Events
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")

    frame:HookScript("OnEvent", function(self, event, target, _, _, kickedBy)
        if event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_START" then
            -- cancel the kickedClock incase the enemy immediately starts casting again
            if kickedClock then kickedClock:Cancel() end
            kickedWait = false
        end
        if event == "UNIT_SPELLCAST_INTERRUPTED" then
            -- if kickedBy is not an ID we still wanna make it clear the cast was stopped
            updateBar(kickedBy or false)
        elseif event == "UNIT_SPELLCAST_CHANNEL_START" or event == "EVENT_SPELLCAST_CHANNEL_STOP" or event == "EVENT_SPELLCAST_CHANNEL_UPDATE" or event == "EVENT_SPELLCAST_START" or event == "EVENT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_DELAYED" then
            updateBar()
        else
            updateBar()
        end
    end)

    return frame;
end
