-- ============================================================
-- MERIDIAN-9 パーティ編成（INSTRUCTION-010）
-- ============================================================

MRD9 = MRD9 or {}
MRD9.Party = {}

local parties = {}
local playerToParty = {}
local globalPendingInvite = {}
local partySeq = 0

---@return string
local function newPartyId()
    partySeq = partySeq + 1
    return ('party_%d_%d'):format(os.time(), partySeq)
end

local function maxMembers()
    local p = Config.Party
    return (p and p.maxMembers) or 5
end

local function minMembers()
    local p = Config.Party
    return (p and p.minMembers) or 1
end

local function inviteRange()
    local p = Config.Party
    return (p and p.inviteRange) or 10.0
end

local function inviteTimeoutSec()
    local p = Config.Party
    return (p and p.inviteTimeoutSeconds) or 30
end

local function autoPromote()
    local p = Config.Party
    return p and p.autoPromoteOnLeaderLeave ~= false
end

---@param src integer
---@return boolean
local function hasAdminAce(src)
    if type(src) ~= 'number' or src <= 0 then
        return false
    end
    local ace = Config.Admin and Config.Admin.aceName or 'jp-meridian9.admin'
    return IsPlayerAceAllowed(src, ace) == true
end

---@param a integer
---@param b integer
---@return number|nil
local function distanceBetweenPlayers(a, b)
    local pedA = GetPlayerPed(a)
    local pedB = GetPlayerPed(b)
    if not pedA or pedA == 0 or not pedB or pedB == 0 then
        return nil
    end
    local ca = GetEntityCoords(pedA)
    local cb = GetEntityCoords(pedB)
    return #(ca - cb)
end

---@param party table
---@return table
local function buildPartyView(party)
    return {
        partyId = party.id,
        leader = party.leader,
        members = party.members,
        state = party.state,
        sessionId = party.sessionId,
    }
end

---@param party table
---@param eventName string
---@param payload any
local function broadcastParty(party, eventName, payload)
    for _, m in ipairs(party.members) do
        TriggerClientEvent(eventName, m, payload)
    end
end

local function destroyParty(partyId, reason)
    local party = parties[partyId]
    if not party then
        return
    end

    for targetSrc in pairs(party.invites or {}) do
        globalPendingInvite[targetSrc] = nil
    end

    for _, m in ipairs(party.members) do
        playerToParty[m] = nil
        TriggerClientEvent('jp-meridian9:client:partyDisbanded', m, { partyId = partyId, reason = reason or 'disbanded' })
    end

    parties[partyId] = nil
end

---@param party table
---@param src integer
local function removeMemberFromList(party, src)
    for i, m in ipairs(party.members) do
        if m == src then
            table.remove(party.members, i)
            break
        end
    end
    playerToParty[src] = nil
end

---@param src integer
---@return table|nil
function MRD9.Party.GetByPlayer(src)
    if type(src) ~= 'number' or src <= 0 then
        return nil
    end
    local id = playerToParty[src]
    if not id then
        return nil
    end
    return parties[id]
end

---@param partyId string|nil
---@return table|nil
function MRD9.Party.Get(partyId)
    if not partyId then
        return nil
    end
    return parties[partyId]
end

---@return table
function MRD9.Party.GetAll()
    return parties
end

---@param sessionId string
function MRD9.Party.NotifySessionDestroyed(sessionId)
    for pid, p in pairs(parties) do
        if p.state == 'dispatched' and p.sessionId == sessionId then
            for _, m in ipairs(p.members) do
                TriggerClientEvent('jp-meridian9:client:partyDisbanded', m, { partyId = pid, reason = 'session_ended' })
                playerToParty[m] = nil
            end
            parties[pid] = nil
            return
        end
    end
end

---@param partyId string
---@return boolean, string|nil
function MRD9.Party.PromoteLeader(partyId)
    local party = parties[partyId]
    if not party then
        return false, 'party_not_found'
    end
    if #party.members < 1 then
        destroyParty(partyId, 'no_members')
        return false, 'no_members_left'
    end
    party.leader = party.members[1]
    local name = GetPlayerName(party.leader) or ('ID %d'):format(party.leader)
    broadcastParty(party, 'jp-meridian9:client:partyMessage', { message = _('party_leader_promoted', name) })
    broadcastParty(party, 'jp-meridian9:client:partyUpdated', buildPartyView(party))
    return true, nil
