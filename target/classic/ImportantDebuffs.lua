local _, core = ...

if core.hasAuraContainer then return end

function core:CreateImportantDebuffsFrame(parent)
    return CreateFrame("Frame", "TargetImportantDebuffAuraContainer", parent)
end
