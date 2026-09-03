local _, core = ...

if not core.isClassicEra then return end

-- Weakaura-like row of spell/aura icons that sits horizontally below the player's primary
-- resource bar. Everything is driven off the core.auraTracker config table below, so adding a
-- new icon is a matter of adding one entry; icons lay out left to right in the order declared.

local ICON_WIDTH = 36;
local ICON_HEIGHT = 30;

-- the row is justified across the full bar width, so the gap is whatever is left over after the
-- icons rather than a fixed value; MIN_ICON_SPACING only kicks in once the row is full
local MIN_ICON_SPACING = 2;

-- how often the OnUpdate driven bits (cooldown text, range, cast counts) refresh
local UPDATE_INTERVAL = 0.1;

-- cooldowns at or below this are treated as the global cooldown and not drawn
local GCD_THRESHOLD = 1.5;

local OUT_OF_RANGE_COLOUR = { r = 1, g = 0.25, b = 0.25 };

--[[
    core.auraTracker is keyed by class token, each value being an ordered list of entries.

    Shared fields:
        type            "spell" | "aura"
        spellID         spellID used for the icon texture, cooldown, range and usability
        alwaysShow      show the icon even when the spell isn't known (default false)

    type == "spell":
        showCooldownSwipe   draw the cooldown swipe (default true)
        showCooldownText    centre text with the cooldown remaining (default true)
        showCastCount       corner text with how many casts the current resources allow
        rangeCheck          recolour the icon red when the target is out of range
        resourceDesaturate  desaturate the icon when there aren't enough resources
        trackedAuraSpellID  optional aura to count; shows how many targets have it
        trackedAuraFilter   aura filter for the above (default "HARMFUL|PLAYER")

    type == "aura":
        showTargetCount     corner text with how many targets currently have the aura
        showTargetDuration  centre text with the time left on the aura on the current target
        auraFilter          aura filter used for both of the above (default "HARMFUL|PLAYER")
        castCountSpellID    spellID whose resource cost drives the "casts remaining" text

    Optional overrides for the resource maths (when the API cost lookup isn't right):
        powerCost           flat resource cost per cast
        powerType           Enum.PowerType.* the cost is paid from
]]
core.auraTracker = {
    -- examples; fill these in per class
    -- ["WARLOCK"] = {
    --     {
    --         type = "spell",
    --         spellID = 172, -- corruption
    --         showCastCount = true,
    --         rangeCheck = true,
    --         resourceDesaturate = true,
    --         trackedAuraSpellID = 172,
    --     },
    --     {
    --         type = "aura",
    --         spellID = 980, -- curse of agony
    --         showTargetCount = true,
    --         showTargetDuration = true,
    --         castCountSpellID = 980,
    --     },
    -- },
};

-- spell lookups ----------------------------------------------------------------------------
-- Classic Era 1.15 carries the modern C_Spell/C_SpellBook namespaces, so the pre-11.0 globals
-- (GetSpellInfo, IsUsableSpell, IsSpellInRange, IsSpellKnown, ...) are deprecated and unused.

local function GetSpellCooldownInfo(spellID)
    local info = C_Spell.GetSpellCooldown(spellID);
    if not info then return 0, 0, false end
    return info.startTime, info.duration, info.isEnabled;
end

local function GetSpellPowerCost(spellID)
    local costs = C_Spell.GetSpellPowerCost(spellID);
    if not costs then return nil end
    for _, cost in ipairs(costs) do
        if cost.cost and cost.cost > 0 then
            return cost.cost, cost.type;
        end
    end
    return nil;
end

local function IsSpellKnown(spellID)
    return C_SpellBook.IsSpellKnown(spellID) or C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Pet);
end

-- helpers ----------------------------------------------------------------------------------

local function FormatRemaining(seconds)
    if seconds >= 60 then
        return string.format("%dm", math.ceil(seconds / 60));
    elseif seconds >= 10 then
        return string.format("%d", math.floor(seconds));
    end
    return string.format("%.1f", seconds);
end

-- spell icons are square textures; crop them (after the usual border trim) so they fill the
-- non-square button without stretching
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

-- units we can read auras from in Classic Era: whatever has a nameplate, plus the target
local nameplateUnits = {};

local function ForEachTrackedUnit(func)
    local seen = {};
    local function visit(unit)
        if not unit or not UnitExists(unit) then return end
        local guid = UnitGUID(unit);
        if not guid or seen[guid] then return end
        seen[guid] = true;
        func(unit);
    end
    for unit in pairs(nameplateUnits) do visit(unit) end
    visit("target");
