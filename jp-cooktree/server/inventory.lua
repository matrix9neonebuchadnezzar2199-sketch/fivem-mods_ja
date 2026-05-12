-- ox_inventory ラッパー（AddItem・任意 metadata）
CookTree = CookTree or {}
CookTree.Inv = CookTree.Inv or {}

---@param src number
---@param item string
---@param count number
---@param metadata table|nil ox_inventory 用（quality / cookedBy 等）
---@return boolean
function CookTree.Inv.AddItem(src, item, count, metadata)
    local ok, res = pcall(function()
        if type(metadata) == 'table' then
            return exports.ox_inventory:AddItem(src, item, count, metadata)
        end
        return exports.ox_inventory:AddItem(src, item, count)
    end)
    if not ok then
        print(('[%s][WARN] AddItem pcall failed src=%s item=%s count=%s err=%s'):format(
            GetCurrentResourceName(), tostring(src), tostring(item), tostring(count), tostring(res)))
        return false
    end
    if res == false or res == nil then
        print(('[%s][WARN] AddItem declined src=%s item=%s count=%d'):format(
            GetCurrentResourceName(), tostring(src), tostring(item), count))
        return false
    end
    return true
end
