-- jp-DDM: クライアント KVS 保存・NUI・プレビュー・再生
local function dbg(msg)
    if Config.Debug then
        print(('[jp-ddm] %s'):format(tostring(msg)))
    end
end

local KVP_BLOB = 'ddm_v1'
local previewCam = nil
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
        if ok and t and t.presets then
            return t
        end
    end
    return { presets = {} }
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

function StopPreviewCamera()
    if previewCam and DoesCamExist(previewCam) then
        SetCamActive(previewCam, false)
        RenderScriptCams(false, true, 500, true, false)
        DestroyCam(previewCam, false)
    end
    previewCam = nil
end

function StartPreviewCamera()
    StopPreviewCamera()
    local ped = PlayerPedId()
    if not ped or ped == 0 then
        return
    end
    local c = GetEntityCoords(ped)
    local f = GetEntityForwardVector(ped)
    local dist = 1.8
    local camX = c.x + f.x * dist
    local camY = c.y + f.y * dist
    local camZ = c.z + 0.35
    previewCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    if not previewCam or previewCam == 0 then
        return
    end
    SetCamCoord(previewCam, camX, camY, camZ)
    PointCamAtEntity(previewCam, ped, 0.0, 0.0, 0.3, true)
    SetCamFov(previewCam, 50.0)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, true, 500, true, false)
end

--- 再生ループ外から呼べる全停止
function StopMotionPlayback()
    playbackActive = false
    playbackPaused = false
    skipToNext = false
    local ped = PlayerPedId()
    if ped and ped ~= 0 then
        ClearPedTasks(ped)
    end
    SendNUIMessage({ type = 'stopYoutube' })
    SendNUIMessage({ type = 'playbackEnded' })
    SendNUIMessage({ type = 'hideMini' })
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
    SendNUIMessage({
        type = 'miniTick',
        current = currentIndex,
        total = totalSteps,
        name = name,
        remain = remainSec,
        loop = loopEnabled,
    })
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
        playbackActive = false
        SendNUIMessage({ type = 'stopYoutube' })
        local ped2 = PlayerPedId()
        if ped2 and ped2 ~= 0 then
            ClearPedTasks(ped2)
        end
        SendNUIMessage({ type = 'hideMini' })
    end)
end

local function openDdmUi()
    if playbackActive then
        StopMotionPlayback()
    end
    StartPreviewCamera()
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = 'openDdm',
        catalog = Config.Catalog,
        maxSlots = Config.MaxSlots,
        defaultDuration = Config.DefaultDuration,
    })
end

local function closeDdmUi()
    SetNuiFocus(false, false)
    StopPreviewCamera()
    SendNUIMessage({ type = 'uiClosed' })
end

RegisterCommand(Config.OpenCommand, function()
    openDdmUi()
end, false)

RegisterCommand(Config.StopCommand, function()
    StopMotionPlayback()
end, false)

TriggerEvent('chat:addSuggestion', ('/%s'):format(Config.OpenCommand), 'jp-DDM: 管理画面', {})
TriggerEvent('chat:addSuggestion', ('/%s'):format(Config.StopCommand), 'jp-DDM: 停止', {})

-- NUI 閉じる
RegisterNUICallback('close', function(_, cb)
    closeDdmUi()
    cb({ ok = true })
end)

RegisterNUICallback('preview', function(data, cb)
    local dict = data.dict
    local clip = data.clip
    if type(dict) ~= 'string' or type(clip) ~= 'string' or dict == '' or clip == '' then
        cb('bad')
        return
    end
    local ped = PlayerPedId()
    RequestAnimDict(dict)
    local t0 = GetGameTimer()
    while not HasAnimDictLoaded(dict) and GetGameTimer() - t0 < 5000 do
        Wait(10)
    end
    if not HasAnimDictLoaded(dict) then
        cb('noload')
        return
    end
    TaskPlayAnim(ped, dict, clip, 8.0, -8.0, 4000, 0, 0.0, false, false, false)
    if previewCam and DoesCamExist(previewCam) then
        PointCamAtEntity(previewCam, ped, 0.0, 0.0, 0.3, true)
    end
    cb('ok')
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
        cb({ setlist = {}, youtubeUrl = '', youtubeStart = 0, loop = false })
        return
    end
    local st = readStore()
    for _, p in ipairs(st.presets or {}) do
        if p.name == data.name then
            cb({
                setlist = p.setlist or {},
                youtubeUrl = p.youtubeUrl or '',
                youtubeStart = p.youtubeStart or 0,
                loop = p.loop and true or false,
            })
            return
        end
    end
    cb({ setlist = {}, youtubeUrl = '', youtubeStart = 0, loop = false })
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

RegisterNUICallback('startPlayback', function(data, cb)
    if type(data) ~= 'table' or type(data.setlist) ~= 'table' or #data.setlist < 1 then
        cb('bad')
        return
    end
    StopMotionPlayback()
    Wait(100)
    StopPreviewCamera()
    setlist = data.setlist
    totalSteps = #setlist
    loopEnabled = data.loop and true or false
    currentIndex = 1
    playbackActive = true
    playbackPaused = false
    skipToNext = false
    local yt = data.youtubeUrl
    if type(yt) == 'string' and yt ~= '' then
        SendNUIMessage({
            type = 'playYoutube',
            url = yt,
            startSeconds = tonumber(data.youtubeStart) or 0,
        })
    end
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'hideManager' })
    SendNUIMessage({ type = 'showMini' })
    local ped = PlayerPedId()
    if ped and ped ~= 0 then
        ClearPedTasks(ped)
    end
    PlaySetlist()
    cb('ok')
end)

-- NUI から 停止（管理画面内）
RegisterNUICallback('stopPlayback', function(_, cb)
    StopMotionPlayback()
    cb('ok')
end)

-- 一時停止 / 再開
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

-- ミニ表示からの制御
RegisterNUICallback('miniStop', function(_, cb)
    StopMotionPlayback()
    cb('ok')
end)
