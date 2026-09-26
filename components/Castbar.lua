local _, core = ...
local colours = core.colours

function core:CreateCastbarBase(name, parent)
    local frame = CreateFrame("Frame", name, parent)
    core:SetPixelSize(frame, core.width, core.castbarHeight)

    frame.bg = frame:CreateTexture()
    core:SetPixelPoint(frame.bg, "RIGHT", frame, "RIGHT", 0, 0)
    frame.bg:SetTexture(134532)
    frame.bg:SetColorTexture(colours.black.r, colours.black.g, colours.black.b)
    core:SetPixelSize(frame.bg, core.width - core.castbarHeight, core.castbarHeight)
    frame.bg:SetDrawLayer("OVERLAY", -2)

    frame.bar = CreateFrame("StatusBar", nil, frame)
    frame.bar:SetStatusBarTexture("Interface/Addons/Bars/assets/fade-bottom.png")
    core:InsetBarInBackground(frame.bar, frame.bg)
    frame.bar:SetMinMaxValues(0, 1, Enum.StatusBarInterpolation.ExponentialEaseOut)

    frame.bgFill = frame:CreateTexture()
    frame.bgFill:SetAllPoints(frame.bar)
    frame.bgFill:SetTexture("Interface/Addons/Bars/assets/fade-top.png")
    frame.bgFill:SetVertexColor(colours.castBackground.r, colours.castBackground.g, colours.castBackground.b)
    frame.bgFill:SetDrawLayer("OVERLAY", -1)

    frame.bgTint = frame:CreateTexture()
    frame.bgTint:SetAllPoints(frame.bar)
    frame.bgTint:SetColorTexture(1, 1, 1)
    frame.bgTint:SetBlendMode("MOD")
    frame.bgTint:SetDrawLayer("OVERLAY", 0)

    frame.spark = frame.bar:CreateTexture(nil, "OVERLAY", nil, 0)
    frame.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    frame.spark:SetBlendMode("ADD")
    frame.spark:SetAlpha(0.4)
    frame.spark:SetSize(12, core.castbarHeight * 2)
    frame.spark:SetPoint("CENTER", frame.bar:GetStatusBarTexture(), "RIGHT", 0, 0)

    frame.icon = frame:CreateTexture()
    core:SetPixelPoint(frame.icon, "LEFT", frame, "LEFT", 0, 0)
    core:SetPixelSize(frame.icon, core.castbarHeight, core.castbarHeight)

    frame.name = frame.bar:CreateFontString("PrimaryText")
    frame.name:SetDrawLayer("OVERLAY", 1)
    frame.name:SetPoint("LEFT", 0, 0)
    frame.name:SetSize(core.width / 2, core.castbarHeight)
    frame.name:SetJustifyH("LEFT")
    core:SetBarFont(frame.name, 10)

    frame.target = frame.bar:CreateFontString("PrimaryText")
    frame.target:SetDrawLayer("OVERLAY", 1)
    frame.target:SetPoint("RIGHT", 0, 0)
    frame.target:SetSize(core.width / 2, core.castbarHeight)
    frame.target:SetJustifyH("RIGHT")
    core:SetBarFont(frame.target, 10)

    return frame;
end

function core:SetCastbarColor(frame, r, g, b)
    frame.bar:SetStatusBarColor(r, g, b)
    frame.bgTint:SetVertexColor(r, g, b)
end

function core:ShowCastbarKicked(frame, savedName, savedIcon, kickedName)
    frame.name:SetText(savedName)
    frame.icon:SetTexture(savedIcon)
    if kickedName then
        frame.target:SetText(UnitNameFromGUID(kickedName))
    end
    core:SetCastbarColor(frame, colours.castKicked.r, colours.castKicked.g, colours.castKicked.b)
    local durationObject = C_DurationUtil.CreateDuration()
    durationObject:SetTimeFromStart(0, 0.1)
    frame.bar:SetTimerDuration(durationObject,
        Enum.StatusBarInterpolation.Immediate,
        Enum.StatusBarTimerDirection.ElapsedTime)
end
