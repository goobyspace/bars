local _, core = ...;

local frame;

local function checkAfk()
    frame.afk:SetShown(UnitIsAFK("player"));
end

local function checkCombat()
    frame.combat:SetShown(PlayerIsInCombat());
end

local function checkRested()
    -- 1 = rested 2 = normal
    local rested = GetRestState();
    if rested == 1 then
        frame.rested:Show();
    else
        frame.rested:Hide();
    end
end

local function checkPvP()
    local isFreeForAll = UnitIsPVPFreeForAll("player")
    local isPvP = UnitIsPVP("player")
    frame.pvp:SetShown(isFreeForAll or isPvP or false)
end

function core:CreateWidgets(parent)
    frame = CreateFrame("Frame", nil, parent);
    frame:SetSize(core.width, 1);

    frame.afk = frame:CreateTexture();
    frame.afk:SetPoint("CENTER", -180, -6);
    frame.afk:SetTexture("Interface/Addons/Bars/assets/afk.png");
    frame.afk:SetSize(16, 16);

    frame.combat = frame:CreateTexture();
    frame.combat:SetPoint("CENTER", 180, 10);
    frame.combat:SetTexture("Interface/Addons/Bars/assets/combat.png");
    frame.combat:SetSize(16, 16);

    frame.rested = frame:CreateTexture();
    frame.rested:SetPoint("CENTER", -180, 10);
    frame.rested:SetTexture("Interface/Addons/Bars/assets/rested.png");
    frame.rested:SetSize(16, 16);

    frame.pvp = frame:CreateTexture();
    frame.pvp:SetPoint("CENTER", 180, -6);
    frame.pvp:SetTexture("Interface/Addons/Bars/assets/pvp.png");
    frame.pvp:SetSize(16, 16);

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PET_BATTLE_OPENING_START")
    frame:RegisterEvent("PET_BATTLE_CLOSE")
    frame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
    frame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
    frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    frame:RegisterEvent("ZONE_CHANGED");
    frame:RegisterEvent("ZONE_CHANGED_INDOORS");
    frame:RegisterEvent("PLAYER_FLAGS_CHANGED");
    frame:RegisterEvent("PLAYER_IN_COMBAT_CHANGED");

    frame:SetScript("OnEvent", function(_, event)
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
        end
    end)
    return frame;
end
