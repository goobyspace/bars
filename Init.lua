--[[
This addon is a replacement for player/target frames, entirely using statusbars
Everything loads from BarFrames.lua, which calls and builds all the frames

Folders to note:
Utils: Folders and general helpers, important files are LayoutConfig.lua & ColourConfig.lua, most simple
edits (including new buffs) will start in this folder.
Components: What it says on the tin, HPbars, statusbars, secret handling, everything that we used in more
than 1 place has gone in here.
Target/player/assets speak for themselves

Changing one of the following?
New/changed spell ID, color, or Classic-vs-Retail issue -> utils/
New way a bar/aura/castbar should render (applies to both player and target) -> components/
Overall frame positioning/spacing -> BarFrames.lua

Most of the sizing and positioning uses a number of pixel perfect helpers, so that we can make sure our bars are the exact size we want them to be.
]]

local _, core = ...

function core:InitEventHandler(event, name)
    if event == "ADDON_LOADED" then
        if name ~= "Bars" then return end
        if BarsGlobalVariables == nil then BarsGlobalVariables = {} end
        return
    end

    core:InitializeBarFrames()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", core.InitEventHandler)
