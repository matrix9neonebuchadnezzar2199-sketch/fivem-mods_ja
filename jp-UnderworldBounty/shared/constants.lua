local RESOURCE_NAME = GetCurrentResourceName()

RESOURCE = RESOURCE_NAME

local function prefix()
  return 'jp-UnderworldBounty'
end

--- FiveM イベント名を統一生成する（クライアント／サーバー共通）
--- @param name string サフィックス（例: 'server:requestStart'）
--- @return string
function UbEvent(name)
  return prefix() .. ':' .. name
end
