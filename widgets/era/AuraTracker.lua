local _, core = ...;
local colours = core.colours;

if not core.isClassicEra then return; end;

local iconWidth = 36;
local iconHeight = 30;

local slotCount = 8;
local minIconSpacing = 2;

local updateInterval = 0.1;

local gcdThreshold = 1.5;

local outOfRangeColour = colours.outOfRange;

local function getSpellCooldownInfo(spellID)
    local info = C_Spell.GetSpellCooldown(spellID);
    if not info then return 0, 0, false; end;
    return info.startTime, info.duration, info.isEnabled;
end;

local function getSpellPowerCost(spellID)
    local costs = C_Spell.GetSpellPowerCost(spellID);
    if not costs then return nil; end;
    for _, cost in ipairs(costs) do
        if cost.cost and cost.cost > 0 then
            return cost.cost, cost.type;
        end;
    end;
    return nil;
end;

local function isSpellKnown(spellID)
    return C_SpellBook.IsSpellKnown(spellID) or C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Pet);
end;

local function getKnownSpellID(entry)
    if entry.rankSpellIDs then
        local known = nil;
        for _, spellID in ipairs(entry.rankSpellIDs) do
            if isSpellKnown(spellID) then known = spellID; end;
        end;
        return known;
    end;
    return isSpellKnown(entry.spellID) and entry.spellID or nil;
end;

local function getEntryAuraIDs(entry)
    if not entry.auraIDs then
        local ids = {};
        for _, spellID in ipairs(entry.rankSpellIDs or { entry.spellID }) do
            ids[spellID] = true;
        end;
        entry.auraIDs = ids;
    end;
    return entry.auraIDs;
end;

