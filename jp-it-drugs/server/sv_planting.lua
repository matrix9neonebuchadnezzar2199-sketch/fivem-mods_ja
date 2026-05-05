math = lib.math
---@type table 登録済み植物の一覧
local plants = {}

---@section Plant クラス
-- 植物オブジェクトとマップ上プロップ・DB を扱う

--- @class Plant : OxClass
--- @field id string
Plant = lib.class('Plant')

--- コンストラクタ
---@param id string
---@param plantData table
function Plant:constructor(id, plantData)

    if Config.Debug then lib.print.info('[Plant:constructor] - Start constructing plant with ID:', id) end

    ---@type string 植物ID
    self.id = id
    ---@type number | nil 植物エンティティ
    self.entity = nil
    ---@type number | nil ネットワークID
    self.netId = nil
    ---@type vector3 座標
    self.coords = plantData.coords
    ---@type number ルーティングバケット（dimension）
    self.dimension = nil
    ---@type string 所有者
    self.owner = plantData.owner
    ---@type number 植えた時刻（unix）
    self.plantTime = plantData.plantTime
    ---@type string 植物タイプ（モデル段階用）
    self.plantType = plantData.plantType
    ---@type string 種アイテム名
    self.seed = plantData.seed
    ---@type number 肥料（%）
    self.fertilizer = plantData.fertilizer
    ---@type number 水分（%）
    self.water = plantData.water
    ---@type number 体力
    self.health = plantData.health
    ---@type number 成長率（%）
    self.growth = self:calcGrowth()

    self.growtime = plantData.growtime
    self.stage = self:calcStage()

    plants[self.id] = self

    --self.metadata = plantData.metadata -- 実験機能（主に ox_inventory）

    if Config.Debug then lib.print.info('[Plant:constructor] - Plant constructed with ID:', id) end
end

--- 植物を削除（テーブル・マップから）
---@return nil
function Plant:delete()
    self:destroyProp()
    plants[self.id] = nil
end

--- マップ上の植物プロップを更新／スポーン
---@return nil
function Plant:spawn()

    if Config.Debug then lib.print.info('[Plant:spawn] - Try to spawning plant with ID:', self.id) end

    ---@type number 成長段階（1〜3）
    local stage = self:calcStage()

    ---@type string 植物タイプ（モデル段階用）
    local plantType = self.plantType

    ---@type string モデルハッシュ名
    local modelHash = Config.PlantTypes[plantType][stage][1]

    ---@type number Zオフセット
    local zOffest = Config.PlantTypes[plantType][stage][2]

    ---@type number エンティティハンドル
    local plantEntity = CreateObjectNoOffset(modelHash, self.coords.x, self.coords.y, self.coords.z + zOffest, true, true, false)
    SetEntityRoutingBucket(plantEntity, self.dimension)
    FreezeEntityPosition(plantEntity, true)

    self.entity = plantEntity
    self.netId = NetworkGetNetworkIdFromEntity(plantEntity)
    plants[self.id] = self

    if Config.Debug then lib.print.info('[Plant:spawn] - Plant spawned with ID:', self.id) end
end

--- マップ上のプロップのみ削除
---@return nil
function Plant:destroyProp()
    if not DoesEntityExist(self.entity) then return end
    DeleteEntity(self.entity)

    self.entity = nil
    self.netId = nil

    plants[self.id] = self
end

--- マップ上の植物プロップを更新／スポーン
---@return nil
function Plant:updateProps()
    local stage = self:calcStage()
    local plantType = self.plantType

    ---@type string モデルハッシュ名
    local modelHash = Config.PlantTypes[plantType][stage][1]

    ---@type number Zオフセット
    local zOffest = Config.PlantTypes[plantType][stage][2]

    DeleteEntity(self.entity)

    ---@type number エンティティハンドル
    local plantEntity = CreateObjectNoOffset(modelHash, self.coords.x, self.coords.y, self.coords.z + zOffest, true, true, false)
    FreezeEntityPosition(plantEntity, true)

    self.stage = stage
    self.entity = plantEntity
    self.netId = NetworkGetNetworkIdFromEntity(plantEntity)
    plants[self.id] = self
