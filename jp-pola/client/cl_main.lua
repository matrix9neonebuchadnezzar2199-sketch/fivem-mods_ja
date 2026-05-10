local QBCore = exports['qb-core']:GetCoreObject()

local camera = false
local photo = false
local fov_max = 80.0
local fov_min = 5.0 -- max zoom level (smaller fov is more zoom)
local zoomspeed = 10.0 -- camera zoom speed
local speed_lr = 8.0 -- speed by which the camera pans left-right
local speed_ud = 8.0 -- speed by which the camera pans up-down
local fov = (fov_max+fov_min)*0.5

local cameraprop = nil
local photoprop = nil

local Functions = exports[GetCurrentResourceName()]

local function grabUploadDetails()
    local newEvent = nil
    local p = promise.new()
    local Key = Functions.Key()
    local event = ("ps-camera:grabbed%s"):format(Key)
    RegisterNetEvent(event)
    newEvent = AddEventHandler(event, function(hook)
        newEvent = RemoveEventHandler(newEvent)
        p:resolve(hook)
    end)
    
    if Config.UseFivemerr == false then
        TriggerServerEvent("ps-camera:requestWebhook", Key)
    else
        TriggerServerEvent("ps-camera:requestFivemerrToken", Key)
    end
    return Citizen.Await(p)
end

RegisterNetEvent("ps-debug", function()
    if Config and Config.Debug then
        print(L('debug_cheating', GetCurrentResourceName(), tostring(source)))
    end
end)

-- Discord サーバー経由アップロード完了（jp-pola:discordB64Upload の結果）
RegisterNetEvent('jp-pola:relayDiscordResult', function(ok, payload)
    if not ok then
        print(('[%s] [ERROR] Discord サーバーアップロード失敗: %s'):format(GetCurrentResourceName(), tostring(payload):sub(1, 400)))
        camera = false
        local ped = PlayerPedId()
        ClearPedTasks(ped)
        if cameraprop and DoesEntityExist(cameraprop) then DeleteEntity(cameraprop) end
        SendNUIMessage({ action = 'hideOverlay' })
        return
    end
    camera = false
    local ped = PlayerPedId()
    if cameraprop and DoesEntityExist(cameraprop) then DeleteEntity(cameraprop) end
    ClearPedTasks(ped)
    TriggerServerEvent('ps-camera:CreatePhoto', json.encode(payload))
    SendNUIMessage({ action = 'SavePic', pic = json.encode(payload) })
    SendNUIMessage({ action = 'hideOverlay' })
end)

local function HideHUDThisFrame()
    HideHelpTextThisFrame()
    HideHudAndRadarThisFrame()
    HideHudComponentThisFrame(1)
    HideHudComponentThisFrame(2)
    HideHudComponentThisFrame(3)
    HideHudComponentThisFrame(4)
    HideHudComponentThisFrame(6)
    HideHudComponentThisFrame(7)
    HideHudComponentThisFrame(8)
    HideHudComponentThisFrame(9)
    HideHudComponentThisFrame(13)
    HideHudComponentThisFrame(11)
    HideHudComponentThisFrame(12)
    HideHudComponentThisFrame(15)
    HideHudComponentThisFrame(18)
    HideHudComponentThisFrame(19)
end

local function CheckInputRotation(cam, zoomvalue)
    local rightAxisX = GetDisabledControlNormal(0, 220)
    local rightAxisY = GetDisabledControlNormal(0, 221)
    local rotation = GetCamRot(cam, 2)
    if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
        local new_z = rotation.z + rightAxisX*-1.0*(speed_ud)*(zoomvalue+0.1)
        local new_x = math.max(math.min(20.0, rotation.x + rightAxisY*-1.0*(speed_lr)*(zoomvalue+0.1)), -89.5)
        SetCamRot(cam, new_x, 0.0, new_z, 2)
        -- Moves the entities body if they are not in a vehicle (else the whole vehicle will rotate as they look around :P)
        if not IsPedSittingInAnyVehicle(PlayerPedId()) then
            SetEntityHeading(PlayerPedId(), new_z)
        end
    end
end

