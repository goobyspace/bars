local _, core = ...;

function core:InitializeLayout()
    core.pixel = core:GetPixelUnit();
    core.barHeight = 10 * core.pixel;
    core.barBgHeight = core.barHeight + 2 * core.pixel;
    core.fontScale = 1.5;
    core.castbarHeight = 28;
    core.barGrowth = core.barBgHeight - 5 * core.pixel;
    core.labelAboveBar = 10 * core.fontScale + core.barGrowth / 2;
    core.labelBelowBar = -(8 * core.fontScale + core.barGrowth / 2);

    core.rowGap = 4 * core.pixel;
    core.rowStep = core.barBgHeight + core.rowGap;
    core.primaryBarOffset = core.rowGap;
    core.hpRowOffset = core.primaryBarOffset + 2 * core.rowStep;
    core.targetHpRowOffset = -16;
    local targetTextTop = core.targetHpRowOffset - core.barBgHeight / 2 + core.labelAboveBar
        + math.floor(12 * core.fontScale + 0.5) / 2;
    core.targetHpRowOffset = core.targetHpRowOffset - core:EvenPixels(targetTextTop + 2 * core.pixel);
    core.targetResourceRowOffset = core.targetHpRowOffset - core.barBgHeight - core.rowGap;

    core.width = core:EvenPixels(340);
    core.playerHeight = core:EvenPixels(core.hpRowOffset + 2 * core.rowStep + core.barBgHeight);
    core.targetHeight = core:EvenPixels(-core.targetResourceRowOffset + core.barBgHeight + 2 * core.pixel);
    core.playerFrameY = -244;
    core.frameGap = 43;
    core.targetFrameY = core.playerFrameY + core.hpRowOffset + 2 * core.barBgHeight + core.frameGap
        - core.targetResourceRowOffset;
end;

core.healPredictionOverflow = 1.5;
core.playerCastbarOffsetY = -48;

core.resourceTickerConfig = {
    fiveSecondRuleDuration = 5,
};

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
