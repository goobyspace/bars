local _, core = ...

local frame = nil;
local interruptSpellID = nil

local function updateBar()
    if not frame then return end;
    local name, text, texture, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    local isChanneled = false

    if not name then
        name, text, texture, _, _, _, notInterruptible = UnitChannelInfo("target")
        isChanneled = true
        if not name then
            return frame:Hide();
        end
    end

    frame:Show();

    frame.name:SetText(text)
    frame.icon:SetTexture(texture)

    if isChanneled then
        frame.bar:SetTimerDuration(UnitChannelDuration("target"), Enum.StatusBarInterpolation.ExponentialEaseOut,
            Enum.StatusBarTimerDirection.RemainingTime)
    else
        frame.bar:SetTimerDuration(UnitCastingDuration("target"), Enum.StatusBarInterpolation.ExponentialEaseOut,
            Enum.StatusBarTimerDirection.ElapsedTime)
    end

    local colorKickNotReady = CreateColor(1.0, 0.1, 0.2)       -- red
    local colorKickReady    = CreateColor(0.1, 1, 0.1, 1.0)    -- Green
    local colorBlocked      = CreateColor(0.5, 0.5, 0.5, 1.0); -- gray

    frame.bar:SetStatusBarDesaturated(not UnitCanAttack("Player", "Target"));

    if notInterruptible ~= nil then
        if interruptSpellID ~= nil then
            -- these values are real the vs code plugin is just out of date
            local spellCD = C_Spell.GetSpellCooldownDuration(interruptSpellID, true);
            local baseColor = C_CurveUtil.EvaluateColorFromBoolean(spellCD:IsActive(), colorKickNotReady, colorKickReady)
            local blockedColor = C_CurveUtil.EvaluateColorFromBoolean(notInterruptible, colorBlocked, baseColor)
            local targetable = C_CurveUtil.EvaluateColorFromBoolean(UnitCanAttack("player", "target"), blockedColor,
                colorBlocked)
            frame.bar:SetStatusBarColor(targetable:GetRGB())
        else
            local blockedColor = C_CurveUtil.EvaluateColorFromBoolean(notInterruptible, colorBlocked, colorKickReady)
            local targetable = C_CurveUtil.EvaluateColorFromBoolean(UnitCanAttack("player", "target"), blockedColor,
                colorBlocked)
            frame.bar:SetStatusBarColor(targetable:GetRGB())
        end
    end
end

local function CachePlayerInterrupt()
    interruptSpellID = nil -- Reset default

    local specIndex = GetSpecialization()
    if not specIndex then return end

    local specID = GetSpecializationInfo(specIndex)
    if not specID then return end

    local specInterrupts = {
        -- DEATH KNIGHT
        [250]  = 47528, -- Blood (Mind Freeze)
        [251]  = 47528, -- Frost (Mind Freeze)
        [252]  = 47528, -- Unholy (Mind Freeze)

        -- DEMON HUNTER
        [577]  = 183752, -- Havoc (Consume Magic)
        [581]  = 183752, -- Vengeance (Consume Magic)

        -- DRUID
        [102]  = 78675,  -- Balance (Solar Beam)
        [103]  = 106839, -- Feral (Skull Bash)
        [104]  = 106839, -- Guardian (Skull Bash)
        [105]  = nil,    -- Restoration :(

        -- EVOKER
        [1467] = 351338, -- Devastation (Quell)
        [1468] = 351338, -- Preservation (Healer - No Kick)
        [1469] = 351338, -- Augmentation (Quell)

        -- HUNTER
        [253]  = 147362, -- Beast Mastery (Counter Shot)
        [254]  = 147362, -- Marksmanship (Counter Shot)
        [255]  = 187707, -- Survival (Muzzle)

        -- MAGE
        [62]   = 2139, -- Arcane (Counterspell)
        [63]   = 2139, -- Fire (Counterspell)
        [64]   = 2139, -- Frost (Counterspell)

        -- MONK
        [268]  = 116705, -- Brewmaster (Spear Hand Strike)
        [270]  = nil,    -- Mistweaver :(
        [269]  = 116705, -- Windwalker (Spear Hand Strike)

        -- PALADIN
        [65]   = nil,   -- Holy :(
        [66]   = 96231, -- Protection (Rebuke)
        [70]   = 96231, -- Retribution (Rebuke)

        -- PRIEST
        -- added death for priest since this info is basically the same as knowing if you can kick or not in pvp
        -- its not too important on a lightning bolt or smth but nice on a poly cast
        [256]  = 32379, -- Discipline (Death)
        [257]  = 32379, -- Holy (Death)
        [258]  = 15487, -- Shadow (Silence)

        -- ROGUE
        [259]  = 1766, -- Assassination (Kick)
        [260]  = 1766, -- Outlaw (Kick)
        [261]  = 1766, -- Subtlety (Kick)

        -- SHAMAN
        [262]  = 57994, -- Elemental (Wind Shear)
        [263]  = 57994, -- Enhancement (Wind Shear)
        [264]  = 57994, -- Restoration (Healer EXCEPTION - Has Wind Shear!)

        -- WARLOCK
        [265]  = 19647, -- Affliction (Spell Lock)
        [266]  = 19647, -- Demonology (Spell Lock)
        [267]  = 19647, -- Destruction (Spell Lock)

        -- WARRIOR
        [71]   = 6552, -- Arms (Pummel)
        [72]   = 6552, -- Fury (Pummel)
        [73]   = 6552, -- Protection (Pummel)
    }

    interruptSpellID = specInterrupts[specID]
end

function core:CreateTargetCastbar(parent)
    frame = CreateFrame("Frame", "TargetCastbar", parent)
    frame:SetSize(core.width, 16)

    frame.bg = frame:CreateTexture()
    frame.bg:SetPoint("RIGHT")
    frame.bg:SetTexture(134532)
    frame.bg:SetColorTexture(0, 0, 0)
    frame.bg:SetSize(core.width - 16, 16)
    frame.bg:SetDrawLayer("OVERLAY", -1)

    frame.bar = CreateFrame("StatusBar", nil, frame)
    frame.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
    frame.bar:SetPoint("RIGHT", -2, 0)
    frame.bar:SetSize(core.width - 16 - 2, 14)
    frame.bar:SetMinMaxValues(0, 1, Enum.StatusBarInterpolation.ExponentialEaseOut)

    frame.icon = frame:CreateTexture()
    frame.icon:SetPoint("LEFT", 0, 0)
    frame.icon:SetSize(16, 16)

    frame.name = frame.bar:CreateFontString("PrimaryText")
    frame.name:SetDrawLayer("OVERLAY", 1)
    frame.name:SetPoint("LEFT", 0, 0)
    frame.name:SetSize(core.width / 4, 16)
    frame.name:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")

    -- Events
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    frame:RegisterUnitEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", "target")

    frame:HookScript("OnEvent", function(self, event, ...)
        updateBar()
    end)

    local kickUpdateFrame = CreateFrame("Frame")
    kickUpdateFrame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    kickUpdateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    kickUpdateFrame:HookScript("OnEvent", function()
        CachePlayerInterrupt()
    end)

    return frame;
end
