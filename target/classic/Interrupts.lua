local _, core = ...

if not core.isClassicEra then return end

-- Classic Era has no specializations; each class has at most one interrupt, sometimes
-- available at multiple talent-independent ranks (highest known rank first)
local CLASS_INTERRUPTS = {
    ["ROGUE"]   = { 1769, 1766 },                                  -- Kick (rank 2, rank 1)
    ["WARRIOR"] = { 7355, 7354, 72, 6554, 6552 },                  -- Shield Bash (r3/r2/r1), Pummel (r2/r1)
    ["MAGE"]    = { 2139 },                                        -- Counterspell
    ["SHAMAN"]  = { 10414, 10413, 10412, 8046, 8045, 8044, 8042 }, -- Earth Shock (r7..r1)
    ["DRUID"]   = { 16979 },                                       -- Feral Charge (Bear Form only)
};

-- Warlock's interrupt is cast through the Felhunter, so it's on the pet's spellbook, not the player's
local CLASS_PET_INTERRUPTS = {
    ["WARLOCK"] = { 19647, 19244 }, -- Spell Lock (rank 2, rank 1)
};

function core:GetPlayerInterruptSpellID()
    local playerClass = select(2, UnitClass("player"))

    for _, spellID in ipairs(CLASS_INTERRUPTS[playerClass] or {}) do
        if C_SpellBook.IsSpellKnown(spellID) then
            return spellID
        end
    end

    for _, spellID in ipairs(CLASS_PET_INTERRUPTS[playerClass] or {}) do
        if C_SpellBook.IsSpellKnown(spellID, Enum.SpellBookSpellBank.Pet) then
            return spellID
        end
    end

    return nil
end
