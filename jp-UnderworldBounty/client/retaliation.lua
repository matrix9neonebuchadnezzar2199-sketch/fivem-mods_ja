local RetaliationActive = false
local RetEntities = {}
local RetGroup = nil

local function ensure_ret_group(neutral_cops)
  if RetGroup then
    return RetGroup
  end
  AddRelationshipGroup('JP_UB_RET')
  RetGroup = GetHashKey('JP_UB_RET')
  local pg = joaat('PLAYER')
  SetRelationshipBetweenGroups(5, RetGroup, pg)
  SetRelationshipBetweenGroups(5, pg, RetGroup)
  if neutral_cops then
    local cg = joaat('COP')
    SetRelationshipBetweenGroups(4, RetGroup, cg)
    SetRelationshipBetweenGroups(4, cg, RetGroup)
  end
  return RetGroup
end

local function push_ent(e)
  RetEntities[#RetEntities + 1] = e
end

function UbRetaliationCleanup()
  RetaliationActive = false
  for _, e in ipairs(RetEntities) do
    if DoesEntityExist(e) then
      DeleteEntity(e)
    end
  end
  RetEntities = {}
end

RegisterNetEvent(UbEvent('client:retaliationStart'), function(data)
  if RetaliationActive then
    UbRetaliationCleanup()
  end
  local pat = Config.RetaliationPatterns[data.pattern_id]
  if not pat then
    TriggerServerEvent(UbEvent('server:retaliationWaveEnd'), true)
    return
  end
  UbNotify(_L('notify_retaliation_start'), 'error')
  RetaliationActive = true
  local grp = ensure_ret_group(pat.neutral_to_cops ~= false)
  local player = PlayerPedId()
  local pcoords = GetEntityCoords(player)
  local heading = GetEntityHeading(player)
  local rad = math.rad(heading + 180.0)
  local spawnDist = 85.0
  local vx = math.sin(rad) * spawnDist
  local vy = math.cos(rad) * spawnDist
  local sx = pcoords.x + vx
  local sy = pcoords.y + vy
  local sz = pcoords.z
  local ground, gz = GetGroundZFor_3dCoord(sx, sy, sz + 50.0, false)
  if ground then
    sz = gz
  end
  local vmodel = pat.vehicle_model or joaat('baller2')
  RequestModel(vmodel)
  local t0 = GetGameTimer()
  while not HasModelLoaded(vmodel) do
    Wait(50)
    if GetGameTimer() - t0 > 8000 then
      break
    end
  end
  local veh = nil
  if HasModelLoaded(vmodel) then
    veh = CreateVehicle(vmodel, sx, sy, sz, heading, false, true)
    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    SetVehicleEngineOn(veh, true, true, false)
    push_ent(veh)
    SetModelAsNoLongerNeeded(vmodel)
  end
  local models = pat.ped_models or { joaat('g_m_m_armgoon_01') }
  local squad = math.min(pat.squad_size or 2, #models > 0 and #models or 1)
  local weapon = pat.weapon or joaat('WEAPON_SMG')
  local seats = { -1, 0, 1, 2 }
  for i = 1, squad do
    local pm = models[((i - 1) % #models) + 1]
    RequestModel(pm)
    t0 = GetGameTimer()
    while not HasModelLoaded(pm) do
      Wait(50)
      if GetGameTimer() - t0 > 8000 then
        break
      end
    end
    if HasModelLoaded(pm) then
      local px, py, pz = sx, sy, sz
      if veh then
        px, py, pz = GetOffsetFromEntityInWorldCoords(veh, 0.0, (i - 2) * 1.2, 0.5)
      end
      local ped = CreatePed(4, pm, px, py, pz, heading, false, true)
      SetEntityAsMissionEntity(ped, true, true)
      SetPedRelationshipGroupHash(ped, grp)
      GiveWeaponToPed(ped, weapon, 220, false, true)
      TaskCombatPed(ped, player, 0, 16)
      if veh and seats[i] then
        TaskWarpPedIntoVehicle(ped, veh, seats[i])
      end
      push_ent(ped)
      SetModelAsNoLongerNeeded(pm)
    end
  end
  local ped_count = 0
  for _, e in ipairs(RetEntities) do
    if DoesEntityExist(e) and IsEntityAPed(e) then
      ped_count = ped_count + 1
    end
  end
  if ped_count == 0 then
    RetaliationActive = false
    TriggerServerEvent(UbEvent('server:retaliationWaveEnd'), true)
    return
  end
  if veh and pat.approach == 'drive' then
    Wait(400)
    local driver = GetPedInVehicleSeat(veh, -1)
    if driver ~= 0 then
      TaskVehicleDriveToCoord(
        driver,
        veh,
        pcoords.x,
        pcoords.y,
        pcoords.z,
        28.0,
        0,
        GetEntityModel(veh),
        786603,
        8.0,
        0.0
      )
    end
  end
  CreateThread(function()
    while RetaliationActive do
      Wait(700)
      local alive = 0
      for _, e in ipairs(RetEntities) do
        if DoesEntityExist(e) and IsEntityAPed(e) and not IsEntityDead(e) then
          alive = alive + 1
        end
      end
      local player_dead = IsEntityDead(PlayerPedId())
      if player_dead then
        UbRetaliationCleanup()
        TriggerServerEvent(UbEvent('server:retaliationWaveEnd'), false)
        break
      end
      if alive == 0 and #RetEntities > 0 then
        UbNotify(_L('notify_retaliation_end'), 'info')
        UbRetaliationCleanup()
        TriggerServerEvent(UbEvent('server:retaliationWaveEnd'), true)
        break
      end
    end
  end)
end)
