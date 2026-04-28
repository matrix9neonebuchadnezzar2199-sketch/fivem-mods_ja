/* global window */
(function () {
    /**
     * サーバーまたは Config のテーマを CSS 変数へ適用する
     * @param {object|null} theme
     */
    function applyTheme(theme) {
        var root = document.documentElement;
        if (!theme || typeof theme !== 'object') {
            return;
        }
        var colors = theme.colors || {};
        var map = [
            ['bgPrimary', '--bg-primary'],
            ['bgSecondary', '--bg-secondary'],
            ['accent1', '--accent-1'],
            ['accent2', '--accent-2'],
            ['accent3', '--accent-3'],
            ['textPrimary', '--text-primary'],
            ['textMuted', '--text-muted'],
            ['borderFrame', '--border-frame'],
            ['glowColor', '--glow-color'],
            ['reelBg', '--reel-bg'],
        ];
        for (var i = 0; i < map.length; i++) {
            var key = map[i][0];
            var css = map[i][1];
            if (colors[key]) {
                root.style.setProperty(css, colors[key]);
            }
        }
        var fonts = theme.fonts || {};
        if (fonts.title) {
            root.style.setProperty('--font-title', "'" + fonts.title + "', serif");
        }
        if (fonts.body) {
            root.style.setProperty('--font-body', "'" + fonts.body + "', serif");
        }
        if (theme.preset) {
            var el = document.getElementById('root');
            if (el) {
                el.setAttribute('data-theme', theme.preset);
            }
        }
    }

    window.JpSlotTheme = {
        applyTheme: applyTheme,
    };
})();
