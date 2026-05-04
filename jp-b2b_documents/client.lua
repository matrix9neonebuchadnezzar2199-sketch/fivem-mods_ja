local currentCtx = nil
local spawnedPeds = {}
local pointsNoTarget = {}

local function openUI(payload)
    CreateThread(function()
        Wait(150)

        currentCtx = {
            slot = payload.slot,
            instanceId = payload.instanceId,
            itemName = payload.itemName,
        }

        local freshMetadata = lib.callback.await('b2b_documents:getFreshMetadata', 200, currentCtx)
        local metadata = freshMetadata or payload.metadata or {}

        local docId = metadata.docId
        if docId == "nil" then docId = nil end

        if Config.UseAnimation then
            TaskStartScenarioInPlace(cache.ped, "PROP_HUMAN_PARKING_METER", 0, true)
        end

        local content = ""
        if docId then
            content = lib.callback.await('b2b_documents:getContent', 500, docId)
        end

        SendNUIMessage({
            action = "open",
            content = content,
            title = metadata.title or T('ui_untitled'),
            locked = metadata.locked or false,
            lang = Config.Locale,
            itemName = currentCtx.itemName,
            locale = {
                ui_title_placeholder = T('ui_title_placeholder'),
                ui_btn_save = T('ui_btn_save'),
                ui_btn_lock = T('ui_btn_lock'),
                ui_btn_duplicate = T('ui_btn_duplicate'),
                ui_btn_close = T('ui_btn_close'),
                ui_modal_dup_title = T('ui_modal_dup_title'),
                ui_modal_dup_desc = T('ui_modal_dup_desc'),
                ui_btn_cancel = T('ui_btn_cancel'),
                ui_btn_copy = T('ui_btn_copy'),
                ui_size_normal = T('ui_size_normal'),
                ui_size_small = T('ui_size_small'),
                ui_size_large = T('ui_size_large'),
                ui_size_title = T('ui_size_title'),
                ui_untitled = T('ui_untitled'),
            }
        })

        SetNuiFocus(true, true)
    end)
end

function usePaper(data)
    openUI({
        slot = data.slot,
        instanceId = nil,
        itemName = data.name or (data.item and data.item.name),
        metadata = data.metadata or (data.item and data.item.metadata),
    })
end
exports('usePaper', usePaper)

RegisterNetEvent('b2b_documents:client:openUI', function(payload)
    openUI(payload)
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    currentCtx = nil
    ClearPedTasks(cache.ped)
    cb('ok')
end)

RegisterNUICallback('doAction', function(data, cb)
    local success, _docId, newInstanceId = lib.callback.await('b2b_documents:handleAction', 1000, data, currentCtx)
    if success and newInstanceId and currentCtx then
        currentCtx.instanceId = newInstanceId
    end
    cb(success)
end)

CreateThread(function()
    for i, v in pairs(Config.DistributionPoints) do
        if v.usePed and v.pedModel ~= "" then
            local model = GetHashKey(v.pedModel)
            RequestModel(model)
            local timeout = 0
            while not HasModelLoaded(model) do
                Wait(100)
                timeout = timeout + 100
                if timeout >= 5000 then break end
            end

            if HasModelLoaded(model) then
                local ped = CreatePed(4, model, v.coords.x, v.coords.y, v.coords.z - 1.0, v.heading, false, true)
                SetEntityInvincible(ped, true)
                SetBlockingOfNonTemporaryEvents(ped, true)
                FreezeEntityPosition(ped, true)
                SetEntityCanBeDamaged(ped, false)
                table.insert(spawnedPeds, ped)
            end
            SetModelAsNoLongerNeeded(model)
        end

        if Config.UseOxTarget and GetResourceState('ox_target') == 'started' then
            exports.ox_target:addSphereZone({
                coords = v.coords,
                radius = 1.5,
                debug = false,
                options = {
                    {
                        name = 'distrib_point_' .. i,
                        icon = v.targetIcon,
                        label = v.targetLabel,
                        distance = 3.0,
                        onSelect = function()
                            TriggerServerEvent('b2b_documents:server:requestPaper')
                        end
                    }
                }
            })
        elseif GetResourceState('qb-target') == 'started' then
            local ok = pcall(function()
                exports['qb-target']:AddCircleZone('b2b_distrib_' .. i, v.coords, 1.5, {
                    name = 'b2b_distrib_' .. i,
                    useZ = true,
                }, {
                    options = { {
                        type = 'client',
                        icon = v.targetIcon,
                        label = v.targetLabel,
                        action = function()
                            TriggerServerEvent('b2b_documents:server:requestPaper')
                        end,
                    } },
                    distance = 3.0,
                })
            end)
            if not ok then
                pointsNoTarget[#pointsNoTarget + 1] = v
            end
        else
            pointsNoTarget[#pointsNoTarget + 1] = v
        end
    end

    if #pointsNoTarget == 0 then return end

    CreateThread(function()
        while true do
            local sleep = 800
            local pcoords = GetEntityCoords(cache.ped)
            local nearest = nil
            local best = 2.5

            for _, pt in ipairs(pointsNoTarget) do
                local d = #(pcoords - pt.coords)
                if d < best then
                    best = d
                    nearest = pt
                end
            end

            if nearest and best < 2.5 then
                sleep = 0
                lib.showTextUI(('[E] %s'):format(nearest.targetLabel))
                if IsControlJustPressed(0, 38) then
                    TriggerServerEvent('b2b_documents:server:requestPaper')
                    Wait(750)
                end
            else
                lib.hideTextUI()
            end
            Wait(sleep)
        end
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)
