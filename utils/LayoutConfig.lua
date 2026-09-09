local _, core = ...

core.thickMode = true;
core.healPredictionOverflow = 1.5;
core.playerCastbarOffsetY = -48;

core.debugConfig = {
    copyWindowWidth = 620,
    copyWindowHeight = 320,
    editWidth = 560,
    scrollLeft = 12,
    scrollTop = 30,
    scrollRight = 32,
    scrollBottom = 12,
};

core.widgetConfig = {
    breath = {
        widthFactor = 0.5,
        screenHeight = 0.75,
        fontSize = 12,
        fallbackTimerCount = 3,
    },
    flightPath = {
        updateInterval = 0.1,
        minimumLearnedDuration = 1,
        icon = "Interface\\Icons\\INV_Misc_PocketWatch_02",
    },
};

function core:SetBarFont(fontString, fontSize)
    if not fontString then return end
    fontString:SetFont("Fonts\\FRIZQT__.TTF", (fontSize or 12) * (core.fontScale or 1), "OUTLINE")
end
