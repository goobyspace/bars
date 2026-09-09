local _, core = ...
local colours = core.colours
local config = core.debugConfig

local copyFrame;

function core:ShowCopyableText(text)
    if not copyFrame then
        copyFrame = CreateFrame("Frame", "BarsCopyFrame", UIParent);
        copyFrame:SetSize(config.copyWindowWidth, config.copyWindowHeight);
        copyFrame:SetPoint("CENTER");
        copyFrame:SetFrameStrata("DIALOG");
        copyFrame:EnableMouse(true);
        copyFrame:SetMovable(true);
        copyFrame:RegisterForDrag("LeftButton");
        copyFrame:SetScript("OnDragStart", copyFrame.StartMoving);
        copyFrame:SetScript("OnDragStop", copyFrame.StopMovingOrSizing);

        local bg = copyFrame:CreateTexture(nil, "BACKGROUND");
        bg:SetAllPoints();
        bg:SetColorTexture(colours.blackDialog.r, colours.blackDialog.g, colours.blackDialog.b,
            colours.blackDialog.a);

        local close = CreateFrame("Button", nil, copyFrame, "UIPanelCloseButton");
        close:SetPoint("TOPRIGHT");

        local scroll = CreateFrame("ScrollFrame", "BarsCopyScrollFrame", copyFrame, "UIPanelScrollFrameTemplate");
        scroll:SetPoint("TOPLEFT", config.scrollLeft, -config.scrollTop);
        scroll:SetPoint("BOTTOMRIGHT", -config.scrollRight, config.scrollBottom);

        copyFrame.edit = CreateFrame("EditBox", nil, scroll);
        copyFrame.edit:SetMultiLine(true);
        copyFrame.edit:SetFontObject("ChatFontNormal");
        copyFrame.edit:SetWidth(config.editWidth);
        copyFrame.edit:SetAutoFocus(false);
        copyFrame.edit:SetScript("OnEscapePressed", function()
            copyFrame:Hide();
        end);
        scroll:SetScrollChild(copyFrame.edit);

        table.insert(UISpecialFrames, "BarsCopyFrame");
    end

    copyFrame.edit:SetText(text);
    copyFrame:Show();
    copyFrame.edit:SetFocus();
    copyFrame.edit:HighlightText();
end

local function getPixelDebugText()
    local screenWidth, screenHeight = GetPhysicalScreenSize();
    local lines = {
        format("screen %dx%d, UIParent %.2fx%.2f units, effective scale %.4f, 1px = %.4f units",
            screenWidth, screenHeight, UIParent:GetWidth(), UIParent:GetHeight(),
            UIParent:GetEffectiveScale(), core.pixel),
    };

    for _, name in ipairs({ "PlayerFrameContainer", "HPBarContainer", "PrimaryResourceContainer",
        "PetFrameContainer", "SwingTimerContainer", "TargetFrameContainer", "TargetHPBarContainer",
        "TargetResourceContainer", "TargetTargetHPBarContainer" }) do
        local frame = _G[name];
        if frame and frame:GetLeft() then
            table.insert(lines, format("%s: left %.2f bottom %.2f width %.2f height %.2f", name,
                frame:GetLeft() / core.pixel, frame:GetBottom() / core.pixel,
                frame:GetWidth() / core.pixel, frame:GetHeight() / core.pixel));
        end
    end

    return table.concat(lines, "\n");
end

local function formatFlightPathKey(route)
    local source, destination = route:match("^(.-)\031(.*)$");
    return source and format("%q .. \"\\031\" .. %q", source, destination) or format("%q", route);
end

local function getFlightPathTimingText()
    local lines = {
        "local _, core = ...",
        "",
        "core.flightPathData = {",
    };

    local allDurations = BarsGlobalVariables and BarsGlobalVariables.flightPathDurations or {};
    for _, faction in ipairs({ "Alliance", "Horde" }) do
        local knownDurations = {};
        for route, duration in pairs(allDurations[faction] or {}) do
            knownDurations[route] = duration;
        end
        for route, duration in pairs(core.flightPathData[faction] or {}) do
            knownDurations[route] = duration;
        end

        local routes = {};
        for route in pairs(knownDurations) do
            table.insert(routes, route);
        end
        table.sort(routes);

        table.insert(lines, format("    %s = {", faction));
        for _, route in ipairs(routes) do
            table.insert(lines, format("        [%s] = %.3f,", formatFlightPathKey(route), knownDurations[route]));
        end
        table.insert(lines, "    },");
    end
    table.insert(lines, "};");
    return table.concat(lines, "\n");
end

SLASH_BARSPX1 = "/barspx";
SlashCmdList["BARSPX"] = function()
    core:ShowCopyableText(getPixelDebugText());
end

SLASH_BARSFLIGHTPATHTIMING1 = "/flightdata";
SlashCmdList["BARSFLIGHTPATHTIMING"] = function()
    core:ShowCopyableText(getFlightPathTimingText());
end
