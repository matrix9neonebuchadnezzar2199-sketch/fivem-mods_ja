-- ============================================================
-- MERIDIAN-9 / ポータル演出 共有定義（INSTRUCTION-022）
-- ゲームロジックは server/portal.lua 側。ここは将来の定数置き場。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.PortalDefs = MRD9.PortalDefs or {
    netSetState = 'mrd9:portal:setState',
    netSyncAll = 'mrd9:portal:syncAll',
    netRequestSync = 'mrd9:portal:requestSync',
}
