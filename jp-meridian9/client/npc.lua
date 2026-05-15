-- ============================================================
-- ヴェガ NPC スポーンと管理
-- ============================================================

MRD9 = MRD9 or {}

local vegaPed = nil
local vegaBlip = nil

---@param b integer|nil
---@return nil
local function removeBlipSafe(b)
    if b and DoesBlipExist(b) then
        RemoveBlip(b)
    end
    return nil
end

local function spawnVega()
    local modelName = Config.NPC and Config.NPC.model or 's_m_m_highsec_01'
    local model = GetHashKey(modelName)
    if not IsModelInCdimage(model) or not IsModelValid(model) then
        MRD9.Log('Vega NPC: invalid model %s', tostring(modelName))
        return
    end

    RequestModel(model)
    local deadline = GetGameTimer() + 15000
    while not HasModelLoaded(model) do
        if GetGameTimer() > deadline then
            MRD9.Log('Vega NPC: model load timeout %s', tostring(modelName))
            return
        end
        Wait(10)
    end

    local c = Config.NPC.coords
    local z = c.z - 1.0
    vegaPed = CreatePed(4, model, c.x, c.y, z, c.w, false, true)
    if not vegaPed or vegaPed == 0 then
        SetModelAsNoLongerNeeded(model)
        MRD9.Log('Vega NPC: CreatePed failed')
        return
    end

    SetEntityAsMissionEntity(vegaPed, true, true)
    SetEntityInvincible(vegaPed, Config.NPC.invincible == true)
    FreezeEntityPosition(vegaPed, Config.NPC.freeze == true)
    SetBlockingOfNonTemporaryEvents(vegaPed, Config.NPC.blockEvents ~= false)

    local scenario = Config.NPC.scenario
    if type(scenario) == 'string' and scenario ~= '' then
        TaskStartScenarioInPlace(vegaPed, scenario, 0, true)
    end

    SetModelAsNoLongerNeeded(model)

    local ok, err = pcall(function()
        exports.ox_target:addLocalEntity(vegaPed, {
            {
                name = 'jp-meridian9:talk_to_vega',
                icon = 'fas fa-user-tie',
                label = _('vega_target_label'),
                distance = Config.NPC.targetDistance or 2.5,
                onSelect = function()
                    TriggerEvent('jp-meridian9:client:openDialogue')
                end,
            },
        })
    end)
    if not ok then
        MRD9.Log('Vega NPC: ox_target addLocalEntity failed: %s', tostring(err))
    end

    local blipCfg = Config.NPC.blip
    if blipCfg and blipCfg.enabled then
        vegaBlip = AddBlipForCoord(c.x, c.y, c.z)
        SetBlipSprite(vegaBlip, blipCfg.sprite or 280)
        SetBlipColour(vegaBlip, blipCfg.color or 4)
        SetBlipScale(vegaBlip, blipCfg.scale or 0.8)
        SetBlipAsShortRange(vegaBlip, blipCfg.shortRange ~= false)
        BeginTextCommandSetBlipName('STRING')
        local labelKey = blipCfg.labelKey
        local labelText = (labelKey and type(labelKey) == 'string' and _(labelKey)) or blipCfg.label or 'Vega & Associates'
        AddTextComponentSubstringPlayerName(labelText)
        EndTextCommandSetBlipName(vegaBlip)
    end

    MRD9.Log('Vega NPC spawned at %.2f, %.2f, %.2f', c.x, c.y, c.z)
end

local function despawnVega()
    if vegaPed and DoesEntityExist(vegaPed) then
        pcall(function()
            exports.ox_target:removeLocalEntity(vegaPed)
        end)
        DeleteEntity(vegaPed)
        vegaPed = nil
    end
    vegaBlip = removeBlipSafe(vegaBlip)
end

CreateThread(function()
    Wait(1000)
    spawnVega()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    despawnVega()
end)
