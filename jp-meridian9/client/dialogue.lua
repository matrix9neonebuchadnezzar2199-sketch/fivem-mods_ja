-- ============================================================
-- ヴェガ対話システム（ox_lib context）
-- ============================================================

MRD9 = MRD9 or {}

---@param text string
---@param duration integer|nil
local function vegaSay(text, duration)
    duration = duration or 5000
    lib.notify({
        title = _('vega_ui_title'),
        description = text,
        duration = duration,
        position = 'bottom-center',
        type = 'inform',
        icon = 'user-tie',
        iconColor = '#3DA8E8',
    })
end

local openFirstPitch
local openPitchDetail
local openContractPrompt
local executeContractSign
local openTutorial
local openTutorialQuestions
local openRepeatVisit
local openFlavorTalk

local function openFirstVisitFlow()
    CreateThread(function()
        vegaSay(_('vega_first_greeting'))
        Wait(2000)

        lib.registerContext({
            id = 'm9_first_greeting',
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
        lib.showContext('m9_first_greeting')
    end)
end

openFirstPitch = function()
    CreateThread(function()
        vegaSay(_('vega_first_how_did_you_know'))
        Wait(2000)

        lib.registerContext({
            id = 'm9_first_source',
            title = _('vega_first_how_did_you_know'),
            options = {
                { title = _('vega_source_bar'), onSelect = function() openPitchDetail() end },
                { title = _('vega_source_friend'), onSelect = function() openPitchDetail() end },
                { title = _('vega_source_intuition'), onSelect = function() openPitchDetail() end },
            },
        })
        lib.showContext('m9_first_source')
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

        lib.registerContext({
            id = 'm9_first_interest',
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
        lib.showContext('m9_first_interest')
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

        lib.registerContext({
            id = 'm9_first_sign',
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
        lib.showContext('m9_first_sign')
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
    lib.registerContext({
        id = 'm9_tutorial_questions',
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
    lib.showContext('m9_tutorial_questions')
end

openRepeatVisit = function()
    CreateThread(function()
        vegaSay(_('vega_repeat_greeting'), 3000)
        Wait(1500)

        lib.registerContext({
            id = 'm9_repeat_main',
            title = _('vega_ui_title'),
            options = {
                {
                    title = _('vega_repeat_start_mission'),
                    icon = 'play',
                    onSelect = function()
                        TriggerEvent('jp-meridian9:client:openPartyMenu')
                    end,
                },
                {
                    title = _('vega_repeat_sell'),
                    icon = 'dollar-sign',
                    description = _('vega_repeat_sell_sub'),
                    onSelect = function()
                        vegaSay(_('vega_repeat_sell_wip'))
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
        lib.showContext('m9_repeat_main')
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
        local contracted = lib.callback.await('jp-meridian9:server:isContracted', false)
        if contracted then
            openRepeatVisit()
        else
            openFirstVisitFlow()
        end
    end)
end)
