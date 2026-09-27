local _, core = ...;

local frame;

local function checkAfk()
    frame.afk:SetAlphaFromBoolean(UnitIsAFK("player"));
end;

local function checkCombat()
    frame.combat:SetAlphaFromBoolean(PlayerIsInCombat());
end;

local function checkRested()
    frame.rested:SetAlphaFromBoolean(IsResting());
end;

local function checkPvP()
    frame.pvp:SetAlphaFromBoolean(UnitIsPVP("player"));
end;

function core:CreateWidgets(parent)
    frame = CreateFrame("Frame", nil, parent);
    core:SetPixelSize(frame, core.width, core.pixel);

    frame.afk = frame:CreateTexture();
    core:SetPixelPoint(frame.afk, "CENTER", frame, "CENTER", -180, -6);
    frame.afk:SetTexture("Interface/Addons/Bars/assets/afk.png");
    core:SetPixelSize(frame.afk, 16, 16);

    frame.combat = frame:CreateTexture();
    core:SetPixelPoint(frame.combat, "CENTER", frame, "CENTER", 180, 10);
    frame.combat:SetTexture("Interface/Addons/Bars/assets/combat.png");
    core:SetPixelSize(frame.combat, 16, 16);

    frame.rested = frame:CreateTexture();
    core:SetPixelPoint(frame.rested, "CENTER", frame, "CENTER", -180, 10);
    frame.rested:SetTexture("Interface/Addons/Bars/assets/rested.png");
    core:SetPixelSize(frame.rested, 16, 16);

    frame.pvp = frame:CreateTexture();
    core:SetPixelPoint(frame.pvp, "CENTER", frame, "CENTER", 180, -6);
    frame.pvp:SetTexture("Interface/Addons/Bars/assets/pvp.png");
    core:SetPixelSize(frame.pvp, 16, 16);

    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterEvent("PET_BATTLE_OPENING_START");
    frame:RegisterEvent("PET_BATTLE_CLOSE");
    frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player");
    frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player");
    frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED");
    frame:RegisterEvent("ZONE_CHANGED");
    frame:RegisterEvent("ZONE_CHANGED_INDOORS");
    frame:RegisterEvent("PLAYER_FLAGS_CHANGED");
    frame:RegisterEvent("PLAYER_IN_COMBAT_CHANGED");

    frame:HookScript("OnEvent", function(_, event)
        if event == "ZONE_CHANGED" then
            checkRested();
        elseif event == "ZONE_CHANGED_INDOORS" then
            checkRested();
        elseif event == "PLAYER_FLAGS_CHANGED" then
            checkRested();
            checkAfk();
            checkPvP();
        elseif event == "PLAYER_IN_COMBAT_CHANGED" then
            checkCombat();
        else
            checkRested();
            checkAfk();
            checkPvP();
            checkCombat();
        end;
    end);
    return frame;
end;
