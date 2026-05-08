-- SPDX-License-Identifier: LGPL-3.0-or-later

---@diagnostic disable: undefined-global

--- M1-a DB smoke test: set true, run /testTectonInsert once in-game, set false (or remove command in a later commit).
local ENABLE_TEST_TECTON_INSERT = false

local scene = Config.DefaultScene or 'default'

local function refreshAutosaveForScene(sid)
    local snap = TectonDB.buildSnapshot(sid)
    return TectonDB.upsertAutosave(sid, snap)
end

AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then
        return
    end
    print(('TECTON server started, scene=%s'):format(scene))
end)

RegisterCommand('testTectonInsert', function(src)
    if not ENABLE_TEST_TECTON_INSERT then
        return
    end
    if src == 0 then
        print('[TECTON] testTectonInsert: run from in-game (player src > 0)')
        return
    end
    local license = GetPlayerIdentifierByType(src, 'license') or ('player:' .. tostring(src))
    local id = TectonDB.insertObject({
        category = 'furniture',
        model = 'prop_test_dummy_m1a',
        pos = { x = 100.0, y = 200.0, z = 30.0 },
        rot = { x = 0.0, y = 0.0, z = 45.0 },
        meta = { test = true },
        scene_id = scene,
        created_by = license,
    })
    print(('[TECTON] testTectonInsert insert id=%s'):format(tostring(id)))
    if id then
        TectonDB.appendHistory({
            type = OpType.CREATE,
            target_id = id,
            before = nil,
            after = { id = id },
            scene_id = scene,
            user_id = license,
        })
        refreshAutosaveForScene(scene)
    end
end, false)
