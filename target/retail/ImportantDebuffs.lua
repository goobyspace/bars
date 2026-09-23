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
        core:InitializeAuraButtonBase(button, 32)

        local blackBorder = button:CreateTexture(nil, "BORDER")
        blackBorder:SetPoint("TOPLEFT", -1, 1)
        blackBorder:SetPoint("BOTTOMRIGHT", 1, -1)
        blackBorder:SetColorTexture(0, 0, 0, 1)
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

    local targetIsVisible

    local function updateAuras()
        targetIsVisible = UnitIsVisible("target")
        frame:SetShown(targetIsVisible)
        if targetIsVisible then
            frame:UpdateAllAuras()
        end
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterUnitEvent("UNIT_AURA", "target")
    eventFrame:SetScript("OnEvent", updateAuras)

    local elapsedSinceVisibilityCheck = 0
    eventFrame:SetScript("OnUpdate", function(_, elapsed)
        elapsedSinceVisibilityCheck = elapsedSinceVisibilityCheck + elapsed
        if elapsedSinceVisibilityCheck < 0.2 then return end
        elapsedSinceVisibilityCheck = 0

        if UnitIsVisible("target") ~= targetIsVisible then
            updateAuras()
        end
    end)

    updateAuras()

    return frame
end
