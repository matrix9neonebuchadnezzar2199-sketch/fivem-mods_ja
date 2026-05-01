--- PHASE A 対戦ルールの純関数（隣接辺比較・配置直後のみ奪取・連鎖なし）
--- CPU 戦・PvP 戦で同一ロジックを共有する。FiveM ネイティブに依存しない。

TcgBattleRule = TcgBattleRule or {}

--- @param idx integer 1..9
--- @return integer r, integer c  0..2
local function idxToRc(idx)
    local z = idx - 1
    return z // 3, z % 3
end

--- @param r integer
--- @param c integer
--- @return integer
local function rcToIdx(r, c)
    return r * 3 + c + 1
end

--- @return table  board[1..9] = nil（空マス）
function TcgBattleRule.CreateEmptyBoard()
    local b = {}
    for i = 1, 9 do
        b[i] = nil
    end
    return b
end

--- 空マスに配置し、隣接する相手マスのみ奪取判定（連鎖なし）
--- @param board table 1..9、要素は nil または { owner = <任意>, card = table }
--- @param cell_index integer 1..9
--- @param card table stat_top/right/bottom/left（数値化して比較）
--- @param owner any 配置プレイヤー識別子（2 人対戦では「自分以外」が相手）
--- @return table { flipped_cells = integer[] }  奪取で owner が変わった隣接マスのインデックス（昇順で追加）
function TcgBattleRule.PlaceAndResolve(board, cell_index, card, owner)
    assert(type(board) == 'table', 'board required')
    assert(cell_index >= 1 and cell_index <= 9 and math.floor(cell_index) == cell_index, 'cell_index 1..9')
    assert(board[cell_index] == nil, 'cell must be empty')
    assert(type(card) == 'table', 'card required')
    assert(owner ~= nil, 'owner required')

    local myTop = tonumber(card.stat_top) or 0
    local myRight = tonumber(card.stat_right) or 0
    local myBottom = tonumber(card.stat_bottom) or 0
    local myLeft = tonumber(card.stat_left) or 0

    board[cell_index] = { owner = owner, card = card }

    local r, c = idxToRc(cell_index)
    local checks = {
        { nr = r - 1, nc = c, my = myTop, oppKey = 'stat_bottom' },
        { nr = r + 1, nc = c, my = myBottom, oppKey = 'stat_top' },
        { nr = r, nc = c - 1, my = myLeft, oppKey = 'stat_right' },
        { nr = r, nc = c + 1, my = myRight, oppKey = 'stat_left' },
    }

    local flipped = {}
    for _, ch in ipairs(checks) do
        if ch.nr >= 0 and ch.nr <= 2 and ch.nc >= 0 and ch.nc <= 2 then
            local ni = rcToIdx(ch.nr, ch.nc)
            local cell = board[ni]
            if cell and cell.owner ~= owner then
                local ostat = tonumber(cell.card[ch.oppKey]) or 0
                if ch.my > ostat then
                    cell.owner = owner
                    flipped[#flipped + 1] = ni
                end
            end
        end
    end

    return { flipped_cells = flipped }
end

--- @param board table
--- @return boolean
function TcgBattleRule.IsBoardFull(board)
    assert(type(board) == 'table', 'board required')
    for i = 1, 9 do
        if board[i] == nil then
            return false
        end
    end
    return true
end

--- @param board table
--- @param owner any
--- @return integer
function TcgBattleRule.CountOwnerCells(board, owner)
    assert(type(board) == 'table', 'board required')
    local n = 0
    for i = 1, 9 do
        local cell = board[i]
        if cell and cell.owner == owner then
            n = n + 1
        end
    end
    return n
end

--- 終了スコア: 盤上の自色マス数 + 手札残枚数
--- @param board table
--- @param owner any
--- @param hand_remaining integer
--- @return integer
function TcgBattleRule.CalcFinalScore(board, owner, hand_remaining)
    assert(type(board) == 'table', 'board required')
    local h = tonumber(hand_remaining) or 0
    if h < 0 then
        h = 0
    end
    return TcgBattleRule.CountOwnerCells(board, owner) + h
end
