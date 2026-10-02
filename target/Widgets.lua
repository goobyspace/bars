local _, core = ...;

local frame;

local function checkAfk()
    frame.afk:SetAlphaFromBoolean(UnitIsAFK("player"));
end;


local function checkPvP()
    frame.pvp:SetAlphaFromBoolean(UnitIsPVP("target"));
end;

local function checkQuest()
    local isQuestTarget = UnitIsQuestBoss and UnitIsQuestBoss("target");
    if not isQuestTarget and C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest then
        isQuestTarget = C_QuestLog.UnitIsRelatedToActiveQuest("target");
    end;
    frame.questIcon:SetShown(isQuestTarget and true or false);
end;

local function checkRareElite()
    local classification = UnitClassification("target");
    if classification == "elite" or classification == "worldboss" then
        frame.elite:Show();
        frame.rare:Hide();
        frame.rareelite:Hide();
    elseif classification == "rare" then
        frame.elite:Hide();
        frame.rare:Show();
        frame.rareelite:Hide();
    elseif classification == "rareelite" then
        frame.elite:Hide();
        frame.rare:Hide();
        frame.rareelite:Show();
    else
        frame.elite:Hide();
        frame.rare:Hide();
        frame.rareelite:Hide();
    end;
end;

local function CheckTRP()
    if not UnitExists("target") or not AddOn_TotalRP3.Player.CreateFromUnit("target"):GetProfileID() then
        return frame.trpframe:Hide();
    end;

    local player = AddOn_TotalRP3.Player.CreateFromUnit("target");
    frame.trpframe:Show();
    frame.trpicon:Show();
    local icon = player:GetCustomIcon() or "inv_inscription_scroll";
    frame.trpicon:SetTexture("Interface/icons/" .. icon);
end;

local function createTRPWidget()
    frame.trpframe = CreateFrame("Frame", nil, frame);
    core:SetPixelPoint(frame.trpframe, "LEFT", frame, "LEFT", 0, -64);
    core:SetPixelSize(frame.trpframe, 128, 24);

    frame.trpicon = frame.trpframe:CreateTexture();
    core:SetPixelPoint(frame.trpicon, "LEFT", frame.trpframe, "LEFT", 0, 0);
    frame.trpicon:SetTexture("Interface/Addons/Bars/assets/afk.png");
    core:SetPixelSize(frame.trpicon, 32, 32);
end;

function core:CreateTargetWidgets(parent, hpBar)
    frame = CreateFrame("Frame", nil, parent);
    core:SetPixelSize(frame, core.width, core.pixel);

    local levelAnchor = hpBar and hpBar.level or parent;

    frame.afk = frame:CreateTexture();
    core:SetPixelPoint(frame.afk, "CENTER", frame, "CENTER", -180, -10);
    frame.afk:SetTexture("Interface/Addons/Bars/assets/afk.png");
    core:SetPixelSize(frame.afk, 16, 16);

    frame.pvp = frame:CreateTexture();
    core:SetPixelPoint(frame.pvp, "CENTER", frame, "CENTER", 180, -10);
    frame.pvp:SetTexture("Interface/Addons/Bars/assets/pvp.png");
    core:SetPixelSize(frame.pvp, 16, 16);

    frame.questIcon = frame:CreateTexture(nil, "OVERLAY");
    frame.questIcon:SetTexture("Interface/Addons/Bars/assets/quest.png");
    core:SetPixelSize(frame.questIcon, 10, 19);
    core:SetPixelPoint(frame.questIcon, "TOPLEFT", levelAnchor, "TOPRIGHT", -4, 1);
    frame.questIcon:Hide();

    frame.elite = frame:CreateTexture();
    core:SetPixelPoint(frame.elite, "CENTER", levelAnchor, "CENTER", 4, 0);
    frame.elite:SetTexture("Interface/Addons/Bars/assets/elite.png");
    core:SetPixelSize(frame.elite, 33, 27);

    frame.rare = frame:CreateTexture();
    core:SetPixelPoint(frame.rare, "CENTER", levelAnchor, "CENTER", 4, 0);
    frame.rare:SetTexture("Interface/Addons/Bars/assets/rare.png");
    core:SetPixelSize(frame.rare, 33, 27);

    frame.rareelite = frame:CreateTexture();
    core:SetPixelPoint(frame.rareelite, "CENTER", levelAnchor, "CENTER", 4, 0);
    frame.rareelite:SetTexture("Interface/Addons/Bars/assets/rare elite.png");
    core:SetPixelSize(frame.rareelite, 33, 27);

    if core.TRP then
        createTRPWidget();
    end;

    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterUnitEvent("PLAYER_TARGET_CHANGED");
    frame:RegisterUnitEvent("PLAYER_FLAGS_CHANGED", "target");
    frame:RegisterUnitEvent("PVP_TIMER_UPDATE", "target");
    frame:RegisterUnitEvent("PLAYER_TARGET_DIED");
    frame:RegisterEvent("QUEST_LOG_UPDATE");
    frame:RegisterEvent("PET_BATTLE_OPENING_START");
    frame:RegisterEvent("PET_BATTLE_CLOSE");

    frame:HookScript("OnEvent", function(_, _)
        checkRareElite();
        checkAfk();
        checkPvP();
        checkQuest();
        CheckTRP();
    end);
    return frame;
end;
