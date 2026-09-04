local _, core = ...

local frame = nil;
local savedIcon = nil
local savedName = nil
local kickedName = nil
local kickedClock = nil
local kickedWait = false
local castSucceeded = false
local currentNotInterruptible = false

local function clearEmpowerStages()
    if not frame or not frame.empowerStages then return end
    frame:SetScript("OnUpdate", nil)
    frame.empowerStartTime = nil
    frame.empowerDuration = nil
    for _, stage in ipairs(frame.empowerStages) do
        stage:Hide()
    end
end

local function addEmpowerStages(numStages, totalDuration)
    clearEmpowerStages()
    if not frame or not numStages or numStages == 0 or totalDuration <= 0 then return end

    local elapsed = 0
    local width = frame.bar:GetWidth()

    for stageIndex = 0, numStages - 1 do
        elapsed = elapsed + (GetUnitEmpowerStageDuration("player", stageIndex) or 0)

        local marker = frame.empowerStages[stageIndex + 1]
        if not marker then
            marker = frame.bar:CreateTexture(nil, "OVERLAY")
            marker:SetColorTexture(1, 1, 1)
            marker:SetWidth(1)
            marker:SetHeight(core.castbarHeight)
            frame.empowerStages[stageIndex + 1] = marker
        end

        marker:ClearAllPoints()
        marker:SetPoint("CENTER", frame.bar, "LEFT", width * elapsed / totalDuration, 0)
        marker:Show()
    end
end

local function updateBar(kicked, empowerEvent)
    if not frame then return end;
    local name, text, texture, startTime, endTime, _, _, notInterruptible
    local isEmpowered = false
    local numStages = nil
    local isChanneled = false

    if not empowerEvent then
        name, text, texture, startTime, endTime, _, _, notInterruptible = UnitCastingInfo("player")
    end

    if empowerEvent or not name then
        local channelIsEmpowered
        name, text, texture, startTime, endTime, _, notInterruptible, _, channelIsEmpowered, numStages = UnitChannelInfo(
            "player")
        isEmpowered = empowerEvent or channelIsEmpowered
        isChanneled = true
        if not name and kicked == nil and not kickedWait then
            clearEmpowerStages()
            return frame:Hide();
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
        clearEmpowerStages()
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
        if isEmpowered and startTime and endTime then
            local holdAtMaxTime = GetUnitEmpowerHoldAtMaxTime("player") or 0
            local totalDuration = endTime - startTime + holdAtMaxTime
            addEmpowerStages(numStages, totalDuration)
            frame.empowerStartTime = startTime / 1000
            frame.empowerDuration = totalDuration / 1000
            frame.bar:SetMinMaxValues(0, frame.empowerDuration)
            frame:SetScript("OnUpdate", function(self)
                local elapsed = math.max(0, math.min(self.empowerDuration, GetTime() - self.empowerStartTime))
                self.bar:SetValue(elapsed)
            end)
            frame:GetScript("OnUpdate")(frame)
        else
            clearEmpowerStages()
            frame.bar:SetTimerDuration(UnitChannelDuration("player"), Enum.StatusBarInterpolation.ExponentialEaseOut,
                Enum.StatusBarTimerDirection.RemainingTime)
        end
    else
        clearEmpowerStages()
        frame.bar:SetTimerDuration(UnitCastingDuration("player"), Enum.StatusBarInterpolation.ExponentialEaseOut,
            Enum.StatusBarTimerDirection.ElapsedTime)
    end

    local colorKickNotReady = CreateColor(1.0, 0.8, 0.2)       -- red
    local colorBlocked      = CreateColor(0.5, 0.5, 0.5, 1.0); -- gray

    -- notInterruptible isn't reliably populated on every call (seen consistently nil on Classic
    -- Era); UNIT_SPELLCAST_(NOT_)INTERRUPTIBLE below keeps currentNotInterruptible in sync instead
    if notInterruptible ~= nil then
        currentNotInterruptible = notInterruptible;
    end

    local blockedCheck = C_CurveUtil.EvaluateColorFromBoolean(currentNotInterruptible, colorBlocked, colorKickNotReady)
    frame.bar:SetStatusBarColor(blockedCheck:GetRGB())
end

function core:CreatePlayerCastbar(parent)
    frame = CreateFrame("Frame", "PlayerCastBar", parent)
    frame:SetSize(core.width, core.castbarHeight)

    PlayerCastingBarFrame:SetScript("OnEvent", nil);
    PlayerCastingBarFrame:Hide();

    frame.bg = frame:CreateTexture()
    frame.bg:SetPoint("RIGHT")
    frame.bg:SetTexture(134532)
    frame.bg:SetColorTexture(0, 0, 0)
    frame.bg:SetSize(core.width - core.castbarHeight, core.castbarHeight)
    frame.bg:SetDrawLayer("OVERLAY", -1)

    frame.bar = CreateFrame("StatusBar", nil, frame)
    frame.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
    frame.bar:SetPoint("RIGHT", -2, 0)
    frame.bar:SetSize(core.width - core.castbarHeight - 2, core.castbarHeight - 2)
    frame.bar:SetMinMaxValues(0, 1, Enum.StatusBarInterpolation.ExponentialEaseOut)
    frame.empowerStages = {}

    frame.icon = frame:CreateTexture()
    frame.icon:SetPoint("LEFT", 0, 0)
    frame.icon:SetSize(core.castbarHeight, core.castbarHeight)

    frame.name = frame.bar:CreateFontString("PrimaryText")
    frame.name:SetDrawLayer("OVERLAY", 1)
    frame.name:SetPoint("LEFT", 0, 0)
    frame.name:SetSize(core.width / 2, core.castbarHeight)
    frame.name:SetJustifyH("LEFT")
    core:SetBarFont(frame.name, 10)

    frame.target = frame.bar:CreateFontString("PrimaryText")
    frame.target:SetDrawLayer("OVERLAY", 1)
    frame.target:SetPoint("RIGHT", 0, 0)
    frame.target:SetSize(core.width / 2, core.castbarHeight)
    frame.target:SetJustifyH("RIGHT")
    core:SetBarFont(frame.target, 10)

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_UPDATE", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "player")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "player")

    frame:HookScript("OnEvent", function(self, event, target, _, _, kickedBy)
        if event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_EMPOWER_START" or event == "UNIT_SPELLCAST_START" then
            -- cancel the kickedClock incase the enemy immediately starts casting again
            if kickedClock then kickedClock:Cancel() end
            kickedWait = false
            castSucceeded = false
            currentNotInterruptible = false
            frame.bar:SetValue(0)
        end
        if event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
            currentNotInterruptible = event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE";
            updateBar()
        elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
            -- if kickedBy is not an ID we still wanna make it clear the cast was stopped
            updateBar(kickedBy or false)
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            castSucceeded = true
        elseif event == "UNIT_SPELLCAST_EMPOWER_START" or event == "UNIT_SPELLCAST_EMPOWER_UPDATE" then
            updateBar(nil, true)
        elseif event == "UNIT_SPELLCAST_EMPOWER_STOP" then
            clearEmpowerStages()
            frame:Hide()
        elseif event == "UNIT_SPELLCAST_STOP" then
            if not castSucceeded then
                updateBar(false)
            else
                updateBar()
            end
        elseif event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" or event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_DELAYED" then
            updateBar()
        else
            updateBar()
        end
    end)

    return frame;
end
