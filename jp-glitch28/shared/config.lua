-- Glitch Minigames
-- Copyright (C) 2024 Glitch
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <https://www.gnu.org/licenses/>.

-- =============================================================
-- Glitch Minigames 日本語版 (jp-glitch28)
-- 元リソース: Gl1tchStudios/glitch-minigames v2.1.1 (GPL-3.0)
-- 日本語化: matrix9neonebuchadnezzar2199-sketch
-- =============================================================
-- 設定項目:
--   config.DebugCommands       : デバッグコマンド有効化 (true/false)
--   config.usingGlitchNotifications : Glitch通知の使用
--   config.ActiveTheme         : 'cyan'(青) または 'monochrome'(モノクロ)
--   config.ActiveVisualTheme   : 'classic'(従来) または 'modern'(現代)
--   config.BackgroundOpacity   : 背景の不透明度 (0.0~1.0)
--   config.NuiSoundVolume        : NUI（HTML5 audio）効果音の音量 0.0〜1.0（ミニゲームUI内の click 等）
-- =============================================================

config = {}

config.DebugCommands = true -- true: /testskillcheck 等のデバッグコマンドを有効（本番は false 推奨）
-- true: Fleeca/Plasma ドリル等の操作説明を glitch-notifications で表示。
-- 当リソースを入れていないサーバーでは false にすること（false 時は説明なしだが落ちない）。
config.usingGlitchNotifications = true

-- 配色テーマ
config.ActiveTheme = 'cyan' -- 'cyan'（青系・原作） / 'monochrome'（モノクロ）

-- ビジュアルテーマ（レイアウト）
config.ActiveVisualTheme = 'classic' -- 'classic'（原作） / 'modern'（新UI）

-- 背景の不透明度（0.0=透明 1.0=不透明）
config.BackgroundOpacity = {
    classic = 0.80,
    modern = 0.90
}

-- NUI 内 HTML5 オーディオ（click / success / failure 等）の音量。クライアント起動時に NUI へ送られる。
config.NuiSoundVolume = 0.5

