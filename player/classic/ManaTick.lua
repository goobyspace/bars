local _, core = ...

if not core.isClassicEra then return end

-- Classic mana regen lands on a fixed 2 second server clock
local tickInterval = 2;
-- spending mana pauses regen for 5 seconds (the "five second rule")
local fsrDuration = 5;

local isSecret = issecretvalue or function() return false end;

local manaState = {
    nextTick = nil,
    fsrStart = nil,
    fsrResume = nil,
    lastMana = nil,
    isFull = false,
};

local function readMana()
    local current = UnitPower("player", Enum.PowerType.Mana);
    local max = UnitPowerMax("player", Enum.PowerType.Mana);
    if isSecret(current) or isSecret(max) then return nil end
    return current, max;
end

local function startFiveSecondRule(now)
    manaState.fsrStart = now;
    local fsrEnd = now + fsrDuration;
    manaState.fsrResume = fsrEnd;
    if manaState.nextTick then
        local boundary = manaState.nextTick;
        while boundary < fsrEnd do
            boundary = boundary + tickInterval;
        end
        manaState.fsrResume = boundary;
    end
end

local manaEvents = CreateFrame("Frame");
manaEvents:RegisterEvent("PLAYER_ENTERING_WORLD");
manaEvents:RegisterUnitEvent("UNIT_POWER_UPDATE", "player");
manaEvents:RegisterUnitEvent("UNIT_MAXPOWER", "player");
manaEvents:SetScript("OnEvent", function(_, event, _, powerType)
    if event == "PLAYER_ENTERING_WORLD" then
        manaState.nextTick = nil;
        manaState.fsrStart = nil;
        manaState.fsrResume = nil;
        local current, max = readMana();
        manaState.lastMana = current;
        manaState.isFull = current ~= nil and max > 0 and current >= max;
        return
    end

    if powerType ~= "MANA" then return end

    local current, max = readMana();
    if not current then return end

    manaState.isFull = max > 0 and current >= max;

    if manaState.lastMana then
        if current > manaState.lastMana then
            manaState.nextTick = GetTime() + tickInterval;
            manaState.fsrStart, manaState.fsrResume = nil, nil;
        elseif current < manaState.lastMana then
            startFiveSecondRule(GetTime());
        end
    end
    manaState.lastMana = current;
end);

function core:CreateManaTicker(bar)
    local ticker = CreateFrame("Frame", nil, bar);
    ticker:SetAllPoints(bar);
    ticker:Hide();

    local line = ticker:CreateTexture(nil, "OVERLAY", nil, 2);
    line:SetColorTexture(1, 1, 1, 1);
    core:SetPixelSize(line, core.pixel, core.barHeight);
    core:SetPixelPoint(line, "LEFT", ticker, "LEFT", 0, 0);

    local active = false;

    local function refresh()
        if active and not manaState.isFull and (manaState.fsrResume or manaState.nextTick) then
            ticker:Show();
        else
            ticker:Hide();
        end
    end

    ticker:SetScript("OnUpdate", function()
        local now = GetTime();

        if manaState.nextTick then
            while now >= manaState.nextTick do
                manaState.nextTick = manaState.nextTick + tickInterval;
            end
        end

        local progress;
        if manaState.fsrResume then
            if now >= manaState.fsrResume then
                manaState.fsrStart, manaState.fsrResume = nil, nil;
                refresh();
            else
                progress = (now - manaState.fsrStart) / (manaState.fsrResume - manaState.fsrStart);
            end
        end

        if not progress then
            if not manaState.nextTick then return end
            progress = 1 - (manaState.nextTick - now) / tickInterval;
        end

        local travel = ticker:GetWidth() - line:GetWidth();
        core:SetPixelPoint(line, "LEFT", ticker, "LEFT", progress * travel, 0);
    end)

    function ticker:SetActive(isActive)
        active = isActive;
        if isActive and manaState.lastMana == nil then
            local current, max = readMana();
            manaState.lastMana = current;
            manaState.isFull = current ~= nil and max > 0 and current >= max;
        end
        refresh();
    end

    return ticker;
end
