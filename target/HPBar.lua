local _, core = ...;

local frame;

local difficultyKeys = { "trivial", "standard", "difficult", "verydifficult", "impossible" };

local function getLevelDifficultyColour(unit)
    local colours = core.colours.levelDifficulty;
    local getContentDifficulty = C_PlayerInfo and C_PlayerInfo.GetContentDifficultyCreatureForPlayer;
    if getContentDifficulty and Enum and Enum.RelativeContentDifficulty then
        local difficulty = getContentDifficulty(unit);
        if difficulty == Enum.RelativeContentDifficulty.Trivial then return colours.trivial; end;
        if difficulty == Enum.RelativeContentDifficulty.Easy then return colours.standard; end;
        if difficulty == Enum.RelativeContentDifficulty.Fair then return colours.difficult; end;
        if difficulty == Enum.RelativeContentDifficulty.Difficult then return colours.verydifficult; end;
        if difficulty == Enum.RelativeContentDifficulty.Impossible then return colours.impossible; end;
        return colours.difficult;
    end;

    local level = UnitLevel(unit);
    if level == -1 then return colours.impossible; end;

    -- we want to use a custom colour for this :3
    local blizzColour = GetQuestDifficultyColor(level);
    for _, key in ipairs(difficultyKeys) do
        if QuestDifficultyColors[key] == blizzColour then
            return colours[key];
        end;
    end;
    return colours.difficult;
end;

local function updateBar(immediate)
    if not frame then return; end;

    local isPlayer = UnitIsPlayer("target");
    local threat = UnitThreatSituation("player", "target");
    if isPlayer then
        local _, name, _ = UnitClass("target");
        if name then
            local color = C_ClassColor.GetClassColor(name);
            frame.bar:SetStatusBarColor(color:GetRGB());
        end;
    elseif threat ~= nil or UnitIsEnemy("player", "target") then
        frame.bar:SetStatusBarColor(core.ClassColors["hostile"].r, core.ClassColors["hostile"].g,
            core.ClassColors["hostile"].b);
    elseif UnitIsFriend("player", "target") then
        frame.bar:SetStatusBarColor(core.ClassColors["friendly"].r, core.ClassColors["friendly"].g,
            core.ClassColors["friendly"].b);
    else
        frame.bar:SetStatusBarColor(core.ClassColors["neutral"].r, core.ClassColors["neutral"].g,
            core.ClassColors["neutral"].b);
    end;

    local currentHP, maxHP = core:UpdateHPBarValues(frame, "target", immediate);
    if not maxHP then
        return;
    end;

    frame.hpText:SetText(AbbreviateNumbers(currentHP));
    frame.name:SetText(core.isForever and _G.GetUnitName("target", true) or UnitName("target"));
    local function levelText()
        if UnitLevel("target") == -1 then return "??"; else return tostring(UnitLevel("target")); end;
    end;
    frame.level:SetText(levelText());
    local levelColour = getLevelDifficultyColour("target");
    frame.level:SetTextColor(levelColour.r, levelColour.g, levelColour.b);
end;

function core:CreateTargetHPBar(parent)
    frame = core:CreateHPBarBase("TargetHPBarContainer", parent, core.width, core.barBgHeight);
    core:AddMouseoverBorder(frame, parent.click, "target");

    frame.hpText = frame.bar:CreateFontString("PrimaryText");
    frame.hpText:SetDrawLayer("OVERLAY", 1);
    frame.hpText:SetPoint("LEFT", 0, core.labelAboveBar);
    core:SetBarFont(frame.hpText, 12);

    frame.level = frame.bar:CreateFontString("PrimaryText");
    frame.level:SetDrawLayer("OVERLAY", 1);
    frame.level:SetPoint("RIGHT", 0, core.labelAboveBar);
    core:SetBarFont(frame.level, 12);

    frame.name = frame.bar:CreateFontString("PrimaryText");
    frame.name:SetDrawLayer("OVERLAY", 1);
    frame.name:SetPoint("CENTER", 0, core.labelAboveBar);
    core:SetBarFont(frame.name, 12);

    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterUnitEvent("PLAYER_TARGET_CHANGED");
    frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "target");
    frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "target");
    frame:RegisterUnitEvent("UNIT_HEALTH", "target");
    frame:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", "target");
    frame:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "target");
    frame:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "target");
    frame:RegisterUnitEvent("UNIT_TARGETABLE_CHANGED", "target");
    frame:RegisterUnitEvent("UNIT_THREAT_LIST_UPDATE", "target");
    frame:RegisterUnitEvent("PLAYER_TARGET_DIED");
    frame:RegisterUnitEvent("UNIT_LEVEL", "target");
    frame:RegisterEvent("PLAYER_LEVEL_UP");
    frame:RegisterEvent("PET_BATTLE_OPENING_START");
    frame:RegisterEvent("PET_BATTLE_CLOSE");

    local playerClass = select(2, UnitClass("target"));

    if playerClass == "DRUID" then
        frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM");
    end;

    frame:SetScript("OnEvent", function(_, event)
        updateBar(event == "PLAYER_TARGET_CHANGED");
    end);

    return frame;
end;
