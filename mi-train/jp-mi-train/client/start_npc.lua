-- jp-mi-train クライアント側: 受注 NPC

---@class StartNpcModule
local M = {}

---@type integer|nil
M.ped = nil

---@type integer|nil
M.blip = nil

---@param msg string
local function log(msg)
    if Config.Debug then
        print(('[%s/npc] %s'):format(GetCurrentResourceName(), msg))
    end
end

local function HasOxTarget()
    return GetResourceState('ox_target') == 'started'
end

---@return boolean
local function IsHeistActive()
    if _G.MiTrainClient and _G.MiTrainClient.IsHeistActive then
        return _G.MiTrainClient.IsHeistActive()
    end
    return false
end

local function BuildTargetOptions()
    local t = Config.StartNpc.target
    return {
        {
            name = 'jp-mi-train_start',
            label = t.label,
            icon = t.icon,
            distance = 2.0,
            canInteract = function()
                return not IsHeistActive()
            end,
            onSelect = function()
                TriggerServerEvent('jp-mi-train:requestStart')
            end,
        },
        {
            name = 'jp-mi-train_reset',
            label = t.resetLabel or 'ヘイストをリセット（中断）',
            icon = t.resetIcon or 'fas fa-rotate-left',
            distance = 2.0,
            canInteract = function()
                return IsHeistActive()
            end,
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'MI Train',
                    content = '進行中のヘイストを中断し、列車と Blip を片付けます。よろしいですか？',
                    centered = true,
                    cancel = true,
                })
                if confirm == 'confirm' then
                    TriggerServerEvent('jp-mi-train:requestReset')
                end
            end,
        },
    }
end

function M.Spawn()
    if M.ped and DoesEntityExist(M.ped) then return end

    local model = joaat(Config.StartNpc.model)
    lib.requestModel(model, 5000)

    local c = Config.StartNpc.coords
    local ped = CreatePed(4, model, c.x, c.y, c.z, c.w, false, true)
    if not ped or ped == 0 then
        log('ERROR: failed to create start NPC')
        SetModelAsNoLongerNeeded(model)
        return
    end

    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedDiesWhenInjured(ped, false)

    if Config.StartNpc.scenario then
        TaskStartScenarioInPlace(ped, Config.StartNpc.scenario, 0, true)
    end

    M.ped = ped
    SetModelAsNoLongerNeeded(model)

    if HasOxTarget() then
        exports.ox_target:addLocalEntity(ped, BuildTargetOptions())
    else
        log('WARNING: ox_target not started. Using fallback E-prompt thread.')
        Citizen.CreateThread(function()
            while M.ped and DoesEntityExist(M.ped) do
                local sleep = 1000
                local p = PlayerPedId()
                local pc = GetEntityCoords(p)
                local nc = GetEntityCoords(M.ped)
                if #(pc - nc) < 2.5 then
                    sleep = 0
                    if IsHeistActive() then
                        lib.showTextUI('~INPUT_CONTEXT~ ヘイストをリセット', { position = 'top-center' })
                        if IsControlJustPressed(0, 38) then
                            lib.hideTextUI()
                            TriggerServerEvent('jp-mi-train:requestReset')
                        end
                    else
                        lib.showTextUI('~INPUT_CONTEXT~ ヘイストの依頼を受ける', { position = 'top-center' })
                        if IsControlJustPressed(0, 38) then
                            lib.hideTextUI()
                            TriggerServerEvent('jp-mi-train:requestStart')
                        end
                    end
                else
                    lib.hideTextUI()
                end
                Wait(sleep)
            end
        end)
    end

    if Config.StartNpc.blip then
        local b = Config.StartNpc.blip
        local blip = AddBlipForCoord(c.x, c.y, c.z)
        SetBlipSprite(blip, b.sprite)
        SetBlipColour(blip, b.color)
        SetBlipScale(blip, b.scale)
        SetBlipAsShortRange(blip, b.shortRange)
        SetBlipDisplay(blip, 4)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(b.label)
        EndTextCommandSetBlipName(blip)
        M.blip = blip
    end

    log(('start NPC spawned at (%.1f, %.1f, %.1f)'):format(c.x, c.y, c.z))
end

function M.Cleanup()
    if M.blip and DoesBlipExist(M.blip) then
        RemoveBlip(M.blip)
        M.blip = nil
    end
    if M.ped and DoesEntityExist(M.ped) then
        if HasOxTarget() then
            pcall(function() exports.ox_target:removeLocalEntity(M.ped) end)
        end
        DeleteEntity(M.ped)
        M.ped = nil
    end
end

_G.MiTrainNpc = M
