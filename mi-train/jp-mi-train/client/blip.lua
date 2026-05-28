-- jp-mi-train クライアント側: 列車位置 Blip
-- 責務:
--   1. ヘイスト中、全プレイヤーの MAP に列車（機関車・最後尾車両）の Blip を表示
--   2. ホストから broadcast される座標で Blip 位置を更新
--   3. ヘイスト終了時に Blip を削除
-- 注意:
--   - AddBlipForEntity はローカルエンティティにしか貼れない（ストリーミング範囲外のプレイヤーには見えない）
--   - そのため座標ベース Blip + 定期更新の方式を採用

---@class BlipModule
local M = {}

---@type integer|nil 機関車 Blip
M.trainBlip = nil

---@type integer|nil 最後尾 Blip
M.lastWagonBlip = nil

---@type integer|nil ホスト専用: 機関車エンティティ Blip（自動追従）
M.hostTrainEntityBlip = nil

---@type integer|nil ホスト専用: 最後尾エンティティ Blip
M.hostLastEntityBlip = nil

---@type vector3|nil 全クライアント共有の最新座標（heli_board 用）
M.cachedTrainCoords = nil

---@type vector3|nil
M.cachedLastWagonCoords = nil

---@type boolean ホストから実座標を受信済み（true のときだけ侵入マーカー有効）
M.coordsLive = false

---@type integer GetGameTimer() で最後に Update した時刻
M.coordsUpdatedAt = 0

---@param msg string
local function log(msg)
    if Config.Debug then
        print(('[%s/blip] %s'):format(GetCurrentResourceName(), msg))
    end
end

---@param b integer|nil
---@return nil
local function RemoveBlipSafe(b)
    if b and DoesBlipExist(b) then
        RemoveBlip(b)
    end
    return nil
end

local function ClearHostEntityBlips()
    M.hostTrainEntityBlip = RemoveBlipSafe(M.hostTrainEntityBlip)
    M.hostLastEntityBlip = RemoveBlipSafe(M.hostLastEntityBlip)
end

-- ============================================================
-- Blip ヘルパー
-- ============================================================

---@param data vector3|table|nil
---@return vector3|nil
local function NormalizeCoords(data)
    if not data then return nil end
    if type(data) == 'vector3' then
        return data
    end
    if type(data) == 'table' then
        local x = data.x or data[1]
        local y = data.y or data[2]
        local z = data.z or data[3]
        if x and y and z then
            return vector3(x + 0.0, y + 0.0, z + 0.0)
        end
    end
    return nil
end

---@param blip integer
---@param cfg table
local function ApplyBlipStyle(blip, cfg)
    SetBlipSprite(blip, cfg.sprite)
    SetBlipColour(blip, cfg.color)
    SetBlipScale(blip, cfg.scale)
    SetBlipAsShortRange(blip, cfg.shortRange)
    SetBlipDisplay(blip, 2)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(cfg.label)
    EndTextCommandSetBlipName(blip)

    if cfg.priority then
        SetBlipPriority(blip, cfg.priority)
    end
    if cfg.flash then
        SetBlipFlashes(blip, true)
        SetBlipFlashInterval(blip, 400)
    end
end

--- GPS ルート付き Blip は SetBlipCoords だけでは動かないことがあるため、一度ルートを外す
---@param blip integer
---@param coords vector3
---@param cfg table
local function MoveCoordBlip(blip, coords, cfg)
    if cfg.showRoute then
        SetBlipRoute(blip, false)
    end
    SetBlipCoords(blip, coords.x, coords.y, coords.z)
    if cfg.showRoute then
        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, cfg.color or 3)
    end
end

---@param coords vector3
---@param cfg table Config.Blip.train または Config.Blip.lastWagon
---@return integer blip
local function CreateCoordBlip(coords, cfg)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    ApplyBlipStyle(blip, cfg)
    if cfg.showRoute then
        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, cfg.color or 3)
    end
    return blip
end

---@param entity integer
---@param cfg table
---@return integer blip
local function CreateEntityBlip(entity, cfg)
    local blip = AddBlipForEntity(entity)
    ApplyBlipStyle(blip, cfg)
    if cfg.showRoute then
        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, cfg.color or 3)
    end
    return blip
end

-- ============================================================
-- 座標更新（サーバーから受信）
-- ============================================================

---@param trainCoords vector3|table|nil
---@param lastWagonCoords vector3|table|nil
function M.Update(trainCoords, lastWagonCoords)
    trainCoords = NormalizeCoords(trainCoords)
    if not trainCoords then
        log('Update skipped: invalid train coords')
        return
    end
    lastWagonCoords = NormalizeCoords(lastWagonCoords)

    M.coordsLive = true
    M.coordsUpdatedAt = GetGameTimer()
    M.cachedTrainCoords = trainCoords
    M.cachedLastWagonCoords = lastWagonCoords or trainCoords

    ClearHostEntityBlips()

    -- 機関車 Blip（座標ベース・非ホスト / リレー用）
    if not M.trainBlip or not DoesBlipExist(M.trainBlip) then
        M.trainBlip = CreateCoordBlip(trainCoords, Config.Blip.train)
        log(('train blip created at (%.1f, %.1f, %.1f)')
            :format(trainCoords.x, trainCoords.y, trainCoords.z))
    else
        MoveCoordBlip(M.trainBlip, trainCoords, Config.Blip.train)
    end

    -- 最後尾 Blip
    if lastWagonCoords then
        if not M.lastWagonBlip or not DoesBlipExist(M.lastWagonBlip) then
            M.lastWagonBlip = CreateCoordBlip(lastWagonCoords, Config.Blip.lastWagon)
            log(('lastWagon blip created at (%.1f, %.1f, %.1f)')
                :format(lastWagonCoords.x, lastWagonCoords.y, lastWagonCoords.z))
        else
            MoveCoordBlip(M.lastWagonBlip, lastWagonCoords, Config.Blip.lastWagon)
        end
    end