end

--- 肥料値を更新
---@param fertilizer number
---@return nil
function Plant:updateFertilizer(fertilizer)
    self.fertilizer = fertilizer

    -- メモリ上の plants テーブルも同期
    plants[self.id].fertilizer = fertilizer
end

--- 水分を更新
---@param water number
---@return nil
function Plant:updateWater(water)
    self.water = water

    -- メモリ上の plants テーブルも同期
    plants[self.id].water = water
end

--- 体力を更新
---@param health number
---@return nil
function Plant:updateHealth(health)
    self.health = health

    -- メモリ上の plants テーブルも同期
    plants[self.id].health = health

    -- DB に反映
    MySQL.update('UPDATE drug_plants SET health = (:health) WHERE id = (:id)', {
        ['health'] = health,
        ['id'] = self.id,
    })
end

--- クライアント送信用データを取得
---@return table
function Plant:getData()
    return {
        id = self.id,
        entity = self.entity,
        netId = self.netId,
        coords = self.coords,
        dimension = self.dimension,
        owner = self.owner,
        plantType = self.plantType,
        seed = self.seed,
        plantTime = self.plantTime,
        fertilizer = self.fertilizer,
        water = self.water,
        health = self.health,
        growtime = self.growtime,
        stage = self.stage,
        growth = self:calcGrowth()
    }
end

-- 体力を計算（閾値・減衰）
---@return integer 体力
function Plant:calcHealth()

    if not plants[self.id] then return 0 end

    -- 現在値から減算
    ---@type number
    local health = self.health
    ---@type number
    local fertilizer_amount = self.fertilizer
    ---@type number
    local water_amount = self.water

    -- 肥料または水分が0なら減少
    if fertilizer_amount == 0 or water_amount == 0 then
        health = health - math.random(Config.HealthBaseDecay[1], Config.HealthBaseDecay[2])
    elseif fertilizer_amount < Config.FertilizerThreshold or water_amount < Config.WaterThreshold then
        health = health - math.random(Config.HealthBaseDecay[1], Config.HealthBaseDecay[2])
    end

    health = math.max(health, 0.0)

    self.health = health
    -- 下限0
    return math.max(health, 0.0)
end

-- 成長率（%）を算出
---@return integer 成長率
function Plant:calcGrowth()
    if not plants[self.id] then return 0 end
    -- 枯れている場合は成長固定
    if self.health <= 0 then return self.growth end
    ---@type number 現在時刻（unix）
    local current_time = os.time()
    ---@type number 成長に要する秒数
    local growTime = self.growtime * 60
    ---@type number 経過秒
    local progress = os.difftime(current_time, self.plantTime)
    ---@type number 計算中の成長率
    local growth = math.round(progress * 100 / growTime, 2)
    ---@type number 戻り値（0〜100）
    local retval = math.min(growth, 100.00)
    self.growth = retval
    return retval
end

-- モデル段階 1〜3
---@return integer 段階
function Plant:calcStage()
    local growth = self:calcGrowth()
    local stage = math.floor(growth / 33) + 1
    if stage > 3 then stage = 3 end
    return stage
end


--- コールバック: ID で植物取得
---@param source number | nil 呼び出し元
---@param plantId string 植物ID
---@return Plant | nil
lib.callback.register('it-drugs:server:getPlantById', function(source, plantId)

    if Config.Debug then lib.print.info('[getPlantById] - Try to get plant with ID:', plantId) end

    if not plants[plantId] then
        lib.print.error('[getPlantById] - Plant with ID:', plantId, 'does not exist')
        return nil
    end

    if Config.Debug then lib.print.info('[getPlantById] - Successfully get Plant with ID:', plantId) end
    return plants[plantId]:getData()
end)

