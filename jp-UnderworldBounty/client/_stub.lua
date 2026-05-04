-- 開発用クライアントスタブ（サーバー↔クライアント契約の単体検証向け）
-- docs/SEQUENCE_DIAGRAMS.md / docs/RETALIATION_FSM.md §13 と整合させて拡張すること。
-- Config.DebugUseClientStub = true のときのみ有効（既定 false）。

if not Config.DebugUseClientStub then
  return
end

CreateThread(function()
  print('[jp-UnderworldBounty] DebugUseClientStub: stub loaded (extend RegisterNetEvent / callbacks as needed)')
end)
