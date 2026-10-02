local _, core = ...;

local iconWidth = 36;
local iconHeight = 30;
local minIconSpacing = 2;
local colours = core.colours;

function core:CreateTotemTracker(parent)
    if select(2, UnitClass("player")) ~= "SHAMAN" then return nil; end;

    local frame = CreateFrame("Frame", "PlayerTotemTrackerContainer", parent);
    core:SetPixelSize(frame, (iconWidth + 4), iconHeight + 4);
    -- slots = 1 fire, 2 earth, 3 water, 4 air
    for i = 1, 4 do
        local totem = CreateFrame("Frame", nil, parent);
        core:SetPixelSize(totem, iconWidth, iconHeight);
        totem:ClearAllPoints();
        core:SetPixelPoint(totem, "LEFT", frame, "LEFT", ((i - 1) % 2) * (iconWidth + minIconSpacing),
            -(i < 3 and 0 or 1) * (iconHeight + minIconSpacing));

        totem.spellID = nil;

        totem:EnableMouse(true);
        totem:SetFrameLevel(10);
        totem:SetScript("OnEnter", function(self)
            if not totem.spellID then return; end;
            GameTooltip:SetOwner(self, "ANCHOR_TOP");
            GameTooltip:SetSpellByID(totem.spellID);
            GameTooltip:Show();
        end);
        totem:SetScript("OnLeave", function()
            GameTooltip:Hide();
        end);
        totem.baseIcon = totem:CreateTexture(nil, "ARTWORK");
        totem.baseIcon:SetTexCoord(core:GetCroppedTexCoords(iconWidth, iconHeight));
        core:SetPixelPoint(totem.baseIcon, "TOPLEFT", totem, "TOPLEFT", core.pixel, -core.pixel);
        core:SetPixelPoint(totem.baseIcon, "BOTTOMRIGHT", totem, "BOTTOMRIGHT", -core.pixel, core.pixel);
        totem.baseIcon:SetDesaturated(true);
        totem.baseIcon:SetTexture(C_Spell.GetSpellTexture(core.totems[i]));

        totem.border = totem:CreateTexture(nil, "BACKGROUND");
        core:SetPixelPoint(totem.border, "TOPLEFT", totem, "TOPLEFT", 0, 0);
        core:SetPixelPoint(totem.border, "BOTTOMRIGHT", totem, "BOTTOMRIGHT", 0, 0);
        totem.border:SetColorTexture(colours.black.r, colours.black.g, colours.black.b);

        totem.cooldown = CreateFrame("Cooldown", nil, totem, "CooldownFrameTemplate");
        totem.cooldown:SetAllPoints();
        totem.cooldown:SetDrawEdge(false);
        totem.cooldown:Hide();

        frame["totem" .. i] = totem;
    end;

    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterEvent("PLAYER_TOTEM_UPDATE");
    frame:RegisterUnitEvent("UNIT_AURA", "player");

    frame:SetScript("OnEvent", function()
        for i = 1, 4 do
            local _, _, _, _, icon, _, spellID = GetTotemInfo(i);
            -- GetTotemDuration exists
            local duration = GetTotemDuration(i);
            local totem = frame["totem" .. i];
            totem.baseIcon:SetTexture(C_Spell.GetSpellTexture(core.totems[i]));
            totem.baseIcon:SetDesaturated(true);
            totem.cooldown:Hide();
            totem.spellID = nil;

            -- duration is nil when there is no totem
            -- this way we can avoid secret shenanigans
            if duration then
                totem.cooldown:Show();
                totem.cooldown:SetCooldownFromDurationObject(duration);
                totem.baseIcon:SetTexture(icon);
                totem.baseIcon:SetDesaturated(false);
                totem.spellID = spellID;
            end;
        end;
    end);

    return frame;
end;
