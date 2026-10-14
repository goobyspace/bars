local _, core = ...;

-- Hides the default Blizzard experience bar (classic and modern layouts)
local function hideDefaultExperienceBar()
    local function suppressFrame(blizzFrame)
        if not blizzFrame or blizzFrame.barsSuppressed then
            return;
        end;
        blizzFrame.barsSuppressed = true;
        blizzFrame:UnregisterAllEvents();
        blizzFrame:SetAlpha(0);
        blizzFrame:EnableMouse(false);
        hooksecurefunc(blizzFrame, "Show", function(self) self:SetAlpha(0); end);
        hooksecurefunc(blizzFrame, "SetAlpha", function(self, alpha)
            if alpha ~= 0 then
                self:SetAlpha(0);
            end;
        end);
    end;

    suppressFrame(MainMenuExpBar);
    suppressFrame(MainMenuBarMaxLevelBar);
    suppressFrame(MainStatusTrackingBarContainer);
    suppressFrame(StatusTrackingBarManager);
end;

local function isPlayerMaxLevel()
    if IsPlayerAtEffectiveMaxLevel then
        return IsPlayerAtEffectiveMaxLevel();
    end;

    -- idk how classic works and im too lazy to go check so do all of them incase above doesnt work
    local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or MAX_PLAYER_LEVEL;
    return maxLevel and UnitLevel("player") >= maxLevel;
end;

