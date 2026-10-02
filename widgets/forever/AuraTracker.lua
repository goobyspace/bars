local _, core = ...;
local colours = core.colours;

if not core.isForever then return; end;

local iconWidth = 36;
local iconHeight = 30;
local slotCount = 8;
local minIconSpacing = 2;
local enchantUpdateInterval = 0.1;

local function formatRemaining(seconds)
    if seconds >= 60 then
        return string.format("%dm", math.ceil(seconds / 60));
    elseif seconds >= 10 then
        return string.format("%d", math.floor(seconds));
    end;
    return string.format("%.1f", seconds);
end;

local function getCroppedTexCoords(width, height)
    local trim = 0.08;
    local span = 1 - (trim * 2);
    local horizontal, vertical = span, span;
    if width >= height then
        vertical = span * (height / width);
    else
        horizontal = span * (width / height);
    end;
    return 0.5 - horizontal / 2, 0.5 + horizontal / 2, 0.5 - vertical / 2, 0.5 + vertical / 2;
end;

local function isSpellKnown(spellID)
    return C_SpellBook.IsSpellKnown(spellID)
        or C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Pet);
end;

local function getKnownSpellID(entry)
    local known;
    for _, spellID in ipairs(entry.knownSpellIDs or entry.spellIDs or {}) do
        if isSpellKnown(spellID) then
            known = spellID;
        end;
    end;
    return known;
end;

