local _, core = ...;
local colours = core.colours;

function core:CreateSimpleStatusBar(name, parent, width, height, opts)
    opts = opts or {};
    local frame = CreateFrame("Frame", name, parent, opts.template);
    core:SetPixelSize(frame, width, height);

    frame.bg = frame:CreateTexture();
    core:SetPixelPoint(frame.bg, "CENTER", frame, "CENTER", 0, 0);
    frame.bg:SetTexture(134532);
    frame.bg:SetColorTexture(colours.black.r, colours.black.g, colours.black.b);
    core:SetPixelSize(frame.bg, width, height);
    frame.bg:SetDrawLayer("OVERLAY", -1);

    frame.bar = CreateFrame("StatusBar", nil, frame);
    frame.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar");
    core:InsetBarInBackground(frame.bar, frame.bg);

    if opts.includeText then
        frame.text = frame.bar:CreateFontString("PrimaryText");
        frame.text:SetDrawLayer("OVERLAY", 1);
        frame.text:SetPoint(opts.textPoint or "CENTER", opts.textX or 0, opts.textY or 0);
        core:SetBarFont(frame.text, opts.fontSize or 12);
    end;

    return frame;
end;

function core:AddMouseoverBorder(frame, hoverFrame, unit, otherHoverFrame)
    local border = CreateFrame("Frame", nil, frame);
    border:SetAllPoints(frame);
    border:SetFrameLevel(frame.bar:GetFrameLevel() + 1);

    local color = colours.mouseoverBorder;
    local function createEdge(point, width, height)
        local edge = border:CreateTexture(nil, "OVERLAY");
        core:SetPixelPoint(edge, point, border, point, 0, 0);
        core:SetPixelSize(edge, width, height);
        edge:SetColorTexture(color.r, color.g, color.b, color.a);
    end;

    createEdge("TOPLEFT", frame:GetWidth(), core.pixel);
    createEdge("BOTTOMLEFT", frame:GetWidth(), core.pixel);
    createEdge("TOPLEFT", core.pixel, frame:GetHeight());
    createEdge("TOPRIGHT", core.pixel, frame:GetHeight());
    border:Hide();

    local hovering = false;
    local function updateBorder()
        local externalHover = UnitExists("mouseover") and UnitIsUnit("mouseover", unit);
        if otherHoverFrame and otherHoverFrame:IsMouseOver() and not hovering then
            externalHover = false;
        end;
        if hovering or externalHover then
            border:Show();
        else
            border:Hide();
        end;
    end;

    border:SetScript("OnUpdate", updateBorder);
    local updater = CreateFrame("Frame");
    updater:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
    updater:RegisterEvent("PLAYER_TARGET_CHANGED");
    if unit == "targettarget" then
        updater:RegisterUnitEvent("UNIT_TARGET", "target");
    end;
    updater:SetScript("OnEvent", updateBorder);

    hoverFrame:HookScript("OnEnter", function()
        hovering = true;
        border:Show();
    end);
    hoverFrame:HookScript("OnLeave", function()
        hovering = false;
        border:Hide();
    end);
end;
