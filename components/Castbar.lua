local _, core = ...

-- creates the chrome shared by every castbar: background, status bar, icon, and name/target
-- fontstrings. Callers add their own event wiring (and, for the player, empower stages) on top.
function core:CreateCastbarBase(name, parent)
    local frame = CreateFrame("Frame", name, parent)
    frame:SetSize(core.width, core.castbarHeight)

    frame.bg = frame:CreateTexture()
    frame.bg:SetPoint("RIGHT")
    frame.bg:SetTexture(134532)
    frame.bg:SetColorTexture(0, 0, 0)
    frame.bg:SetSize(core.width - core.castbarHeight, core.castbarHeight)
    frame.bg:SetDrawLayer("OVERLAY", -1)

    frame.bar = CreateFrame("StatusBar", nil, frame)
    frame.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
    frame.bar:SetPoint("RIGHT", -2, 0)
    frame.bar:SetSize(core.width - core.castbarHeight - 2, core.castbarHeight - 2)
    frame.bar:SetMinMaxValues(0, 1, Enum.StatusBarInterpolation.ExponentialEaseOut)

    frame.icon = frame:CreateTexture()
    frame.icon:SetPoint("LEFT", 0, 0)
    frame.icon:SetSize(core.castbarHeight, core.castbarHeight)

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

-- renders the frozen "kicked" red bar state shared by the player/target castbars
function core:ShowCastbarKicked(frame, savedName, savedIcon, kickedName)
    frame.name:SetText(savedName)
    frame.icon:SetTexture(savedIcon)
    if kickedName then
        frame.target:SetText(UnitNameFromGUID(kickedName))
    end
    frame.bar:SetStatusBarColor(1.0, 0.1, 0.2)
    local durationObject = C_DurationUtil.CreateDuration()
    durationObject:SetTimeFromStart(0, 0.1)
    frame.bar:SetTimerDuration(durationObject,
        Enum.StatusBarInterpolation.Immediate,
        Enum.StatusBarTimerDirection.ElapsedTime)
end
