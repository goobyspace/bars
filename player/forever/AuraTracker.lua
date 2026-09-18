local _, core = ...
local colours = core.colours

if not core.isForever then return end

local iconWidth = 36;
local iconHeight = 30;
local slotCount = 8;
local minIconSpacing = 2;
local outOfRangeColour = colours.outOfRange;

local function IsSpellKnown(spellID)
    return C_SpellBook.IsSpellKnown(spellID) or C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Pet);
end

local function GetKnownSpellID(entry)
    if entry.rankSpellIDs then
        local known;
        for _, spellID in ipairs(entry.rankSpellIDs) do
            if IsSpellKnown(spellID) then known = spellID end
        end
        return known;
    end
    return IsSpellKnown(entry.spellID) and entry.spellID or nil;
end

local function GetFallbackSpellID(entry)
    return entry.spellID or (entry.rankSpellIDs and entry.rankSpellIDs[#entry.rankSpellIDs]);
end

local function EntryAllowedInCurrentForm(entry, currentForm)
    local form = entry.form;
    if not form then return true end
    if form:sub(1, 1) == "!" then return form:sub(2) ~= currentForm end
    return form == currentForm;
end

local function CreateIcon(parent, entry)
    local button = CreateFrame("Frame", nil, parent);
    button:SetSize(iconWidth, iconHeight);
    button.entry = entry;
    button.spellID = GetKnownSpellID(entry) or GetFallbackSpellID(entry);

    button.border = button:CreateTexture(nil, "BACKGROUND");
    button.border:SetPoint("TOPLEFT", -1, 1);
    button.border:SetPoint("BOTTOMRIGHT", 1, -1);
    button.border:SetColorTexture(colours.black.r, colours.black.g, colours.black.b);

    button.icon = button:CreateTexture(nil, "ARTWORK");
    button.icon:SetAllPoints();
    button.icon:SetTexture(C_Spell.GetSpellTexture(button.spellID));
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);

    -- Cooldown:SetCooldown/SetCooldownDuration both refuse spell-cooldown data from addon code on
    -- Forever (it's secret there), so this type has no real swipe/glow, just the usable/range
    -- desaturation logic below; StatusBar timers accept secret duration objects directly, so this
    -- gets a StatusBar overlay instead
    button.cooldownBar = CreateFrame("StatusBar", nil, button);
    button.cooldownBar:SetAllPoints();
    button.cooldownBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    button.cooldownBar:SetStatusBarColor(colours.black.r, colours.black.g, colours.black.b, 0.7);
    button.cooldownBar:SetReverseFill(true);
    button.cooldownBar:Hide();

    return button;
end

local function UpdateSpellIcon(button)
    local entry = button.entry;
    local spellID = button.spellID;

    -- Cooldown:SetCooldown can't take Forever's secret spell-cooldown numbers from addon code, but
    -- StatusBar timers accept secret duration objects directly, so drive the overlay through that
    local onCooldown = false;
    if entry.showCooldownSwipe ~= false then
        local duration = C_Spell.GetSpellCooldownDuration(spellID);
        onCooldown = duration ~= nil and not duration:IsZero();
        if onCooldown then
            button.cooldownBar:SetTimerDuration(duration, Enum.StatusBarInterpolation.Linear,
                Enum.StatusBarTimerDirection.RemainingTime);
            button.cooldownBar:Show();
        else
            button.cooldownBar:Hide();
        end
    end

    local invalidTarget = false;
    if entry.rangeCheck then
        local hasTarget = UnitExists("target");
        invalidTarget = hasTarget and not UnitCanAttack("player", "target");
        local inRange = hasTarget and not invalidTarget and C_Spell.IsSpellInRange(spellID, "target");
        if inRange == false then
            button.icon:SetVertexColor(outOfRangeColour.r, outOfRangeColour.g, outOfRangeColour.b);
        else
            button.icon:SetVertexColor(colours.white.r, colours.white.g, colours.white.b);
        end
    end

    local isUsable = not (entry.resourceDesaturate or entry.rangeCheck) or C_Spell.IsSpellUsable(spellID);
    button.icon:SetDesaturated(onCooldown or invalidTarget or (entry.resourceDesaturate and not isUsable) or false);
end

-- "aura"/"reminder" entries are backed by a native AuraContainer aura slot instead of a manually
-- driven Cooldown, since C_UnitAuras duration/expirationTime for the player's own auras hit the
-- same secret-value wall as spell cooldowns; the container reads them from untainted Blizzard code
-- and drives the icon/cooldown/duration text itself, so addon Lua never has to touch them.
-- The slot's frame is hidden by the container whenever its candidate aura is absent - overridden
-- here to stay visible and simply desaturate, since these are meant to read as persistent reminders.
local function CreateAuraIcon(parent, entry, unit, auraFilter)
    local container = CreateFrame("AuraContainer", nil, parent, "CustomAuraContainerTemplate");
    container:SetSize(iconWidth, iconHeight);
    container:SetUnit(unit);
    container.entry = entry;

    local spellIDs = {};
    for _, spellID in ipairs(entry.rankSpellIDs or { entry.spellID }) do
        spellIDs[spellID] = true;
    end

    local function initializeFrame(button)
        core:InitializeAuraButtonBase(button, iconWidth);
        button.Hide = function() end;

        function button:OnAuraInstanceAssigned()
            self.icon:SetDesaturated(false);
        end

        function button:OnAuraInstanceCleared()
            self.icon:SetDesaturated(true);
        end

        local spellID = GetKnownSpellID(entry) or GetFallbackSpellID(entry);
        if spellID then
            button.icon:SetTexture(C_Spell.GetSpellTexture(spellID));
        end
        button.icon:SetDesaturated(true);
        button:Show();
    end

    local button = container:AddAuraSlot("tracked", auraFilter, {
        candidateFilters = { includeSpellIDs = spellIDs },
        initializeFrame = initializeFrame,
    });
    button:SetAllPoints(container);
    container.button = button;

    return container;
end

local function UpdateAuraIconSpell(container)
    local entry = container.entry;
    local knownSpellID = GetKnownSpellID(entry);
    local spellID = knownSpellID or GetFallbackSpellID(entry);
    if spellID ~= container.spellID then
        container.spellID = spellID;
        container.button.icon:SetTexture(C_Spell.GetSpellTexture(spellID));
        container:SetAuraSlotCandidateFilters("tracked", { includeSpellIDs = { [spellID] = true } });
    end
    return knownSpellID;
end

function core:CreateAuraTracker(parent)
    local frame = CreateFrame("Frame", "PlayerAuraTrackerContainer", parent);
    frame:SetSize(core.width, iconHeight);

    local playerClass = select(2, UnitClass("player"));
    local entries = core.auraTracker[playerClass];
    if not entries or #entries == 0 then return frame end

    local icons = {};
    for index, entry in ipairs(entries) do
        local button;
        if entry.type == "aura" then
            button = CreateAuraIcon(frame, entry, "target", "HARMFUL");
        elseif entry.type == "reminder" then
            button = CreateAuraIcon(frame, entry, "player", "HELPFUL");
        else
            button = CreateIcon(frame, entry);
        end
        button.slot = entry.slot or index;
        table.insert(icons, button);
    end

    local function Layout()
        local step = math.max(iconWidth + minIconSpacing, (core.width - iconWidth) / (slotCount - 1));
        for _, button in ipairs(icons) do
            button:ClearAllPoints();
            button:SetPoint("LEFT", frame, "LEFT", (button.slot - 1) * step, 0);
            button:SetShown(button.visible);
        end
    end

    local function UpdateVisibility()
        local changed = false;
        local currentForm = core:GetShapeshiftFormKey();
        for _, button in ipairs(icons) do
            local knownSpellID;
            if button.entry.type == "aura" or button.entry.type == "reminder" then
                knownSpellID = UpdateAuraIconSpell(button);
            else
                knownSpellID = GetKnownSpellID(button.entry);
                local spellID = knownSpellID or GetFallbackSpellID(button.entry);
                if spellID ~= button.spellID then
                    button.spellID = spellID;
                    button.icon:SetTexture(C_Spell.GetSpellTexture(spellID));
                end
            end

            local visible = (button.entry.alwaysShow or knownSpellID ~= nil)
                and EntryAllowedInCurrentForm(button.entry, currentForm);
            if visible ~= button.visible then
                button.visible = visible;
                changed = true;
            end
        end
        if changed then Layout() end
    end

    local function UpdateAll()
        for _, button in ipairs(icons) do
            if button.visible and button.entry.type ~= "aura" and button.entry.type ~= "reminder" then
                UpdateSpellIcon(button);
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

    frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" or event == "LEARNED_SPELL_IN_SKILL_LINE"
            or event == "SPELLS_CHANGED" or event == "UPDATE_SHAPESHIFT_FORM" then
            UpdateVisibility();
        end
        UpdateAll();
    end);

    UpdateVisibility();
    Layout();
    UpdateAll();
    return frame;
end
