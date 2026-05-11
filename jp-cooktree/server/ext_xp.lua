-- EXP MOD ラッパー（ext-xp 接続前のプレースホルダ）
CookTree = CookTree or {}
CookTree.ExtXP = CookTree.ExtXP or {}

function CookTree.ExtXP.GetLevel(_src)
    -- TODO: return exports['ext-xp']:GetLevel(src)
    return (Config and Config.DummyLevel) or 1
end

function CookTree.ExtXP.AddXP(src, amount)
    -- TODO: exports['ext-xp']:AddXP(src, amount)
    print(('[%s][DUMMY] AddXP src=%d amount=%d'):format(
        GetCurrentResourceName(), src or 0, tonumber(amount) or 0))
end
