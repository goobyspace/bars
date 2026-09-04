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

-- UI units are not physical pixels (UIParent is scaled), so every size and offset that has to land
-- on an exact pixel is rounded to a whole number of pixels; otherwise a 1px border ends up straddling
-- two pixel rows and renders as 2px on one side and nothing on the other
local function snap(units)
    if not units or units == 0 then return 0 end;
    local pixels = math.floor(math.abs(units) / core.pixel + 0.5);
    return (units < 0 and -1 or 1) * pixels * core.pixel;
end

function core:SetPixelPoint(region, point, relativeTo, relativePoint, x, y)
    region:SetPoint(point, relativeTo, relativePoint, snap(x), snap(y));
end

function core:SetPixelSize(region, width, height)
    region:SetSize(snap(width), snap(height));
end

local function getPixelUnit()
    local _, screenHeight = GetPhysicalScreenSize();
    return UIParent:GetHeight() / screenHeight;
end

function core:EvenPixels(units)
    local pixels = math.max(2, math.floor(units / core.pixel + 0.5));
    if pixels % 2 == 1 then
        pixels = pixels + 1;
    end
    return pixels * core.pixel;
end

function core:SnapToPixelGrid(frame)
    if not frame then return end;

    local left, bottom = frame:GetLeft(), frame:GetBottom();
    if not left or not bottom then return end;

    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1);
    if not point then return end;

    local dx, dy = left - snap(left), bottom - snap(bottom);
    if dx == 0 and dy == 0 then return end;

    frame:SetPoint(point, relativeTo, relativePoint, (x or 0) - dx, (y or 0) - dy);
end

function core:InsetBarInBackground(bar, bg)
    bar:ClearAllPoints();
    core:SetPixelPoint(bar, "TOPLEFT", bg, "TOPLEFT", core.pixel, -core.pixel);
    core:SetPixelPoint(bar, "BOTTOMRIGHT", bg, "BOTTOMRIGHT", -core.pixel, core.pixel);
end

local copyFrame;
local function showCopyableText(text)
    if not copyFrame then
        copyFrame = CreateFrame("Frame", "BarsCopyFrame", UIParent);
        copyFrame:SetSize(620, 320);
        copyFrame:SetPoint("CENTER");
        copyFrame:SetFrameStrata("DIALOG");
        copyFrame:EnableMouse(true);
        copyFrame:SetMovable(true);
        copyFrame:RegisterForDrag("LeftButton");
        copyFrame:SetScript("OnDragStart", copyFrame.StartMoving);
        copyFrame:SetScript("OnDragStop", copyFrame.StopMovingOrSizing);

        local bg = copyFrame:CreateTexture(nil, "BACKGROUND");
        bg:SetAllPoints();
        bg:SetColorTexture(0, 0, 0, 0.92);

        local close = CreateFrame("Button", nil, copyFrame, "UIPanelCloseButton");
        close:SetPoint("TOPRIGHT");

        local scroll = CreateFrame("ScrollFrame", "BarsCopyScrollFrame", copyFrame, "UIPanelScrollFrameTemplate");
        scroll:SetPoint("TOPLEFT", 12, -30);
        scroll:SetPoint("BOTTOMRIGHT", -32, 12);

        copyFrame.edit = CreateFrame("EditBox", nil, scroll);
        copyFrame.edit:SetMultiLine(true);
        copyFrame.edit:SetFontObject("ChatFontNormal");
        copyFrame.edit:SetWidth(560);
        copyFrame.edit:SetAutoFocus(false);
        copyFrame.edit:SetScript("OnEscapePressed", function()
            copyFrame:Hide();
        end);
        scroll:SetScrollChild(copyFrame.edit);

        table.insert(UISpecialFrames, "BarsCopyFrame");
    end

    copyFrame.edit:SetText(text);
    copyFrame:Show();
    copyFrame.edit:SetFocus();
    copyFrame.edit:HighlightText();
end

function core:SetBarFont(fontString, size)
    fontString:SetFont("Fonts\\FRIZQT__.TTF", math.floor(size * core.fontScale + 0.5), "OUTLINE");
end

