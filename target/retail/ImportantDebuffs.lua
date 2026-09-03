local _, core = ...

if not core.hasAuraContainer then return end

function core:CreateImportantDebuffsFrame(parent)
    local frame = CreateFrame("AuraContainer", "TargetImportantDebuffAuraContainer", parent,
        "CustomAuraContainerTemplate")
    frame:SetSize(66, 66)
    frame:SetPoint("CENTER", 0, 0)
    frame:SetUnit("target")
    -- this is pixel count not icon count for some dumb reason so this = overflow once you reach 68 pixels
    frame:SetFlowLayoutMaximumLineSize(68)
    frame:SetFlowLayoutAnchorPoint("TOPRIGHT")
    frame:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Left, AnchorUtil.FlowDirection.Down)

    local function initializeFrame(button)
        local icon = button:CreateTexture(nil, "OVERLAY")
        icon:SetAllPoints()
        button:SetIcon(icon)
        button:SetSize(32, 32)

        local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        cooldown:SetAllPoints()
        cooldown:SetHideCountdownNumbers(true)
        button:SetDurationCooldown(cooldown)
    end

    frame:AddAuraGroup("CrowdControl", AuraUtil.AuraFilters.Harmful .. "|" .. AuraUtil.AuraFilters.CrowdControl, {
        initializeFrame = initializeFrame,
        maxFrameCount = 1,
        layout = { layoutIndex = 1 },
    })

    frame:AddAuraGroup("DefensiveCooldowns", AuraUtil.AuraFilters.Helpful .. "|" .. AuraUtil.AuraFilters.BigDefensive, {
        initializeFrame = initializeFrame,
        maxFrameCount = 2,
        layout = { layoutIndex = 2 },
    })

    frame:AddAuraGroup("ExternalDefensiveCooldowns",
        AuraUtil.AuraFilters.Helpful .. "|" .. AuraUtil.AuraFilters.ExternalDefensive, {
            initializeFrame = initializeFrame,
            maxFrameCount = 2,
            layout = { layoutIndex = 3 },
        })

    frame:AddAuraGroup("OffensiveCooldowns",
        AuraUtil.AuraFilters.Helpful .. "|" .. AuraUtil.AuraFilters.Important
        .. "|!" .. AuraUtil.AuraFilters.BigDefensive
        .. "|!" .. AuraUtil.AuraFilters.ExternalDefensive, {
            initializeFrame = initializeFrame,
            maxFrameCount = 2,
            layout = { layoutIndex = 4 },
        })

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterUnitEvent("UNIT_AURA", "target")
    eventFrame:SetScript("OnEvent", function()
        frame:UpdateAllAuras()
    end)

    return frame
end
