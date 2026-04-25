local function getAllPlayers()
    return GetPlayers()
end

local function getRandomResult()
    local roll = math.random(1, 2)
    if roll == 1 then
        return { side = 'heads', label = Config.HeadsLabel }
    end
    return { side = 'tails', label = Config.TailsLabel }
end

RegisterNetEvent('jp-coin:tossCoin', function()
    local source = source
    local result = getRandomResult()
    TriggerClientEvent('jp-coin:showResult', source, result)

    if not Config.ShowChatMessage then
        return
    end

    local sourcePed = GetPlayerPed(source)
    if sourcePed <= 0 then
        return
    end

    local sourceCoords = GetEntityCoords(sourcePed)
    local playerName = GetPlayerName(source) or ('Player %s'):format(source)
    local message = ('[🪙 コイントス] %s → %s！'):format(playerName, result.label)

    for _, targetIdStr in ipairs(getAllPlayers()) do
        local targetId = tonumber(targetIdStr)
        if targetId then
            local targetPed = GetPlayerPed(targetId)
            if targetPed > 0 then
                local targetCoords = GetEntityCoords(targetPed)
                local dist = #(sourceCoords - targetCoords)
                if dist <= Config.ChatRange then
                    TriggerClientEvent('chat:addMessage', targetId, {
                        color = { 220, 180, 50 },
                        args = { message }
                    })
                end
            end
        end
    end
end)