function core:InitializeBarFrames()
    -- core variables before anything else
    core.pixel = getPixelUnit();
    -- fill height of a bar and the bg behind it, which adds the 1px border on each side
    core.barHeight = (core.thickMode and 10 or 3) * core.pixel;
    core.barBgHeight = core.barHeight + 2 * core.pixel;
    core.fontScale = core.thickMode and 1.5 or 1;
    core.castbarHeight = core.thickMode and 28 or 16;
    -- every stacked row and label offset adds this so the layout expands with the bar height
    core.barGrowth = core.barBgHeight - 5 * core.pixel;
    core.labelAboveBar = 10 * core.fontScale + core.barGrowth / 2;
    core.labelBelowBar = -(8 * core.fontScale + core.barGrowth / 2);

    core.width = core:EvenPixels(340);
    core.playerHeight = core:EvenPixels(36 + 2 * core.barGrowth);
    core.targetHeight = core:EvenPixels(28 + 2 * core.barGrowth);
    core.targetFrameY = -106;
    core.frameGap = 24;
    core.playerFrameY = core.targetFrameY - core.targetHeight - core.frameGap - core.playerHeight;

    -- playerframe
    do
        -- hide defaults
        PlayerFrame:SetScript("OnEvent", nil);
        PlayerFrame:Hide();

        local playerFrame = CreateFrame("Frame", "PlayerFrameContainer", UIParent, "SecureHandlerStateTemplate")
        core:SetPixelSize(playerFrame, core.width, core.playerHeight);
        core:SetPixelPoint(playerFrame, "BOTTOM", UIParent, "CENTER", 0, core.playerFrameY);
        core:SnapToPixelGrid(playerFrame);
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
        core:SetPixelPoint(primaryResourceBar, "BOTTOM", playerFrame, "BOTTOM", 0, 3)
        core:SnapToPixelGrid(primaryResourceBar)

        local secondaryResourceBar = core:CreateSecondaryBar(playerFrame);
        local tertiaryResourceBar = core:CreateTertiaryBar(playerFrame);

        local swingTimer = core.CreateSwingTimer and core:CreateSwingTimer(playerFrame);

        local castbar = core:CreatePlayerCastbar(playerFrame)
        castbar:SetPoint("CENTER", 0, -74)

        if core.CreateAuraTracker then
            local auraTracker = core:CreateAuraTracker(playerFrame)
            auraTracker:SetPoint("TOP", playerFrame, "BOTTOM", 0, -2)
        end

        local hpBar = core:CreateHPBar(playerFrame);
        local petFrame = core:CreatePetFrame(playerFrame);

        local secondaryShown = false;
        local tertiaryShown = false;
        local petShown = false;
        local layoutPending = false;

        local function updateLayout()
            if InCombatLockdown() then
                layoutPending = true;
                return;
            end

            local growth = core.barGrowth;
            local offset = 13 + growth;

            if secondaryShown then
                core:SetPixelPoint(secondaryResourceBar, "BOTTOM", playerFrame, "BOTTOM", 0, 9 + growth);
                offset = offset + 9 + growth;
            end

            core:SetPixelPoint(hpBar, "BOTTOM", playerFrame, "BOTTOM",
                (core.width - hpBar:GetWidth()) / 2, offset);

            core:SetPixelPoint(tertiaryResourceBar, "BOTTOM", playerFrame, "BOTTOM",
                -(core.width - tertiaryResourceBar:GetWidth()) / 2, offset);

            core:SetPixelPoint(petFrame, "BOTTOM", playerFrame, "BOTTOM", -core.width / 6,
                tertiaryShown and (offset + 9 + growth) or offset);

            if swingTimer then
                core:SetPixelPoint(swingTimer, "BOTTOM", playerFrame, "BOTTOM", -core.width / 6,
                    petShown and (offset + 13 + growth) or offset);
            end

            core:SnapToPixelGrid(secondaryResourceBar);
            core:SnapToPixelGrid(hpBar);
            core:SnapToPixelGrid(tertiaryResourceBar);
            core:SnapToPixelGrid(petFrame);
            core:SnapToPixelGrid(swingTimer);
        end

        local layoutRetryFrame = CreateFrame("Frame")
        layoutRetryFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        layoutRetryFrame:SetScript("OnEvent", function()
            if layoutPending then
                layoutPending = false;
                updateLayout();
            end
        end)

        petShown = petFrame:IsShown();
        petFrame:HookScript("OnShow", function()
            petShown = true;
            updateLayout();
        end)
        petFrame:HookScript("OnHide", function()
            petShown = false;
            updateLayout();
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
        core:SetPixelSize(targetFrame, core.width, core.targetHeight);
        core:SetPixelPoint(targetFrame, "TOP", UIParent, "CENTER", 0, core.targetFrameY);
        core:SnapToPixelGrid(targetFrame);
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
        core:SetPixelPoint(hpBar, "TOP", targetFrame, "TOP", 0, -16)
        core:SnapToPixelGrid(hpBar)

        local widgets = core:CreateTargetWidgets(targetFrame);
        widgets:SetPoint("TOP")

        local primaryResourceBar = core:CreateTargetResourceBar(targetFrame)
        core:SetPixelPoint(primaryResourceBar, "TOPLEFT", targetFrame, "TOPLEFT", 0, -22 - core.barGrowth)
        core:SnapToPixelGrid(primaryResourceBar)

        local targetOfTargetBar = core:CreateTargetTargetHPBar(targetFrame)
        core:SetPixelPoint(targetOfTargetBar, "TOPRIGHT", targetFrame, "TOPRIGHT", 0, -22 - core.barGrowth)
        core:SnapToPixelGrid(targetOfTargetBar)

        local castbar = core:CreateTargetCastbar(targetFrame)
        castbar:SetPoint("BOTTOM", targetFrame, "TOP", 0, 4 * core.fontScale + core.barGrowth)

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

    SLASH_BARSPX1 = "/barspx";
    SlashCmdList["BARSPX"] = function()
        local screenWidth, screenHeight = GetPhysicalScreenSize();
        local lines = {
            format("screen %dx%d, UIParent %.2fx%.2f units, effective scale %.4f, 1px = %.4f units",
                screenWidth, screenHeight, UIParent:GetWidth(), UIParent:GetHeight(),
                UIParent:GetEffectiveScale(), core.pixel),
        };

        for _, name in ipairs({ "PlayerFrameContainer", "HPBarContainer", "PrimaryResourceContainer",
            "PetFrameContainer", "SwingTimerContainer", "TargetFrameContainer", "TargetHPBarContainer",
            "TargetResourceContainer", "TargetTargetHPBarContainer" }) do
            local f = _G[name];
            if f and f:GetLeft() then
                table.insert(lines, format("%s: left %.2f bottom %.2f width %.2f height %.2f", name,
                    f:GetLeft() / core.pixel, f:GetBottom() / core.pixel,
                    f:GetWidth() / core.pixel, f:GetHeight() / core.pixel));
            end
        end

        showCopyableText(table.concat(lines, "\n"));
    end
end
