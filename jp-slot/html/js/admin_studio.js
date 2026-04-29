/* global window, document, fetch, GetParentResourceName */
(function () {
    var RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'jp-slot';

    var STATE_GROUPS = [
        {
            id: 'g_basic',
            title: '1. 通常・基本',
            states: [
                { id: 'idle', name: '通常 / Idle', icon: '▶' },
                { id: 'spin_start', name: '変動開始 / Spin Start', icon: '▶' },
                { id: 'minor_win', name: '小役成立 / Minor Win', icon: '▶' },
            ],
        },
        {
            id: 'g_tease',
            title: '2. 前兆・煽り',
            states: [
                { id: 'reach', name: 'リーチ / テンパイ', icon: '▶' },
                { id: 'tease', name: '煽り / Tease', icon: '▶' },
                { id: 'stepup', name: 'ステップアップ', icon: '▶' },
                { id: 'cutin', name: 'カットイン', icon: '▶' },
                { id: 'pseudo', name: '擬似連', icon: '▶' },
            ],
        },
        {
            id: 'g_result',
            title: '3. 当落・結果',
            states: [
                { id: 'win', name: '当たり / Win', icon: '⭐' },
                { id: 'big_win', name: '大当たり / Big Win', icon: '💎' },
                { id: 'lose', name: 'ハズレ / Lose', icon: '💀', subtitle: '期待させて外す演出' },
                { id: 'revival', name: '復活 / Revival', icon: '✨' },
            ],
        },
        {
            id: 'g_bonus',
            title: '4. ボーナス',
            states: [
                { id: 'bonus_confirm', name: 'ボーナス確定', icon: '🎰' },
                { id: 'bonus_play', name: 'ボーナス中', icon: '🎉' },
                { id: 'addon', name: '上乗せ / Add-on', icon: '➕' },
                { id: 'streak', name: '連チャン / Streak', icon: '🔥' },
            ],
        },
        {
            id: 'g_premium',
            title: '5. プレミアム',
            states: [
                { id: 'super_hot', name: '激アツ', icon: '🌟' },
                { id: 'freeze', name: 'フリーズ', icon: '❄' },
            ],
        },
    ];

    var DEFAULT_PROBS = {
        win: { enabled: true, p: 20.0 },
        lose: { enabled: true, p: 60.0 },
        reach_to_win: { enabled: true, p: 8.0 },
        reach_to_lose: { enabled: true, p: 5.0 },
        bonus_single: { enabled: true, p: 5.0 },
        bonus_streak: { enabled: false, p: 1.5 },
        freeze: { enabled: false, p: 0.5 },
    };

    var viewMode = 'probs';
    var selectedStateId = 'win';
    var workspace = {
        probs: JSON.parse(JSON.stringify(DEFAULT_PROBS)),
        preset: null,
        dirty: false,
    };
    var assetLib = null;

    function $(id) {
        return document.getElementById(id);
    }

    function fetchNui(path, body) {
        var tok = window.JpSlotAdminAuth && window.JpSlotAdminAuth.token;
        body = body || {};
        if (tok) {
            body.token = tok;
        }
        return fetch('https://' + RES + '/' + path, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(body),
        })
            .then(function (r) {
                return r.json();
            })
            .catch(function () {
                return { ok: false };
            });
    }

    function escapeHtml(s) {
        return String(s || '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function buildLeftNav() {
        var left = $('admin-left');
        if (!left) {
            return;
        }
        var h =
            '<div class="studio-nav-head"><button type="button" class="studio-nav-all" id="studio-btn-probs">🎲 全体確率設定</button></div>';
        for (var g = 0; g < STATE_GROUPS.length; g++) {
            var grp = STATE_GROUPS[g];
            h += '<details class="studio-acc" open><summary>' + escapeHtml(grp.title) + '</summary><div class="studio-acc-body">';
            for (var i = 0; i < grp.states.length; i++) {
                var st = grp.states[i];
                var sub = st.subtitle ? '<span class="studio-sub">' + escapeHtml(st.subtitle) + '</span>' : '';
                h +=
                    '<button type="button" class="studio-nav-item" data-state="' +
                    escapeHtml(st.id) +
                    '">' +
                    st.icon +
                    ' ' +
                    escapeHtml(st.name) +
                    sub +
                    '</button>';
            }
            h += '</div></details>';
        }
        h +=
            '<div class="studio-nav-head"><button type="button" class="studio-nav-all" id="studio-btn-legacy">⚙ テーマ・UIサイズ</button></div>';
        left.innerHTML = h;
        $('studio-btn-probs').addEventListener('click', function () {
            viewMode = 'probs';
            renderCenter();
            $('adm-current-state').textContent = '全体確率';
        });
        $('studio-btn-legacy').addEventListener('click', function () {
            viewMode = 'legacy';
            renderCenter();
            $('adm-current-state').textContent = 'テーマ・UI';
        });
        var btns = left.querySelectorAll('.studio-nav-item');
        for (var j = 0; j < btns.length; j++) {
            btns[j].addEventListener('click', function () {
                selectedStateId = this.getAttribute('data-state');
                viewMode = 'state';
                $('adm-current-state').textContent = this.textContent.trim().split('\n')[0];
                renderCenter();
            });
        }
    }

    function renderProbEditor() {
        var html = '<div class="studio-section"><h3>全体確率（参考・保存のみ）</h3><p class="studio-note">合計 100% を目安に調整できます（抽選本体は config_server.lua）。</p>';
        var sum = 0;
        for (var k in workspace.probs) {
            if (workspace.probs.hasOwnProperty(k)) {
                var row = workspace.probs[k];
                sum += row.enabled ? row.p : 0;
                html +=
                    '<div class="studio-prob-row"><label><input type="checkbox" data-k="' +
                    k +
                    '" class="pr-en"' +
                    (row.enabled ? ' checked' : '') +
                    '> ' +
                    k +
                    '</label><input type="range" min="0" max="100" step="0.1" class="pr-sl" data-k="' +
                    k +
                    '" value="' +
                    row.p +
                    '"><span class="pr-val">' +
                    row.p +
                    '%</span></div>';
            }
        }
        html +=
            '<div class="studio-sum' +
            (Math.abs(sum - 100) < 0.05 ? ' ok' : ' bad') +
            '">合計 ' +
            sum.toFixed(1) +
            '%</div>';
        html +=
            '<button type="button" class="studio-save" id="studio-save-probs">保存 (KVS jp-slot:adm:probs)</button> ';
        html +=
            '<button type="button" class="studio-sim" disabled title="将来実装">▶ 10,000回シミュレーション</button></div>';
        return html;
    }

    function renderStateEditor() {
        var html =
            '<div class="studio-section"><h3>演出レイヤー（' +
            escapeHtml(selectedStateId) +
            '）</h3>';
        html += '<div class="studio-layer"><h4>🅰 UI / タイポグラフィ</h4><select id="lay-typo" class="studio-select"></select></div>';
        html += '<div class="studio-layer"><h4>🧍 キャラ</h4><label><input type="radio" name="ck" value="image" checked>静止画</label> <label><input type="radio" name="ck" value="video">動画</label><select id="lay-char" class="studio-select"></select></div>';
        html += '<div class="studio-layer"><h4>✨ カットイン</h4><select id="lay-cutin" class="studio-select"></select></div>';
        html += '<div class="studio-layer"><h4>🖼 背景 / VFX</h4><select id="lay-bg" class="studio-select"></select> <select id="lay-vfx" class="studio-select"></select></div>';
        html += '<div class="studio-layer"><h4>🔊 サウンド</h4><select id="lay-bgm" class="studio-select"></select> <select id="lay-se" class="studio-select"></select> <select id="lay-voice" class="studio-select"></select></div>';
        html +=
            '<p class="studio-note">タイムライン編集・プリセット連携は今後拡張予定。素材は html/assets をスキャンしています。</p></div>';
        return html;
    }

    function legacyHtml() {
        return (
            '<div class="admin-wrap studio-legacy-inner">' +
            '<h2 class="admin-title" data-i18n-key="admin.tab_design"></h2>' +
            '<ul class="admin-tabs">' +
            '<li><button type="button" class="admin-tab active" data-tab="design" data-i18n-key="admin.tab_design"></button></li>' +
            '<li><button type="button" class="admin-tab" data-tab="display" data-i18n-key="admin.tab_display"></button></li>' +
            '</ul>' +
            '<div class="admin-pane admin-pane-design" data-pane="design">' +
            '<label class="admin-row">bgPrimary <input type="color" id="adm-bgPrimary"></label>' +
            '<label class="admin-row">accent1 <input type="color" id="adm-accent1"></label>' +
            '<label class="admin-row">textPrimary <input type="color" id="adm-textPrimary"></label>' +
            '<label class="admin-row">theme name <input type="text" id="adm-themeName"></label>' +
            '<div class="admin-actions">' +
            '<button type="button" id="adm-save" data-i18n-key="admin.save_theme"></button>' +
            '</div></div>' +
            '<div class="admin-pane admin-pane-display" data-pane="display" style="display:none">' +
            '<h3 class="admin-subtitle" data-i18n-key="admin.ui_size_title"></h3>' +
            '<p class="admin-hint" data-i18n-key="admin.ui_size_hint"></p>' +
            '<div class="form-row"><label for="ui-width" data-i18n-key="admin.ui_width"></label>' +
            '<input type="range" id="ui-width" min="30" max="100" value="90" step="5"><span id="ui-width-val">90</span>%</div>' +
            '<div class="form-row"><label for="ui-height" data-i18n-key="admin.ui_height"></label>' +
            '<input type="range" id="ui-height" min="30" max="100" value="90" step="5"><span id="ui-height-val">90</span>%</div>' +
            '<div class="form-row"><label for="ui-maxwidth" data-i18n-key="admin.ui_maxwidth"></label>' +
            '<input type="number" id="ui-maxwidth" min="0" max="7680" step="10" value="0"></div>' +
            '<div class="admin-actions">' +
            '<button type="button" id="ui-size-save" class="btn-primary" data-i18n-key="admin.ui_size_save"></button>' +
            '<button type="button" id="ui-size-reset" class="btn-secondary" data-i18n-key="admin.ui_size_reset"></button>' +
            '</div></div></div>'
        );
    }

    function fillSelect(sel, files, prefix) {
        if (!sel) {
            return;
        }
        sel.innerHTML = '<option value="">（なし）</option>';
        for (var i = 0; i < (files || []).length; i++) {
            var f = files[i];
            var o = document.createElement('option');
            o.value = f;
            o.textContent = f;
            sel.appendChild(o);
        }
    }

    function bindAssetSelects() {
        if (!assetLib) {
            return;
        }
        fillSelect($('lay-typo'), assetLib.typography, '');
        fillSelect($('lay-char'), assetLib.characters, '');
        fillSelect($('lay-cutin'), assetLib.cutins, '');
        fillSelect($('lay-bg'), assetLib.bg, '');
        fillSelect($('lay-vfx'), assetLib.vfx, '');
        fillSelect($('lay-bgm'), assetLib.bgm, '');
        fillSelect($('lay-se'), assetLib.se, '');
        fillSelect($('lay-voice'), assetLib.voice, '');
    }

    function renderCenter() {
        var c = $('admin-center');
        if (!c) {
            return;
        }
        if (viewMode === 'probs') {
            c.innerHTML = renderProbEditor();
            wireProbEditor();
        } else if (viewMode === 'legacy') {
            c.innerHTML = legacyHtml();
            if (window.__jpSlotAdminLegacyBind) {
                window.__jpSlotAdminLegacyBind();
            }
        } else {
            c.innerHTML = renderStateEditor();
            bindAssetSelects();
        }
    }

    function wireProbEditor() {
        var rows = document.querySelectorAll('.pr-sl');
        for (var i = 0; i < rows.length; i++) {
            rows[i].addEventListener('input', function () {
                var k = this.getAttribute('data-k');
                workspace.probs[k].p = Number(this.value);
                var lab = this.parentNode.querySelector('.pr-val');
                if (lab) {
                    lab.textContent = this.value + '%';
                }
            });
        }
        var ens = document.querySelectorAll('.pr-en');
        for (var j = 0; j < ens.length; j++) {
            ens[j].addEventListener('change', function () {
                var k = this.getAttribute('data-k');
                workspace.probs[k].enabled = this.checked;
            });
        }
        var sv = $('studio-save-probs');
        if (sv) {
            sv.addEventListener('click', function () {
                fetchNui('admin/preset/save', {
                    preset: {
                        id: 'probs_only',
                        name: '全体確率',
                        probs: workspace.probs,
                        states: {},
                    },
                }).then(function () {
                    alert('保存しました（プリセット probs_only）');
                });
            });
        }
    }

    function buildRight() {
        var r = $('admin-right');
        if (!r) {
            return;
        }
        r.innerHTML =
            '<div class="studio-right-inner">' +
            '<button type="button" class="studio-preview-main" id="studio-preview-start" data-i18n-key="admin.preview_start">▶ プレビュー開始</button>' +
            '<button type="button" class="studio-preview-end" id="studio-preview-end" data-i18n-key="admin.preview_end">✕ プレビュー終了</button>' +
            '<p class="studio-mini" data-i18n-key="admin.preview_subtitle">所持金∞ ・獲得金反映なし</p>' +
            '<div class="studio-preset"><label>プリセット名 <input type="text" id="studio-preset-name" placeholder="default"></label>' +
            '<button type="button" id="studio-preset-save">💾 上書き保存</button>' +
            '<button type="button" id="studio-preset-saveas">📄 別名で保存</button></div>' +
            '</div>';
        $('studio-preview-start').addEventListener('click', function () {
            fetchNui('admin/previewStart', {}).then(function () {});
        });
        $('studio-preview-end').addEventListener('click', function () {
            fetchNui('admin/previewEnd', {}).then(function () {});
        });
        $('studio-preset-save').addEventListener('click', savePreset);
        $('studio-preset-saveas').addEventListener('click', function () {
            var n = prompt('プリセット名');
            if (!n) {
                return;
            }
            $('studio-preset-name').value = n;
            savePreset();
        });
    }

    function savePreset() {
        var name = ($('studio-preset-name') && $('studio-preset-name').value) || 'default';
        var id = name.replace(/[^a-zA-Z0-9_-]/g, '_') || 'preset';
        fetchNui('admin/preset/save', {
            preset: {
                id: id,
                name: name,
                probs: workspace.probs,
                states: {},
                editor: 'studio-v1',
            },
        }).then(function (r) {
            if (r.ok) {
                alert('保存しました');
            }
        });
    }

    function scanAssets() {
        fetchNui('admin/assets/scan', {}).then(function (r) {
            if (r.ok && r.assets) {
                assetLib = r.assets;
                if (viewMode === 'state') {
                    bindAssetSelects();
                }
            }
        });
    }

    function onLogin() {
        scanAssets();
    }

    function onOpenAdmin(payload) {
        buildLeftNav();
        buildRight();
        viewMode = 'probs';
        renderCenter();
        if (window.jpSlotApplyI18n) {
            window.jpSlotApplyI18n();
        }
        if (payload && payload.theme && window.__jpSlotFillTheme) {
            window.__jpSlotFillTheme(payload.theme);
        }
        if (payload && payload.uiSize && window.__jpSlotSyncUiSliders) {
            window.__jpSlotSyncUiSliders(payload.uiSize);
        }
    }

    window.JpSlotAdminStudio = {
        onLogin: onLogin,
        onOpenAdmin: onOpenAdmin,
    };

    window.addEventListener('message', function (e) {
        var d = e.data || {};
        if (d.type === 'openAdmin' && window.JpSlotAdminStudio.onOpenAdmin) {
            window.JpSlotAdminStudio.onOpenAdmin(d.payload || {});
        }
    });
})();
