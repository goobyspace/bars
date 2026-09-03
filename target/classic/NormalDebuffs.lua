local _, core = ...

if core.hasAuraContainer then return end

local DEBUFF_FILTER_STRING = AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Harmful,
    AuraUtil.AuraFilters.IncludeNameplateOnly);

local MAX_DEBUFFS = 10

local function InitializeButton(button)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()

    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints()
    button.cooldown:SetHideCountdownNumbers(true)

    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetPoint("TOPLEFT", -1, 1)
    button.border:SetPoint("BOTTOMRIGHT", 1, -1)
end

local function UpdateButton(button, auraData)
    button.icon:SetTexture(auraData.icon)

    local duration = auraData.duration or 0
    local start = duration > 0 and (auraData.expirationTime - duration) or 0
    CooldownFrame_Set(button.cooldown, start, duration, duration > 0)

    AuraUtil.SetAuraBorderColor(button.border, auraData.dispelName);
end

local function UpdateDebuffBudgets(container)
    local playerCount = math.min(container:GetGroupCount("PlayerDebuffs"), MAX_DEBUFFS)
    local remainingAfterPlayer = MAX_DEBUFFS - playerCount
    container:SetGroupMaxCount("ImportantDebuffs", remainingAfterPlayer)

    local importantCount = math.min(container:GetGroupCount("ImportantDebuffs"), remainingAfterPlayer)
    container:SetGroupMaxCount("OtherDebuffs", remainingAfterPlayer - importantCount)
end

function core:CreateNormalDebuffsFrame(parent)
    local frame = CreateFrame("Frame", "TargetNormalDebuffAuraContainer", parent)
    frame:SetSize(20, 20)

    local container = core:CreateAuraContainer(frame, {
        unit = "target",
        iconSize = 20,
        spacing = 2,
        maxLineSize = 108,
        anchorPoint = "BOTTOMLEFT",
        growX = 1,
        growY = 1,
    })

    container:AddGroup("PlayerDebuffs", DEBUFF_FILTER_STRING, {
        initializeFrame = InitializeButton,
        updateFrame = UpdateButton,
        candidateFilters = { isFromPlayerOrPlayerPet = true },
        maxFrameCount = MAX_DEBUFFS,
    })

    container:AddGroup("ImportantDebuffs", DEBUFF_FILTER_STRING, {
        initializeFrame = InitializeButton,
        updateFrame = UpdateButton,
        candidateFilters = { isFromPlayerOrPlayerPet = false, isPriorityAura = true },
        maxFrameCount = 0,
    })

    container:AddGroup("OtherDebuffs", DEBUFF_FILTER_STRING, {
        initializeFrame = InitializeButton,
        updateFrame = UpdateButton,
        candidateFilters = { isFromPlayerOrPlayerPet = false, isPriorityAura = false },
        maxFrameCount = 0,
    })

    UpdateDebuffBudgets(container);

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterUnitEvent("UNIT_AURA", "target")
    eventFrame:SetScript("OnEvent", function()
        container:Update()
        UpdateDebuffBudgets(container)
    end)

    return frame
end
