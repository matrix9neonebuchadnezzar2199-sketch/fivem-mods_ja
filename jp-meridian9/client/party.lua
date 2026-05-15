-- ============================================================
-- パーティ編成 UI（INSTRUCTION-010）
-- ============================================================

MRD9 = MRD9 or {}

local currentParty = nil

---@param data table|nil
local function setCurrentParty(data)
    currentParty = data
end

---@param payload { text?: string, key?: string, args?: any[] }
local function showPartyError(payload)
    if not payload then
        return
    end
    local desc
    if payload.text then
        desc = payload.text
    elseif payload.key then
        if type(payload.args) == 'table' and #payload.args > 0 then
            desc = _(payload.key, table.unpack(payload.args))
        else
            desc = _(payload.key)
        end
    else
        desc = _('err_unknown')
    end
    lib.notify({ title = _('party_menu_title'), description = desc, type = 'error' })
end

local function refreshPartyState()
    local view = lib.callback.await('jp-meridian9:server:partyGetState', false)
    setCurrentParty(view)
    return view
end

local function openPartyMainMenu()
    local party = refreshPartyState()
    if not party then
        lib.notify({ title = _('party_menu_title'), description = _('err_not_in_party'), type = 'error' })
        return
    end

    if party.state == 'dispatched' then
        lib.notify({ title = _('party_menu_title'), description = _('party_dispatched'), type = 'inform' })
        return
    end

    local myId = GetPlayerServerId(PlayerId())
    local isLeader = party.leader == myId
    local n = #party.members
    local maxM = (Config.Party and Config.Party.maxMembers) or 5

    local options = {
        {
            title = _('party_member_list', n, maxM),
            icon = 'users',
            disabled = true,
        },
    }

    if isLeader and party.state == 'forming' and n < maxM then
        options[#options + 1] = {
            title = _('party_invite_nearby'),
            icon = 'user-plus',
            onSelect = function()
                local nearby = lib.callback.await('jp-meridian9:server:partyGetNearby', false)
                if not nearby or #nearby == 0 then
                    lib.notify({ description = _('party_no_nearby_players'), type = 'inform' })
                    openPartyMainMenu()
                    return
                end
                local sub = {}
                for _, pl in ipairs(nearby) do
                    local tid = pl.id
                    sub[#sub + 1] = {
                        title = pl.name,
                        description = ('ID %d'):format(tid),
                        onSelect = function()
                            local ok, err = lib.callback.await('jp-meridian9:server:partyInvite', false, tid)
                            if not ok then
                                showPartyError({ key = err or 'err_unknown' })
                            else
                                lib.notify({
                                    description = (_('party_invite_sent')):format(pl.name),
                                    type = 'success',
                                })
                            end
                            openPartyMainMenu()
                        end,
                    }
                end
                lib.registerContext({
                    id = 'mrd9_party_invite_nearby',
                    title = _('party_invite_nearby'),
                    menu = 'mrd9_party_main',
                    options = sub,
                })
                lib.showContext('mrd9_party_invite_nearby')
            end,
        }
    end

    if isLeader and party.state == 'forming' and n >= 2 then
        local kickOpts = {}
        for _, m in ipairs(party.members) do
            if m ~= party.leader then
                local mid = m
                local pid = GetPlayerFromServerId(mid)
                local name = (pid ~= -1 and GetPlayerName(pid)) or ('ID %d'):format(mid)
                kickOpts[#kickOpts + 1] = {
                    title = name,
                    description = _('party_kick_member'),
                    onSelect = function()
                        local ok, err = lib.callback.await('jp-meridian9:server:partyKick', false, mid)
                        if not ok then
                            showPartyError({ key = err or 'err_unknown' })
                        end
                        openPartyMainMenu()
                    end,
                }
            end
        end
        if #kickOpts > 0 then
            options[#options + 1] = {
                title = _('party_kick_select'),
                icon = 'user-minus',
                onSelect = function()
                    lib.registerContext({
                        id = 'mrd9_party_kick',
                        title = _('party_kick_select'),
                        menu = 'mrd9_party_main',
                        options = kickOpts,
                    })
                    lib.showContext('mrd9_party_kick')
                end,
            }
        end
    end

    if isLeader and party.state == 'forming' then
        options[#options + 1] = {
            title = _('party_confirm_dispatch'),
            icon = 'door-open',
            onSelect = function()
                local ok, err = lib.callback.await('jp-meridian9:server:partyConfirm', false)
                if not ok then
                    showPartyError({ key = err or 'err_unknown' })
                end
                setCurrentParty(nil)
            end,
        }
    end

    if not isLeader and party.state == 'forming' then
        options[#options + 1] = {
            title = _('party_leave'),
            icon = 'sign-out-alt',
            onSelect = function()
                local ok, err = lib.callback.await('jp-meridian9:server:partyLeave', false)
                if not ok then
                    showPartyError({ key = err or 'err_unknown' })
                end
                setCurrentParty(nil)
            end,
        }
    end

    if isLeader and party.state == 'forming' then
        options[#options + 1] = {
            title = _('party_disband'),
            icon = 'times-circle',
            onSelect = function()
                local ok, err = lib.callback.await('jp-meridian9:server:partyDisband', false)
                if not ok then
                    showPartyError({ key = err or 'err_unknown' })
                end
                setCurrentParty(nil)
            end,
        }
    end

    options[#options + 1] = {
        title = _('party_close_menu'),
        icon = 'xmark',
        onSelect = function() end,
    }

    lib.registerContext({
        id = 'mrd9_party_main',
        title = _('party_menu_title'),
        options = options,
    })
    lib.showContext('mrd9_party_main')
end

RegisterNetEvent('jp-meridian9:client:openPartyMenu', function()
    CreateThread(function()
        openPartyMainMenu()
    end)
end)

RegisterNetEvent('jp-meridian9:client:partyInviteReceived', function(data)
    if type(data) ~= 'table' or not data.partyId then
        return
    end
    CreateThread(function()
        local leaderName = data.leaderName or '?'
        local result = lib.alertDialog({
            header = _('party_invite_received_header'),
            content = (_('party_invite_received')):format(leaderName),
            centered = true,
            cancel = true,
            labels = {
                confirm = _('party_invite_accept'),
                cancel = _('party_invite_decline'),
            },
        })
        if result == 'confirm' then
            local ok, err = lib.callback.await('jp-meridian9:server:partyAccept', false, data.partyId)
            if not ok then
                showPartyError({ key = err or 'err_unknown' })
            end
        else
            lib.callback.await('jp-meridian9:server:partyDecline', false, data.partyId)
        end
    end)
end)

RegisterNetEvent('jp-meridian9:client:partyUpdated', function(view)
    if type(view) == 'table' then
        setCurrentParty(view)
    end
end)

RegisterNetEvent('jp-meridian9:client:partyDisbanded', function(payload)
    setCurrentParty(nil)
    if type(payload) == 'table' and payload.reason == 'kicked' then
        lib.notify({ title = _('party_menu_title'), description = _('party_you_were_kicked'), type = 'inform' })
    end
end)

RegisterNetEvent('jp-meridian9:client:partyInviteCancelled', function(payload)
    if type(payload) == 'table' and payload.reason == 'timeout' then
        lib.notify({ description = _('party_invite_timeout'), type = 'inform' })
    end
end)

RegisterNetEvent('jp-meridian9:client:partyError', function(payload)
    showPartyError(payload)
end)

RegisterNetEvent('jp-meridian9:client:partyMessage', function(payload)
    if type(payload) == 'table' and payload.message then
        lib.notify({ title = _('party_menu_title'), description = payload.message, type = 'inform' })
    end
end)
