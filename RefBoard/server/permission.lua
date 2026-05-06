--[[
  編集権限: 編集モード入室時にパスワード検証（Config.EditPassword、既定 "ref"）。
  閲覧: presence に登録済み（session_enter 済み）なら読み取り系 API 利用可。
]]

local editApproved = {}

function RefboardSetEditApproved(src, approved)
  if type(src) ~= 'number' then
    return
  end
  if approved then
    editApproved[src] = true
  else
    editApproved[src] = nil
  end
end

function RefboardIsEditApproved(src)
  return type(src) == 'number' and editApproved[src] == true
end

--- 試合作成用チーム一覧など: セッション参加者のみ
function RefboardCanRead(src)
  return type(RefboardPresenceHasSession) == 'function' and RefboardPresenceHasSession(src)
end

--- DB 更新・ロック取得など
function RefboardRequireEdit(src)
  if not RefboardIsEditApproved(src) then
    TriggerClientEvent('refboard:notify', src, { type = 'error', key = 'no_permission' })
    return false
  end
  return true
end

function RefboardValidateEditPassword(pw)
  local expected = (Config and Config.EditPassword) or 'ref'
  if type(pw) ~= 'string' then
    return false
  end
  local trimmed = pw:match('^%s*(.-)%s*$') or ''
  return trimmed == expected
end

AddEventHandler('playerDropped', function()
  RefboardSetEditApproved(source, false)
end)
