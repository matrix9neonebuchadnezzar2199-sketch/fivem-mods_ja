# TECTON

**A builder’s toolkit for FiveM**

Japanese-first docs live under [`docs/ja/`](docs/ja/) (start with [`docs/ja/spec.md`](docs/ja/spec.md)).

| | |
| --- | --- |
| **License** | [LGPL-3.0-or-later](LICENSE) |
| **Status** | **WIP** — repository scaffold only; no builder UI or DB wiring yet. |
| **Resource name** | `tecton` (folder may be `tecton-fivem`; match `ensure` to folder name) |

## Database（初回必須）

oxmysql が接続している **同じデータベース**（例: `fivem_db`）に、[`sql/install.sql`](sql/install.sql) を実行する。未実行だと `Table 'fivem_db.tec_objects' doesn't exist` のように INSERT が失敗する。

HeidiSQL / phpMyAdmin / CLI などで `install.sql` を丸ごと流せばよい（`tec_objects`, `tec_history`, `tec_autosave`, `tec_user_prefs` が作成される）。

## Credits

- **Prop categorization data** derived from [ShiftyWreckzz/prop-list](https://github.com/ShiftyWreckzz/prop-list) (GPL-3.0). Original listings trace to **Menyoo** (GPL-3.0). Regenerated into `config/props.lua` via `npm run build:props` — see file header and [CONTRIBUTING.md](CONTRIBUTING.md).
- **Runtime / UI stack**: [ox_lib](https://github.com/overextended/ox_lib), [oxmysql](https://github.com/overextended/ox_mysql). [object_gizmo](https://github.com/Demigod916/object_gizmo) は **fxmanifest の必須依存には含めない**（サーバーに無いと `ensure` が失敗するため）。配置・ギズモを使うときは別途リソースとして入れ、`ensure object_gizmo` のあとに tecton を使う。 [ox_inventory](https://github.com/overextended/ox_inventory), [ox_doorlock](https://github.com/overextended/ox_doorlock) は `docs/ja/spec.md` に従い任意連携。
