-- ============================================================
-- ヴェガ対話システム
-- 選択肢は ox_lib の registerContext ではサイズ変更不可のため自前 NUI（vega_context）を使用。
-- 台詞モーダルは引き続き lib.alertDialog。
-- ============================================================

MRD9 = MRD9 or {}

---ヴェガの台詞をモーダル対話ウィンドウで表示する。
---`lib.alertDialog` を同期呼出してプレイヤーが「進む」を押すまで待機。
---size='xl' で最大幅、ox_lib の標準モーダルでは最も大きい表示。
---@param text string
---@param duration integer|nil
local function vegaSay(text, duration)
    lib.alertDialog({
        header = _('vega_ui_title'),
        content = text,
        centered = true,
        cancel = false,
        size = 'xl',
        labels = { confirm = '進む' },
    })
end

local openFirstPitch
local openPitchDetail
local openContractPrompt
local executeContractSign
local openTutorial
local openTutorialQuestions
local openRepeatMainPanel
local openGateSubmenu
local openRepeatVisit
local openFlavorTalk

local function openFirstVisitFlow()
    CreateThread(function()
        vegaSay(_('vega_first_greeting'))
        Wait(2000)

        MRD9.VegaContextShow({
            title = _('vega_ui_title'),
            options = {
                {
                    title = _('vega_first_choice_other'),
                    icon = 'briefcase',
                    onSelect = function()
                        openFirstPitch()
                    end,
                },
                {
                    title = _('vega_first_choice_legal'),
                    icon = 'gavel',
                    onSelect = function()
                        vegaSay(_('vega_legal_decline'))
                    end,
                },
                {
                    title = _('vega_first_choice_wrong'),
                    icon = 'door-open',
                    onSelect = function() end,
                },
            },
        })
    end)
end

openFirstPitch = function()
    CreateThread(function()
        vegaSay(_('vega_first_how_did_you_know'))
        Wait(2000)

        MRD9.VegaContextShow({
            title = _('vega_first_how_did_you_know'),
            options = {
                { title = _('vega_source_bar'), onSelect = function() openPitchDetail() end },
                { title = _('vega_source_friend'), onSelect = function() openPitchDetail() end },
                { title = _('vega_source_intuition'), onSelect = function() openPitchDetail() end },
            },
        })
    end)
end

openPitchDetail = function()
    CreateThread(function()
        vegaSay(_('vega_first_pitch_1'), 4000)
        Wait(4500)
        vegaSay(_('vega_first_pitch_2'), 8000)
        Wait(8500)
        vegaSay(_('vega_first_pitch_3'), 9000)
        Wait(9500)
        vegaSay(_('vega_first_pitch_4'), 3000)
        Wait(3500)

        MRD9.VegaContextShow({
            title = _('vega_first_pitch_4'),
            options = {
                {
                    title = _('vega_first_choice_continue'),
                    icon = 'arrow-right',
                    onSelect = function()
                        openContractPrompt()
                    end,
                },
                {
                    title = _('vega_first_choice_refuse'),
                    icon = 'times',
                    onSelect = function()
                        vegaSay(_('vega_first_refuse_response'))
                    end,
                },
            },
        })
    end)
end

openContractPrompt = function()
    CreateThread(function()
        vegaSay(_('vega_first_contract_intro'), 6000)
        Wait(6500)
        vegaSay(_('vega_first_confidentiality'), 9000)
        Wait(9500)
        vegaSay(_('vega_first_contract_prompt'), 3000)
        Wait(3500)

        MRD9.VegaContextShow({
            title = _('vega_first_contract_prompt'),
            options = {
                {
                    title = _('vega_first_choice_sign'),
                    icon = 'file-signature',
                    onSelect = function()
                        executeContractSign()
                    end,
                },
                {
                    title = _('vega_first_choice_think'),
                    icon = 'clock',
                    onSelect = function()
                        vegaSay(_('vega_first_think_response'))
                    end,
                },
            },
        })
    end)
end

executeContractSign = function()
    CreateThread(function()
        local ok = lib.callback.await('jp-meridian9:server:signContract', false)
        if ok then
            vegaSay(_('vega_first_signed'), 4000)
            Wait(4500)
            openTutorial()
        else
            vegaSay(_('vega_contract_failed'))
        end
    end)
end

