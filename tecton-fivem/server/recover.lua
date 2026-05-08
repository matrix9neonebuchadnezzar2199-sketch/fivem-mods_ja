-- SPDX-License-Identifier: LGPL-3.0-or-later

---@diagnostic disable: undefined-global

assert(TectonDB, '[TECTON] TectonDB not loaded — check server_scripts order')

local M = {}

--- tec_autosave の snapshot 件数と tec_objects の生件数を比較するだけ（M1 はログのみ、自動修復はしない）。
---@param scene_id string
function M.checkIntegrity(scene_id)
    local live = TectonDB.fetchScene(scene_id)
    local liveCount = #live
    local snap = TectonDB.fetchAutosave(scene_id)
    if not snap or type(snap.objects) ~= 'table' then
        if liveCount > 0 then
            print(
                ('^3[TECTON] scene \'%s\': no autosave snapshot but %d live objects (autosave updates on each op)^0'):format(
                    scene_id,
                    liveCount
                )
            )
        else
            print(('TECTON: scene integrity OK for \'%s\' (empty scene, no snapshot)'):format(scene_id))
        end
        return
    end
    local snapCount = #snap.objects
    if snapCount ~= liveCount then
        print(
            ('^3[TECTON] WARNING scene \'%s\': autosave snapshot has %d objects, live DB has %d (trust autosave for M3 replay; no auto-fix)^0'):format(
                scene_id,
                snapCount,
                liveCount
            )
        )
    else
        print(('TECTON: scene integrity OK for \'%s\' (%d objects)'):format(scene_id, liveCount))
    end
end

TectonRecover = M
return M
