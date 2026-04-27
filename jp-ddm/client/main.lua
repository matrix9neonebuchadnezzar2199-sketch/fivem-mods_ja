-- jp-DDM: クライアント KVS 保存・NUI・再生（プレビューはゲーム透過表示のためスクリプトカメラなし）
local function dbg(msg)
    if Config.Debug then
        print(('[jp-ddm] %s'):format(tostring(msg)))
    end
end

local KVP_BLOB = 'ddm_v1'
--- 本番: 管理画面を隠して左手ミニ表示のとき true（/ddm で戻る）
local managerUiHidden = false
--- プレビュー: 画面を開いたままモーションだけ再生
local previewMode = false
local playbackActive = false
local playbackPaused = false
local skipToNext = false
local setlist = {}
local currentIndex = 0
local loopEnabled = false
local totalSteps = 0

---@return table
local function readStore()
    local s = GetResourceKvpString and GetResourceKvpString(KVP_BLOB) or (GetResourceKvp and GetResourceKvp(KVP_BLOB) or nil)
    if s and s ~= '' then
        local ok, t = pcall(json.decode, s)
        if ok and t and type(t) == 'table' then
            t.presets = t.presets or {}
            t.historyCatalog = t.historyCatalog or {}
            if type(t.historyCatalog) ~= 'table' then
                t.historyCatalog = {}
            end
            return t
        end
    end
    return { presets = {}, historyCatalog = {} }
end

---@param store table
local function writeStore(store)
    local enc = json.encode(store)
    if SetResourceKvpString then
        SetResourceKvpString(KVP_BLOB, enc)
    elseif SetResourceKvp then
        SetResourceKvp(KVP_BLOB, enc)
    end
end

--- 再生ループ外から呼べる全停止
function StopMotionPlayback()
    local wasPreview = previewMode
    previewMode = false
    managerUiHidden = false
    playbackActive = false
    playbackPaused = false
    skipToNext = false
    local ped = PlayerPedId()
    if ped and ped ~= 0 then
        ClearPedTasks(ped)
    end
    SendNUIMessage({ type = 'stopYoutube' })
    SendNUIMessage({ type = 'playbackEnded' })
    if wasPreview then
        SendNUIMessage({ type = 'previewEnd' })
    else
        SendNUIMessage({ type = 'hideMini' })
    end
    dbg('StopMotionPlayback')
end

---@param remainMs integer
---@param stepDurMs integer
local function sendMiniState(remainMs, stepDurMs)
    local name = '—'
    if setlist[currentIndex] then
        name = setlist[currentIndex].name or setlist[currentIndex].clip or '—'
    end
    local remainSec = math.max(0, math.floor(remainMs / 1000))
    local pay = {
        type = 'miniTick',
        current = currentIndex,
        total = totalSteps,
        name = name,
        remain = remainSec,
        loop = loopEnabled,
    }
    if previewMode then
        pay.type = 'previewTick'
    end
    SendNUIMessage(pay)
end

