local _, core = ...;

if not core.hasAuraContainer then return; end;

local debuffFilterString = AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Harmful,
    AuraUtil.AuraFilters.Player, AuraUtil.AuraFilters.IncludeNameplateOnly, "!" .. AuraUtil.AuraFilters.CrowdControl);

local maxDebuffs = 8;

function core:CreateNormalDebuffsFrame(parent)
    local frame = CreateFrame("Frame", "TargetNormalDebuffAuraContainer", parent);
    local layout = core.auraTrackerLayout;
    local spacing = math.max(layout.iconWidth + layout.minIconSpacing,
        (core.width - layout.iconWidth) / (maxDebuffs - 1)) - layout.iconWidth;
    core:SetPixelSize(frame, core.width, layout.iconHeight);
    local container = CreateFrame("AuraContainer", nil, frame, "CustomAuraContainerTemplate");
    container:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT");
    container:SetUnit("target");
    container:SetFlowLayoutMaximumLineSize(core.width + spacing);
    container:SetFlowLayoutAnchorPoint("BOTTOMLEFT");
    container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Up);

    local durationFormatter = core:CreateAuraDurationFormatter();

    local function initializeFrame(button)
        for _, border in ipairs(core:InitializeTrackedDebuffButton(button)) do
            button:AddDispelTypeTexture(border, {
                style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
                showWhenHarmful = true,
                showWhenHelpful = false,
                showWithoutDispelType = true,
                customDispelColorMap = core.auraDispelColorMap,
            });
        end;
        button:SetDurationText(button.durationText, { textFormatter = durationFormatter });
    end;

    container:AddAuraGroup("PlayerDebuffs", debuffFilterString, {
        initializeFrame = initializeFrame,
        maxFrameCount = maxDebuffs,
        layout = { layoutIndex = 1, elementSpacing = spacing },
    });

    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
    eventFrame:RegisterUnitEvent("UNIT_AURA", "target");
    eventFrame:SetScript("OnEvent", function()
        container:UpdateAllAuras();
    end);

    return frame;
end;
