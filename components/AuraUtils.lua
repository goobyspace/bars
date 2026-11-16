local _, core = ...;

core.auraDispelColorMap = {
    None = { r = 0, g = 0, b = 0 },
    Physical = { r = 0, g = 0, b = 0 },
};

function core:InitializeAuraButtonBase(button, iconSize)
    if not button.icon then
        -- native AuraContainer buttons expect an OVERLAY-layer icon texture, or it renders blank/white
        button.icon = button:CreateTexture(nil, "OVERLAY");
        button.icon:SetAllPoints();
        if button.SetIcon then button:SetIcon(button.icon); end;
    end;

    if iconSize then
        core:SetPixelSize(button, iconSize, iconSize);
    end;

    button.icon:SetTexCoord(core:GetCroppedTexCoords(button:GetWidth(), button:GetHeight()));

    if not button.cooldown then
        button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate");
        button.cooldown:SetAllPoints();
        button.cooldown:SetHideCountdownNumbers(true);
        if button.SetDurationCooldown then button:SetDurationCooldown(button.cooldown); end;
    end;
end;

function core:UpdateAuraCooldown(button, auraData)
    if button.icon and auraData.icon then
        button.icon:SetTexture(auraData.icon);
    end;

    if button.cooldown then
        local duration = auraData.duration or 0;
        local start = duration > 0 and (auraData.expirationTime - duration) or 0;
        CooldownFrame_Set(button.cooldown, start, duration, duration > 0);
    end;
end;

function core:CreateAuraDurationFormatter()
    local formatter = C_StringUtil.CreateNumericRuleFormatter();
    formatter:SetBreakpoints({
        {
            threshold = 0,
            step = 1,
            rounding = Enum.NumericRuleFormatRounding.Down,
            format = "%d",
        },
    });
    return formatter;
end;

function core:InitializeAuraDurationText(button, parent)
    button.durationText = parent:CreateFontString(nil, "OVERLAY");
    button.durationText:SetPoint("CENTER");
    core:SetBarFont(button.durationText, 12);
end;

-- 4 white edge textures on a frame above the cooldown, meant to be tinted by AddDispelTypeTexture
function core:CreateEdgeBorders(button, thickness)
    local borderFrame = CreateFrame("Frame", nil, button);
    borderFrame:SetAllPoints();
    borderFrame:SetFrameLevel(button.cooldown:GetFrameLevel() + 1);

    local borders = {};
    for _, edge in ipairs({
        { "TOPLEFT", "TOPRIGHT", true },
        { "BOTTOMLEFT", "BOTTOMRIGHT", true },
        { "TOPLEFT", "BOTTOMLEFT", false },
        { "TOPRIGHT", "BOTTOMRIGHT", false },
    }) do
        local border = borderFrame:CreateTexture(nil, "OVERLAY");
        core:SetPixelPoint(border, edge[1], borderFrame, edge[1], 0, 0);
        core:SetPixelPoint(border, edge[2], borderFrame, edge[2], 0, 0);
        if edge[3] then
            border:SetHeight(thickness * core.pixel);
        else
            border:SetWidth(thickness * core.pixel);
        end;
        border:SetColorTexture(1, 1, 1, 1);
        table.insert(borders, border);
    end;
    return borders, borderFrame;
end;

function core:InitializeTrackedDebuffButton(button)
    local width = core.auraTrackerLayout.iconWidth;
    local height = core.auraTrackerLayout.iconHeight;
    core:SetPixelSize(button, width, height);
    core:InitializeAuraButtonBase(button);
    button.icon:ClearAllPoints();
    core:SetPixelPoint(button.icon, "TOPLEFT", button, "TOPLEFT", 2 * core.pixel, -2 * core.pixel);
    core:SetPixelPoint(button.icon, "BOTTOMRIGHT", button, "BOTTOMRIGHT", -2 * core.pixel, 2 * core.pixel);
    button.cooldown:SetDrawEdge(false);

    local borders, borderFrame = core:CreateEdgeBorders(button, 2);
    core:InitializeAuraDurationText(button, borderFrame);

    return borders;
end;
