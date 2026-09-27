local _, core = ...
local colours = core.colours

local frame = nil;
local interruptSpellID = nil
local savedIcon = nil
local savedName = nil
local kickedName = nil
local kickedClock = nil
local kickedWait = false
local currentNotInterruptible = false
local castSucceeded = false
local hasActiveCast = false

local function updateBar(kicked)
    if not frame then return end;
    local name, text, texture, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    local isChanneled = false

    if not name then
        name, text, texture, _, _, _, notInterruptible = UnitChannelInfo("target")
        isChanneled = true
        -- cancelling via esc/stopcasting clears cast info before interrupted event
        if not name and kicked == nil and not kickedWait then
            hasActiveCast = false
            return frame:Hide();
        end
    end

    if kicked ~= nil then
        if kickedClock then kickedClock:Cancel() end
        kickedWait = true;
        kickedName = kicked
        kickedClock = C_Timer.NewTimer(1, function()
            kickedWait = false
            return frame:Hide();
        end)
    end

    frame:Show();

    if kickedWait then
        core:ShowCastbarKicked(frame, savedName, savedIcon, kickedName)
        return
    end

    frame.name:SetText(text)
    frame.icon:SetTexture(texture)
    frame.target:SetText(UnitName("targettarget"))

    savedIcon = texture;
    savedName = text;

    if isChanneled then
        frame.bar:SetTimerDuration(UnitChannelDuration("target"), Enum.StatusBarInterpolation.ExponentialEaseOut,
            Enum.StatusBarTimerDirection.RemainingTime)
    else
        frame.bar:SetTimerDuration(UnitCastingDuration("target"), Enum.StatusBarInterpolation.ExponentialEaseOut,
            Enum.StatusBarTimerDirection.ElapsedTime)
    end

    local baseColour = isChanneled and colours.castChannel or colours.castNormal
    local colorKickNotReady = CreateColor(baseColour.r, baseColour.g, baseColour.b)
    local colorKickReady = CreateColor(colours.castKickReady.r, colours.castKickReady.g, colours.castKickReady.b)
    local colorKickUnavailable = CreateColor(colours.castKickUnavailable.r, colours.castKickUnavailable.g,
        colours.castKickUnavailable.b)
    local colorBlocked = CreateColor(colours.castBlocked.r, colours.castBlocked.g, colours.castBlocked.b)

    -- notInterruptible is nil on era
    if notInterruptible ~= nil then
        currentNotInterruptible = notInterruptible;
    end

    if interruptSpellID ~= nil then
        local ignoreGCD = true
        -- this accepts 2 values the language server is wrong
        local cooldownDuration = C_Spell.GetSpellCooldownDuration(interruptSpellID, ignoreGCD)
        local spellReady = not cooldownDuration or cooldownDuration:IsZero()
        local baseColor = C_CurveUtil.EvaluateColorFromBoolean(spellReady, colorKickReady, colorKickNotReady)
        local blockedCheck = C_CurveUtil.EvaluateColorFromBoolean(currentNotInterruptible, colorBlocked, baseColor)
        local friendlyCheck = C_CurveUtil.EvaluateColorFromBoolean(UnitCanAttack("player", "target"), blockedCheck,
            colorKickNotReady)
        core:SetCastbarColor(frame, friendlyCheck:GetRGB())
    else
        local blockedCheck = C_CurveUtil.EvaluateColorFromBoolean(currentNotInterruptible, colorBlocked,
            colorKickUnavailable)
        local friendlyCheck = C_CurveUtil.EvaluateColorFromBoolean(UnitCanAttack("player", "target"), blockedCheck,
            colorKickNotReady)
        core:SetCastbarColor(frame, friendlyCheck:GetRGB())
    end
end

local function CachePlayerInterrupt()
    interruptSpellID = core:GetPlayerInterruptSpellID()
    if interruptSpellID then
        print("Bars: detected interrupt:", C_Spell.GetSpellName(interruptSpellID) or "unknown", "spell ID:",
            interruptSpellID)
    else
        print("Bars: no interrupt detected")
    end
end

function core:CreateTargetCastbar(parent)
    frame = core:CreateCastbarBase("TargetCastbar", parent)

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterUnitEvent("UNIT_TARGET", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "target")

    frame:HookScript("OnEvent", function(_, event, _, _, _, kickedBy)
        if event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_START" or event == "PLAYER_TARGET_CHANGED" then
            if kickedClock then kickedClock:Cancel() end
            kickedWait = false
            castSucceeded = false
            currentNotInterruptible = false
            hasActiveCast = event ~= "PLAYER_TARGET_CHANGED" or
                (UnitCastingInfo("target") or UnitChannelInfo("target")) ~= nil
        end
        if event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
            currentNotInterruptible = event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE";
            updateBar()
        elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
            if hasActiveCast then
                hasActiveCast = false
                updateBar(kickedBy or false)
            end
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            castSucceeded = true
        elseif event == "UNIT_SPELLCAST_STOP" then
            local wasActive = hasActiveCast
            hasActiveCast = false
            if wasActive and not castSucceeded then
                updateBar(false)
            else
                updateBar()
            end
        else
            updateBar()
        end
    end)

    local kickUpdateFrame = CreateFrame("Frame")
    kickUpdateFrame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
    kickUpdateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    -- warlock's interrupt is on the pet's spellbook, so it needs to be rechecked when the pet changes
    kickUpdateFrame:RegisterEvent("UNIT_PET")

    kickUpdateFrame:HookScript("OnEvent", function()
        CachePlayerInterrupt()
    end)

    return frame;
end
