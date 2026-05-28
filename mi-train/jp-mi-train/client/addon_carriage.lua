-- jp-mi-train Phase 2: DBuz747 等 add-on 客車をミッション列車に attach
-- CreateMissionTrain は add-on を直接使えないため、最後尾貨車に CreateVehicle + AttachEntityToEntity

---@class AddonCarriageModule
local M = {}

---@type integer|nil
M.entity = nil

---@type integer|nil attach 親（通常は最後尾 freight 車両）
M.parent = nil

---@param msg string
local function log(msg)
    if Config.Debug then
        print(('[%s/addon] %s'):format(GetCurrentResourceName(), msg))
    end
end

---@return boolean
local function IsEnabled()
    return Config.AddonCarriage and Config.AddonCarriage.enabled == true
end

---@param modelName string
---@return boolean
local function LoadAddonModel(modelName)
    local hash = joaat(modelName)
    local timeout = Config.AddonCarriage.modelLoadTimeoutMs or 15000

    -- add-on は IsModelInCdimage が常に false になるため RequestModel + HasModelLoaded のみ使う
    RequestModel(hash)
    local deadline = GetGameTimer() + timeout
    while not HasModelLoaded(hash) and GetGameTimer() < deadline do
        RequestModel(hash)
        Wait(0)
    end

    if not HasModelLoaded(hash) then
        local resHint = ''
        local req = Config.AddonCarriage and Config.AddonCarriage.requiredResource
        if req and req ~= '' then
            resHint = (' (resource %s state=%s)'):format(req, GetResourceState(req))
        end
        log(('model load failed: %s — ensure DBuz747 started, stream/meta OK%s'):format(
            modelName, resHint))
        return false
    end

    return true
end

---@param entity integer
local function ConfigureAddonEntity(entity)
    local cfg = Config.AddonCarriage
    SetEntityAsMissionEntity(entity, true, true)
    SetEntityInvincible(entity, cfg.invincible ~= false)

    if cfg.disableCollision then
        SetEntityCollision(entity, false, false)
    end

    -- DBuz747 は地面衝突でクラッシュしやすいため freeze + エンジン off
    SetVehicleEngineOn(entity, false, true, true)
    FreezeEntityPosition(entity, true)
    SetEntityCanBeDamaged(entity, false)
end

---@param parentEntity integer
---@return boolean
local function AttachToParent(parentEntity)
    if not M.entity or not DoesEntityExist(M.entity) then
        return false
    end
    if not parentEntity or not DoesEntityExist(parentEntity) then
        return false
    end

    local cfg = Config.AddonCarriage
    local off = cfg.attachOffset or vec3(0.0, -12.0, 0.35)
    local rot = cfg.attachRotation or vec3(0.0, 0.0, 0.0)

    if not NetworkHasControlOfEntity(M.entity) then
        NetworkRequestControlOfEntity(M.entity)
        local t = GetGameTimer() + 1500
        while not NetworkHasControlOfEntity(M.entity) and GetGameTimer() < t do
            Wait(50)
        end
    end

    DetachEntity(M.entity, true, true)
    AttachEntityToEntity(
        M.entity, parentEntity, cfg.boneIndex or 0,
        off.x, off.y, off.z,
        rot.x, rot.y, rot.z,
        false, false, cfg.useSoftPinning == true, false, 2, true
    )
    -- 貨車本体コリジョンと客車が干渉しないよう分離（見た目の高さは attachOffset.z）
    SetEntityNoCollisionEntity(M.entity, parentEntity, true)
    FreezeEntityPosition(M.entity, true)
    M.parent = parentEntity
    return true
end

