local _, core = ...

function core:CreateSimpleStatusBar(name, parent, width, height, opts)
    opts = opts or {}
    local frame = CreateFrame("Frame", name, parent, opts.template)
    core:SetPixelSize(frame, width, height)

    frame.bg = frame:CreateTexture()
    core:SetPixelPoint(frame.bg, "CENTER", frame, "CENTER", 0, 0)
    frame.bg:SetTexture(134532)
    frame.bg:SetColorTexture(0, 0, 0)
    core:SetPixelSize(frame.bg, width, height)
    frame.bg:SetDrawLayer("OVERLAY", -1)

    frame.bar = CreateFrame("StatusBar", nil, frame)
    frame.bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
    core:InsetBarInBackground(frame.bar, frame.bg)

    if opts.includeText then
        frame.text = frame.bar:CreateFontString("PrimaryText")
        frame.text:SetDrawLayer("OVERLAY", 1)
        frame.text:SetPoint(opts.textPoint or "CENTER", opts.textX or 0, opts.textY or 0)
        core:SetBarFont(frame.text, opts.fontSize or 12)
    end

    return frame
end
