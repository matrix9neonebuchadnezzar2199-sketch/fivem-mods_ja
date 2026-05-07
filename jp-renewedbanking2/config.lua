--[[
    Renewed-Banking 設定（日本語コメント版）
    原作: uShifty / Renewed-Scripts — CC BY-NC-SA 4.0
    キー名・値の型は本家互換のため変更しないこと。
]]

lib.locale()

Config = {
    -- フレームワークは起動リソースから自動検出（QB / QBX / ESX）。他は framework.lua で拡張。
    -- QB, QBX, and ESX preconfigured edit the framework.lua to add functionality to other frameworks
    renewedMultiJob = false, -- QBCORE のみ。Renewed qb-phone マルチジョブ: https://github.com/Renewed-Scripts/qb-phone
    progressbar = 'circle', -- circle または rectangle（circle 以外は矩形扱い）
    currency = 'USD', -- 通貨コード（USD, EUR, GBP 等）。表示は NUI 側 format に依存。
    -- 原作は ATM 利用時（ox_target の atm=true）に入金ボタンを出さない。日本語サーバーでは ATM 入金を期待する運営が多いため true 推奨。原作どおりにしたい場合は false。
    allowDepositAtAtm = true,
    atms = {
        `prop_atm_01`,
        `prop_atm_02`,
        `prop_atm_03`,
        `prop_fleeca_atm`
    },
    peds = {
        [1] = { -- Pacific Standard（口座作成メニューあり）
            model = 'u_m_m_bankman',
            coords = vector4(241.44, 227.19, 106.29, 170.43),
            createAccounts = true
        },
        [2] = {
            model = 'ig_barry',
            coords = vector4(313.84, -280.58, 54.16, 338.31)
        },
        [3] = {
            model = 'ig_barry',
            coords = vector4(149.46, -1042.09, 29.37, 335.43)
        },
        [4] = {
            model = 'ig_barry',
            coords = vector4(-351.23, -51.28, 49.04, 341.73)
        },
        [5] = {
            model = 'ig_barry',
            coords = vector4(-1211.9, -331.9, 37.78, 20.07)
        },
        [6] = {
            model = 'ig_barry',
            coords = vector4(-2961.14, 483.09, 15.7, 83.84)
        },
        [7] = {
            model = 'ig_barry',
            coords = vector4(1174.8, 2708.2, 38.09, 178.52)
        },
        [8] = { -- Paleto（口座作成メニューあり）
            model = 'u_m_m_bankman',
            coords = vector4(-112.22, 6471.01, 31.63, 134.18),
            createAccounts = true
        }
    }
}
