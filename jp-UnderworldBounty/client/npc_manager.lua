local Managed = {}
local HeistGroup = nil
local HeistCombatActive = false
-- 'heist' | 'contract' — 全滅時に送るサーバーイベントを切り替える
local NpcCombatSession = 'heist'
-- UbNpcCleanup 呼び出しで無効化され、遅延削除スレッドを打ち切る
local npcCleanupEpoch = 0

local function ensure_heist_group()
  if HeistGroup then
    return HeistGroup
  end
  AddRelationshipGroup('JP_UB_HEIST')
  HeistGroup = GetHashKey('JP_UB_HEIST')
  local pg = joaat('PLAYER')
  SetRelationshipBetweenGroups(5, HeistGroup, pg)
  SetRelationshipBetweenGroups(5, pg, HeistGroup)
  return HeistGroup
end

local function apply_behavior(ped, behavior)
  local player = PlayerPedId()
  behavior = behavior or 'aggressive'
  if behavior == 'passive' then
    TaskWanderStandard(ped, 10.0, 10)
    CreateThread(function()
      while HeistCombatActive and DoesEntityExist(ped) and not IsEntityDead(ped) do
        Wait(400)
        if #(GetEntityCoords(ped) - GetEntityCoords(player)) < 18.0 then
          TaskCombatPed(ped, player, 0, 16)
          break
        end
      end
    end)
    return
  end
  if behavior == 'alert' then
    SetBlockingOfNonTemporaryEvents(ped, false)
  end
  TaskCombatPed(ped, player, 0, 16)
end

--- @param scenario_id string
--- @param spawn_opts table|nil { session='heist'|'contract', anchor=vector3, anchor_heading=number }
function UbNpcBeginScenario(scenario_id, spawn_opts)
  spawn_opts = spawn_opts or {}
  UbNpcCleanup(false)
  local sc = UbClientFindScenario(scenario_id)
  if not sc then
    return
  end
  NpcCombatSession = spawn_opts.session or 'heist'
  local anchor = spawn_opts.anchor
  local anchorHeading = spawn_opts.anchor_heading or 0.0
  local grp = ensure_heist_group()
  HeistCombatActive = true
  for _, row in ipairs(sc.enemies or {}) do
    local model = row.model
    RequestModel(model)
    local deadline = GetGameTimer() + 10000
    while not HasModelLoaded(model) do
      Wait(50)
      if GetGameTimer() > deadline then
        break
      end
    end
    if HasModelLoaded(model) then
      local c = row.coords
      local wx, wy, wz, wh
      if sc.enemies_relative and anchor then
        wx = anchor.x + c.x
        wy = anchor.y + c.y
        wz = anchor.z + c.z
        wh = anchorHeading + (c.w or 0.0)
      else
        wx, wy, wz, wh = c.x, c.y, c.z, c.w or 0.0
      end
      local ped = CreatePed(4, model, wx, wy, wz, wh, false, true)
      SetEntityAsMissionEntity(ped, true, true)
      SetPedRelationshipGroupHash(ped, grp)
      SetPedArmour(ped, (row.behavior == 'boss') and 100 or 40)
      SetEntityMaxHealth(ped, (row.behavior == 'boss') and 350 or 200)
      SetEntityHealth(ped, (row.behavior == 'boss') and 350 or 200)
      GiveWeaponToPed(ped, row.weapon or joaat('WEAPON_PISTOL'), 220, false, true)
      SetPedCombatAbility(ped, 2)
      SetPedCombatMovement(ped, 2)
      SetPedAccuracy(ped, (row.behavior == 'boss') and 45 or 25)
      apply_behavior(ped, row.behavior)
      Managed[#Managed + 1] = ped
      SetModelAsNoLongerNeeded(model)
    end
  end
  if #Managed == 0 then
    HeistCombatActive = false
    if NpcCombatSession == 'contract' then
      TriggerServerEvent(UbEvent('server:contractNpcSpawnFailed'))
    else
      TriggerServerEvent(UbEvent('server:npcSpawnFailed'))
    end
    return
  end
  CreateThread(function()
    while HeistCombatActive do
      Wait(500)
      local alive = 0
      for _, p in ipairs(Managed) do
        if DoesEntityExist(p) and not IsEntityDead(p) then
          alive = alive + 1
        end
      end
      if alive == 0 and #Managed > 0 then
        HeistCombatActive = false
        if NpcCombatSession == 'contract' then
          TriggerServerEvent(UbEvent('server:contractCombatComplete'))
        else
          TriggerServerEvent(UbEvent('server:completeCombat'))
        end
        break
      end
    end
  end)
end

--- @param silent boolean|nil NPC を削除しない（リソース停止時など）
function UbNpcCleanup(silent)
  npcCleanupEpoch = npcCleanupEpoch + 1
  HeistCombatActive = false
  for _, p in ipairs(Managed) do
    if DoesEntityExist(p) then
      DeleteEntity(p)
    end
  end
  Managed = {}
end

--- 強盗終了後に NPC を遅延削除（新規強盗開始等で UbNpcCleanup が走れば打ち切り）
--- @param delayMs number
--- @param silent boolean|nil
function UbNpcCleanupAfter(delayMs, silent)
  local epoch = npcCleanupEpoch
  CreateThread(function()
    Wait(math.max(0, math.floor(delayMs or 0)))
    if epoch ~= npcCleanupEpoch then
      return
    end
    UbNpcCleanup(silent)
  end)
end