local function getIconSpellID(entry, knownSpellID)
    return entry.iconSpellID or knownSpellID or entry.spellIDs and entry.spellIDs[#entry.spellIDs];
end;

local function isAllowedInCurrentForm(entry, currentForm)
    return not entry.forms or entry.forms[currentForm] == true;
end;

local function addSpellTooltip(button, getSpellID)
    button:EnableMouse(true);
    button:SetScript("OnEnter", function(self)
        local spellID = getSpellID(self);
        if not spellID then return; end;
        GameTooltip:SetOwner(self, "ANCHOR_TOP");
        GameTooltip:SetSpellByID(spellID);
        GameTooltip:Show();
    end);
    button:SetScript("OnLeave", function()
        GameTooltip:Hide();
    end);
end;

local function createGlow(parent)
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
end;

local function setGlowShown(frame, shown)
    frame.glow:SetShown(shown);
end;

local function createBaseIcon(parent, entry)
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
    button.icon:SetTexCoord(getCroppedTexCoords(iconWidth, iconHeight));
    button.icon:SetDesaturated(true);
    if not entry.auraSpellIDs then
        addSpellTooltip(button, function(self) return self.spellID; end);
    end;

    button.glow = createGlow(button);

    if entry.spellCooldown then
        button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate");
        button.cooldown:SetAllPoints();
        button.cooldown:SetHideCountdownNumbers(not entry.displayText);
        button.cooldown:SetDrawEdge(false);
        button.cooldown:Hide();

        button.cooldownFallback = CreateFrame("StatusBar", nil, button);
        button.cooldownFallback:SetAllPoints();
        button.cooldownFallback:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
        button.cooldownFallback:SetStatusBarColor(colours.black.r, colours.black.g, colours.black.b, 0.7);
        button.cooldownFallback:SetReverseFill(true);
        button.cooldownFallback:Hide();
    end;

    return button;
end;

local function createAuraLayer(button, entry)
    if not entry.auraSpellIDs then return; end;

    local container = CreateFrame("AuraContainer", nil, button, "CustomAuraContainerTemplate");
    container:SetAllPoints();
    container:SetUnit(entry.auraUnit);

    local includeSpellIDs = {};
    for _, spellID in ipairs(entry.auraSpellIDs) do
        includeSpellIDs[spellID] = true;
    end;

    local function initializeAuraFrame(auraButton)
        core:SetPixelSize(auraButton, iconWidth, iconHeight);

        auraButton.border = auraButton:CreateTexture(nil, "BACKGROUND");
        core:SetPixelPoint(auraButton.border, "TOPLEFT", auraButton, "TOPLEFT", 0, 0);
        core:SetPixelPoint(auraButton.border, "BOTTOMRIGHT", auraButton, "BOTTOMRIGHT", 0, 0);
        auraButton.border:SetColorTexture(colours.black.r, colours.black.g, colours.black.b);

        auraButton.icon = auraButton:CreateTexture(nil, "OVERLAY");
        core:SetPixelPoint(auraButton.icon, "TOPLEFT", auraButton, "TOPLEFT", core.pixel, -core.pixel);
        core:SetPixelPoint(auraButton.icon, "BOTTOMRIGHT", auraButton, "BOTTOMRIGHT", -core.pixel, core.pixel);
        auraButton.icon:SetTexCoord(getCroppedTexCoords(iconWidth, iconHeight));
        auraButton:SetIcon(auraButton.icon);

        auraButton.cooldown = CreateFrame("Cooldown", nil, auraButton, "CooldownFrameTemplate");
        auraButton.cooldown:SetAllPoints();
        auraButton.cooldown:SetHideCountdownNumbers(true);
        auraButton.cooldown:SetDrawEdge(false);
        auraButton:SetDurationCooldown(auraButton.cooldown);

        if entry.displayCharges or entry.displayText then
            auraButton.auraText = auraButton.cooldown:CreateFontString(nil, "OVERLAY");
            auraButton.auraText:SetPoint("CENTER", 0, 0);
            core:SetBarFont(auraButton.auraText, entry.displayTextSize or 8);
            if entry.displayCharges then
                auraButton:SetApplicationCount(auraButton.auraText);
            else
                local durationTextOptions;
                if entry.textNoSeconds then
                    local formatter = C_StringUtil.CreateNumericRuleFormatter();
                    formatter:SetBreakpoints({
                        {
                            threshold = 0,
                            step = 1,
                            rounding = Enum.NumericRuleFormatRounding.Down,
                            format = "%d",
                        },
                    });
                    durationTextOptions = { textFormatter = formatter };
                end;
                auraButton:SetDurationText(auraButton.auraText, durationTextOptions);
            end;
        end;

        if entry.auraGlow then
            auraButton.glow = createGlow(auraButton);
            setGlowShown(auraButton, true);
        end;
    end;

    local auraButton = container:AddAuraSlot("active", entry.auraFilter, {
        candidateFilters = { includeSpellIDs = includeSpellIDs },
        initializeFrame = initializeAuraFrame,
    });
    auraButton:SetAllPoints(container);
    button.auraContainer = container;
end;

local function createEnchantLayer(button, entry)
    if not entry.weaponEnchant then return; end;

    if entry.enchantIDs then
        button.enchantIDs = {};
        for _, enchantID in ipairs(entry.enchantIDs) do
            button.enchantIDs[enchantID] = true;
        end;
    end;

    local layer = CreateFrame("Frame", nil, button);
    layer:SetAllPoints();

    layer.icon = layer:CreateTexture(nil, "ARTWORK");
    core:SetPixelPoint(layer.icon, "TOPLEFT", layer, "TOPLEFT", core.pixel, -core.pixel);
    core:SetPixelPoint(layer.icon, "BOTTOMRIGHT", layer, "BOTTOMRIGHT", -core.pixel, core.pixel);
    layer.icon:SetTexCoord(getCroppedTexCoords(iconWidth, iconHeight));
    addSpellTooltip(layer, function() return button.spellID; end);

    layer.cooldown = CreateFrame("Cooldown", nil, layer, "CooldownFrameTemplate");
    layer.cooldown:SetAllPoints();
    layer.cooldown:SetHideCountdownNumbers(true);
    layer.cooldown:SetDrawEdge(false);

    if entry.displayText then
        layer.durationText = layer.cooldown:CreateFontString(nil, "OVERLAY");
        layer.durationText:SetPoint("CENTER", 0, 0);
        core:SetBarFont(layer.durationText, entry.displayTextSize or 8);
    end;

    if entry.auraGlow then
        layer.glow = createGlow(layer);
        setGlowShown(layer, true);
    end;

    layer:Hide();
    button.enchantLayer = layer;
end;

local function findWeaponEnchant(button)
    -- forever's Enum.WeaponSlot: 0 = main hand, 1 = off hand; the global GetWeaponEnchantInfo always reports false here
    local weaponSlot = button.entry.weaponEnchant == "OFFHAND" and 1 or 0;
    for _, enchant in ipairs(C_Item.GetWeaponEnchantInfo(weaponSlot) or {}) do
        if enchant.hasEnchant and (not button.enchantIDs or button.enchantIDs[enchant.enchantID]) then
            return enchant;
        end;
    end;
end;

local function updateWeaponEnchant(button)
    local layer = button.enchantLayer;
    if not layer then return; end;

    local info = findWeaponEnchant(button);
    if not info then
        layer:Hide();
        layer.duration, layer.expirationTime = nil, nil;
        return;
    end;
    layer:Show();

    local expiration = info.timeLeft;
    if not expiration or issecretvalue(expiration) or expiration <= 0 then
        layer.cooldown:Clear();
        if layer.durationText then layer.durationText:SetText(""); end;
        return;
    end;

    local remaining = expiration / 1000;
    local expirationTime = GetTime() + remaining;
    -- the API has no total duration, so use the largest remaining time seen since the imbue was applied
    if not layer.duration or remaining > layer.duration then
        layer.duration = remaining;
    end;
    if not layer.expirationTime or math.abs(expirationTime - layer.expirationTime) > 0.5 then
        layer.expirationTime = expirationTime;
        layer.cooldown:SetCooldown(expirationTime - layer.duration, layer.duration);
    end;

    if layer.durationText then
        layer.durationText:SetText(formatRemaining(remaining));
    end;
end;

local function updateSpellCooldown(button)
    if not button.cooldown then return; end;

    local info = C_Spell.GetSpellCooldown(button.spellID);
    if not info or not info["isActive"] or info["isOnGCD"] then
        button.cooldown:Clear();
        button.cooldown:Hide();
        button.cooldownFallback:Hide();
        return;
    end;

    local duration = C_Spell.GetSpellCooldownDuration(button.spellID);
    if not duration then return; end;

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
    end;
end;

local function updateBaseState(button, activeOverlays)
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
    end;

    local activationGlow = false;
    if entry.activationGlow then
        for _, candidate in ipairs(entry.spellIDs or {}) do
            if activeOverlays[candidate] or C_Spell.IsCurrentSpell(candidate) then
                activationGlow = true;
                break;
            end;
        end;
    end;
    setGlowShown(button, activationGlow or entry.usableGlow and usable or false);
    updateSpellCooldown(button);
    updateWeaponEnchant(button);
end;

function core:CreateAuraTracker(parent)
    local frame = CreateFrame("Frame", "PlayerAuraTrackerContainer", parent);
    core:SetPixelSize(frame, core.width, iconHeight);

    local playerClass = select(2, UnitClass("player"));
    local entries = core.foreverAuraTracker and core.foreverAuraTracker[playerClass];
    if not entries then return frame; end;

    local buttons = {};
    local activeOverlays = {};

    for index, entry in ipairs(entries) do
        local button = createBaseIcon(frame, entry);
        button.slot = entry.slot or index;
        createAuraLayer(button, entry);
        createEnchantLayer(button, entry);
        table.insert(buttons, button);
    end;

    local function layout()
        local step = math.max(iconWidth + minIconSpacing, (core.width - iconWidth) / (slotCount - 1));
        for _, button in ipairs(buttons) do
            button:ClearAllPoints();
            core:SetPixelPoint(button, "LEFT", frame, "LEFT", (button.slot - 1) * step, 0);
        end;
    end;

    local function updateVisibility()
        local currentForm = core:GetShapeshiftFormKey();
        for _, button in ipairs(buttons) do
            local knownSpellID = getKnownSpellID(button.entry);
            local spellID = getIconSpellID(button.entry, knownSpellID);
            button.spellID = spellID;
            button.icon:SetTexture(C_Spell.GetSpellTexture(spellID));
            if button.enchantLayer then
                button.enchantLayer.icon:SetTexture(C_Spell.GetSpellTexture(spellID));
            end;
            button:SetShown(knownSpellID ~= nil and isAllowedInCurrentForm(button.entry, currentForm));

            if knownSpellID and button.entry.activationGlow then
                local succeeded, overlayed = pcall(C_SpellActivationOverlay.IsSpellOverlayed, knownSpellID);
                activeOverlays[knownSpellID] = succeeded and overlayed or nil;
            end;
        end;
    end;

    local function updateAll()
        for _, button in ipairs(buttons) do
            if button:IsShown() then
                updateBaseState(button, activeOverlays);
            end;
        end;
    end;

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
    frame:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player");
    frame:RegisterEvent("WEAPON_ENCHANT_CHANGED");

    -- imbue expiry fires no event, so poll while any enchant entry exists
    local enchantElapsed = 0;
    for _, button in ipairs(buttons) do
        if button.enchantLayer then
            frame:SetScript("OnUpdate", function(_, elapsed)
                enchantElapsed = enchantElapsed + elapsed;
                if enchantElapsed < enchantUpdateInterval then return; end;
                enchantElapsed = 0;
                for _, candidate in ipairs(buttons) do
                    if candidate:IsShown() then updateWeaponEnchant(candidate); end;
                end;
            end);
            break;
        end;
    end;

    frame:SetScript("OnEvent", function(_, event, spellID)
        if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
            activeOverlays[spellID] = true;
        elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
            activeOverlays[spellID] = nil;
        elseif event == "PLAYER_ENTERING_WORLD" or event == "LEARNED_SPELL_IN_SKILL_LINE"
            or event == "SPELLS_CHANGED" or event == "UPDATE_SHAPESHIFT_FORM" then
            updateVisibility();
        end;
        updateAll();
    end);

    layout();
    updateVisibility();
    updateAll();
    return frame;
end;
