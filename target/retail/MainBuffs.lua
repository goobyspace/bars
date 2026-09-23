---@diagnostic disable: undefined-global

local _, core = ...

if not core.hasAuraContainer then return end

local maxBuffs = 32

-- Reuse Blizzard's own first-party TargetFrameAuraContainer instead of building
-- a CustomAuraContainerTemplate: addon-created containers can't render auras
-- that aren't the player's own casts on this client (secret aura data), but
-- Blizzard's built-in container isn't subject to that restriction.
function core:CreateMainBuffsFrame(parent)
    local frame = TargetFrame.TargetFrameContent.TargetFrameContentContextual.Auras

    frame:SetParent(parent)
    frame:SetAuraContainerAnchorsChangedCallback(nil) -- stop Blizzard's TargetFrame layout from re-anchoring this
    frame:ClearAllPoints()
    frame:SetMaxBuffs(maxBuffs)
    frame:SetMaxDebuffs(0) -- our own Normal/ImportantDebuffs frames already cover debuffs
    frame:SetShowAuraCount(true)
    frame:SetUnit("target")

    -- TargetFrame's own OnEvent (which normally triggers this) is disabled elsewhere,
    -- so refresh explicitly whenever the target itself changes, not just its auras.
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:SetScript("OnEvent", function()
        frame:UpdateAllAuras()
    end)

    return frame
end
