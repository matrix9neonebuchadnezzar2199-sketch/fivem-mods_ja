return {

    ----------------------------------------------
    --        💬 Setup logging system
    ----------------------------------------------

    logs = {
        -- What logging service do you want to use?
        -- Available options: 'fivemanage', 'fivemerr', 'discord' & 'none'
        -- It is highly recommended to use a proper logging service such as Fivemanage or Fivemerr
        service = 'none',
        -- Do you want to include screenshots with your logs?
        -- This is only applicable to Fivemanage and Fivemerr
        screenshots = false,
        -- You can enable (true) or disable (false) specific player events to log here
        events = {
            -- 'mined' is when a player mines a rock
            mined = false,
            -- 'smelted' is when a player smelts an ingot
            smelted = false,
            -- 'purchase' is when a player makes a purchase from shop
            purchased = false,
            -- 'pawned' is when a player pawns an item
            pawned = false,
        },
        -- If service = 'discord', you can customize the webhook data here
        -- If not using Discord, this section can be ignored
        discord = {
            -- The name of the webhook
            name = 'Mining Logs',
            -- The webhook link
            link = '',
            -- The webhook profile image
            image = 'https://i.imgur.com/ILTkWBh.png',
            -- The webhook footer image
            footer = 'https://i.imgur.com/ILTkWBh.png'
        }
    },

    -- 管理者: 採掘レベル上書き。ゲーム内は mining_setlevel [id] [lv]、省略時 lv=5
    -- ACE の付け方: ゲーム内のチャットで add_ace を打っても**サーバには入らない**。次のいずれかに書く:
    --   ・server.cfg に1行入れて from 0 で再起動、または
    --   ・txAdmin 左の「**サーバーコンソール**」（F8/ゲーム内ではない）に貼る
    -- 例1: 管理者名義に一括（group.admin 所属者）
    --   add_ace group.admin command.mining_setlevel allow
    -- 例2: 自分の識別子だけ直付け（QBCore 等で group に入れない人向け）
    --   add_ace identifier.license:xxxxxxxx command.mining_setlevel allow
    -- 権限が無い人がコマンドを使うと通知のみ拒否（エンジン側の Access denied にはならないようRegisterは非制限）
    admin = {
        command = 'mining_setlevel',
        ace = 'command.mining_setlevel',
    },

}