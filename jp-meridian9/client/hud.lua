-- ============================================================
-- jp-meridian9 / client/hud.lua
-- ============================================================
-- 任務中 NUI HUD（INSTRUCTION-014）。フォーカスは取らない。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.HUD = MRD9.HUD or {}

---@class Mrd9HudClientMember
---@field src integer
---@field name string
---@field hp integer
---@field maxHp integer
---@field armor integer
---@field alive boolean
---@field isLeader boolean
---@field isSelf boolean

MRD9.HUDClient = MRD9.HUDClient or {
    visible = false,
    session = { sessionId = '', timerSec = 0, endsAtMs = 0 },
    self = { src = 0, hp = 0, maxHp = 200, armor = 0 },
    members = {},
    inventory = { total = 0, byRarity = { common = 0, uncommon = 0, rare = 0, legendary = 0 } },
    arena = { active = false, wave = 0, totalWaves = 0, zombiesAlive = 0 },
    extract = { active = false, label = '' },
}

local resName = GetCurrentResourceName()

local State = {
    lastDto = nil,
    endsAtMs = 0,
    tickRunning = false,
    lastSentTimer = -1,
    lastSentHp = -1,
    lastSentArmor = -1,
}

local function hudCfg()
    return Config.HUD or {}
end

local function buildHudConfigPayload()
    local c = hudCfg()
    return {
        showPartyHP = c.showPartyHP ~= false,
        showTimer = c.showTimer ~= false,
        showInventory = c.showInventory ~= false,
        showWaveBanner = c.showWaveBanner ~= false,
        inventoryMode = c.inventoryMode or 'byRarity',
    }
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

---@param dto table
---@return table
local function mergeLocalPedIntoDto(dto)
    local ped = PlayerPedId()
    local hp, maxHp, armor, alive = 0, 200, 0, false
    if ped and ped ~= 0 then
        hp = GetEntityHealth(ped)
        maxHp = math.max(1, GetEntityMaxHealth(ped))
        armor = GetPedArmour(ped)
        alive = not IsPedDeadOrDying(ped, true)
    end
    local timerSec = math.max(0, math.floor((State.endsAtMs - GetGameTimer()) / 1000))

    local members = {}
    for _, row in ipairs(dto.members or {}) do
        local copy = {
            src = row.src,
            name = row.name,
            hp = row.hp,
            maxHp = row.maxHp,
            armor = row.armor,
            alive = row.alive,
            isLeader = row.isLeader == true,
            isSelf = row.isSelf == true,
        }
        if copy.isSelf then
            copy.hp, copy.maxHp, copy.armor, copy.alive = hp, maxHp, armor, alive
        end
        members[#members + 1] = copy
    end

    return {
        sessionId = dto.sessionId,
        timerSec = timerSec,
        self = { hp = hp, maxHp = maxHp, armor = armor },
        members = members,
        inventory = dto.inventory or { total = 0, byRarity = {} },
        arena = dto.arena
            or { active = false, wave = 0, totalWaves = 0, zombiesAlive = 0 },
        hudConfig = buildHudConfigPayload(),
    }
end

local function syncHudClientFromDto(merged)
    local c = MRD9.HUDClient
    c.session.sessionId = merged.sessionId or ''
    c.session.timerSec = merged.timerSec or 0
    c.session.endsAtMs = State.endsAtMs
    c.self.hp = merged.self.hp or 0
    c.self.maxHp = merged.self.maxHp or 200
    c.self.armor = merged.self.armor or 0
    c.members = merged.members or {}
    c.inventory = merged.inventory or c.inventory
    c.arena = merged.arena or c.arena
end

local function stopClientTick()
    State.tickRunning = false
end

local function startClientTick()
    if State.tickRunning then
        return
    end
    State.tickRunning = true
    CreateThread(function()
        while State.tickRunning and MRD9.CurrentSession and hudCfg().enabled ~= false do
            local ms = tonumber(hudCfg().tickClientMs) or 250
            Wait(ms)
            if not MRD9.CurrentSession or not State.tickRunning then
                break
            end
            local dto = State.lastDto
            if not dto then
                goto continue
            end
            local merged = mergeLocalPedIntoDto(dto)
            local timerSec = merged.timerSec
            local hp = merged.self.hp
            local armor = merged.self.armor
            if timerSec ~= State.lastSentTimer or hp ~= State.lastSentHp or armor ~= State.lastSentArmor then
                State.lastSentTimer = timerSec
                State.lastSentHp = hp
                State.lastSentArmor = armor
                syncHudClientFromDto(merged)
                SendNUIMessage({ type = 'm9_hud_state', payload = merged })
            end
            ::continue::
        end
        State.tickRunning = false
    end)
end

---@param data table|nil
function MRD9.HUD.OnMissionStart(data)
    if hudCfg().enabled == false then
        return
    end
    MRD9.HUDClient.visible = true
    State.lastDto = nil
    State.endsAtMs = 0
    State.lastSentTimer = -1
    State.lastSentHp = -1
    State.lastSentArmor = -1
    SendNUIMessage({ type = 'm9_hud_locale', payload = buildLocalePayload() })
    SendNUIMessage({ type = 'm9_hud_show', payload = {} })
    startClientTick()
end

---@param data table|nil
function MRD9.HUD.OnMissionEnd(data)
    stopClientTick()
    MRD9.HUDClient.visible = false
    State.lastDto = nil
    if type(data) == 'table' and data.reason == 'extracted' then
        local ms = tonumber(hudCfg().waveEventMs) or 4500
        SendNUIMessage({
            type = 'm9_hud_event',
            payload = { kind = 'extract_success', ms = ms, label = '' },
        })
    end
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

RegisterNetEvent('jp-meridian9:client:hud:state', function(dto)
    if hudCfg().enabled == false then
        return
    end
    if type(dto) ~= 'table' then
        return
    end
    if not MRD9.CurrentSession then
        return
    end
    State.lastDto = dto
    State.endsAtMs = GetGameTimer() + (tonumber(dto.timerSec) or 0) * 1000

    local merged = mergeLocalPedIntoDto(dto)
    State.lastSentTimer = merged.timerSec
    State.lastSentHp = merged.self.hp
    State.lastSentArmor = merged.self.armor
    syncHudClientFromDto(merged)
    SendNUIMessage({ type = 'm9_hud_state', payload = merged })
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= resName then
        return
    end
    stopClientTick()
    MRD9.HUDClient.visible = false
    State.lastDto = nil
    SendNUIMessage({ type = 'm9_hud_hide', payload = {} })
    SetNuiFocus(false, false)
end)