--- コールバック: ネットIDで植物取得
---@param source number | nil 呼び出し元
---@param netId number
---@return Plant | nil
lib.callback.register('it-drugs:server:getPlantByNetId', function(source, netId)

    if Config.Debug then lib.print.info('[getPlantByNetId] - Try to get plant with netId:', netId) end
   
    for _, v in pairs(plants) do
        if v.netId == netId then
            if Config.Debug then lib.print.info('[getPlantByNetId] - Successfully get Plant with netId:', netId) end
            return v:getData()
        end
    end

    lib.print.error('[getPlantByNetId] - Plant with netId:', netId, 'does not exist')
    return nil
end)

--- コールバック: 所有者の植物一覧
---@param source number
---@return table | nil
lib.callback.register('it-drugs:server:getPlantByOwner', function(source)

    if Config.Debug then lib.print.info('[getPlantByOwner] - Try to get all plants owned by player:', source) end

    ---@type number source（プレイヤー番号）
    local src = source
    ---@type string 市民ID（it_bridge）
    local citId = exports.it_bridge:GetCitizenId(src)
    ---@type table 一時テーブル
    local temp = {}

    -- 全植物から所有者一致を抽出
    for k, v in pairs(plants) do
        if v.owner == citId then
            temp[k] = v:getData()
        end
    end
    
    -- 0件なら nil
    if next(temp) == nil then
        if Config.Debug then lib.print.info('[getPlantsOwned] - Player:', src, 'does not own any plants') end
        return nil
    end

    if Config.Debug then lib.print.info('[getPlantsOwned] - Successfully get all plants owned by player:', src) end
    return temp

end)

--- コールバック: 全植物
---@param source number
---@return table | nil
lib.callback.register('it-drugs:server:getPlants', function(source)

    if Config.Debug then lib.print.info('[getPlants] - Try to get all plants') end

    ---@type table 一時テーブル
    local temp = {}

    -- 全件をコピー
    for k, v in pairs(plants) do
        temp[k] = v:getData()
    end

    if Config.Debug then lib.print.info('[getPlants] - Successfully get all plants') end
    return temp
end)