function core:CreateExperienceBar(parent)
    hideDefaultExperienceBar();

    if isPlayerMaxLevel() then
        return;
    end;

    local frame = core:CreateSimpleStatusBar("PlayerExperienceBar", parent, core.width, core.barBgHeight);

    frame.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    frame.bar:SetStatusBarColor(core.colours.experience.r, core.colours.experience.g, core.colours.experience.b);
    frame:EnableMouse(true);

    local function createPreviewBar(previewColour)
        local bar = CreateFrame("StatusBar", nil, frame);
        bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
        bar:SetStatusBarColor(previewColour.r, previewColour.g, previewColour.b);
        bar:SetMinMaxValues(0, 1);
        bar:SetValue(1);
        return bar;
    end;

    frame.restedBar = createPreviewBar(core.colours.restedExperience);
    frame.questBar = createPreviewBar(core.colours.questExperience);
    frame.questBar:SetFrameLevel(frame.restedBar:GetFrameLevel() + 1);

    local dividerFrame = CreateFrame("Frame", nil, frame);
    dividerFrame:SetAllPoints(frame.bar);
    dividerFrame:SetFrameLevel(frame.questBar:GetFrameLevel() + 2);
    local dividers = {};
    for index = 1, 19 do
        local notches = {};
        for key = 1, 2 do
            local notch = dividerFrame:CreateTexture(nil, "OVERLAY", nil, 7);
            notch:SetColorTexture(core.colours.experienceDivider.r, core.colours.experienceDivider.g,
                core.colours.experienceDivider.b, core.colours.experienceDivider.a);
            notches[key] = notch;
        end;
        dividers[index] = notches;
    end;

    local function updateDividers(_, width)
        local notchHeight = frame.bar:GetHeight() / 2;
        for index, notches in ipairs(dividers) do
            local offset = width * index / 20;
            notches[1]:ClearAllPoints();
            core:SetPixelPoint(notches[1], "TOPLEFT", frame.bar, "TOPLEFT", offset, 0);
            core:SetPixelSize(notches[1], core.pixel, notchHeight);
            notches[2]:ClearAllPoints();
            core:SetPixelPoint(notches[2], "BOTTOMLEFT", frame.bar, "BOTTOMLEFT", offset, 0);
            core:SetPixelSize(notches[2], core.pixel, notchHeight);
        end;
    end;

    frame.bar:HookScript("OnSizeChanged", updateDividers);
    updateDividers(frame.bar, frame.bar:GetWidth());

    frame.text = dividerFrame:CreateFontString(nil, "OVERLAY");
    frame.text:SetPoint("CENTER");
    core:SetBarFont(frame.text, 12);
    frame.text:Hide();

    frame.completedText = dividerFrame:CreateFontString(nil, "OVERLAY");
    frame.completedText:SetPoint("LEFT", frame.bar, "LEFT", core.pixel, 0);
    frame.completedText:SetJustifyH("LEFT");
    core:SetBarFont(frame.completedText, 10);
    frame.completedText:Hide();

    frame.restedText = dividerFrame:CreateFontString(nil, "OVERLAY");
    frame.restedText:SetPoint("RIGHT", frame.bar, "RIGHT", -core.pixel, 0);
    frame.restedText:SetJustifyH("RIGHT");
    core:SetBarFont(frame.restedText, 10);
    frame.restedText:Hide();

    local function getCompletedQuestXP()
        local total = 0;

        -- GetQuestLogRewardXP(questID) is a global; it is not part of C_QuestLog
        local getRewardXP = (C_QuestLog and C_QuestLog.GetQuestLogRewardXP) or GetQuestLogRewardXP;
        if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo and getRewardXP then
            for index = 1, C_QuestLog.GetNumQuestLogEntries() do
                local questInfo = C_QuestLog.GetInfo(index);
                if questInfo and questInfo.questID and not questInfo.isHeader then
                    local isComplete = questInfo.isComplete
                        or (C_QuestLog.IsComplete and C_QuestLog.IsComplete(questInfo.questID))
                        or (C_QuestLog.ReadyForTurnIn and C_QuestLog.ReadyForTurnIn(questInfo.questID));
                    if isComplete then
                        total = total + (getRewardXP(questInfo.questID) or 0);
                    end;
                end;
            end;
        elseif GetNumQuestLogEntries and GetQuestLogTitle and GetQuestLogRewardXP then
            -- Legacy GetQuestLogRewardXP takes no argument and reads the selected entry
            local selected = GetQuestLogSelection and GetQuestLogSelection();
            for index = 1, GetNumQuestLogEntries() do
                local _, _, _, isHeader, _, isComplete = GetQuestLogTitle(index);
                if not isHeader and isComplete == 1 and SelectQuestLogEntry then
                    SelectQuestLogEntry(index);
                    total = total + (GetQuestLogRewardXP() or 0);
                end;
            end;
            if selected and SelectQuestLogEntry then
                SelectQuestLogEntry(selected);
            end;
        end;

        return total;
    end;

    local function updatePreviewBar(bar, amount, currentXP, maximumXP)
        local endXP = math.min(maximumXP, currentXP + amount);
        if endXP <= currentXP then
            bar:Hide();
            return;
        end;

        local barWidth = frame.bar:GetWidth();
        local startOffset = barWidth * currentXP / maximumXP;
        local endOffset = barWidth * endXP / maximumXP;
        bar:ClearAllPoints();
        core:SetPixelPoint(bar, "TOPLEFT", frame.bar, "TOPLEFT", startOffset, 0);
        core:SetPixelPoint(bar, "BOTTOMRIGHT", frame.bar, "BOTTOMLEFT", endOffset, 0);
        bar:Show();
    end;

    local function update()
        local currentXP = UnitXP("player");
        local maximumXP = UnitXPMax("player");
        if not maximumXP or maximumXP <= 0 then
            frame:Hide();
            frame.text:Hide();
            frame.completedText:Hide();
            frame.restedText:Hide();
            frame.restedBar:Hide();
            frame.questBar:Hide();
            return;
        end;

        local restedXP = GetXPExhaustion() or 0;
        local completedQuestXP = getCompletedQuestXP();
        frame.bar:SetMinMaxValues(0, maximumXP);
        frame.bar:SetValue(currentXP);
        updatePreviewBar(frame.restedBar, restedXP, currentXP, maximumXP);
        updatePreviewBar(frame.questBar, completedQuestXP, currentXP, maximumXP);
        frame.text:SetFormattedText("%d / %d (%.1f%%)", currentXP, maximumXP,
            currentXP / maximumXP * 100);
        frame.completedText:SetFormattedText("(|cffffd100%.0f%%|r)",
            completedQuestXP / maximumXP * 100);
        frame.restedText:SetFormattedText("(|cff66ccff%.0f%%|r)",
            restedXP / maximumXP * 100);
        frame:Show();
    end;

    frame:SetScript("OnEnter", function()
        update();
        frame.text:Show();
        frame.completedText:Show();
        frame.restedText:Show();
    end);
    frame:SetScript("OnLeave", function()
        frame.text:Hide();
        frame.completedText:Hide();
        frame.restedText:Hide();
    end);

    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterEvent("PLAYER_XP_UPDATE");
    frame:RegisterEvent("PLAYER_LEVEL_UP");
    frame:RegisterEvent("UPDATE_EXHAUSTION");
    frame:RegisterEvent("PLAYER_UPDATE_RESTING");
    frame:RegisterEvent("QUEST_LOG_UPDATE");
    frame:RegisterEvent("QUEST_ACCEPTED");
    frame:RegisterEvent("QUEST_TURNED_IN");
    frame:SetScript("OnEvent", update);

    update();
    return frame;
end;
