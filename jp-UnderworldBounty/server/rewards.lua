local function randi(a, b)
  return math.random(math.min(a, b), math.max(a, b))
end

--- @param src number
--- @param reward_table_id string
function UbGrantRewards(src, reward_table_id)
  local tbl = Config.RewardTables[reward_table_id]
  if not tbl then
    return
  end
  if tbl.cash then
    local ch = tbl.cash.chance or 1.0
    if math.random() <= ch then
      local amt = randi(tbl.cash.min or 0, tbl.cash.max or 0)
      if amt > 0 then
        pcall(function()
          Bridge.AddMoney(src, 'cash', amt)
        end)
      end
    end
  end
  if tbl.items then
    for _, it in ipairs(tbl.items) do
      local ch = it.chance or 1.0
      if math.random() <= ch then
        local c = randi(it.count_min or 1, it.count_max or 1)
        pcall(function()
          Bridge.AddItem(src, it.item, c)
        end)
      end
    end
  end
end
