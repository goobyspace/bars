local _, core = ...;
local colours = core.colours;

local gcdSpellID = 61304;
-- gcd never exceeds 1.5s, anything longer on the reference spell is its own cooldown
local gcdMaxDuration = 1.6;

-- temporary debugging, flip off once the ticker is confirmed working
local debugGCD = false;
local isSecret = issecretvalue or function() return false; end;
local function dprint(...)
    if debugGCD then
        print("|cff00ff96[GCD]|r", ...);
    end;
end;

-- classic clients dont have the gcd dummy spell, so remember the last cast spell
-- whose cooldown came back gcd-length and read the gcd off of it instead
local referenceSpellID = nil;
local candidateSpellID = nil;

local function resolveCandidate()
    if not candidateSpellID then return; end;
    local info = C_Spell.GetSpellCooldown(candidateSpellID);
    if not info then
        candidateSpellID = nil;
        return;
    end;
    -- forever flags gcd cooldowns directly, no numbers needed
    if info.isOnGCD then
        referenceSpellID = candidateSpellID;
        dprint("reference spell set to", candidateSpellID);
        candidateSpellID = nil;
        return;
    end;
    -- era has no isOnGCD so check the numbers instead
    if core:IsSafeNumber(info.duration) and info.duration > 0 then
        if info.duration <= gcdMaxDuration then
            referenceSpellID = candidateSpellID;
            dprint("reference spell set to", candidateSpellID);
        end;
        candidateSpellID = nil;
    end;
end;

local function readGCD()
    local info = C_Spell.GetSpellCooldown(gcdSpellID);
    if info then return info, gcdSpellID, false; end;
    if referenceSpellID then
        local refInfo = C_Spell.GetSpellCooldown(referenceSpellID);
        if refInfo then return refInfo, referenceSpellID, true; end;
    end;
end;

function core:CreateGCDTicker(bar)
    -- invisible timer bar so the line can ride its texture edge, keeps secret durations working
    local ticker = CreateFrame("StatusBar", nil, bar);
    ticker:SetAllPoints(bar);
    ticker:SetFrameLevel(bar:GetFrameLevel() + 5);
    ticker:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");
    ticker:SetStatusBarColor(0, 0, 0, 0);
    ticker:SetMinMaxValues(0, 1);
    ticker:SetValue(0);
    ticker:Hide();

    local line = ticker:CreateTexture(nil, "OVERLAY", nil, 2);
    line:SetColorTexture(colours.white.r, colours.white.g, colours.white.b, colours.white.a);
    core:SetPixelSize(line, core.pixel, core.barHeight);
    line:SetPoint("RIGHT", ticker:GetStatusBarTexture(), "RIGHT", 0, 0);

    local inCombat = InCombatLockdown();
    local endTime, duration;
    local objectSpellID;

    local function refresh()
        endTime, duration, objectSpellID = nil, nil, nil;
        resolveCandidate();
        if not inCombat then
            ticker:Hide();
            return;
        end;

        local info, sourceSpellID, fromReference = readGCD();
        if not info then
            dprint("refresh: no cooldown info (reference=" .. tostring(referenceSpellID) .. "), hiding");
            ticker:Hide();
            return;
        end;
        if info.isActive == false then
            dprint("refresh: gcd not active, hiding");
            ticker:Hide();
            return;
        end;
        if fromReference and info.isOnGCD == false then
            dprint("refresh: reference on its own cooldown, hiding");
            ticker:Hide();
            return;
        end;

        if core:IsSafeNumber(info.startTime) and core:IsSafeNumber(info.duration) then
            if info.duration <= 0 then
                dprint("refresh: no gcd running, hiding");
                ticker:Hide();
                return;
            end;
            if fromReference and info.duration > gcdMaxDuration then
                dprint(format("refresh: reference on its own cooldown (%.2f), hiding", info.duration));
                ticker:Hide();
                return;
            end;
            endTime = info.startTime + info.duration;
            duration = info.duration;
            dprint(format("refresh: numeric path, start=%.2f duration=%.2f now=%.2f", info.startTime, info.duration,
                GetTime()));
            -- set the value now so the line doesnt flash at the stale position from the last gcd
            ticker:SetValue(math.min(1, math.max(0, (endTime - GetTime()) / duration)));
            ticker:Show();
            return;
        end;

        -- secret numbers, let the client animate it from the duration object instead
        -- (no IsZero here, it returns a secret boolean on forever)
        local durationObject = C_Spell.GetSpellCooldownDuration(sourceSpellID);
        if durationObject then
            dprint("refresh: duration object path via", sourceSpellID, ", showing");
            objectSpellID = sourceSpellID;
            -- no easing, it would sweep the line over from the previous (near empty) value
            ticker:SetTimerDuration(durationObject, Enum.StatusBarInterpolation.Immediate,
                Enum.StatusBarTimerDirection.RemainingTime);
            ticker:Show();
        else
            dprint("refresh: duration object nil via " .. tostring(sourceSpellID) .. ", hiding");
            ticker:Hide();
        end;
    end;

    -- only runs while shown, ticks the line down and hides it once the gcd finishes
    ticker:SetScript("OnUpdate", function()
        if endTime then
            local remaining = endTime - GetTime();
            if remaining <= 0 then
                endTime, duration = nil, nil;
                ticker:Hide();
            else
                ticker:SetValue(remaining / duration);
            end;
            return;
        end;

        -- isActive is a plain boolean even when the times are secret
        if objectSpellID then
            local info = C_Spell.GetSpellCooldown(objectSpellID);
            if not info or info.isActive == false then
                ticker:Hide();
            end;
        end;
    end);

    ticker.events = CreateFrame("Frame");
    ticker.events:RegisterEvent("PLAYER_ENTERING_WORLD");
    ticker.events:RegisterEvent("PLAYER_REGEN_DISABLED");
    ticker.events:RegisterEvent("PLAYER_REGEN_ENABLED");
    ticker.events:RegisterEvent("SPELL_UPDATE_COOLDOWN");
    ticker.events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player");
    ticker.events:SetScript("OnEvent", function(_, event, _, _, spellID)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            if spellID and not isSecret(spellID) then
                candidateSpellID = spellID;
            end;
        elseif event == "PLAYER_REGEN_DISABLED" then
            inCombat = true;
            dprint("entered combat");
        elseif event == "PLAYER_REGEN_ENABLED" then
            inCombat = false;
            dprint("left combat");
        elseif event == "PLAYER_ENTERING_WORLD" then
            inCombat = InCombatLockdown();
        elseif inCombat then
            dprint(event);
        end;
        refresh();
    end);

    return ticker;
end;
