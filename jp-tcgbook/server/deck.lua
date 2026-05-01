--- デッキ編成ロジック（所有権チェックは本モジュールの責務）

Deck = {}

local MasterByCardId = {}
for _, c in ipairs(TcgCardsMaster) do
    MasterByCardId[c.card_id] = c
end

--- @param citizenid string
--- @param deck_id number
--- @return boolean
local function assertDeckOwner(citizenid, deck_id)
    local row = MySQL.single.await(
        'SELECT id FROM tcg_decks WHERE id = ? AND citizenid = ? LIMIT 1',
        { deck_id, citizenid }
    )
    return row ~= nil
end

--- 指示書のコピー名生成
--- @param citizenid string
--- @param baseName string
--- @return string
local function generateCopyName(citizenid, baseName)
    local r = Database.GetDeckNames(citizenid)
    if not r.success then
        return baseName .. ' - Copy'
    end
    local nameSet = {}
    for _, n in ipairs(r.data or {}) do
        nameSet[n] = true
    end

    local candidate = baseName .. ' - Copy'
    if not nameSet[candidate] then
        return candidate
    end

    local i = 1
    while true do
        candidate = baseName .. ' - Copy ' .. i
        if not nameSet[candidate] then
            return candidate
        end
        i = i + 1
    end
end

--- @param name string
--- @return boolean, string|nil error
local function validateDeckName(name)
    local trimmed = name:match('^%s*(.-)%s*$') or ''
    if trimmed == '' then
        return false, 'デッキ名を入力してください'
    end
    if #trimmed > 64 then
        return false, 'デッキ名は64文字以内にしてください'
    end
    return true, trimmed
end

--- @param citizenid string
--- @param deck_id number
function Deck.GetDeck(citizenid, deck_id)
    if not assertDeckOwner(citizenid, deck_id) then
        return { success = false, error = '権限がありません' }
    end
    return Database.GetDeckById(deck_id)
end

--- @param citizenid string
function Deck.GetAllDecks(citizenid)
    return Database.GetPlayerDecks(citizenid)
end

--- @param citizenid string
--- @param name string
function Deck.CreateDeck(citizenid, name)
    local okName, trimmedOrErr = validateDeckName(name)
    if not okName then
        return { success = false, error = trimmedOrErr }
    end

    local cnt = Database.CountDecks(citizenid)
    if not cnt.success then
        return cnt
    end
    if cnt.data >= Config.MaxDecksPerPlayer then
        return { success = false, error = 'デッキ保有数が上限に達しています' }
    end

    return Database.CreateDeck(citizenid, trimmedOrErr)
end

--- @param citizenid string
--- @param deck_id number
--- @param new_name string
function Deck.RenameDeck(citizenid, deck_id, new_name)
    if not assertDeckOwner(citizenid, deck_id) then
        return { success = false, error = '権限がありません' }
    end

    local okName, trimmedOrErr = validateDeckName(new_name)
    if not okName then
        return { success = false, error = trimmedOrErr }
    end

    return Database.UpdateDeckName(deck_id, trimmedOrErr)
end

--- @param citizenid string
--- @param deck_id number
function Deck.DeleteDeck(citizenid, deck_id)
    if not assertDeckOwner(citizenid, deck_id) then
        return { success = false, error = '権限がありません' }
    end

    local cnt = Database.CountDecks(citizenid)
    if not cnt.success then
        return cnt
    end
    if cnt.data <= 1 then
        return { success = false, error = '最後のデッキは削除できません' }
    end

    local row = MySQL.single.await(
        'SELECT is_active FROM tcg_decks WHERE id = ? AND citizenid = ? LIMIT 1',
        { deck_id, citizenid }
    )
    local wasActive = row and (row.is_active == true or row.is_active == 1)

    local del = Database.DeleteDeck(deck_id)
    if not del.success then
        return del
    end

    if wasActive then
        local decks = Database.GetPlayerDecks(citizenid)
        if decks.success and decks.data and #decks.data > 0 then
            table.sort(decks.data, function(a, b)
                return a.id < b.id
            end)
            Database.SetActiveDeck(citizenid, decks.data[1].id)
        end
    end

    return { success = true, data = {} }
end

