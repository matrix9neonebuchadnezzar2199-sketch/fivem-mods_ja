-- 配達ジョブ クライアント側 状態管理（日本語版）
Delivery = {}
Delivery.Functions = {}

-- 状態管理テーブル
Delivery.State = {
    inJob = false, -- 業務中かどうか
    PlayerData = nil, -- プレイヤーデータ
    inAnim = false, -- アニメーション再生中かどうか
    entity = nil, -- 荷物エンティティ
    haveBox = false, -- 荷物を持っているか（最初の本部からトラックへ）
    getBox = false, -- 荷物を持っているか（配達中）
    vehicle = nil, -- 配達車両
    vehicle2 = nil, -- 最寄り車両（参照用）
    gotoPoint = false, -- 次の配達地点へ向かう状態
    comeBack = false, -- 本部に戻る状態
    dest_blip = nil, -- 目的地ブリップ
    blipStatus = nil, -- ブリップ状態フラグ
    deliveryZoneId = nil, -- 配達ターゲットゾーンID
    returnZoneId = nil, -- 返却ターゲットゾーンID
    currentRoute = 1, -- 現在のルート番号
    currentStop = 1 -- 現在の配達ポイント番号
}
