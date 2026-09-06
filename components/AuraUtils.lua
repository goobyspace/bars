local _, core = ...

function core:InitializeAuraButtonBase(button, iconSize)
    if not button.icon then
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetAllPoints()
        if button.SetIcon then button:SetIcon(button.icon) end
    end

    if iconSize then
        button:SetSize(iconSize, iconSize)
    end

    if not button.cooldown then
        button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        button.cooldown:SetAllPoints()
        button.cooldown:SetHideCountdownNumbers(true)
        if button.SetDurationCooldown then button:SetDurationCooldown(button.cooldown) end
    end
end

function core:UpdateAuraCooldown(button, auraData)
    if button.icon and auraData.icon then
        button.icon:SetTexture(auraData.icon)
    end

    if button.cooldown then
        local duration = auraData.duration or 0
        local start = duration > 0 and (auraData.expirationTime - duration) or 0
        CooldownFrame_Set(button.cooldown, start, duration, duration > 0)
    end
end
