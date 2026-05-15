-- ============================================================
-- jp-meridian9 / server/arena/wave.lua
-- ============================================================
-- 波構成参照（MERIDIAN-9 独自）。TP-Advanced-Zombies 由来コードは含まない。
-- ============================================================

MRD9.Arena = MRD9.Arena or {}
MRD9.Arena.Wave = MRD9.Arena.Wave or {}

---@param waveNumber integer
---@return table|nil
function MRD9.Arena.Wave.GetConfig(waveNumber)
    local w = Config.Arena and Config.Arena.waves and Config.Arena.waves[waveNumber]
    return w
end
