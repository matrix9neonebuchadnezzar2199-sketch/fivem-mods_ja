--[[
  RefBoard — ツール接続中プレイヤー一覧（設計: 編集権限は単一ロック、表示は「接続人数」＝閲覧含む）
  main.lua から TriggerEvent('refboard:presence:add'|'remove'|'setMode', ...) で更新する。
]]

local sessions = {}

local function toList()
  local list = {}
  for sid, s in pairs(sessions) do
    list[#list + 1] = {
      serverId = sid,
      license = s.license,
      name = s.name,
      mode = s.mode,
      since = s.since,
      focus = s.focus,
    }
  end
  table.sort(list, function(a, b)
    return a.serverId < b.serverId
  end)
  return list
end

local function broadcast()
  TriggerClientEvent('refboard:presence:update', -1, { users = toList() })
end

local function addSession(src, license, name, mode)
  local m = (mode == 'edit') and 'edit' or 'view'
  sessions[src] = {
    license = license or '',
    name = name or ('Player %s'):format(src),
    mode = m,
    since = os.time(),
    focus = nil,
  }
  broadcast()
end

local function removeSession(src)
  if sessions[src] then
    sessions[src] = nil
    broadcast()
  end
end

local function setSessionMode(src, mode)
  local s = sessions[src]
  if not s then
    return
  end
  s.mode = (mode == 'edit') and 'edit' or 'view'
  broadcast()
end

AddEventHandler('refboard:presence:add', function(src, license, name, mode)
  if type(src) ~= 'number' then
    return
  end
  addSession(src, license, name, mode)
end)

AddEventHandler('refboard:presence:remove', function(src)
  if type(src) ~= 'number' then
    return
  end
  removeSession(src)
end)

AddEventHandler('refboard:presence:setMode', function(src, mode)
  if type(src) ~= 'number' then
    return
  end
  setSessionMode(src, mode)
end)

AddEventHandler('playerDropped', function()
  removeSession(source)
end)

RegisterNetEvent('refboard:presence:list', function()
  local src = source
  if not IsPlayerAceAllowed(src, Config.RefereePermission) then
    return
  end
  TriggerClientEvent('refboard:presence:list:ack', src, { users = toList() })
end)

RegisterNetEvent('refboard:presence:focus', function(payload)
  local src = source
  if not IsPlayerAceAllowed(src, Config.RefereePermission) then
    return
  end
  local s = sessions[src]
  if not s then
    return
  end
  if type(payload) ~= 'table' then
    return
  end
  local f = payload.focus
  if type(f) == 'string' then
    s.focus = (f ~= '' and f) or nil
  else
    s.focus = nil
  end
  broadcast()
end)