end

--- ホスト: エンティティ Blip で MAP を自動追従（SetBlipCoords 不具合を回避）
---@param trainEntity integer|nil
---@param lastEntity integer|nil
function M.UpdateHostEntities(trainEntity, lastEntity)
    M.coordsLive = true
    M.coordsUpdatedAt = GetGameTimer()

    -- 座標 Blip はホストでは使わない（サーバー relay で上書きされるのを防ぐ）
    M.trainBlip = RemoveBlipSafe(M.trainBlip)
    M.lastWagonBlip = RemoveBlipSafe(M.lastWagonBlip)

    if trainEntity and trainEntity ~= 0 and DoesEntityExist(trainEntity) then
        M.cachedTrainCoords = GetEntityCoords(trainEntity)
        if not M.hostTrainEntityBlip or not DoesBlipExist(M.hostTrainEntityBlip) then
            M.hostTrainEntityBlip = CreateEntityBlip(trainEntity, Config.Blip.train)
            log(('host train entity blip on entity=%d'):format(trainEntity))
        end
    end

    if lastEntity and lastEntity ~= 0 and DoesEntityExist(lastEntity) then
        M.cachedLastWagonCoords = GetEntityCoords(lastEntity)
        if not M.hostLastEntityBlip or not DoesBlipExist(M.hostLastEntityBlip) then
            M.hostLastEntityBlip = CreateEntityBlip(lastEntity, Config.Blip.lastWagon)
            log(('host lastWagon entity blip on entity=%d'):format(lastEntity))
        end
    elseif M.cachedTrainCoords then
        M.cachedLastWagonCoords = M.cachedTrainCoords
    end
end

-- ============================================================
-- クリーンアップ
-- ============================================================

function M.Cleanup()
    ClearHostEntityBlips()
    M.trainBlip = RemoveBlipSafe(M.trainBlip)
    M.lastWagonBlip = RemoveBlipSafe(M.lastWagonBlip)
    M.cachedTrainCoords = nil
    M.cachedLastWagonCoords = nil
    M.coordsLive = false
    M.coordsUpdatedAt = 0
    log('blips removed')
end

---@return integer 最後の座標更新からの経過 ms（未更新なら大きな値）
function M.GetCoordsAgeMs()
    if M.coordsUpdatedAt == 0 then
        return 999999
    end
    return GetGameTimer() - M.coordsUpdatedAt
end

--- スポーン地点の仮 Blip のみ（侵入マーカー・E 判定には使わない）
---@param tx number
---@param ty number
---@param tz number
function M.SetBootstrap(tx, ty, tz)
    M.coordsLive = false
    M.cachedTrainCoords = nil
    M.cachedLastWagonCoords = nil
    ClearHostEntityBlips()
    M.lastWagonBlip = RemoveBlipSafe(M.lastWagonBlip)

    local spawn = vector3(tx + 0.0, ty + 0.0, tz + 0.0)
    local cfg = Config.Blip.bootstrap or Config.Blip.train
    if not M.trainBlip or not DoesBlipExist(M.trainBlip) then
        M.trainBlip = CreateCoordBlip(spawn, cfg)
    else
        SetBlipCoords(M.trainBlip, spawn.x, spawn.y, spawn.z)
    end
    log(('bootstrap blip only (%.1f, %.1f, %.1f) — boarding locked until train live')
        :format(tx, ty, tz))
end

---@return boolean 黄色サークル / E 侵入を許可するか
function M.IsBoardingActive()
    return M.coordsLive and M.GetBoardingCoords() ~= nil
end

---@return vector3|nil 侵入判定に使う最後尾付近の座標（coordsLive 時のみ）
function M.GetBoardingCoords()
    if not M.coordsLive then
        return nil
    end
    return M.cachedLastWagonCoords or M.cachedTrainCoords
end

---@return boolean
function M.HasBoardingCoords()
    return M.IsBoardingActive()
end

-- ============================================================
-- net イベント
-- ============================================================

-- サーバーから broadcast される座標更新（vector3 は送らず数値のみ）
RegisterNetEvent('jp-mi-train:trainCoordsUpdate', function(tx, ty, tz, hasLast, lx, ly, lz)
    -- ホストは UpdateHostEntities で既に反映済み。relay で座標 Blip に戻るのを防ぐ
    if exports[GetCurrentResourceName()]:IsHost() then
        return
    end

    local trainCoords = vector3(tx + 0.0, ty + 0.0, tz + 0.0)
    local lastWagonCoords = nil
    if hasLast then
        lastWagonCoords = vector3(lx + 0.0, ly + 0.0, lz + 0.0)
    end
    M.Update(trainCoords, lastWagonCoords)
end)

-- ヘイスト開始直後: スポーン地点に仮 Blip（列車生成完了までの目安）
RegisterNetEvent('jp-mi-train:heistBlipBootstrap', function(tx, ty, tz)
    M.SetBootstrap(tx, ty, tz)
end)

_G.MiTrainBlip = M

exports('GetBoardingCoords', function()
    return M.GetBoardingCoords()
end)
