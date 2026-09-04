local _, core = ...

local frame = nil;
local interruptSpellID = nil
local savedIcon = nil
local savedName = nil
local kickedName = nil
local kickedClock = nil
local kickedWait = false
local currentNotInterruptible = false

local function updateBar(target, kicked)
    if not frame then return end;
    local name, text, texture, _, _, _, _, notInterruptible = UnitCastingInfo("target")
    local isChanneled = false

    if not name then
        name, text, texture, _, _, _, notInterruptible = UnitChannelInfo("target")
        isChanneled = true
        if not name then
            if not kickedWait then
                return frame:Hide();
            end
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
    if target then
        frame.target:SetText(UnitName(target));
    end

    savedIcon = texture;
    savedName = text;

    if isChanneled then
        frame.bar:SetTimerDuration(UnitChannelDuration("target"), Enum.StatusBarInterpolation.ExponentialEaseOut,
            Enum.StatusBarTimerDirection.RemainingTime)
    else
        frame.bar:SetTimerDuration(UnitCastingDuration("target"), Enum.StatusBarInterpolation.ExponentialEaseOut,
            Enum.StatusBarTimerDirection.ElapsedTime)
    end

    local colorKickNotReady = CreateColor(1.0, 0.8, 0.2)       -- red
    local colorKickReady    = CreateColor(0.1, 1, 0.1, 1.0)    -- Green
    local colorBlocked      = CreateColor(0.5, 0.5, 0.5, 1.0); -- gray

    -- notInterruptible isn't reliably populated on every call (seen consistently nil on Classic
    -- Era); UNIT_SPELLCAST_(NOT_)INTERRUPTIBLE below keeps currentNotInterruptible in sync instead
    if notInterruptible ~= nil then
        currentNotInterruptible = notInterruptible;
    end

    if interruptSpellID ~= nil then
        -- retail treats cooldown durations as secret numbers, so readiness is read via the duration
        -- object's own IsZero() instead of comparing the raw seconds value ourselves
        local ignoreGCD = true
        local cooldownDuration = C_Spell.GetSpellCooldownDuration(interruptSpellID, ignoreGCD)
        local spellReady = not cooldownDuration or cooldownDuration:IsZero()
        local baseColor = C_CurveUtil.EvaluateColorFromBoolean(spellReady, colorKickReady, colorKickNotReady)
        local blockedCheck = C_CurveUtil.EvaluateColorFromBoolean(currentNotInterruptible, colorBlocked, baseColor)
        local friendlyCheck = C_CurveUtil.EvaluateColorFromBoolean(UnitCanAttack("player", "target"), blockedCheck,
            colorKickNotReady)
        frame.bar:SetStatusBarColor(friendlyCheck:GetRGB())
    else
        local blockedCheck = C_CurveUtil.EvaluateColorFromBoolean(currentNotInterruptible, colorBlocked, colorKickReady)
        local friendlyCheck = C_CurveUtil.EvaluateColorFromBoolean(UnitCanAttack("player", "target"), blockedCheck,
            colorKickNotReady)
        frame.bar:SetStatusBarColor(friendlyCheck:GetRGB())
    end
end

local function CachePlayerInterrupt()
    interruptSpellID = core:GetPlayerInterruptSpellID()
end

function core:CreateTargetCastbar(parent)
    frame = core:CreateCastbarBase("TargetCastbar", parent)

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    frame:RegisterUnitEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_START", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_STOP", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "target")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "target")

    frame:HookScript("OnEvent", function(self, event, target, _, _, kickedBy)
        if event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_START" then
            -- cancel the kickedClock incase the enemy immediately starts casting again
            if kickedClock then kickedClock:Cancel() end
            kickedWait = false
            currentNotInterruptible = false
        end
        if event == "UNIT_SPELLCAST_INTERRUPTIBLE" or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
            currentNotInterruptible = event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE";
            updateBar()
        elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
            -- if kickedBy is not an ID we still wanna make it clear the cast was stopped
            updateBar(target, kickedBy or false)
        elseif event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_STOP" or event == "UNIT_SPELLCAST_CHANNEL_UPDATE" or event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_DELAYED" then
            updateBar(target, nil)
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
