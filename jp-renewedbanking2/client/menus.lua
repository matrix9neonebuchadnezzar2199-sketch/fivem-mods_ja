--[[
    Renewed-Banking / client/menus.lua
    原作: uShifty (Renewed-Scripts) — CC BY-NC-SA 4.0
    ox_lib コンテキストメニューで口座作成・メンバー管理等を提供
]]

-- 口座管理メインメニュー（作成 / 既存管理）
RegisterNetEvent("Renewed-Banking:client:accountManagmentMenu", function()
    lib.registerContext({
        id = 'renewed_banking_account_management',
        title = locale("bank_name"),
        position = 'top-right',
        options = {
            {
                title = locale("create_account"),
                icon = 'file-invoice-dollar',
                metadata = {locale("create_account_txt")},
                event = "Renewed-Banking:client:createAccountMenu"
            },
            {
                title = locale("manage_account"),
                icon = 'users-gear',
                metadata = {locale("manage_account_txt")},
                event = 'Renewed-Banking:client:viewAccountsMenu'
            }
        }
    })
    lib.showContext("renewed_banking_account_management")
end)

-- 新規口座 ID 入力
RegisterNetEvent("Renewed-Banking:client:createAccountMenu", function()
    local input = lib.inputDialog(locale("bank_name"), {{
        type = "input",
        label = locale("account_id"),
        placeholder = "a_test_account"
    }})
    if input and input[1] then
        input[1] = input[1]:lower():gsub("%s+", "")
        TriggerServerEvent("Renewed-Banking:server:createNewAccount", input[1])
    end
end)

-- 作成済みサブ口座の一覧
RegisterNetEvent("Renewed-Banking:client:accountsMenu", function(data)
    local menuOpts = {}
    if #data >= 1 then
        for k=1, #data do
            menuOpts[#menuOpts+1] = {
                title = data[k],
                icon = 'users-gear',
                metadata = {locale("view_members")},
                event = "Renewed-Banking:client:accountsMenuView",
                args = {
                    account = data[k],
                }
            }
        end
    else
        menuOpts[#menuOpts+1] = {
            title = locale("no_account"),
            metadata = {locale("no_account_txt")},
        }
    end
    lib.registerContext({
        id = 'renewed_banking_account_list',
        title = locale("bank_name"),
        position = 'top-right',
        menu = "renewed_banking_account_management",
        options = menuOpts
    })
    lib.showContext("renewed_banking_account_list")
end)

-- 1 口座の詳細操作
RegisterNetEvent("Renewed-Banking:client:accountsMenuView", function(data)
    lib.registerContext({
        id = 'renewed_banking_account_view',
        title = locale("bank_name"),
        position = 'top-right',
        menu = "renewed_banking_account_list",
        options = {
            {
                title = locale("manage_members"),
                icon = 'users-gear',
                metadata = {locale("manage_members_txt")},
                serverEvent = "Renewed-Banking:server:viewMemberManagement",
                args = data
            },
            {
                title = locale("edit_acc_name"),
                icon = 'users-gear',
                metadata = {locale("edit_acc_name_txt")},
                event = "Renewed-Banking:client:changeAccountName",
                args = data
            },
            {
                title = locale("delete_account"),
                icon = 'users-gear',
                metadata = {locale("delete_account_txt")},
                serverEvent = "Renewed-Banking:server:deleteAccount",
                args = data
            }
        }
    })
    lib.showContext("renewed_banking_account_view")
end)

-- メンバー一覧と追加
RegisterNetEvent("Renewed-Banking:client:viewMemberManagement", function(data)
    local menuOpts = {}
    local account = data.account
    for k,v in pairs(data.members) do
        menuOpts[#menuOpts+1] = {
            title = v,
            metadata = {locale("remove_member_txt")},
            event = 'Renewed-Banking:client:removeMemberConfirmation',
            args = {
                account = account,
                cid = k,
            }
        }
    end
    menuOpts[#menuOpts+1] = {
        title = locale("add_member"),
        metadata = {locale("add_member_txt")},
        event = 'Renewed-Banking:client:addAccountMember',
        args = {
            account = account
        }
    }
    lib.registerContext({
        id = 'renewed_banking_member_manage',
        title = locale("bank_name"),
        position = 'top-right',
        menu = 'renewed_banking_account_view',
        options = menuOpts
    })
    lib.showContext("renewed_banking_member_manage")
end)

-- メンバー削除の確認
RegisterNetEvent('Renewed-Banking:client:removeMemberConfirmation', function(data)
    lib.registerContext({
        id = 'renewed_banking_member_remove',
        title = locale('bank_name'),
        position = 'top-right',
        menu = 'renewed_banking_account_view',
        options = {
            {
                title = locale('remove_member'),
                metadata = {locale('remove_member_txt2', data.cid)},
                serverEvent = 'Renewed-Banking:server:removeAccountMember',
                args = data
            }
        }
    })
    lib.showContext('renewed_banking_member_remove')
end)

-- Citizen ID 入力でメンバー追加
RegisterNetEvent('Renewed-Banking:client:addAccountMember', function(data)
    local input = lib.inputDialog(locale('add_account_member'), {{
        type = "input",
        label = locale('citizen_id'),
        placeholder = '1001'
    }})
    if input and input[1] then
        input[1] = input[1]:upper():gsub("%s+", "")
        TriggerServerEvent('Renewed-Banking:server:addAccountMember', data.account, input[1])
    end
end)

-- 口座 ID の変更入力
RegisterNetEvent('Renewed-Banking:client:changeAccountName', function(data)
    local input = lib.inputDialog(locale('change_account_name'), {{
        type = "input",
        label = locale('account_id'),
        placeholder = 'savings-1001'
    }})
    if input and input[1] then
        input[1] = input[1]:lower():gsub("%s+", "")
        TriggerServerEvent('Renewed-Banking:server:changeAccountName', data.account, input[1])
    end
end)
