--[[
  ox_inventory で強盗報酬が「入手できない」ときの対処

  多くの場合、`markedbills` / `stickynote` が ox の items に未定義のため
  AddItem が invalid_item で失敗しています。

  手順:
  1. サーバの ox_inventory の data/items.lua（または items/*.lua）を開く
  2. 下のブロックを、既存のアイテムテーブルと同じ形式で「キーを追加」する
     （このファイルをそのまま require するのではなく、定義をコピーして統合）
  3. restart ox_inventory（またはサーバ再起動）

  weight / label はサーバのバランスに合わせて調整してください。
  rolex / goldbar は多くの ox セットで既に入っているため、無ければ同様に追加。
]]

--[[ コピー用（items.lua のアイテム辞書に追記）

  client.image を付ける場合は画像を ox_inventory/web/images/ に置く。
  qb-inventory から流用する例（パスは環境に合わせて変更）:

  Copy-Item "...\qb-inventory\html\images\markedbills.png" "...\ox_inventory\web\images\"
  Copy-Item "...\qb-inventory\html\images\stickynote.png" "...\ox_inventory\web\images\"

  メタデータの worth / label は bridge から渡したテーブルがそのまま保持される。
  アイテム未定義の場合、ox は invalid_item で AddItem が失敗する（本リソースはサーバログに理由を出す）。
]]

--[[

['markedbills'] = {
    label = 'マークされた紙幣',
    weight = 0,
    stack = true,
    close = true,
    description = '強盗で盗んだマークされた紙幣。フェンサーで換金できる',
    client = {
        image = 'markedbills.png',
    },
},

['stickynote'] = {
    label = 'メモ',
    weight = 0,
    stack = false,
    close = true,
    description = '何か書かれたメモ',
    client = {
        image = 'stickynote.png',
    },
},

--]]
