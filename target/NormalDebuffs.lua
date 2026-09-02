local _, core = ...

local frame = nil;

-- Matches Blizzard's default target frame debuff filter.
local DEBUFF_FILTER_STRING = AuraUtil.AuraFilters.Harmful .. "|" .. AuraUtil.AuraFilters.IncludeNameplateOnly;

local MAX_DEBUFFS = 10

-- PlayerDebuffs stays uncapped (at MAX_DEBUFFS) so it never flashes; ImportantDebuffs and
-- OtherDebuffs caps are derived directly from the live counts of the tiers above them, avoiding
-- the widen-then-shrink flicker that came from resetting every group to the full budget.
local function UpdateDebuffBudgets()
    if frame == nil then return end

    local playerCount = math.min(frame:GetAuraGroupFrameCount("PlayerDebuffs"), MAX_DEBUFFS)
    local remainingAfterPlayer = MAX_DEBUFFS - playerCount
    frame:SetAuraGroupMaxFrameCount("ImportantDebuffs", remainingAfterPlayer)

    local importantCount = math.min(frame:GetAuraGroupFrameCount("ImportantDebuffs"), remainingAfterPlayer)
    frame:SetAuraGroupMaxFrameCount("OtherDebuffs", remainingAfterPlayer - importantCount)
end

function core:CreateNormalDebuffsFrame(parent)
    frame = CreateFrame("AuraContainer", "TargetNormalDebuffAuraContainer", parent, "CustomAuraContainerTemplate")
    frame:SetSize(20, 20)
    frame:SetUnit("target")
    -- 5 icons per row (2 rows of 10): 5 * 20px icons + 4 * 2px gaps.
    frame:SetFlowLayoutMaximumLineSize(108)
    frame:SetFlowLayoutAnchorPoint("BOTTOMLEFT")
    frame:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Up)

    local function initializeFrame(button)
        local icon = button:CreateTexture(nil, "OVERLAY")
        icon:SetAllPoints()
        button:SetIcon(icon)
        button:SetSize(20, 20)

        local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        cooldown:SetAllPoints()
        cooldown:SetHideCountdownNumbers(true)
        button:SetDurationCooldown(cooldown)

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

    -- Priority order: your own debuffs, then important ones, then anything left, sharing a 10-icon budget.
    frame:AddAuraGroup("PlayerDebuffs", DEBUFF_FILTER_STRING, {
        initializeFrame = initializeFrame,
        candidateFilters = { isFromPlayerOrPlayerPet = true },
        maxFrameCount = MAX_DEBUFFS,
        layout = { layoutIndex = 1, elementSpacing = 2 },
    })

    frame:AddAuraGroup("ImportantDebuffs", DEBUFF_FILTER_STRING, {
        initializeFrame = initializeFrame,
        candidateFilters = { isFromPlayerOrPlayerPet = false, isPriorityAura = true },
        maxFrameCount = 0,
        layout = { layoutIndex = 2, elementSpacing = 2 },
    })

    frame:AddAuraGroup("OtherDebuffs", DEBUFF_FILTER_STRING, {
        initializeFrame = initializeFrame,
        candidateFilters = { isFromPlayerOrPlayerPet = false, isPriorityAura = false },
        maxFrameCount = 0,
        layout = { layoutIndex = 3, elementSpacing = 2 },
    })

    UpdateDebuffBudgets();

    -- AuraContainer frames can't RegisterEvent directly (forbidden aspect), so use a plain helper frame.
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterUnitEvent("UNIT_AURA", "target")
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_TARGET_CHANGED" then
            frame:UpdateAllAuras()
        end
        UpdateDebuffBudgets()
    end)

    return frame
end