--- DB から植物を読み込みスポーン
--- @return boolean
local setupPlants = function()
    local result = MySQL.query.await('SELECT * FROM `drug_plants`')

    if Config.Debug then lib.print.info('[setupPlants] - Found', #result, 'plants in the database') end

    if not result then return true end

    for i = 1, #result do
        local v = result[i]
        if not Config.Plants[v.type] then
            MySQL.query('DELETE from drug_plants WHERE id = :id', {
                ['id'] = v.id
            }, function()
                lib.print.info('[setuPlant] Plant with ID: '..v.id..' has a invalid type, deleting it from the database')
            end)
        elseif v.owner == nil then
            MySQL.query('DELETE from drug_plants WHERE id = :id', {
                ['id'] = v.id
            }, function()
                lib.print.info('[setuPlant] Plant with ID: '..v.id..' has a invalid owner, deleting it from the database')
            end)
        else
            if Config.ClearOnStartup then
                if v.health == 0 then
                    MySQL.query('DELETE from drug_plants WHERE id = :id', {
                        ['id'] = v.id
                    }, function()
                        lib.print.info('[setuPlant] Plant with ID: '..v.id..' is dead, deleting it from the database')
                    end)
                else
                    local coords = json.decode(v.coords)
                    local currentPlant = Plant:new(v.id, {
                            entity = nil,
                            coords = vector3(coords.x, coords.y, coords.z),
                            dimension = v.dimension,
                            owner = v.owner,
                            plantTime = v.time,
                            plantType = Config.Plants[v.type].plantType,
                            fertilizer = v.fertilizer,
                            water = v.water,
                            health = v.health,
                            growtime = v.growtime,
                            seed = v.type,
                        }
                    )
                    currentPlant:spawn()
                end
            else
                local coords = json.decode(v.coords)
                local currentPlant = Plant:new(v.id, {
                        entity = nil,
                        coords = vector3(coords.x, coords.y, coords.z),
                        owner = v.owner,
                        dimension = v.dimension,
                        plantTime = v.time,
                        plantType = Config.Plants[v.type].plantType,
                        fertilizer = v.fertilizer,
                        water = v.water,
                        health = v.health,
                        growtime = v.growtime,
                        seed = v.type,
                    }
                )
                currentPlant:spawn()
            end
        end
    end
    TriggerClientEvent('it-drugs:client:syncPlantList', -1, plants)
    return true
end

--- 毎分、肥料・水分・体力を更新
updatePlantNeeds = function ()
    for plantId, plant in pairs(plants) do
        local plantData = plant:getData()
        local fertilizer = plantData.fertilizer
        local water = plantData.water

        local time = os.time()
        local planted = plantData.plantTime

        if Config.Debug then lib.print.info('[updatePlantNeeds] - Plant with ID:', plantId, 'Time:', time, 'Planted:', planted) end

        local elapsed = os.difftime(time, planted)
        -- 植えてから1分未満はスキップ
        if elapsed >= 60 then
            if Config.Debug then lib.print.info('[updatePlantNeeds] - Plant with ID:', plantId, 'is ready to be updated') end
            if fertilizer - Config.FertilizerDecay >= 0 then
                plant:updateFertilizer(math.round(fertilizer - Config.FertilizerDecay, 2))
            else
                plant:updateFertilizer(0)
            end
    
            if water - Config.WaterDecay >= 0 then
                plant:updateWater(math.round(water - Config.WaterDecay, 2))
            else
                plant:updateWater(0)
            end
            local health = plant:calcHealth()
            MySQL.update('UPDATE drug_plants SET water = (:water), fertilizer = (:fertilizer), health = (:health) WHERE id = (:id)', {
                ['water'] = plant.water,
                ['fertilizer'] = plant.fertilizer,
                ['health'] = health,
                ['id'] = plant.id,
            })
        end

        local entity = plantData.entity

        if not DoesEntityExist(entity) then
            if Config.Debug then lib.print.info('[updatePlantNeeds] - Plant with ID:', plantId, 'does not exist try to respawn the plant') end
            -- エンティティ欠落時は再スポーン
            plant:spawn()
        end

        local stage = plant:calcStage()
            if stage ~= plantData.stage then
                plant:updateProps()
            end
    end

    SetTimeout(60 * 1000, updatePlantNeeds)
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    while not DatabaseSetuped do
        lib.print.info('Waiting for Database to be setup')
        Wait(100)
    end
    if Config.Debug then lib.print.info('[resoucesStart] Starting Plant Setup...') end
    setupPlants()
    while not setupPlants do
        Wait(100)
    end
    TriggerClientEvent('it-drugs:client:syncPlantList', -1)
    SendToWebhook(0, 'message', nil, {description = 'Started '..GetCurrentResourceName()..' logger'})
    updatePlantNeeds()

    if Config.Debug then lib.print.info('[resoucesStart] Finished Setup...') end

end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    for plantId, plant in pairs(plants) do
        local plantData = plant:getData()
        MySQL.update('UPDATE drug_plants SET health = (:health), water = (:water), fertilizer = (:fertilizer) WHERE id = (:id)', {
            ['health'] = plant:calcHealth(),
            ['water'] = json.encode(plantData.water),
            ['fertilizer'] = json.encode(plantData.fertilizer),
            ['id'] = plantId,
        })
    end

    for _, plant in pairs(plants) do
        plant:delete()
    end
end)

--- イベント

