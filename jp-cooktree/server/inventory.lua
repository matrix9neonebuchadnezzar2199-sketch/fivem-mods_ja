-- ox_inventory ラッパー（P3a は AddItem のみ）
CookTree = CookTree or {}
CookTree.Inv = CookTree.Inv or {}

---@return boolean
function CookTree.Inv.AddItem(src, item, count)
    local ok, res = pcall(function()
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
