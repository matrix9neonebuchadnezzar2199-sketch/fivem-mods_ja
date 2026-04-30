-- OS 非依存のディレクトリ一覧（素材スキャン用）

--- Windows で dir が空になる場合の代替（PowerShell / UTF-8 パス）
---@param winPath string バックスラッシュ正規化済み・末尾 \ 可
---@return string[]
local function jpSlotListDirWindowsAlt(winPath)
    winPath = winPath:gsub('/', '\\')
    if winPath:sub(-1) == '\\' then
        winPath = winPath:sub(1, -2)
    end
    -- PowerShell のシングルクォートエスケープ: ' → ''（ソースに ''' 連続を書かない）
    local SQ = "'"
    local lit = winPath:gsub(SQ, SQ .. SQ)
    local cmd = table.concat({
        'powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "',
        'Get-ChildItem -LiteralPath ',
        SQ,
        lit,
        SQ,
        ' -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }"',
    })
    local p = io.popen(cmd)
    if not p then
        return {}
    end
    local out = {}
    for line in p:lines() do
        line = line and line:gsub('\r', ''):gsub('^%s+', ''):gsub('%s+$', '') or ''
        if line ~= '' and not line:match('^%.') then
            out[#out + 1] = line
        end
    end
    p:close()
    return out
end

---@param dir string 末尾スラッシュまたはバックスラッシュ可
---@return string[]
function JpSlotListDir(dir)
    if not dir or dir == '' then
        return {}
    end
    -- FiveM のサーバー Lua では global package が無い環境がある
    local use_windows_shell = false
    if type(package) == 'table' and type(package.config) == 'string' then
        use_windows_shell = (package.config:sub(1, 1) == '\\')
    else
        local osenv = os.getenv('OS') or ''
        use_windows_shell = osenv:find('Windows') ~= nil or dir:match('^%a:[/\\]') ~= nil
    end
    local winPath = dir:gsub('/', '\\')
    local cmd
    if use_windows_shell then
        -- /ad = ディレクトリのみ（ファイル除外）
        cmd = 'cmd /c dir /b /ad "' .. winPath .. '" 2>nul'
    else
        cmd = 'ls -1 "' .. dir .. '" 2>/dev/null'
    end
    local p = io.popen(cmd)
    if not p then
        if use_windows_shell then
            return jpSlotListDirWindowsAlt(winPath)
        end
        return {}
    end
    local out = {}
    for line in p:lines() do
        line = line and line:gsub('\r', ''):gsub('^%s+', ''):gsub('%s+$', '') or ''
        if line ~= '' and not line:match('^%.') then
            out[#out + 1] = line
        end
    end
    p:close()
    if use_windows_shell and #out == 0 then
        return jpSlotListDirWindowsAlt(winPath)
    end
    return out
end

--- html/assets/ からの相対パス（例: cutins/img_01.png）でファイル名を列挙
---@param assetRoot string html/assets/ までの絶対パス（末尾スラッシュ可）
---@param relDir string 相対ディレクトリ（例: cutins/ または cutins）
---@return string[]
function JpSlotListAssetRel(assetRoot, relDir)
    if not assetRoot or relDir == nil or relDir == '' then
        return {}
    end
    relDir = tostring(relDir)
    if relDir:sub(-1) ~= '/' and relDir:sub(-1) ~= '\\' then
        relDir = relDir .. '/'
    end
    local ar = assetRoot
    if ar:sub(-1) ~= '/' and ar:sub(-1) ~= '\\' then
        ar = ar .. '/'
    end
    local names = JpSlotListDir(ar .. relDir)
    local out = {}
    for _, n in ipairs(names) do
        out[#out + 1] = relDir .. n
    end
    return out
end

--- characters/ 直下のフォルダ内ファイルも含めて相対パス列挙（例: characters/luna/idle.png）
---@param assetRoot string html/assets/ まで
---@return string[]
function JpSlotListCharactersRel(assetRoot)
    if not assetRoot or assetRoot == '' then
        return {}
    end
    local ar = assetRoot
    if ar:sub(-1) ~= '/' and ar:sub(-1) ~= '\\' then
        ar = ar .. '/'
    end
    local rel = 'characters/'
    local full = ar .. rel
    local top = JpSlotListDir(full)
    local out = {}
    for _, name in ipairs(top) do
        local sub = JpSlotListDir(full .. name .. '/')
        if #sub > 0 then
            for _, f in ipairs(sub) do
                out[#out + 1] = rel .. name .. '/' .. f
            end
        else
            out[#out + 1] = rel .. name
        end
    end
    return out
end

---@param id string|nil
---@return boolean
function JpSlotCharacterIdValid(id)
    if not id or id == '' or type(id) ~= 'string' then
        return false
    end
    local path = ('html/assets/characters/%s/manifest.json'):format(id)
    local raw = LoadResourceFile(GetCurrentResourceName(), path)
    return raw ~= nil and raw ~= ''
end

--- html/assets/characters/<id>/manifest.json を読む（失敗時 nil）
---@param characterId string|nil
---@return table|nil
function JpSlotLoadCharacterManifest(characterId)
    local def = (Config.Characters and Config.Characters.DefaultId) or 'luna'
    local cid = characterId
    if not cid or cid == '' then
        cid = def
    end
    local path = ('html/assets/characters/%s/manifest.json'):format(cid)
    local raw = LoadResourceFile(GetCurrentResourceName(), path)
    if not raw or raw == '' then
        return nil
    end
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == 'table' then
        return data
    end
    return nil
end

--- io.popen / dir が失敗しても manifest が読めるキャラは列挙（管理 UI 用）
---@return table[]
local function jpSlotScanCharactersFromManifestFallback()
    local out = {}
    local seenOutId = {}
    local def = (Config.Characters and Config.Characters.DefaultId) or 'luna'
    local tryOrder = { def, 'luna' }
    local tried = {}
    for i = 1, #tryOrder do
        local tid = tryOrder[i]
        if type(tid) == 'string' and tid ~= '' and not tried[tid] then
            tried[tid] = true
            local man = JpSlotLoadCharacterManifest(tid)
            if man then
                local id = type(man.id) == 'string' and man.id ~= '' and man.id or tid
                local dn = type(man.displayName) == 'string' and man.displayName ~= '' and man.displayName or id
                if not seenOutId[id] then
                    seenOutId[id] = true
                    out[#out + 1] = { id = id, displayName = dn }
                end
            end
        end
    end
    return out
end

--- html/assets/characters/ をスキャンし manifest.json が読めるキャラのみ返す
---@return table[]
function JpSlotScanCharacters()
    local resName = GetCurrentResourceName()
    local base = GetResourcePath(resName)
    if not base or base == '' then
        return jpSlotScanCharactersFromManifestFallback()
    end
    local sep = base:find('\\') and '\\' or '/'
    if base:sub(-1) ~= '/' and base:sub(-1) ~= '\\' then
        base = base .. sep
    end
    base = base .. 'html' .. sep .. 'assets' .. sep .. 'characters' .. sep
    local dirs = JpSlotListDir(base)
    local out = {}
    local seenId = {}
    for _, dir in ipairs(dirs) do
        if type(dir) == 'string' and dir ~= '' then
            local man = JpSlotLoadCharacterManifest(dir)
            if man then
                local id = type(man.id) == 'string' and man.id ~= '' and man.id or dir
                local dn = type(man.displayName) == 'string' and man.displayName ~= '' and man.displayName or id
                if not seenId[id] then
                    seenId[id] = true
                    out[#out + 1] = { id = id, displayName = dn }
                end
            end
        end
    end
    if #out == 0 then
        out = jpSlotScanCharactersFromManifestFallback()
    end
    table.sort(out, function(a, b)
        return (a.id or '') < (b.id or '')
    end)
    return out
end

--- KVP キー: jp-slot:adm:preset:<characterId>:<presetName>
---@param characterId string
---@param presetName string
---@return string
function JpSlotPresetBodyKvpKey(characterId, presetName)
    return ('jp-slot:adm:preset:%s:%s'):format(characterId, presetName)
end

--- アクティブプリセット（JSON）を解決。旧形式（単一プリセット id 文字列）は luna 配下として解釈。
---@return string|nil, string|nil
function JpSlotParseActivePresetRef()
    local raw = GetResourceKvpString('jp-slot:adm:preset:active')
    if not raw or raw == '' then
        return nil, nil
    end
    local trimmed = raw:match('^%s*(.-)%s*$') or raw
    if trimmed:sub(1, 1) == '{' then
        local ok, j = pcall(json.decode, trimmed)
        if ok and type(j) == 'table' then
            local cid = type(j.characterId) == 'string' and j.characterId ~= '' and j.characterId or nil
            local pname = type(j.presetName) == 'string' and j.presetName ~= '' and j.presetName or nil
            return cid, pname
        end
        return nil, nil
    end
    return 'luna', trimmed
end

--- manifest.assets からキャラルート基準の相対パス一覧（管理 UI datalist 用）
---@param manifest table
---@return table
function JpSlotAssetLibraryFromManifest(manifest)
    local assets = type(manifest) == 'table' and manifest.assets or nil
    local empty = {
        cutins = {},
        characters = {},
        bgm = {},
        se = {},
        voice = {},
        backgrounds = {},
    }
    if type(assets) ~= 'table' then
        return empty
    end
    local cutins = {}
    if type(assets.cutins) == 'table' then
        for _, p in ipairs(assets.cutins) do
            if type(p) == 'string' and p ~= '' then
                cutins[#cutins + 1] = p
            end
        end
    end
    local chars = {}
    local function add(p)
        if type(p) == 'string' and p ~= '' then
            chars[#chars + 1] = p
        end
    end
    local idle = assets.idle
    if type(idle) == 'table' then
        add(idle.portrait)
        if type(idle.videos) == 'table' then
            for _, v in ipairs(idle.videos) do
                add(v)
            end
        end
    end
    local win = assets.win
    if type(win) == 'table' then
        add(win.video)
        add(win.bigwin_video)
    end
    local bonus = assets.bonus
    if type(bonus) == 'table' then
        add(bonus.in_video)
        add(bonus.loop_video)
        add(bonus.streak_video)
        add(bonus.big_video)
    end
    local miss = assets.miss
    if type(miss) == 'table' then
        add(miss.video)
    end
    local bgm, se, voice = {}, {}, {}
    local snd = assets.sounds
    if type(snd) == 'table' then
        if type(snd.bgm) == 'table' then
            for _, p in pairs(snd.bgm) do
                if type(p) == 'string' and p ~= '' then
                    bgm[#bgm + 1] = p
                end
            end
        end
        if type(snd.se) == 'table' then
            for _, p in pairs(snd.se) do
                if type(p) == 'string' and p ~= '' then
                    se[#se + 1] = p
                end
            end
        end
        if type(snd.voice) == 'table' then
            for _, p in pairs(snd.voice) do
                if type(p) == 'string' and p ~= '' then
                    voice[#voice + 1] = p
                end
            end
        end
    end
    local backgrounds = {}
    local bgg = assets.backgrounds
    if type(bgg) == 'table' then
        if type(bgg.default) == 'string' and bgg.default ~= '' then
            backgrounds[#backgrounds + 1] = bgg.default
        end
        if type(bgg.bonus) == 'string' and bgg.bonus ~= '' then
            backgrounds[#backgrounds + 1] = bgg.bonus
        end
    end
    empty.cutins = cutins
    empty.characters = chars
    empty.bgm = bgm
    empty.se = se
    empty.voice = voice
    empty.backgrounds = backgrounds
    return empty
end

--- kind に応じてスキャン結果を間引く（未対応・all はそのまま）
---@param lib table
---@param kind string|nil
---@return table
function JpSlotFilterAssetLibByKind(lib, kind)
    kind = kind and string.lower(kind) or 'all'
    if kind == 'all' or kind == '' then
        return lib
    end
    local sym = lib.symbols
    local frm = lib.frames
    local typo = lib.typography
    local z = function()
        return {
            cutins = {},
            characters = {},
            bgm = {},
            se = {},
            voice = {},
            backgrounds = {},
            symbols = sym,
            frames = frm,
            typography = typo,
        }
    end
    if kind == 'cutin' then
        local o = z()
        o.cutins = lib.cutins or {}
        return o
    elseif kind == 'video' or kind == 'image' then
        local o = z()
        o.characters = lib.characters or {}
        o.cutins = lib.cutins or {}
        return o
    elseif kind == 'bgm' then
        local o = z()
        o.bgm = lib.bgm or {}
        return o
    elseif kind == 'se' then
        local o = z()
        o.se = lib.se or {}
        return o
    elseif kind == 'voice' then
        local o = z()
        o.voice = lib.voice or {}
        return o
    elseif kind == 'background' then
        local o = z()
        o.backgrounds = lib.backgrounds or {}
        return o
    end
    return lib
end

--- プリセット body の leftStage 2スロット化（1回のみ・KVP `jp-slot:adm:preset:migrated_v3`）
---@return integer 書き換えたプリセット本体の件数
function JpSlotMigratePresetsV3()
    if GetResourceKvpString('jp-slot:adm:preset:migrated_v3') == '1' then
        return 0
    end
    local function indexNames(characterId)
        local raw = GetResourceKvpString('jp-slot:adm:preset:index:' .. characterId)
        if not raw or raw == '' then
            return {}
        end
        local ok, t = pcall(json.decode, raw)
        if ok and type(t) == 'table' then
            return t
        end
        return {}
    end
    local function detectKind(file)
        if type(file) ~= 'string' or file == '' then
            return 'image'
        end
        local f = file:lower()
        if f:match('%.mp4$') or f:match('%.webm$') or f:match('%.mov$') or f:match('%.m4v$') then
            return 'video'
        end
        return 'image'
    end
    local function emptySlot(disabled)
        return {
            enabled = not disabled,
            file = '',
            kind = 'image',
            durationMs = 0,
            fadeIn = true,
            bgm = nil,
            voiceKeys = {},
        }
    end
    local function leftFromCharVideo(sec, useCharVideo)
        if type(sec) ~= 'table' then
            return false
        end
        if type(sec.leftStage) == 'table' and type(sec.leftStage.slots) == 'table' and #sec.leftStage.slots >= 2 then
            return false
        end
        if useCharVideo then
            local cv = sec.char_video or {}
            local file = type(cv.file) == 'string' and cv.file or ''
            local enabled = cv.enabled ~= false and file ~= ''
            sec.leftStage = {
                slots = {
                    {
                        enabled = enabled,
                        file = file,
                        kind = detectKind(file),
                        durationMs = 0,
                        fadeIn = cv.fade_back ~= false,
                        bgm = nil,
                        voiceKeys = {},
                    },
                    emptySlot(true),
                },
            }
        else
            sec.leftStage = {
                slots = { emptySlot(true), emptySlot(true) },
            }
        end
        return true
    end
    local n = 0
    local chars = JpSlotScanCharacters()
    for ci = 1, #chars do
        local row = chars[ci]
        local cid = type(row) == 'table' and row.id or nil
        if type(cid) == 'string' and cid ~= '' then
            local names = indexNames(cid)
            for ni = 1, #names do
                local pname = names[ni]
                if type(pname) == 'string' and pname ~= '' then
                    local key = JpSlotPresetBodyKvpKey(cid, pname)
                    local body = GetResourceKvpString(key)
                    if body and body ~= '' then
                        local ok, preset = pcall(json.decode, body)
                        if ok and type(preset) == 'table' and type(preset.effects) == 'table' then
                            local changed = false
                            local eff = preset.effects
                            if leftFromCharVideo(eff.idle, true) then
                                changed = true
                            end
                            if leftFromCharVideo(eff.miss_tease, true) then
                                changed = true
                            end
                            for _, ek in ipairs({ 'win', 'bonus', 'bonus_streak', 'bonus_big' }) do
                                if leftFromCharVideo(eff[ek], false) then
                                    changed = true
                                end
                            end
                            if changed then
                                SetResourceKvp(key, json.encode(preset))
                                n = n + 1
                            end
                        end
                    end
                end
            end
        end
    end
    SetResourceKvp('jp-slot:adm:preset:migrated_v3', '1')
    return n
end
