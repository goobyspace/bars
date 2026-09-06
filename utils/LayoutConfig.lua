local _, core = ...

core.thickMode = true;
core.healPredictionOverflow = 1.5;

function core:SetBarFont(fontString, fontSize)
    if not fontString then return end
    fontString:SetFont("Fonts\\FRIZQT__.TTF", (fontSize or 12) * (core.fontScale or 1), "OUTLINE")
end
