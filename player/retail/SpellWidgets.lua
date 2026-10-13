local _, core = ...;
local colours = core.colours;

local DEFENSIVE_STANCE_SPELL_ID = 386208;

local function createHighlightGlow(parent)
    local glow = CreateFrame("Frame", nil, parent);
    glow:SetAllPoints(parent);
    glow:SetFrameLevel(parent:GetFrameLevel() + 1);

    local border = CreateFrame("Frame", nil, glow, "BackdropTemplate");
    border:SetFrameLevel(glow:GetFrameLevel());
    local padding = 4 * core.pixel;
    core:SetPixelPoint(border, "TOPLEFT", glow, "TOPLEFT", -padding, padding);
    core:SetPixelPoint(border, "BOTTOMRIGHT", glow, "BOTTOMRIGHT", padding, -padding);
    border:SetBackdrop({
        edgeFile = "Interface\\TutorialFrame\\UI-TutorialFrame-CalloutGlow",
        edgeSize = 8 * core.pixel,
        tileEdge = false,
    });

    border:SetBackdropBorderColor(0.7, 0.15, 0.1, 1);

    local animation = border:CreateAnimationGroup();
    animation:SetLooping("BOUNCE");
    local pulse = animation:CreateAnimation("Alpha");
    pulse:SetFromAlpha(0.6);
    pulse:SetToAlpha(1);
    pulse:SetDuration(0.8);
    pulse:SetSmoothing("IN_OUT");
    animation:Play();

    glow:SetAlpha(0);
    return glow;
end;

function core:CreateSpellWidgets(hpBar, primaryBar)
    local playerClass = select(2, UnitClass("player"));
    local classHighlights = core.primaryResourceHighlights and core.primaryResourceHighlights[playerClass];
    local isWarrior = playerClass == "WARRIOR";
    if not classHighlights and not isWarrior then return; end;

    local eventFrame = CreateFrame("Frame");
    local highlightSpell = nil;
    local glow, shield;

    if classHighlights then
        -- the glow sits above the bg so the bar has to be pushed above the glow
        primaryBar.bar.bg = primaryBar.bar:CreateTexture(nil, "BACKGROUND");
        primaryBar.bar.bg:SetAllPoints();
        primaryBar.bar.bg:SetColorTexture(colours.black.r, colours.black.g, colours.black.b);

        glow = createHighlightGlow(primaryBar);
        primaryBar.bar:SetFrameLevel(primaryBar:GetFrameLevel() + 2);
        eventFrame:RegisterEvent("SPELL_UPDATE_USABLE");
        eventFrame:RegisterEvent("SPELLS_CHANGED");
    end;

    if isWarrior then
        -- BACKGROUND layer so it draws under the bar bg, half peeking out the left side
        shield = hpBar:CreateTexture(nil, "BACKGROUND");
        shield:SetTexture("Interface/Addons/Bars/assets/shield.png");
        core:SetPixelSize(shield, 14, 15);
        core:SetPixelPoint(shield, "CENTER", hpBar, "LEFT", 0, 0);
        shield:Hide();
        eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM");
        eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS");
    end;

    local function updateHighlightSpell()
        highlightSpell = nil;
        if not classHighlights then return; end;

        local spec = C_SpecializationInfo.GetSpecialization();
        local specID = spec and C_SpecializationInfo.GetSpecializationInfo(spec);
        local spellID = specID and classHighlights[specID];
        highlightSpell = spellID and C_SpellBook.IsSpellKnown(spellID) and spellID or nil;
    end;

    local function updateGlow()
        if not glow then return; end;

        if not highlightSpell or not primaryBar:IsShown() then
            return glow:SetAlpha(0);
        end;

        -- usability can be a secret value in combat, so never branch on it
        -- IsSpellUsable returns a second value which would land in the alpha args, so only pass the first :/
        local usable = C_Spell.IsSpellUsable(highlightSpell);
        glow:SetAlphaFromBoolean(usable, 1, 0);
    end;

    local function updateShield()
        if not shield then return; end;

        -- the aura is hidden from addons in combat so the stance bar is checked instead
        local active = false;
        for i = 1, GetNumShapeshiftForms() do
            local _, isActive, _, spellID = GetShapeshiftFormInfo(i);
            if spellID == DEFENSIVE_STANCE_SPELL_ID then
                active = isActive;
                break;
            end;
        end;
        shield:SetShown(active);
    end;

    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
    eventFrame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player");
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" or event == "SPELLS_CHANGED" or event == "PLAYER_SPECIALIZATION_CHANGED" then
            updateHighlightSpell();
        end;
        updateGlow();
        updateShield();
    end);

    -- the primary bar can hide on its own so the glow has to follow
    primaryBar:HookScript("OnShow", updateGlow);
    primaryBar:HookScript("OnHide", updateGlow);
end;
