local _, core = ...;
local colours = core.colours;

local frame = nil;
local savedIcon = nil;
local savedName = nil;
local kickedName = nil;
local kickedClock = nil;
local kickedWait = false;
local castSucceeded = false;
local currentNotInterruptible = false;
local hasActiveCast = false;

local function updateQueueWindowOverlay(isChanneled, startTime, endTime, isEmpowered)
    if not frame then return; end;

    local overlay = frame.queueWindowOverlay;
    if isEmpowered or not startTime or not endTime then
        if overlay then overlay:Hide(); end;
        return;
    end;

    local duration = (endTime - startTime) / 1000;
    local queueWindow = (tonumber(GetCVar("SpellQueueWindow")) or 0) / 1000;
    if duration <= 0 or queueWindow <= 0 then
        if overlay then overlay:Hide(); end;
        return;
    end;

    if not overlay then
        overlay = frame.bar:CreateTexture(nil, "OVERLAY", nil, 0);
        overlay:SetColorTexture(colours.white.r, colours.white.g, colours.white.b);
        overlay:SetAlpha(0.25);
        frame.queueWindowOverlay = overlay;
    end;

    local fraction = math.min(queueWindow, duration) / duration;
    local overlayWidth = frame.bar:GetWidth() * fraction;
    overlay:ClearAllPoints();
    if isChanneled then
        core:SetPixelPoint(overlay, "TOPLEFT", frame.bar, "TOPLEFT", 0, 0);
        core:SetPixelPoint(overlay, "BOTTOMRIGHT", frame.bar, "BOTTOMLEFT", overlayWidth, 0);
    else
        core:SetPixelPoint(overlay, "TOPLEFT", frame.bar, "TOPRIGHT", -overlayWidth, 0);
        core:SetPixelPoint(overlay, "BOTTOMRIGHT", frame.bar, "BOTTOMRIGHT", 0, 0);
    end;
    overlay:Show();
end;

local function clearEmpowerStages()
    if not frame or not frame.empowerStages then return; end;
    frame:SetScript("OnUpdate", nil);
    frame.empowerStartTime = nil;
    frame.empowerDuration = nil;
    for _, stage in ipairs(frame.empowerStages) do
        stage:Hide();
    end;
end;

local function addEmpowerStages(numStages, totalDuration)
    clearEmpowerStages();
    if not frame or not numStages or numStages == 0 or totalDuration <= 0 then return; end;

    local elapsed = 0;
    local width = frame.bar:GetWidth();

    for stageIndex = 0, numStages - 1 do
        elapsed = elapsed + (GetUnitEmpowerStageDuration("player", stageIndex) or 0);

        local marker = frame.empowerStages[stageIndex + 1];
        if not marker then
            marker = frame.bar:CreateTexture(nil, "OVERLAY");
            marker:SetColorTexture(colours.white.r, colours.white.g, colours.white.b);
            core:SetPixelSize(marker, core.pixel, core.castbarHeight);
            frame.empowerStages[stageIndex + 1] = marker;
        end;

        marker:ClearAllPoints();
        core:SetPixelPoint(marker, "CENTER", frame.bar, "LEFT", width * elapsed / totalDuration, 0);
        marker:Show();
    end;
end;

