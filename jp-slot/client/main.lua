-- NUI・インタラクト・サーバーイベント中継

local nuiOpen = false
local adminOpen = false
local currentMachineId = nil
local localeTable = {}

--- NUI フォーカス（KeepInput 無効・複数回適用で CEF でフォーカスが抜ける環境への対策）
---@param active boolean
local function setSlotNuiFocus(active)
    if not active then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        return
    end
    CreateThread(function()
        SetNuiFocusKeepInput(false)
        Wait(0)
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
        Wait(60)
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
        Wait(100)
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
    end)
end

--- locales/*.json を読み込み
---@return table
local function loadLocales()
    local name = (Config.Locale or 'ja') .. '.json'
    local raw = LoadResourceFile(GetCurrentResourceName(), 'locales/' .. name)
    if not raw then
        raw = LoadResourceFile(GetCurrentResourceName(), 'locales/ja.json')
    end
    if not raw then
        return {}
    end
    local ok, t = pcall(json.decode, raw)
    if ok and type(t) == 'table' then
        return t
    end
    return {}
end

localeTable = loadLocales()

--- リソース起動直後は NUI を操作対象にしない（ensure だけで画面が黒くなるのを防ぐ）
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end)

--- ネストキー参照（例 ui.balance）
---@param root table
---@param path string
---@return string|nil
local function localeGet(root, path)
    local cur = root
    for part in string.gmatch(path, '[^.]+') do
        if type(cur) ~= 'table' then
            return nil
        end
        cur = cur[part]
    end
    return cur
end

---@param key string
---@param fallback string|nil
---@return string
local function T(key, fallback)
    local v = localeTable[key]
    if type(v) == 'string' then
        return v
    end
    local nested = localeGet(localeTable, key)
    if type(nested) == 'string' then
        return nested
    end
    return fallback or key
end

--- NUI へ初期データを送る
---@param payload table|nil
local function pushInit(payload)
    SendNUIMessage({
        type = 'init',
        payload = payload or {},
    })
end

---@param machine table
local function openPlayUi(machine, extra)
    extra = extra or {}
    currentMachineId = machine.id
    local payId = machine.paytableId or 'normal'
    local pt = Config.PaytableDisplay and Config.PaytableDisplay[payId]
    nuiOpen = true
    adminOpen = false
    -- NUI に init を渡してからフォーカス（順序を逆にするとマウスが効かない環境がある）
    pushInit({
        machine = machine,
        theme = extra.theme,
        jackpot = extra.jackpot,
        balance = extra.balance,
        spinDuration = extra.spinDuration or Config.SpinDurationDefault,
        paytable = pt,
        marquee = extra.marquee or { hype = {}, info = {} },
        symbolIds = extra.symbolIds,
        locales = localeTable,
        localeCode = Config.Locale or 'ja',
        assetsRoot = 'nui://' .. GetCurrentResourceName() .. '/html/assets/',
        uiSize = extra.uiSize,
        character = extra.character,
        characterBasePath = extra.characterBasePath,
        characterId = extra.characterId,
        effects = extra.effects,
        debug = {
            enabled = Config.Debug and Config.Debug.enabled or false,
            nuiVerbose = Config.Debug and Config.Debug.nuiVerbose or false,
        },
    })
    setSlotNuiFocus(true)
end

RegisterNetEvent('jp-slot:seatGranted', function(data)
    data = type(data) == 'table' and data or {}
    local m = data.machine
    if not m then
        return
    end
    openPlayUi(m, {
        theme = data.theme,
        jackpot = data.jackpot,
        balance = data.balance,
        spinDuration = data.spinDuration,
        uiSize = data.uiSize,
        marquee = data.marquee,
        symbolIds = data.symbolIds,
        character = data.character,
        characterBasePath = data.characterBasePath,
        characterId = data.characterId,
        effects = data.effects,
    })
end)

RegisterNetEvent('jp-slot:seatDenied', function(_data)
    -- 通知のみ（必要なら locale）
end)

RegisterNetEvent('jp-slot:spinResult', function(data)
    SendNUIMessage({
        type = 'spinResult',
        payload = type(data) == 'table' and data or {},
    })
end)

RegisterNetEvent('jp-slot:themeUpdated', function(theme)
    SendNUIMessage({
        type = 'theme',
        payload = theme,
    })
end)

RegisterNetEvent('jp-slot:cl:adminEmbedSlotInit', function(data)
    data = type(data) == 'table' and data or {}
    print(('[jp-slot][cl] adminEmbedSlotInit received machine=%s character=%s'):format(
        tostring(data.machine and data.machine.id or 'nil'),
        tostring((data.character and data.character.id) or data.characterId or 'nil')
    ))
    local m = data.machine
    if not m then
        return
    end
    SendNUIMessage({
        type = 'init',
        payload = {
            machine = m,
            theme = data.theme,
            jackpot = data.jackpot,
            balance = data.balance or 999999999,
            spinDuration = data.spinDuration or Config.SpinDurationDefault,
            paytable = data.paytable,
            marquee = data.marquee or { hype = {}, info = {} },
            symbolIds = data.symbolIds,
            locales = localeTable,
            localeCode = Config.Locale or 'ja',
            assetsRoot = 'nui://' .. GetCurrentResourceName() .. '/html/assets/',
            uiSize = data.uiSize,
            embedPreview = true,
            neutralPreviewCharacter = data.neutralPreviewCharacter == true,
            character = data.character,
            characterBasePath = data.characterBasePath,
            characterId = data.characterId,
            characters = data.characters,
            effects = data.effects,
            debug = {
                enabled = Config.Debug and Config.Debug.enabled or false,
                nuiVerbose = Config.Debug and Config.Debug.nuiVerbose or false,
            },
        },
    })
end)

RegisterNetEvent('jp-slot:openAdmin', function(data)
    data = type(data) == 'table' and data or {}
    nuiOpen = true
    adminOpen = true
    SendNUIMessage({
        type = 'openAdmin',
        payload = {
            theme = data.theme,
            locales = localeTable,
            debug = data.debug,
            showDebugTab = data.showDebugTab,
            uiSize = data.uiSize,
            requirePassword = data.requirePassword,
            sessionTtl = data.sessionTtl,
            locales = localeTable,
        },
    })
    setSlotNuiFocus(true)
end)

RegisterNetEvent('jp-slot:applyUISize', function(size)
    SendNUIMessage({
        type = 'applyUISize',
        payload = type(size) == 'table' and size or {},
    })
end)

RegisterNetEvent('jp-slot:notify', function(data)
    SendNUIMessage({
        type = 'notify',
        payload = data,
    })
end)

RegisterNetEvent('jp-slot:forceLeave', function(data)
    data = type(data) == 'table' and data or {}
    currentMachineId = nil
    nuiOpen = false
    adminOpen = false
    setSlotNuiFocus(false)
    SendNUIMessage({ type = 'forceLeave', payload = data })
end)

RegisterNUICallback('closeAdmin', function(_, cb)
    adminOpen = false
    setSlotNuiFocus(false)
    SendNUIMessage({ type = 'adminClosed' })
    cb({})
end)

RegisterNUICallback('spin', function(body, cb)
    cb({})
    body = type(body) == 'table' and body or {}
    local bet = tonumber(body.bet) or 0
    local mid = body.machineId or currentMachineId
    TriggerServerEvent('jp-slot:spin', {
        machineId = mid,
        bet = bet,
        embedPreview = body.embedPreview == true,
    })
end)

RegisterNUICallback('exit', function(_, cb)
    print('[jp-slot] exit NUI callback received')
    SendNUIMessage({ type = 'hide' })
    TriggerServerEvent('jp-slot:leaveSeat')
    currentMachineId = nil
    nuiOpen = false
    adminOpen = false
    setSlotNuiFocus(false)
    cb({ ok = true })
end)

--- NUI 内 console / window.error をクライアントログへ（F8 で確認）
RegisterNUICallback('clientLog', function(data, cb)
    cb({})
    data = type(data) == 'table' and data or {}
    local level = tostring(data.level or '?')
    local msg = tostring(data.message or '')
    print(('[jp-slot/NUI:%s] %s'):format(level, msg))
end)

CreateThread(function()
    Wait(500)
    Machines.spawnAll()
    Wait(1000)
    TriggerServerEvent('jp-slot:dyn:requestSync')
end)

--- メインループ: 近くで [E]
CreateThread(function()
    local helpLock = false
    while true do
        local waitMs = 750
        local ped = PlayerPedId()
        local near, dist = Machines.findNearest(Config.InteractDistance or 5.0)
        if near and not nuiOpen then
            waitMs = 0
            local label = T('ui.press_e_to_play', '[E]')
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName(label)
            EndTextCommandDisplayHelp(0, false, true, -1)
            if IsControlJustReleased(0, 38) then
                local now = GetGameTimer()
                if not helpLock or (now - helpLock) > (Config.SeatRequestCooldownMs or 800) then
                    helpLock = now
                    TriggerServerEvent('jp-slot:requestSeat', near.id)
                end
            end
        end
        Wait(waitMs)
    end
end)