local function HandleZoom(cam)
    local lPed = PlayerPedId()
    if not IsPedSittingInAnyVehicle(lPed) then
        if IsControlJustPressed(0,241) then
            fov = math.max(fov - zoomspeed, fov_min)
        end
        if IsControlJustPressed(0,242) then
            fov = math.min(fov + zoomspeed, fov_max)
        end
        local current_fov = GetCamFov(cam)
        if math.abs(fov-current_fov) < 0.1 then
            fov = current_fov
        end
        SetCamFov(cam, current_fov + (fov - current_fov)*0.05)
    else
        if IsControlJustPressed(0,17) then
            fov = math.max(fov - zoomspeed, fov_min)
        end
        if IsControlJustPressed(0,16) then
            fov = math.min(fov + zoomspeed, fov_max)
        end
        local current_fov = GetCamFov(cam)
        if math.abs(fov-current_fov) < 0.1 then
            fov = current_fov
        end
        SetCamFov(cam, current_fov + (fov - current_fov)*0.05)
    end
end

local function SharedRequestAnimDict(animDict, cb)
	if not HasAnimDictLoaded(animDict) then
		RequestAnimDict(animDict)

		while not HasAnimDictLoaded(animDict) do
			Citizen.Wait(1)
		end
	end
	if cb ~= nil then
		cb()
	end
end

local function LoadPropDict(model)
    while not HasModelLoaded(GetHashKey(model)) do
        RequestModel(GetHashKey(model))
        Wait(10)
    end
end

local function GetStreetNames()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local streetName, crossingRoad = GetStreetNameAtCoord(playerCoords.x, playerCoords.y, playerCoords.z)
    local streetNameText = GetStreetNameFromHashKey(streetName)
    local crossingRoadText = ""

    if crossingRoad ~= 0 then
        crossingRoadText = GetStreetNameFromHashKey(crossingRoad)
    end

    return streetNameText, crossingRoadText
end

function SetLocation()
    local streetName, crossingRoad = GetStreetNames()

    if crossingRoad ~= "" then
        SendNUIMessage({action = "SetLocation", location = streetName .. " & " .. crossingRoad})
    else
        SendNUIMessage({action = "SetLocation", location = streetName})
    end
end

local doFlash = false
local function FlashLightEffect()
    local ped = GetPlayerPed(-1)
    local pos = GetEntityCoords(ped)
    local lightPos = vector3(pos.x, pos.y, pos.z + 1.1)
    local lightHandle = nil
    CreateThread(function()
        local endTime = GetGameTimer() + 150
        while endTime > GetGameTimer() do
            lightHandle = DrawLightWithRangeAndShadow(lightPos.x, lightPos.y, lightPos.z, 15, 15, 15, 50.0, 10.0, 0.5, true)
            Wait(0)
        end
        if lightHandle ~= nil then
            lightHandle = nil
        end
    end)
end

