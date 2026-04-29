-- OS 非依存のディレクトリ一覧（素材スキャン用）

---@param dir string 末尾スラッシュまたはバックスラッシュ可
---@return string[]
function JpSlotListDir(dir)
    if not dir or dir == '' then
        return {}
    end
    local sep = package.config:sub(1, 1)
    local cmd
    if sep == '\\' then
        cmd = 'cmd /c dir /b "' .. dir:gsub('/', '\\') .. '" 2>nul'
    else
        cmd = 'ls "' .. dir .. '" 2>/dev/null'
    end
    local p = io.popen(cmd)
    if not p then
        return {}
    end
    local out = {}
    for line in p:lines() do
        line = line and line:gsub('^%s+', ''):gsub('%s+$', '') or ''
        if line ~= '' and not line:match('^%.') then
            out[#out + 1] = line
        end
    end
    p:close()
    return out
end
