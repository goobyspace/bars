local _, core = ...;
local colours = core.colours;

if core.isClassicRules then return; end;

local iconWidth = 36;
local iconHeight = 30;
local slotCount = 8;
local minIconSpacing = 2;
local updateInterval = 0.1;

local whiteColour = CreateColor(colours.white.r, colours.white.g, colours.white.b, 1);
local outOfRangeColour = CreateColor(colours.outOfRange.r, colours.outOfRange.g, colours.outOfRange.b, 1);

local function isAnySpellKnown(spellIDs)
    for _, spellID in ipairs(spellIDs) do
        if C_SpellBook.IsSpellKnown(spellID) then
            return true;
        end;
    end;
    return false;
end;

local function getKnownSpellID(entry)
    local known;
    for _, spellID in ipairs(entry.knownSpellIDs or entry.spellIDs) do
        if C_SpellBook.IsSpellKnown(spellID) then
            known = spellID;
        end;
    end;
    return known;
end;

local function addSpellTooltip(button)
    button:EnableMouse(true);
    button:SetScript("OnEnter", function(self)
        if not self.spellID then return; end;
        GameTooltip:SetOwner(self, "ANCHOR_TOP");
        GameTooltip:SetSpellByID(self.spellID);
        GameTooltip:Show();
    end);
    button:SetScript("OnLeave", function()
        GameTooltip:Hide();
    end);
end;

local function playGlowAnimation(texture)
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
    animation:Play();
end;

local function createGlow(parent)
    local glow = CreateFrame("Frame", nil, parent);
    glow:SetFrameLevel(parent:GetFrameLevel() + 5);
    core:SetPixelSize(glow, iconWidth * 1.4, iconHeight * 1.4);
    core:SetPixelPoint(glow, "CENTER", parent, "CENTER", 0, 0);

    local texture = glow:CreateTexture(nil, "OVERLAY", nil, 7);
    texture:SetAllPoints();
    playGlowAnimation(texture);

    return glow;
end;

-- the aura container only ever fills this bar proportionally to the stacks (min cant be set), so the glow sits in a clipping
-- window that follows the end of the fill. the bar is so wide that the window only overlaps the glow at max stacks
local function createStackGlow(auraButton, maxStacks)
    local glowWidth, glowHeight = iconWidth * 1.4, iconHeight * 1.4;

    local bar = CreateFrame("StatusBar", nil, auraButton);
    core:SetPixelSize(bar, glowWidth * maxStacks * 2, glowHeight);
    core:SetPixelPoint(bar, "RIGHT", auraButton, "CENTER", glowWidth / 2, 0);
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");
    bar:SetStatusBarColor(0, 0, 0, 0);

    local window = CreateFrame("Frame", nil, auraButton);
    window:SetFrameLevel(auraButton:GetFrameLevel() + 5);
    window:SetClipsChildren(true);
    core:SetPixelSize(window, glowWidth, glowHeight);
    window:SetPoint("RIGHT", bar:GetStatusBarTexture(), "RIGHT", 0, 0);

    local glow = createGlow(window);
    glow:ClearAllPoints();
    core:SetPixelPoint(glow, "CENTER", auraButton, "CENTER", 0, 0);

    auraButton:SetApplicationBar(bar, { minApplications = 0, maxApplications = maxStacks });
end;

local function createIconTexture(button, layer, subLevel)
    local icon = button:CreateTexture(nil, layer, nil, subLevel);
    core:SetPixelPoint(icon, "TOPLEFT", button, "TOPLEFT", core.pixel, -core.pixel);
    core:SetPixelPoint(icon, "BOTTOMRIGHT", button, "BOTTOMRIGHT", -core.pixel, core.pixel);
    icon:SetTexCoord(core:GetCroppedTexCoords(iconWidth, iconHeight));
    return icon;
end;

