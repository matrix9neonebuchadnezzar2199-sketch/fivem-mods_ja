---@diagnostic disable: undefined-global

local ox = exports.ox_inventory

---YouTube 動画 ID を URL から抽出（クエリの &si= 等は無視）
---@param url string
---@return string|nil
local function extractYouTubeVideoId(url)
    if type(url) ~= 'string' then return nil end
    local u = url:gsub('^%s+', ''):gsub('%s+$', '')
    if not u:match('^https://') then return nil end
    local id = u:match('[%?&]v=([%w%-_]+)') -- watch?v= または &v=
        or u:match('youtu%.be/([%w%-_]+)')
        or u:match('youtube%.com/embed/([%w%-_]+)')
        or u:match('youtube%.com/live/([%w%-_]+)')
        or u:match('youtube%.com/shorts/([%w%-_]+)')
    if id and #id >= 6 and #id <= 32 then
        return id
    end
    return nil
end

---YouTube URL か（https のみ・ID 抽出で判定）
---@param url string
---@return boolean
local function isValidYouTubeUrl(url)
    return extractYouTubeVideoId(url) ~= nil
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

---GitHub のファイルページ（/blob/）を img 用の raw 直リンクへ寄せる。それ以外はそのまま。
---@param u string
---@return string
local function normalizeCoverImageUrl(u)
    if type(u) ~= 'string' or u == '' then
        return u
    end
    u = u:gsub('^%s+', ''):gsub('%s+$', '')
    if u:match('^http://') then
        u = 'https://' .. u:sub(8)
    end
    if u:match('^https://raw%.githubusercontent%.com/') then
        return u
    end
    local owner, repo, branch, path = u:match('^https://github%.com/([^/]+)/([^/]+)/blob/([^/]+)/(.+)$')
    if not owner then
        owner, repo, branch, path = u:match('^https://www%.github%.com/([^/]+)/([^/]+)/blob/([^/]+)/(.+)$')
    end
    if owner and repo and branch and path then
        path = path:gsub('%?.*$', ''):gsub('#.*$', '')
        return ('https://raw.githubusercontent.com/%s/%s/%s/%s'):format(owner, repo, branch, path)
    end
    return u
end

---トール用表紙 URL（空文字は「未設定で可」）
---@param u string
---@return boolean
local function isValidCoverUrl(u)
    if type(u) ~= 'string' then return false end
    u = u:gsub('^%s+', ''):gsub('%s+$', '')
    if u == '' then return true end
    if #u > Config.MaxCoverUrlLength then return false end
    if not u:match('^https://') then return false end
    return true
end

---@param pack string
---@return string|nil
local function recordedItemForPack(pack)
    if type(pack) ~= 'string' then return nil end
    local hard
    if pack == 'fushokufu' then
        hard = 'dvd_recorded1'
    elseif pack == 'clear' then
        hard = 'dvd_recorded2'
    elseif pack == 'tall' then
        hard = 'dvd_recorded3'
    else
        hard = nil
    end
    local fromConfig = Config.RecordedByPack[pack]
    if fromConfig and hard and fromConfig ~= hard then
        print(('[dvd-maker] WARNING: Config.RecordedByPack[%s]=%s が既定 %s と一致しません。既定側で付与します。config.lua を修正してください。'):format(
            pack, tostring(fromConfig), hard))
        return hard
    end
    return fromConfig or hard
end

---空 DVD をデータ入り DVD に変換（所持・削除・付与はサーバー権威）
RegisterNetEvent('dvd-maker:server:create', function(title, url, pack, coverUrl)
    local src = source
    if type(title) ~= 'string' or type(url) ~= 'string' then
        print(('[dvd-maker] invalid types from %s'):format(src))
        return
    end

    title = title:gsub('^%s+', ''):gsub('%s+$', '')
    url = url:gsub('^%s+', ''):gsub('%s+$', '')
    if url:match('^http://') then
        url = 'https://' .. url:sub(8)
    end

    if type(pack) ~= 'string' then
        print(('[dvd-maker] invalid pack type from %s'):format(src))
        TriggerClientEvent('dvd-maker:client:createResult', src, false)
        return
    end

    pack = pack:gsub('^%s+', ''):gsub('%s+$', '')

    local itemName = recordedItemForPack(pack)
    if not itemName then
        print(('[dvd-maker] unknown pack from %s: %s'):format(src, pack))
        TriggerClientEvent('dvd-maker:client:createResult', src, false)
        return
    end

    if type(coverUrl) ~= 'string' then coverUrl = '' end
    coverUrl = coverUrl:gsub('^%s+', ''):gsub('%s+$', '')
    if coverUrl ~= '' then
        coverUrl = normalizeCoverImageUrl(coverUrl)
    end

    if pack == 'tall' then
        if not isValidCoverUrl(coverUrl) then
            print(('[dvd-maker] invalid cover url from %s'):format(src))
            TriggerClientEvent('dvd-maker:client:createResult', src, false)
            return
        end
    else
        if coverUrl ~= '' then
            print(('[dvd-maker] cover url only allowed for tall from %s'):format(src))
            TriggerClientEvent('dvd-maker:client:createResult', src, false)
            return
        end
    end

    if pack == 'tall' and coverUrl ~= '' then
        local l = coverUrl:lower()
        if string.find(l, 'photos.app.goo.gl', 1, true)
            or (string.find(l, 'photos.google.com', 1, true) and string.find(l, '/share', 1, true)) then
            print(('[dvd-maker] notice: cover URL may not load in NUI (Google Photos share page) player=%s'):format(src))
        end
    end

    if not isValidTitle(title) then
        print(('[dvd-maker] validation failed (title) from %s'):format(src))
        TriggerClientEvent('dvd-maker:client:createResult', src, false)
        return
    end
    if not isValidYouTubeUrl(url) then
        print(('[dvd-maker] validation failed (youtube url) from %s'):format(src))
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

    local meta = {
        title = title,
        url = url,
        label = title,
        pack = pack,
    }
    -- スロット画像は metadata.image で上書き（items.lua の誤設定でも種類どおりに表示）
    local slotImg = Config.InventorySlotImage and Config.InventorySlotImage[pack]
    if type(slotImg) == 'string' and slotImg ~= '' then
        local low = slotImg:lower()
        if #slotImg > 4 and low:sub(-4) == '.png' then
            slotImg = slotImg:sub(1, -5)
        end
        meta.image = slotImg
    end
    -- 表紙は NUI の coverUrl のみ。imageurl は付けない（失敗 URL でスロットが透明になるため）。
    if pack == 'tall' and coverUrl ~= '' then
        meta.coverUrl = coverUrl
    end

    local added = ox:AddItem(src, itemName, 1, meta)
    if not added then
        print(('[dvd-maker] AddItem failed, restoring blank: %s'):format(src))
        ox:AddItem(src, Config.BlankItem, 1)
        TriggerClientEvent('dvd-maker:client:createResult', src, false)
        return
    end

    print(('[dvd-maker] 記録成功: 付与アイテム=%s pack=%s player=%s'):format(itemName, pack, src))

    TriggerClientEvent('dvd-maker:client:createResult', src, true)
end)
