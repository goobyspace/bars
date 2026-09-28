local _, core = ...;

local function configurePingableUnitFrame(frame, unit, isPlayer)
    frame.unit = unit;
    frame:SetAttribute("unit", unit);
    frame:SetAttribute("ping-receiver", true);

    function frame:GetIsPingable()
        return true;
    end;

    function frame:GetAllowRadialWheel()
        return true;
    end;

    function frame:GetTargetInfo()
        local guid = UnitGUID(self.unit);
        -- if guid is secret in combat we do a generic ping instead
        if issecretvalue and issecretvalue(guid) then
            guid = nil;
        end;

        local targetInfo = {
            guid = guid,
        };

        if isPlayer then
            targetInfo.isPlayerResource = true;
        end;

        return targetInfo;
    end;
end;

function core:AddUnitTooltip(button, unit)
    button:HookScript("OnEnter", function(self)
        if not UnitExists(unit) then return; end;
        GameTooltip_SetDefaultAnchor(GameTooltip, self);
        GameTooltip:SetUnit(unit);
        GameTooltip:Show();
    end);
    button:HookScript("OnLeave", function()
        GameTooltip:Hide();
    end);
end;

function core:InitializeBarFrames()
    core.pixel = core:GetPixelUnit();
    core.barHeight = (core.thickMode and 10 or 3) * core.pixel;
    core.barBgHeight = core.barHeight + 2 * core.pixel;
    core.fontScale = core.thickMode and 1.5 or 1;
    core.castbarHeight = core.thickMode and 28 or 16;
    core.barGrowth = core.barBgHeight - 5 * core.pixel;
    core.labelAboveBar = 10 * core.fontScale + core.barGrowth / 2;
    core.labelBelowBar = -(8 * core.fontScale + core.barGrowth / 2);

    core.rowGap = 4 * core.pixel;
    core.rowStep = core.barBgHeight + core.rowGap;
    core.primaryBarOffset = core.rowGap;
    core.hpRowOffset = core.primaryBarOffset + 2 * core.rowStep;
    core.targetHpRowOffset = -16;
    local targetTextTop = core.targetHpRowOffset - core.barBgHeight / 2 + core.labelAboveBar
        + math.floor(12 * core.fontScale + 0.5) / 2;
    core.targetHpRowOffset = core.targetHpRowOffset - core:EvenPixels(targetTextTop + 2 * core.pixel);
    core.targetResourceRowOffset = core.targetHpRowOffset - core.barBgHeight - core.rowGap;

    core.width = core:EvenPixels(340);
    core.playerHeight = core:EvenPixels(core.hpRowOffset + 2 * core.rowStep + core.barBgHeight);
    core.targetHeight = core:EvenPixels(-core.targetResourceRowOffset + core.barBgHeight + 2 * core.pixel);
    core.playerFrameY = -244;
    core.frameGap = 43;
    core.targetFrameY = core.playerFrameY + core.hpRowOffset + 2 * core.barBgHeight + core.frameGap
        - core.targetResourceRowOffset;

    -- playerframe
    do
        PlayerFrame:SetScript("OnEvent", nil);
        PlayerFrame:Hide();

        local function disableBlizzardResourceFrame(resourceFrame)
            if not resourceFrame then return; end;
            resourceFrame:SetScript("OnEvent", nil);
            resourceFrame:Hide();
            resourceFrame:HookScript("OnShow", function(self)
                self:Hide();
            end);
        end;

        disableBlizzardResourceFrame(ComboFrame);
        disableBlizzardResourceFrame(PlayerFrame.classPowerBar);

        local playerFrame = CreateFrame("Frame", "PlayerFrameContainer", UIParent, "SecureHandlerStateTemplate");
        core:SetPixelSize(playerFrame, core.width, core.playerHeight);
        core:SetPixelPoint(playerFrame, "BOTTOM", UIParent, "CENTER", 0, core.playerFrameY);
        core:SnapToPixelGrid(playerFrame);
        configurePingableUnitFrame(playerFrame, "player", true);

        playerFrame.click = CreateFrame("Button", "PlayerFrameClick", playerFrame, "SecureActionButtonTemplate");
        playerFrame.click:SetPoint("CENTER");
        core:SetPixelSize(playerFrame.click, core.width, core.playerHeight);

        if core.Debug then
            playerFrame.bg = playerFrame:CreateTexture();
            playerFrame.bg:SetPoint("CENTER");
            playerFrame.bg:SetColorTexture(0, 1, 0, 0.5);
            core:SetPixelSize(playerFrame.bg, core.width, core.playerHeight);
        end;

        playerFrame.click:SetAttribute("unit", "player");
        playerFrame.click:SetAttribute("type1", "target");
        playerFrame.click:SetAttribute("type2", "togglemenu");
        playerFrame.click:RegisterForClicks("AnyUp", "AnyDown");
        configurePingableUnitFrame(playerFrame.click, "player", true);
        core:AddUnitTooltip(playerFrame.click, "player");

        local widgets = core:CreateWidgets(playerFrame);
        widgets:SetPoint("BOTTOM");

        local primaryResourceBar = core:CreatePrimaryBar(playerFrame);
        core:SetPixelPoint(primaryResourceBar, "BOTTOM", playerFrame, "BOTTOM", 0, core.primaryBarOffset);
        core:SnapToPixelGrid(primaryResourceBar);

        local secondaryResourceBar = core:CreateSecondaryBar(playerFrame);
        local tertiaryResourceBar = core:CreateTertiaryBar(playerFrame);

        local swingTimer = core.CreateSwingTimer and core:CreateSwingTimer(playerFrame);

        local castbar = core:CreatePlayerCastbar(playerFrame);
        core:SetPixelPoint(castbar, "TOP", playerFrame, "BOTTOM", 0, core.playerCastbarOffsetY);

        local flightPathTimer = core:CreateFlightPathTimer(playerFrame);
        core:SetPixelPoint(flightPathTimer, "TOP", playerFrame, "BOTTOM", 0, core.playerCastbarOffsetY);

        core:CreateBreathBar(UIParent);

        if core.CreateAuraTracker then
            local auraTracker = core:CreateAuraTracker(playerFrame);
            core:SetPixelPoint(auraTracker, "TOP", playerFrame, "BOTTOM", 0, -2);
        end;

        local hpBar = core:CreateHPBar(playerFrame);
        local petFrame = core:CreatePetFrame(playerFrame);

        local secondaryShown = false;
        local tertiaryShown = false;
        local petShown = false;
        local layoutPending = false;

        local function updateLayout()
            local canMovePet = not InCombatLockdown();
            if not canMovePet then
                layoutPending = true;
            end;

            local offset = core.primaryBarOffset + core.rowStep;

            if secondaryShown then
                core:SetPixelPoint(secondaryResourceBar, "BOTTOM", playerFrame, "BOTTOM", 0,
                    core.primaryBarOffset + core.rowStep);
                offset = offset + core.rowStep;
            end;

            core:SetPixelPoint(hpBar, "BOTTOM", playerFrame, "BOTTOM",
                (core.width - hpBar:GetWidth()) / 2, offset);

            core:SetPixelPoint(tertiaryResourceBar, "BOTTOM", playerFrame, "BOTTOM",
                -(core.width - tertiaryResourceBar:GetWidth()) / 2, offset);

            local petOffset = offset + (tertiaryShown and core.rowStep or 0);

            if canMovePet then
                core:SetPixelPoint(petFrame, "BOTTOM", playerFrame, "BOTTOM", -core.width / 6, petOffset);
            end;

            if swingTimer then
                core:SetPixelPoint(swingTimer, "BOTTOM", playerFrame, "BOTTOM", -core.width / 6,
                    petShown and (petOffset + core.rowStep) or petOffset);
            end;

            core:SnapToPixelGrid(secondaryResourceBar);
            core:SnapToPixelGrid(hpBar);
            core:SnapToPixelGrid(tertiaryResourceBar);
            if canMovePet then
                core:SnapToPixelGrid(petFrame);
            end;
            core:SnapToPixelGrid(swingTimer);
        end;

        local layoutRetryFrame = CreateFrame("Frame");
        layoutRetryFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
        layoutRetryFrame:SetScript("OnEvent", function()
            if layoutPending then
                layoutPending = false;
                updateLayout();
            end;
        end);

        petShown = petFrame:IsShown();
        petFrame:HookScript("OnShow", function()
            petShown = true;
            updateLayout();
        end);
        petFrame:HookScript("OnHide", function()
            petShown = false;
            updateLayout();
        end);

        if secondaryResourceBar then
            function secondaryResourceBar:SetHidden(hidden)
                if hidden then
                    secondaryResourceBar:Hide();
                    secondaryShown = false;
                else
                    secondaryResourceBar:Show();
                    secondaryShown = true;
                end;
                updateLayout();
            end;
        end;

        if tertiaryResourceBar then
            function tertiaryResourceBar:SetHidden(hidden)
                if hidden then
                    tertiaryResourceBar:Hide();
                    tertiaryShown = false;
                else
                    tertiaryResourceBar:Show();
                    tertiaryShown = true;
                end;
                updateLayout();
            end;
        end;

        updateLayout();
    end;

    --targetframe
    do
        TargetFrame:SetScript("OnEvent", nil);
        TargetFrame:Hide();

        local targetFrame = CreateFrame("Frame", "TargetFrameContainer", UIParent, "SecureHandlerStateTemplate");
        core:SetPixelSize(targetFrame, core.width, core.targetHeight);
        core:SetPixelPoint(targetFrame, "TOP", UIParent, "CENTER", 0, core.targetFrameY);
        core:SnapToPixelGrid(targetFrame);
        configurePingableUnitFrame(targetFrame, "target");

        targetFrame.click = CreateFrame("Button", "TargetFrameClick", targetFrame, "SecureActionButtonTemplate");
        targetFrame.click:SetPoint("CENTER");
        core:SetPixelSize(targetFrame.click, core.width, core.targetHeight);

        if core.Debug then
            targetFrame.bg = targetFrame:CreateTexture();
            targetFrame.bg:SetPoint("CENTER");
            targetFrame.bg:SetColorTexture(0, 0, 1, 0.5);
            core:SetPixelSize(targetFrame.bg, core.width, core.targetHeight);
        end;

        targetFrame.click:SetAttribute("unit", "target");
        targetFrame.click:SetAttribute("type1", "target");
        targetFrame.click:SetAttribute("type2", "togglemenu");
        targetFrame.click:RegisterForClicks("AnyUp", "AnyDown");
        configurePingableUnitFrame(targetFrame.click, "target");
        core:AddUnitTooltip(targetFrame.click, "target");

        local hpBar = core:CreateTargetHPBar(targetFrame);
        core:SetPixelPoint(hpBar, "TOP", targetFrame, "TOP", 0, core.targetHpRowOffset);
        core:SnapToPixelGrid(hpBar);

        local widgets = core:CreateTargetWidgets(targetFrame, hpBar);
        widgets:SetPoint("TOP");

        local primaryResourceBar = core:CreateTargetResourceBar(targetFrame);
        core:SetPixelPoint(primaryResourceBar, "TOPLEFT", targetFrame, "TOPLEFT", 0, core.targetResourceRowOffset);
        core:SnapToPixelGrid(primaryResourceBar);

        local targetOfTargetBar = core:CreateTargetTargetHPBar(targetFrame);
        core:SetPixelPoint(targetOfTargetBar, "TOPRIGHT", targetFrame, "TOPRIGHT", 0, core.targetResourceRowOffset);
        core:SnapToPixelGrid(targetOfTargetBar);

        local castbar = core:CreateTargetCastbar(targetFrame);
        core:SetPixelPoint(castbar, "BOTTOM", targetFrame, "TOP", 0,
            4 * core.fontScale + core.barGrowth);

        local BigDebuffs = core:CreateImportantDebuffsFrame(targetFrame);
        core:SetPixelPoint(BigDebuffs, "TOPRIGHT", hpBar.hpText, "TOPLEFT", -4, 0);

        local mainBuffs = core:CreateMainBuffsFrame(targetFrame);
        core:SetPixelPoint(mainBuffs, "TOPLEFT", hpBar, "TOPRIGHT", 4, -7);

        local normalDebuffs = core:CreateNormalDebuffsFrame(targetFrame);
        core:SetPixelPoint(normalDebuffs, "BOTTOMLEFT", mainBuffs, "TOPLEFT", 0, 8);

        -- taint safe way to hide/show this depending on target
        targetFrame:SetAttribute("unit", "target");
        RegisterUnitWatch(targetFrame, false);
    end;
end;
