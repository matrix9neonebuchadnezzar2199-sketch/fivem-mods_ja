local ContractRunning = false
local ContractPhase = nil
local ContractSite = nil
local informantPed = nil
local siteBlip = nil
local lastInformantHelp = 0
local lastSiteHelp = 0
local INFORMANT_HELP_MS = 3800
local SITE_HELP_MS = 3800
local SITE_MARKER_DIST = 48.0

local function delete_site_blip()
  if siteBlip and DoesBlipExist(siteBlip) then
    RemoveBlip(siteBlip)
  end
  siteBlip = nil
end

local function clear_waypoint_nav()
  delete_site_blip()
  DeleteWaypoint()
end

--- 衝突ロード後に GetGroundZ のみ使用。設定Zと大きくズレる値（下の道路など）は捨てる。
local function informant_resolve_spawn_z(x, y, zConfig)
  RequestCollisionAtCoord(x, y, zConfig)
  for _ = 1, 30 do
    Wait(0)
  end
  local gok, gz = GetGroundZFor_3dCoord(x, y, zConfig + 15.0, false)
  if gok and gz then
    local dz = gz - zConfig
    if dz > -6.0 and dz < 3.5 then
      return gz + 0.02
    end
  end
  return zConfig
end

local function spawn_informant()
  local ci = Config.ContractInformant
  if not ci or not ci.coords then
    return
  end
  if informantPed ~= nil and DoesEntityExist(informantPed) then
    return
  end
  local model = ci.model or joaat('a_m_m_business_01')
  RequestModel(model)
  local t0 = GetGameTimer()
  while not HasModelLoaded(model) do
    Wait(50)
    if GetGameTimer() - t0 > 12000 then
      return
    end
  end
  if not HasModelLoaded(model) then
    return
  end
  local c = ci.coords
  local hx = c.x
  local hy = c.y
  local hz = informant_resolve_spawn_z(hx, hy, c.z) + (ci.spawn_z_offset or 0.0)
  local heading = c.w or 0.0
  informantPed = CreatePed(4, model, hx, hy, hz, heading, false, false)
  if informantPed == 0 or not DoesEntityExist(informantPed) then
    informantPed = nil
    SetModelAsNoLongerNeeded(model)
    return
  end
  SetEntityAsMissionEntity(informantPed, true, true)
  SetBlockingOfNonTemporaryEvents(informantPed, true)
  SetEntityCoordsNoOffset(informantPed, hx, hy, hz, false, false, false)
  SetEntityHeading(informantPed, heading)
  FreezeEntityPosition(informantPed, true)
  SetPedFleeAttributes(informantPed, 0, false)
  SetPedCombatAttributes(informantPed, 46, true)
  SetEntityInvincible(informantPed, true)
  SetModelAsNoLongerNeeded(model)
end

local function cleanup_informant()
  if informantPed ~= nil and DoesEntityExist(informantPed) then
    DeleteEntity(informantPed)
  end
  informantPed = nil
end

local function informant_vec3()
  local ci = Config.ContractInformant
  if not ci or not ci.coords then
    return nil
  end
  return vector3(ci.coords.x, ci.coords.y, ci.coords.z)
end

local function dist_to_informant(ped)
  local p = informant_vec3()
  if not p then
    return 9999.0
  end
  return #(GetEntityCoords(ped) - p)
end

local function dist_to_site(ped)
  if not ContractSite then
    return 9999.0
  end
  return #(GetEntityCoords(ped) - ContractSite)
end