local function updateBar(kicked, empowerEvent)
    if not frame then return; end;
    local name, text, texture, startTime, endTime, _, _, notInterruptible;
    local isEmpowered = false;
    local numStages = nil;
    local isChanneled = false;

    if not empowerEvent then
        name, text, texture, startTime, endTime, _, _, notInterruptible = UnitCastingInfo("player");
    end;

    if empowerEvent or not name then
        local channelIsEmpowered;
        name, text, texture, startTime, endTime, _, notInterruptible, _, channelIsEmpowered, numStages = UnitChannelInfo(
            "player");
        isEmpowered = empowerEvent or channelIsEmpowered;
        isChanneled = true;
        if not name and kicked == nil and not kickedWait then
            -- authoritative "nothing is casting" point; catches CHANNEL_STOP and other events
            -- that don't otherwise clear hasActiveCast, so it can't get stuck true
            hasActiveCast = false;
            clearEmpowerStages();
            updateQueueWindowOverlay(false, nil, nil, true);
            return frame:Hide();
        end;
    end;

    if kicked ~= nil then
        if kickedClock then kickedClock:Cancel(); end;
        kickedWait = true;
        kickedName = kicked;
        kickedClock = C_Timer.NewTimer(1, function()
            kickedWait = false;
            return frame:Hide();
        end);
    end;

    frame:Show();

    if kickedWait then
        clearEmpowerStages();
        updateQueueWindowOverlay(false, nil, nil, true);
        core:ShowCastbarKicked(frame, savedName, savedIcon, kickedName);
        return;
    end;

    updateQueueWindowOverlay(isChanneled, startTime, endTime, isEmpowered);

    frame.name:SetText(text);
    frame.icon:SetTexture(texture);
    frame.target:SetText("");

    savedIcon = texture;
    savedName = text;

    if isChanneled then
        if isEmpowered and startTime and endTime then
            local holdAtMaxTime = GetUnitEmpowerHoldAtMaxTime("player") or 0;
            local totalDuration = endTime - startTime + holdAtMaxTime;
            addEmpowerStages(numStages, totalDuration);
            frame.empowerStartTime = startTime / 1000;
            frame.empowerDuration = totalDuration / 1000;
            frame.bar:SetMinMaxValues(0, frame.empowerDuration);
            frame:SetScript("OnUpdate", function(self)
                local elapsed = math.max(0, math.min(self.empowerDuration, GetTime() - self.empowerStartTime));
                self.bar:SetValue(elapsed);
            end);
            frame:GetScript("OnUpdate")(frame);
        else
            clearEmpowerStages();
            frame.bar:SetTimerDuration(UnitChannelDuration("player"), Enum.StatusBarInterpolation.ExponentialEaseOut,
                Enum.StatusBarTimerDirection.RemainingTime);
        end;
    else
        clearEmpowerStages();
        frame.bar:SetTimerDuration(UnitCastingDuration("player"), Enum.StatusBarInterpolation.ExponentialEaseOut,
            Enum.StatusBarTimerDirection.ElapsedTime);
    end;

    local baseColour = (isEmpowered and colours.castEmpower) or (isChanneled and colours.castChannel) or
        colours.castNormal;
    local colorBase = CreateColor(baseColour.r, baseColour.g, baseColour.b);
    local colorBlocked = CreateColor(colours.castBlocked.r, colours.castBlocked.g, colours.castBlocked.b);

    -- notInterruptible isn't reliably populated on every call (seen consistently nil on Classic
    -- Era); UNIT_SPELLCAST_(NOT_)INTERRUPTIBLE below keeps currentNotInterruptible in sync instead
    if notInterruptible ~= nil then
        currentNotInterruptible = notInterruptible;
    end;

    local blockedCheck = C_CurveUtil.EvaluateColorFromBoolean(currentNotInterruptible, colorBlocked, colorBase);
    core:SetCastbarColor(frame, blockedCheck:GetRGB());
end;

function core:CreatePlayerCastbar(parent)
    frame = core:CreateCastbarBase("PlayerCastBar", parent);

    PlayerCastingBarFrame:SetScript("OnEvent", nil);
    PlayerCastingBarFrame:Hide();

    frame.empowerStages = {};

    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterEvent("CVAR_UPDATE");
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player");
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player");
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "player");
    frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_START", "player");
    frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_UPDATE", "player");
    frame:RegisterUnitEvent("UNIT_SPELLCAST_EMPOWER_STOP", "player");
    frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "player");
    frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "player");
    frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player");
    frame:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", "player");
    frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "player");
    frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "player");
    frame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "player");

    frame:HookScript("OnEvent", function(self, event, target, _, _, kickedBy)
        if event == "CVAR_UPDATE" then
            if target == "SpellQueueWindow" then updateBar(); end;
            return;
        end;

        if event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_EMPOWER_START" or event == "UNIT_SPELLCAST_START" then
            if kickedClock then kickedClock:Cancel(); end;
            kickedWait = false;
            castSucceeded = false;
            currentNotInterruptible = false;
            hasActiveCast = true;
            frame.bar:SetValue(0);
        end;
        if event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
            currentNotInterruptible = event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE";
            updateBar();
        elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
            -- on-next-swing spells (e.g. Heroic Strike) fire this on cancel without ever starting a cast
            if hasActiveCast then
                hasActiveCast = false;
                updateBar(kickedBy or false);
            end;
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            castSucceeded = true;
        elseif event == "UNIT_SPELLCAST_EMPOWER_START" or event == "UNIT_SPELLCAST_EMPOWER_UPDATE" then
            updateBar(nil, true);
        elseif event == "UNIT_SPELLCAST_EMPOWER_STOP" then
            hasActiveCast = false;
            clearEmpowerStages();
            frame:Hide();
        elseif event == "UNIT_SPELLCAST_STOP" then
            local wasActive = hasActiveCast;
            hasActiveCast = false;
            if not castSucceeded and wasActive then
                updateBar(false);
            else
                updateBar();
            end;
        elseif event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" or event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_DELAYED" then
            updateBar();
        else
            updateBar();
        end;
    end);

    return frame;
end;
