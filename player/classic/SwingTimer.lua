local _, core = ...

if not core.isClassicEra then return end

local frame;
local combatLogGetCurrentEventInfo = rawget(_G, "CombatLogGetCurrentEventInfo");

local AUTO_SHOT_SPELL_ID = 75;
local SHOOT_BOW_SPELL_ID = 2480;
local SHOOT_GUN_SPELL_ID = 7918;
local SHOOT_CROSSBOW_SPELL_ID = 7919;
local SHOOT_WAND_SPELL_ID = 5019;
local RANGED_SPELL_IDS = {
    [AUTO_SHOT_SPELL_ID] = true,
    [SHOOT_BOW_SPELL_ID] = true,
    [SHOOT_GUN_SPELL_ID] = true,
    [SHOOT_CROSSBOW_SPELL_ID] = true,
    [SHOOT_WAND_SPELL_ID] = true,
};

local DEFAULT_RANGED_SPEED = 2.0;
local MAX_MEASURED_RANGED_INTERVAL = 10;

local playerGUID;
local inCombat = false;

local mainHandSpeed, offHandSpeed;
local mainHandStart, mainHandExpiry;
local offHandStart, offHandExpiry;

local rangedSpeed = DEFAULT_RANGED_SPEED;
local rangedStart, rangedExpiry;
local lastRangedShotTime;

local mainHandBar, mainHandBg;
local offHandBar, offHandBg;
local rangedBar, rangedBg;

local function createSwingBar(colorKey)
    local bg = frame:CreateTexture();
    bg:SetTexture(134532)
    bg:SetColorTexture(0, 0, 0);
    bg:SetHeight(core.barBgHeight);
    bg:SetDrawLayer("OVERLAY", -1);
    bg:Hide();

    local bar = CreateFrame("StatusBar", nil, frame);
    bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    core:InsetBarInBackground(bar, bg);
    bar:SetMinMaxValues(0, 1);
    bar:SetValue(0);
    bar:Hide();

    local color = core.resources.resourceColours[colorKey];
    bar:SetStatusBarColor(color.r / 255, color.g / 255, color.b / 255);

    return bar, bg;
end

local function showTimerBar(bar, startTime, expiry)
    local duration = C_DurationUtil.CreateDuration();
    duration:SetTimeSpan(startTime, expiry);
    bar:SetTimerDuration(duration, Enum.StatusBarInterpolation.ExponentialEaseOut,
        Enum.StatusBarTimerDirection.ElapsedTime);
    bar:Show();
end

local function updateBars()
    local haveMainHand = inCombat and mainHandExpiry ~= nil;
    local haveOffHand = inCombat and offHandSpeed ~= nil and offHandExpiry ~= nil;

    if haveMainHand then
        showTimerBar(mainHandBar, mainHandStart, mainHandExpiry);
        mainHandBg:Show();
    else
        mainHandBar:Hide(); mainHandBg:Hide();
    end

    if haveOffHand then
        showTimerBar(offHandBar, offHandStart, offHandExpiry);
        offHandBg:Show();
    else
        offHandBar:Hide(); offHandBg:Hide();
    end

    if rangedExpiry ~= nil then
        showTimerBar(rangedBar, rangedStart, rangedExpiry);
        rangedBg:Show();

        if haveMainHand or haveOffHand then
            rangedBg:SetPoint("BOTTOM", frame, "BOTTOM", 0, core.rowStep);
        else
            rangedBg:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0);
        end
    else
        rangedBar:Hide(); rangedBg:Hide();
    end
end

local function onMeleeSwingLanded()
    local now = GetTime();
    mainHandSpeed, offHandSpeed = UnitAttackSpeed("player");
    if not mainHandSpeed then return end

    if offHandSpeed then
        local mainRemaining = mainHandExpiry and (mainHandExpiry - now) or -math.huge;
        local offRemaining = offHandExpiry and (offHandExpiry - now) or -math.huge;
        if offRemaining < mainRemaining then
            offHandStart, offHandExpiry = now, now + offHandSpeed;
        else
            mainHandStart, mainHandExpiry = now, now + mainHandSpeed;
        end
    else
        offHandStart, offHandExpiry = nil, nil;
        mainHandStart, mainHandExpiry = now, now + mainHandSpeed;
    end

    updateBars();
