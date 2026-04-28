-- 動的台・デバッグ用コマンド（必ずサーバー側で権限再チェック）

---@param source number
---@return boolean
local function isAdmin(source)
    return source > 0 and IsPlayerAceAllowed(source, Config.AdminAce or 'jp-slot.admin')
end

---@param source number
---@param msg string
---@param color table|nil
local function notify(source, msg, color)
    color = color or { 255, 210, 74 }
    TriggerClientEvent('chat:addMessage', source, {
        color = color,
        multiline = true,
        args = { '[jp-slot]', msg },
    })
end

---@param source number
---@param msg string
local function notifyError(source, msg)
    notify(source, msg, { 255, 80, 80 })
end

---@param source number
---@return string
local function licenseOf(source)
    local ids = GetPlayerIdentifiers(source)
    if ids then
        for i = 1, #ids do
            local id = ids[i]
            if id and string.sub(id, 1, 8) == 'license:' then
                return id
            end
        end
        return ids[1] or ('source:' .. source)
    end
    return 'source:' .. source
end

RegisterCommand('jpslotplace', function(source, args)
    if source == 0 then
        return
    end
    if not isAdmin(source) then
        notifyError(source, '権限がありません（jp-slot.admin が必要）')
        return
    end
    local dp = Config.DynamicPlacement or {}
    local propKey = args[1] or dp.DefaultProp or 'cherry_theme'
    local charId = args[2] or dp.DefaultChar or 'luna'
    local ptId = args[3] or dp.DefaultPaytable or 'normal'
    TriggerClientEvent('jp-slot:dyn:requestPlacePos', source, {
        propKey = propKey,
        charId = charId,
        paytableId = ptId,
    })
end, false)

RegisterNetEvent('jp-slot:dyn:placeAt', function(data)
    local src = source
    if not isAdmin(src) then
        return
    end
    data = type(data) == 'table' and data or {}
    local lic = licenseOf(src)
    local ok, err, machine = DynamicMachines.add({
        coords = data.coords,
        heading = data.heading,
        propKey = data.propKey,
        characterId = data.charId,
        paytableId = data.paytableId,
        minBet = (Config.DynamicPlacement and Config.DynamicPlacement.DefaultMinBet) or 100,
        maxBet = (Config.DynamicPlacement and Config.DynamicPlacement.DefaultMaxBet) or 10000,
        displayName = data.displayName,
    }, lic)
    if not ok then
        notifyError(src, '設置失敗: ' .. (err or 'unknown'))
        return
    end
    TriggerClientEvent('jp-slot:dyn:spawn', -1, machine)
    notify(src, ('台を設置しました id=%s'):format(machine.id))
end)

RegisterCommand('jpslotremove', function(source, args)
    if source == 0 then
        return
    end
    if not isAdmin(source) then
        notifyError(source, '権限がありません')
        return
    end
    if args[1] and args[1] ~= '' then
        local id = args[1]
        JpSlotForceLeaveOccupant(id, '台が撤去されました')
        if DynamicMachines.remove(id) then
            TriggerClientEvent('jp-slot:dyn:despawn', -1, id)
            notify(source, ('撤去しました: %s'):format(id))
        else
            notifyError(source, ('IDが見つかりません: %s'):format(id))
        end
        return
    end
    TriggerClientEvent('jp-slot:dyn:requestRemoveNearest', source)
end, false)

RegisterNetEvent('jp-slot:dyn:removeNearestAt', function(coords)
    local src = source
    if not isAdmin(src) then
        return
    end
    coords = type(coords) == 'table' and coords or {}
    local cx = tonumber(coords.x) or 0.0
    local cy = tonumber(coords.y) or 0.0
    local cz = tonumber(coords.z) or 0.0
    local rad = (Config.DynamicPlacement and Config.DynamicPlacement.SearchRadius) or 3.0
    local nearest = DynamicMachines.findNearest({ x = cx, y = cy, z = cz }, rad)
    if not nearest then
        notifyError(src, ('半径%.1fm以内に動的台がありません'):format(rad))
        return
    end
    local id = nearest.id
    JpSlotForceLeaveOccupant(id, '台が撤去されました')
    DynamicMachines.remove(id)
    TriggerClientEvent('jp-slot:dyn:despawn', -1, id)
    notify(source, ('撤去しました: %s'):format(id))
end)

RegisterCommand('jpslotmove', function(source, _args)
    if source == 0 then
        return
    end
    if not isAdmin(source) then
        notifyError(source, '権限がありません')
        return
    end
    TriggerClientEvent('jp-slot:dyn:requestMove', source)
end, false)

