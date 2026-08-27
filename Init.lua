local _, core = ...

function core:InitEventHandler(event, name)
    if name ~= "Bars" then return end
    if BarsGlobalVariables == nil then BarsGlobalVariables = {} end
    core:InitializeBarFrames()
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", core.InitEventHandler)