end

---@param src integer
function MRD9.Party.HandleDisconnect(src)
    if type(src) ~= 'number' or src <= 0 then
        return
    end

    local party = MRD9.Party.GetByPlayer(src)
    if not party then
        if globalPendingInvite[src] then
            globalPendingInvite[src] = nil
        end
        return
    end

    if party.state == 'dispatched' then
        return
    end

    if party.invites and party.invites[src] then
        party.invites[src] = nil
        globalPendingInvite[src] = nil
    end

    local wasLeader = party.leader == src
    removeMemberFromList(party, src)

    if #party.members == 0 then
        destroyParty(party.id, 'empty')
        return
    end

    if wasLeader then
        if autoPromote() then
            MRD9.Party.PromoteLeader(party.id)
        else
            destroyParty(party.id, 'leader_left')
        end
    else
        broadcastParty(party, 'jp-meridian9:client:partyUpdated', buildPartyView(party))
    end
end

---@param leaderSrc integer
---@return string|nil, string|nil
function MRD9.Party.Create(leaderSrc)
    if type(leaderSrc) ~= 'number' or leaderSrc <= 0 then
        return nil, 'err_unknown'
    end

    if MRD9.Session.GetByPlayer(leaderSrc) then
        return nil, 'err_target_in_session'
    end

    local existing = MRD9.Party.GetByPlayer(leaderSrc)
    if existing and existing.state ~= 'dispatched' then
        return existing.id, nil
    end

    local ident = MRD9.GetIdentifier(leaderSrc)
    if not ident or not MRD9.Contract.IsContracted(ident) then
        return nil, 'err_target_not_contracted'
    end

    local id = newPartyId()
    local party = {
        id = id,
        leader = leaderSrc,
        members = { leaderSrc },
        invites = {},
        createdAt = os.time(),
        state = 'forming',
        sessionId = nil,
    }
    parties[id] = party
    playerToParty[leaderSrc] = id

    TriggerClientEvent('jp-meridian9:client:partyUpdated', leaderSrc, buildPartyView(party))
    return id, nil
end

---@param leaderSrc integer
---@param targetSrc integer
---@return boolean, string|nil
function MRD9.Party.Invite(leaderSrc, targetSrc)
    if type(leaderSrc) ~= 'number' or type(targetSrc) ~= 'number' or targetSrc <= 0 then
        return false, 'err_unknown'
    end

    local party = MRD9.Party.GetByPlayer(leaderSrc)
    if not party or party.leader ~= leaderSrc then
        return false, 'err_not_leader'
    end
    if party.state ~= 'forming' then
        return false, 'err_unknown'
    end

    if targetSrc == leaderSrc then
        return false, 'err_unknown'
    end

    if #party.members >= maxMembers() then
        return false, 'err_party_full'
    end

    local tid = MRD9.GetIdentifier(targetSrc)
    if not tid or not MRD9.Contract.IsContracted(tid) then
        return false, 'err_target_not_contracted'
    end

    if MRD9.Party.GetByPlayer(targetSrc) then
        return false, 'err_target_in_party'
    end

    if MRD9.Session.GetByPlayer(targetSrc) then
        return false, 'err_target_in_session'
    end

    if globalPendingInvite[targetSrc] and globalPendingInvite[targetSrc] ~= party.id then
        return false, 'err_invite_pending_elsewhere'
    end

    local dist = distanceBetweenPlayers(leaderSrc, targetSrc)
    if not dist or dist > inviteRange() then
        return false, 'err_target_too_far'
    end

    if party.invites[targetSrc] then
        return false, 'err_unknown'
    end

    local token = math.random(1, 2147483647)
    local now = os.time()
    party.invites[targetSrc] = {
        invitedAt = now,
        expiresAt = now + inviteTimeoutSec(),
        timeoutToken = token,
    }
    globalPendingInvite[targetSrc] = party.id

    local leaderName = GetPlayerName(leaderSrc) or ('ID %d'):format(leaderSrc)
    TriggerClientEvent('jp-meridian9:client:partyInviteReceived', targetSrc, {
        partyId = party.id,
        leaderName = leaderName,
        expiresAt = party.invites[targetSrc].expiresAt,
    })

    local ms = inviteTimeoutSec() * 1000
    CreateThread(function()
        Wait(ms)
        local p = parties[party.id]
        if not p or p.state ~= 'forming' then
            return
        end
        local inv = p.invites and p.invites[targetSrc]
        if not inv or inv.timeoutToken ~= token then
            return
        end
        p.invites[targetSrc] = nil
        globalPendingInvite[targetSrc] = nil
        TriggerClientEvent('jp-meridian9:client:partyInviteCancelled', targetSrc, { partyId = party.id, reason = 'timeout' })
        TriggerClientEvent('jp-meridian9:client:partyError', leaderSrc, { text = _('party_invite_timeout') })
    end)

    return true, nil
