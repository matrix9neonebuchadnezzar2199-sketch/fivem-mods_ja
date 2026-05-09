PolaPaintStorage = {}

local STORAGE_DIR = 'data/photos/'
local hmacKey     = nil

--- 起動時初期化（ディレクトリは SaveResourceFile が親を作成しない場合があるため、初回保存で確実）
function PolaPaintStorage.init()
    local k = {}
    for i = 1, 32 do k[i] = ('%02x'):format(math.random(0, 255)) end
    hmacKey = table.concat(k)

    SaveResourceFile(GetCurrentResourceName(), 'data/photos/.polapaint_dir', 'ok', 2)

    local retention = Config.Storage and Config.Storage.retentionSec or 0
    if retention > 0 and Config.Debug then
        print('[polapaint] retentionSec>0: OS 側での定期削除を推奨（FiveM にディレクトリ列挙無し）')
    end
end

local function pathOf(id)
    return ('%s%s.jpg'):format(STORAGE_DIR, id)
end

--- バイナリ書き込み
---@param bin string 生バイナリ JPEG
---@return string|nil id, string|nil err
function PolaPaintStorage.savePhoto(bin)
    if type(bin) ~= 'string' or #bin < 32 then return nil, 'empty' end
    local b1, b2, b3 = bin:byte(1), bin:byte(2), bin:byte(3)
    local e1, e2 = bin:byte(#bin - 1), bin:byte(#bin)
    if b1 ~= 0xFF or b2 ~= 0xD8 or b3 ~= 0xFF then return nil, 'not_jpeg' end
    if e1 ~= 0xFF or e2 ~= 0xD9 then return nil, 'not_jpeg' end

    local maxBytes = (Config.Storage and Config.Storage.maxBytes) or (4 * 1024 * 1024)
    if #bin > maxBytes then return nil, 'too_large' end

    local id = PolaPaintUtil.token(16)
    local ok = SaveResourceFile(GetCurrentResourceName(), pathOf(id), bin, #bin)
    if not ok then return nil, 'write_fail' end
    return id, nil
end

--- ファイル読込
---@param id string（32 hex）
---@return string|nil bin
function PolaPaintStorage.loadPhoto(id)
    if type(id) ~= 'string' or not id:match('^[a-f0-9]+$') or #id ~= 32 then return nil end
    return LoadResourceFile(GetCurrentResourceName(), pathOf(id))
end

--- 簡易 HMAC（FNV-1a ベース。改ざん防止用途）
local function lightHmac(id)
    if not hmacKey then return '' end
    local h = 2166136261
    local s = hmacKey .. ':' .. id
    for i = 1, #s do
        h = (h ~ s:byte(i)) & 0xFFFFFFFF
        h = (h * 16777619) & 0xFFFFFFFF
    end
    return ('%08x'):format(h)
end

--- 公開URL用トークン発行（id.signature）
function PolaPaintStorage.publicUrl(id)
    local signed = id .. '.' .. lightHmac(id)
    return signed
end

--- URL から id を検証 + 抽出
---@param signed string id.hmac
---@return string|nil id
function PolaPaintStorage.verifySignedId(signed)
    if type(signed) ~= 'string' then return nil end
    local id, sig = signed:match('^([a-f0-9]+)%.([a-f0-9]+)$')
    if not id or #id ~= 32 then return nil end
    if Config.HttpToken and Config.HttpToken.enabled == false then
        return id
    end
    if lightHmac(id) ~= sig then return nil end
    return id
end
