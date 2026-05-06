--[[
  Logger / RefboardGuard（実機テスト前夜: 観測可能性）
]]

Logger = {}

local LOG_LEVELS = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }

local function currentLevelNum()
  local lv = (Config and Config.LogLevel) or 'INFO'
  if lv == 'DEBUG' then
    return LOG_LEVELS.DEBUG
  end
  if lv == 'WARN' then
    return LOG_LEVELS.WARN
  end
  if lv == 'ERROR' then
    return LOG_LEVELS.ERROR
  end
  return LOG_LEVELS.INFO
end

local function formatLog(level, source, message, context)
  local time = os.date('%H:%M:%S')
  local ms = math.floor((GetGameTimer() % 1000))
  local ctxStr = ''
  if type(context) == 'table' then
    local parts = {}
    for k, v in pairs(context) do
      parts[#parts + 1] = ('%s=%s'):format(tostring(k), tostring(v))
    end
    if #parts > 0 then
      ctxStr = ' | ' .. table.concat(parts, ' ')
    end
  end
  return ('[%s.%03d] [%s] [%s] %s%s'):format(time, ms, level, source, message, ctxStr)
end

function Logger.debug(source, message, context)
  if currentLevelNum() <= LOG_LEVELS.DEBUG then
    print('^7' .. formatLog('DEBUG', source, message, context))
  end
end

function Logger.info(source, message, context)
  if currentLevelNum() <= LOG_LEVELS.INFO then
    print('^2' .. formatLog('INFO', source, message, context))
  end
end

function Logger.warn(source, message, context)
  if currentLevelNum() <= LOG_LEVELS.WARN then
    print('^3' .. formatLog('WARN', source, message, context))
  end
end

function Logger.error(source, message, context)
  print('^1' .. formatLog('ERROR', source, message, context))
  if type(context) == 'table' and context.stack then
    print('^1' .. tostring(context.stack))
  end
end

--- NetEvent 本体を xpcall で保護。例外時はログ + 任意で ACK に構造化エラーを返す。
---@param src number
---@param ackEvent string|nil TriggerClientEvent 名（nil のときクライアントへは送らない）
---@param tag string ログ用タグ（例: net:score:goal）
---@param fn function
function RefboardGuard(src, ackEvent, tag, fn)
  local ok, err = xpcall(fn, function(msg)
    return debug.traceback(tostring(msg), 2)
  end)
  if ok then
    return
  end
  Logger.error(tag, 'unhandled_exception', { src = src, stack = err })
  if ackEvent and MakeError and ErrorCodes then
    local firstLine = tostring(err):match('^[^\n]+') or 'error'
    TriggerClientEvent(
      ackEvent,
      src,
      MakeError(ErrorCodes.UNHANDLED_EXCEPTION, firstLine, {
        source = tag,
        stack = err,
      })
    )
  end
end
