local _, core = ...

local function configurePingableUnitFrame(frame, unit, isPlayer)
    frame.unit = unit;
    frame:SetAttribute("unit", unit);
    frame:SetAttribute("ping-receiver", true);

    function frame:GetIsPingable()
        return true;
    end

    function frame:GetAllowRadialWheel()
        return true;
    end

    function frame:GetTargetInfo()
        local targetInfo = {
            guid = UnitGUID(self.unit),
        };

        if isPlayer then
            targetInfo.isPlayerResource = true;
        end

        return targetInfo;
    end
end

function core:InitializeBarFrames()
    -- core variables before anything else
    core.width = 340;
    core.playerHeight = 36;
    core.targetHeight = 28;

    -- playerframe
    do
        -- hide defaults
        PlayerFrame:SetScript("OnEvent", nil);
        PlayerFrame:Hide();

        local playerFrame = CreateFrame("Frame", "PlayerFrameContainer", UIParent, "SecureHandlerStateTemplate")
        playerFrame:SetSize(core.width, core.playerHeight);
        playerFrame:SetPoint("CENTER", 0, -176);
        configurePingableUnitFrame(playerFrame, "player", true);

        -- debug BG to show the size of click frame
        -- playerFrame.bg = playerFrame:CreateTexture();
        -- playerFrame.bg:SetPoint("CENTER");
        -- playerFrame.bg:SetColorTexture(0, 0, 0, 0.1);
        -- playerFrame.bg:SetSize(core.width, core.playerHeight);

        playerFrame.click = CreateFrame("Button", "PlayerFrameClick", playerFrame, "SecureActionButtonTemplate")
        playerFrame.click:SetPoint("CENTER");
        playerFrame.click:SetSize(core.width, core.playerHeight);
        playerFrame.click:SetAttribute("unit", "player")
        playerFrame.click:SetAttribute("type1", "target")
        playerFrame.click:SetAttribute("type2", "togglemenu")
        playerFrame.click:RegisterForClicks("AnyUp", "AnyDown")
        configurePingableUnitFrame(playerFrame.click, "player", true);

        local widgets = core:CreateWidgets(playerFrame);
        widgets:SetPoint("BOTTOM")

        local primaryResourceBar = core:CreatePrimaryBar(playerFrame)
        primaryResourceBar:SetPoint("BOTTOM")

        local secondaryResourceBar = core:CreateSecondaryBar(playerFrame);
        local tertiaryResourceBar = core:CreateTertiaryBar(playerFrame);

        local castbar = core:CreatePlayerCastbar(playerFrame)
        castbar:SetPoint("CENTER", 0, -74)

        -- Classic Era only feature, so the constructor is absent on retail
        if core.CreateAuraTracker then
            local auraTracker = core:CreateAuraTracker(playerFrame)
            auraTracker:SetPoint("TOP", playerFrame, "BOTTOM", 0, -2)
        end

        local hpBar = core:CreateHPBar(playerFrame);
        local petFrame = core:CreatePetFrame(playerFrame);

        local secondaryShown = false;
        local tertiaryShown = false;
        local layoutPending = false;

        local function updateLayout()
            -- petFrame is protected (secure handler + RegisterUnitWatch); repositioning it is
            -- blocked while in combat, so defer until PLAYER_REGEN_ENABLED fires
            if InCombatLockdown() then
                layoutPending = true;
                return;
            end

            -- 13 is the line height for a single resource bar row, plus a little extra breathing
            -- room so the (now taller, name+text) pet frame doesn't feel cramped against it
            local offset = 13;

            if secondaryShown then
                secondaryResourceBar:SetPoint("BOTTOM", 0, 9);
                offset = offset + 9;
            end

            -- 34 is half of the HP bars total size
            hpBar:SetPoint("BOTTOM", core.width / 3, offset);

            -- tertiary resource shares the HP bar's line, mirroring its width, aligned left
            tertiaryResourceBar:SetPoint("BOTTOM", -core.width / 3, offset);

            -- pet sits on the same line as the HP bar, unless a tertiary resource is
            -- taking up that line, in which case it moves up one line to stay clear of it
            if tertiaryShown then
                petFrame:SetPoint("BOTTOM", -core.width / 3, offset + 9);
            else
                petFrame:SetPoint("BOTTOM", -core.width / 3, offset);
            end
        end

        local layoutRetryFrame = CreateFrame("Frame")
        layoutRetryFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        layoutRetryFrame:SetScript("OnEvent", function()
            if layoutPending then
                layoutPending = false;
                updateLayout();
            end
        end)

        if secondaryResourceBar then
            function secondaryResourceBar:SetHidden(hidden)
                if hidden then
                    secondaryResourceBar:Hide();
                    secondaryShown = false;
                else
                    secondaryResourceBar:Show();
                    secondaryShown = true;
                end
                updateLayout();
            end
        end

        if tertiaryResourceBar then
            function tertiaryResourceBar:SetHidden(hidden)
                if hidden then
                    tertiaryResourceBar:Hide();
                    tertiaryShown = false;
                else
                    tertiaryResourceBar:Show();
                    tertiaryShown = true;
                end
                updateLayout();
            end
        end

        updateLayout();
    end

    -- targetframe
    do
        -- hide defaults
        TargetFrame:SetScript("OnEvent", nil);
        TargetFrame:Hide();

        local targetFrame = CreateFrame("Frame", "TargetFrameContainer", UIParent, "SecureHandlerStateTemplate")
        targetFrame:SetSize(core.width, core.targetHeight);
        targetFrame:SetPoint("CENTER", 0, -120);
        configurePingableUnitFrame(targetFrame, "target");

        -- debug BG to show the size of click frame
        -- targetFrame.bg = targetFrame:CreateTexture();
        -- targetFrame.bg:SetPoint("CENTER");
        -- targetFrame.bg:SetColorTexture(0, 0, 0, 0.1);
        -- targetFrame.bg:SetSize(core.width, core.targetHeight);

        targetFrame.click = CreateFrame("Button", "TargetFrameClick", targetFrame, "SecureActionButtonTemplate")
        targetFrame.click:SetPoint("CENTER");
        targetFrame.click:SetSize(core.width, core.targetHeight);
        targetFrame.click:SetAttribute("unit", "target")
        targetFrame.click:SetAttribute("type1", "target")
        targetFrame.click:SetAttribute("type2", "togglemenu")
        targetFrame.click:RegisterForClicks("AnyUp", "AnyDown")
        configurePingableUnitFrame(targetFrame.click, "target");

        local hpBar = core:CreateTargetHPBar(targetFrame)
        hpBar:SetPoint("TOP", 0, -16)

        local widgets = core:CreateTargetWidgets(targetFrame);
        widgets:SetPoint("TOP")

        local primaryResourceBar = core:CreateTargetResourceBar(targetFrame)
        primaryResourceBar:SetPoint("TOPLEFT", -core.width / 6, -20)

        local targetOfTargetBar = core:CreateTargetTargetHPBar(targetFrame)
        targetOfTargetBar:SetPoint("TOPRIGHT", core.width / 3 + 1, -23)

        local castbar = core:CreateTargetCastbar(targetFrame)
        -- above the frame instead of below the HP bar, to leave the space below free for the
        -- player frame's pet row (which sits just below the target frame)
        castbar:SetPoint("BOTTOM", targetFrame, "TOP", 0, 4)

        local BigDebuffs = core:CreateImportantDebuffsFrame(targetFrame)
        BigDebuffs:SetPoint("TOPRIGHT", hpBar.hpText, "TOPLEFT", -4, 0)

        local mainBuffs = core:CreateMainBuffsFrame(targetFrame)
        mainBuffs:SetPoint("TOPLEFT", hpBar, "TOPRIGHT", 4, -7)

        local normalDebuffs = core:CreateNormalDebuffsFrame(targetFrame)
        normalDebuffs:SetPoint("BOTTOMLEFT", mainBuffs, "TOPLEFT", 0, 8)

        -- taint safe way to hide/show this depending on target
        targetFrame:SetAttribute("unit", "target")
        RegisterUnitWatch(targetFrame, false)
    end
end

-- actual todo:
-- cast bar
-- pet stuff
-- side resources like holy power/chi/stagger/etc
-- weakaura like features for stuff like teachings of the monastery & enrage, maybe whirlwind timer etc
-- literally everything for target still
-- do we maybe want a trp feature? like a way to open someones trp

-- target frame
-- big ol HP bar
-- cast bar
-- mana/other power resource
-- buffs/debuffs on target
-- target of target