RegisterNetEvent('jp-slot:dyn:applyMove', function(data)
    local src = source
    if not isAdmin(src) then
        return
    end
    data = type(data) == 'table' and data or {}
    local pc = data.playerCoords
    local nc = data.newCoords
    local nh = tonumber(data.newHeading) or 0.0
    if type(pc) ~= 'table' or type(nc) ~= 'table' then
        return
    end
    local rad = (Config.DynamicPlacement and Config.DynamicPlacement.SearchRadius) or 3.0
    local nearest = DynamicMachines.findNearest(pc, rad)
    if not nearest then
        notifyError(src, '近くに動的台がありません')
        return
    end
    local ok, err = DynamicMachines.setPosition(nearest.id, nc, nh)
    if not ok then
        notifyError(src, '移動失敗: ' .. (err or ''))
        return
    end
    local fresh = DynamicMachines.get(nearest.id)
    TriggerClientEvent('jp-slot:dyn:respawn', -1, fresh)
    notify(source, ('移動しました: %s'):format(nearest.id))
end)

RegisterCommand('jpslotrotate', function(source, args)
    if source == 0 then
        return
    end
    if not isAdmin(source) then
        notifyError(source, '権限がありません')
        return
    end
    local deg = tonumber(args[1]) or 90.0
    TriggerClientEvent('jp-slot:dyn:requestRotate', source, { deg = deg })
end, false)

RegisterNetEvent('jp-slot:dyn:rotateAt', function(data)
    local src = source
    if not isAdmin(src) then
        return
    end
    data = type(data) == 'table' and data or {}
    local pc = data.playerCoords
    local deg = tonumber(data.deg) or 90.0
    if type(pc) ~= 'table' then
        return
    end
    local rad = (Config.DynamicPlacement and Config.DynamicPlacement.SearchRadius) or 3.0
    local nearest = DynamicMachines.findNearest(pc, rad)
    if not nearest then
        notifyError(src, '近くに動的台がありません')
        return
    end
    local ok, err = DynamicMachines.addHeading(nearest.id, deg)
    if not ok then
        notifyError(src, '回転失敗: ' .. (err or ''))
        return
    end
    local fresh = DynamicMachines.get(nearest.id)
    TriggerClientEvent('jp-slot:dyn:respawn', -1, fresh)
    notify(source, ('回転しました: %s'):format(nearest.id))
end)

RegisterCommand('jpslotedit', function(source, args)
    if source == 0 then
        return
    end
    if not isAdmin(source) then
        notifyError(source, '権限がありません')
        return
    end
    local id, field, value = args[1], args[2], args[3]
    if not id or not field or value == nil then
        notifyError(source, '使用法: /jpslotedit [id] [field] [value]')
        return
    end
    local allowed = {
        propKey = true,
        charId = true,
        characterId = true,
        paytableId = true,
        minBet = true,
        maxBet = true,
        displayName = true,
    }
    if not allowed[field] then
        notifyError(source, ('編集不可フィールド: %s'):format(field))
        return
    end
    if field == 'minBet' or field == 'maxBet' then
        value = tonumber(value)
        if not value then
            notifyError(source, '数値で指定してください')
            return
        end
    end
    local ok, err = DynamicMachines.update(id, field, value)
    if ok then
        local fresh = DynamicMachines.get(id)
        if fresh then
            TriggerClientEvent('jp-slot:dyn:respawn', -1, fresh)
        end
        notify(source, ('更新: %s.%s = %s'):format(id, field, tostring(value)))
    else
        notifyError(source, '更新失敗: ' .. (err or 'unknown'))
    end
end, false)

