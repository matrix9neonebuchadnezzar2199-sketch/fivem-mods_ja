-- サーバー側 ユーティリティ関数（日本語版）
-- 主にDiscord Webhookでのログ送信機能

Delivery = {}
Delivery.Functions = {}

-- プレイヤー詳細情報を取得
Delivery.Functions.GetPlayerDetails = function(source)
    local player = Bridge.GetPlayer(source)
    if not player then return nil end
    local ids = player.getIdentifiers()

    return {
        name = player.getName(),
        identifier = player.identifier,
        discord = ids.discord,
        license = ids.license,
        ip = ids.ip
    }
end

-- Discord Webhook へログを送信
Delivery.Functions.SendWB = function(title, msg, color, source)
    if not Config['EnableWebhook'] then return end

    local footerTokens = {
        text = Config['CommunityName'] .. " • " .. os.date("%Y/%m/%d %H:%M:%S"),
        icon_url = Config['CommunityLogo']
    }

    local embed = {
        {
            ["color"] = color,
            ["title"] = title,
            ["description"] = msg,
            ["footer"] = footerTokens,
            ["author"] = {
                ["name"] = Config['CommunityName'],
                ["icon_url"] = Config['CommunityLogo']
            }
        }
    }

    -- プレイヤー情報があれば、Embedにフィールドを追加
    if source then
        local playerDetails = Delivery.Functions.GetPlayerDetails(source)
        if playerDetails then
            local discordRaw = playerDetails.discord or 'discord:0'
            local discordMention = '<@' .. string.sub(discordRaw, 9) .. '>'
            embed[1]["fields"] = {
                { ["name"] = "プレイヤー名", ["value"] = playerDetails.name, ["inline"] = true },
                { ["name"] = "サーバーID", ["value"] = tostring(source), ["inline"] = true },
                { ["name"] = "識別子", ["value"] = "||" .. playerDetails.identifier .. "||", ["inline"] = false },
                { ["name"] = "Discord", ["value"] = discordMention, ["inline"] = true },
                { ["name"] = "ライセンス", ["value"] = "||" .. (playerDetails.license or "N/A") .. "||", ["inline"] = true },
            }
        end
    end

    PerformHttpRequest(Config['Webhook'], function(err, text, headers) end, 'POST', json.encode({
        username = "配達ログ",
        avatar_url = Config['Avatar'],
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end
