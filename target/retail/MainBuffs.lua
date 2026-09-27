---@diagnostic disable: undefined-global

local _, core = ...;

if not core.hasAuraContainer then return; end;

local maxBuffs = 32;

-- For some reason on forever the aura container only shows player-cast buffs
-- so we cant use it as a proper target buff tracker :(
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
