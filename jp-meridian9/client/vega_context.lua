-- ============================================================
-- ヴェガ選択肢メニュー（自前 NUI）
-- ox_lib の lib.registerContext は幅・文字サイズを Lua から変えられないため、
-- 任務受注の選択肢のみ本リソースの NUI で表示する。
-- ============================================================

MRD9 = MRD9 or {}

local State = {
    open = false,
    handlers = {},
    onBack = nil,
}

function MRD9.VegaContextHide()
    State.open = false
    State.handlers = {}
    State.onBack = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'vegaContextClose' })
end

---@param def { title: string, showBack?: boolean, onBack?: function|nil, options: { title: string, description?: string, icon?: string, disabled?: boolean, onSelect?: function }[] }
function MRD9.VegaContextShow(def)
    MRD9.VegaContextHide()

    local serial = {}
    local handlers = {}
    for i, o in ipairs(def.options or {}) do
        handlers[i] = o.onSelect
        serial[i] = {
            title = o.title or '',
            description = o.description,
            icon = o.icon,
            disabled = o.disabled and true or false,
        }
    end

    local scale = 2.0
    if Config and Config.NPC and type(Config.NPC.contextMenuScale) == 'number' and Config.NPC.contextMenuScale > 0 then
        scale = Config.NPC.contextMenuScale
    end

    State.handlers = handlers
    State.onBack = def.onBack
    State.open = true

    SendNUIMessage({
        type = 'vegaContextOpen',
        title = def.title or '',
        showBack = def.showBack and true or false,
        options = serial,
        scale = scale,
    })
    SetNuiFocus(true, true)
end

RegisterNUICallback('mrd9_vega_ctx_select', function(data, cb)
    local idx = tonumber(data and data.index)
    local fn = idx and State.handlers[idx]
    MRD9.VegaContextHide()
    if fn then
        fn()
    end
    cb({ ok = true })
end)

RegisterNUICallback('mrd9_vega_ctx_back', function(_, cb)
    local backFn = State.onBack
    MRD9.VegaContextHide()
    if backFn then
        backFn()
    end
    cb({ ok = true })
end)

RegisterNUICallback('mrd9_vega_ctx_close', function(_, cb)
    MRD9.VegaContextHide()
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then
        return
    end
    MRD9.VegaContextHide()
end)