local function getFallbackSpellID(entry)
    return entry.spellID or (entry.rankSpellIDs and entry.rankSpellIDs[#entry.rankSpellIDs]);
end;

local function entryAllowedInCurrentForm(entry, currentForm)
    local form = entry.form;
    if not form then return true; end;
    if form:sub(1, 1) == "!" then return form:sub(2) ~= currentForm; end;
    return form == currentForm;
end;

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

-- units we can read auras from in Classic Era: whatever has a nameplate, plus the target
local nameplateUnits = {};

local function forEachTrackedUnit(func)
    local seen = {};
    local function visit(unit)
        if not unit or not UnitExists(unit) then return; end;
        local guid = UnitGUID(unit);
        if not guid or seen[guid] then return; end;
        seen[guid] = true;
        func(unit);
    end;
    for unit in pairs(nameplateUnits) do visit(unit); end;
    visit("target");
end;

local function findAuraOnUnit(unit, auraIDs, filter)
    local found = nil;
    AuraUtil.ForEachAura(unit, filter, nil, function(auraData)
        if auraIDs[auraData.spellId] then
            found = auraData;
            return true;
        end;
        return false;
    end, true);
    return found;
end;

local function countUnitsWithAura(auraIDs, filter)
    local count = 0;
    forEachTrackedUnit(function(unit)
        if findAuraOnUnit(unit, auraIDs, filter) then
            count = count + 1;
        end;
    end);
    return count;
end;

local function getCastsRemaining(entry, spellID)
    local cost, powerType = entry.powerCost, entry.powerType;
    if not cost then
        cost, powerType = getSpellPowerCost(spellID);
    end;
    if not cost or cost <= 0 or not powerType then return nil; end;

    local current = UnitPower("player", powerType);
    if issecretvalue and issecretvalue(current) then return nil; end;

    return math.floor(current / cost);
end;

local textAnchors = {
    [1] = { "CENTER" },
    [2] = { "TOP", "BOTTOM" },
    [3] = { "TOP", "CENTER", "BOTTOM" },
};

local function getEntryTexts(entry)
    local texts = {};
    if entry.showTargetCount or entry.trackedAuraSpellID then
        table.insert(texts, "auraCountText");
    end;
    if entry.showCastCount then
        table.insert(texts, "castCountText");
    end;
    if entry.type == "reminder"
        or (entry.type == "aura" and entry.showTargetDuration)
        or (entry.type ~= "aura" and entry.type ~= "reminder" and entry.showCooldownText ~= false) then
        table.insert(texts, "centreText");
    end;
    return texts;
end;

local function createIcon(parent, entry)
    local button = CreateFrame("Frame", nil, parent);
    core:SetPixelSize(button, iconWidth, iconHeight);
    button.entry = entry;
    button.spellID = getKnownSpellID(entry) or getFallbackSpellID(entry);

    button.border = button:CreateTexture(nil, "BACKGROUND");
    core:SetPixelPoint(button.border, "TOPLEFT", button, "TOPLEFT", 0, 0);
    core:SetPixelPoint(button.border, "BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0);
    button.border:SetColorTexture(colours.black.r, colours.black.g, colours.black.b);

    button.icon = button:CreateTexture(nil, "ARTWORK");
    core:SetPixelPoint(button.icon, "TOPLEFT", button, "TOPLEFT", core.pixel, -core.pixel);
    core:SetPixelPoint(button.icon, "BOTTOMRIGHT", button, "BOTTOMRIGHT", -core.pixel, core.pixel);
    button.icon:SetTexture(C_Spell.GetSpellTexture(button.spellID));
    button.icon:SetTexCoord(getCroppedTexCoords(iconWidth, iconHeight));

    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate");
    button.cooldown:SetAllPoints();
    button.cooldown:SetHideCountdownNumbers(true);
    button.cooldown:SetDrawEdge(false);

    button.centreText = button:CreateFontString(nil, "OVERLAY");

    button.castCountText = button:CreateFontString(nil, "OVERLAY");

    button.auraCountText = button:CreateFontString(nil, "OVERLAY");
    button.auraCountText:SetTextColor(colours.auraCountText.r, colours.auraCountText.g, colours.auraCountText.b);

    for _, key in ipairs({ "centreText", "castCountText", "auraCountText" }) do
        button[key]:SetPoint("CENTER", 0, 0);
        core:SetBarFont(button[key], 11);
    end;

    local texts = getEntryTexts(entry);
    local anchors = textAnchors[#texts];
    for index, key in ipairs(texts) do
        local anchor = anchors[index];
        local offset = (anchor == "TOP" and -1) or (anchor == "BOTTOM" and 1) or 0;
        button[key]:ClearAllPoints();
        button[key]:SetPoint(anchor, 0, offset);
        core:SetBarFont(button[key], anchor == "CENTER" and 13 or 11);
    end;

    return button;
end;

local function updateSpellIcon(button)
    local entry = button.entry;
    local spellID = button.spellID;

    local start, duration, enabled = getSpellCooldownInfo(spellID);
    local onCooldown = enabled and duration and duration > gcdThreshold;

    if entry.showCooldownSwipe ~= false then
        CooldownFrame_Set(button.cooldown, start, duration, onCooldown and 1 or 0);
    end;

    if entry.showCooldownText ~= false and onCooldown then
        local remaining = (start + duration) - GetTime();
        button.centreText:SetText(remaining > 0 and formatRemaining(remaining) or "");
    else
        button.centreText:SetText("");
    end;

    if entry.showCastCount then
        local casts = getCastsRemaining(entry, spellID);
        button.castCountText:SetText(casts and tostring(casts) or "");
    end;

    if entry.trackedAuraSpellID then
        entry.trackedAuraIDs = entry.trackedAuraIDs or { [entry.trackedAuraSpellID] = true };
        local count = countUnitsWithAura(entry.trackedAuraIDs, entry.trackedAuraFilter or "HARMFUL|PLAYER");
        button.auraCountText:SetText(count > 0 and tostring(count) or "");
    end;

    local invalidTarget = false;
    if entry.rangeCheck then
        local hasTarget = UnitExists("target");
        -- IsSpellInRange reports true for units the spell can't be cast on at all
        invalidTarget = hasTarget and not UnitCanAttack("player", "target");
        local inRange = hasTarget and not invalidTarget and C_Spell.IsSpellInRange(spellID, "target");
        if inRange == false then
            button.icon:SetVertexColor(outOfRangeColour.r, outOfRangeColour.g, outOfRangeColour.b);
        else
            button.icon:SetVertexColor(colours.white.r, colours.white.g, colours.white.b);
        end;
    end;

    if entry.resourceDesaturate or entry.rangeCheck then
        -- isUsable is false for any reason the spell can't be cast (missing shield/weapon,
        -- wrong stance, insufficient resources, etc.), not just resource shortage
        local isUsable = C_Spell.IsSpellUsable(spellID);
        button.icon:SetDesaturated(invalidTarget or (entry.resourceDesaturate and not isUsable) or false);
    end;
end;

local function updateAuraIcon(button)
    local entry = button.entry;
    local filter = entry.auraFilter or "HARMFUL|PLAYER";
    local auraIDs = getEntryAuraIDs(entry);

    if entry.showTargetDuration or entry.showTargetSwipe then
        local auraData = UnitExists("target") and findAuraOnUnit("target", auraIDs, filter) or nil;
        local expiration = auraData and auraData.expirationTime;
        local remaining = expiration and expiration > 0 and (expiration - GetTime()) or 0;

        if entry.showTargetDuration then
            button.centreText:SetText(remaining > 0 and formatRemaining(remaining) or "");
        end;

        if entry.showTargetSwipe then
            local total = auraData and auraData.duration or 0;
            if remaining > 0 and total > 0 then
                CooldownFrame_Set(button.cooldown, expiration - total, total, 1);
            else
                CooldownFrame_Set(button.cooldown, 0, 0, 0);
            end;
        end;

        button.icon:SetDesaturated(auraData == nil);
    end;

    if entry.showTargetCount then
        local count = countUnitsWithAura(auraIDs, filter);
        button.auraCountText:SetText(count > 0 and tostring(count) or "");
    end;

    local castCountSpellID = entry.showCastCount and (entry.castCountSpellID or button.spellID);
    if castCountSpellID then
        local casts = getCastsRemaining(entry, castCountSpellID);
        button.castCountText:SetText(casts and tostring(casts) or "");
    end;
end;

local function updateReminderIcon(button)
    local entry = button.entry;
    local filter = entry.auraFilter or "HELPFUL|PLAYER";

    local auraData = findAuraOnUnit("player", getEntryAuraIDs(entry), filter);
    local expiration = auraData and auraData.expirationTime;
    if expiration and expiration > 0 then
        local remaining = expiration - GetTime();
        button.centreText:SetText(remaining > 0 and formatRemaining(remaining) or "");
    else
        button.centreText:SetText("");
    end;
    button.icon:SetDesaturated(auraData == nil);
end;

function core:CreateAuraTracker(parent)
    local frame = CreateFrame("Frame", "PlayerAuraTrackerContainer", parent);
    core:SetPixelSize(frame, core.width, iconHeight);

    local playerClass = select(2, UnitClass("player"));
    local entries = core.auraTracker[playerClass];
    if not entries or #entries == 0 then return frame; end;

    local icons = {};
    for index, entry in ipairs(entries) do
        local button = createIcon(frame, entry);
        button.slot = entry.slot or index;
        table.insert(icons, button);
    end;

    local function layout()
        local step = math.max(iconWidth + minIconSpacing, (core.width - iconWidth) / (slotCount - 1));
        for _, button in ipairs(icons) do
            button:ClearAllPoints();
            core:SetPixelPoint(button, "LEFT", frame, "LEFT", (button.slot - 1) * step, 0);
            button:SetShown(button.visible);
        end;

        core:SetPixelSize(frame, core.width, iconHeight);
    end;

    local function updateVisibility()
        local changed = false;
        local currentForm = core:GetShapeshiftFormKey();
        for _, button in ipairs(icons) do
            local entry = button.entry;
            local knownSpellID = getKnownSpellID(entry);
            local spellID = knownSpellID or getFallbackSpellID(entry);
            if spellID ~= button.spellID then
                button.spellID = spellID;
                button.icon:SetTexture(C_Spell.GetSpellTexture(spellID));
            end;

            local visible = (entry.alwaysShow or knownSpellID ~= nil) and entryAllowedInCurrentForm(entry, currentForm);
            if visible ~= button.visible then
                button.visible = visible;
                changed = true;
            end;
        end;
        if changed then layout(); end;
    end;

    local function updateAll()
        for _, button in ipairs(icons) do
            if button.visible then
                if button.entry.type == "aura" then
                    updateAuraIcon(button);
                elseif button.entry.type == "reminder" then
                    updateReminderIcon(button);
                else
                    updateSpellIcon(button);
                end;
            end;
        end;
    end;

    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE");
    frame:RegisterEvent("SPELLS_CHANGED");
    frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM");
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
            or event == "LEARNED_SPELL_IN_SKILL_LINE"
            or event == "SPELLS_CHANGED"
            or event == "UPDATE_SHAPESHIFT_FORM" then
            updateVisibility();
        end;
        updateAll();
    end);

    local elapsedSinceUpdate = 0;
    frame:SetScript("OnUpdate", function(_, elapsed)
        elapsedSinceUpdate = elapsedSinceUpdate + elapsed;
        if elapsedSinceUpdate < updateInterval then return; end;
        elapsedSinceUpdate = 0;
        updateAll();
    end);

    updateVisibility();
    layout();
    updateAll();

    return frame;
end;
