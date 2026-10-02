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
    if InCombatLockdown() or (not UnitExists("target") or not AddOn_TotalRP3.Player.CreateFromUnit("target"):GetProfileID()) then
        return frame.trpframe:Hide();
    end;

    local player = AddOn_TotalRP3.Player.CreateFromUnit("target");
    frame.trpframe:Show();
    local icon = player:GetCustomIcon() or "inv_inscription_scroll";
    frame.trpicon.texture:SetTexture("Interface/icons/" .. icon);

    if player:GetProfile() then
        local glances = player:GetInfo("misc/PE") or {};
        local shownGlanceIcons = {};

        for slot = 1, 5 do
            local glance = glances[tostring(slot)];
            local glanceIcon = frame.trpframe["glanceIcon" .. slot];

            if glance and glance.AC then
                local icon = glance.IC;
                if not icon or icon == "" then
                    icon = "inv_misc_questionmark";
                end;

                glanceIcon.texture:SetTexture("Interface\\ICONS\\" .. icon);

                glanceIcon:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM");
                    GameTooltip:SetText(
                        TRP3_API.utils.str.icon(icon, 30) .. " " .. (glance.TI or "...")
                    );

                    local text = glance.TX;
                    if text then
                        text = TRP3_StringUtil.TrimNewlinesAndSpaces(text);
                        if text ~= "" then
                            GameTooltip:AddLine(text, 1, 1, 1, true);
                        end;
                    end;

                    GameTooltip:Show();
                end);

                glanceIcon:SetScript("OnLeave", function()
                    GameTooltip:Hide();
                end);

                glanceIcon:Show();
                table.insert(shownGlanceIcons, glanceIcon);
            else
                glanceIcon:Hide();
            end;
        end;

        for slot, glanceIcon in ipairs(shownGlanceIcons) do
            core:SetPixelPoint(glanceIcon, "LEFT", frame.trpframe, "LEFT", 28 * slot, 0);
        end;
    end;
end;

local function createTRPWidget()
    frame.trpframe = CreateFrame("Frame", nil, frame);
    core:SetPixelPoint(frame.trpframe, "LEFT", frame, "LEFT", 0, -60);
    core:SetPixelSize(frame.trpframe, 128, 24);

    local trpicon = CreateFrame("Frame", nil, frame.trpframe);
    core:SetPixelPoint(trpicon, "LEFT", frame.trpframe, "LEFT", 0, -2);
    core:SetPixelSize(trpicon, 24, 24);

    trpicon.texture = trpicon:CreateTexture();
    trpicon.texture:SetDrawLayer("ARTWORK");
    core:SetPixelPoint(trpicon.texture, "TOPLEFT", trpicon, "TOPLEFT", core.pixel, -core.pixel);
    core:SetPixelPoint(trpicon.texture, "BOTTOMRIGHT", trpicon, "BOTTOMRIGHT", -core.pixel, core.pixel);
    trpicon.texture:SetTexCoord(core:GetCroppedTexCoords(24, 24));

    trpicon.border = trpicon:CreateTexture();
    core:SetPixelPoint(trpicon.border, "TOPLEFT", trpicon, "TOPLEFT", 0, 0);
    core:SetPixelPoint(trpicon.border, "BOTTOMRIGHT", trpicon, "BOTTOMRIGHT", 0, 0);
    trpicon.border:SetColorTexture(core.colours.black.r, core.colours.black.g, core.colours.black.b);

    frame.trpicon = trpicon;

    for slot = 1, 5 do
        local glanceIcon = CreateFrame("Frame", nil, frame.trpframe);
        core:SetPixelPoint(glanceIcon, "LEFT", frame.trpframe, "LEFT", 28 * slot, 0);
        core:SetPixelSize(glanceIcon, 24, 20);

        glanceIcon.texture = glanceIcon:CreateTexture();
        glanceIcon.texture:SetDrawLayer("ARTWORK");
        core:SetPixelPoint(glanceIcon.texture, "TOPLEFT", glanceIcon, "TOPLEFT", core.pixel, -core.pixel);
        core:SetPixelPoint(glanceIcon.texture, "BOTTOMRIGHT", glanceIcon, "BOTTOMRIGHT", -core.pixel, core.pixel);
        glanceIcon.texture:SetTexCoord(core:GetCroppedTexCoords(24, 20));

        glanceIcon.border = glanceIcon:CreateTexture(nil, "BACKGROUND");
        core:SetPixelPoint(glanceIcon.border, "TOPLEFT", glanceIcon, "TOPLEFT", 0, 0);
        core:SetPixelPoint(glanceIcon.border, "BOTTOMRIGHT", glanceIcon, "BOTTOMRIGHT", 0, 0);
        glanceIcon.border:SetColorTexture(core.colours.black.r, core.colours.black.g, core.colours.black.b);

        frame.trpframe["glanceIcon" .. slot] = glanceIcon;
    end;

    trpicon:SetScript("OnEnter", function()
        GameTooltip_SetDefaultAnchor(GameTooltip, trpicon);
        GameTooltip:ClearAllPoints();
        GameTooltip:AddLine(TRP3_API.loc.BINDING_NAME_TRP3_OPEN_TARGET_PROFILE, 1, 1, 1, 1);
        GameTooltip:SetPoint("BOTTOMLEFT", trpicon, "TOPLEFT", 0, 0);
        GameTooltip:Show();
    end);
    trpicon:SetScript("OnLeave", function() GameTooltip:Hide(); end);
    trpicon:SetScript("OnMouseDown", function() trpicon.texture:SetTexCoord(0, 1, 0, 1); end);
    trpicon:SetScript("OnMouseUp", function()
        trpicon.texture:SetTexCoord(.08, .92, .08, .92);
        TRP3_API.slash.openProfile("target");
    end);
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

        if core.TRP then
            CheckTRP();
        end;
    end);
    return frame;
end;
