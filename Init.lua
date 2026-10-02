--[[
This addon is a replacement for player/target frames, entirely using statusbars
Everything loads from BarFrames.lua, which calls and builds all the frames

Important folders:
Utils: General helpers and compatibility code.
Data: IDs and lookup tables.
Config: Colors, layout, and client-specific configuration; most simple edits (including new buffs) will start here.
Components: What it says on the tin, HPbars, statusbars, secret handling, everything that we used in more
than 1 place has gone in here.
Target/player/assets speak for themselves

Changing one of the following?
New/changed spell ID -> data/ or config/
Color or Classic-vs-Retail issue -> config/
New way a bar/aura/castbar should render (applies to both player and target) -> components/
Overall frame positioning/spacing -> BarFrames.lua

Most of the sizing and positioning uses a number of pixel perfect helpers, so that we can make sure our bars are the exact size we want them to be.
]]

local _, core = ...;

function core:InitEventHandler(event, name)
    if event == "ADDON_LOADED" then
        if name ~= "Bars" then return; end;
        if BarsGlobalVariables == nil then BarsGlobalVariables = {}; end;
        return;
    end;

    core.Debug = false;

    core.TRP = C_AddOns.IsAddOnLoaded("TotalRP3");

    core:InitializeBarFrames();
end;

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:RegisterEvent("PLAYER_LOGIN");
events:SetScript("OnEvent", core.InitEventHandler);
