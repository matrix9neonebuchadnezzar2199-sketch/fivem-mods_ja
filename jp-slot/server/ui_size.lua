-- UI サイズの読込（KVS）。admin.lua / main.lua より先に読み込む。

---@return table
function JpSlotGetUISize()
    local raw = GetResourceKvpString('jp-slot:ui_size')
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then
            return {
                widthPercent = math.max(30, math.min(100, tonumber(data.widthPercent) or 90)),
                heightPercent = math.max(30, math.min(100, tonumber(data.heightPercent) or 90)),
                maxWidthPx = math.max(0, math.min(7680, tonumber(data.maxWidthPx) or 0)),
            }
        end
    end
    local u = Config.UISize or {}
    return {
        widthPercent = tonumber(u.widthPercent) or 90,
        heightPercent = tonumber(u.heightPercent) or 90,
        maxWidthPx = tonumber(u.maxWidthPx) or 0,
    }
end