---@param parentEntity integer ミッション列車の attach 基準（最後尾 wagon）
---@return boolean success
function M.SpawnAndAttach(parentEntity)
    if not IsEnabled() then
        return false
    end

    if not parentEntity or parentEntity == 0 or not DoesEntityExist(parentEntity) then
        log('SpawnAndAttach aborted: invalid parent')
        return false
    end

    local cfg = Config.AddonCarriage
    local modelName = cfg.model or 'dbuz747'

    if cfg.requiredResource and cfg.requiredResource ~= '' then
        local state = GetResourceState(cfg.requiredResource)
        if state ~= 'started' and state ~= 'starting' then
            log(('required resource not started: %s (state=%s)'):format(cfg.requiredResource, state))
            if cfg.failIfMissingModel then
                return false
            end
        end
    end

    if not LoadAddonModel(modelName) then
        if cfg.failIfMissingModel then
            lib.notify({
                type = 'error',
                title = 'MI Train',
                description = ('add-on 客車モデル %s が見つかりません。dlcpacks を確認してください。'):format(modelName),
                duration = 10000,
            })
        else
            log('addon skipped (model missing, failIfMissingModel=false)')
        end
        return false
    end

    local hash = joaat(modelName)
    local parentCoords = GetEntityCoords(parentEntity)
    local heading = GetEntityHeading(parentEntity)

    local veh = CreateVehicle(hash, parentCoords.x, parentCoords.y, parentCoords.z, heading, false, false)
    if not veh or veh == 0 or not DoesEntityExist(veh) then
        log('CreateVehicle failed for addon carriage')
        SetModelAsNoLongerNeeded(hash)
        return false
    end

    ConfigureAddonEntity(veh)
    M.entity = veh
    M.parent = parentEntity

    if not AttachToParent(parentEntity) then
        M.Cleanup()
        SetModelAsNoLongerNeeded(hash)
        return false
    end

    SetModelAsNoLongerNeeded(hash)
    log(('addon carriage attached: model=%s entity=%d parent=%d'):format(modelName, veh, parentEntity))

    if cfg.notifyOnAttach then
        lib.notify({
            type = 'inform',
            title = 'MI Train',
            description = 'DBuz747 客車を編成末尾に接続した。',
            duration = 6000,
        })
    end

    return true
end

--- attach 切れを定期修復（ホスト maintenance から呼ぶ）
function M.MaintainAttach()
    if not IsEnabled() or not M.entity then
        return
    end

    if not DoesEntityExist(M.entity) then
        return
    end

    if M.parent and DoesEntityExist(M.parent) then
        if not IsEntityAttachedToEntity(M.entity, M.parent) then
            log('reattaching addon carriage')
            AttachToParent(M.parent)
        end
    end
end

---@return integer|nil
function M.GetEntity()
    if M.entity and DoesEntityExist(M.entity) then
        return M.entity
    end
    return nil
end

---@return boolean
function M.IsActive()
    return M.GetEntity() ~= nil
end

--- 車内歩行時のみ客車メッシュの当たり判定を有効化（attach 時は false のまま）
---@param enable boolean
function M.SetInteriorCollision(enable)
    if not M.entity or not DoesEntityExist(M.entity) then
        return
    end
    if enable then
        SetEntityCollision(M.entity, true, true)
        SetEntityRecordsCollisions(M.entity, true)
    elseif Config.AddonCarriage and Config.AddonCarriage.disableCollision then
        SetEntityCollision(M.entity, false, false)
    end
end

function M.Cleanup()
    if M.entity and DoesEntityExist(M.entity) then
        if IsEntityAttached(M.entity) then
            DetachEntity(M.entity, true, true)
        end
        if not NetworkHasControlOfEntity(M.entity) then
            NetworkRequestControlOfEntity(M.entity)
            local t = GetGameTimer() + 1000
            while not NetworkHasControlOfEntity(M.entity) and GetGameTimer() < t do
                Wait(50)
            end
        end
        DeleteEntity(M.entity)
    end
    M.entity = nil
    M.parent = nil
    log('addon carriage cleaned up')
end

_G.MiTrainAddon = M

exports('GetAddonCarriage', function()
    return M.GetEntity()
end)

exports('IsAddonCarriageActive', function()
    return M.IsActive()
end)
