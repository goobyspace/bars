local _, core = ...

-- important-debuff tracking (CC/big defensive/external defensive) needs the sanctioned
-- AuraContainer widget to read secret aura values; Classic Era has no such widget, so this
-- category is simply unavailable there and the frame stays empty.
if core.hasAuraContainer then return end

function core:CreateImportantDebuffsFrame(parent)
    return CreateFrame("Frame", "TargetImportantDebuffAuraContainer", parent)
end
