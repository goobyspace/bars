local _, core = ...

local frame = nil;

function core:CreateImportantDebuffsFrame(parent)
    frame = CreateFrame("AuraContainer", "TargetImportantDebuffAuraContainer", parent, "CustomAuraContainerTemplate")
    frame:SetSize(66, 66)
    frame:SetPoint("CENTER", 0, 0)
    frame:SetUnit("target")
    -- maximumLineSize is a pixel extent, not an icon count - 2 icons wide at 32px each.
    frame:SetFlowLayoutMaximumLineSize(64)
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

    -- Exclude defensive categories because an aura can be both important and defensive.
    frame:AddAuraGroup("OffensiveCooldowns",
        AuraUtil.AuraFilters.Helpful .. "|" .. AuraUtil.AuraFilters.Important
        .. "|!" .. AuraUtil.AuraFilters.BigDefensive
        .. "|!" .. AuraUtil.AuraFilters.ExternalDefensive, {
            initializeFrame = initializeFrame,
            maxFrameCount = 2,
            layout = { layoutIndex = 4 },
        })

    -- AuraContainers don't automatically refresh on target swap; force it like Blizzard's TargetFrameMixin does.
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:SetScript("OnEvent", function()
        frame:UpdateAllAuras()
    end)

    return frame
end
