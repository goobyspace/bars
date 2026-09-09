local _, core = ...
local colours = core.colours
local config = core.widgetConfig.breath

local timerCount = rawget(_G, "MIRRORTIMER_NUMTIMERS") or config.fallbackTimerCount;

local function hideBlizzardTimer(timer)
    if MirrorTimerContainer and MirrorTimerContainer.ClearTimer then
        MirrorTimerContainer:ClearTimer(timer);
        return
    end

    for index = 1, timerCount do
        local blizzardTimer = _G["MirrorTimer" .. index];
        if blizzardTimer and blizzardTimer.timer == timer then
            blizzardTimer:Hide();
        end
    end
end

function core:CreateBreathBar(parent)
    local frame = CreateFrame("Frame", "BarsBreathBar", parent);
    local width = core.width * config.widthFactor;
    core:SetPixelSize(frame, width, core.barBgHeight);
    core:SetPixelPoint(frame, "CENTER", UIParent, "BOTTOM", 0, UIParent:GetHeight() * config.screenHeight);
    core:SnapToPixelGrid(frame);

    local bars = {};

    local function getBar(timer)
        local timerBar = bars[timer];
        if timerBar then return timerBar end

        timerBar = core:CreateSimpleStatusBar(nil, frame, width, core.barBgHeight, {
            includeText = true,
            fontSize = config.fontSize,
        });
        local colour = colours.mirrorTimers[timer] or colours.mirrorTimers.BREATH;
        timerBar.bar:SetStatusBarColor(colour.r, colour.g, colour.b);
        timerBar.timer = timer;
        bars[timer] = timerBar;
        return timerBar;
    end

    local function layoutBars()
        local activeCount = 0;
        for _, timerBar in pairs(bars) do
            if timerBar.active then
                activeCount = activeCount + 1;
                timerBar:ClearAllPoints();
                core:SetPixelPoint(timerBar, "TOP", frame, "TOP", 0, -(activeCount - 1) * core.rowStep);
                timerBar:Show();
            else
                timerBar:Hide();
            end
        end

        frame:SetShown(activeCount > 0);
    end

    local function setTimer(timer, value, maximum, scale, paused, label)
        if not timer or timer == "UNKNOWN" or not value or not maximum or maximum <= 0 then return end

        local timerBar = getBar(timer);
        timerBar.value = value;
        timerBar.maximum = maximum;
        timerBar.baseScale = scale;
        timerBar.scale = paused == 1 and 0 or scale;
        timerBar.label = label or timer;
        timerBar.active = true;
        timerBar.bar:SetMinMaxValues(0, maximum);
        timerBar.bar:SetValue(value);
        hideBlizzardTimer(timer);
    end

    local function refresh()
        for _, timerBar in pairs(bars) do
            timerBar.active = false;
        end

        for index = 1, timerCount do
            setTimer(GetMirrorTimerInfo(index));
        end
        layoutBars();
    end

    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterEvent("MIRROR_TIMER_START");
    frame:RegisterEvent("MIRROR_TIMER_STOP");
    frame:RegisterEvent("MIRROR_TIMER_PAUSE");
    frame:SetScript("OnEvent", function(_, event, timer, ...)
        if event == "MIRROR_TIMER_START" then
            setTimer(timer, ...);
        elseif event == "MIRROR_TIMER_STOP" then
            if bars[timer] then
                bars[timer].active = false;
            end
        elseif event == "MIRROR_TIMER_PAUSE" then
            local paused = ...;
            if bars[timer] then
                bars[timer].scale = paused == 1 and 0 or bars[timer].baseScale;
            end
        else
            refresh();
            return
        end
        layoutBars();
    end);
    frame:SetScript("OnUpdate", function(_, elapsed)
        for _, timerBar in pairs(bars) do
            if timerBar.active then
                local progress = GetMirrorTimerProgress(timerBar.timer);
                timerBar.value = progress or math.max(0,
                    math.min(timerBar.maximum, timerBar.value + elapsed * 1000 * timerBar.scale));
                timerBar.bar:SetValue(timerBar.value);
                timerBar.text:SetFormattedText("%s  %d", timerBar.label, math.ceil(timerBar.value / 1000));
            end
        end
    end);

    refresh();
    return frame;
end