function PlaySetlist()
    CreateThread(function()
        local lastReportSec = -1
        while playbackActive and #setlist > 0 do
            if currentIndex < 1 or currentIndex > #setlist then
                if loopEnabled and #setlist > 0 then
                    currentIndex = 1
                else
                    break
                end
            end
            local item = setlist[currentIndex]
            if not item or not item.dict or not item.clip or item.dict == '' or item.clip == '' then
                currentIndex = currentIndex + 1
            else
                local ped = PlayerPedId()
                if not ped or ped == 0 then
                    break
                end
                local dict, clip = item.dict, item.clip
                RequestAnimDict(dict)
                local t0r = GetGameTimer()
                while not HasAnimDictLoaded(dict) do
                    if not playbackActive or GetGameTimer() - t0r > 8000 then
                        break
                    end
                    Wait(20)
                end
                if HasAnimDictLoaded(dict) and playbackActive then
                    TaskPlayAnim(ped, dict, clip, 8.0, -8.0, -1, 1, 0.0, false, false, false)
                end
                local stepMs = (item.duration or 10) * 1000
                local t0 = GetGameTimer()
                while playbackActive do
                    if skipToNext then
                        skipToNext = false
                        lastReportSec = -1
                        break
                    end
                    while playbackPaused and playbackActive do
                        Wait(100)
                    end
                    if not playbackActive then
                        break
                    end
                    local elapsed = GetGameTimer() - t0
                    if elapsed >= stepMs then
                        lastReportSec = -1
                        break
                    end
                    local remain = stepMs - elapsed
                    local remainSec = math.floor(remain / 1000)
                    if remainSec ~= lastReportSec then
                        lastReportSec = remainSec
                        sendMiniState(remain, stepMs)
                    end
                    Wait(150)
                end
                if not playbackActive then
                    break
                end
                currentIndex = currentIndex + 1
                if currentIndex > #setlist and loopEnabled and #setlist > 0 then
                    currentIndex = 1
                elseif currentIndex > #setlist and not loopEnabled then
                    break
                end
            end
        end
        local wasPreview = previewMode
        previewMode = false
        playbackActive = false
        SendNUIMessage({ type = 'stopYoutube' })
        local ped2 = PlayerPedId()
        if ped2 and ped2 ~= 0 then
            ClearPedTasks(ped2)
        end
        if wasPreview then
            SendNUIMessage({ type = 'previewEnd' })
        else
            SendNUIMessage({ type = 'hideMini' })
        end
    end)
end

local function openDdmUi()
    if playbackActive and managerUiHidden then
        SetNuiFocus(true, true)
        SendNUIMessage({ type = 'showManager' })
        managerUiHidden = false
        return
    end
    if playbackActive and previewMode then
        SetNuiFocus(true, true)
        return
    end
    if playbackActive then
        return
    end
    SetNuiFocus(true, true)
    managerUiHidden = false
    local st0 = readStore()
    SendNUIMessage({
        type = 'openDdm',
        catalog = Config.Catalog,
        historyCatalog = st0.historyCatalog,
        maxSlots = Config.MaxSlots,
        defaultDuration = Config.DefaultDuration,
    })
end

local function closeDdmUi()
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'uiClosed' })
end

RegisterCommand(Config.OpenCommand, function()
    openDdmUi()
end, false)

RegisterCommand(Config.StopCommand, function()
    StopMotionPlayback()
end, false)

--- 最小化中は NUI フォーカスが無いためマウス不可 → F12 または /ddm（キーは GTA 設定で変更可）
local reopenUiCmd = 'jp_ddm_reopen_ui'
RegisterCommand(reopenUiCmd, function()
    openDdmUi()
end, false)
local defaultKey = type(Config.ReopenManagerKey) == 'string' and Config.ReopenManagerKey ~= '' and Config.ReopenManagerKey or 'F12'
RegisterKeyMapping(reopenUiCmd, 'jp-DDM: 管理に戻る (最小化中・マウス不可のため)', 'keyboard', defaultKey)

TriggerEvent('chat:addSuggestion', ('/%s'):format(Config.OpenCommand), 'jp-DDM: 管理画面', {})
TriggerEvent('chat:addSuggestion', ('/%s'):format(Config.StopCommand), 'jp-DDM: 停止', {})

RegisterNUICallback('close', function(_, cb)
    StopMotionPlayback()
    closeDdmUi()
    cb({ ok = true })
end)

--- 再生中: 管理画面（ツール）を再表示。モーションは継続
RegisterNUICallback('reopenManager', function(_, cb)
    if not playbackActive then
        cb({ ok = false })
        return
    end
    managerUiHidden = false
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'showManager' })
    cb({ ok = true })
end)

--- ミニHUD: 全停止＋NUI フォーカス解放（オーバーレイ全閉じ）
RegisterNUICallback('closeFromMini', function(_, cb)
    StopMotionPlayback()
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'uiClosed' })
    cb({ ok = true })
