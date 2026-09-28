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

function core:AddMouseoverBorder(frame, hoverFrame, unit, linkedFrame, linkedUnit)
    local border = CreateFrame("Frame", nil, frame);
    border:SetAllPoints(frame);
    border:SetFrameLevel(frame.bar:GetFrameLevel() + 1);

    local color = colours.mouseoverBorder;
    local inset = core.pixel;
    local outerWidth = frame:GetWidth() + 2 * inset;
    local outerHeight = frame:GetHeight() + 2 * inset;
    local function createEdge(point, width, height, xOfs, yOfs)
        local edge = border:CreateTexture(nil, "OVERLAY");
        core:SetPixelPoint(edge, point, border, point, xOfs, yOfs);
        core:SetPixelSize(edge, width, height);
        edge:SetColorTexture(color.r, color.g, color.b, color.a);
    end;

    -- offset outward by a pixel so this sits outside the black background border instead of covering it
    createEdge("TOPLEFT", outerWidth, core.pixel, -inset, inset);
    createEdge("BOTTOMLEFT", outerWidth, core.pixel, -inset, -inset);
    createEdge("TOPLEFT", core.pixel, outerHeight, -inset, inset);
    createEdge("TOPRIGHT", core.pixel, outerHeight, inset, inset);
    border:Show();
    border:SetAlpha(0);

    -- GameTooltip:SetUnit (used for our own tooltips) sets the "mouseover" unit but never clears it on leave,
    -- so it goes stale once we stop hovering; only trust it for genuinely external sources via events, never on our own OnLeave
    local hovering = false;
    local ignoreMouseoverUnit = false;
    local function updateExternalHover()
        if hovering then
            border:SetAlpha(1);
        elseif linkedFrame and linkedFrame:IsMouseOver() then
            border:SetAlphaFromBoolean(UnitIsUnit(linkedUnit, unit));
        elseif not ignoreMouseoverUnit and UnitExists("mouseover") then
            border:SetAlphaFromBoolean(UnitIsUnit("mouseover", unit));
        else
            border:SetAlpha(0);
        end;
    end;

    local updater = CreateFrame("Frame");
    updater:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
    updater:RegisterEvent("PLAYER_TARGET_CHANGED");
    if unit == "targettarget" then
        updater:RegisterUnitEvent("UNIT_TARGET", "target");
    end;
    updater:SetScript("OnEvent", function(_, event)
        if event == "UPDATE_MOUSEOVER_UNIT" then
            ignoreMouseoverUnit = false;
        end;
        updateExternalHover();
    end);
    -- poll every frame instead of relying solely on events, so external hover state always resyncs
    updater:SetScript("OnUpdate", updateExternalHover);

    hoverFrame:HookScript("OnEnter", function()
        hovering = true;
        border:SetAlpha(1);
    end);
    hoverFrame:HookScript("OnLeave", function()
        hovering = false;
        ignoreMouseoverUnit = true;
        border:SetAlpha(0);
    end);
end;
