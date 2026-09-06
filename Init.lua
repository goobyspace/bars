local _, core = ...

core.thickMode = true;

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
