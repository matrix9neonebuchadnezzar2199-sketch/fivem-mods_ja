--[[
  開発用: トランザクション周りのスモーク確認（詳細は docs/testing/transaction_test.md）
]]

if not Config.EnableTestCommands then
  return
end

RegisterCommand(
  'refboard_test_transaction',
  function(src)
    if src ~= 0 then
      return
    end
    print('[RefBoard] transaction_test: EnableTestCommands=true — 手動手順は docs/testing/transaction_test.md を参照')
    local ok, err = pcall(function()
      MySQL.query.await('SELECT 1')
    end)
    if ok then
      print('[RefBoard] transaction_test: MySQL.query.await OK')
    else
      print('[RefBoard] transaction_test: MySQL error: ' .. tostring(err))
    end
  end,
  true
)
