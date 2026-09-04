local _, core = ...

if not core.isClassicEra then return end

-- Classic mana regen lands on a fixed 2 second server clock
local TICK_INTERVAL = 2;
-- spending mana pauses regen for 5 seconds (the "five second rule")
local FSR_DURATION = 5;

local isSecret = issecretvalue or function() return false end;

function core:CreateManaTicker(bar)
    local ticker = CreateFrame("Frame", "ManaTickerContainer", bar);
    ticker:SetAllPoints(bar);
    ticker:Hide();

    local line = ticker:CreateTexture(nil, "OVERLAY", nil, 2);
    line:SetColorTexture(1, 1, 1, 1);
    core:SetPixelSize(line, core.pixel, core.barHeight);
    core:SetPixelPoint(line, "LEFT", ticker, "LEFT", 0, 0);

    local active = false;
    local nextTick = nil;
    local fsrStart, fsrResume = nil, nil;
    local lastMana = nil;
    local isFull = false;

    local function readMana()
        local current = UnitPower("player", Enum.PowerType.Mana);
        local max = UnitPowerMax("player", Enum.PowerType.Mana);
        if isSecret(current) or isSecret(max) then return nil end
        return current, max;
    end

    local function refresh()
        if active and not isFull and (fsrResume or nextTick) then
            ticker:Show();
        else
            ticker:Hide();
        end
    end

    -- the 2s server clock keeps running through the five second rule, so regen resumes on the
    -- first tick boundary at or after the rule expires rather than exactly 5s after the spend
    local function startFiveSecondRule(now)
        fsrStart = now;
        local fsrEnd = now + FSR_DURATION;
        fsrResume = fsrEnd;
        if nextTick then
            local boundary = nextTick;
            while boundary < fsrEnd do
                boundary = boundary + TICK_INTERVAL;
            end
            fsrResume = boundary;
        end
    end

    ticker:SetScript("OnUpdate", function()
        local now = GetTime();

        if nextTick then
            while now >= nextTick do
                nextTick = nextTick + TICK_INTERVAL;
            end
        end

        local progress;
        if fsrResume then
            if now >= fsrResume then
                fsrStart, fsrResume = nil, nil;
                refresh();
            else
                progress = (now - fsrStart) / (fsrResume - fsrStart);
            end
        end

        if not progress then
            if not nextTick then return end
            progress = 1 - (nextTick - now) / TICK_INTERVAL;
        end

        local travel = ticker:GetWidth() - line:GetWidth();
        core:SetPixelPoint(line, "LEFT", ticker, "LEFT", progress * travel, 0);
    end)

    ticker:RegisterEvent("PLAYER_ENTERING_WORLD");
    ticker:RegisterUnitEvent("UNIT_POWER_UPDATE", "player");
    ticker:RegisterUnitEvent("UNIT_MAXPOWER", "player");
    ticker:SetScript("OnEvent", function(_, event, _, powerType)
        if event == "PLAYER_ENTERING_WORLD" then
            nextTick = nil;
            fsrStart, fsrResume = nil, nil;
            local current, max = readMana();
            lastMana = current;
            isFull = current ~= nil and max > 0 and current >= max;
            refresh();
            return;
        end

        if powerType ~= "MANA" then return end

        local current, max = readMana();
        if not current then return end

        isFull = max > 0 and current >= max;

        if lastMana then
            if current > lastMana then
                -- any mana gain lands on the tick clock, so it resyncs the cadence
                nextTick = GetTime() + TICK_INTERVAL;
                fsrStart, fsrResume = nil, nil;
            elseif current < lastMana then
                startFiveSecondRule(GetTime());
            end
        end
        lastMana = current;

        refresh();
    end)

    function ticker:SetActive(isActive)
        active = isActive;
        if not isActive then
            lastMana = nil;
        elseif lastMana == nil then
            local current, max = readMana();
            lastMana = current;
            isFull = current ~= nil and max > 0 and current >= max;
        end
        refresh();
    end

    return ticker;
end
