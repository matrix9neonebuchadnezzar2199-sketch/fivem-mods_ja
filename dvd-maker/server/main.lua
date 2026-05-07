---@diagnostic disable: undefined-global

local ox = exports.ox_inventory

---YouTube URL ホワイトリスト（指示書の正規表現どおり）
---@param url string
---@return boolean
local function isValidYouTubeUrl(url)
    if type(url) ~= 'string' then return false end
    if url:match('^https://www%.youtube%.com/watch%?v=[%w%-_]+') then return true end
    if url:match('^https://youtube%.com/watch%?v=[%w%-_]+') then return true end
    if url:match('^https://youtu%.be/[%w%-_]+') then return true end
    if url:match('^https://m%.youtube%.com/watch%?v=[%w%-_]+') then return true end
    return false
end

---タイトル検証（UTF-8 文字数 1〜Max）
---@param title string
---@return boolean
local function isValidTitle(title)
    if type(title) ~= 'string' then return false end
    local len = utf8.len(title)
    if not len or len < 1 or len > Config.MaxTitleLength then return false end
    return true
end

---空 DVD をデータ入り DVD に変換（所持・削除・付与はサーバー権威）
RegisterNetEvent('dvd-maker:server:create', function(title, url)
    local src = source
    if type(title) ~= 'string' or type(url) ~= 'string' then
        print(('[dvd-maker] invalid types from %s'):format(src))
        return
    end

    title = title:gsub('^%s+', ''):gsub('%s+$', '')
    url = url:gsub('^%s+', ''):gsub('%s+$', '')

    if not isValidTitle(title) or not isValidYouTubeUrl(url) then
        print(('[dvd-maker] validation failed from %s'):format(src))
        TriggerClientEvent('dvd-maker:client:createResult', src, false)
        return
    end

    local count = ox:Search(src, 'count', Config.BlankItem) or 0
    if count < 1 then
        print(('[dvd-maker] no blank dvd: %s'):format(src))
        TriggerClientEvent('dvd-maker:client:createResult', src, false)
        return
    end

    local removed = ox:RemoveItem(src, Config.BlankItem, 1)
    if not removed then
        print(('[dvd-maker] RemoveItem failed: %s'):format(src))
        TriggerClientEvent('dvd-maker:client:createResult', src, false)
        return
    end

    local added = ox:AddItem(src, Config.RecordedItem, 1, { title = title, url = url })
    if not added then
        print(('[dvd-maker] AddItem failed, restoring blank: %s'):format(src))
        ox:AddItem(src, Config.BlankItem, 1)
        TriggerClientEvent('dvd-maker:client:createResult', src, false)
        return
    end

    TriggerClientEvent('dvd-maker:client:createResult', src, true)
end)
