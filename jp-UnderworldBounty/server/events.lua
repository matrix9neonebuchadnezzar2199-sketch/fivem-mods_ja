--- 公開イベントフック（他リソースは RegisterNetEvent ではなく TriggerEvent で購読）
--- @param name string DESIGN の onHeistStart など（接頭辞なし）
--- @param payload table|nil
function UbEmitHook(name, payload)
  TriggerEvent('jp-UnderworldBounty:' .. name, payload or {})
end
