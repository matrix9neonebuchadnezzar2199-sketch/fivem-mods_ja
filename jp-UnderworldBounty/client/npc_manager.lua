local Managed = {}
local HeistGroup = nil
local HeistCombatActive = false

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

function UbNpcBeginScenario(scenario_id)
  UbNpcCleanup(false)
  local sc = UbClientFindScenario(scenario_id)
  if not sc then
    return
  end
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
      local ped = CreatePed(4, model, c.x, c.y, c.z, c.w or 0.0, false, true)
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
    TriggerServerEvent(UbEvent('server:npcSpawnFailed'))
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
        TriggerServerEvent(UbEvent('server:completeCombat'))
        break
      end
    end
  end)
end

--- @param silent boolean|nil NPC を削除しない（リソース停止時など）
function UbNpcCleanup(silent)
  HeistCombatActive = false
  for _, p in ipairs(Managed) do
    if DoesEntityExist(p) then
      DeleteEntity(p)
    end
  end
  Managed = {}
end