end)

RegisterNUICallback('preview', function(data, cb)
    local dict = data.dict
    local clip = data.clip
    if type(dict) ~= 'string' or type(clip) ~= 'string' or dict == '' or clip == '' then
        cb({ err = 'bad' })
        return
    end
    local ped = PlayerPedId()
    RequestAnimDict(dict)
    local t0 = GetGameTimer()
    while not HasAnimDictLoaded(dict) and GetGameTimer() - t0 < 5000 do
        Wait(10)
    end
    if not HasAnimDictLoaded(dict) then
        cb({ err = 'noload' })
        return
    end
    TaskPlayAnim(ped, dict, clip, 8.0, -8.0, 4000, 0, 0.0, false, false, false)
    cb({ ok = true })
end)

RegisterNUICallback('savePreset', function(data, cb)
    if type(data) ~= 'table' or type(data.name) ~= 'string' or data.name == '' then
        cb({ ok = false })
        return
    end
    local st = readStore()
    st.presets = st.presets or {}
    local entry = {
        name = data.name,
        setlist = data.setlist or {},
        youtubeUrl = data.youtubeUrl,
        youtubeStart = tonumber(data.youtubeStart) or 0,
        loop = data.loop and true or false,
        audioEnabled = (data.audioEnabled == false) and false or true,
    }
    local found = false
    for i, p in ipairs(st.presets) do
        if p.name == entry.name then
            st.presets[i] = entry
            found = true
            break
        end
    end
    if not found then
        st.presets[#st.presets + 1] = entry
    end
    writeStore(st)
    cb({ ok = true })
end)

RegisterNUICallback('loadPreset', function(data, cb)
    if type(data) ~= 'table' or type(data.name) ~= 'string' then
        cb({ setlist = {}, youtubeUrl = '', youtubeStart = 0, loop = false, audioEnabled = true })
        return
    end
    local st = readStore()
    for _, p in ipairs(st.presets or {}) do
        if p.name == data.name then
            local ae = p.audioEnabled
            if ae == nil then
                ae = true
            end
            cb({
                setlist = p.setlist or {},
                youtubeUrl = p.youtubeUrl or '',
                youtubeStart = p.youtubeStart or 0,
                loop = p.loop and true or false,
                audioEnabled = ae and true or false,
            })
            return
        end
    end
    cb({ setlist = {}, youtubeUrl = '', youtubeStart = 0, loop = false, audioEnabled = true })
end)

RegisterNUICallback('listPresets', function(_, cb)
    local st = readStore()
    local list = {}
    for _, p in ipairs(st.presets or {}) do
        if p.name and p.name ~= '' then
            list[#list + 1] = p.name
        end
    end
    cb({ presets = list })
end)

RegisterNUICallback('deletePreset', function(data, cb)
    if type(data) ~= 'table' or type(data.name) ~= 'string' or data.name == '' then
        cb({ ok = false })
        return
    end
    local st = readStore()
    st.presets = st.presets or {}
    local np = {}
    for _, p in ipairs(st.presets) do
        if p.name ~= data.name then
            np[#np + 1] = p
        end
    end
    st.presets = np
    writeStore(st)
    cb({ ok = true })
end)

--- カスタム追加（Dict+Clip+リスト）が確定したら KVS 履歴に。カタログ「その他」下の「過去に入力…」用
RegisterNUICallback('rememberCustomMotion', function(data, cb)
    if type(data) ~= 'table' or type(data.dict) ~= 'string' or type(data.clip) ~= 'string' then
        cb({ ok = false })
        return
    end
    local d = (data.dict:gsub('^%s+', '')):gsub('%s+$', '')
    local cl = (data.clip:gsub('^%s+', '')):gsub('%s+$', '')
    if d == '' or cl == '' or #d > 220 or #cl > 220 then
        cb({ ok = false })
        return
    end
    for _, c in ipairs(Config.Catalog or {}) do
        if c.dict == d and c.clip == cl then
            local st0 = readStore()
            cb({ ok = true, historyCatalog = st0.historyCatalog or {}, skipped = true })
            return
        end
    end
    local name = data.name
    if type(name) ~= 'string' or name == '' then
        name = cl
    else
        name = name:sub(1, 200)
    end
    local dur = tonumber(data.defaultDuration) or 10
    if dur < 1 then dur = 1 end
    if dur > 600 then dur = 600 end
    local st = readStore()
    st.historyCatalog = st.historyCatalog or {}
    local maxH = 200
    if type(Config.HistoryCatalogMax) == 'number' and Config.HistoryCatalogMax > 0 then
        maxH = math.floor(Config.HistoryCatalogMax)
    end
    local found = false
    for i, e in ipairs(st.historyCatalog) do
        if type(e) == 'table' and e.dict == d and e.clip == cl then
            st.historyCatalog[i] = { name = name, dict = d, clip = cl, defaultDuration = dur, category = 'other' }
            found = true
            break
        end
    end
    if not found then
        while #st.historyCatalog >= maxH do
            table.remove(st.historyCatalog, 1)
        end
        st.historyCatalog[#st.historyCatalog + 1] = { name = name, dict = d, clip = cl, defaultDuration = dur, category = 'other' }
    end
    writeStore(st)
    cb({ ok = true, historyCatalog = st.historyCatalog })
end)

--- プレビュー: 管理画面＋NUI フォーカスを維持。YouTube は鳴らさない
RegisterNUICallback('startPreview', function(data, cb)
    if type(data) ~= 'table' or type(data.setlist) ~= 'table' or #data.setlist < 1 then
        cb('bad')
        return
    end
    StopMotionPlayback()
    Wait(80)
    setlist = data.setlist
    totalSteps = #setlist
    loopEnabled = data.loop and true or false
    currentIndex = 1
    previewMode = true
    managerUiHidden = false
    playbackActive = true
    playbackPaused = false
    skipToNext = false
    local ped = PlayerPedId()
    if ped and ped ~= 0 then
        ClearPedTasks(ped)
    end
    PlaySetlist()
    cb('ok')
end)

RegisterNUICallback('startPlayback', function(data, cb)
    if type(data) ~= 'table' or type(data.setlist) ~= 'table' or #data.setlist < 1 then
        cb('bad')
        return
    end
    StopMotionPlayback()
    Wait(100)
    previewMode = false
    setlist = data.setlist
    totalSteps = #setlist
    loopEnabled = data.loop and true or false
    currentIndex = 1
    playbackActive = true
    playbackPaused = false
    skipToNext = false
    local audioOn = (data.audioEnabled == false) and false or true
    local yt = data.youtubeUrl
    if type(yt) == 'string' and yt ~= '' then
        SendNUIMessage({
            type = 'playYoutube',
            url = yt,
            startSeconds = tonumber(data.youtubeStart) or 0,
            audioEnabled = audioOn,
        })
    end
    SetNuiFocus(false, false)
    managerUiHidden = true
    SendNUIMessage({ type = 'hideManager' })
    SendNUIMessage({
        type = 'showMini',
        reopenKey = defaultKey,
        openCommand = Config.OpenCommand,
    })
    local ped = PlayerPedId()
    if ped and ped ~= 0 then
        ClearPedTasks(ped)
    end
    PlaySetlist()
    cb('ok')
end)

RegisterNUICallback('stopPlayback', function(_, cb)
    StopMotionPlayback()
    cb('ok')
end)

RegisterNUICallback('togglePause', function(data, cb)
    if data and data.pause ~= nil then
        playbackPaused = data.pause and true or false
    else
        playbackPaused = not playbackPaused
    end
    cb('ok')
end)

RegisterNUICallback('nextStep', function(_, cb)
    skipToNext = true
    cb('ok')
end)

RegisterNUICallback('miniStop', function(_, cb)
    StopMotionPlayback()
    cb('ok')
end)