--- 新規植物作成
---@param coords vector3
---@param plantItem string 種アイテム
---@param zone string | nil 栽培ゾーンID
---@param metadata table | nil
RegisterNetEvent('it-drugs:server:createNewPlant', function(coords, plantItem, zone, metadata)
    local src = source
    local plantInfos = Config.Plants[plantItem]
    if #(GetEntityCoords(GetPlayerPed(src)) - coords) > Config.rayCastingDistance + 10 then return end


    -- 必要アイテムの消費はサーバーで検証
    if plantInfos.reqItems and plantInfos.reqItems['planting'] ~= nil then
        local givenItems = {}
        for item, itemData in pairs(plantInfos.reqItems["planting"]) do
            if Config.Debug then lib.print.info('Checking for item: ' .. item) end -- デバッグ
            if not exports.it_bridge:HasItem(source, item, itemData.amount or 1) then
                ShowNotification(nil, _U('NOTIFICATION__NO__ITEMS'), "Error")

                if #givenItems > 0 then
                    for _, item in pairs(givenItems) do
                        exports.it_bridge:GiveItem(source, item)
                    end
                end
                return
            else
                if itemData.remove then
                    if exports.it_bridge:RemoveItem(source, item, itemData.amount or 1) then
                        table.insert(givenItems, item)
                    end
                end
            end
        end
    end

    if exports.it_bridge:RemoveItem(src, plantItem, 1, metadata) then
        local time = os.time()
        local owner = exports.it_bridge:GetCitizenId(src)

        local growTime = Config.GlobalGrowTime
        if plantInfos.growthTime then
            growTime = plantInfos.growthTime
        end
        if Config.Zones[zone] ~= nil and Config.Zones[zone].growMultiplier then
            growTime = (growTime / Config.Zones[zone].growMultiplier)
        end

        local id = exports.it_bridge:GenerateCustomID(8)
        while plants[id] do
            id = exports.it_bridge:GenerateCustomID(8)
        end

        local currentDimension = GetPlayerRoutingBucket(src)

        MySQL.insert('INSERT INTO `drug_plants` (id, owner, coords, dimension, time, type, water, fertilizer, health, growtime) VALUES (:id, :owner, :coords, :dimension, :time, :type, :water, :fertilizer, :health, :growtime)', {
            ['id'] = id,
            ['owner'] = owner,
            ['coords'] = json.encode(coords),
            ['dimension'] = currentDimension,
            ['time'] = time,
            ['type'] = plantItem,
            ['water'] = 0.0,
            ['fertilizer'] = 0.0,
            ['health'] = 100.0,
            ['growtime'] = growTime,
        }, function()
            local currentPlant = Plant:new(id, {
                coords = coords,
                dimension = currentDimension,
                owner = owner,
                plantTime = time,
                plantType = Config.Plants[plantItem].plantType,
                fertilizer = 0.0,
                water = 0.0,
                health = 100.0,
                growtime = growTime,
                seed = plantItem,

            })
            currentPlant:spawn()
            TriggerClientEvent('it-drugs:client:syncPlantList', -1, plants)
            SendToWebhook(src, 'plant', 'plant', plants[id]:getData())
        end)
    end
end)

--- 世話（水やり・肥料）アイテム使用時
---@param plantId string
---@param item string 使用アイテム
RegisterNetEvent('it-drugs:server:plantTakeCare', function(plantId, item)

    if not plants[plantId] then return end
    local plant = plants[plantId]
    local plantData = plant:getData()

    local src = source
    if #(GetEntityCoords(GetPlayerPed(src)) - plantData.coords) > 10 then return end

    if exports.it_bridge:RemoveItem(src, item, 1) then
        local itemData = Config.Items[item]
        if itemData.water ~= 0 then
            local itemStrength = itemData.water
            local currentWater = plantData.water
            if currentWater + itemStrength >= 100 then
                plant:updateWater(100)
            else
                plant:updateWater(currentWater + itemStrength)
            end

            plantData = plant:getData()

            MySQL.update('UPDATE drug_plants SET water = (:water) WHERE id = (:id)', {
                ['water'] = json.encode(plantData.water),
                ['id'] = plantData.id,
            })
            SendToWebhook(src, 'plant', 'water', plantData)
        end

        if itemData.fertilizer ~= 0 then
            local itemStrength = itemData.fertilizer
            local currentFertilizer = plantData.fertilizer
            if currentFertilizer + itemStrength >= 100 then
                plant:updateFertilizer(100)
            else
                plant:updateFertilizer(currentFertilizer + itemStrength)
            end

            plantData = plant:getData()

            MySQL.update('UPDATE drug_plants SET fertilizer = (:fertilizer) WHERE id = (:id)', {
                ['fertilizer'] = json.encode(plantData.fertilizer),
                ['id'] = plantData.id,
            })
            SendToWebhook(src, 'plant', 'fertilize', plantData)
        end
        if itemData.itemBack ~= nil then
            exports.it_bridge:GiveItem(src, itemData.itemBack, 1)
        end
    end
end)

