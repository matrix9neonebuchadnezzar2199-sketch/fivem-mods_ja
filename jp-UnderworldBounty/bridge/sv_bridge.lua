Bridge = Bridge or {}

local ESX
local QBCore

local function ensure_esx()
  if ESX then
    return ESX
  end
  local ok, obj = pcall(function()
    return exports['es_extended']:getSharedObject()
  end)
  if ok and obj then
    ESX = obj
  end
  return ESX
end

local function ensure_qb()
  if QBCore then
    return QBCore
  end
  local ok, obj = pcall(function()
    return exports['qb-core']:GetCoreObject()
  end)
  if ok and obj then
    QBCore = obj
  end
  return QBCore
end

local function qb_like_player(src)
  local core = ensure_qb()
  if not core then
    return nil
  end
  return core.Functions.GetPlayer(src)
end

--- @param source number
--- @return table|nil
function Bridge.GetPlayerData(source)
  if Framework == 'esx' then
    local xPlayer = ensure_esx() and ESX.GetPlayerFromId(source)
    if not xPlayer then
      return nil
    end
    return {
      name = xPlayer.getName and xPlayer.getName() or GetPlayerName(source),
      money = xPlayer.getMoney and xPlayer.getMoney() or 0,
      job = xPlayer.job and xPlayer.job.name or 'unemployed',
      identifier = xPlayer.identifier,
    }
  end

  if Framework == 'qbcore' or Framework == 'qbox' then
    local Player = qb_like_player(source)
    if not Player then
      return nil
    end
    local ci = Player.PlayerData.charinfo or {}
    local full = ((ci.firstname or '') .. ' ' .. (ci.lastname or '')):gsub('^%s*(.-)%s*$', '%1')
    local cash = (Player.PlayerData.money and Player.PlayerData.money.cash) or 0
    return {
      name = (full ~= '' and full) or GetPlayerName(source),
      money = cash,
      job = Player.PlayerData.job and Player.PlayerData.job.name or 'unemployed',
      identifier = Player.PlayerData.citizenid,
    }
  end

  return {
    name = GetPlayerName(source),
    money = 0,
    job = 'civilian',
    identifier = 'standalone:' .. tostring(source),
  }
end

--- @param source number
--- @param typ string cash|bank|black （Standalone は無視）
--- @param amount number
--- @return boolean
function Bridge.AddMoney(source, typ, amount)
  amount = math.floor(tonumber(amount) or 0)
  if amount <= 0 then
    return true
  end
  if Framework == 'esx' then
    local xPlayer = ensure_esx() and ESX.GetPlayerFromId(source)
    if not xPlayer then
      return false
    end
    local account = 'money'
    if typ == 'bank' then
      account = 'bank'
    elseif typ == 'black' or typ == 'black_money' then
      account = 'black_money'
    end
    xPlayer.addAccountMoney(account, amount)
    return true
  end
  if Framework == 'qbcore' or Framework == 'qbox' then
    local Player = qb_like_player(source)
    if not Player then
      return false
    end
    local mtyp = (typ == 'bank' and 'bank') or 'cash'
    Player.Functions.AddMoney(mtyp, amount)
    return true
  end
  return true
end

--- @return boolean
function Bridge.RemoveMoney(source, typ, amount)
  amount = math.floor(tonumber(amount) or 0)
  if amount <= 0 then
    return true
  end
  if Framework == 'esx' then
    local xPlayer = ensure_esx() and ESX.GetPlayerFromId(source)
    if not xPlayer then
      return false
    end
    local account = 'money'
    if typ == 'bank' then
      account = 'bank'
    elseif typ == 'black' or typ == 'black_money' then
      account = 'black_money'
    end
    xPlayer.removeAccountMoney(account, amount)
    return true
  end
  if Framework == 'qbcore' or Framework == 'qbox' then
    local Player = qb_like_player(source)
    if not Player then
      return false
    end
    local mtyp = (typ == 'bank' and 'bank') or 'cash'
    Player.Functions.RemoveMoney(mtyp, amount)
    return true
  end
  return true
end

--- @return boolean
function Bridge.HasItem(source, item, count)
  count = math.max(1, math.floor(tonumber(count) or 1))
  if Framework == 'esx' then
    local xPlayer = ensure_esx() and ESX.GetPlayerFromId(source)
    if not xPlayer then
      return false
    end
    local inv = xPlayer.getInventoryItem(item)
    return inv and inv.count >= count
  end
  if Framework == 'qbcore' or Framework == 'qbox' then
    local Player = qb_like_player(source)
    if not Player then
      return false
    end
    local it = Player.Functions.GetItemByName(item)
    return it and (it.amount or it.count or 0) >= count
  end
  return true
end

--- @return boolean
function Bridge.AddItem(source, item, count)
  count = math.max(1, math.floor(tonumber(count) or 1))
  if Framework == 'esx' then
    local xPlayer = ensure_esx() and ESX.GetPlayerFromId(source)
    if not xPlayer then
      return false
    end
    xPlayer.addInventoryItem(item, count)
    return true
  end
  if Framework == 'qbcore' or Framework == 'qbox' then
    local Player = qb_like_player(source)
    if not Player then
      return false
    end
    return Player.Functions.AddItem(item, count)
  end
  return true
end

--- @return boolean
function Bridge.RemoveItem(source, item, count)
  count = math.max(1, math.floor(tonumber(count) or 1))
  if Framework == 'esx' then
    local xPlayer = ensure_esx() and ESX.GetPlayerFromId(source)
    if not xPlayer then
      return false
    end
    xPlayer.removeInventoryItem(item, count)
    return true
  end
  if Framework == 'qbcore' or Framework == 'qbox' then
    local Player = qb_like_player(source)
    if not Player then
      return false
    end
    return Player.Functions.RemoveItem(item, count)
  end
  return true
end

--- @return string
function Bridge.GetJob(source)
  local d = Bridge.GetPlayerData(source)
  return (d and d.job) or 'unemployed'
end

--- @return integer
function Bridge.GetCopCount()
  local total = 0
  for _, sid in ipairs(GetPlayers()) do
    local src = tonumber(sid)
    local job = Bridge.GetJob(src):lower()
    if Config.PoliceJobs[job] then
      total = total + 1
    end
  end
  return total
end

--- @param message string
--- @param typ string|nil info|success|error
function Bridge.Notify(source, message, typ)
  typ = typ or 'info'
  if Framework == 'esx' then
    TriggerClientEvent('esx:showNotification', source, message)
    return
  end
  if Framework == 'qbcore' or Framework == 'qbox' then
    local mapped = typ == 'error' and 'error' or 'primary'
    TriggerClientEvent('QBCore:Notify', source, message, mapped)
    return
  end
  TriggerClientEvent(UbEvent('client:standaloneNotify'), source, message, typ)
end
