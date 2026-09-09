local _, core = ...
local colours = core.colours

if not core.isClassicEra then return end

-- Classic mana regen lands on a fixed 2 second server clock
local tickInterval = 2;
-- spending mana pauses regen for 5 seconds (the "five second rule")
local fsrDuration = 5;

local isSecret = issecretvalue or function() return false end;

local resourceStates = {
    [Enum.PowerType.Mana] = {},
    [Enum.PowerType.Energy] = {},
};

local function readPower(resource)
    local current = UnitPower("player", resource);
    local max = UnitPowerMax("player", resource);
    if isSecret(current) or isSecret(max) then return nil end
    return current, max;
end

local function startFiveSecondRule(state, now)
    state.fsrStart = now;
    local fsrEnd = now + fsrDuration;
    state.fsrResume = fsrEnd;
    if state.nextTick then
        local boundary = state.nextTick;
        while boundary < fsrEnd do
            boundary = boundary + tickInterval;
        end
        state.fsrResume = boundary;
    end
end

local manaEvents = CreateFrame("Frame");
manaEvents:RegisterEvent("PLAYER_ENTERING_WORLD");
manaEvents:RegisterUnitEvent("UNIT_POWER_UPDATE", "player");
manaEvents:RegisterUnitEvent("UNIT_MAXPOWER", "player");
manaEvents:SetScript("OnEvent", function(_, event, _, powerType)
    if event == "PLAYER_ENTERING_WORLD" then
        for resource, state in pairs(resourceStates) do
            state.nextTick = nil;
            state.fsrStart = nil;
            state.fsrResume = nil;
            local current, max = readPower(resource);
            state.lastPower = current;
            state.isFull = current ~= nil and max > 0 and current >= max;
        end
        return
    end

    local resource = powerType == "MANA" and Enum.PowerType.Mana
        or powerType == "ENERGY" and Enum.PowerType.Energy;
    local state = resource and resourceStates[resource];
    if not state then return end

    local current, max = readPower(resource);
    if not current then return end

    state.isFull = max > 0 and current >= max;

    if state.lastPower then
        if current > state.lastPower then
            state.nextTick = GetTime() + tickInterval;
            state.fsrStart, state.fsrResume = nil, nil;
        elseif resource == Enum.PowerType.Mana and current < state.lastPower then
            startFiveSecondRule(state, GetTime());
        end
    end
    state.lastPower = current;
end);

function core:CreateResourceTicker(bar, fixedResource)
    local ticker = CreateFrame("Frame", nil, bar);
    ticker:SetAllPoints(bar);
    ticker:Hide();

    local line = ticker:CreateTexture(nil, "OVERLAY", nil, 2);
    line:SetColorTexture(colours.white.r, colours.white.g, colours.white.b, colours.white.a);
    core:SetPixelSize(line, core.pixel, core.barHeight);
    core:SetPixelPoint(line, "LEFT", ticker, "LEFT", 0, 0);

    local resource;

    local function refresh()
        local state = resource and resourceStates[resource];
        if state and not state.isFull and (state.fsrResume or state.nextTick) then
            ticker:Show();
        else
            ticker:Hide();
        end
    end

    ticker:SetScript("OnUpdate", function()
        local state = resource and resourceStates[resource];
        if not state then return end
        local now = GetTime();

        if state.nextTick then
            while now >= state.nextTick do
                state.nextTick = state.nextTick + tickInterval;
            end
        end

        local progress;
        if state.fsrResume then
            if now >= state.fsrResume then
                state.fsrStart, state.fsrResume = nil, nil;
                refresh();
            else
                progress = (now - state.fsrStart) / (state.fsrResume - state.fsrStart);
            end
        end

        if not progress then
            if not state.nextTick then return end
            progress = 1 - (state.nextTick - now) / tickInterval;
        end

        local travel = ticker:GetWidth() - line:GetWidth();
        core:SetPixelPoint(line, "LEFT", ticker, "LEFT", progress * travel, 0);
    end)

    function ticker:SetActive(activeResource)
        resource = fixedResource and activeResource and fixedResource or activeResource;
        local state = resource and resourceStates[resource];
        if state and state.lastPower == nil then
            local current, max = readPower(resource);
            state.lastPower = current;
            state.isFull = current ~= nil and max > 0 and current >= max;
        end
        refresh();
    end

    return ticker;
end

function core:CreateManaTicker(bar)
    return core:CreateResourceTicker(bar, Enum.PowerType.Mana);
end
