local _, core = ...

if not core.hasAuraContainer then return end

local debuffFilterString = AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Harmful,
    AuraUtil.AuraFilters.IncludeNameplateOnly);

local maxDebuffs = 10

function core:CreateNormalDebuffsFrame(parent)
    local frame = CreateFrame("AuraContainer", "TargetNormalDebuffAuraContainer", parent, "CustomAuraContainerTemplate")
    frame:SetSize(20, 20)
    frame:SetUnit("target")
    frame:SetFlowLayoutMaximumLineSize(108)
    frame:SetFlowLayoutAnchorPoint("BOTTOMLEFT")
    frame:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Up)

    local function UpdateDebuffBudgets()
        local playerCount = math.min(frame:GetAuraGroupFrameCount("PlayerDebuffs"), maxDebuffs)
        local remainingAfterPlayer = maxDebuffs - playerCount
        frame:SetAuraGroupMaxFrameCount("ImportantDebuffs", remainingAfterPlayer)

        local importantCount = math.min(frame:GetAuraGroupFrameCount("ImportantDebuffs"), remainingAfterPlayer)
        frame:SetAuraGroupMaxFrameCount("OtherDebuffs", remainingAfterPlayer - importantCount)
    end

    local function initializeFrame(button)
        core:InitializeAuraButtonBase(button, 20)

        local border = button:CreateTexture(nil, "OVERLAY")
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        button:AddDispelTypeTexture(border, {
            style = Enum.CustomAuraButtonDispelTypeTextureStyle.Border,
            showWhenHarmful = true,
            showWhenHelpful = false,
            showWithoutDispelType = true,
        })
    end

    frame:AddAuraGroup("PlayerDebuffs", debuffFilterString, {
        initializeFrame = initializeFrame,
        candidateFilters = { isFromPlayerOrPlayerPet = true },
        maxFrameCount = maxDebuffs,
        layout = { layoutIndex = 1, elementSpacing = 2 },
    })

    frame:AddAuraGroup("ImportantDebuffs", debuffFilterString, {
        initializeFrame = initializeFrame,
        candidateFilters = { isFromPlayerOrPlayerPet = false, isPriorityAura = true },
        maxFrameCount = 0,
        layout = { layoutIndex = 2, elementSpacing = 2 },
    })

    frame:AddAuraGroup("OtherDebuffs", debuffFilterString, {
        initializeFrame = initializeFrame,
        candidateFilters = { isFromPlayerOrPlayerPet = false, isPriorityAura = false },
        maxFrameCount = 0,
        layout = { layoutIndex = 3, elementSpacing = 2 },
    })

    UpdateDebuffBudgets();

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterUnitEvent("UNIT_AURA", "target")
    eventFrame:SetScript("OnEvent", function()
        frame:UpdateAllAuras()
        UpdateDebuffBudgets()
    end)

    return frame
end
