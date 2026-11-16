local _, core = ...;
local colours = core.colours;

if not core.isForever then return; end;

local glowAuras = {
    { spellID = 29166, r = 0.1, g = 0.45, b = 0.9 },                    -- innervate
    { spellID = 1259799, r = 161 / 255, g = 113 / 255, b = 235 / 255 }, -- night elf racial
};

function core:CreateSpellWidgets(_, primaryBar)
    -- the glow sits above the bg so the bar has to be pushed above the glow
    primaryBar.bar.bg = primaryBar.bar:CreateTexture(nil, "BACKGROUND");
    primaryBar.bar.bg:SetAllPoints();
    primaryBar.bar.bg:SetColorTexture(colours.black.r, colours.black.g, colours.black.b);

    -- aura apis hide spell ids in combat, so the aura container does the matching and the glow rides on the aura frame
    -- no scripts on the aura frame itself, secret shown calls fail on frames with handlers
    for _, entry in ipairs(glowAuras) do
        local container = CreateFrame("AuraContainer", nil, primaryBar, "CustomAuraContainerTemplate");
        container:SetAllPoints(primaryBar);
        container:SetUnit("player");
        container:AddAuraSlot("active", "HELPFUL", {
            candidateFilters = { includeSpellIDs = { [entry.spellID] = true } },
            initializeFrame = function(auraFrame)
                auraFrame:SetAllPoints(container);
                core:CreateBarGlow(auraFrame, entry.r, entry.g, entry.b):SetAlpha(1);
            end,
        });
    end;

    primaryBar.bar:SetFrameLevel(primaryBar:GetFrameLevel() + 5);
end;