RegisterNetEvent(UbEvent('client:contractOfferSync'), function(data)
  ContractRunning = true
  ContractPhase = 'travel'
  if data.coords then
    ContractSite = vector3(data.coords.x, data.coords.y, data.coords.z)
    SetNewWaypoint(data.coords.x + 0.01, data.coords.y + 0.01)
    delete_site_blip()
    siteBlip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipSprite(siteBlip, 480)
    SetBlipColour(siteBlip, 1)
    SetBlipAsShortRange(siteBlip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(_L('contract_blip_site'))
    EndTextCommandSetBlipName(siteBlip)
    SetBlipRoute(siteBlip, true)
  else
    ContractSite = nil
  end
  UbNotify(_L('notify_contract_nav_set'), 'info')
end)

RegisterNetEvent(UbEvent('client:contractRunGimmick'), function()
  ContractPhase = 'gimmick'
  UbRunMinigame('timing_wheel', function(ok)
    TriggerServerEvent(UbEvent('server:contractMinigameResult'), ok)
  end)
end)

RegisterNetEvent(UbEvent('client:contractCombatSync'), function(data)
  ContractPhase = 'combat'
  ContractSite = nil
  clear_waypoint_nav()
  local scid = data.scenario_id
  local c = data.coords
  if not scid or not c then
    return
  end
  local anchor = vector3(c.x, c.y, c.z)
  UbNpcBeginScenario(scid, {
    session = 'contract',
    anchor = anchor,
    anchor_heading = data.heading or 0.0,
  })
end)

RegisterNetEvent(UbEvent('client:contractEnded'), function(payload)
  ContractRunning = false
  ContractPhase = nil
  ContractSite = nil
  clear_waypoint_nav()
  UbUiMinigameClose()
  local delay = (Config.CombatEntityCleanupDelayMs or 0)
  if delay > 0 then
    UbNpcCleanupAfter(delay, true)
  else
    UbNpcCleanup(true)
  end
  local reason = payload and payload.reason
  if reason == 'success' then
    UbNotify(_L('notify_contract_success'), 'success')
  elseif reason == 'cancel' then
    UbNotify(_L('notify_contract_cancelled'), 'info')
  end
end)

CreateThread(function()
  Wait(800)
  local ok, err = pcall(spawn_informant)
  if not ok then
    print(('^1[jp-UnderworldBounty] informant spawn error: %s^0'):format(tostring(err)))
  end
  Wait(4500)
  if informantPed == nil or not DoesEntityExist(informantPed) then
    pcall(spawn_informant)
  end
end)

CreateThread(function()
  while true do
    local waitMs = 600
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local iv = informant_vec3()
    if iv and ContractPhase == 'travel' and ContractSite and dist_to_site(ped) <= SITE_MARKER_DIST then
      waitMs = 0
      local c = ContractSite
      local r = Config.ContractSiteRadius or 2.5
      DrawMarker(
        25,
        c.x, c.y, c.z - 0.98,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        r * 2.4, r * 2.4, 0.35,
        255, 200, 60, 120,
        false,
        false,
        2,
        false,
        nil,
        nil,
        false
      )
    elseif iv and not ContractRunning and #(pos - iv) <= 42.0 then
      waitMs = 0
      local r = (Config.ContractInformant and Config.ContractInformant.radius) or 2.2
      DrawMarker(
        25,
        iv.x, iv.y, iv.z - 0.98,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        r * 2.4, r * 2.4, 0.35,
        200, 220, 255, 110,
        false,
        false,
        2,
        false,
        nil,
        nil,
        false
      )
    end
    Wait(waitMs)
  end
end)

CreateThread(function()
  while true do
    local ped = PlayerPedId()
    local nearI = informant_vec3() and dist_to_informant(ped) <= ((Config.ContractInformant and Config.ContractInformant.radius) or 2.2) + 0.35
    if nearI then
      local now = GetGameTimer()
      if ContractRunning and ContractPhase == 'travel' then
        if now - lastInformantHelp >= INFORMANT_HELP_MS then
          BeginTextCommandDisplayHelp('STRING')
          AddTextComponentSubstringPlayerName(_L('prompt_contract_cancel'))
          EndTextCommandDisplayHelp(0, false, false, -1)
          lastInformantHelp = now
        end
        if IsControlJustReleased(0, 38) then
          TriggerServerEvent(UbEvent('server:contractCancel'))
          Wait(600)
        end
      elseif not ContractRunning then
        if now - lastInformantHelp >= INFORMANT_HELP_MS then
          BeginTextCommandDisplayHelp('STRING')
          AddTextComponentSubstringPlayerName(_L('prompt_contract_accept'))
          EndTextCommandDisplayHelp(0, false, false, -1)
          lastInformantHelp = now
        end
        if IsControlJustReleased(0, 38) then
          TriggerServerEvent(UbEvent('server:contractAccept'))
          Wait(600)
        end
      end
      Wait(16)
    else
      Wait(Config.ZonePollIntervalMs or 500)
    end
  end
end)

CreateThread(function()
  while true do
    if ContractRunning and ContractPhase == 'travel' and ContractSite then
      local ped = PlayerPedId()
      local rad = Config.ContractSiteRadius or 2.5
      if dist_to_site(ped) <= rad then
        local now = GetGameTimer()
        if now - lastSiteHelp >= SITE_HELP_MS then
          BeginTextCommandDisplayHelp('STRING')
          AddTextComponentSubstringPlayerName(_L('prompt_contract_site'))
          EndTextCommandDisplayHelp(0, false, false, -1)
          lastSiteHelp = now
        end
        if IsControlJustReleased(0, 38) then
          TriggerServerEvent(UbEvent('server:contractRequestMinigame'))
          Wait(700)
        end
        Wait(16)
      else
        Wait(Config.ZonePollIntervalMs or 500)
      end
    else
      Wait(600)
    end
  end
end)

CreateThread(function()
  while true do
    Wait(350)
    if ContractRunning and ContractPhase == 'combat' then
      if IsPedDeadOrDying(PlayerPedId(), true) then
        TriggerServerEvent(UbEvent('server:contractPlayerDown'))
        ContractRunning = false
        ContractPhase = nil
        ContractSite = nil
        clear_waypoint_nav()
        UbNpcCleanup(true)
      end
    end
  end
end)

function UbContractClientReset()
  ContractRunning = false
  ContractPhase = nil
  ContractSite = nil
  clear_waypoint_nav()
  UbUiMinigameClose()
end

AddEventHandler('onResourceStop', function(resName)
  if resName ~= RESOURCE then
    return
  end
  UbContractClientReset()
  cleanup_informant()
end)
