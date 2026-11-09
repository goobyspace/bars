local _, core = ...;

local function createReminder(parent, entry, offset)
    local layout = core.auraTrackerLayout;
    local button = CreateFrame("Frame", nil, parent);
    core:SetPixelSize(button, layout.iconWidth, layout.iconHeight);
    core:SetPixelPoint(button, "LEFT", parent, "LEFT", offset, 0);

    local border = button:CreateTexture(nil, "BACKGROUND");
    border:SetAllPoints();
    border:SetColorTexture(core.colours.black.r, core.colours.black.g, core.colours.black.b);

    local icon = button:CreateTexture(nil, "ARTWORK");
    core:SetPixelPoint(icon, "TOPLEFT", button, "TOPLEFT", core.pixel, -core.pixel);
    core:SetPixelPoint(icon, "BOTTOMRIGHT", button, "BOTTOMRIGHT", -core.pixel, core.pixel);
    icon:SetTexture(entry.icon);
    icon:SetTexCoord(core:GetCroppedTexCoords(layout.iconWidth, layout.iconHeight));

    local glow = CreateFrame("Frame", nil, button);
    glow:SetFrameLevel(button:GetFrameLevel() + 5);
    core:SetPixelSize(glow, layout.iconWidth * 1.4, layout.iconHeight * 1.4);
    core:SetPixelPoint(glow, "CENTER", button, "CENTER", 0, 0);
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
    button:SetScript("OnShow", function() animation:Play(); end);
    button:SetScript("OnHide", function()
        animation:Stop();
        if GameTooltip:GetOwner() == button then GameTooltip:Hide(); end;
    end);

    button:EnableMouse(true);
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP");
        GameTooltip:SetText(entry.auraName);
        GameTooltip:Show();
    end);
    button:SetScript("OnLeave", function() GameTooltip:Hide(); end);

    local function update()
        -- aura slots error out when secret so just keep the last known state until they're readable again
        if C_Secrets and C_Secrets.ShouldAurasBeSecret() then return; end;
        local active = false;
        AuraUtil.ForEachAura("player", "HELPFUL", nil, function(aura)
            if not (issecretvalue and issecretvalue(aura.name)) and aura.name == entry.auraName then
                active = true;
                return true;
            end;
            return false;
        end, true);
        button:SetShown(not active);
    end;
    button:RegisterEvent("PLAYER_ENTERING_WORLD");
    button:RegisterEvent("PLAYER_REGEN_ENABLED");
    button:RegisterUnitEvent("UNIT_AURA", "player");
    button:SetScript("OnEvent", update);
    button:Hide();
    update();
end;

function core:CreateTrackers(parent, auraTracker)
    local layout = core.auraTrackerLayout;
    local client = core.isForever and "forever" or core.isClassicEra and "era" or "retail";
    local playerClass = select(2, UnitClass("player"));
    local entries = core.trackers[client][playerClass] or {};
    local maxSlot = 0;

    local function countSlots(list)
        for index, entry in ipairs(list) do
            maxSlot = math.max(maxSlot, entry.slot or index);
        end;
    end;

    if client == "retail" then
        for _, specEntries in pairs(entries) do
            countSlots(specEntries);
        end;
    else
        countSlots(entries);
    end;

    local step = math.max(layout.iconWidth + layout.minIconSpacing,
        (core.width - layout.iconWidth) / (layout.slotCount - 1));
    local reminders = core.trackers.reminders;
    local totalSlots = maxSlot + #reminders;
    local width = totalSlots > 0 and (totalSlots - 1) * step + layout.iconWidth or 0;
    local frame = core:CreateAuraTracker(parent, {
        name = "PlayerTrackersContainer",
        entries = entries,
        width = width,
    });
    for index, entry in ipairs(reminders) do
        createReminder(frame, entry, (maxSlot + index - 1) * step);
    end;
    frame.hasEntries = totalSlots > 0;
    core:SetPixelPoint(frame, "TOPLEFT", auraTracker, "TOPRIGHT", layout.minIconSpacing, 0);
    return frame;
end;
