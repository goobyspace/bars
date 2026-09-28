local _, core = ...;

if not core.hasAuraContainer then return; end;

local debuffFilterString = AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Harmful,
    AuraUtil.AuraFilters.IncludeNameplateOnly);

local maxDebuffs = 10;

local playerDebuffSlots = 6;
local importantDebuffSlots = 2;
local otherDebuffSlots = maxDebuffs - playerDebuffSlots - importantDebuffSlots;

function core:CreateNormalDebuffsFrame(parent)
    local frame = CreateFrame("AuraContainer", "TargetNormalDebuffAuraContainer", parent, "CustomAuraContainerTemplate");
    core:SetPixelSize(frame, 22, 22);
    frame:SetUnit("target");
    frame:SetFlowLayoutMaximumLineSize(120);
    frame:SetFlowLayoutAnchorPoint("BOTTOMLEFT");
    frame:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Up);

    local function initializeFrame(button)
        core:InitializeAuraButtonBase(button, 22);

        local blackBorder = button:CreateTexture(nil, "BORDER");
        blackBorder:SetDrawLayer("BORDER", 1);
        core:SetPixelPoint(blackBorder, "TOPLEFT", button, "TOPLEFT", -core.pixel, core.pixel);
        core:SetPixelPoint(blackBorder, "BOTTOMRIGHT", button, "BOTTOMRIGHT", core.pixel, -core.pixel);
        blackBorder:SetColorTexture(0, 0, 0, 1);

        local border = button:CreateTexture(nil, "OVERLAY");
        border:SetDrawLayer("OVERLAY", 6);
        core:SetPixelPoint(border, "TOPLEFT", button, "TOPLEFT", -core.pixel, core.pixel);
        core:SetPixelPoint(border, "BOTTOMRIGHT", button, "BOTTOMRIGHT", core.pixel, -core.pixel);
        button:AddDispelTypeTexture(border, {
            style = Enum.CustomAuraButtonDispelTypeTextureStyle.Border,
            showWhenHarmful = true,
            showWhenHelpful = false,
            showWithoutDispelType = true,
        });
    end;

    frame:AddAuraGroup("PlayerDebuffs", debuffFilterString, {
        initializeFrame = initializeFrame,
        candidateFilters = { isFromPlayerOrPlayerPet = true },
        maxFrameCount = playerDebuffSlots,
        layout = { layoutIndex = 1, elementSpacing = 2 },
    });

    frame:AddAuraGroup("ImportantDebuffs", debuffFilterString, {
        initializeFrame = initializeFrame,
        candidateFilters = { isFromPlayerOrPlayerPet = false, isPriorityAura = true },
        maxFrameCount = importantDebuffSlots,
        layout = { layoutIndex = 2, elementSpacing = 2 },
    });

    frame:AddAuraGroup("OtherDebuffs", debuffFilterString, {
        initializeFrame = initializeFrame,
        candidateFilters = { isFromPlayerOrPlayerPet = false, isPriorityAura = false },
        maxFrameCount = otherDebuffSlots,
        layout = { layoutIndex = 3, elementSpacing = 2 },
    });

    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
    eventFrame:RegisterUnitEvent("UNIT_AURA", "target");
    eventFrame:SetScript("OnEvent", function()
        frame:UpdateAllAuras();
    end);

    return frame;
end;
