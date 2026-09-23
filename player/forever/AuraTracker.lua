local _, core = ...
local colours = core.colours

if not core.isForever then return end

local iconWidth = 36;
local iconHeight = 30;
local slotCount = 8;
local minIconSpacing = 2;

local function GetCroppedTexCoords(width, height)
    local trim = 0.08;
    local span = 1 - (trim * 2);
    local horizontal, vertical = span, span;
    if width >= height then
        vertical = span * (height / width);
    else
        horizontal = span * (width / height);
    end
    return 0.5 - horizontal / 2, 0.5 + horizontal / 2, 0.5 - vertical / 2, 0.5 + vertical / 2;
end

local function IsSpellKnown(spellID)
    return C_SpellBook.IsSpellKnown(spellID)
        or C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Pet);
end

local function GetKnownSpellID(entry)
    local known;
    for _, spellID in ipairs(entry.knownSpellIDs or entry.spellIDs or {}) do
        if IsSpellKnown(spellID) then
            known = spellID;
        end
    end
    return known;
end

local function GetIconSpellID(entry, knownSpellID)
    return entry.iconSpellID or knownSpellID or entry.spellIDs and entry.spellIDs[#entry.spellIDs];
end

local function IsAllowedInCurrentForm(entry, currentForm)
    return not entry.forms or entry.forms[currentForm] == true;
end

local function CreateGlow(parent)
    local glow = CreateFrame("Frame", nil, parent);
    core:SetPixelSize(glow, iconWidth * 1.4, iconHeight * 1.4);
    core:SetPixelPoint(glow, "CENTER", parent, "CENTER", 0, 0);

    local texture = glow:CreateTexture(nil, "OVERLAY", nil, 7);
    texture:SetAllPoints();
    texture:SetAtlas("UI-HUD-ActionBar-Proc-Loop-Flipbook", false);

    local animation = texture:CreateAnimationGroup();
    animation:SetLooping("REPEAT");

    local flipbook = animation:CreateAnimation("FlipBook");
    flipbook:SetDuration(1);
    flipbook:SetFlipBookRows(6);
    flipbook:SetFlipBookColumns(5);
    flipbook:SetFlipBookFrames(30);
    flipbook:SetFlipBookFrameWidth(0);
    flipbook:SetFlipBookFrameHeight(0);

    glow.animation = animation;
    animation:Play();

    glow:Hide();
    return glow;
end

local function SetGlowShown(frame, shown)
    frame.glow:SetShown(shown);
end

local function CreateBaseIcon(parent, entry)
    local button = CreateFrame("Frame", nil, parent);
    core:SetPixelSize(button, iconWidth, iconHeight);
    button.entry = entry;

    button.border = button:CreateTexture(nil, "BACKGROUND");
    core:SetPixelPoint(button.border, "TOPLEFT", button, "TOPLEFT", 0, 0);
    core:SetPixelPoint(button.border, "BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0);
    button.border:SetColorTexture(colours.black.r, colours.black.g, colours.black.b);

    button.icon = button:CreateTexture(nil, "ARTWORK");
    core:SetPixelPoint(button.icon, "TOPLEFT", button, "TOPLEFT", core.pixel, -core.pixel);
    core:SetPixelPoint(button.icon, "BOTTOMRIGHT", button, "BOTTOMRIGHT", -core.pixel, core.pixel);
    button.icon:SetTexCoord(GetCroppedTexCoords(iconWidth, iconHeight));
    button.icon:SetDesaturated(true);

    button.glow = CreateGlow(button);

    if entry.spellCooldown then
        button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate");
        button.cooldown:SetAllPoints();
        button.cooldown:SetHideCountdownNumbers(true);
        button.cooldown:SetDrawEdge(false);
        button.cooldown:Hide();

        button.cooldownFallback = CreateFrame("StatusBar", nil, button);
        button.cooldownFallback:SetAllPoints();
        button.cooldownFallback:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
        button.cooldownFallback:SetStatusBarColor(colours.black.r, colours.black.g, colours.black.b, 0.7);
        button.cooldownFallback:SetReverseFill(true);
        button.cooldownFallback:Hide();
    end

    return button;
end

local function CreateAuraLayer(button, entry)
    if not entry.auraSpellIDs then return end

    local container = CreateFrame("AuraContainer", nil, button, "CustomAuraContainerTemplate");
    container:SetAllPoints();
    container:SetUnit(entry.auraUnit);

    local includeSpellIDs = {};
    for _, spellID in ipairs(entry.auraSpellIDs) do
        includeSpellIDs[spellID] = true;
    end

    local function InitializeAuraFrame(auraButton)
        core:SetPixelSize(auraButton, iconWidth, iconHeight);

        auraButton.border = auraButton:CreateTexture(nil, "BACKGROUND");
        core:SetPixelPoint(auraButton.border, "TOPLEFT", auraButton, "TOPLEFT", 0, 0);
        core:SetPixelPoint(auraButton.border, "BOTTOMRIGHT", auraButton, "BOTTOMRIGHT", 0, 0);
        auraButton.border:SetColorTexture(colours.black.r, colours.black.g, colours.black.b);

        auraButton.icon = auraButton:CreateTexture(nil, "OVERLAY");
        core:SetPixelPoint(auraButton.icon, "TOPLEFT", auraButton, "TOPLEFT", core.pixel, -core.pixel);
        core:SetPixelPoint(auraButton.icon, "BOTTOMRIGHT", auraButton, "BOTTOMRIGHT", -core.pixel, core.pixel);
        auraButton.icon:SetTexCoord(GetCroppedTexCoords(iconWidth, iconHeight));
        auraButton:SetIcon(auraButton.icon);

        auraButton.cooldown = CreateFrame("Cooldown", nil, auraButton, "CooldownFrameTemplate");
        auraButton.cooldown:SetAllPoints();
        auraButton.cooldown:SetHideCountdownNumbers(true);
        auraButton.cooldown:SetDrawEdge(false);
        auraButton:SetDurationCooldown(auraButton.cooldown);

        if entry.auraGlow then
            auraButton.glow = CreateGlow(auraButton);
            SetGlowShown(auraButton, true);
        end
    end

    local auraButton = container:AddAuraSlot("active", entry.auraFilter, {
        candidateFilters = { includeSpellIDs = includeSpellIDs },
        initializeFrame = InitializeAuraFrame,
    });
    auraButton:SetAllPoints(container);
    button.auraContainer = container;
end

local function UpdateSpellCooldown(button)
    if not button.cooldown then return end

    local info = C_Spell.GetSpellCooldown(button.spellID);
    if not info or not info["isActive"] or info["isOnGCD"] then
        button.cooldown:Clear();
        button.cooldown:Hide();
        button.cooldownFallback:Hide();
        return;
    end

    local duration = C_Spell.GetSpellCooldownDuration(button.spellID);
    if not duration then return end

    if not duration:HasSecretValues() then
        button.cooldown:SetCooldownFromDurationObject(duration, true);
        button.cooldown:Show();
        button.cooldownFallback:Hide();
    else
        button.cooldown:Clear();
        button.cooldown:Hide();
        button.cooldownFallback:SetTimerDuration(duration, Enum.StatusBarInterpolation.ExponentialEaseOut,
            Enum.StatusBarTimerDirection.RemainingTime);
        button.cooldownFallback:Show();
    end
end

local function UpdateBaseState(button, activeOverlays)
    local entry = button.entry;
    local spellID = button.spellID;
    local outOfRange = entry.rangeCheck and UnitExists("target")
        and C_Spell.IsSpellInRange(spellID, "target") == false;
    local usable = entry.usability and C_Spell.IsSpellUsable(spellID);

    if outOfRange then
        button.icon:SetVertexColor(colours.outOfRange.r, colours.outOfRange.g, colours.outOfRange.b);
        button.icon:SetDesaturated(false);
    else
        button.icon:SetVertexColor(colours.white.r, colours.white.g, colours.white.b);
        button.icon:SetDesaturated(not (entry.usability and usable));
    end

    local activationGlow = false;
    if entry.activationGlow then
        for _, candidate in ipairs(entry.spellIDs or {}) do
            if activeOverlays[candidate] or C_Spell.IsCurrentSpell(candidate) then
                activationGlow = true;
                break;
            end
        end
    end
    SetGlowShown(button, activationGlow or entry.usableGlow and usable or false);
    UpdateSpellCooldown(button);
end

function core:CreateAuraTracker(parent)
    local frame = CreateFrame("Frame", "PlayerAuraTrackerContainer", parent);
    core:SetPixelSize(frame, core.width, iconHeight);

    local playerClass = select(2, UnitClass("player"));
    local entries = core.foreverAuraTracker and core.foreverAuraTracker[playerClass];
    if not entries then return frame end

    local buttons = {};
    local activeOverlays = {};

    for index, entry in ipairs(entries) do
        local button = CreateBaseIcon(frame, entry);
        button.slot = entry.slot or index;
        CreateAuraLayer(button, entry);
        table.insert(buttons, button);
    end

    local function Layout()
        local step = math.max(iconWidth + minIconSpacing, (core.width - iconWidth) / (slotCount - 1));
        for _, button in ipairs(buttons) do
            button:ClearAllPoints();
            core:SetPixelPoint(button, "LEFT", frame, "LEFT", (button.slot - 1) * step, 0);
        end
    end

    local function UpdateVisibility()
        local currentForm = core:GetShapeshiftFormKey();
        for _, button in ipairs(buttons) do
            local knownSpellID = GetKnownSpellID(button.entry);
            local spellID = GetIconSpellID(button.entry, knownSpellID);
            button.spellID = spellID;
            button.icon:SetTexture(C_Spell.GetSpellTexture(spellID));
            button:SetShown(knownSpellID ~= nil and IsAllowedInCurrentForm(button.entry, currentForm));

            if knownSpellID and button.entry.activationGlow then
                local succeeded, overlayed = pcall(C_SpellActivationOverlay.IsSpellOverlayed, knownSpellID);
                activeOverlays[knownSpellID] = succeeded and overlayed or nil;
            end
        end
    end

    local function UpdateAll()
        for _, button in ipairs(buttons) do
            if button:IsShown() then
                UpdateBaseState(button, activeOverlays);
            end
        end
    end

    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE");
    frame:RegisterEvent("SPELLS_CHANGED");
    frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM");
    frame:RegisterEvent("PLAYER_TARGET_CHANGED");
    frame:RegisterEvent("SPELL_UPDATE_COOLDOWN");
    frame:RegisterEvent("SPELL_UPDATE_USABLE");
    frame:RegisterEvent("CURRENT_SPELL_CAST_CHANGED");
    frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW");
    frame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE");
    frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player");

    frame:SetScript("OnEvent", function(_, event, spellID)
        if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
            activeOverlays[spellID] = true;
        elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
            activeOverlays[spellID] = nil;
        elseif event == "PLAYER_ENTERING_WORLD" or event == "LEARNED_SPELL_IN_SKILL_LINE"
            or event == "SPELLS_CHANGED" or event == "UPDATE_SHAPESHIFT_FORM" then
            UpdateVisibility();
        end
        UpdateAll();
    end);

    Layout();
    UpdateVisibility();
    UpdateAll();
    return frame;
end
