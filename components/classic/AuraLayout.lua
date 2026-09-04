local _, core = ...

if core.hasAuraContainer then return end

local function MatchesCandidateFilters(auraData, candidateFilters)
    if not candidateFilters then return true end
    for key, value in pairs(candidateFilters) do
        if auraData[key] ~= value then return false end
    end
    return true
end

local function CollectAuras(unit, filter, maxCount, candidateFilters, sortFunc)
    local auras = {}
    local batchSize = maxCount and math.max(maxCount * 4, 40) or 40
    AuraUtil.ForEachAura(unit, filter, batchSize, function(auraData)
        if MatchesCandidateFilters(auraData, candidateFilters) then
            table.insert(auras, auraData)
        end
        return false
    end, true)

    table.sort(auras, sortFunc or AuraUtil.DefaultAuraCompare)

    if maxCount and maxCount > 0 and #auras > maxCount then
        for i = #auras, maxCount + 1, -1 do
            auras[i] = nil
        end
    end

    return auras
end

-- layout = { unit, iconSize, spacing, maxLineSize (px), anchorPoint, growX (1/-1), growY (1/-1) }
-- groups are drawn in the order they were added, flowing continuously across the same grid
function core:CreateAuraContainer(parent, layout)
    local pool = CreateFramePool("Frame", parent, nil, function(_, button) button:Hide() end)
    local groups = {}
    local container = {}

    function container:AddGroup(name, filter, opts)
        table.insert(groups, {
            name = name,
            filter = filter,
            maxCount = opts.maxFrameCount,
            candidateFilters = opts.candidateFilters,
            sortFunc = opts.sortFunc,
            initializeFrame = opts.initializeFrame,
            updateFrame = opts.updateFrame,
            cachedCount = 0,
        })
    end

    function container:GetGroupCount(name)
        for _, group in ipairs(groups) do
            if group.name == name then
                return group.cachedCount
            end
        end
        return 0
    end

    function container:SetGroupMaxCount(name, maxCount)
        for _, group in ipairs(groups) do
            if group.name == name then
                group.maxCount = maxCount
            end
        end
    end

    function container:Update()
        pool:ReleaseAll()

        local iconSize = layout.iconSize
        local spacing = layout.spacing or 0
        local perLine = math.max(1, math.floor((layout.maxLineSize + spacing) / (iconSize + spacing)))
        local growX = layout.growX or 1
        local growY = layout.growY or -1
        local anchorPoint = layout.anchorPoint or "TOPLEFT"

        local index = 0
        for _, group in ipairs(groups) do
            local auras = CollectAuras(layout.unit, group.filter, group.maxCount, group.candidateFilters, group.sortFunc)
            group.cachedCount = #auras

            for _, auraData in ipairs(auras) do
                local button = pool:Acquire()
                if not button.initialized then
                    button:SetSize(iconSize, iconSize)
                    if group.initializeFrame then group.initializeFrame(button) end
                    button.initialized = true
                end
                if group.updateFrame then group.updateFrame(button, auraData) end

                local col = index % perLine
                local row = math.floor(index / perLine)
                button:ClearAllPoints()
                button:SetPoint(anchorPoint, parent, anchorPoint,
                    growX * col * (iconSize + spacing), growY * row * (iconSize + spacing))
                button:Show()

                index = index + 1
            end
        end
    end

    return container
end
