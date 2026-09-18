local _, core = ...
local colours = core.colours

if not core.isForever then return end

local fsrDuration = core.resourceTickerConfig.fiveSecondRuleDuration;
local activeTickers = {};
local fsrEndTime = nil;

local function SpellCostsMana(spellID)
    for _, costInfo in ipairs(C_Spell.GetSpellPowerCost(spellID) or {}) do
        if costInfo.type == Enum.PowerType.Mana
            and ((costInfo.cost or 0) > 0 or (costInfo.costPercent or 0) > 0) then
            return true;
        end
    end
    return false;
end

local function RefreshTickers()
    for ticker in pairs(activeTickers) do
        ticker:Refresh();
    end
end

local manaEvents = CreateFrame("Frame");
manaEvents:RegisterEvent("PLAYER_ENTERING_WORLD");
manaEvents:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player");
manaEvents:SetScript("OnEvent", function(_, event, _, _, spellID)
    if event == "PLAYER_ENTERING_WORLD" then
        fsrEndTime = nil;
    elseif spellID and SpellCostsMana(spellID) then
        fsrEndTime = GetTime() + fsrDuration;
    end
    RefreshTickers();
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

    function ticker:Refresh()
        if resource == Enum.PowerType.Mana and fsrEndTime and GetTime() < fsrEndTime then
            ticker:Show();
        else
            ticker:Hide();
        end
    end

    ticker:SetScript("OnUpdate", function()
        if resource ~= Enum.PowerType.Mana or not fsrEndTime then return end

        local remaining = fsrEndTime - GetTime();
        if remaining <= 0 then
            fsrEndTime = nil;
            ticker:Refresh();
            return;
        end

        local progress = 1 - remaining / fsrDuration;
        local travel = ticker:GetWidth() - line:GetWidth();
        core:SetPixelPoint(line, "LEFT", ticker, "LEFT", progress * travel, 0);
    end);

    function ticker:SetActive(activeResource)
        resource = fixedResource and activeResource and fixedResource or activeResource;
        ticker:Refresh();
    end

    activeTickers[ticker] = true;
    return ticker;
end

function core:CreateManaTicker(bar)
    return core:CreateResourceTicker(bar, Enum.PowerType.Mana);
end