end

local function onRangedShotLanded()
    local now = GetTime();
    if lastRangedShotTime then
        local measured = now - lastRangedShotTime;
        if measured > 0.2 and measured < MAX_MEASURED_RANGED_INTERVAL then
            rangedSpeed = measured;
        end
    end
    lastRangedShotTime = now;
    rangedStart, rangedExpiry = now, now + rangedSpeed;

    updateBars();
end

local function onRangedAimStarted()
    if rangedExpiry then return end
    local now = GetTime();
    rangedStart, rangedExpiry = now, now + rangedSpeed;
    updateBars();
end

local function onRangedStopped()
    lastRangedShotTime = nil;
    rangedStart, rangedExpiry = nil, nil;
    updateBars();
end

local function resetMelee()
    mainHandStart, mainHandExpiry = nil, nil;
    offHandStart, offHandExpiry = nil, nil;
end

function core:CreateSwingTimer(parent)
    frame = CreateFrame("Frame", "SwingTimerContainer", parent);
    core:SetPixelSize(frame, core:EvenPixels(core.width * 2 / 3), core.barBgHeight);

    local GAP = 2;

    mainHandBar, mainHandBg = createSwingBar("SWING_MELEE");
    mainHandBg:SetPoint("LEFT", frame, "LEFT");
    mainHandBg:SetPoint("RIGHT", frame, "CENTER", -GAP / 2, 0);
    mainHandBg:SetPoint("BOTTOM", frame, "BOTTOM");

    offHandBar, offHandBg = createSwingBar("SWING_MELEE");
    offHandBg:SetPoint("LEFT", frame, "CENTER", GAP / 2, 0);
    offHandBg:SetPoint("RIGHT", frame, "RIGHT", -GAP, 0);
    offHandBg:SetPoint("BOTTOM", frame, "BOTTOM");

    rangedBar, rangedBg = createSwingBar("SWING_RANGED");
    rangedBg:SetPoint("LEFT", frame, "LEFT");
    rangedBg:SetPoint("RIGHT", frame, "CENTER", -GAP / 2, 0);
    rangedBg:SetPoint("BOTTOM", frame, "BOTTOM");

    playerGUID = UnitGUID("player");
    inCombat = InCombatLockdown();

    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterEvent("PLAYER_REGEN_DISABLED");
    frame:RegisterEvent("PLAYER_REGEN_ENABLED");
    frame:RegisterEvent("START_AUTOREPEAT_SPELL");
    frame:RegisterEvent("STOP_AUTOREPEAT_SPELL");
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");

    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            playerGUID = UnitGUID("player");
            inCombat = InCombatLockdown();
            resetMelee();
            onRangedStopped();
        elseif event == "PLAYER_REGEN_DISABLED" then
            inCombat = true;
            updateBars();
        elseif event == "PLAYER_REGEN_ENABLED" then
            inCombat = false;
            resetMelee();
            updateBars();
        elseif event == "START_AUTOREPEAT_SPELL" then
            onRangedAimStarted();
        elseif event == "STOP_AUTOREPEAT_SPELL" then
            onRangedStopped();
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            if not combatLogGetCurrentEventInfo then return end

            local _, subevent, _, sourceGUID, _, _, _, _, _, _, _, spellID = combatLogGetCurrentEventInfo();
            if sourceGUID ~= playerGUID then return end

            if subevent == "SWING_DAMAGE" or subevent == "SWING_MISSED" then
                onMeleeSwingLanded();
            elseif RANGED_SPELL_IDS[spellID]
                and (subevent == "SPELL_CAST_SUCCESS" or subevent == "SPELL_DAMAGE" or subevent == "SPELL_MISSED") then
                onRangedShotLanded();
            end
        end
    end)

    return frame;
end