openTutorial = function()
    CreateThread(function()
        local lines = {
            _('vega_tutorial_1'),
            _('vega_tutorial_2'),
            _('vega_tutorial_3'),
            _('vega_tutorial_4'),
            _('vega_tutorial_5'),
            _('vega_tutorial_6'),
        }
        for _, line in ipairs(lines) do
            vegaSay(line, 7000)
            Wait(7500)
        end
        vegaSay(_('vega_tutorial_7'), 3000)
        Wait(3500)
        openTutorialQuestions()
    end)
end

openTutorialQuestions = function()
    MRD9.VegaContextShow({
        title = _('vega_tutorial_7'),
        options = {
            {
                title = _('vega_q_where'),
                onSelect = function()
                    CreateThread(function()
                        vegaSay(_('vega_a_where'))
                        Wait(3000)
                        openTutorialQuestions()
                    end)
                end,
            },
            {
                title = _('vega_q_enemy'),
                onSelect = function()
                    CreateThread(function()
                        vegaSay(_('vega_a_enemy'))
                        Wait(3000)
                        openTutorialQuestions()
                    end)
                end,
            },
            {
                title = _('vega_q_staff'),
                onSelect = function()
                    CreateThread(function()
                        vegaSay(_('vega_a_staff'))
                        Wait(3000)
                        openTutorialQuestions()
                    end)
                end,
            },
            {
                title = _('vega_q_max_reward'),
                onSelect = function()
                    CreateThread(function()
                        vegaSay(_('vega_a_max_reward'), 7000)
                        Wait(7200)
                        openTutorialQuestions()
                    end)
                end,
            },
            {
                title = _('vega_q_none'),
                icon = 'check',
                onSelect = function()
                    vegaSay(_('vega_tutorial_end'), 5000)
                end,
            },
        },
    })
end

openGateSubmenu = function()
    local opts = {}
    if Config.Party and Config.Party.allowSoloMission then
        opts[#opts + 1] = {
            title = _('gate_solo'),
            description = _('gate_solo_desc'),
            icon = 'user',
            onSelect = function()
                CreateThread(function()
                    local ok, err = lib.callback.await('jp-meridian9:server:partyCreate', false)
                    if not ok then
                        lib.notify({ description = _(err or 'err_unknown'), type = 'error' })
                        return
                    end
                    local ok2, err2 = lib.callback.await('jp-meridian9:server:partyConfirm', false)
                    if not ok2 then
                        lib.notify({ description = _(err2 or 'err_unknown'), type = 'error' })
                    end
                end)
            end,
        }
    end
    opts[#opts + 1] = {
        title = _('gate_party'),
        description = _('gate_party_desc'),
        icon = 'users',
        onSelect = function()
            CreateThread(function()
                local ok, err = lib.callback.await('jp-meridian9:server:partyCreate', false)
                if not ok then
                    lib.notify({ description = _(err or 'err_unknown'), type = 'error' })
                    return
                end
                TriggerEvent('jp-meridian9:client:openPartyMenu')
            end)
        end,
    }

    MRD9.VegaContextShow({
        title = _('vega_repeat_start_mission'),
        showBack = true,
        onBack = function()
            openRepeatMainPanel()
        end,
        options = opts,
    })
end

openRepeatMainPanel = function()
    MRD9.VegaContextShow({
        title = _('vega_ui_title'),
        options = {
            {
                title = _('vega_repeat_start_mission'),
                icon = 'play',
                onSelect = function()
                    openGateSubmenu()
                end,
            },
            {
                title = _('vega_repeat_info'),
                icon = 'info-circle',
                onSelect = function()
                    openFlavorTalk()
                end,
            },
            {
                title = _('vega_repeat_leave'),
                icon = 'door-open',
                onSelect = function()
                    vegaSay(_('vega_repeat_leave_response'))
                end,
            },
        },
    })
end

openRepeatVisit = function()
    CreateThread(function()
        vegaSay(_('vega_repeat_greeting'), 3000)
        Wait(1500)
        openRepeatMainPanel()
    end)
end

openFlavorTalk = function()
    local pack = Locales['ja']
    local flavors = pack and pack.vega_flavor
    if type(flavors) ~= 'table' or #flavors == 0 then
        vegaSay(_('vega_flavor_none'))
        return
    end
    local picked = flavors[math.random(#flavors)]
    vegaSay(picked, 8000)
end

RegisterNetEvent('jp-meridian9:client:openDialogue', function()
    CreateThread(function()
        MRD9.VegaContextHide()
        local contracted = lib.callback.await('jp-meridian9:server:isContracted', false)
        if contracted then
            openRepeatVisit()
        else
            openFirstVisitFlow()
        end
    end)
end)