end

local function FindAuraOnUnit(unit, spellID, filter)
    local found = nil;
    AuraUtil.ForEachAura(unit, filter, nil, function(auraData)
        if auraData.spellId == spellID then
            found = auraData;
            return true;
        end
        return false;
    end, true);
    return found;
end

local function CountUnitsWithAura(spellID, filter)
    local count = 0;
    ForEachTrackedUnit(function(unit)
        if FindAuraOnUnit(unit, spellID, filter) then
            count = count + 1;
        end
    end)
    return count;
end

local function GetCastsRemaining(entry, spellID)
    local cost, powerType = entry.powerCost, entry.powerType;
    if not cost then
        cost, powerType = GetSpellPowerCost(spellID);
    end
    if not cost or cost <= 0 or not powerType then return nil end

    local current = UnitPower("player", powerType);
    if issecretvalue and issecretvalue(current) then return nil end

    return math.floor(current / cost);
end

-- icon construction ------------------------------------------------------------------------

local function CreateIcon(parent, entry)
    local button = CreateFrame("Frame", nil, parent);
    button:SetSize(ICON_WIDTH, ICON_HEIGHT);
    button.entry = entry;

    button.border = button:CreateTexture(nil, "BACKGROUND");
    button.border:SetPoint("TOPLEFT", -1, 1);
    button.border:SetPoint("BOTTOMRIGHT", 1, -1);
    button.border:SetColorTexture(0, 0, 0);

    button.icon = button:CreateTexture(nil, "ARTWORK");
    button.icon:SetAllPoints();
    button.icon:SetTexture(C_Spell.GetSpellTexture(entry.spellID));
    button.icon:SetTexCoord(GetCroppedTexCoords(ICON_WIDTH, ICON_HEIGHT));

    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate");
    button.cooldown:SetAllPoints();
    button.cooldown:SetHideCountdownNumbers(true);
    button.cooldown:SetDrawEdge(false);

    -- centre slot: cooldown remaining (spells) / aura duration on target (auras)
    button.centreText = button:CreateFontString(nil, "OVERLAY");
    button.centreText:SetPoint("CENTER", 0, 0);
    button.centreText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE");

    -- bottom right slot: how many casts the current resources allow
    button.castCountText = button:CreateFontString(nil, "OVERLAY");
    button.castCountText:SetPoint("BOTTOMRIGHT", -1, 1);
    button.castCountText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE");

    -- top right slot: how many targets currently have the tracked aura
    button.auraCountText = button:CreateFontString(nil, "OVERLAY");
    button.auraCountText:SetPoint("TOPRIGHT", -1, -1);
    button.auraCountText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE");
    button.auraCountText:SetTextColor(0.6, 0.9, 1);

    return button;
end

local function UpdateSpellIcon(button)
    local entry = button.entry;
    local spellID = entry.spellID;

    local start, duration, enabled = GetSpellCooldownInfo(spellID);
    local onCooldown = enabled and duration and duration > GCD_THRESHOLD;

    if entry.showCooldownSwipe ~= false then
        CooldownFrame_Set(button.cooldown, start, duration, onCooldown and 1 or 0);
    end

    if entry.showCooldownText ~= false and onCooldown then
        local remaining = (start + duration) - GetTime();
        button.centreText:SetText(remaining > 0 and FormatRemaining(remaining) or "");
    else
        button.centreText:SetText("");
    end

    if entry.showCastCount then
        local casts = GetCastsRemaining(entry, spellID);
        button.castCountText:SetText(casts and tostring(casts) or "");
    end

    if entry.trackedAuraSpellID then
        local count = CountUnitsWithAura(entry.trackedAuraSpellID, entry.trackedAuraFilter or "HARMFUL|PLAYER");
        button.auraCountText:SetText(count > 0 and tostring(count) or "");
    end

    if entry.resourceDesaturate then
        local _, noResource = C_Spell.IsSpellUsable(spellID);
        button.icon:SetDesaturated(noResource and true or false);
    end

    if entry.rangeCheck then
        local inRange = UnitExists("target") and C_Spell.IsSpellInRange(spellID, "target");
        if inRange == false then
            button.icon:SetVertexColor(OUT_OF_RANGE_COLOUR.r, OUT_OF_RANGE_COLOUR.g, OUT_OF_RANGE_COLOUR.b);
        else
            button.icon:SetVertexColor(1, 1, 1);
        end
    end
end

