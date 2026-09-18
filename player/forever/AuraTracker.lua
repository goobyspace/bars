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

local function FindAuraOnUnit(unit, entry)
    for _, spellID in ipairs(entry.rankSpellIDs or { entry.spellID }) do
        local auraData = C_UnitAuras.GetUnitAuraBySpellID(unit, spellID);
        if auraData then return auraData end
    end
end

local function ClearCooldown(cooldown)
    CooldownFrame_Set(cooldown, 0, 0, 0);
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

    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate");
    button.cooldown:SetAllPoints();
    button.cooldown:SetHideCountdownNumbers(false);
    button.cooldown:SetDrawEdge(false);

    return button;
end

local function UpdateSpellIcon(button)
    local entry = button.entry;
    local spellID = button.spellID;

    if entry.showCooldownSwipe ~= false then
        local duration = C_Spell.GetSpellCooldownDuration(spellID);
        if duration then
            button.cooldown:SetCooldownDuration(duration);
        else
            ClearCooldown(button.cooldown);
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

    if entry.resourceDesaturate or entry.rangeCheck then
        local isUsable = C_Spell.IsSpellUsable(spellID);
        button.icon:SetDesaturated(invalidTarget or (entry.resourceDesaturate and not isUsable) or false);
    end
end

local function UpdateAuraIcon(button)
    local auraData = UnitExists("target") and FindAuraOnUnit("target", button.entry) or nil;
    if auraData then
        local duration = C_UnitAuras.GetAuraDuration("target", auraData.auraInstanceID);
        if duration then
            button.cooldown:SetCooldownDuration(duration);
        else
            ClearCooldown(button.cooldown);
        end
    else
        ClearCooldown(button.cooldown);
    end
    button.icon:SetDesaturated(not auraData);
end

local function UpdateReminderIcon(button)
    local auraData = FindAuraOnUnit("player", button.entry);
    if auraData then
        local duration = C_UnitAuras.GetAuraDuration("player", auraData.auraInstanceID);
        if duration then
            button.cooldown:SetCooldownDuration(duration);
        else
            ClearCooldown(button.cooldown);
        end
    else
        ClearCooldown(button.cooldown);
    end
    button.icon:SetDesaturated(not auraData);
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
            local knownSpellID = GetKnownSpellID(button.entry);
            local spellID = knownSpellID or GetFallbackSpellID(button.entry);
            if spellID ~= button.spellID then
                button.spellID = spellID;
                button.icon:SetTexture(C_Spell.GetSpellTexture(spellID));
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
    frame:RegisterEvent("UNIT_AURA");
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