local function createBlackBorder(button)
    local border = button:CreateTexture(nil, "BACKGROUND");
    core:SetPixelPoint(border, "TOPLEFT", button, "TOPLEFT", 0, 0);
    core:SetPixelPoint(border, "BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0);
    border:SetColorTexture(colours.black.r, colours.black.g, colours.black.b);
    return border;
end;

local function createBaseIcon(parent, entry)
    local button = CreateFrame("Frame", nil, parent);
    core:SetPixelSize(button, iconWidth, iconHeight);
    button.entry = entry;
    button.border = createBlackBorder(button);
    button.icon = createIconTexture(button, "ARTWORK", 0);
    addSpellTooltip(button);

    if entry.usability then
        -- usability can be a secret value in combat so a lit icon fades in over a greyed one instead of branching
        button.icon:SetDesaturated(true);
        button.litIcon = createIconTexture(button, "ARTWORK", 1);
        button.litIcon:SetAlpha(0);
    elseif entry.auraSpellIDs and not entry.spellCooldown and not entry.keepSpellIcon then
        button.icon:SetDesaturated(true);
    end;

    if entry.spellCooldown then
        button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate");
        button.cooldown:SetAllPoints();
        button.cooldown:SetDrawEdge(false);

        if entry.chargeCooldown then
            -- edge only so recharging doesnt black out the icon whilst a charge is still left
            button.chargeCooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate");
            button.chargeCooldown:SetAllPoints();
            button.chargeCooldown:SetDrawSwipe(false);
            button.chargeCooldown:SetDrawEdge(true);
            button.chargeCooldown:SetHideCountdownNumbers(true);
        end;
    end;

    if entry.usableGlow or entry.procGlow then
        button.glow = createGlow(button);
        button.glow:SetAlpha(0);
    end;

    if entry.chargesText then
        local textFrame = CreateFrame("Frame", nil, button);
        textFrame:SetAllPoints();
        textFrame:SetFrameLevel(button:GetFrameLevel() + 10);
        button.chargesText = textFrame:CreateFontString(nil, "OVERLAY");
        button.chargesText:SetPoint("BOTTOMRIGHT", -2 * core.pixel, 2 * core.pixel);
        core:SetBarFont(button.chargesText, entry.chargesTextSize or 10);
    end;

    return button;
end;

local function createAuraLayer(button, entry)
    if not entry.auraSpellIDs then return; end;

    local container = CreateFrame("AuraContainer", nil, button, "CustomAuraContainerTemplate");
    container:SetAllPoints();
    container:SetUnit("player");

    local includeSpellIDs = {};
    for _, spellID in ipairs(entry.auraSpellIDs) do
        includeSpellIDs[spellID] = true;
    end;

    local function initializeAuraFrame(auraButton)
        core:SetPixelSize(auraButton, iconWidth, iconHeight);
        auraButton:SetPoint("CENTER", button, "CENTER");

        if not entry.keepSpellIcon then
            auraButton.border = createBlackBorder(auraButton);
            auraButton.icon = createIconTexture(auraButton, "OVERLAY", 0);
            auraButton:SetIcon(auraButton.icon);

            auraButton.cooldown = CreateFrame("Cooldown", nil, auraButton, "CooldownFrameTemplate");
            auraButton.cooldown:SetAllPoints();
            auraButton.cooldown:SetHideCountdownNumbers(true);
            auraButton.cooldown:SetDrawEdge(false);
            auraButton:SetDurationCooldown(auraButton.cooldown);
        end;
        if entry.displayCharges then
            -- not parented to the cooldown, auras without a duration (dance of the wind) hide it :/
            local textFrame = CreateFrame("Frame", nil, auraButton);
            textFrame:SetAllPoints();
            textFrame:SetFrameLevel(auraButton:GetFrameLevel() + 10);
            auraButton.stackText = textFrame:CreateFontString(nil, "OVERLAY");
            auraButton.stackText:SetPoint("CENTER", 0, 0);
            core:SetBarFont(auraButton.stackText, entry.displayTextSize or 14);
            auraButton:SetApplicationCount(auraButton.stackText);
        end;

        if entry.auraGlow then
            createGlow(auraButton);
        end;

        if entry.maxStacksGlow then
            createStackGlow(auraButton, entry.maxStacksGlow);
        end;
    end;

    container:AddAuraSlot("active", "HELPFUL", {
        candidateFilters = { includeSpellIDs = includeSpellIDs },
        initializeFrame = initializeAuraFrame,
    });
end;

local function updateCooldown(button)
    if not button.cooldown then return; end;

    local duration = C_Spell.GetSpellCooldownDuration(button.spellID, true);
    if duration then
        button.cooldown:SetCooldownFromDurationObject(duration, true);
    else
        button.cooldown:Clear();
    end;

    if button.chargeCooldown then
        local chargeDuration = C_Spell.GetSpellChargeDuration(button.spellID);
        if chargeDuration then
            button.chargeCooldown:SetCooldownFromDurationObject(chargeDuration, true);
        else
            button.chargeCooldown:Clear();
        end;
    end;
end;

local function updateState(button)
    local entry = button.entry;
    local spellID = button.spellID;

    if entry.rangeCheck then
        local inRange = true;
        if UnitExists("target") then
            inRange = C_Spell.IsSpellInRange(spellID, "target");
            if not issecretvalue(inRange) then
                inRange = inRange ~= false;
            end;
        end;
        button.icon:SetVertexColorFromBoolean(inRange, whiteColour, outOfRangeColour);
    end;

    if entry.usability then
        local usable = C_Spell.IsSpellUsable(spellID);
        button.litIcon:SetAlphaFromBoolean(usable, 1, 0);
        if entry.usableGlow then
            button.glow:SetAlphaFromBoolean(usable);
        end;
    elseif entry.usableGlow then
        -- isActive and isOnGCD are never secret, so this is safe to branch on
        local info = C_Spell.GetSpellCooldown(spellID);
        local offCooldown = info and (not info.isActive or info.isOnGCD);
        button.glow:SetAlpha(offCooldown and UnitAffectingCombat("player") and 1 or 0);
    end;

    if button.chargesText then
        if entry.castCountText then
            -- vivify has no display count, its cast count is the number of renewing mists up
            local count = C_Spell.GetSpellCastCount(spellID);
            button.chargesText:SetText(not issecretvalue(count) and count == 0 and "" or count);
        else
            -- the display count is a string that can be secret in combat, SetText handles it fine
            button.chargesText:SetText(C_Spell.GetSpellDisplayCount(spellID));
        end;
    end;

    if entry.procGlow then
        local overlayed = C_SpellActivationOverlay.IsSpellOverlayed(spellID)
            or C_SpellActivationOverlay.IsSpellOverlayed(button.baseSpellID);
        button.glow:SetAlpha(overlayed and 1 or 0);
    end;
end;

-- follows spell overrides like bloodthirst -> bloodbath
local function refreshSpell(button)
    local spellID = button.entry.iconSpellID;
    if not spellID then
        local override = C_Spell.GetOverrideSpell(button.baseSpellID);
        spellID = override and override > 0 and override or button.baseSpellID;
    end;
    if spellID == button.spellID then return; end;

    button.spellID = spellID;
    local texture = C_Spell.GetSpellTexture(spellID);
    button.icon:SetTexture(texture);
    if button.litIcon then
        button.litIcon:SetTexture(texture);
    end;
    updateCooldown(button);
end;

function core:CreateAuraTracker(parent)
    local frame = CreateFrame("Frame", "PlayerAuraTrackerContainer", parent);
    core:SetPixelSize(frame, core.width, iconHeight);

    local playerClass = select(2, UnitClass("player"));
    local classEntries = core.retailAuraTracker and core.retailAuraTracker[playerClass];
    if not classEntries then return frame; end;

    local buttons = {};
    local step = math.max(iconWidth + minIconSpacing, (core.width - iconWidth) / (slotCount - 1));

    for specID, specEntries in pairs(classEntries) do
        for index, entry in ipairs(specEntries) do
            local button = createBaseIcon(frame, entry);
            button.specID = specID;
            core:SetPixelPoint(button, "LEFT", frame, "LEFT", ((entry.slot or index) - 1) * step, 0);
            createAuraLayer(button, entry);
            button:Hide();
            table.insert(buttons, button);
        end;
    end;

    local function updateVisibility()
        local spec = C_SpecializationInfo.GetSpecialization();
        local currentSpecID = spec and C_SpecializationInfo.GetSpecializationInfo(spec);
        for _, button in ipairs(buttons) do
            local entry = button.entry;
            local hidden = button.specID ~= currentSpecID
                or entry.hideIfKnownSpellIDs and isAnySpellKnown(entry.hideIfKnownSpellIDs);
            button.baseSpellID = not hidden and getKnownSpellID(entry) or nil;
            button.spellID = nil;
            button:SetShown(button.baseSpellID ~= nil);
        end;
    end;

    local function updateAll()
        for _, button in ipairs(buttons) do
            if button:IsShown() then
                refreshSpell(button);
                updateCooldown(button);
                updateState(button);
            end;
        end;
    end;

    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterEvent("SPELLS_CHANGED");
    frame:RegisterEvent("PLAYER_TALENT_UPDATE");
    frame:RegisterEvent("TRAIT_CONFIG_UPDATED");
    frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player");
    frame:RegisterEvent("PLAYER_TARGET_CHANGED");
    frame:RegisterEvent("SPELL_UPDATE_COOLDOWN");
    frame:RegisterEvent("SPELL_UPDATE_CHARGES");
    frame:RegisterEvent("SPELL_UPDATE_USABLE");

    frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" or event == "SPELLS_CHANGED" or event == "PLAYER_TALENT_UPDATE"
            or event == "TRAIT_CONFIG_UPDATED" or event == "PLAYER_SPECIALIZATION_CHANGED" then
            updateVisibility();
        end;
        updateAll();
    end);

    -- range and target health based usability have no event to hook into so poll them :/
    local elapsedSinceUpdate = 0;
    frame:SetScript("OnUpdate", function(_, elapsed)
        elapsedSinceUpdate = elapsedSinceUpdate + elapsed;
        if elapsedSinceUpdate < updateInterval then return; end;
        elapsedSinceUpdate = 0;
        for _, button in ipairs(buttons) do
            if button:IsShown() then
                refreshSpell(button);
                updateState(button);
            end;
        end;
    end);

    updateVisibility();
    updateAll();
    return frame;
end;
