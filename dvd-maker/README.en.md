# DVD Maker for FiveM

<p align="right"><strong>English</strong> · <a href="./README.md">日本語</a></p>

<p align="center">
  <a href="./LICENSE"><img src="https://img.shields.io/badge/License-MIT-326CB5?style=flat-square" alt="MIT License"></a>
  <a href="https://www.lua.org/"><img src="https://img.shields.io/badge/Lua-5.4-000080?style=flat-square&logo=lua&logoColor=white" alt="Lua 5.4"></a>
  <img src="https://img.shields.io/badge/FiveM-cerulean-111111?style=flat-square" alt="FiveM">
  <a href="https://github.com/overextended/ox_inventory"><img src="https://img.shields.io/badge/ox__inventory-required-EF7F31?style=flat-square" alt="ox_inventory required"></a>
</p>

<p align="center">
  <sub>Standalone resource · Vanilla JS NUI · YouTube IFrame API · Server-side URL validation</sub>
</p>

---

## Table of contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#install)
- [Usage (players)](#usage)
- [Tall case: host cover art on GitHub](#github-cover-images)
- [Metadata (reference)](#metadata)
- [Configuration](#config)
- [Known limitations](#limitations)
- [Migrating from older versions](#migration)
- [License](#license)
- [Contributing](#contributing)

---

<a id="features"></a>

## Features

- **Record to a blank DVD**: choose package type, title (max length configurable), YouTube URL — optional **cover image URL** for **tall case** only → grants one recorded DVD of the matching type (consumes one blank DVD).
- **Playback**: open the recorded item → menu → play in an embedded YouTube IFrame.
- **Inventory label**: metadata includes **`label = title`**, so the slot shows the title (ox_inventory behaviour).
- **Video source**: only allowlisted YouTube hosts (`youtube.com` / `youtu.be` / `m.youtube.com`).

<a id="requirements"></a>

## Requirements

- A FiveM server (recent server artifacts recommended).
- **[ox_inventory](https://github.com/overextended/ox_inventory)** — dedicated integration; **not** a generic ESX / QBCore bridge (those frameworks are **not** required).

<a id="install"></a>

## Installation (follow in order)

### 1. Copy the resource

Copy this entire folder under your server’s `resources` tree.  
The **folder name becomes the resource name** (e.g. `resources/[standalone]/dvd-maker`).

These instructions assume the resource is named **`dvd-maker`**. If you rename the folder, replace **`dvd-maker`** everywhere in steps 3–4 (exports, `ensure` name).

### 2. Start it from `server.cfg`

Add (match your folder name):

```cfg
ensure dvd-maker
```

### 3. Copy icon PNGs into ox_inventory

Copy these **four** files from this resource’s `html/img/` into ox_inventory’s image folder (commonly `ox_inventory/web/images/`).

| File | Role |
|------|------|
| `disc_128_tight.png` | **Blank DVD** (`dvd_blank`) only — plain disc art |
| `dvd_case_128_tight.png` | Recorded — **paper sleeve** (`dvd_recorded1`) |
| `dvd_jewel_transparent_128.png` | Recorded — **clear jewel case** (`dvd_recorded2`) |
| `dvd_case_text_transparent_128.png` | Recorded — **tall case** (`dvd_recorded3`); also used in the NUI as the case graphic |

**Filenames must match the table** and align with `client.image` in `items.lua`.

### 4. Register items in ox_inventory

**Typical file**: `ox_inventory/data/items.lua`  
(If your project splits items across files, paste into whichever file owns item definitions.)

Inside `return { ... }`, paste the block below. If it follows another item, ensure the **previous entry ends with a comma**.

```lua
    -- DVD Maker: blank DVD (before recording)
    ['dvd_blank'] = {
        label = 'DVD (blank)',
        weight = 20,
        stack = true,
        close = true,
        description = 'A blank DVD with nothing recorded yet',
        client = {
            image = 'disc_128_tight.png',
            export = 'dvd-maker.useBlank',
        },
    },

    -- DVD Maker: recorded (paper sleeve)
    ['dvd_recorded1'] = {
        label = 'DVD (paper sleeve)',
        weight = 20,
        stack = false,
        close = true,
        description = 'A recorded DVD in a paper sleeve',
        client = {
            image = 'dvd_case_128_tight.png',
            export = 'dvd-maker.useRecorded',
        },
    },

    -- DVD Maker: recorded (clear case)
    ['dvd_recorded2'] = {
        label = 'DVD (clear case)',
        weight = 20,
        stack = false,
        close = true,
        description = 'A recorded DVD in a clear jewel case',
        client = {
            image = 'dvd_jewel_transparent_128.png',
            export = 'dvd-maker.useRecorded',
        },
    },

    -- DVD Maker: recorded (tall case)
    ['dvd_recorded3'] = {
        label = 'DVD (tall case)',
        weight = 20,
        stack = false,
        close = true,
        description = 'A recorded DVD in a tall case',
        client = {
            image = 'dvd_case_text_transparent_128.png',
            export = 'dvd-maker.useRecorded',
        },
    },
```

If the resource folder is **not** `dvd-maker`, only change the **`export`** prefix to match (e.g. `my-dvd-mod.useBlank`).

**Match `config.lua`**: `Config.BlankItem` and `Config.RecordedByPack` must use the **same strings** as the keys above (`dvd_blank`, `dvd_recorded1`–`3`).

| Field | Meaning |
|-------|---------|
| `stack = true` (blank) | Blank DVDs may stack |
| `stack = false` (recorded) | **Required** — each slot must keep its own metadata |
| `client.image` | PNG filename under `ox_inventory/web/images/` |
| `client.export` | All three recorded types may share **`dvd-maker.useRecorded`**; **slot item name** (`dvd_recorded1`–`3`) selects the package art |

**Tall selected but wrong inventory art?** (1) Confirm `['dvd_recorded3'].client.image` is **`dvd_case_text_transparent_128.png`**. (2) New recordings set `metadata.image` to the **basename without `.png`**; older slots may need **re-recording** to pick up fixes.

### 5. Reload on the server

In the server console or txAdmin:

```
refresh
ensure dvd-maker
restart ox_inventory
```

After editing `items.lua`, **`restart ox_inventory`** is usually required.

---

<a id="usage"></a>

## Usage (players)

1. Use **blank DVD** in inventory → recording UI.  
2. Choose **package type** (paper sleeve / clear / tall), enter **title** and **YouTube URL**. For **tall** only, optionally paste a **cover image URL (`https`)** → Save.  
3. One blank DVD is removed; one **recorded** DVD of the chosen type is added (inventory label shows the title).  
4. Use the recorded DVD → playback menu → **Play**. For **tall**, the menu shows a **large cover preview on the left** and **case art on the right**; click the cover for a **lightbox** (close with `Esc` or **Close**). If the URL cannot be loaded, an error message appears in the left panel.

> Slot **grid size** is controlled by **ox_inventory’s UI**, not this resource (higher-res PNGs may look slightly sharper).

<a id="github-cover-images"></a>

## Tall case: host cover art on GitHub (step-by-step)

The tall-case **cover URL** must be an **HTTPS URL that returns image bytes** suitable for `<img src>`. A practical free option is a **public** GitHub repository (anyone with the URL can fetch the image — **private repos are a poor fit**).

### 1. Create an account and repository

1. Sign up / log in at [GitHub](https://github.com).  
2. **+** → **New repository**.  
3. **Repository name** — e.g. `my-server-dvd-covers`.  
4. Visibility: **Public**.  
5. **Create repository**.

### 2. Add image files

1. Open the repository page.  
2. **Add file** → **Upload files**.  
3. Drag and drop your **PNG** (or other image) files.  
   - For a subfolder like `covers/`, use **Add file** → **Create new file**, set the filename to **`covers/.gitkeep`** (the slash creates the folder), commit, then upload images into `covers/`.  
4. **Commit changes**.

Prefer **ASCII filenames** (`a-z`, `0-9`, `-`, `_`) to keep URLs short and predictable.

### 3. Copy the URL you paste into the game (important)

| URL shape | In-game (this resource) |
|-----------|-------------------------|
| `https://raw.githubusercontent.com/…` | **Use as-is** (recommended) |
| `https://github.com/…/blob/…/file.png` | **Auto-rewritten to raw** on save & playback |
| Repo home, folder browser, `github.com/…/tree/…` | **Invalid** (HTML, not an image) |

Open the **single file** view for the image on GitHub (not only the repo root or folder list).

**Recommended — raw file URL**

1. On the file page, click **Raw** (top right).  
2. The browser opens a tab showing **only the image** (or raw bytes).  
3. **Select all** in the **address bar** and copy.  
   - Shape:  
     `https://raw.githubusercontent.com/USER/REPO/BRANCH/path/to/file.png`  
4. Paste that into DVD Maker’s **cover image URL** field.

**Right-click Raw → copy link address**

- On the file page, **right-click** **Raw** → **Copy link address** (Chrome) / **Copy link** (Edge) / your browser’s equivalent. You still get a **`raw.githubusercontent.com`** URL.

**Pasting a normal GitHub file page URL is OK**

- URLs like  
  `https://github.com/USER/REPO/blob/main/image.png`  
  contain **`/blob/`** (HTML viewer). This resource **normalizes them to `raw.githubusercontent.com`** on save and when opening playback.  
- **Repo home** or **folder listing** URLs are **not** image URLs — use a **single-file page** or **Raw**.

### 4. Use in-game

1. Use blank DVD → choose **tall** package.  
2. Paste the **`https://…`** string into **cover image URL**.  
3. Enter title + YouTube URL → Save.

**Sanity check:** paste the same URL into a **new browser tab**. You should see **only the image**. Login walls, HTML, or 404 mean the game client will not load it either.

<a id="metadata"></a>

## Metadata (reference)

Main keys the server sets:

| Key | Description |
|-----|-------------|
| `title` | Video title (NUI) |
| `url` | YouTube URL |
| `label` | Inventory display name (same as title) |
| `pack` | `fushokufu` / `clear` / `tall` (client UI) |
| `coverUrl` | Tall + optional cover — **NUI preview only** |
| `image` | ox slot image: **basename without extension** (the web UI appends `.png`; place `basename.png` under `web/images/`) |

Legacy **`metadata.imageurl`** on some tall DVDs can make ox try to load a remote URL as a slot icon and show **transparent** slots. Remove `imageurl` with admin tools or replace the item.

If recording **always** yields paper sleeve (`dvd_recorded1`), confirm **`refresh` / `restart dvd-maker`** deployed the latest **`html/script.js`** — the save payload sends **`dvdPack`** (fallback when JSON omits `pack`).

**Server log on success** (message is **Japanese** in the current resource):

```text
[dvd-maker] 記録成功: 付与アイテム=dvd_recorded3 pack=tall player=…
```

If this shows `dvd_recorded3`, the server granted the tall item; grid art still depends on **`items.lua` `client.image`**.

`pack` values align with `Config.RecordedByPack` in `config.lua`.

<a id="config"></a>

## Configuration (`config.lua`)

| Key | Description |
|-----|-------------|
| `Config.BlankItem` | Blank item name (default `dvd_blank`) |
| `Config.RecordedByPack` | Maps `pack` string → granted item (`fushokufu` → `dvd_recorded1`, …) |
| `Config.MaxTitleLength` | Max title length in **UTF-8 characters** (default 40) |
| `Config.MaxCoverUrlLength` | Max cover URL length (default 768) |
| `Config.InventorySlotImage` | Basename **without `.png`** written to `metadata.image` per pack (a trailing `.png` in config becomes a broken `*.png.png` in ox) |

<a id="limitations"></a>

## Known limitations

- **YouTube only** — enforced by server-side allowlist.
- **First play** may start **muted** due to browser autoplay policies.
- Cover URLs must be **direct HTTPS image URLs** usable in `<img>`. **Google Drive “view” links** are HTML pages, not raw image bytes; `uc?export=view&id=…` often **fails in FiveM NUI (CEF)** due to blocking / CORS. Prefer **self-hosted `.png`**, **imgbb-style direct links**, or **GitHub raw**.
- **GitHub**: `/blob/…` file URLs are HTML; this resource **rewrites them to raw** on save and playback. See **[Tall case: host cover art on GitHub](#github-cover-images)**.
- **Google Photos** share links (e.g. [`photos.app.goo.gl/…`](https://photos.app.goo.gl/kgsEmayEjU962cFv5)) are **album web pages**, not stable public image endpoints — **not supported** as “paste and display”. A **confirm dialog** appears when the URL looks like a share page.
- Some hosts may still fail due to **CORS** or CEF restrictions.
- **ox_inventory `metadata.image`**: must be **basename only** (no `.png`). Wrong values become **`xxx.png.png`** and icons disappear; re-record old slots after fixes.
- NUI is **Vanilla JS** — no bundler required.

<a id="migration"></a>

## Migrating from older versions

Older setups used a **single** item `dvd_recorded`. This version uses **three** recorded items (`dvd_recorded1`–`3`). Existing `dvd_recorded` stacks need admin migration or temporary dual definitions.

<a id="license"></a>

## License

[MIT License](./LICENSE). Copyright **えいほー** (2026).

<a id="contributing"></a>

## Contributing

Pull requests for fixes and improvements are welcome. For larger behaviour changes, please open an **Issue** first.

---

<p align="center">
  <sub>Documentation · <a href="./README.md">日本語 README</a> · <a href="./README.en.md">English README</a></sub>
</p>