function CameraLoop()
    local ped = PlayerPedId()

    SharedRequestAnimDict("amb@world_human_paparazzi@male@base", function()
        TaskPlayAnim(ped, "amb@world_human_paparazzi@male@base", "base", 2.0, 2.0, -1, 1, 0, false, false, false)
    end)

    local x, y, z = table.unpack(GetEntityCoords(ped))

    if not HasModelLoaded("ps_camera") then
        LoadPropDict("ps_camera")
    end

    cameraprop = CreateObject(GetHashKey("ps_camera"), x, y, z + 0.2, true, true, true)
    AttachEntityToEntity(cameraprop, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded("ps_camera")

    CreateThread(function()
        local lPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(lPed)
        -- Discord サーバー経由アップロード時は Webhook URL をクライアントに渡さない（grab 不要）
        local uploadHookOrSecret
        if Config.UseFivemerr == false and Config.DiscordUploadViaServer then
            uploadHookOrSecret = ''
        else
            uploadHookOrSecret = grabUploadDetails()
        end
        Wait(500)

        SetTimecycleModifier("default")
        SetTimecycleModifierStrength(0.3)

        local cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
        AttachCamToEntity(cam, lPed, 0.0, 1.0, 0.8, true)
        SetCamRot(cam, 0.0, 0.0, GetEntityHeading(lPed), 2)
        SetCamFov(cam, fov)
        RenderScriptCams(true, false, 0, true, false)

        while camera and not IsEntityDead(lPed) and (GetVehiclePedIsIn(lPed) == vehicle) do
            if doFlash then
                SendNUIMessage({action = "toggleFlash", status = true})
            else
                SendNUIMessage({action = "toggleFlash", status = false})
            end
            if IsControlJustPressed(0, 177) then
                camera = false
                PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                ClearPedTasks(lPed)
                if cameraprop then DeleteEntity(cameraprop) end
            elseif IsControlJustPressed(0, 49) then
                doFlash = not doFlash
            elseif IsControlJustPressed(1, 176) then
                if doFlash then
                    FlashLightEffect()
                    Wait(100)
                end
                PlaySoundFrontend(-1, "Camera_Shoot", "Phone_Soundset_Franklin", false)

                if Config.UseFivemerr == false and Config.DiscordUploadViaServer then
                    -- サーバー経由 Discord 投稿（CEF→Discord の 40333 / Cloudflare 回避）
                    exports['screenshot-basic']:requestScreenshot({ encoding = 'png' }, function(dataUri)
                        if type(dataUri) ~= 'string' or not dataUri:find('^data:image', 1, false) then
                            print(('[%s] [ERROR] requestScreenshot の戻りが不正'):format(GetCurrentResourceName()))
                            camera = false
                            if cameraprop then DeleteEntity(cameraprop) end
                            ClearPedTasks(lPed)
                            SendNUIMessage({ action = 'hideOverlay' })
                            return
                        end
                        local b64 = dataUri:match('base64,(.+)$')
                        local maxB64 = (Config.DiscordRelayMaxBase64Chars or (40 * 1024 * 1024))
                        if not b64 or #b64 < 32 or #b64 > maxB64 then
                            print(('[%s] [ERROR] base64 長さが上限を超えたか短すぎます len=%s max=%s（config.lua の DiscordRelayMaxBase64Chars で拡張可）'):format(
                                GetCurrentResourceName(), tostring(b64 and #b64), tostring(maxB64)))
                            camera = false
                            if cameraprop then DeleteEntity(cameraprop) end
                            ClearPedTasks(lPed)
                            SendNUIMessage({ action = 'hideOverlay' })
                            return
                        end
                        if Config and Config.Debug then
                            print(('[%s] [DEBUG] Discord サーバー経由アップロード開始 base64 len=%d'):format(GetCurrentResourceName(), #b64))
                        end
                        -- bps を大きめに（高解像度 PNG の latent 転送がタイムアウトしにくい）
                        TriggerLatentServerEvent('jp-pola:discordB64Upload', 100000000, b64)
                    end)
                elseif Config.UseFivemerr == false then
                    if Config and Config.Debug then
                        print(('[%s] [DEBUG] webhook URL 先頭20文字=%s len=%d'):format(GetCurrentResourceName(), tostring(uploadHookOrSecret):sub(1, 20), #tostring(uploadHookOrSecret)))
                    end
                    -- Discord は multipart のファイル名を files[0] にする。files[] は非推奨／エラーになり得る。
                    -- encoding + headers は screenshot-basic の request 仕様に合わせる。
                    exports['screenshot-basic']:requestScreenshotUpload(tostring(uploadHookOrSecret), 'files[0]', {
                        headers = {},
                        encoding = 'png',
                    }, function(data)
                        if Config and Config.Debug then
                            print(('[%s] [DEBUG] screenshot-basic コールバック発火'):format(GetCurrentResourceName()))
                            print(('[%s] [DEBUG] 生レスポンス（先頭500字）= %s'):format(GetCurrentResourceName(), tostring(data):sub(1, 500)))
                        end
                        local ok, image = pcall(json.decode, data)
                        if not ok or type(image) ~= 'table' then
                            print(('[%s] [ERROR] レスポンス JSON パース失敗: %s'):format(GetCurrentResourceName(), tostring(image)))
                            camera = false
                            if cameraprop then DeleteEntity(cameraprop) end
                            ClearPedTasks(lPed)
                            SendNUIMessage({action = "hideOverlay"})
                            return
                        end
                        if not image.attachments or not image.attachments[1] then
                            print(('[%s] [ERROR] Discord 応答に attachments なし。webhook URL が無効か、権限/制限の可能性。応答 = %s'):format(GetCurrentResourceName(), tostring(data):sub(1, 500)))
                            camera = false
                            if cameraprop then DeleteEntity(cameraprop) end
                            ClearPedTasks(lPed)
                            SendNUIMessage({action = "hideOverlay"})
                            return
                        end
                        camera = false
                        if cameraprop then DeleteEntity(cameraprop) end
                        ClearPedTasks(lPed)
                        if Config and Config.Debug then
                            print(('[%s] [DEBUG] proxy_url=%s → CreatePhoto 送信'):format(GetCurrentResourceName(), tostring(image.attachments[1].proxy_url)))
                        end
                        TriggerServerEvent("ps-camera:CreatePhoto", json.encode(image.attachments[1].proxy_url))
                        SendNUIMessage({action = "SavePic", pic = json.encode(image.attachments[1].proxy_url)})
                        SendNUIMessage({action = "hideOverlay"})
                    end)
                else
                    exports['screenshot-basic']:requestScreenshotUpload("https://api.fivemerr.com/v1/media/images", "file", {
                        headers = {
                            Authorization = tostring(uploadHookOrSecret)
                        },
                        encoding = 'png'
                    }, function(data)
                        local image = json.decode(data)
                        camera = false
                        if cameraprop then DeleteEntity(cameraprop) end
                        ClearPedTasks(lPed)
                        local link = (image and image.url) or 'invalid_url'
                        TriggerServerEvent("ps-camera:CreatePhoto", json.encode(link))
                        SendNUIMessage({action = "SavePic", pic = json.encode(link)})
                        SendNUIMessage({action = "hideOverlay"})
                    end)
                end
                Wait(100) -- You can adjust the timing if needed
                ClearTimecycleModifier()
            end

            local zoomvalue = (1.0 / (fov_max - fov_min)) * (fov - fov_min)
            CheckInputRotation(cam, zoomvalue)
            HandleZoom(cam)
            HideHUDThisFrame()
            Wait(0)
        end
        camera = false
        ClearTimecycleModifier()
        fov = (fov_max + fov_min) * 0.5
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(cam, false)
        SetNightvision(false)
        SetSeethrough(false)
        SendNUIMessage({action = "hideOverlay"})
    end)
end

RegisterNetEvent("ps-camera:getStreetName", function(url, coords)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)

    TriggerServerEvent("ps-camera:savePhoto", url, streetName)
end)


RegisterNetEvent("ps-camera:usePhoto", function(url, location)
    photo = not photo

    if photo then
        SetNuiFocus(true, true);
        SendNUIMessage({action = "openPhoto", image = url, location = location})

        local ped = PlayerPedId()
        SharedRequestAnimDict("amb@world_human_tourist_map@male@base", function()
            TaskPlayAnim(ped, "amb@world_human_tourist_map@male@base", "base", 2.0, 2.0, -1, 1, 0, false, false, false)
        end)

        local coords = GetEntityCoords(ped)

        if not HasModelLoaded("prop_cs_planning_photo") then
            LoadPropDict("prop_cs_planning_photo")
        end

        photoprop = CreateObject(`prop_cs_planning_photo`, coords.x, coords.y, coords.z+0.2,  true,  true, true)
        AttachEntityToEntity(photoprop, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
        SetModelAsNoLongerNeeded("prop_cs_planning_photo")
    end
end)


RegisterNUICallback("close", function()
    SetNuiFocus(false, false)
    photo = false

    if photoprop then
        DeleteEntity(photoprop)
    end

    ClearPedTasks(PlayerPedId())
end)

RegisterNetEvent('ps-camera:useCamera', function()
    camera = not camera

    if camera then
        SendNUIMessage({action = "showOverlay"})

        CameraLoop()
    else
        local playerPed = PlayerPedId()
        ClearPedTasks(playerPed)
        if cameraprop then
            DeleteEntity(cameraprop)
        end
        SendNUIMessage({action = "hideOverlay"})
    end
end)

-- リソース停止時のクリーンアップ（fivem-lua / fivem-nui ルール準拠）
-- カメラ／写真プロップ、NUI フォーカス、タイムサイクル、スクリプトカメラを必ず元に戻す。
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end

    SetNuiFocus(false, false)

    if cameraprop and DoesEntityExist(cameraprop) then
        DeleteEntity(cameraprop)
    end
    if photoprop and DoesEntityExist(photoprop) then
        DeleteEntity(photoprop)
    end

    ClearTimecycleModifier()
    RenderScriptCams(false, false, 0, true, false)

    local ped = PlayerPedId()
    if ped ~= 0 then
        ClearPedTasks(ped)
    end

    camera = false
    photo = false
end)
