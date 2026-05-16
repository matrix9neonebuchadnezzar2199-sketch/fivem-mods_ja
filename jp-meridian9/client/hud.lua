-- ============================================================
-- jp-meridian9 / client/hud.lua
-- ============================================================
-- 任務中 NUI: 旧 `#app` グリッド（ウェーブ帯）＋ Phase-C HUD（`#mrd9-hud-root`）。
-- Phase-C はフォーカスを取らない。自分 HP はクライアントのみで NUI へ `hud:selfHp`。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.HUD = MRD9.HUD or {}

MRD9.HUDClient = MRD9.HUDClient or {
    visible = false,
}

local resName = GetCurrentResourceName()

local State = {
    phaseCVisible = false,
    hpMonitorActive = false,
    lastSelfHp = -1,
}

local ammoHudSuppressRunning = false

local function hudCfg()
    return Config.HUD or {}
end

local function stopAmmoHudSuppress()
    ammoHudSuppressRunning = false
end

---@return nil
local function startAmmoHudSuppress()
    if hudCfg().hideAmmoHud == false then
        return
    end
    if ammoHudSuppressRunning then
        return
    end
    ammoHudSuppressRunning = true
    CreateThread(function()
        while ammoHudSuppressRunning do
            DisplayAmmoThisFrame(false)
            Wait(0)
        end
    end)
end

local function buildLocalePayload()
    return {
        locale = Config.Locale or 'ja',
        uiScale = tonumber((Config.HUD or {}).uiScale) or 2.0,
        strings = {
            hud_timer_remaining = _('hud_timer_remaining'),
            hud_party_label = _('hud_party_label'),
            hud_inv_label = _('hud_inv_label'),
            hud_inv_total = _('hud_inv_total'),
            hud_inv_common = _('hud_inv_common'),
            hud_inv_uncommon = _('hud_inv_uncommon'),
            hud_inv_rare = _('hud_inv_rare'),
            hud_inv_legendary = _('hud_inv_legendary'),
            hud_wave_banner = _('hud_wave_banner'),
            hud_leader_badge = _('hud_leader_badge'),
            hud_self_badge = _('hud_self_badge'),
            hud_event_wave_start = _('hud_event_wave_start'),
            hud_event_wave_cleared = _('hud_event_wave_cleared'),
            hud_event_mission_success = _('hud_event_mission_success'),
            hud_event_mission_failed = _('hud_event_mission_failed'),
            hud_event_extract_success = _('hud_event_extract_success'),
            hud_event_countdown = _('hud_event_countdown'),
        },
    }
end

---@param payload table|nil
local function localizeHudLootRows(payload)
    if type(payload) ~= 'table' or type(payload.loot) ~= 'table' then
        return
    end
    for _idx, row in ipairs(payload.loot) do
        if type(row) == 'table' and type(row.nameKey) == 'string' and row.nameKey ~= '' then
            row.label = _(row.nameKey)
        end
    end
end

local function sendSelfHp(force)
    if not State.phaseCVisible then
        return
    end
    local ped = PlayerPedId()
    if not ped or ped == 0 then
        return
    end
    local rawHp = GetEntityHealth(ped)
    local rawMax = GetEntityMaxHealth(ped)
    local hp = math.max(0, rawHp - 100)
    local maxHp = math.max(1, rawMax - 100)
    local minDelta = tonumber(hudCfg().selfHpMinDelta) or 1
    if not force and math.abs(hp - State.lastSelfHp) < minDelta then
        return
    end
    State.lastSelfHp = hp
    SendNUIMessage({
        type = 'hud:selfHp',
        payload = { hp = hp, maxHp = maxHp },
    })
end

local function stopHpMonitor()
    State.hpMonitorActive = false
end

local function startHpMonitor()
    if State.hpMonitorActive then
        return
    end
    State.hpMonitorActive = true
    CreateThread(function()
        local poll = tonumber(hudCfg().selfHpPollMs) or 250
        while State.hpMonitorActive and State.phaseCVisible do
            sendSelfHp(false)
            Wait(poll)
        end
        State.hpMonitorActive = false
    end)
end

---@param data table|nil
function MRD9.HUD.OnMissionStart(data)
    if hudCfg().enabled == false then
        return
    end
    stopAmmoHudSuppress()
    MRD9.HUDClient.visible = true
    State.phaseCVisible = true
    State.lastSelfHp = -1
    SendNUIMessage({ type = 'm9_hud_locale', payload = buildLocalePayload() })
    SendNUIMessage({ type = 'm9_hud_show', payload = {} })
    SendNUIMessage({ type = 'hud:show', payload = {} })
    sendSelfHp(true)
    startHpMonitor()
    startAmmoHudSuppress()
end

---@param data table|nil
function MRD9.HUD.OnMissionEnd(data)
    stopAmmoHudSuppress()
    stopHpMonitor()
    MRD9.HUDClient.visible = false
    State.phaseCVisible = false
    State.lastSelfHp = -1
    if type(data) == 'table' and data.reason == 'extracted' then
        local ms = tonumber(hudCfg().waveEventMs) or 4500
        SendNUIMessage({
            type = 'm9_hud_event',
            payload = { kind = 'extract_success', ms = ms, label = '' },
        })
    end
    SendNUIMessage({ type = 'hud:hide', payload = {} })
    SendNUIMessage({ type = 'm9_hud_hide', payload = {} })
end

---@param kind string
---@param opts table|nil
function MRD9.HUD.PushEvent(kind, opts)
    if hudCfg().enabled == false or not MRD9.HUDClient.visible then
        return
    end
    opts = opts or {}
    local ms = tonumber(opts.ms) or tonumber(hudCfg().waveEventMs) or 4500
    SendNUIMessage({
        type = 'm9_hud_event',
        payload = {
            kind = kind,
            label = opts.label,
            ms = ms,
            wave = opts.wave,
            total = opts.total,
            alive = opts.alive,
            seconds = opts.seconds,
        },
    })
end

RegisterNetEvent('jp-meridian9:client:hud:state', function(payload)
    if hudCfg().enabled == false or not State.phaseCVisible then
        return
    end
    if type(payload) ~= 'table' then
        return
    end
    localizeHudLootRows(payload)
    SendNUIMessage({ type = 'hud:state', payload = payload })
end)

RegisterNetEvent('jp-meridian9:client:hud:pickup', function(payload)
    if hudCfg().enabled == false then
        return
    end
    if type(payload) ~= 'table' then
        return
    end
    if type(payload.nameKey) == 'string' and payload.nameKey ~= '' then
        payload.label = _(payload.nameKey)
    end
    SendNUIMessage({ type = 'hud:pickup', payload = payload })
end)

RegisterNetEvent('jp-meridian9:client:hud:partyLeave', function(payload)
    if hudCfg().enabled == false or not State.phaseCVisible then
        return
    end
    if type(payload) ~= 'table' then
        return
    end
    SendNUIMessage({ type = 'hud:partyLeave', payload = payload })
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= resName then
        return
    end
    stopAmmoHudSuppress()
    stopHpMonitor()
    MRD9.HUDClient.visible = false
    State.phaseCVisible = false
    SendNUIMessage({ type = 'hud:hide', payload = {} })
    SendNUIMessage({ type = 'm9_hud_hide', payload = {} })
    SetNuiFocus(false, false)
end)