--- @param citizenid string
--- @param deck_id number
function Deck.DuplicateDeck(citizenid, deck_id)
    if not assertDeckOwner(citizenid, deck_id) then
        return { success = false, error = '権限がありません' }
    end

    local cnt = Database.CountDecks(citizenid)
    if not cnt.success then
        return cnt
    end
    if cnt.data >= Config.MaxDecksPerPlayer then
        return { success = false, error = 'デッキ保有数が上限に達しています' }
    end

    local src = Database.GetDeckById(deck_id)
    if not src.success then
        return src
    end

    local d = src.data

    local need = {}
    for _, slot in ipairs(d.slots or {}) do
        if slot.card then
            local cid = slot.card.card_id
            need[cid] = (need[cid] or 0) + 1
        end
    end

    local inv = Database.GetPlayerCards(citizenid)
    if not inv.success then
        return inv
    end
    local owned = {}
    for _, row in ipairs(inv.data or {}) do
        owned[row.card_id] = (owned[row.card_id] or 0) + 1
    end
    for cid, n in pairs(need) do
        if (owned[cid] or 0) < n then
            return { success = false, error = '所持枚数が不足しているためコピーできません' }
        end
    end

    local newName = generateCopyName(citizenid, d.name)
    local created = Database.CreateDeck(citizenid, newName)
    if not created.success then
        return created
    end

    local newId = created.data and created.data.id
    if not newId then
        return { success = false, error = 'デッキコピーに失敗しました' }
    end

    for _, slot in ipairs(d.slots or {}) do
        if slot.card then
            local sc = Database.SetDeckCard(newId, slot.slot_index, slot.card.card_id)
            if not sc.success then
                return sc
            end
        end
    end

    return { success = true, data = { id = newId, name = newName } }
end

local function countFilledSlots(deckData)
    local n = 0
    for _, slot in ipairs(deckData.slots or {}) do
        if slot.card then
            n = n + 1
        end
    end
    return n
end

--- @param citizenid string
--- @param deck_id number
function Deck.SetActiveDeck(citizenid, deck_id)
    if not assertDeckOwner(citizenid, deck_id) then
        return { success = false, error = '権限がありません' }
    end

    local deck = Database.GetDeckById(deck_id)
    if not deck.success then
        return deck
    end

    if countFilledSlots(deck.data) < Config.DeckSize then
        return { success = false, error = '10枚揃ったデッキのみ使用設定できます' }
    end

    return Database.SetActiveDeck(citizenid, deck_id)
end

--- @param citizenid string
--- @param deck_id number
--- @param card_id string
function Deck.CanAddCardToDeck(citizenid, deck_id, card_id)
    if not assertDeckOwner(citizenid, deck_id) then
        return { success = false, error = '権限がありません' }
    end

    local master = MasterByCardId[card_id]
    if not master then
        return { success = true, data = { canAdd = false, reason = '存在しないカードです' } }
    end

    local deckR = Database.GetDeckById(deck_id)
    if not deckR.success then
        return deckR
    end
    local deckData = deckR.data

    local filled = countFilledSlots(deckData)
    if filled >= Config.DeckSize then
        return { success = true, data = { canAdd = false, reason = 'デッキが満杯です' } }
    end

    local cardsR = Database.GetPlayerCards(citizenid)
    if not cardsR.success then
        return cardsR
    end

    local owned = 0
    for _, row in ipairs(cardsR.data or {}) do
        if row.card_id == card_id then
            owned = owned + 1
        end
    end

    local inDeckSame = 0
    local shiteiInDeck = 0
    for _, slot in ipairs(deckData.slots or {}) do
        if slot.card then
            if slot.card.card_id == card_id then
                inDeckSame = inDeckSame + 1
            end
            local sm = MasterByCardId[slot.card.card_id]
            if sm and sm.type == 'shitei' then
                shiteiInDeck = shiteiInDeck + 1
            end
        end
    end

    if owned <= inDeckSame then
        return { success = true, data = { canAdd = false, reason = '所持枚数が不足しています' } }
    end

    local limitPerCard = (master.type == 'shitei') and Config.CardLimit.shitei or Config.CardLimit.free
    if inDeckSame >= limitPerCard then
        return {
            success = true,
            data = { canAdd = false, reason = 'このカードは既に上限まで編成されています' },
        }
    end

    if master.type == 'shitei' and shiteiInDeck >= Config.MaxShiteiPerDeck then
        return { success = true, data = { canAdd = false, reason = '指定カード上限です' } }
    end

    return { success = true, data = { canAdd = true } }
end

--- @param citizenid string
--- @param deck_id number
--- @param card_id string
function Deck.AddCardToDeck(citizenid, deck_id, card_id)
    local check = Deck.CanAddCardToDeck(citizenid, deck_id, card_id)
    if not check.success then
        return check
    end
    if not check.data.canAdd then
        return { success = false, error = check.data.reason or 'カードを追加できません' }
    end

    local deckR = Database.GetDeckById(deck_id)
    if not deckR.success then
        return deckR
    end

    local emptySlot
    for i = 1, Config.DeckSize do
        local sl = deckR.data.slots[i]
        if sl and not sl.card then
            emptySlot = i
            break
        end
    end

    if not emptySlot then
        return { success = false, error = 'デッキが満杯です' }
    end

    return Database.SetDeckCard(deck_id, emptySlot, card_id)
end

--- @param citizenid string
--- @param deck_id number
--- @param slot number
function Deck.RemoveCardFromDeck(citizenid, deck_id, slot)
    if not assertDeckOwner(citizenid, deck_id) then
        return { success = false, error = '権限がありません' }
    end

    return Database.RemoveDeckCard(deck_id, slot)
end
