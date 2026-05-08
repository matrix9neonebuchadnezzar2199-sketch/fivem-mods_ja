---@diagnostic disable: undefined-global

local uiOpen = false

---NUI を閉じてフォーカス解除
local function closeUi()
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'setState', state = 'hidden' })
end

---ゲーム側で ESC / フロントキャンセルを拾う（NUI に届かない環境向け）
CreateThread(function()
    while true do
        if uiOpen then
            Wait(0)
            -- 202 INPUT_FRONTEND_CANCEL / 322 は他 JP-MOD でメニュー閉じに使用
            if IsControlJustPressed(0, 202) or IsControlJustPressed(0, 322) then
                closeUi()
                Wait(200)
            end
        else
            Wait(500)
        end
    end
end)

---作成結果（サーバーまたはローカル検証）
---@param ok boolean
local function applyCreateResult(ok)
    if ok then
        closeUi()
    end
end

---NUI を表示
---@param payload table
local function openUi(payload)
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage(payload)
end

---空 DVD（items.lua の export）
exports('useBlank', function(_, _)
    if uiOpen then return end
    openUi({ action = 'openCreate' })
end)

---@param meta table
---@return string
local function normalizePack(meta)
    local p = type(meta.pack) == 'string' and meta.pack or ''
    if p == 'fushokufu' or p == 'clear' or p == 'tall' then
        return p
    end
    return 'clear'
end

---スロットのアイテム名からパッケージ種別を決める（ox の行とインベントリ画像の正）
---@param slotName string
---@return string
local function packFromSlotName(slotName)
    if slotName == 'dvd_recorded1' then return 'fushokufu' end
    if slotName == 'dvd_recorded2' then return 'clear' end
    if slotName == 'dvd_recorded3' then return 'tall' end
    return ''
end

---GitHub のファイルページ（/blob/）を img 用の raw 直リンクへ寄せる（server と同じ規則）
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

---データ入り DVD（dvd_recorded1〜3 共通 export）
exports('useRecorded', function(_, slot)
    if uiOpen then return end
    local meta = (slot and slot.metadata) or {}
    local title = type(meta.title) == 'string' and meta.title or ''
    local url = type(meta.url) == 'string' and meta.url or ''
    local slotName = slot and slot.name or ''
    local pack = packFromSlotName(slotName)
    if pack == '' then
        pack = normalizePack(meta)
    end
    local coverUrl = type(meta.coverUrl) == 'string' and meta.coverUrl or ''
    if coverUrl == '' and pack == 'tall' and type(meta.imageurl) == 'string' then
        coverUrl = meta.imageurl
    end
    if coverUrl ~= '' then
        coverUrl = normalizeCoverImageUrl(coverUrl)
    end
    openUi({
        action = 'openPlayer',
        title = title,
        url = url,
        pack = pack,
        coverUrl = coverUrl,
    })
end)

RegisterNUICallback('save', function(data, cb)
    if type(data) == 'string' then
        local ok, decoded = pcall(json.decode, data)
        if ok and type(decoded) == 'table' then
            data = decoded
        else
            data = {}
        end
    end
    local title = data and data.title
    local url = data and data.url
    -- dvdPack を優先（JSON のキー pack が欠ける環境向け）。従来 pack も受け付ける。
    local pack = data and (data.dvdPack or data.pack)
    local coverUrl = data and data.coverUrl
    if type(pack) == 'string' then
        pack = pack:gsub('^%s+', ''):gsub('%s+$', '')
    end
    if type(title) ~= 'string' or type(url) ~= 'string' or type(pack) ~= 'string' then
        cb('ok')
        return
    end
    if type(coverUrl) ~= 'string' then coverUrl = '' end
    title = title:gsub('^%s+', ''):gsub('%s+$', '')
    url = url:gsub('^%s+', ''):gsub('%s+$', '')
    coverUrl = coverUrl:gsub('^%s+', ''):gsub('%s+$', '')
    if coverUrl ~= '' then
        coverUrl = normalizeCoverImageUrl(coverUrl)
    end
    local tlen = utf8.len(title)
    if title == '' or url == '' or not tlen or tlen < 1 or tlen > Config.MaxTitleLength then
        applyCreateResult(false)
        cb('ok')
        return
    end
    if pack ~= 'fushokufu' and pack ~= 'clear' and pack ~= 'tall' then
        applyCreateResult(false)
        cb('ok')
        return
    end
    if pack ~= 'tall' and coverUrl ~= '' then
        applyCreateResult(false)
        cb('ok')
        return
    end
    if pack == 'tall' and coverUrl ~= '' then
        if not coverUrl:match('^https://') or #coverUrl > Config.MaxCoverUrlLength then
            applyCreateResult(false)
            cb('ok')
            return
        end
    end
    TriggerServerEvent('dvd-maker:server:create', title, url, pack, coverUrl)
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    closeUi()
    cb('ok')
end)

RegisterNUICallback('playbackEnded', function(_, cb)
    cb('ok')
end)

RegisterNetEvent('dvd-maker:client:createResult', applyCreateResult)
