local _, core = ...


function core:InitializeBarFrames()
    -- core variables before anything else
    core.width = 340;
    core.playerHeight = 36;
    core.targetHeight = 36;

    -- playerframe
    do
        -- hide defaults
        PlayerFrame:SetScript("OnEvent", nil);
        PlayerFrame:Hide();

        local playerFrame = CreateFrame("Frame", "PlayerFrameContainer", UIParent)
        playerFrame:SetSize(core.width, core.playerHeight);
        playerFrame:SetPoint("CENTER", 0, -176);

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

        local widgets = core:CreateWidgets(playerFrame);
        widgets:SetPoint("BOTTOM")

        local primaryResourceBar = core:CreatePrimaryBar(playerFrame)
        primaryResourceBar:SetPoint("BOTTOM")

        local secondaryResourceBar = core:CreateSecondaryBar(playerFrame);
        if secondaryResourceBar then
            secondaryResourceBar:SetPoint("BOTTOM", 0, 9);
        end

        local tertiaryHeight = secondaryResourceBar:IsShown() and 18 or 9;

        local hpBar = core:CreateHPBar(playerFrame);


        function secondaryResourceBar:SetHidden(hidden)
            if hidden then
                secondaryResourceBar:Hide();
                tertiaryHeight = 9;
            else
                secondaryResourceBar:Show();
                tertiaryHeight = 18;
            end
            -- 34 is half of the HP bars total size
            hpBar:SetPoint("BOTTOM", core.width / 2 - 40, tertiaryHeight)
        end
    end

    -- targetframe
    do
        -- hide defaults
        --TargetFrame:SetScript("OnEvent", nil);
        --TargetFrame:Hide();

        local targetFrame = CreateFrame("Frame", "TargetFrameContainer", UIParent, "SecureHandlerStateTemplate")
        targetFrame:SetSize(core.width, core.targetHeight);
        targetFrame:SetPoint("CENTER", 0, -120);

        -- debug BG to show the size of click frame
        targetFrame.bg = targetFrame:CreateTexture();
        targetFrame.bg:SetPoint("CENTER");
        targetFrame.bg:SetColorTexture(0, 0, 0, 0.1);
        targetFrame.bg:SetSize(core.width, core.targetHeight);

        targetFrame.click = CreateFrame("Button", "TargetFrameClick", targetFrame, "SecureActionButtonTemplate")
        targetFrame.click:SetPoint("CENTER");
        targetFrame.click:SetSize(core.width, core.playerHeight);
        targetFrame.click:SetAttribute("unit", "target")
        targetFrame.click:SetAttribute("type1", "target")
        targetFrame.click:SetAttribute("type2", "togglemenu")
        targetFrame.click:RegisterForClicks("AnyUp", "AnyDown")

        local hpBar = core:CreateTargetHPBar(targetFrame)
        hpBar:SetPoint("TOP", 0, -16)

        local widgets = core:CreateTargetWidgets(targetFrame);
        widgets:SetPoint("TOP")

        targetFrame:SetAttribute("unit", "target")
        -- Register the frame with unit watch
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