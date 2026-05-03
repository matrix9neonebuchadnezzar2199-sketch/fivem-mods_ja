local function loadPtfx(dict)
    if not HasNamedPtfxAssetLoaded(dict) then
        RequestNamedPtfxAsset(dict)
        local t = GetGameTimer() + 5000
        while not HasNamedPtfxAssetLoaded(dict) and GetGameTimer() < t do
            Wait(10)
        end
    end
end

---@param fxType string
---@param coords vector3
function PlayFx(fxType, coords)
    local cfg
    if fxType == 'spawn' then
        cfg = Config.Spawn
    elseif fxType == 'destruct' then
        cfg = Config.SelfDestruct
    elseif fxType == 'shotdown' then
        cfg = Config.ShotDown
    else
        return
    end

    loadPtfx(cfg.ParticleDict)
    UseParticleFxAssetNextCall(cfg.ParticleDict)
    StartParticleFxNonLoopedAtCoord(
        cfg.ParticleName,
        coords.x,
        coords.y,
        coords.z,
        0.0,
        0.0,
        0.0,
        cfg.ParticleScale or 1.0,
        false,
        false,
        false
    )
    if cfg.SoundName and cfg.SoundSet then
        PlaySoundFromCoord(-1, cfg.SoundName, coords.x, coords.y, coords.z, cfg.SoundSet, false, 0, false)
    end
end

RegisterNetEvent('jp-sentinel:client:playFx', function(data)
    if type(data) ~= 'table' or type(data.coords) ~= 'table' then
        return
    end
    local c = data.coords
    PlayFx(data.fxType, vector3(tonumber(c.x) or 0.0, tonumber(c.y) or 0.0, tonumber(c.z) or 0.0))
end)

RegisterNetEvent('jp-sentinel:client:notify', function(msg, ntype)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(tostring(msg))
    EndTextCommandThefeedPostTicker(false, true)
end)

AddEventHandler('jp-sentinel:client:notifyLocal', function(msg, _)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(tostring(msg))
    EndTextCommandThefeedPostTicker(false, true)
end)
