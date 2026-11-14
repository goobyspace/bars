local _, core = ...;
local colours = core.colours;

if not core.isForever then return; end;

local iconWidth = core.auraTrackerLayout.iconWidth;
local iconHeight = core.auraTrackerLayout.iconHeight;
local spacing = core.auraTrackerLayout.minIconSpacing;
local perRow = core.cooldownTrackerLayout.perRow;
local pollInterval = 0.25;

local inventorySlots = {
    HEAD = 1, NECK = 2, SHOULDER = 3, BODY = 4, CHEST = 5, WAIST = 6, LEGS = 7, FEET = 8, WRIST = 9,
    HANDS = 10, FINGER1 = 11, FINGER2 = 12, TRINKET1 = 13, TRINKET2 = 14, BACK = 15,
    MAINHAND = 16, OFFHAND = 17, RANGED = 18,
};

local function resolveSpellID(spell)
    if type(spell) == "number" then
        return spell;
    elseif type(spell) == "string" then
        local spellInfo = C_Spell.GetSpellInfo(spell);
        return spellInfo and spellInfo.spellID;
    end;
end;

-- a list is treated as spell ranks, the highest known one is used
local function resolveKnownSpellID(spell)
    if type(spell) ~= "table" then return resolveSpellID(spell); end;
    local known;
    for _, rank in ipairs(spell) do
        local spellID = resolveSpellID(rank);
        if spellID and (C_SpellBook.IsSpellKnown(spellID)
            or C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Pet)) then
            known = spellID;
        end;
    end;
    return known;
end;

local function createButton(parent, entry, resourceOnly)
    local button = CreateFrame("Frame", nil, parent);
    core:SetPixelSize(button, iconWidth, iconHeight);
    button.entry = entry;
    button.resourceOnly = resourceOnly;
    button.itemID = entry.item;
    button.slotID = type(entry.slot) == "string" and inventorySlots[entry.slot:upper()] or tonumber(entry.slot);

    local border = button:CreateTexture(nil, "BACKGROUND");
    border:SetAllPoints();
    border:SetColorTexture(colours.black.r, colours.black.g, colours.black.b);

    button.icon = button:CreateTexture(nil, "ARTWORK");
    core:SetPixelPoint(button.icon, "TOPLEFT", button, "TOPLEFT", core.pixel, -core.pixel);
    core:SetPixelPoint(button.icon, "BOTTOMRIGHT", button, "BOTTOMRIGHT", -core.pixel, core.pixel);
    button.icon:SetTexCoord(core:GetCroppedTexCoords(iconWidth, iconHeight));

    if resourceOnly then
        button.resourceOverlay = button:CreateTexture(nil, "OVERLAY");
        button.resourceOverlay:SetAllPoints(button.icon);
        button.resourceOverlay:SetColorTexture(colours.outOfRange.r, colours.outOfRange.g, colours.outOfRange.b, 0.45);
    end;

    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate");
    button.cooldown:SetAllPoints();
    button.cooldown:SetHideCountdownNumbers(entry.displayText == false);
    button.cooldown:SetDrawEdge(false);

    button.cooldownFallback = CreateFrame("StatusBar", nil, button);
    button.cooldownFallback:SetAllPoints();
    button.cooldownFallback:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    button.cooldownFallback:SetStatusBarColor(colours.black.r, colours.black.g, colours.black.b, 0.7);
    button.cooldownFallback:SetReverseFill(true);
    button.cooldownFallback:Hide();

    button:EnableMouse(true);
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP");
        if self.slotID then
            GameTooltip:SetInventoryItem("player", self.slotID);
        elseif self.itemID then
            GameTooltip:SetItemByID(self.itemID);
        elseif self.spellID then
            GameTooltip:SetSpellByID(self.spellID);
        end;
        GameTooltip:Show();
    end);
    button:SetScript("OnLeave", function() GameTooltip:Hide(); end);
    button:SetScript("OnHide", function(self)
        if GameTooltip:GetOwner() == self then GameTooltip:Hide(); end;
    end);

    button:Hide();
    return button;
end;

-- returns whether the button should be shown, and whether it needs polling to notice the cooldown ending
local function updateButton(button)
    local info, duration;
    if button.resourceOnly then
        button.cooldown:Clear();
        button.cooldownFallback:Hide();
        if not button.spellID then return false, false; end;
        button.icon:SetTexture(C_Spell.GetSpellTexture(button.spellID));
        local _, insufficientPower = C_Spell.IsSpellUsable(button.spellID);
        return insufficientPower == true, false;
    end;

    if button.slotID then
        button.itemID = GetInventoryItemID("player", button.slotID);
        if not button.itemID then
            button.cooldown:Clear();
            button.cooldownFallback:Hide();
            return false, false;
        end;
    end;

    if button.itemID then
        info = C_Spell.GetItemCooldown(button.itemID);
        button.icon:SetTexture(C_Item.GetItemIconByID(button.itemID));
    else
        button.spellID = resolveKnownSpellID(button.entry.spell);
        if not button.spellID then return false, false; end;
        info = C_Spell.GetSpellCooldown(button.spellID);
        button.icon:SetTexture(C_Spell.GetSpellTexture(button.spellID));
    end;

    if not info or not info["isActive"] or info["isOnGCD"] then
        button.cooldown:Clear();
        button.cooldownFallback:Hide();
        return false, false;
    end;

    if button.itemID then
        if not issecretvalue(info.startTime) and not issecretvalue(info.duration) then
            button.cooldown:SetCooldown(info.startTime, info.duration, info.modRate);
        end;
        return true, false;
    end;

    duration = C_Spell.GetSpellCooldownDuration(button.spellID);
    if not duration then return false, false; end;

    -- secret durations can be rejected, only then fall back to the bar
    if pcall(button.cooldown.SetCooldownFromDurationObject, button.cooldown, duration, true) then
        button.cooldownFallback:Hide();
        return true, false;
    end;

    button.cooldown:Clear();
    button.cooldownFallback:SetTimerDuration(duration, Enum.StatusBarInterpolation.ExponentialEaseOut,
        Enum.StatusBarTimerDirection.RemainingTime);
    button.cooldownFallback:Show();
    return true, true;
