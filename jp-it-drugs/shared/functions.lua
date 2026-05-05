-- ┌─────────────────────────────────────────────┐
-- │ _____                 _   _                 │
-- │|  ___|   _ _ __   ___| |_(_) ___  _ __  ___ │
-- │| |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|│
-- │|  _|| |_| | | | | (__| |_| | (_) | | | \__ \│
-- │|_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/│
-- └─────────────────────────────────────────────┘

function SendPoliceAlert(coords)
    -- ここに独自の警察通報処理を追加
    local message = 'Drug Dealer spotted at '..coords
    TriggerEvent('chat:addMessage', {
        args = {message}
    })
end

function ShowNotification(source, message, type)
    -- Bridge.Functions.Notify はフレームワーク標準の通知。別システムに差し替え可
    if source ~= nil then -- サーバーからプレイヤーへ
        if type == 'Error' then
            exports.it_bridge:SendNotification(source, 'it-drugs', message, 5000, "Error", true)
        elseif type == 'Success' then
            exports.it_bridge:SendNotification(source, 'it-drugs', message, 5000, "Success", true)
        else
            exports.it_bridge:SendNotification(source, 'it-drugs', message, 5000, "Info", false)
        end
    else -- クライアント自身へ
        if type == 'Error' then
            exports.it_bridge:SendNotification('it-drugs', message, 5000, "Error", true)
        elseif type == 'Success' then
            exports.it_bridge:SendNotification('it-drugs', message, 5000, "Success", true)
        else
            exports.it_bridge:SendNotification('it-drugs', message, 5000, "Info", false)
        end
    end
end

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoord())
    local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)
    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov
    if onScreen then
        SetTextScale(0.0, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry('STRING')
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end


--- プログレスバーを表示する
---@param progressBarData table
---@return boolean success
function ShowProgressBar(progressBarData)

    if lib.progressBar({
        duration = progressBarData.duration,
        label = progressBarData.label,
        useWhileDead = progressBarData.useWhileDead,
        disable = progressBarData.disable,
        canCancel = progressBarData.canCancel,
        controlDisables = progressBarData.controlDisables,
        anim = progressBarData.anim,
    }) then
        return true
    else
        return false
    end
end

--- プレイヤーの食料メタを回復（フレームワーク別に実装）
function FoodRegen()
    -- QBCore 例
    -- TriggerEvent("QBCore:Server:SetMetaData", "hunger", 40000)
    --TriggerEvent("QBCore:Server:SetMetaData", "thirst", 20000)

    -- ESX 例
    -- TriggerEvent('esx_status:set', 'hunger', 1000000)
    -- TriggerEvent('esx_status:set', 'thirst', 1000000)
end