-- Available Color Themes
config.Themes = {
    -- Cyan/Teal Theme (The Original Glitch Studio's Theme)
    cyan = {
        -- Primary Theme Colors
        primary = '#33b5e5',         -- Main theme color (light blue gradient top) - used for success, highlights and accents
        primaryRgba = '51, 181, 229',  -- RGB values for rgba() usage
        secondary = '#0078d7',       -- Secondary/darker variant of primary for gradients (neon blue gradient bottom)
        secondaryRgba = '0, 120, 215', -- RGB values for secondary
        
        -- Success/Failure Colors
        success = '#33b5e5',         -- Success feedback color (light blue)
        successRgba = '51, 181, 229',  -- RGB values for success
        failure = '#ff4444',         -- Failure/error color (red)
        failureRgba = '255, 68, 68',   -- RGB values for failure
        
        -- Warning/Caution Colors
        warning = '#ff7a30',         -- Warning color (dark orange)
        warningRgba = '255, 122, 48',  -- RGB values for warning
        
        -- Neutral/UI Colors
        background = '#0f1e2d',      -- Dark blue background
        backgroundRgba = '15, 30, 45', -- RGB values for background
        backgroundGradient1 = '#0f1e2d', -- Gradient start (dark blue)
        backgroundGradient1Rgba = '15, 30, 45',
        backgroundGradient2 = '#1e3c5a', -- Gradient end (medium blue)
        backgroundGradient2Rgba = '30, 60, 90',
        backgroundSecondary = '#001428', -- Secondary darker background (dark blue for buttons)
        backgroundSecondaryRgba = '0, 20, 40',
        backgroundTertiary = '#002038', -- Tertiary background (for gradients)
        backgroundTertiaryRgba = '0, 32, 56',
        border = '#33b5e5',          -- Border/outline color (light blue for active borders)
        borderRgba = '51, 181, 229',     -- RGB values for borders
        text = '#ffffff',            -- Primary text color
        textRgba = '255, 255, 255',    -- RGB values for text
        textSecondary = '#969696',   -- Secondary/muted text
        textSecondaryRgba = '150, 150, 150', -- RGB values for secondary text
        
        -- Additional Colors
        danger = '#ff3030',          -- High danger/critical (red)
        dangerRgba = '255, 48, 48',      -- RGB values for danger
        safe = '#36ff00',            -- Safe zone (green)
        safeRgba = '54, 255, 0',      -- RGB values for safe
        
        -- Minigame Specific Colors
        minigameColor1 = '#273cfcff',  -- VarHack block 1, Memory Colors blue
        minigameColor2 = '#2add57ff',  -- VarHack block 2, Memory Colors red
        minigameColor3 = '#28e757ff',  -- VarHack block 3, Memory Colors green
        minigameColor4 = '#edeb64ff',  -- VarHack block 4, Memory Colors yellow
        minigameColor5 = '#eb87deff',  -- VarHack block 5
    },

    -- Black & White Monochrome Theme
    monochrome = {
        -- Primary Theme Colors
        primary = '#ffffff',          -- Main theme color (white) - used for highlights and accents
        primaryRgba = '255, 255, 255',  -- RGB values for rgba() usage
        secondary = '#cccccc',        -- Secondary/darker variant of primary for gradients
        secondaryRgba = '204, 204, 204', -- RGB values for secondary
        
        -- Success/Failure Colors (Using color for feedback)
        success = '#2dd4a8',         -- Success feedback color (cyan/green)
        successRgba = '45, 212, 168',  -- RGB values for success
        failure = '#ff4444',         -- Failure/error color (red)
        failureRgba = '255, 68, 68',   -- RGB values for failure
        
        -- Warning/Caution Colors
        warning = '#ff7a30',         -- Warning color (dark orange)
        warningRgba = '255, 122, 48',  -- RGB values for warning
        
        -- Neutral/UI Colors
        background = '#000000',       -- Pure black background
        backgroundRgba = '0, 0, 0',     -- RGB values for background
        backgroundGradient1 = '#000000', -- Gradient start (black)
        backgroundGradient1Rgba = '0, 0, 0',
        backgroundGradient2 = '#1a1a1a', -- Gradient end (very dark gray)
        backgroundGradient2Rgba = '26, 26, 26',
        backgroundSecondary = '#0d0d0d', -- Secondary background (very dark gray)
        backgroundSecondaryRgba = '13, 13, 13',
        backgroundTertiary = '#1a1a1a', -- Tertiary background (for gradients)
        backgroundTertiaryRgba = '26, 26, 26',
        border = '#808080',           -- Border/outline color (medium gray)
        borderRgba = '128, 128, 128',   -- RGB values for borders
        text = '#ffffff',             -- Primary text color (white)
        textRgba = '255, 255, 255',     -- RGB values for text
        textSecondary = '#a0a0a0',    -- Secondary/muted text (light gray)
        textSecondaryRgba = '160, 160, 160', -- RGB values for secondary text
        
        -- Additional Colors
        danger = '#cc0000',          -- High danger/critical (dark red)
        dangerRgba = '204, 0, 0',      -- RGB values for danger
        safe = '#22c55e',            -- Safe zone (green)
        safeRgba = '34, 197, 94',      -- RGB values for safe
        
        -- Minigame Specific Colors (all same for monochrome)
        minigameColor1 = '#273cfcff',  -- VarHack block 1, Memory Colors blue
        minigameColor2 = '#2add57ff',  -- VarHack block 2, Memory Colors red
        minigameColor3 = '#28e757ff',  -- VarHack block 3, Memory Colors green
        minigameColor4 = '#edeb64ff',  -- VarHack block 4, Memory Colors yellow
        minigameColor5 = '#eb87deff',  -- VarHack block 5
    }
}

config.Colors = config.Themes[config.ActiveTheme]