end

---@param targetSrc integer
---@param partyId string|nil
---@return boolean, string|nil
function MRD9.Party.Accept(targetSrc, partyId)
    if type(targetSrc) ~= 'number' or not partyId then
        return false, 'err_unknown'
    end

    local party = parties[partyId]
    if not party or party.state ~= 'forming' then
        return false, 'err_no_pending_invite'
    end

    local inv = party.invites and party.invites[targetSrc]
    if not inv then
        return false, 'err_no_pending_invite'
    end

    if os.time() > inv.expiresAt then
        party.invites[targetSrc] = nil
        globalPendingInvite[targetSrc] = nil
        return false, 'err_invite_expired'
    end

    if MRD9.Party.GetByPlayer(targetSrc) then
        return false, 'err_already_in_party'
    end

    if MRD9.Session.GetByPlayer(targetSrc) then
        return false, 'err_target_in_session'
    end

    if #party.members >= maxMembers() then
        return false, 'err_party_full'
    end

    inv.timeoutToken = 0
    party.invites[targetSrc] = nil
    globalPendingInvite[targetSrc] = nil

    party.members[#party.members + 1] = targetSrc
    playerToParty[targetSrc] = party.id

    local tname = GetPlayerName(targetSrc) or ('ID %d'):format(targetSrc)
    broadcastParty(party, 'jp-meridian9:client:partyMessage', { message = _('party_member_joined', tname) })
    broadcastParty(party, 'jp-meridian9:client:partyUpdated', buildPartyView(party))

    return true, nil
end

---@param targetSrc integer
---@param partyId string|nil
---@return boolean, string|nil
function MRD9.Party.Decline(targetSrc, partyId)
    if type(targetSrc) ~= 'number' or not partyId then
        return false, 'err_unknown'
    end

    local party = parties[partyId]
    if not party or party.state ~= 'forming' then
        return false, 'err_no_pending_invite'
    end

    if not party.invites or not party.invites[targetSrc] then
        return false, 'err_no_pending_invite'
    end

    party.invites[targetSrc].timeoutToken = 0
    party.invites[targetSrc] = nil
    globalPendingInvite[targetSrc] = nil

    local tname = GetPlayerName(targetSrc) or ('ID %d'):format(targetSrc)
    TriggerClientEvent('jp-meridian9:client:partyMessage', party.leader, { message = _('party_invite_declined', tname) })

    return true, nil
end

---@param memberSrc integer
---@return boolean, string|nil
function MRD9.Party.Leave(memberSrc)
    local party = MRD9.Party.GetByPlayer(memberSrc)
    if not party or party.state ~= 'forming' then
        return false, 'err_not_in_party'
    end

    local wasLeader = party.leader == memberSrc
    removeMemberFromList(party, memberSrc)

    local mname = GetPlayerName(memberSrc) or ('ID %d'):format(memberSrc)
    if #party.members == 0 then
        destroyParty(party.id, 'all_left')
        return true, nil
    end

    broadcastParty(party, 'jp-meridian9:client:partyMessage', { message = _('party_member_left', mname) })

    if wasLeader then
        if autoPromote() then
            MRD9.Party.PromoteLeader(party.id)
        else
            destroyParty(party.id, 'leader_left')
        end
    else
        broadcastParty(party, 'jp-meridian9:client:partyUpdated', buildPartyView(party))
    end

    return true, nil
end

---@param leaderSrc integer
---@param targetSrc integer
---@return boolean, string|nil
function MRD9.Party.Kick(leaderSrc, targetSrc)
    local party = MRD9.Party.GetByPlayer(leaderSrc)
    if not party or party.leader ~= leaderSrc then
        return false, 'err_not_leader'
    end
    if party.state ~= 'forming' then
        return false, 'err_unknown'
    end
    if targetSrc == leaderSrc then
        return false, 'err_unknown'
    end

    local found = false
    for _, m in ipairs(party.members) do
        if m == targetSrc then
            found = true
            break
        end
    end
    if not found then
        return false, 'err_unknown'
    end

    removeMemberFromList(party, targetSrc)
    TriggerClientEvent('jp-meridian9:client:partyDisbanded', targetSrc, { partyId = party.id, reason = 'kicked' })

    local tname = GetPlayerName(targetSrc) or ('ID %d'):format(targetSrc)
    broadcastParty(party, 'jp-meridian9:client:partyMessage', { message = _('party_member_kicked', tname) })
    broadcastParty(party, 'jp-meridian9:client:partyUpdated', buildPartyView(party))

    return true, nil
end

---@param leaderSrc integer
---@return boolean, string|nil
function MRD9.Party.Disband(leaderSrc)
    local party = MRD9.Party.GetByPlayer(leaderSrc)
    if not party or party.leader ~= leaderSrc then
        return false, 'err_not_leader'
    end
    if party.state ~= 'forming' then
        return false, 'err_unknown'
    end

    destroyParty(party.id, 'disbanded')
    return true, nil
end

---@param leaderSrc integer
---@return boolean, string|nil
function MRD9.Party.Confirm(leaderSrc)
    local party = MRD9.Party.GetByPlayer(leaderSrc)
    if not party or party.leader ~= leaderSrc then
        return false, 'err_not_leader'
    end
    if party.state ~= 'forming' then
        return false, 'err_unknown'
    end

    local pendingInv = 0
    for _ in pairs(party.invites or {}) do
        pendingInv = pendingInv + 1
    end
    if pendingInv > 0 then
        return false, 'err_pending_invites'
    end

    if #party.members < minMembers() then
        return false, 'err_party_too_few'
    end

    for _, m in ipairs(party.members) do
        if GetPlayerName(m) == nil then
            return false, 'err_target_offline'
        end
        local idf = MRD9.GetIdentifier(m)
        if not idf or not MRD9.Contract.IsContracted(idf) then
            return false, 'err_target_not_contracted'
        end
        if MRD9.Session.GetByPlayer(m) then
            return false, 'err_target_in_session'
        end
    end

    party.state = 'confirming'

    local sessionId, sErr = MRD9.Session.Create({
        leader = party.leader,
        members = party.members,
    })

    if not sessionId then
        party.state = 'forming'
        TriggerClientEvent('jp-meridian9:client:partyError', leaderSrc, { text = _('err_session_create_failed', sErr or 'unknown') })
        return false, sErr or 'err_unknown'
    end

    local okTransfer, tErr = MRD9.Session.TransferIn(sessionId)
    if not okTransfer then
        MRD9.Session.Destroy(sessionId, 'transfer_failed')
        party.state = 'forming'
        TriggerClientEvent('jp-meridian9:client:partyError', leaderSrc, { text = _('err_session_create_failed', tErr or 'transfer') })
        return false, tErr or 'err_unknown'
    end

    party.sessionId = sessionId
    party.state = 'dispatched'

    broadcastParty(party, 'jp-meridian9:client:partyMessage', { message = _('party_dispatched') })
    broadcastParty(party, 'jp-meridian9:client:partyUpdated', buildPartyView(party))

    return true, nil
end

-- ============================================================
-- lib.callback
-- ============================================================

lib.callback.register('jp-meridian9:server:partyCreate', function(source)
    local src = source
    if not src or src <= 0 then
        return false, 'err_unknown'
    end
    local id, err = MRD9.Party.Create(src)
    if not id then
        return false, err or 'err_unknown'
    end
    return true, id
end)

lib.callback.register('jp-meridian9:server:partyGetState', function(source)
    local src = source
    if not src or src <= 0 then
        return nil
    end
    local party = MRD9.Party.GetByPlayer(src)
    if not party then
        return nil
    end
    return buildPartyView(party)
end)

lib.callback.register('jp-meridian9:server:partyInvite', function(source, targetServerId)
    local src = source
    if not src or src <= 0 then
        return false, 'err_unknown'
    end
    if type(targetServerId) ~= 'number' or targetServerId <= 0 then
        return false, 'err_unknown'
    end
    local ok, err = MRD9.Party.Invite(src, targetServerId)
    if not ok then
        return false, err or 'err_unknown'
    end
    return true, nil
end)

lib.callback.register('jp-meridian9:server:partyAccept', function(source, partyId)
    local src = source
    if not src or src <= 0 or type(partyId) ~= 'string' then
        return false, 'err_unknown'
    end
    local ok, err = MRD9.Party.Accept(src, partyId)
    if not ok then
        return false, err or 'err_unknown'
    end
    return true, nil
end)

lib.callback.register('jp-meridian9:server:partyDecline', function(source, partyId)
    local src = source
    if not src or src <= 0 or type(partyId) ~= 'string' then
        return false, 'err_unknown'
    end
    local ok, err = MRD9.Party.Decline(src, partyId)
    if not ok then
        return false, err or 'err_unknown'
    end
    return true, nil
end)

lib.callback.register('jp-meridian9:server:partyLeave', function(source)
    local src = source
    if not src or src <= 0 then
        return false, 'err_unknown'
    end
    local ok, err = MRD9.Party.Leave(src)
    if not ok then
        return false, err or 'err_unknown'
    end
    return true, nil
end)

lib.callback.register('jp-meridian9:server:partyKick', function(source, targetServerId)
    local src = source
    if not src or src <= 0 then
        return false, 'err_unknown'
    end
    if type(targetServerId) ~= 'number' or targetServerId <= 0 then
        return false, 'err_unknown'
    end
    local ok, err = MRD9.Party.Kick(src, targetServerId)
    if not ok then
        return false, err or 'err_unknown'
    end
    return true, nil
end)

lib.callback.register('jp-meridian9:server:partyDisband', function(source)
    local src = source
    if not src or src <= 0 then
        return false, 'err_unknown'
    end
    local ok, err = MRD9.Party.Disband(src)
    if not ok then
        return false, err or 'err_unknown'
    end
    return true, nil
end)

lib.callback.register('jp-meridian9:server:partyConfirm', function(source)
    local src = source
    if not src or src <= 0 then
        return false, 'err_unknown'
    end
    local ok, err = MRD9.Party.Confirm(src)
    if not ok then
        return false, err or 'err_unknown'
    end
    return true, nil
end)

lib.callback.register('jp-meridian9:server:partyGetNearby', function(source)
    local src = source
    if not src or src <= 0 then
        return {}
    end

    local party = MRD9.Party.GetByPlayer(src)
    if not party or party.leader ~= src then
        return {}
    end

    local out = {}
    for _, sidStr in ipairs(GetPlayers()) do
        local other = tonumber(sidStr)
        if other and other > 0 and other ~= src then
            local dist = distanceBetweenPlayers(src, other)
            if dist and dist <= inviteRange() then
                out[#out + 1] = {
                    id = other,
                    name = GetPlayerName(other) or ('ID %d'):format(other),
                }
            end
        end
    end
    return out
end)

-- ============================================================
-- デバッグコマンド
-- ============================================================

if Config.Debug then
    RegisterCommand('m9_party_status', function(source)
        if source == 0 then
            return
        end
        local p = MRD9.Party.GetByPlayer(source)
        if not p then
            TriggerClientEvent('chat:addMessage', source, { args = { '[MRD9]', 'パーティ未所属' } })
            return
        end
        local mem = table.concat(p.members, ', ')
        TriggerClientEvent(
            'chat:addMessage',
            source,
            { args = { '[MRD9]', ('party=%s leader=%d state=%s members=[%s]'):format(p.id, p.leader, p.state, mem) } }
        )
    end, false)

    RegisterCommand('m9_party_list', function(source)
        if source == 0 then
            for pid, p in pairs(parties) do
                print(('[jp-meridian9] party %s leader=%d state=%s members=%d'):format(pid, p.leader, p.state, #p.members))
            end
            return
        end
        if not hasAdminAce(source) then
            return
        end
        local n = 0
        for pid, p in pairs(parties) do
            n = n + 1
            TriggerClientEvent(
                'chat:addMessage',
                source,
                { args = { '[MRD9]', ('%s leader=%d state=%s n=%d'):format(pid, p.leader, p.state, #p.members) } }
            )
        end
        if n == 0 then
            TriggerClientEvent('chat:addMessage', source, { args = { '[MRD9]', 'アクティブパーティなし' } })
        end
    end, false)
end
