---@diagnostic disable: undefined-global

local _, core = ...;

if not core.isForever then return; end;

local maxBuffs = 32;

-- On Forever, a CustomAuraContainerTemplate can only ever render the player's own
-- casts (target buff data from other sources is secret), so reuse Blizzard's own
-- first-party TargetFrameAuraContainer instead, which isn't subject to that restriction.
function core:CreateMainBuffsFrame(parent)
    local frame = TargetFrame.TargetFrameContent.TargetFrameContentContextual.Auras;

    frame:SetParent(parent);
    frame:SetAuraContainerAnchorsChangedCallback(nil); -- keep the game from moving it back
    frame:ClearAllPoints();
    frame:SetMaxBuffs(maxBuffs);
    frame:SetMaxDebuffs(0);
    frame:SetShowAuraCount(true);
    frame:SetUnit("target");

    -- we disabled targetframe's event handler so we gotta make it again
    local eventFrame = CreateFrame("Frame");
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
    eventFrame:SetScript("OnEvent", function()
        frame:UpdateAllAuras();
    end);

    return frame;
end;
