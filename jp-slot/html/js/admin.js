/* global window, document, GetParentResourceName, fetch */
(function () {
    function resourceName() {
        if (typeof GetParentResourceName === 'function') {
            return GetParentResourceName();
        }
        return 'jp-slot';
    }

    function authBody(extra) {
        var o = {};
        if (extra && typeof extra === 'object') {
            for (var k in extra) {
                if (Object.prototype.hasOwnProperty.call(extra, k)) {
                    o[k] = extra[k];
                }
            }
        }
        var tok = window.JpSlotAdminAuth && window.JpSlotAdminAuth.token;
        if (tok) {
            o.token = tok;
        }
        return o;
    }

    function syncSlidersFromSize(s) {
        if (!s) {
            return;
        }
        var wEl = document.getElementById('ui-width');
        var hEl = document.getElementById('ui-height');
        var mEl = document.getElementById('ui-maxwidth');
        var wVal = document.getElementById('ui-width-val');
        var hVal = document.getElementById('ui-height-val');
        if (wEl) {
            wEl.value = String(s.widthPercent != null ? s.widthPercent : 90);
        }
        if (hEl) {
            hEl.value = String(s.heightPercent != null ? s.heightPercent : 90);
        }
        if (mEl) {
            mEl.value = String(s.maxWidthPx != null ? s.maxWidthPx : 0);
        }
        if (wVal) {
            wVal.textContent = wEl ? wEl.value : '90';
        }
        if (hVal) {
            hVal.textContent = hEl ? hEl.value : '90';
        }
    }

    function previewLocal() {
        var wEl = document.getElementById('ui-width');
        var hEl = document.getElementById('ui-height');
        var mEl = document.getElementById('ui-maxwidth');
        if (!wEl || !hEl || !mEl) {
            return;
        }
        var size = {
            widthPercent: Number(wEl.value),
            heightPercent: Number(hEl.value),
            maxWidthPx: Number(mEl.value),
        };
        if (window.applyUISize) {
            window.applyUISize(size);
        }
    }

    function initTabs() {
        var tabs = document.querySelectorAll('.admin-tab');
        var panes = document.querySelectorAll('.admin-pane');
        for (var i = 0; i < tabs.length; i++) {
            tabs[i].addEventListener('click', function () {
                var tabName = this.getAttribute('data-tab');
                for (var j = 0; j < tabs.length; j++) {
                    tabs[j].classList.remove('active');
                }
                this.classList.add('active');
                for (var k = 0; k < panes.length; k++) {
                    var p = panes[k];
                    if (p.getAttribute('data-pane') === tabName) {
                        p.style.display = 'block';
                    } else {
                        p.style.display = 'none';
                    }
                }
            });
        }
    }

    function initUISizeControls() {
        var wEl = document.getElementById('ui-width');
        var hEl = document.getElementById('ui-height');
        var mEl = document.getElementById('ui-maxwidth');
        var wVal = document.getElementById('ui-width-val');
        var hVal = document.getElementById('ui-height-val');
        var saveBtn = document.getElementById('ui-size-save');
        var resetBtn = document.getElementById('ui-size-reset');
        if (!wEl || !hEl || !mEl) {
            return;
        }

        wEl.addEventListener('input', function () {
            if (wVal) {
                wVal.textContent = wEl.value;
            }
            previewLocal();
        });
        hEl.addEventListener('input', function () {
            if (hVal) {
                hVal.textContent = hEl.value;
            }
            previewLocal();
        });
        mEl.addEventListener('input', previewLocal);

        if (saveBtn) {
            saveBtn.addEventListener('click', function () {
                var body = authBody({
                    widthPercent: Number(wEl.value),
                    heightPercent: Number(hEl.value),
                    maxWidthPx: Number(mEl.value),
                });
                fetch('https://' + resourceName() + '/admin/setUISize', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                    body: JSON.stringify(body),
                }).catch(function (err) {
                    console.warn('[jp-slot] setUISize failed', err);
                });
            });
        }
        if (resetBtn) {
            resetBtn.addEventListener('click', function () {
                wEl.value = '90';
                hEl.value = '90';
                mEl.value = '0';
                if (wVal) {
                    wVal.textContent = '90';
                }
                if (hVal) {
                    hVal.textContent = '90';
                }
                previewLocal();
                fetch('https://' + resourceName() + '/admin/resetUISize', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                    body: JSON.stringify(authBody({})),
                }).catch(function (err) {
                    console.warn('[jp-slot] resetUISize failed', err);
                });
            });
        }
    }

    function __jpSlotFillTheme(theme) {
        theme = theme || {};
        var colors = theme.colors || {};
        var bg = document.getElementById('adm-bgPrimary');
        var a1 = document.getElementById('adm-accent1');
        var tp = document.getElementById('adm-textPrimary');
        var tn = document.getElementById('adm-themeName');
        if (bg) {
            bg.value = colors.bgPrimary || '#0a0608';
        }
        if (a1) {
            a1.value = colors.accent1 || '#d4af37';
        }
        if (tp) {
            tp.value = colors.textPrimary || '#f5e6c8';
        }
        if (tn) {
            tn.value = theme.name || '';
        }
    }

    function jpSlotWireLegacyAdmin(payload) {
        payload = payload || {};
        initTabs();
        initUISizeControls();
        if (payload.uiSize) {
            syncSlidersFromSize(payload.uiSize);
        }
        __jpSlotFillTheme(payload.theme);
        var themeRef = payload.theme || {};
        var colors = themeRef.colors || {};
        var bg = document.getElementById('adm-bgPrimary');
        var a1 = document.getElementById('adm-accent1');
        var tp = document.getElementById('adm-textPrimary');
        var tn = document.getElementById('adm-themeName');
        var saveBtn = document.getElementById('adm-save');
        if (saveBtn) {
            saveBtn.onclick = function () {
                var t = {
                    name: tn ? tn.value : 'Custom',
                    preset: 'custom',
                    colors: {
                        bgPrimary: bg ? bg.value : '#0a0608',
                        accent1: a1 ? a1.value : '#d4af37',
                        textPrimary: tp ? tp.value : '#f5e6c8',
                        bgSecondary: colors.bgSecondary || '#1a0e12',
                        accent2: colors.accent2 || '#f5e6a8',
                        accent3: colors.accent3 || '#8b1538',
                        textMuted: colors.textMuted || '#a89070',
                        borderFrame: colors.borderFrame || '#d4af37',
                        glowColor: colors.glowColor || '#ffd700',
                        reelBg: colors.reelBg || '#000000',
                        buttonSpin: colors.buttonSpin || '#c9302c',
                    },
                    fonts: themeRef.fonts || { title: 'Cinzel', body: 'Noto Serif JP' },
                    effectIntensity: themeRef.effectIntensity || 60,
                };
                fetch('https://' + resourceName() + '/adminSaveTheme', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                    body: JSON.stringify(authBody({ theme: t })),
                }).catch(function (err) {
                    console.warn('[jp-slot] adminSaveTheme failed', err);
                });
            };
        }
    }

    window.__jpSlotAdminLegacyBind = function () {
        jpSlotWireLegacyAdmin(window.__jpSlotLastAdminPayload || {});
    };

    window.__jpSlotFillTheme = __jpSlotFillTheme;
    window.__jpSlotSyncUiSliders = syncSlidersFromSize;
    window.jpSlotWireLegacyAdmin = jpSlotWireLegacyAdmin;

    window.addEventListener('message', function (e) {
        var d = e.data || {};
        if (d.type === 'openAdmin' && d.payload && d.payload.uiSize) {
            syncSlidersFromSize(d.payload.uiSize);
        }
        if (d.type === 'applyUISize' && d.payload) {
            syncSlidersFromSize(d.payload);
        }
    });

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function () {
            initTabs();
            initUISizeControls();
        });
    } else {
        initTabs();
        initUISizeControls();
    }
})();
