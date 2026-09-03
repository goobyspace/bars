local _, core = ...

function core:InitEventHandler(event, name)
    if event == "ADDON_LOADED" then
        if name ~= "Bars" then return end
        if BarsGlobalVariables == nil then BarsGlobalVariables = {} end
        return
    end

    -- UIParent is still at scale 1 during ADDON_LOADED, so the pixel size the bars are built from
    -- would be wrong; wait for login when the UI scale has been applied
    core:InitializeBarFrames()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", core.InitEventHandler)