RegisterCommand('jpslotlist', function(source, _args)
    if source == 0 then
        return
    end
    if not isAdmin(source) then
        notifyError(source, '権限がありません')
        return
    end
    local list = DynamicMachines.getAll()
    if #list == 0 then
        notify(source, '動的台はありません')
        return
    end
    notify(source, ('動的台 %d 件:'):format(#list))
    for _, m in ipairs(list) do
        local c = m.coords
        local xs, ys, zs = '?', '?', '?'
        if c and c.x then
            xs = ('%.1f'):format(c.x)
            ys = ('%.1f'):format(c.y)
            zs = ('%.1f'):format(c.z)
        end
        notify(source,
            ('  %s @ (%s,%s,%s) prop=%s char=%s pt=%s'):format(m.id, xs, ys, zs, tostring(m.propKey),
                tostring(m.characterId), tostring(m.paytableId)))
    end
end, false)

RegisterCommand('jpslotinfo', function(source, _args)
    if source == 0 then
        return
    end
    if not isAdmin(source) then
        notifyError(source, '権限がありません')
        return
    end
    TriggerClientEvent('jp-slot:dyn:requestInfo', source)
end, false)

RegisterNetEvent('jp-slot:dyn:infoAt', function(coords)
    local src = source
    if not isAdmin(src) then
        return
    end
    coords = type(coords) == 'table' and coords or {}
    local rad = (Config.DynamicPlacement and Config.DynamicPlacement.SearchRadius) or 3.0
    local nearest = DynamicMachines.findNearest(coords, rad)
    if not nearest then
        notifyError(src, ('半径%.1fm以内に動的台がありません'):format(rad))
        return
    end
    local c = nearest.coords
    notify(src, ('ID: %s'):format(nearest.id))
    notify(src,
        ('座標: %.2f, %.2f, %.2f heading=%.1f'):format(c.x, c.y, c.z, tonumber(nearest.heading) or 0))
    notify(src,
        ('prop=%s char=%s pt=%s bet=%d-%d'):format(tostring(nearest.propKey), tostring(nearest.characterId),
            tostring(nearest.paytableId), tonumber(nearest.minBet) or 0, tonumber(nearest.maxBet) or 0))
end)

RegisterCommand('jpslotsave', function(source, _args)
    if source == 0 then
        return
    end
    if not isAdmin(source) then
        notifyError(source, '権限がありません')
        return
    end
    local list = DynamicMachines.getAll()
    local base = GetResourcePath(GetCurrentResourceName())
    if not base then
        notifyError(source, 'パス取得失敗')
        return
    end
    local name = ('dynamic_export_%d.lua'):format(os.time())
    local path = base .. '/server/logs/' .. name

    local lines = {}
    lines[#lines + 1] = '-- ' .. name
    lines[#lines + 1] = '-- Config.Machines にコピペする場合: id が既存と重複しないよう変更すること。'
    lines[#lines + 1] = '-- createdBy / createdAt は静的設定では不要のため省略。'
    lines[#lines + 1] = ''

    for i = 1, #list do
        local m = list[i]
        local c = m.coords or {}
        local pk = tostring(m.propKey or 'cherry_theme')
        local dn = m.displayName
        if not dn or dn == '' then
            dn = (m.id or ('dyn_' .. i)) .. '_name'
        end
        lines[#lines + 1] = '    {'
        lines[#lines + 1] = ("        id = '%s',"):format(string.gsub(tostring(m.id or ''), "'", "\\'"))
        lines[#lines + 1] =
            ('        coords = vector3(%.4f, %.4f, %.4f),'):format(c.x or 0, c.y or 0, c.z or 0)
        lines[#lines + 1] = ('        heading = %.2f,'):format(tonumber(m.heading) or 0)
        lines[#lines + 1] = ('        prop = Config.PropModels.%s,'):format(pk)
        lines[#lines + 1] = ("        characterId = '%s',"):format(string.gsub(tostring(m.characterId or 'luna'), "'", "\\'"))
        lines[#lines + 1] = ("        paytableId = '%s',"):format(string.gsub(tostring(m.paytableId or 'normal'), "'", "\\'"))
        lines[#lines + 1] = ('        minBet = %d,'):format(math.floor(tonumber(m.minBet) or 100))
        lines[#lines + 1] = ('        maxBet = %d,'):format(math.floor(tonumber(m.maxBet) or 10000))
        lines[#lines + 1] = '        themeOverride = nil,'
        lines[#lines + 1] = ("        displayName = '%s',"):format(string.gsub(tostring(dn), "'", "\\'"))
        lines[#lines + 1] = "        machineDescriptionLocaleKey = 'machine_01_desc',"
        lines[#lines + 1] = '    },'
        lines[#lines + 1] = ''
    end

    if #list == 0 then
        lines[#lines + 1] = '-- 動的台が0件です。'
    end

    pcall(function()
        local f = io.open(path, 'w')
        if f then
            for _, line in ipairs(lines) do
                f:write(line .. '\n')
            end
            f:close()
        end
    end)
    notify(source, ('書き出し: server/logs/%s'):format(name))
    print(('[jp-slot] jpslotsave -> %s'):format(path))
end, false)

RegisterCommand('jpslotreload', function(source, _args)
    if source == 0 then
        DynamicMachines.load()
        TriggerClientEvent('jp-slot:dyn:syncAll', -1, DynamicMachines.getAll())
        print('[jp-slot] jpslotreload (console)')
        return
    end
    if not isAdmin(source) then
        notifyError(source, '権限がありません')
        return
    end
    DynamicMachines.load()
    TriggerClientEvent('jp-slot:dyn:syncAll', -1, DynamicMachines.getAll())
    notify(source, '動的台を KVS から再読込しました')
end, false)

RegisterNetEvent('jp-slot:dyn:requestSync', function()
    local src = source
    TriggerClientEvent('jp-slot:dyn:syncAll', src, DynamicMachines.getAll())
end)
