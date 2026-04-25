local function buildDeck()
    local deck = {}

    for _, suit in ipairs(Config.Suits) do
        for _, rank in ipairs(Config.Ranks) do
            deck[#deck + 1] = {
                isJoker = false,
                suit = suit.symbol,
                suitName = suit.name,
                rank = rank.name,
                display = rank.display,
                color = suit.color,
            }
        end
    end

    for _, joker in ipairs(Config.Jokers) do
        deck[#deck + 1] = {
            isJoker = true,
            suit = joker.symbol,
            jokerName = joker.name,
            color = joker.color,
        }
    end

    return deck
end

local function drawRandomCard()
    local deck = buildDeck()
    local index = math.random(1, #deck)
    return deck[index]
end

RegisterNetEvent('jp-card:drawCard', function()
    local source = source
    local cardData = drawRandomCard()
    TriggerClientEvent('jp-card:showResult', source, cardData)

    if not Config.ShowChatMessage then
        return
    end

    local playerName = GetPlayerName(source) or ('Player %s'):format(source)
    local message
    if cardData.isJoker then
        message = ('[🂠 トランプ] %s が %s %s を引いた！'):format(playerName, cardData.suit, cardData.jokerName)
    else
        message = ('[🂠 トランプ] %s が %s %s を引いた！'):format(playerName, cardData.suit, cardData.display)
    end

    local srcPed = GetPlayerPed(source)
    if srcPed <= 0 then
        return
    end

    local srcCoords = GetEntityCoords(srcPed)
    local players = GetPlayers()
    for _, targetIdStr in ipairs(players) do
        local targetId = tonumber(targetIdStr)
        if targetId then
            local targetPed = GetPlayerPed(targetId)
            if targetPed > 0 then
                local targetCoords = GetEntityCoords(targetPed)
                local dist = #(srcCoords - targetCoords)
                if dist <= Config.ChatRange then
                    TriggerClientEvent('chat:addMessage', targetId, {
                        color = { 200, 200, 50 },
                        args = { message }
                    })
                end
            end
        end
    end
end)
