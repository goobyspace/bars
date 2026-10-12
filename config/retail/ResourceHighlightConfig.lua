local _, core = ...;

if core.isClassicRules then return; end;

-- spells that make the primary resource bar glow once they become usable
-- keyed by class then spec id
core.primaryResourceHighlights = {
    ["WARRIOR"] = {
        [72] = 184367, -- fury: rampage
    },
};
