local _, core = ...

if core.hasAuraContainer then return end

-- classic era purges are on the player's own spellbook (priest/shaman) or the pet's (warlock)
local CLASSIC_PURGE_SPELL_IDS = {
    527,  -- priest: dispel magic
    370,  -- shaman: purge (rank 1)
    8012, -- shaman: purge (rank 2)
};

local CLASSIC_PET_PURGE_SPELL_IDS = {
    19505, -- warlock felhunter: devour magic (rank 1)
    19731, -- rank 2
    19734, -- rank 3
    19736, -- rank 4
};

local knowsPurge = false;

local function CheckKnowsPurge()
    for _, spellID in ipairs(CLASSIC_PURGE_SPELL_IDS) do
        if C_SpellBook.IsSpellKnown(spellID) then
            return true;
        end
    end
    for _, spellID in ipairs(CLASSIC_PET_PURGE_SPELL_IDS) do
        if C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Pet) then
            return true;
        end
    end
    return false;
end

local MAX_BUFFS = 16

local function InitializeButton(button)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()

    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints()
    button.cooldown:SetHideCountdownNumbers(true)

    button.PurgeBorder = button:CreateTexture(nil, "OVERLAY")
    button.PurgeBorder:SetPoint("TOPLEFT")
    button.PurgeBorder:SetPoint("BOTTOMRIGHT")
    button.PurgeBorder:SetColorTexture(1, 1, 1, 1)
end

local function UpdateButton(button, auraData)
    button.icon:SetTexture(auraData.icon)

    local duration = auraData.duration or 0
    local start = duration > 0 and (auraData.expirationTime - duration) or 0
    CooldownFrame_Set(button.cooldown, start, duration, duration > 0)

    button.PurgeBorder:SetShown(knowsPurge and auraData.isStealable);
end

function core:CreateMainBuffsFrame(parent)
    local frame = CreateFrame("Frame", "TargetMainBuffAuraContainer", parent)
    frame:SetSize(14, 14)

    local container = core:CreateAuraContainer(frame, {
        unit = "target",
        iconSize = 14,
        spacing = 2,
        maxLineSize = 126,
        anchorPoint = "TOPLEFT",
        growX = 1,
        growY = -1,
    })

    container:AddGroup("Buffs", AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Helpful), {
        initializeFrame = InitializeButton,
        updateFrame = UpdateButton,
        maxFrameCount = MAX_BUFFS,
    })

    knowsPurge = CheckKnowsPurge();

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    eventFrame:RegisterEvent("UNIT_PET")
    eventFrame:RegisterUnitEvent("UNIT_AURA", "target")
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_TALENT_UPDATE" or event == "UNIT_PET" then
            knowsPurge = CheckKnowsPurge();
        end
        container:Update()
    end)

    return frame
end
