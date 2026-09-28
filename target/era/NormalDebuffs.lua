local _, core = ...;

if core.hasAuraContainer then return; end;

local debuffFilterString = AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Harmful,
    AuraUtil.AuraFilters.IncludeNameplateOnly);

local maxDebuffs = 10;

local function initializeButton(button)
    core:InitializeAuraButtonBase(button);

    button.BlackBorder = button:CreateTexture(nil, "BORDER");
    button.BlackBorder:SetDrawLayer("BORDER", 1);
    core:SetPixelPoint(button.BlackBorder, "TOPLEFT", button, "TOPLEFT", -core.pixel, core.pixel);
    core:SetPixelPoint(button.BlackBorder, "BOTTOMRIGHT", button, "BOTTOMRIGHT", core.pixel, -core.pixel);
    button.BlackBorder:SetColorTexture(0, 0, 0, 1);

    button.border = button:CreateTexture(nil, "OVERLAY");
    button.border:SetDrawLayer("OVERLAY", 6);
    core:SetPixelPoint(button.border, "TOPLEFT", button, "TOPLEFT", -core.pixel, core.pixel);
    core:SetPixelPoint(button.border, "BOTTOMRIGHT", button, "BOTTOMRIGHT", core.pixel, -core.pixel);
end;

local function updateButton(button, auraData)
    core:UpdateAuraCooldown(button, auraData);

    AuraUtil.SetAuraBorderColor(button.border, auraData.dispelName);
end;

local function updateDebuffBudgets(container)
    local playerCount = math.min(container:GetGroupCount("PlayerDebuffs"), maxDebuffs);
    local remainingAfterPlayer = maxDebuffs - playerCount;
    container:SetGroupMaxCount("ImportantDebuffs", remainingAfterPlayer);
    container:Update();

    local importantCount = math.min(container:GetGroupCount("ImportantDebuffs"), remainingAfterPlayer);
    container:SetGroupMaxCount("OtherDebuffs", remainingAfterPlayer - importantCount);
    container:Update();
end;

function core:CreateNormalDebuffsFrame(parent)
    local frame = CreateFrame("Frame", "TargetNormalDebuffAuraContainer", parent);
    core:SetPixelSize(frame, 20, 20);

    local container = core:CreateAuraContainer(frame, {
        unit = "target",
        iconSize = 22,
        spacing = 2,
        maxLineSize = 120,
        anchorPoint = "BOTTOMLEFT",
        growX = 1,
        growY = 1,
    });

    container:AddGroup("PlayerDebuffs", debuffFilterString, {
        initializeFrame = initializeButton,
        updateFrame = updateButton,
        candidateFilters = { isFromPlayerOrPlayerPet = true },
        maxFrameCount = maxDebuffs,
    });

    container:AddGroup("ImportantDebuffs", debuffFilterString, {
        initializeFrame = initializeButton,
        updateFrame = updateButton,
        candidateFilters = { isFromPlayerOrPlayerPet = false, isPriorityAura = true },
        maxFrameCount = 0,
    });

    container:AddGroup("OtherDebuffs", debuffFilterString, {
        initializeFrame = initializeButton,
        updateFrame = updateButton,
        candidateFilters = { isFromPlayerOrPlayerPet = false, isPriorityAura = false },
        maxFrameCount = 0,
    });

    container:Update();
    updateDebuffBudgets(container);

    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
    eventFrame:RegisterUnitEvent("UNIT_AURA", "target");
    eventFrame:SetScript("OnEvent", function()
        container:Update();
        updateDebuffBudgets(container);
    end);

    return frame;
end;
