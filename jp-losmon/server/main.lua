-- jp-losmon サーバー: 図鑑のサーバー保存等は使わない（KVS はクライアントのみ）
-- 将来: 全プレイヤー共通図鑑等を付ける場合にここで処理する
CreateThread(function()
  print('[jp-losmon] server: 図鑑はクライアントKVS only')
end)
