local _, core = ...;

local function getWatchedFaction()
    if C_Reputation and C_Reputation.GetWatchedFactionData then
        local data = C_Reputation.GetWatchedFactionData();
        if data and data.factionID and data.factionID ~= 0 then
            return data;
        end;
        return nil;
    end;

    local name, reaction, minimum, maximum, value, factionID = GetWatchedFactionInfo();
    if not name or not factionID or factionID == 0 then
        return nil;
    end;
    return {
        name = name,
        factionID = factionID,
        reaction = reaction,
        currentReactionThreshold = minimum,
        nextReactionThreshold = maximum,
        currentStanding = value,
    };
end;

-- returns the bar values for the watched faction, mirroring ReputationStatusBarMixin:Update from blizzard
local function getReputationProgress(faction)
    local factionID = faction.factionID;
    local reaction = faction.reaction;
    local minimum, maximum, value = faction.currentReactionThreshold, faction.nextReactionThreshold,
        faction.currentStanding;
    local useBlue = false;
    local capped = false;

    local isParagon = C_Reputation and C_Reputation.IsFactionParagonForCurrentPlayer
        and C_Reputation.IsFactionParagonForCurrentPlayer(factionID);
    local isMajor = C_Reputation and C_Reputation.IsMajorFaction and C_Reputation.IsMajorFaction(factionID);
    local friendship = C_GossipInfo and C_GossipInfo.GetFriendshipReputation
        and C_GossipInfo.GetFriendshipReputation(factionID);

    if isParagon then
        local currentValue, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionID);
        if currentValue and threshold then
            minimum, maximum = 0, threshold;
            value = currentValue % threshold;
            if hasRewardPending then
                value = value + threshold;
            end;
        end;
        useBlue = isMajor;
    elseif isMajor then
        local majorFactionData = C_MajorFactions.GetMajorFactionData(factionID);
        minimum, maximum = 0, majorFactionData.renownLevelThreshold;
        value = majorFactionData.renownReputationEarned or 0;
        useBlue = true;
    elseif friendship and friendship.friendshipFactionID and friendship.friendshipFactionID > 0 then
        if friendship.nextThreshold then
            minimum, maximum, value = friendship.reactionThreshold, friendship.nextThreshold, friendship.standing;
        else
            capped = true;
        end;
        reaction = 5;
    elseif reaction and reaction >= (MAX_REPUTATION_REACTION or 8) then
        capped = true;
    end;

    if capped or not maximum or maximum <= minimum then
        return 1, 1, reaction, useBlue, true;
    end;

    return value - minimum, maximum - minimum, reaction, useBlue, false;
end;

local function findFactionIndex(factionID)
    for index = 1, C_Reputation.GetNumFactions() do
        local data = C_Reputation.GetFactionDataByIndex(index);
        if data and data.factionID == factionID then
            return index;
        end;
    end;
end;

local function openReputationTab()
    ToggleCharacter("ReputationFrame");
    if not ReputationFrame or not ReputationFrame:IsShown() then
        return;
    end;

    local faction = getWatchedFaction();
    if not faction then
        return;
    end;

    local index = findFactionIndex(faction.factionID);
    if not index then
        -- the faction is probably inside a collapsed header, which hides it from the list
        C_Reputation.ExpandAllFactionHeaders();
        index = findFactionIndex(faction.factionID);
    end;
    if not index then
        return;
    end;

    C_Reputation.SetSelectedFaction(index);
    ReputationFrame:Update();
    EventRegistry:TriggerEvent("ReputationFrame.NewFactionSelected");
    ReputationFrame.ScrollBox:ScrollToElementDataByPredicate(function(elementData)
        return elementData.factionID == faction.factionID;
    end);
end;

function core:CreateReputationBar(parent, experienceBar)
    local frame = core:CreateSimpleStatusBar("PlayerReputationBar", parent, core.width, core.barBgHeight);
    frame:EnableMouse(true);
    frame:Hide();

    local textFrame = CreateFrame("Frame", nil, frame);
    textFrame:SetAllPoints(frame.bar);
    textFrame:SetFrameLevel(frame.bar:GetFrameLevel() + 2);

    frame.text = textFrame:CreateFontString(nil, "OVERLAY");
    frame.text:SetPoint("CENTER");
    core:SetBarFont(frame.text, 12);
    frame.text:Hide();

    -- sits on the bottom edge of the screen, or stacked above the experience bar while that one is visible
    local function updatePosition()
        frame:ClearAllPoints();
        if experienceBar and experienceBar:IsShown() then
            core:SetPixelPoint(frame, "BOTTOM", experienceBar, "TOP", 0, core.rowGap);
        else
            core:SetPixelPoint(frame, "BOTTOM", UIParent, "BOTTOM", 0, 4 * core.pixel);
        end;
        core:SnapToPixelGrid(frame);
    end;

    local function update()
        local faction = getWatchedFaction();
        if not faction then
            frame:Hide();
            return;
        end;

        local value, maximum, reaction, useBlue, capped = getReputationProgress(faction);
        local colour = useBlue and core.colours.reputation.blue
            or core.colours.reputation[reaction] or core.colours.reputation.default;

        frame.bar:SetStatusBarColor(colour.r, colour.g, colour.b);
        frame.bar:SetMinMaxValues(0, maximum);
        frame.bar:SetValue(value);
        if capped then
            frame.text:SetText(faction.name);
        else
            frame.text:SetFormattedText("%s  %d / %d (%.1f%%)", faction.name, value, maximum,
                value / maximum * 100);
        end;
        updatePosition();
        frame:Show();
    end;

    frame:SetScript("OnEnter", function()
        update();
        frame.text:Show();
    end);
    frame:SetScript("OnLeave", function()
        frame.text:Hide();
    end);
    frame:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            openReputationTab();
        end;
    end);

    if experienceBar then
        experienceBar:HookScript("OnShow", updatePosition);
        experienceBar:HookScript("OnHide", updatePosition);
    end;

    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterEvent("UPDATE_FACTION");
    -- these only exist on some clients, registering an unknown event throws
    pcall(frame.RegisterEvent, frame, "MAJOR_FACTION_RENOWN_LEVEL_CHANGED");
    pcall(frame.RegisterEvent, frame, "MAJOR_FACTION_UNLOCKED");
    pcall(frame.RegisterEvent, frame, "WATCHED_FACTION_UPDATED");
    frame:SetScript("OnEvent", update);

    update();
    return frame;
end;
