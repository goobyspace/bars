local _, core = ...
local colours = core.colours

if not core.isClassicEra then return end

local iconWidth = 36;
local iconHeight = 30;

local slotCount = 8;
local minIconSpacing = 2;

local updateInterval = 0.1;

local gcdThreshold = 1.5;

local outOfRangeColour = colours.outOfRange;

--[[
    core.auraTracker is keyed by class token, each value being a list of entries.

    Shared fields:
        type            "spell" | "aura" | "reminder"
        slot            which of the SLOT_COUNT positions in the row the icon occupies (1 = left)
        spellID         spellID used for the icon texture, cooldown, range and usability
        rankSpellIDs    ordered list of rank spellIDs (lowest first); the highest known rank is
                        used in place of spellID, and every rank matches when reading auras
        alwaysShow      show the icon even when the spell isn't known (default false)
        form            restrict visibility to a shapeshift form key from core:GetShapeshiftFormKey()
                        (e.g. "CAT", "BEAR", "MOONKIN", "AQUATIC", "TRAVEL"): shows the icon
                        only in that form; prefixing with "!" (e.g. "!CAT") shows it everywhere
                        except that form (default: always)

    Text placement is automatic: a single text sits in the centre of the icon, two split into
    top and bottom, three use top / centre / bottom.

    type == "spell":
        showCooldownSwipe   draw the cooldown swipe (default true)
        showCooldownText    text with the cooldown remaining (default true)
        showCastCount       text with how many casts the current resources allow
        rangeCheck          red when the target is out of range, desaturated when the spell
                            can't be used on the current target at all
        resourceDesaturate  desaturate the icon when there aren't enough resources
        trackedAuraSpellID  optional aura to count; shows how many targets have it
        trackedAuraFilter   aura filter for the above (default "HARMFUL|PLAYER")

    type == "aura":
        showTargetCount     text with how many targets currently have the aura
        showTargetDuration  text with the time left on the aura on the current target
        showTargetSwipe     drain the cooldown swipe over the aura's remaining duration
        showCastCount       text with how many casts the current resources allow
        auraFilter          aura filter used for the above (default "HARMFUL|PLAYER")
        castCountSpellID    spellID whose resource cost drives the "casts remaining" text
                            (defaults to the icon's own spellID / highest known rank)

    type == "reminder":
        icon is grayed out while the aura isn't active on the player, and shows full colour
        with a countdown while it is (e.g. a self buff to keep rolling)
        auraFilter          aura filter to look for the aura with (default "HELPFUL|PLAYER")

    Optional overrides for the resource maths (when the API cost lookup isn't right):
        powerCost           flat resource cost per cast
        powerType           Enum.PowerType.* the cost is paid from
]]

core.auraTracker = {
    ["DRUID"] = {
        {
            type = "aura",
            slot = 1,
            -- moonfire
            rankSpellIDs = { 8921, 8924, 8925, 8926, 8927, 8928, 8929, 9833, 9834, 9835 },
            form = "!CAT",
            showTargetDuration = true,
            showTargetSwipe = true,
            showCastCount = true,
        },
        {
            type = "spell",
            slot = 2,
            -- wrath
            rankSpellIDs = { 5176, 5177, 5178, 5179, 5180, 6780, 8905, 9912 },
            form = "!CAT",
            rangeCheck = true,
            showCooldownText = false,
            showCastCount = true,
        },
        {
            type = "aura",
            slot = 1,
            -- rip
            rankSpellIDs = { 1079, 9492, 9493, 9752, 9894, 9896 },
            form = "CAT",
            showTargetDuration = true,
            showTargetSwipe = true,
            showCastCount = true,
        },
        {
            type = "aura",
            slot = 2,
            -- rake
            rankSpellIDs = { 1822, 1823, 1824, 9904 },
            form = "CAT",
            showTargetDuration = true,
            showTargetSwipe = true,
            showCastCount = true,
        },
        {
            type = "spell",
            slot = 3,
            -- healing touch
            rankSpellIDs = { 5185, 5186, 5187, 5188, 5189, 6778, 8903, 9758, 9888, 9889, 25297 },
            showCooldownText = false,
            showCastCount = true,
        },
        {
            type = "reminder",
            slot = 7,
            -- thorns
            rankSpellIDs = { 467, 782, 1075, 8914, 9756, 9910 },
            alwaysShow = true,
        },
        {
            type = "reminder",
            slot = 8,
            -- motw
            rankSpellIDs = { 1126, 5232, 6756, 5234, 8907, 9884, 9885 },
            alwaysShow = true,
        },
    },
};

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

local function GetKnownSpellID(entry)
    if entry.rankSpellIDs then
        local known = nil;
        for _, spellID in ipairs(entry.rankSpellIDs) do
            if IsSpellKnown(spellID) then known = spellID end
        end
        return known;
    end
    return IsSpellKnown(entry.spellID) and entry.spellID or nil;
end

local function GetEntryAuraIDs(entry)
    if not entry.auraIDs then
        local ids = {};
        for _, spellID in ipairs(entry.rankSpellIDs or { entry.spellID }) do
            ids[spellID] = true;
        end
        entry.auraIDs = ids;
    end
    return entry.auraIDs;
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

local function FormatRemaining(seconds)
    if seconds >= 60 then
        return string.format("%dm", math.ceil(seconds / 60));
    elseif seconds >= 10 then
        return string.format("%d", math.floor(seconds));
    end
    return string.format("%.1f", seconds);
end

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

local function FindAuraOnUnit(unit, auraIDs, filter)
    local found = nil;
    AuraUtil.ForEachAura(unit, filter, nil, function(auraData)
        if auraIDs[auraData.spellId] then
            found = auraData;
            return true;
        end
        return false;
    end, true);
    return found;
end

local function CountUnitsWithAura(auraIDs, filter)
    local count = 0;
    ForEachTrackedUnit(function(unit)
        if FindAuraOnUnit(unit, auraIDs, filter) then
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

local textAnchors = {
    [1] = { "CENTER" },
    [2] = { "TOP", "BOTTOM" },
    [3] = { "TOP", "CENTER", "BOTTOM" },
};

local function GetEntryTexts(entry)
    local texts = {};
    if entry.showTargetCount or entry.trackedAuraSpellID then
        table.insert(texts, "auraCountText");
    end
    if entry.showCastCount then
        table.insert(texts, "castCountText");
    end
    if entry.type == "reminder"
        or (entry.type == "aura" and entry.showTargetDuration)
        or (entry.type ~= "aura" and entry.type ~= "reminder" and entry.showCooldownText ~= false) then
        table.insert(texts, "centreText");
    end
    return texts;
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
    button.icon:SetTexCoord(GetCroppedTexCoords(iconWidth, iconHeight));

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
    end

    local texts = GetEntryTexts(entry);
    local anchors = textAnchors[#texts];
    for index, key in ipairs(texts) do
        local anchor = anchors[index];
        local offset = (anchor == "TOP" and -1) or (anchor == "BOTTOM" and 1) or 0;
        button[key]:ClearAllPoints();
        button[key]:SetPoint(anchor, 0, offset);
        core:SetBarFont(button[key], anchor == "CENTER" and 13 or 11);
    end

    return button;
end

local function UpdateSpellIcon(button)
    local entry = button.entry;
    local spellID = button.spellID;

    local start, duration, enabled = GetSpellCooldownInfo(spellID);
    local onCooldown = enabled and duration and duration > gcdThreshold;

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
        entry.trackedAuraIDs = entry.trackedAuraIDs or { [entry.trackedAuraSpellID] = true };
        local count = CountUnitsWithAura(entry.trackedAuraIDs, entry.trackedAuraFilter or "HARMFUL|PLAYER");
        button.auraCountText:SetText(count > 0 and tostring(count) or "");
    end

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
        end
    end

    if entry.resourceDesaturate or entry.rangeCheck then
        local _, noResource = C_Spell.IsSpellUsable(spellID);
        button.icon:SetDesaturated(invalidTarget or (entry.resourceDesaturate and noResource) or false);
    end
end

local function UpdateAuraIcon(button)
    local entry = button.entry;
    local filter = entry.auraFilter or "HARMFUL|PLAYER";
    local auraIDs = GetEntryAuraIDs(entry);

    if entry.showTargetDuration or entry.showTargetSwipe then
        local auraData = UnitExists("target") and FindAuraOnUnit("target", auraIDs, filter) or nil;
        local expiration = auraData and auraData.expirationTime;
        local remaining = expiration and expiration > 0 and (expiration - GetTime()) or 0;

        if entry.showTargetDuration then
            button.centreText:SetText(remaining > 0 and FormatRemaining(remaining) or "");
        end

        if entry.showTargetSwipe then
            local total = auraData and auraData.duration or 0;
            if remaining > 0 and total > 0 then
                CooldownFrame_Set(button.cooldown, expiration - total, total, 1);
            else
                CooldownFrame_Set(button.cooldown, 0, 0, 0);
            end
        end

        button.icon:SetDesaturated(auraData == nil);
    end

    if entry.showTargetCount then
        local count = CountUnitsWithAura(auraIDs, filter);
        button.auraCountText:SetText(count > 0 and tostring(count) or "");
    end

    local castCountSpellID = entry.showCastCount and (entry.castCountSpellID or button.spellID);
    if castCountSpellID then
        local casts = GetCastsRemaining(entry, castCountSpellID);
        button.castCountText:SetText(casts and tostring(casts) or "");
    end
end

local function UpdateReminderIcon(button)
    local entry = button.entry;
    local filter = entry.auraFilter or "HELPFUL|PLAYER";

    local auraData = FindAuraOnUnit("player", GetEntryAuraIDs(entry), filter);
    local expiration = auraData and auraData.expirationTime;
    if expiration and expiration > 0 then
        local remaining = expiration - GetTime();
        button.centreText:SetText(remaining > 0 and FormatRemaining(remaining) or "");
    else
        button.centreText:SetText("");
    end
    button.icon:SetDesaturated(auraData == nil);
end

function core:CreateAuraTracker(parent)
    local frame = CreateFrame("Frame", "PlayerAuraTrackerContainer", parent);
    frame:SetSize(core.width, iconHeight);

    local playerClass = select(2, UnitClass("player"));
    local entries = core.auraTracker[playerClass];
    if not entries or #entries == 0 then return frame end

    local icons = {};
    for index, entry in ipairs(entries) do
        local button = CreateIcon(frame, entry);
        button.slot = entry.slot or index;
        table.insert(icons, button);
    end

    local function layout()
        local step = math.max(iconWidth + minIconSpacing, (core.width - iconWidth) / (slotCount - 1));
        for _, button in ipairs(icons) do
            button:ClearAllPoints();
            button:SetPoint("LEFT", frame, "LEFT", (button.slot - 1) * step, 0);
            button:SetShown(button.visible);
        end

        frame:SetSize(core.width, iconHeight);
    end

    local function updateVisibility()
        local changed = false;
        local currentForm = core:GetShapeshiftFormKey();
        for _, button in ipairs(icons) do
            local entry = button.entry;
            local knownSpellID = GetKnownSpellID(entry);
            local spellID = knownSpellID or GetFallbackSpellID(entry);
            if spellID ~= button.spellID then
                button.spellID = spellID;
                button.icon:SetTexture(C_Spell.GetSpellTexture(spellID));
            end

            local visible = (entry.alwaysShow or knownSpellID ~= nil) and EntryAllowedInCurrentForm(entry, currentForm);
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
                elseif button.entry.type == "reminder" then
                    UpdateReminderIcon(button);
                else
                    UpdateSpellIcon(button);
                end
            end
        end
    end

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
        end
        updateAll();
    end)

    local elapsedSinceUpdate = 0;
    frame:SetScript("OnUpdate", function(_, elapsed)
        elapsedSinceUpdate = elapsedSinceUpdate + elapsed;
        if elapsedSinceUpdate < updateInterval then return end
        elapsedSinceUpdate = 0;
        updateAll();
    end)

    updateVisibility();
    layout();
    updateAll();

    return frame;
end