local function UpdateAuraIcon(button)
    local entry = button.entry;
    local filter = entry.auraFilter or "HARMFUL|PLAYER";

    if entry.showTargetDuration then
        local auraData = UnitExists("target") and FindAuraOnUnit("target", entry.spellID, filter);
        local expiration = auraData and auraData.expirationTime;
        if expiration and expiration > 0 then
            local remaining = expiration - GetTime();
            button.centreText:SetText(remaining > 0 and FormatRemaining(remaining) or "");
        else
            button.centreText:SetText("");
        end
        button.icon:SetDesaturated(auraData == nil or auraData == false);
    end

    if entry.showTargetCount then
        local count = CountUnitsWithAura(entry.spellID, filter);
        button.auraCountText:SetText(count > 0 and tostring(count) or "");
    end

    if entry.castCountSpellID then
        local casts = GetCastsRemaining(entry, entry.castCountSpellID);
        button.castCountText:SetText(casts and tostring(casts) or "");
    end
end

-- frame ------------------------------------------------------------------------------------

function core:CreateAuraTracker(parent)
    local frame = CreateFrame("Frame", "PlayerAuraTrackerContainer", parent);
    frame:SetSize(core.width, ICON_HEIGHT);

    local playerClass = select(2, UnitClass("player"));
    local entries = core.auraTracker[playerClass];
    if not entries or #entries == 0 then return frame end

    local icons = {};
    for _, entry in ipairs(entries) do
        table.insert(icons, CreateIcon(frame, entry));
    end

    -- icons grow left to right in declaration order, hidden ones collapse out of the row; the
    -- leftover width is split evenly between the gaps so the outermost icon edges line up with
    -- the edges of the bars above
    local function layout()
        local shown = 0;
        for _, button in ipairs(icons) do
            if button.visible then shown = shown + 1 end
        end

        local spacing = MIN_ICON_SPACING;
        if shown > 1 then
            spacing = math.max(MIN_ICON_SPACING, (core.width - shown * ICON_WIDTH) / (shown - 1));
        end

        local rowWidth = shown * ICON_WIDTH + math.max(0, shown - 1) * spacing;
        local index = 0;
        for _, button in ipairs(icons) do
            if button.visible then
                button:ClearAllPoints();
                button:SetPoint("LEFT", frame, "LEFT", index * (ICON_WIDTH + spacing), 0);
                button:Show();
                index = index + 1;
            else
                button:Hide();
            end
        end

        frame:SetSize(math.max(1, rowWidth), ICON_HEIGHT);
    end

    local function updateVisibility()
        local changed = false;
        for _, button in ipairs(icons) do
            local entry = button.entry;
            local visible = entry.alwaysShow or IsSpellKnown(entry.spellID);
            if visible ~= button.visible then
                button.visible = visible;
                changed = true;
            end
        end
        if changed then layout() end
    end

    local function updateAll()
        for _, button in ipairs(icons) do
            if button.visible then
                if button.entry.type == "aura" then
                    UpdateAuraIcon(button);
                else
                    UpdateSpellIcon(button);
                end
            end
        end
    end

    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterEvent("LEARNED_SPELL_IN_TAB");
    frame:RegisterEvent("SPELLS_CHANGED");
    frame:RegisterEvent("PLAYER_TARGET_CHANGED");
    frame:RegisterEvent("NAME_PLATE_UNIT_ADDED");
    frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED");
    frame:RegisterEvent("UNIT_AURA");
    frame:RegisterEvent("SPELL_UPDATE_COOLDOWN");
    frame:RegisterEvent("SPELL_UPDATE_USABLE");
    frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player");
    frame:RegisterUnitEvent("UNIT_MAXPOWER", "player");

    frame:SetScript("OnEvent", function(_, event, unit)
        if event == "NAME_PLATE_UNIT_ADDED" then
            nameplateUnits[unit] = true;
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            nameplateUnits[unit] = nil;
        elseif event == "PLAYER_ENTERING_WORLD"
            or event == "LEARNED_SPELL_IN_TAB"
            or event == "SPELLS_CHANGED" then
            updateVisibility();
        end
        updateAll();
    end)

    local elapsedSinceUpdate = 0;
    frame:SetScript("OnUpdate", function(_, elapsed)
        elapsedSinceUpdate = elapsedSinceUpdate + elapsed;
        if elapsedSinceUpdate < UPDATE_INTERVAL then return end
        elapsedSinceUpdate = 0;
        updateAll();
    end)

    updateVisibility();
    layout();
    updateAll();

    return frame;
end