--- 収穫
---@param plantId string
RegisterNetEvent('it-drugs:server:harvestPlant', function(plantId)

    if not plants[plantId] then return end
    local plant = plants[plantId]
    local plantData = plant:getData()
    
    local src = source
    if #(GetEntityCoords(GetPlayerPed(src)) - plantData.coords) > 10 then return end
    if plant:calcGrowth() ~= 100 then return end

    local extendedPlantData = Config.Plants[plantData.seed]

    if extendedPlantData.reqItems and extendedPlantData.reqItems["harvesting"] ~= nil then
        local givenItems = {}
        for item, itemData in pairs(extendedPlantData.reqItems["harvesting"]) do
            if Config.Debug then lib.print.info('Checking for item: ' .. item) end -- デバッグ
            if not exports.it_bridge:HasItem(source, item, itemData.amount or 1) then
                ShowNotification(nil, _U('NOTIFICATION__NO__ITEMS'), "Error")

                if #givenItems > 0 then
                    for _, item in pairs(givenItems) do
                        exports.it_bridge:GiveItem(source, item)
                    end
                end
                return
            else
                if itemData.remove then
                    if exports.it_bridge:RemoveItem(source, item, itemData.amount or 1) then
                        table.insert(givenItems, item)
                    end
                end
            end
        end
    end

    if DoesEntityExist(plantData.entity) then
        for k, v in pairs(Config.Plants[plantData.seed].products) do
            local product = k
            local minAmount = v.min
            local maxAmount = v.max
            local amount = math.random(minAmount, maxAmount)
            exports.it_bridge:GiveItem(src, product, amount)
        end
        if math.random(1, 100) <= Config.Plants[plantData.seed].seed.chance then
            local seed = plantData.type

            if Config.Plants[plantData.seed].seed.max > 1 then
                local seedAmount = math.random(Config.Plants[plantData.seed].seed.min, Config.Plants[plantData.seed].seed.max)
                exports.it_bridge:GiveItem(src, plantData.seed, seedAmount)
            end
        end
  
        MySQL.query('DELETE from drug_plants WHERE id = :id', {
            ['id'] = plantData.id
        })

        plant:delete()
        TriggerClientEvent('it-drugs:client:syncPlantList', -1, plants)
        SendToWebhook(src, 'plant', 'harvest', plantData)
    end
end)

--- 破棄
---@param args table
RegisterNetEvent('it-drugs:server:destroyPlant', function(args)
    local plant = plants[args.plantId]
    if not plant then return end
    
    if not args.extra then
        if #(GetEntityCoords(GetPlayerPed(source)) - plant.coords) > 10 then return end
    end
    
    SendToWebhook(source, 'plant', 'destroy', plant:getData())
    if DoesEntityExist(plant.entity) then
      
        TriggerClientEvent('it-drugs:client:startPlantFire', -1, plant.coords)
        Wait(Config.FireTime / 2)

        plant:delete()

        MySQL.query('DELETE from drug_plants WHERE id = :id', {
            ['id'] = plant.id
        })
        plant:delete()
        TriggerClientEvent('it-drugs:client:syncPlantList', -1, plants)
    end
end)