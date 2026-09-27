---@diagnostic disable: undefined-global

local _, core = ...;
local colours = core.colours;

if not core.isForever then return; end;

local frame = nil;
local timers = {};
local swingTimerAPI = rawget(_G, "C_SwingTimer");

local function createSwingBar(colorKey)
    if not frame then return; end;

    local timer = {};

    timer.bg = frame:CreateTexture();
    timer.bg:SetTexture(134532);
    timer.bg:SetColorTexture(colours.black.r, colours.black.g, colours.black.b);
    timer.bg:SetHeight(core.barBgHeight);
    timer.bg:SetDrawLayer("OVERLAY", -1);
    timer.bg:Hide();

    timer.bar = CreateFrame("StatusBar", nil, frame);
    timer.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    core:InsetBarInBackground(timer.bar, timer.bg);
    timer.bar:SetMinMaxValues(0, 1);
    timer.bar:SetValue(0);
    timer.bar:Hide();

    local color = core.resources.resourceColours[colorKey];
    timer.bar:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255);
    return timer;
end;

local function hideTimer(timer)
    timer.endTime = nil;
    timer.duration = nil;
    timer.bar:SetValue(0);
    timer.bar:Hide();
    timer.bg:Hide();
end;

local function startTimer(timer, duration)
    if not duration or duration <= 0 then return; end;

    timer.duration = duration;
    timer.endTime = GetTime() + duration;
    timer.bar:SetValue(0);
    timer.bg:Show();
    timer.bar:Show();
end;

function core:CreateSwingTimer(parent)
    frame = CreateFrame("Frame", "SwingTimerContainer", parent);
    core:SetPixelSize(frame, core:EvenPixels(core.width * 2 / 3), core.barBgHeight);

    local gap = 2 * core.pixel;

    timers[Enum.PlayerSwingType.MainHand] = createSwingBar("SWING_MELEE");
    timers[Enum.PlayerSwingType.MainHand].bg:SetPoint("LEFT", frame, "LEFT");
    timers[Enum.PlayerSwingType.MainHand].bg:SetPoint("RIGHT", frame, "CENTER", -gap / 2, 0);
    timers[Enum.PlayerSwingType.MainHand].bg:SetPoint("BOTTOM", frame, "BOTTOM");

    timers[Enum.PlayerSwingType.OffHand] = createSwingBar("SWING_MELEE");
    timers[Enum.PlayerSwingType.OffHand].bg:SetPoint("LEFT", frame, "CENTER", gap / 2, 0);
    timers[Enum.PlayerSwingType.OffHand].bg:SetPoint("RIGHT", frame, "RIGHT");
    timers[Enum.PlayerSwingType.OffHand].bg:SetPoint("BOTTOM", frame, "BOTTOM");

    timers[Enum.PlayerSwingType.Ranged] = createSwingBar("SWING_RANGED");
    timers[Enum.PlayerSwingType.Ranged].bg:SetPoint("LEFT", frame, "LEFT");
    timers[Enum.PlayerSwingType.Ranged].bg:SetPoint("RIGHT", frame, "CENTER", -gap / 2, 0);
    timers[Enum.PlayerSwingType.Ranged].bg:SetPoint("BOTTOM", frame, "BOTTOM", 0, core.rowStep);

    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterEvent("PLAYER_SWING");
    frame:RegisterEvent("PLAYER_SWING_RANGE_UPDATE");

    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            for _, timer in pairs(timers) do
                hideTimer(timer);
            end;
            return;
        end;

        if event == "PLAYER_SWING" then
            local duration, swingType = ...;
            local timer = timers[swingType];
            if timer then startTimer(timer, duration); end;
            return;
        end;

        local swingType, isInRange, checksRange = ...;
        local timer = timers[swingType];
        if timer then
            timer.bg:SetAlpha(checksRange and not isInRange and 0.4 or 1);
            timer.bar:SetAlpha(checksRange and not isInRange and 0.4 or 1);
        end;
    end);

    frame:SetScript("OnUpdate", function()
        -- SetTimerDuration didn't animate this bar, so update it like Blizzard's swing timer does.
        local now = GetTime();
        for _, timer in pairs(timers) do
            if timer.endTime then
                local remaining = timer.endTime - now;
                if remaining <= 0 then
                    hideTimer(timer);
                else
                    timer.bar:SetValue((timer.duration - remaining) / timer.duration);
                end;
            end;
        end;
    end);

    if swingTimerAPI then
        for swingType in pairs(timers) do
            swingTimerAPI.EnableRangeCheck(swingType, true);
        end;
    end;

    return frame;
end;
