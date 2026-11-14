local _, core = ...;
local colours = core.colours;
local config = core.widgetConfig.flightPath;

local function formatDuration(seconds)
    seconds = math.max(0, math.ceil(seconds));
    return format("%d:%02d", math.floor(seconds / 60), seconds % 60);
end;

function core:CreateFlightPathTimer(parent)
    local frame = core:CreateCastbarBase("BarsFlightPathTimer", parent);
    frame.icon:SetTexture(config.icon);
    frame.bar:SetStatusBarColor(colours.flightPath.r, colours.flightPath.g, colours.flightPath.b);
    frame:Hide();

    BarsGlobalVariables.flightPathDurations = BarsGlobalVariables.flightPathDurations or {};
    local allDurations = BarsGlobalVariables.flightPathDurations;
    local faction = UnitFactionGroup("player");
    local oppositeFaction = faction == "Alliance" and "Horde" or "Alliance";
    allDurations.Alliance = allDurations.Alliance or {};
    allDurations.Horde = allDurations.Horde or {};

    -- Legacy timings had no faction bucket, so preserve them under the faction loading the migration.
    for route, duration in pairs(allDurations) do
        if type(duration) == "number" then
            allDurations[faction][route] = duration;
            allDurations[route] = nil;
        end;
    end;

    local durations = allDurations[faction];
    local oppositeDurations = allDurations[oppositeFaction];
    local factionData = core.flightPathData[faction] or {};
    local oppositeFactionData = core.flightPathData[oppositeFaction] or {};
    local taxiNodes = {};
    local sourceName;
    local pendingDestination;
    local pendingRoute;
    local selectedAt;
    local selectionExpiresAt;
    local gossipNPC;
    local gossipName;
    local gossipOptions = {};
    local startedAt;
    local expectedDuration;
    local elapsedSinceUpdate = 0;

    local controller = CreateFrame("Frame");

    local function captureTaxiMap()
        wipe(taxiNodes);
        sourceName = nil;
        for index = 1, NumTaxiNodes() do
            taxiNodes[index] = TaxiNodeName(index);
            if TaxiNodeGetType(index) == "CURRENT" then
                sourceName = taxiNodes[index];
            end;
        end;
    end;

    local function beginFlight()
        if startedAt or not UnitOnTaxi("player") then return; end;
        if selectionExpiresAt and GetTime() > selectionExpiresAt then
            pendingDestination = nil;
            pendingRoute = nil;
            selectedAt = nil;
        end;
        selectionExpiresAt = nil;
        startedAt = selectedAt or GetTime();
        expectedDuration = pendingRoute and (factionData[pendingRoute] or durations[pendingRoute]
            or oppositeFactionData[pendingRoute] or oppositeDurations[pendingRoute]) or nil;
        frame.name:SetText(pendingDestination or "Flight path");
        if expectedDuration then
            frame.bar:SetMinMaxValues(0, expectedDuration);
            frame.bar:SetValue(expectedDuration);
        else
            frame.bar:SetMinMaxValues(0, 1);
            frame.bar:SetValue(1);
        end;
        frame:Show();
    end;

    local function endFlight()
        if not startedAt then return; end;
        local duration = GetTime() - startedAt;
        if pendingRoute and not factionData[pendingRoute] and duration > config.minimumLearnedDuration then
            durations[pendingRoute] = duration;
        end;
        startedAt = nil;
        expectedDuration = nil;
        selectedAt = nil;
        selectionExpiresAt = nil;
        pendingDestination = nil;
        pendingRoute = nil;
        frame:Hide();
    end;

    hooksecurefunc("TakeTaxiNode", function(index)
        pendingDestination = taxiNodes[index];
        pendingRoute = sourceName and pendingDestination and (sourceName .. "\031" .. pendingDestination) or nil;
        selectedAt = GetTime();
        selectionExpiresAt = nil;
    end);

    local function selectGossipOption(optionID)
        if startedAt or not gossipNPC or not optionID then return; end;
        pendingDestination = gossipName;
        pendingRoute = "gossip:" .. gossipNPC .. "\031" .. optionID;
        selectedAt = GetTime();
        selectionExpiresAt = selectedAt + 10;
    end;

    if core.isForever then
        hooksecurefunc(C_GossipInfo, "SelectOption", selectGossipOption);
        if C_GossipInfo.SelectOptionByIndex then
            hooksecurefunc(C_GossipInfo, "SelectOptionByIndex", function(index)
                local option = gossipOptions[index];
                selectGossipOption(option and option.gossipOptionID);
            end);
        end;
        controller:RegisterEvent("GOSSIP_SHOW");
    end;

    controller:RegisterEvent("PLAYER_ENTERING_WORLD");
    controller:RegisterEvent("TAXIMAP_OPENED");
    controller:RegisterEvent("PLAYER_CONTROL_LOST");
    controller:RegisterEvent("PLAYER_CONTROL_GAINED");
    controller:SetScript("OnEvent", function(_, event)
        if event == "TAXIMAP_OPENED" then
            captureTaxiMap();
        elseif event == "GOSSIP_SHOW" then
            local guid = UnitGUID("npc");
            gossipName = UnitName("npc");
            if guid and not issecretvalue(guid) then
                gossipNPC = guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-");
            elseif gossipName and not issecretvalue(gossipName) then
                gossipNPC = gossipName;
            else
                gossipNPC = nil;
            end;
            gossipOptions = C_GossipInfo.GetOptions();
        elseif UnitOnTaxi("player") then
            beginFlight();
        elseif event == "PLAYER_CONTROL_GAINED" then
            endFlight();
        end;
    end);
    controller:SetScript("OnUpdate", function(_, elapsed)
        elapsedSinceUpdate = elapsedSinceUpdate + elapsed;
        if elapsedSinceUpdate < config.updateInterval then return; end;
        elapsedSinceUpdate = 0;

        if UnitOnTaxi("player") then
            beginFlight();
        elseif startedAt then
            endFlight();
            return;
        end;

        if not startedAt then return; end;
        local flightElapsed = GetTime() - startedAt;
        if expectedDuration then
            local remaining = math.max(0, expectedDuration - flightElapsed);
            frame.bar:SetValue(remaining);
            frame.target:SetText(formatDuration(remaining));
        else
            frame.target:SetFormattedText("Estimating %s", formatDuration(flightElapsed));
        end;
    end);

    return frame;
end;