end;

function core:CreateCooldownTracker(parent, castbar)
    local frame = CreateFrame("Frame", "PlayerCooldownTrackerContainer", parent);
    core:SetPixelSize(frame, core.width, iconHeight);
    core:SetPixelPoint(frame, "TOPLEFT", castbar, "BOTTOMLEFT", 0, core.cooldownTrackerLayout.offsetY);

    local playerClass = select(2, UnitClass("player"));
    local buttons = {};
    for _, entries in ipairs({ core.foreverCooldownTracker.ALL or {}, core.foreverCooldownTracker[playerClass] or {} }) do
        for _, entry in ipairs(entries) do
            if entry.spell or entry.item or entry.slot then
                table.insert(buttons, createButton(frame, entry));
            end;
        end;
    end;
    local resourceTracker = core.foreverResourceTracker or {};
    for _, entries in ipairs({ resourceTracker.ALL or {}, resourceTracker[playerClass] or {} }) do
        for _, entry in ipairs(entries) do
            if entry.spell then
                local button = createButton(frame, entry, true);
                table.insert(buttons, button);
            end;
        end;
    end;
    if #buttons == 0 then return frame; end;

    local polling = false;

    local function resolveResourceSpells()
        local knownSpells = {};
        local function addSpell(slot, bank)
            local info = C_SpellBook.GetSpellBookItemInfo(slot, bank);
            if info and info.spellID and not knownSpells[info.name]
                and not C_SpellBook.IsSpellBookItemLowRank(slot, bank)
                and C_SpellBook.IsSpellKnown(info.spellID, bank) then
                knownSpells[info.name] = info.spellID;
            end;
        end;

        local playerBank = Enum.SpellBookSpellBank.Player;
        for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
            local skillLine = C_SpellBook.GetSpellBookSkillLineInfo(i);
            if skillLine then
                for slot = skillLine.itemIndexOffset + 1, skillLine.itemIndexOffset + skillLine.numSpellBookItems do
                    addSpell(slot, playerBank);
                end;
            end;
        end;
        local petBank = Enum.SpellBookSpellBank.Pet;
        for slot = 1, C_SpellBook.HasPetSpells() or 0 do
            addSpell(slot, petBank);
        end;

        for _, button in ipairs(buttons) do
            if button.resourceOnly then
                local spell = button.entry.spell;
                if type(spell) == "table" then
                    button.spellID = resolveKnownSpellID(spell);
                else
                    local info = type(spell) == "number" and C_Spell.GetSpellInfo(spell);
                    local name = info and info.name or type(spell) == "string" and spell;
                    button.spellID = knownSpells[name];
                end;
            end;
        end;
    end;

    local function refresh()
        local shown = 0;
        polling = false;
        for _, button in ipairs(buttons) do
            local active, needsPoll = updateButton(button);
            button:SetShown(active);
            polling = polling or needsPoll;
            if active then
                local column = shown % perRow;
                local row = math.floor(shown / perRow);
                button:ClearAllPoints();
                core:SetPixelPoint(button, "TOPLEFT", frame, "TOPLEFT",
                    column * (iconWidth + spacing), -row * (iconHeight + spacing));
                shown = shown + 1;
            end;
        end;
    end;

    for _, button in ipairs(buttons) do
        button.cooldown:SetScript("OnCooldownDone", refresh);
    end;

    local elapsedSincePoll = 0;
    frame:SetScript("OnUpdate", function(_, elapsed)
        if not polling then return; end;
        elapsedSincePoll = elapsedSincePoll + elapsed;
        if elapsedSincePoll < pollInterval then return; end;
        elapsedSincePoll = 0;
        refresh();
    end);

    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterEvent("SPELLS_CHANGED");
    frame:RegisterEvent("SPELL_UPDATE_COOLDOWN");
    frame:RegisterEvent("BAG_UPDATE_COOLDOWN");
    frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
    frame:RegisterEvent("SPELL_UPDATE_USABLE");
    frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player");
    frame:RegisterUnitEvent("UNIT_PET", "player");
    frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" or event == "SPELLS_CHANGED" or event == "UNIT_PET" then
            resolveResourceSpells();
        end;
        refresh();
    end);

    resolveResourceSpells();
    refresh();
    return frame;
end;
