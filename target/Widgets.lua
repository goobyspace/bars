local _, core = ...;

local frame;

local function checkAfk()
    frame.afk:SetAlphaFromBoolean(UnitIsAFK("player"));
end


local function checkPvP()
    frame.pvp:SetAlphaFromBoolean(UnitIsPVP("target"))
end

local function checkQuest()
    local isQuestTarget = UnitIsQuestBoss("target")
    if not isQuestTarget and C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest then
        isQuestTarget = C_QuestLog.UnitIsRelatedToActiveQuest("target")
    end
    frame.questIcon:SetShown(isQuestTarget and true or false)
end

local function checkRareElite()
    local classification = UnitClassification("target");
    if classification == "elite" or classification == "worldboss" then
        frame.elite:Show()
        frame.rare:Hide()
        frame.rareelite:Hide()
    elseif classification == "rare" then
        frame.elite:Hide()
        frame.rare:Show()
        frame.rareelite:Hide()
    elseif classification == "rareelite" then
        frame.elite:Hide()
        frame.rare:Hide()
        frame.rareelite:Show()
    else
        frame.elite:Hide()
        frame.rare:Hide()
        frame.rareelite:Hide()
    end
end

function core:CreateTargetWidgets(parent, hpBar)
    frame = CreateFrame("Frame", nil, parent);
    frame:SetSize(core.width, 1);

    local levelAnchor = hpBar and hpBar.level or parent;

    frame.afk = frame:CreateTexture();
    frame.afk:SetPoint("CENTER", -180, -10);
    frame.afk:SetTexture("Interface/Addons/Bars/assets/afk.png");
    frame.afk:SetSize(16, 16);

    frame.pvp = frame:CreateTexture();
    frame.pvp:SetPoint("CENTER", 180, -10);
    frame.pvp:SetTexture("Interface/Addons/Bars/assets/pvp.png");
    frame.pvp:SetSize(16, 16);

    frame.questIcon = frame:CreateTexture(nil, "OVERLAY")
    frame.questIcon:SetTexture("Interface/Addons/Bars/assets/quest.png")
    frame.questIcon:SetSize(10, 17)
    frame.questIcon:SetPoint("TOPLEFT", levelAnchor, "TOPRIGHT", -4, 0)
    frame.questIcon:Hide()

    frame.elite = frame:CreateTexture();
    frame.elite:SetPoint("CENTER", levelAnchor, "CENTER", 4, 0);
    frame.elite:SetTexture("Interface/Addons/Bars/assets/elite.png");
    frame.elite:SetSize(33, 27);

    frame.rare = frame:CreateTexture();
    frame.rare:SetPoint("CENTER", levelAnchor, "CENTER", 4, 0);
    frame.rare:SetTexture("Interface/Addons/Bars/assets/rare.png");
    frame.rare:SetSize(33, 27);

    frame.rareelite = frame:CreateTexture();
    frame.rareelite:SetPoint("CENTER", levelAnchor, "CENTER", 4, 0);
    frame.rareelite:SetTexture("Interface/Addons/Bars/assets/rare elite.png");
    frame.rareelite:SetSize(33, 27);

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterUnitEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", "target")
    frame:RegisterUnitEvent("PVP_TIMER_UPDATE", "target")
    frame:RegisterUnitEvent("PLAYER_TARGET_DIED")
    frame:RegisterEvent("QUEST_LOG_UPDATE")
    frame:RegisterEvent("PET_BATTLE_OPENING_START")
    frame:RegisterEvent("PET_BATTLE_CLOSE")

    frame:HookScript("OnEvent", function(_, _)
        checkRareElite();
        checkAfk();
        checkPvP();
        checkQuest();
    end)
    return frame;
end
