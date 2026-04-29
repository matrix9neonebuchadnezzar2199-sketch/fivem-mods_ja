/* global window, document, fetch, GetParentResourceName, Chart */
(function () {
    var RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'jp-slot';

    var STUDIO_NAV = [
        { key: 'master', icon: '🎲', i18n: 'admin.nav.master' },
        { key: 'idle', icon: '🎰', i18n: 'admin.nav.idle' },
        { key: 'win', icon: '🎯', i18n: 'admin.nav.win' },
        { key: 'bonus', icon: '🎁', i18n: 'admin.nav.bonus' },
        { key: 'bonus_streak', icon: '🔁', i18n: 'admin.nav.bonus_streak' },
        { key: 'bonus_big', icon: '💎', i18n: 'admin.nav.bonus_big' },
        { key: 'miss_tease', icon: '😅', i18n: 'admin.nav.miss_tease' },
        { key: 'theme', icon: '⚙️', i18n: 'admin.nav.theme' },
        { key: 'preview', icon: '🎬', i18n: 'admin.nav.preview' },
    ];

    var EFFECT_KEYS = ['idle', 'win', 'bonus', 'bonus_streak', 'bonus_big', 'miss_tease'];

    function defaultBlockText() {
        return {
            enabled: true,
            text: '',
            color: '#f4ead0',
            size_percent: 80,
            duration_ms: 600,
            fade: true,
            effect: 'none',
        };
    }

    function defaultEffectSection() {
        return {
            pre_text: defaultBlockText(),
            cutin_block: { kind: 'none', file: '', duration_ms: 1200 },
            post_text: (function () {
                var b = defaultBlockText();
                b.size_percent = 140;
                b.color = '#d4af37';
                b.effect = 'pulse';
                return b;
            })(),
            char_video: { enabled: true, file: '', fade_back: true },
            sound: { se: '', voice: '', bgm_change: false, bgm_file: '' },
            reel_fx: { mode: 'none', custom_color: '#d4af37' },
            payout: { enabled: true, duration_ms: 2000, animation: 'countup' },
            reaction: { reaction: 'confused', tease_strength: 'medium' },
            streak_intensity: {},
        };
    }

    /** 全体確率（マスター）。サーバー Config.Master とキー対応 */
    function defaultMaster() {
        return {
            normal: { win: 25, bonus: 5, miss_tease: 70 },
            bonus_promote: { streak: 30, big: 5, max_streak: 3, big_multiplier: 10 },
            cooldown: { spins: 5 },
        };
    }

    /**
     * 新規・default 用の参考データ（ルナ想定テキスト・html/assets 配下の実ファイル例）。
     * 保存時は buildPresetPayload → サーバー KVP にそのまま入る。
     */
    function studioReferenceEffects() {
        var effects = {};
        for (var i = 0; i < EFFECT_KEYS.length; i++) {
            effects[EFFECT_KEYS[i]] = defaultEffectSection();
        }

        var idle = effects.idle;
        idle.pre_text.text = 'おかえりなさい、マスター♪';
        idle.post_text.text = '今日もよろしくね♪';
        idle.char_video.file = 'characters/luna/idle.png';

        var win = effects.win;
        win.pre_text.text = '当たり！';
        win.post_text.text = 'おめでとうございます！';
        win.cutin_block = { kind: 'image', file: 'cutins/img_02.png', duration_ms: 1400 };
        win.char_video.file = 'characters/luna/win.webm';

        var bonus = effects.bonus;
        bonus.pre_text.text = 'BONUS TIME!';
        bonus.post_text.text = 'フリースピンスタート！';
        bonus.cutin_block = { kind: 'image', file: 'cutins/img_01.png', duration_ms: 1800 };
        bonus.char_video.file = 'characters/luna/bigwin.webm';

        var bst = effects.bonus_streak;
        bst.pre_text.text = '連チャン！';
        bst.post_text.text = 'まだまだいくよ！';
        bst.cutin_block = { kind: 'image', file: 'cutins/img_02.png', duration_ms: 1400 };

        var bbig = effects.bonus_big;
        bbig.pre_text.text = 'MEGA BONUS!';
        bbig.post_text.text = '超高倍率チャンス！';
        bbig.cutin_block = { kind: 'image', file: 'cutins/img_03.png', duration_ms: 2000 };

        var miss = effects.miss_tease;
        miss.pre_text.text = 'ハズレ…';
        miss.post_text.text = '次こそ！';
        miss.payout.enabled = false;

        return effects;
    }

    /** プリセット読込用の空テンプレ（参考文は入れない）。欠落キーの補完に使う */
    function emptyEffectsShape() {
        var effects = {};
        for (var i = 0; i < EFFECT_KEYS.length; i++) {
            effects[EFFECT_KEYS[i]] = defaultEffectSection();
        }
        effects.miss_tease.payout.enabled = false;
        return effects;
    }

    function createDefaultWorkspace() {
        return {
            master: defaultMaster(),
            effects: studioReferenceEffects(),
            dirty: false,
        };
    }

    function cloneJson(obj) {
        return JSON.parse(JSON.stringify(obj));
    }

    function mergeMasterData(incoming) {
        var def = defaultMaster();
        if (!incoming || typeof incoming !== 'object') {
            return def;
        }
        return {
            normal: Object.assign({}, def.normal, incoming.normal || {}),
            bonus_promote: Object.assign({}, def.bonus_promote, incoming.bonus_promote || {}),
            cooldown: Object.assign({}, def.cooldown, incoming.cooldown || {}),
        };
    }

    function mergeEffectSection(defSec, incoming) {
        if (!incoming || typeof incoming !== 'object') {
            return cloneJson(defSec);
        }
        var o = cloneJson(defSec);
        var subKeys = [
            'pre_text',
            'post_text',
            'cutin_block',
            'char_video',
            'sound',
            'reel_fx',
            'payout',
            'reaction',
            'streak_intensity',
        ];
        for (var s = 0; s < subKeys.length; s++) {
            var k = subKeys[s];
            if (incoming[k] != null && typeof incoming[k] === 'object' && !Array.isArray(incoming[k])) {
                o[k] = Object.assign({}, o[k] || {}, incoming[k]);
            } else if (incoming[k] !== undefined) {
                o[k] = incoming[k];
            }
        }
        return o;
    }

    /** 古いプリセットでも欠落キーを埋める。参考テキストは createDefaultWorkspace のみ（読込時は空形ベース） */
    function mergeEffectsData(incoming) {
        var baseShape = emptyEffectsShape();
        if (!incoming || typeof incoming !== 'object') {
            return baseShape;
        }
        var out = {};
        for (var i = 0; i < EFFECT_KEYS.length; i++) {
            var key = EFFECT_KEYS[i];
            out[key] = mergeEffectSection(baseShape[key], incoming[key]);
        }
        return out;
    }

    var workspace = createDefaultWorkspace();
    var viewMode = 'master';
    var selectedKey = 'master';
    var simCharts = { cumulative: null, hist: null };
    var activePresetId = 'default';
    /** パンくず表示用（サーバー preset.name または一覧の表示名） */
    var activePresetLabel = 'default';
    var suppressAutosave = false;
    var workspacePushTimer = null;

    function $(id) {
        return document.getElementById(id);
    }

    /** FiveM CEF では window.alert がフリーズの原因になりやすい（同期モーダル） */
    var adminToastTimer = null;
    function showAdminToast(message, isError) {
        var el = $('adm-status-center');
        if (!el) {
            return;
        }
        el.textContent = message || '';
        el.classList.remove('adm-toast-ok', 'adm-toast-err');
        if (isError) {
            el.classList.add('adm-toast-err');
        } else if (message) {
            el.classList.add('adm-toast-ok');
        }
        if (adminToastTimer) {
            clearTimeout(adminToastTimer);
        }
        adminToastTimer = setTimeout(function () {
            adminToastTimer = null;
            el.textContent = '';
            el.classList.remove('adm-toast-ok', 'adm-toast-err');
        }, 4500);
    }
    window.jpSlotShowAdminToast = showAdminToast;

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

    function markDirty() {
        workspace.dirty = true;
        scheduleWorkspacePush();
    }

    function scheduleWorkspacePush() {
        if (suppressAutosave) {
            return;
        }
        if (workspacePushTimer) {
            clearTimeout(workspacePushTimer);
        }
        workspacePushTimer = setTimeout(function () {
            workspacePushTimer = null;
            pushWorkspaceToServer();
        }, 900);
    }

    function pushWorkspaceToServer() {
        if (suppressAutosave || !activePresetId) {
            return;
        }
        fetchNui('admin/preset/save', { preset: buildPresetPayload() })
            .then(function (r) {
                if (r && r.ok) {
                    workspace.dirty = false;
                    if (viewMode === 'preview') {
                        return fetchNui('admin/embedSlotInit', embedSlotInitOpts());
                    }
                    return;
                }
                showAdminToast('自動保存に失敗しました', true);
            })
            .catch(function () {
                showAdminToast('自動保存に失敗しました（通信エラー）', true);
            });
    }

    function mergePresetWorkspace(data) {
        if (!data) {
            return;
        }
        workspace.master = mergeMasterData(data.master);
        workspace.effects = mergeEffectsData(data.effects);
    }

    /** ホーム › 演出 › （読み込み中のプリセット名）。applyI18n で上書きされないよう data-i18n-key は付けない */
    function updateBreadcrumbPreset() {
        var el = $('adm-current-state');
        if (!el) {
            return;
        }
        el.removeAttribute('data-i18n-key');
        var label = activePresetLabel || activePresetId || 'default';
        el.textContent = label;
    }

    /** default プリセット時はプレビューで Config 既定キャラ（ルナ等）の名前・画像を出さない */
    function embedSlotInitOpts() {
        return {
            neutralPreviewCharacter: activePresetId === 'default',
        };
    }

    function renderPresetBarHtml() {
        return (
            '<div class="admin-preset-bar">' +
            '<label class="admin-preset-bar-label">' +
            '<span data-i18n-key="admin.preset.select_label">プリセット選択</span> ' +
            '<select id="studio-preset-select" class="studio-preset-select"></select>' +
            '</label></div>'
        );
    }

    function refreshAllPresetSelects() {
        fetchNui('admin/preset/list').then(function (res) {
            var list = res && res.ok && res.list ? res.list : [];
            function fill(sel) {
                if (!sel) {
                    return;
                }
                sel.innerHTML = '';
                var seen = {};
                var j;
                for (j = 0; j < list.length; j++) {
                    var e = list[j];
                    if (!e || !e.id || seen[e.id]) {
                        continue;
                    }
                    seen[e.id] = true;
                    var opt = document.createElement('option');
                    opt.value = e.id;
                    opt.textContent = e.name || e.id;
                    sel.appendChild(opt);
                }
                if (!seen.default) {
                    var op = document.createElement('option');
                    op.value = 'default';
                    op.textContent = 'default';
                    sel.insertBefore(op, sel.firstChild);
                }
                if (activePresetId) {
                    sel.value = activePresetId;
                    var ix = sel.selectedIndex;
                    if (ix >= 0 && sel.options[ix]) {
                        activePresetLabel = sel.options[ix].textContent || activePresetId;
                    }
                }
            }
            fill($('studio-preset-select'));
            fill($('preview-preset-select'));
            updateBreadcrumbPreset();
        });
    }

    function loadPreset(id, opts) {
        opts = opts || {};
        if (!id) {
            return;
        }
        suppressAutosave = true;
        fetchNui('admin/preset/get', { id: id })
            .then(function (r) {
                if (!r || !r.ok || !r.data) {
                    if (id === 'default') {
                        workspace = createDefaultWorkspace();
                        activePresetId = 'default';
                        activePresetLabel = 'default';
                        return fetchNui('admin/preset/setActive', { id: 'default' })
                            .then(function () {
                                suppressAutosave = false;
                                workspace.dirty = false;
                                if (opts.skipRender) {
                                    refreshAllPresetSelects();
                                    if (opts.refreshEmbed) {
                                        return fetchNui('admin/embedSlotInit', embedSlotInitOpts());
                                    }
                                } else {
                                    renderCenter();
                                    refreshAllPresetSelects();
                                }
                                updateBreadcrumbPreset();
                                if (window.jpSlotApplyI18n) {
                                    window.jpSlotApplyI18n();
                                }
                            })
                            .catch(function () {
                                suppressAutosave = false;
                                showAdminToast('プリセットの適用に失敗しました', true);
                            });
                    }
                    suppressAutosave = false;
                    refreshAllPresetSelects();
                    showAdminToast('プリセットを読み込めませんでした', true);
                    return;
                }
                mergePresetWorkspace(r.data);
                activePresetId = id;
                activePresetLabel =
                    r.data.name != null && String(r.data.name).trim() !== ''
                        ? String(r.data.name).trim()
                        : id;
                return fetchNui('admin/preset/setActive', { id: id })
                    .then(function () {
                        suppressAutosave = false;
                        workspace.dirty = false;
                        if (opts.skipRender) {
                            refreshAllPresetSelects();
                            if (opts.refreshEmbed) {
                                return fetchNui('admin/embedSlotInit', embedSlotInitOpts());
                            }
                        } else {
                            renderCenter();
                            refreshAllPresetSelects();
                        }
                        updateBreadcrumbPreset();
                        if (window.jpSlotApplyI18n) {
                            window.jpSlotApplyI18n();
                        }
                    })
                    .catch(function () {
                        suppressAutosave = false;
                        showAdminToast('プリセットの適用に失敗しました', true);
                    });
            })
            .catch(function () {
                suppressAutosave = false;
                showAdminToast('プリセットの読み込みに失敗しました（通信エラー）', true);
            });
    }

    function wirePresetBar() {
        var sel = $('studio-preset-select');
        if (!sel) {
            return;
        }
        sel.onchange = function () {
            loadPreset(sel.value, {});
        };
    }

    function escapeHtml(s) {
        return String(s || '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function masterSumOk(m) {
        var a = Number(m.normal.win) + Number(m.normal.bonus) + Number(m.normal.miss_tease);
        return Math.abs(a - 100) <= 0.1;
    }

    function masterPromoteSum(m) {
        return Number(m.bonus_promote.streak) + Number(m.bonus_promote.big);
    }

    function rowMaster(k, label, val) {
        return (
            '<div class="studio-row master-row" data-k="' +
            k +
            '"><div class="studio-row-label">' +
            escapeHtml(label) +
            '</div><div class="studio-row-control"><input type="range" min="0" max="100" step="0.1" class="studio-slider master-sl" data-k="' +
            k +
            '" value="' +
            val +
            '"><span class="studio-slider-value master-sl-val">' +
            Number(val).toFixed(1) +
            '%</span></div></div>'
        );
    }

    function rowPromote(k, label, val) {
        return (
            '<div class="studio-row">' +
            '<div class="studio-row-label">' +
            escapeHtml(label) +
            '</div><div class="studio-row-control">' +
            '<input type="range" min="0" max="100" step="0.1" class="studio-slider pr-sl" data-pk="' +
            k +
            '" value="' +
            val +
            '"><span class="studio-slider-value pr-sl-val">' +
            Number(val).toFixed(1) +
            '%</span></div></div>'
        );
    }

    function setDeep(root, pathStr, value) {
        var parts = pathStr.split('.');
        var cur = root;
        for (var i = 0; i < parts.length - 1; i++) {
            var pk = parts[i];
            if (!cur[pk] || typeof cur[pk] !== 'object') {
                cur[pk] = {};
            }
            cur = cur[pk];
        }
        cur[parts[parts.length - 1]] = value;
    }

    function escAttr(s) {
        return escapeHtml(String(s == null ? '' : s));
    }

    function selAttr(cur, val) {
        return cur === val ? ' selected' : '';
    }

    function chkAttr(on) {
        return on ? ' checked' : '';
    }

    function studioRowField(i18nKey, fallbackLabel, controlHtml) {
        return (
            '<div class="studio-row">' +
            '<div class="studio-row-label"><span data-i18n-key="' +
            i18nKey +
            '">' +
            escapeHtml(fallbackLabel) +
            '</span></div>' +
            '<div class="studio-row-control">' +
            controlHtml +
            '</div></div>'
        );
    }

    function sceneTitleI18n(key) {
        var map = {
            idle: 'admin.scene.idle',
            win: 'admin.scene.win',
            bonus: 'admin.nav.bonus',
            bonus_streak: 'admin.nav.bonus_streak',
            bonus_big: 'admin.nav.bonus_big',
            miss_tease: 'admin.nav.miss_tease',
        };
        return map[key] || '';
    }

    function estimateTimelineSec(sec, sceneKey) {
        var ms = 0;
        if (sec.pre_text && sec.pre_text.enabled !== false && (sec.pre_text.text || '').trim()) {
            ms += Number(sec.pre_text.duration_ms) || 600;
        }
        var cb = sec.cutin_block || {};
        if (cb.kind && cb.kind !== 'none' && (cb.file || '').trim()) {
            ms += Number(cb.duration_ms) || 1200;
        }
        if (sec.post_text && sec.post_text.enabled !== false && (sec.post_text.text || '').trim()) {
            ms += Number(sec.post_text.duration_ms) || 800;
        }
        if (sceneKey !== 'miss_tease' && sec.payout && sec.payout.enabled !== false) {
            ms += Number(sec.payout.duration_ms) || 2000;
        }
        return (ms / 1000).toFixed(1);
    }

    function normalizeMaster() {
        var w = workspace.master.normal.win;
        var b = workspace.master.normal.bonus;
        var t = workspace.master.normal.miss_tease;
        var s = w + b + t;
        if (s <= 0) {
            return;
        }
        workspace.master.normal.win = (w / s) * 100;
        workspace.master.normal.bonus = (b / s) * 100;
        workspace.master.normal.miss_tease = (t / s) * 100;
        markDirty();
        renderCenter();
    }

    function renderTextBlockCard(num, blockKey, basePath, d, showFade, showEffect) {
        d = d || defaultBlockText();
        var titleHtml =
            '<span class="studio-effect-block-num">' +
            escapeHtml(num) +
            '</span> <span data-i18n-key="' +
            blockKey +
            '"></span>';
        var body = '';
        body +=
            '<div class="studio-row studio-row--check">' +
            '<div class="studio-row-label"></div><div class="studio-row-control">' +
            '<label class="studio-inline-check"><input type="checkbox" data-path="' +
            basePath +
            '.enabled"' +
            chkAttr(d.enabled !== false) +
            '> <span data-i18n-key="admin.effect.field_use_block">このブロックを使用</span></label>' +
            '</div></div>';
        body +=
            studioRowField(
                'admin.effect.field_text',
                'テキスト',
                '<input type="text" class="studio-input-wide" data-path="' +
                    basePath +
                    '.text" value="' +
                    escAttr(d.text) +
                    '" placeholder="テキスト" autocomplete="off">'
            );
        body +=
            studioRowField(
                'admin.effect.field_color',
                'フォント色',
                '<input type="color" data-path="' +
                    basePath +
                    '.color" value="' +
                    escAttr(d.color || '#f4ead0') +
                    '">'
            );
        var sz = d.size_percent != null ? d.size_percent : 80;
        body +=
            studioRowField(
                'admin.effect.field_size',
                'サイズ (%)',
                '<input type="range" min="50" max="200" step="5" class="studio-slider" data-path="' +
                    basePath +
                    '.size_percent" value="' +
                    escAttr(sz) +
                    '"><span class="studio-slider-value ef-range-val">' +
                    Math.round(Number(sz)) +
                    '%</span>'
            );
        var dm = d.duration_ms != null ? d.duration_ms : 600;
        body +=
            studioRowField(
                'admin.effect.field_duration',
                '表示時間 (ms)',
                '<input type="range" min="100" max="4000" step="50" class="studio-slider" data-path="' +
                    basePath +
                    '.duration_ms" value="' +
                    escAttr(dm) +
                    '"><span class="studio-slider-value ef-range-val">' +
                    Math.round(Number(dm)) +
                    ' ms</span>'
            );
        if (showFade) {
            body +=
                studioRowField(
                    'admin.effect.field_fade',
                    'フェード',
                    '<label class="studio-inline-check"><input type="checkbox" data-path="' +
                        basePath +
                        '.fade"' +
                        chkAttr(d.fade !== false) +
                        '> <span data-i18n-key="admin.effect.field_fade_on">あり</span></label>'
                );
        }
        if (showEffect) {
            var eff = d.effect || 'none';
            body +=
                studioRowField(
                    'admin.effect.field_effect',
                    'エフェクト',
                    '<select data-path="' +
                        basePath +
                        '.effect" class="studio-input-wide">' +
                        '<option value="none"' +
                        selAttr(eff, 'none') +
                        '>none</option>' +
                        '<option value="pulse"' +
                        selAttr(eff, 'pulse') +
                        '>pulse</option>' +
                        '<option value="zoom"' +
                        selAttr(eff, 'zoom') +
                        '>zoom</option></select>'
                );
        }
        return (
            '<div class="studio-card studio-effect-block">' +
            '<div class="studio-card-title">' +
            titleHtml +
            '</div>' +
            body +
            '</div>'
        );
    }

    function renderCutinCard(cb) {
        cb = cb || { kind: 'none', file: '', duration_ms: 1200 };
        var kind = cb.kind || 'none';
        var dm = cb.duration_ms != null ? cb.duration_ms : 1200;
        var body = '';
        body +=
            studioRowField(
                'admin.effect.cutin_kind',
                '種別',
                '<select data-path="cutin_block.kind" class="studio-input-wide">' +
                    '<option value="none"' +
                    selAttr(kind, 'none') +
                    '>none</option>' +
                    '<option value="image"' +
                    selAttr(kind, 'image') +
                    '>image</option>' +
                    '<option value="video"' +
                    selAttr(kind, 'video') +
                    '>video</option></select>'
            );
        body +=
            studioRowField(
                'admin.effect.cutin_file',
                'ファイル',
                '<input type="text" class="studio-input-wide" data-path="cutin_block.file" value="' +
                    escAttr(cb.file) +
                    '" placeholder="cutins/xxx.png / xxx.webm" autocomplete="off">'
            );
        body +=
            studioRowField(
                'admin.effect.cutin_duration',
                '表示時間 (ms)',
                '<input type="range" min="200" max="8000" step="100" class="studio-slider" data-path="cutin_block.duration_ms" value="' +
                    escAttr(dm) +
                    '"><span class="studio-slider-value ef-range-val">' +
                    Math.round(Number(dm)) +
                    ' ms</span>'
            );
        body +=
            '<p class="studio-note studio-cutin-hint" data-i18n-key="admin.effect.cutin_hint">html/assets/cutins/ からのファイル名。実機プレビューで確認できます。</p>';
        var titleHtml =
            '<span class="studio-effect-block-num">②</span> <span data-i18n-key="admin.effect.block_cutin"></span>';
        return (
            '<div class="studio-card studio-effect-block">' +
            '<div class="studio-card-title">' +
            titleHtml +
            '</div>' +
            body +
            '</div>'
        );
    }

    function renderCharVideoCard(cv) {
        cv = cv || { enabled: true, file: '', fade_back: true };
        var body = '';
        body +=
            '<div class="studio-row studio-row--check"><div class="studio-row-label"></div><div class="studio-row-control">' +
            '<label class="studio-inline-check"><input type="checkbox" data-path="char_video.enabled"' +
            chkAttr(cv.enabled !== false) +
            '> <span data-i18n-key="admin.effect.field_use_block">このブロックを使用</span></label>' +
            '</div></div>';
        body +=
            studioRowField(
                'admin.effect.char_file',
                'ファイル',
                '<input type="text" class="studio-input-wide" data-path="char_video.file" value="' +
                    escAttr(cv.file) +
                    '" placeholder="characters/luna.webm" autocomplete="off">'
            );
        body +=
            studioRowField(
                'admin.effect.char_fade_back',
                '静止画フェード復帰',
                '<label class="studio-inline-check"><input type="checkbox" data-path="char_video.fade_back"' +
                chkAttr(cv.fade_back !== false) +
                '> ON</label>'
            );
        var titleHtml =
            '<span class="studio-effect-block-num">④</span> <span data-i18n-key="admin.effect.block_char_video"></span>';
        return (
            '<div class="studio-card studio-effect-block">' +
            '<div class="studio-card-title">' +
            titleHtml +
            '</div>' +
            body +
            '</div>'
        );
    }

    function renderSoundCard(snd) {
        snd = snd || { se: '', voice: '', bgm_change: false, bgm_file: '' };
        var body = '';
        body +=
            studioRowField(
                'admin.effect.sound_se',
                'SE',
                '<input type="text" class="studio-input-wide" data-path="sound.se" value="' +
                    escAttr(snd.se) +
                    '" placeholder="sound/se/xxx.wav" autocomplete="off">'
            );
        body +=
            studioRowField(
                'admin.effect.sound_voice',
                'ボイス',
                '<input type="text" class="studio-input-wide" data-path="sound.voice" value="' +
                    escAttr(snd.voice) +
                    '" placeholder="sound/voice/xxx.wav" autocomplete="off">'
            );
        body +=
            '<div class="studio-row"><div class="studio-row-label"><span data-i18n-key="admin.effect.sound_bgm">BGM変更</span></div><div class="studio-row-control studio-row-control--stack">' +
            '<label class="studio-inline-check"><input type="checkbox" data-path="sound.bgm_change"' +
            chkAttr(snd.bgm_change === true) +
            '> <span data-i18n-key="admin.effect.sound_bgm_use">別BGMに切替</span></label>' +
            '<input type="text" class="studio-input-wide" data-path="sound.bgm_file" value="' +
            escAttr(snd.bgm_file) +
            '" placeholder="sound/bgm/xxx.mp3" autocomplete="off"></div></div>';
        var titleHtml =
            '<span class="studio-effect-block-num">⑤</span> <span data-i18n-key="admin.effect.block_sound"></span>';
        return (
            '<div class="studio-card studio-effect-block">' +
            '<div class="studio-card-title">' +
            titleHtml +
            '</div>' +
            body +
            '</div>'
        );
    }

    function renderReelFxCard(rfx) {
        rfx = rfx || { mode: 'none', custom_color: '#d4af37' };
        var mode = rfx.mode || 'none';
        var body = '';
        body +=
            studioRowField(
                'admin.effect.reel_mode',
                'モード',
                '<select data-path="reel_fx.mode" class="studio-input-wide">' +
                    '<option value="none"' +
                    selAttr(mode, 'none') +
                    '>なし</option>' +
                    '<option value="gold_pulse"' +
                    selAttr(mode, 'gold_pulse') +
                    '>ゴールド脈動</option>' +
                    '<option value="custom"' +
                    selAttr(mode, 'custom') +
                    '>カスタム色</option></select>'
            );
        body +=
            studioRowField(
                'admin.effect.reel_custom_color',
                'カスタム色',
                '<input type="color" data-path="reel_fx.custom_color" value="' +
                    escAttr(rfx.custom_color || '#d4af37') +
                    '">'
            );
        var titleHtml =
            '<span class="studio-effect-block-num">⑥</span> <span data-i18n-key="admin.effect.block_reel_fx"></span>';
        return (
            '<div class="studio-card studio-effect-block">' +
            '<div class="studio-card-title">' +
            titleHtml +
            '</div>' +
            body +
            '</div>'
        );
    }

    function renderPayoutCard(po, sceneKey) {
        po = po || { enabled: true, duration_ms: 2000, animation: 'countup' };
        var anim = po.animation || 'countup';
        var dm = po.duration_ms != null ? po.duration_ms : 2000;
        var disabledNote = '';
        if (sceneKey === 'miss_tease') {
            disabledNote =
                '<p class="studio-note studio-payout-miss" data-i18n-key="admin.effect.payout_miss_note">はずれ演出では配当表示は使いません。</p>';
        }
        var body = '';
        body +=
            '<div class="studio-row studio-row--check"><div class="studio-row-label"></div><div class="studio-row-control">' +
            '<label class="studio-inline-check"><input type="checkbox" data-path="payout.enabled"' +
            chkAttr(po.enabled !== false) +
            (sceneKey === 'miss_tease' ? ' disabled' : '') +
            '> <span data-i18n-key="admin.effect.field_use_block">このブロックを使用</span></label>' +
            '</div></div>';
        body += disabledNote;
        body +=
            studioRowField(
                'admin.effect.payout_duration',
                '表示時間 (ms)',
                '<input type="range" min="200" max="8000" step="100" class="studio-slider" data-path="payout.duration_ms" value="' +
                    escAttr(dm) +
                    '"><span class="studio-slider-value ef-range-val">' +
                    Math.round(Number(dm)) +
                    ' ms</span>'
            );
        body +=
            studioRowField(
                'admin.effect.payout_anim',
                'アニメーション',
                '<select data-path="payout.animation" class="studio-input-wide">' +
                    '<option value="countup"' +
                    selAttr(anim, 'countup') +
                    '>カウントアップ</option>' +
                    '<option value="instant"' +
                    selAttr(anim, 'instant') +
                    '>即時</option></select>'
            );
        var titleHtml =
            '<span class="studio-effect-block-num">⑦</span> <span data-i18n-key="admin.effect.block_payout"></span>';
        return (
            '<div class="studio-card studio-effect-block">' +
            '<div class="studio-card-title">' +
            titleHtml +
            '</div>' +
            body +
            '</div>'
        );
    }

    function renderMissTeaseExtra(react) {
        react = react || { reaction: 'confused', tease_strength: 'medium' };
        var r = react.reaction || 'confused';
        var ts = react.tease_strength || 'medium';
        var body = '';
        body +=
            studioRowField(
                'admin.effect.miss_reaction',
                'リアクション',
                '<select data-path="reaction.reaction" class="studio-input-wide">' +
                    '<option value="are"' +
                    selAttr(r, 'are') +
                    '>are</option>' +
                    '<option value="confused"' +
                    selAttr(r, 'confused') +
                    '>confused</option>' +
                    '<option value="disappointed"' +
                    selAttr(r, 'disappointed') +
                    '>disappointed</option></select>'
            );
        body +=
            studioRowField(
                'admin.effect.miss_strength',
                '煽り強度',
                '<select data-path="reaction.tease_strength" class="studio-input-wide">' +
                    '<option value="low"' +
                    selAttr(ts, 'low') +
                    '>low</option>' +
                    '<option value="medium"' +
                    selAttr(ts, 'medium') +
                    '>medium</option>' +
                    '<option value="high"' +
                    selAttr(ts, 'high') +
                    '>high</option></select>'
            );
        return (
            '<div class="studio-card studio-effect-block studio-card--extra">' +
            '<div class="studio-card-title"><span data-i18n-key="admin.effect.miss_extra_title">はずれ演出の追加設定</span></div>' +
            body +
            '</div>'
        );
    }

    function renderBonusStreakNote() {
        return (
            '<div class="studio-card studio-effect-block studio-card--extra">' +
            '<div class="studio-card-title"><span data-i18n-key="admin.effect.streak_extra_title">連続ボーナス</span></div>' +
            '<p class="studio-note" data-i18n-key="admin.effect.streak_note">段階別の強度（streak_intensity）は今後の拡張用です。</p>' +
            '</div>'
        );
    }

    function renderBonusBigNote() {
        return (
            '<div class="studio-card studio-effect-block studio-card--extra">' +
            '<div class="studio-card-title"><span data-i18n-key="admin.effect.big_extra_title">ビッグボーナス</span></div>' +
            '<p class="studio-note" data-i18n-key="admin.effect.big_note">倍率・連続は「全体確率設定」のマスター値を参照します。</p>' +
            '</div>'
        );
    }

    function renderTimelineCard(sec, sceneKey) {
        var est = estimateTimelineSec(sec, sceneKey);
        return (
            '<div class="studio-card studio-card--timeline">' +
            '<div class="studio-card-title"><span data-i18n-key="admin.effect.timeline">タイムライン</span></div>' +
            '<p class="studio-timeline-body"><span data-i18n-key="admin.effect.timeline_estimate_label">概算合計</span>　<strong id="effect-timeline-val">' +
            est +
            '</strong> <span data-i18n-key="admin.effect.timeline_sec">秒</span> <span class="studio-timeline-sub" data-i18n-key="admin.effect.timeline_sub">（①〜③・⑦の表示時間ベース）</span></p>' +
            '</div>'
        );
    }

    function renderMasterTab() {
        var m = workspace.master;
        var ok = masterSumOk(m);
        var ps = masterPromoteSum(m);
        var single = Math.max(0, 100 - ps);
        var sumNum = (Number(m.normal.win) + Number(m.normal.bonus) + Number(m.normal.miss_tease)).toFixed(1);
        var sumText = '合計 ' + sumNum + '%' + (ok ? ' ✓' : '');
        var titleStatusClass = 'studio-card-title-status' + (ok ? '' : ' is-error');

        var html = '<div class="studio-editor-sheet studio-editor-sheet--master"><div class="studio-section studio-master-wrap">';
        html +=
            '<h3 class="studio-page-title" data-i18n-key="admin.master.title">' +
            escapeHtml('全体確率設定') +
            '</h3>';

        html += '<div class="studio-master-grid">';
        html += '<div class="studio-card">';
        html += '<div class="studio-card-title">';
        html += '<span data-i18n-key="admin.master.normal_section">通常中の抽選（合計100%）</span>';
        html +=
            '<span id="master-sum-val" class="' +
            titleStatusClass +
            '">' +
            escapeHtml(sumText) +
            '</span>';
        html += '</div>';
        html += rowMaster('win', 'WIN', m.normal.win);
        html += rowMaster('bonus', 'BONUS', m.normal.bonus);
        html += rowMaster('miss_tease', 'MISS', m.normal.miss_tease);
        html += '<div class="studio-card-actions studio-card-actions--end">';
        html +=
            '<button type="button" class="studio-btn-secondary" id="master-norm-go" data-i18n-key="admin.master.auto_normalize">自動正規化</button>';
        html += '</div>';
        html += '</div>';

        html += '<div class="studio-card">';
        html += '<div class="studio-card-title">';
        html +=
            '<span data-i18n-key="admin.master.bonus_promote_section">ボーナス昇格抽選（ボーナス当選時）</span>';
        html += '</div>';
        html += rowPromote('streak', 'STREAK', m.bonus_promote.streak);
        html += rowPromote('big', 'BIG', m.bonus_promote.big);
        html += '<div class="studio-row studio-row--readonly">';
        html +=
            '<div class="studio-row-label" data-i18n-key="admin.master.single_auto_label">単発（自動）</div>';
        html +=
            '<div class="studio-row-control"><span id="master-single-pct" class="studio-slider-value studio-single-readonly">' +
            single.toFixed(2) +
            '%</span></div>';
        html += '</div>';
        html += '<div class="studio-row">';
        html +=
            '<div class="studio-row-label" data-i18n-key="admin.master.max_streak_label">最大連続回数</div>';
        html += '<div class="studio-row-control">';
        html +=
            '<input type="number" min="1" max="9" id="mx-str" value="' +
            escapeHtml(String(m.bonus_promote.max_streak)) +
            '">';
        html += ' <span class="studio-row-hint">(1〜9)</span>';
        html += '</div></div>';
        html += '<div class="studio-row">';
        html += '<div class="studio-row-label" data-i18n-key="admin.master.big_mul_label">ビッグ倍率</div>';
        html += '<div class="studio-row-control">';
        html +=
            '<input type="number" min="2" max="20" id="big-mul" value="' +
            escapeHtml(String(m.bonus_promote.big_multiplier)) +
            '">';
        html += ' <span class="studio-row-hint">(2〜20)</span>';
        html += '</div></div>';
        html += '</div>';

        html += '<div class="studio-card">';
        html += '<div class="studio-card-title">';
        html += '<span data-i18n-key="admin.master.cooldown_section">クールタイム</span>';
        html += '</div>';
        html +=
            '<p class="studio-note studio-card-note" data-i18n-key="admin.master.cooldown_note">ボーナス終了後、通常スピンN回まで全抽選をハズレ演出に置き換え</p>';
        html += '<div class="studio-row">';
        html += '<div class="studio-row-label" data-i18n-key="admin.master.spin_count_label">スピン数</div>';
        html += '<div class="studio-row-control">';
        html +=
            '<input type="number" min="0" max="50" id="cd-spins" value="' +
            m.cooldown.spins +
            '" />';
        html += ' <span class="studio-row-hint">(0〜50)</span>';
        html += '</div></div>';
        html += '</div>';

        html += '</div>';

        html += '<div class="studio-master-primary-wrap">';
        html +=
            '<button type="button" class="studio-btn-primary" id="master-norm-btn" ' +
            (ok ? '' : 'disabled') +
            ' data-i18n-key="admin.master.save_master">💾 マスター設定を保存</button>';
        html += '</div>';

        html += '<div class="studio-card studio-card--sim">';
        html += '<div class="studio-card-title">';
        html += '<span data-i18n-key="admin.master.simulation_section">シミュレーション</span>';
        html += '</div>';
        html += '<div class="sim-toolbar">';
        html +=
            '<label class="sim-toolbar-field"><span data-i18n-key="admin.master.sim_trials">試行回数</span> ';
        html +=
            '<select id="sim-trials"><option>100</option><option>500</option><option selected>1000</option><option>5000</option><option>10000</option></select></label>';
        html +=
            '<label class="sim-toolbar-field"><span data-i18n-key="admin.master.bet_label">ベット</span> ';
        html += '<input type="number" id="sim-bet" value="100"></label>';
        html +=
            '<button type="button" class="studio-btn-primary studio-btn-sim-run" id="sim-run" data-i18n-key="admin.master.simulation_run">実行</button>';
        html += '</div>';
        html += '<div id="sim-warn-banner" class="sim-warn-banner" hidden></div>';
        html += '<pre id="sim-out" class="sim-out"></pre>';
        html +=
            '<div class="sim-chart-tabs"><button type="button" class="sim-tab-btn" data-sim-tab="cum">累積収支</button><button type="button" class="sim-tab-btn" data-sim-tab="hist">払戻分布</button></div>';
        html += '<canvas id="chart-cum" height="120"></canvas>';
        html += '<canvas id="chart-hist" height="120" hidden></canvas>';
        html += '</div>';

        html += '</div>';
        html += '</div>';
        return html;
    }

    function wireMaster() {
        var rows = document.querySelectorAll('.master-sl');
        for (var i = 0; i < rows.length; i++) {
            rows[i].addEventListener('input', function () {
                var k = this.getAttribute('data-k');
                workspace.master.normal[k] = Number(this.value);
                var row = this.closest('.studio-row');
                var lab = row ? row.querySelector('.master-sl-val') : null;
                if (lab) {
                    lab.textContent = Number(this.value).toFixed(1) + '%';
                }
                var sum =
                    workspace.master.normal.win +
                    workspace.master.normal.bonus +
                    workspace.master.normal.miss_tease;
                var el = $('master-sum-val');
                var okNow = masterSumOk(workspace.master);
                if (el) {
                    el.textContent = '合計 ' + sum.toFixed(1) + '%' + (okNow ? ' ✓' : '');
                    el.className = 'studio-card-title-status' + (okNow ? '' : ' is-error');
                }
                var btn = $('master-norm-btn');
                if (btn) {
                    btn.disabled = !okNow;
                }
                markDirty();
            });
        }
        var pr = document.querySelectorAll('.pr-sl');
        for (var j = 0; j < pr.length; j++) {
            pr[j].addEventListener('input', function () {
                var k = this.getAttribute('data-pk');
                workspace.master.bonus_promote[k] = Number(this.value);
                var prow = this.closest('.studio-row');
                var pv = prow ? prow.querySelector('.pr-sl-val') : null;
                if (pv) {
                    pv.textContent = Number(this.value).toFixed(1) + '%';
                }
                var sp = $('master-single-pct');
                if (sp) {
                    var psu = masterPromoteSum(workspace.master);
                    sp.textContent = Math.max(0, 100 - psu).toFixed(2) + '%';
                }
                markDirty();
            });
        }
        var mx = $('mx-str');
        if (mx) {
            mx.addEventListener('change', function () {
                workspace.master.bonus_promote.max_streak = Number(mx.value);
                markDirty();
            });
        }
        var bm = $('big-mul');
        if (bm) {
            bm.addEventListener('change', function () {
                workspace.master.bonus_promote.big_multiplier = Number(bm.value);
                markDirty();
            });
        }
        var cds = $('cd-spins');
        if (cds) {
            cds.addEventListener('change', function () {
                workspace.master.cooldown.spins = Number(cds.value);
                markDirty();
            });
        }
        var nb = $('master-norm-btn');
        if (nb) {
            nb.addEventListener('click', function () {
                fetchNui('admin/preset/save', {
                    preset: buildPresetPayload(),
                })
                    .then(function (r) {
                        if (r && r.ok) {
                            workspace.dirty = false;
                            showAdminToast('保存しました', false);
                            refreshAllPresetSelects();
                        } else {
                            showAdminToast(
                                '保存に失敗しました' + (r && r.reason ? ': ' + r.reason : ''),
                                true
                            );
                        }
                    })
                    .catch(function () {
                        showAdminToast('保存に失敗しました（通信エラー）', true);
                    });
            });
        }
        var ng = $('master-norm-go');
        if (ng) {
            ng.addEventListener('click', normalizeMaster);
        }
        var sr = $('sim-run');
        if (sr) {
            sr.addEventListener('click', runSimulationClick);
        }
        document.querySelectorAll('[data-sim-tab]').forEach(function (bt) {
            bt.addEventListener('click', function () {
                var t = bt.getAttribute('data-sim-tab');
                var c1 = $('chart-cum');
                var c2 = $('chart-hist');
                if (t === 'cum') {
                    if (c1) {
                        c1.hidden = false;
                    }
                    if (c2) {
                        c2.hidden = true;
                    }
                } else {
                    if (c1) {
                        c1.hidden = true;
                    }
                    if (c2) {
                        c2.hidden = false;
                    }
                }
            });
        });
    }

    /** FiveM NUI では window.prompt がフリーズしやすいためモーダルを使う */
    function openPresetNameModal(defaultName, onDone) {
        var modal = $('admin-preset-name-modal');
        var inp = $('admin-preset-name-input');
        var okBtn = $('admin-preset-name-ok');
        var cancelBtn = $('admin-preset-name-cancel');
        if (!modal || !inp || !okBtn || !cancelBtn) {
            if (onDone) {
                onDone(null);
            }
            return;
        }
        inp.value = defaultName || 'my_preset';
        modal.hidden = false;
        function cleanup() {
            modal.hidden = true;
            okBtn.onclick = null;
            cancelBtn.onclick = null;
            inp.onkeydown = null;
            document.removeEventListener('keydown', onKey);
        }
        function finish(val) {
            cleanup();
            if (onDone) {
                onDone(val);
            }
        }
        function onKey(e) {
            if (e.key === 'Escape') {
                e.preventDefault();
                finish(null);
            }
        }
        cancelBtn.onclick = function () {
            finish(null);
        };
        okBtn.onclick = function () {
            var v = (inp.value || '').trim();
            finish(v ? v : null);
        };
        inp.onkeydown = function (e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                okBtn.click();
            }
        };
        document.addEventListener('keydown', onKey);
        window.setTimeout(function () {
            inp.focus();
            inp.select();
        }, 0);
        if (window.jpSlotApplyI18n) {
            window.jpSlotApplyI18n();
        }
    }

    function renderPreviewTab() {
        return (
            '<div class="studio-editor-sheet studio-preview-page">' +
            '<div class="admin-preview-toolbar">' +
            '<label class="admin-preview-toolbar-label">' +
            '<span data-i18n-key="admin.preset.select_label">プリセット</span> ' +
            '<select id="preview-preset-select" class="studio-preset-select"></select>' +
            '</label>' +
            '<button type="button" id="preview-save-as-new" class="studio-btn-secondary" data-i18n-key="admin.preset.save_as_new_btn"></button>' +
            '<button type="button" id="preview-save-overwrite" class="studio-btn-primary" data-i18n-key="admin.preset.overwrite_btn"></button>' +
            '</div>' +
            '<div id="admin-slot-embed" class="admin-slot-embed"></div>' +
            '<p class="studio-note studio-preview-hint" data-i18n-key="admin.preview.embed_hint"></p>' +
            '</div>'
        );
    }

    function wirePreviewTab() {
        fetchNui('admin/previewStart', {})
            .then(function () {
                return fetchNui('admin/embedSlotInit', embedSlotInitOpts());
            })
            .then(function () {
                window.requestAnimationFrame(function () {
                    var host = $('admin-slot-embed');
                    if (window.jpSlotMoveRootToEmbed && host) {
                        window.jpSlotMoveRootToEmbed(host);
                    }
                });
            })
            .catch(function () {
                showAdminToast('プレビューの開始に失敗しました', true);
            });
        refreshAllPresetSelects();
        var ps = $('preview-preset-select');
        if (ps) {
            ps.onchange = function () {
                loadPreset(ps.value, { skipRender: true, refreshEmbed: true });
            };
        }
        var sn = $('preview-save-as-new');
        if (sn) {
            sn.onclick = function () {
                openPresetNameModal('my_preset', function (name) {
                    if (!name || String(name).trim() === '') {
                        return;
                    }
                    name = String(name).trim();
                    var id = name.replace(/[^a-zA-Z0-9_-]/g, '_') || 'preset';
                    fetchNui('admin/preset/save', {
                        preset: buildPresetPayload(id, name),
                    })
                        .then(function (r) {
                            if (r && r.ok) {
                                activePresetId = id;
                                activePresetLabel = name;
                                workspace.dirty = false;
                                showAdminToast('保存しました', false);
                                refreshAllPresetSelects();
                                return fetchNui('admin/embedSlotInit', embedSlotInitOpts()).then(function () {
                                    window.requestAnimationFrame(function () {
                                        var host = $('admin-slot-embed');
                                        if (window.jpSlotMoveRootToEmbed && host) {
                                            window.jpSlotMoveRootToEmbed(host);
                                        }
                                    });
                                });
                            }
                            showAdminToast(
                                '保存に失敗しました' + (r && r.reason ? ': ' + r.reason : ''),
                                true
                            );
                        })
                        .catch(function () {
                            showAdminToast('保存に失敗しました（通信エラー）', true);
                        });
                });
            };
        }
        var ow = $('preview-save-overwrite');
        if (ow) {
            ow.onclick = function () {
                fetchNui('admin/preset/save', { preset: buildPresetPayload() })
                    .then(function (r) {
                        if (r && r.ok) {
                            workspace.dirty = false;
                            showAdminToast('保存しました', false);
                            return fetchNui('admin/embedSlotInit', embedSlotInitOpts());
                        }
                        showAdminToast(
                            '保存に失敗しました' + (r && r.reason ? ': ' + r.reason : ''),
                            true
                        );
                    })
                    .catch(function () {
                        showAdminToast('保存に失敗しました（通信エラー）', true);
                    });
            };
        }
    }

    function buildPresetPayload(overrideId, overrideName) {
        var id = overrideId || activePresetId || 'default';
        var name = overrideName;
        if (!name) {
            var sel = $('studio-preset-select') || $('preview-preset-select');
            if (sel && sel.options && sel.selectedIndex >= 0) {
                name = sel.options[sel.selectedIndex].textContent || id;
            } else {
                name = id;
            }
        }
        return {
            id: id,
            name: name,
            master: workspace.master,
            effects: workspace.effects,
            editor: 'studio-v2',
        };
    }

    function simWinPayout(bet) {
        return Math.floor(bet * 2.4);
    }
    function simBonusSpinPayout(bet, multB) {
        return Math.floor(bet * 3.2 * (multB || 2));
    }

    function runSimulation(trials, bet, s) {
        var inBonus = false;
        var bonusRemaining = 0;
        var pendingPromote = null;
        var currentStreak = 0;
        var cooldown = 0;
        var r = {
            win: 0,
            bonus: 0,
            bonus_single: 0,
            bonus_streak: 0,
            bonus_big: 0,
            miss_tease: 0,
            cooldown_blocked: 0,
            total_bet: 0,
            total_payout: 0,
            max_streak: 0,
            history: [],
        };
        var bonusMult = 2;
        var fs = 8;
        var maxStr = s.maxStreak || 3;
        var bigM = s.bigMultiplier || 10;
        for (var i = 0; i < trials; i++) {
            if (inBonus) {
                var win = simBonusSpinPayout(bet, bonusMult);
                r.total_payout += win;
                r.history.push({ type: 'bonus_spin', payout: win, bet: 0 });
                bonusRemaining--;
                if (bonusRemaining <= 0) {
                    if (pendingPromote === 'streak' && currentStreak < maxStr) {
                        currentStreak++;
                        bonusRemaining = fs;
                        r.bonus_streak++;
                        r.max_streak = Math.max(r.max_streak, currentStreak);
                    } else if (pendingPromote === 'big') {
                        bonusRemaining = fs * bigM;
                        pendingPromote = null;
                        r.bonus_big++;
                    } else {
                        inBonus = false;
                        pendingPromote = null;
                        currentStreak = 0;
                        cooldown = s.cooldownSpins || 5;
                    }
                }
                continue;
            }
            r.total_bet += bet;
            if (cooldown > 0) {
                cooldown--;
                r.cooldown_blocked++;
                r.miss_tease++;
                r.history.push({ type: 'miss_tease', payout: 0, bet: bet });
                continue;
            }
            var roll = Math.random() * 100;
            if (roll < s.normalWin) {
                var w = simWinPayout(bet);
                r.win++;
                r.total_payout += w;
                r.history.push({ type: 'win', payout: w, bet: bet });
            } else if (roll < s.normalWin + s.normalBonus) {
                r.bonus++;
                inBonus = true;
                bonusRemaining = fs;
                var sub = Math.random() * 100;
                if (sub < s.promoteStreak) {
                    pendingPromote = 'streak';
                    currentStreak = 1;
                } else if (sub < s.promoteStreak + s.promoteBig) {
                    pendingPromote = 'big';
                } else {
                    pendingPromote = null;
                    r.bonus_single++;
                }
                r.history.push({ type: 'bonus', payout: 0, bet: bet });
            } else {
                r.miss_tease++;
                r.history.push({ type: 'miss_tease', payout: 0, bet: bet });
            }
        }
        return r;
    }

    function runSimulationClick() {
        var trials = Number(($('sim-trials') && $('sim-trials').value) || 1000);
        var bet = Number(($('sim-bet') && $('sim-bet').value) || 100);
        var m = workspace.master;
        var s = {
            normalWin: Number(m.normal.win),
            normalBonus: Number(m.normal.bonus),
            promoteStreak: Number(m.bonus_promote.streak),
            promoteBig: Number(m.bonus_promote.big),
            maxStreak: Number(m.bonus_promote.max_streak),
            bigMultiplier: Number(m.bonus_promote.big_multiplier),
            cooldownSpins: Number(m.cooldown.spins),
        };
        var res = runSimulation(trials, bet, s);
        var rtp = res.total_bet > 0 ? (res.total_payout / res.total_bet) * 100 : 0;
        var out = $('sim-out');
        if (out) {
            out.textContent =
                JSON.stringify(
                    {
                        rtp: rtp.toFixed(2) + '%',
                        total_bet: res.total_bet,
                        total_payout: res.total_payout,
                        counts: {
                            win: res.win,
                            bonus: res.bonus,
                            bonus_single: res.bonus_single,
                            bonus_streak: res.bonus_streak,
                            bonus_big: res.bonus_big,
                            miss_tease: res.miss_tease,
                            cooldown_blocked: res.cooldown_blocked,
                        },
                        max_streak: res.max_streak,
                    },
                    null,
                    2
                );
        }
        var warn = $('sim-warn-banner');
        if (warn) {
            if (res.total_payout > res.total_bet) {
                warn.hidden = false;
                warn.textContent =
                    '⚠️ 警告：払い出しが入金を超えています！ RTP: ' + rtp.toFixed(1) + '%';
            } else {
                warn.hidden = true;
            }
        }
        drawSimCharts(res, bet);
    }

    function drawSimCharts(res, bet) {
        if (typeof Chart === 'undefined') {
            return;
        }
        var cum = [];
        var acc = 0;
        for (var i = 0; i < res.history.length; i++) {
            var h = res.history[i];
            acc += (h.payout || 0) - (h.bet || 0);
            cum.push({ x: i + 1, y: acc });
        }
        var ctx1 = $('chart-cum');
        if (simCharts.cumulative) {
            simCharts.cumulative.destroy();
        }
        if (ctx1) {
            simCharts.cumulative = new Chart(ctx1.getContext('2d'), {
                type: 'line',
                data: {
                    datasets: [
                        {
                            label: '累積収支',
                            data: cum.map(function (p) {
                                return p.y;
                            }),
                        },
                    ],
                },
                options: { animation: false },
            });
        }
        var buckets = [0, 0, 0, 0, 0, 0, 0];
        for (var j = 0; j < res.history.length; j++) {
            var p = res.history[j].payout || 0;
            var idx = 6;
            if (p <= 0) {
                idx = 0;
            } else if (p <= bet) {
                idx = 1;
            } else if (p <= bet * 5) {
                idx = 2;
            } else if (p <= bet * 10) {
                idx = 3;
            } else if (p <= bet * 50) {
                idx = 4;
            } else if (p <= bet * 100) {
                idx = 5;
            }
            buckets[idx]++;
        }
        var ctx2 = $('chart-hist');
        if (simCharts.hist) {
            simCharts.hist.destroy();
        }
        if (ctx2) {
            simCharts.hist = new Chart(ctx2.getContext('2d'), {
                type: 'bar',
                data: {
                    labels: ['0', '1x', '1-5x', '5-10x', '10-50x', '50-100x', '100x+'],
                    datasets: [{ data: buckets }],
                },
                options: { animation: false },
            });
        }
    }

    function renderEffectTab(key) {
        var sec = workspace.effects[key] || defaultEffectSection();
        workspace.effects[key] = sec;

        var html = '<div class="studio-editor-sheet"><div class="studio-section studio-effect-wrap">';
        var titleKey = sceneTitleI18n(key);
        html +=
            '<h3 class="studio-page-title"' +
            (titleKey ? ' data-i18n-key="' + titleKey + '"' : '') +
            '>' +
            escapeHtml(key) +
            '</h3>';
        html +=
            '<p class="studio-note studio-effect-intro" data-i18n-key="admin.effect.intro">7ブロック構成。カードごとに編集し、プリセット保存で反映されます。</p>';

        html += '<div class="studio-effect-grid">';
        html += renderTextBlockCard('①', 'admin.effect.block_pre_text', 'pre_text', sec.pre_text, true, false);
        html += renderCutinCard(sec.cutin_block);
        html += renderTextBlockCard('③', 'admin.effect.block_post_text', 'post_text', sec.post_text, false, true);
        html += renderCharVideoCard(sec.char_video);
        html += renderSoundCard(sec.sound);
        html += renderReelFxCard(sec.reel_fx);
        html += renderPayoutCard(sec.payout, key);

        if (key === 'miss_tease') {
            html += renderMissTeaseExtra(sec.reaction);
        } else if (key === 'bonus_streak') {
            html += renderBonusStreakNote();
        } else if (key === 'bonus_big') {
            html += renderBonusBigNote();
        }

        html += '</div>';

        html += '<div class="studio-effect-timeline-wrap">';
        html += renderTimelineCard(sec, key);
        html += '</div>';

        html += '</div></div>';
        return html;
    }

    function wireEffectTab(key) {
        var root = $('admin-center');
        if (!root) {
            return;
        }

        function refreshTimeline() {
            var tl = $('effect-timeline-val');
            if (tl && workspace.effects[key]) {
                tl.textContent = estimateTimelineSec(workspace.effects[key], key);
            }
        }

        function onChange(el) {
            var path = el.getAttribute('data-path');
            if (!path || el.disabled) {
                return;
            }
            var val;
            if (el.type === 'checkbox') {
                val = el.checked;
            } else if (el.type === 'range' || el.type === 'number') {
                val = Number(el.value);
            } else {
                val = el.value;
            }
            setDeep(workspace.effects[key], path, val);
            markDirty();
            refreshTimeline();
            var ctrl = el.closest('.studio-row-control');
            if (ctrl && el.type === 'range') {
                var disp = ctrl.querySelector('.ef-range-val');
                if (disp) {
                    if (path.indexOf('size_percent') !== -1) {
                        disp.textContent = Math.round(Number(el.value)) + '%';
                    } else {
                        disp.textContent = Math.round(Number(el.value)) + ' ms';
                    }
                }
            }
        }

        root.querySelectorAll('[data-path]').forEach(function (el) {
            var ev =
                el.tagName === 'SELECT' ||
                (el.type && (el.type === 'checkbox' || el.type === 'number'))
                    ? 'change'
                    : 'input';
            if (el.type === 'range') {
                ev = 'input';
            }
            el.addEventListener(ev, function () {
                onChange(el);
            });
        });

        refreshTimeline();
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
            '<div class="admin-actions"><button type="button" id="adm-save" data-i18n-key="admin.save_theme"></button></div></div>' +
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

    function buildLeftNav() {
        var left = $('admin-left');
        if (!left) {
            return;
        }
        var h = '<ul class="studio-nav-list">';
        for (var i = 0; i < STUDIO_NAV.length; i++) {
            var it = STUDIO_NAV[i];
            h +=
                '<li><button type="button" class="studio-nav-item' +
                (selectedKey === it.key ? ' is-active' : '') +
                '" data-nav="' +
                it.key +
                '"><span class="studio-nav-ico" aria-hidden="true">' +
                it.icon +
                '</span><span class="studio-nav-txt" data-i18n-key="' +
                it.i18n +
                '"></span></button></li>';
        }
        h += '</ul>';
        left.innerHTML = h;
        var btns = left.querySelectorAll('[data-nav]');
        for (var j = 0; j < btns.length; j++) {
            btns[j].addEventListener('click', function () {
                selectedKey = this.getAttribute('data-nav');
                if (selectedKey === 'theme') {
                    viewMode = 'legacy';
                } else if (selectedKey === 'master') {
                    viewMode = 'master';
                } else if (selectedKey === 'preview') {
                    viewMode = 'preview';
                } else {
                    viewMode = 'effect';
                }
                buildLeftNav();
                renderCenter();
                updateBreadcrumbPreset();
            });
        }
    }

    function renderCenter() {
        var c = $('admin-center');
        if (!c) {
            return;
        }
        var prev = window.__jpSlotPrevViewMode;
        var curr = viewMode;
        if (prev === 'preview' && curr !== 'preview') {
            if (typeof window.jpSlotMoveRootToBody === 'function') {
                window.jpSlotMoveRootToBody();
            }
            fetchNui('admin/previewEnd', {});
        }
        window.__jpSlotPrevViewMode = curr;

        if (curr === 'preview') {
            c.innerHTML = renderPreviewTab();
            wirePreviewTab();
        } else if (curr === 'master') {
            c.innerHTML = renderPresetBarHtml() + renderMasterTab();
            wirePresetBar();
            wireMaster();
            refreshAllPresetSelects();
        } else if (curr === 'legacy') {
            c.innerHTML = legacyHtml();
            if (window.__jpSlotAdminLegacyBind) {
                window.__jpSlotAdminLegacyBind();
            }
        } else {
            c.innerHTML = renderEffectTab(selectedKey);
            wireEffectTab(selectedKey);
        }
        if (window.jpSlotApplyI18n) {
            window.jpSlotApplyI18n();
        }
        updateBreadcrumbPreset();
    }

    function buildRight() {
        var r = $('admin-right');
        if (!r) {
            return;
        }
        r.innerHTML = '';
    }

    function tryConfirmExit(done) {
        if (!workspace.dirty) {
            done();
            return;
        }
        var modal = $('admin-confirm-exit');
        if (!modal) {
            done();
            return;
        }
        var uns = modal && modal.querySelector('[data-unsaved]');
        if (uns) {
            uns.hidden = false;
        }
        if (modal) {
            modal.hidden = false;
        }
        var ok = $('admin-confirm-exit-ok');
        var cancel = $('admin-confirm-exit-cancel');
        function cleanup() {
            if (modal) {
                modal.hidden = true;
            }
            if (ok) {
                ok.onclick = null;
            }
            if (cancel) {
                cancel.onclick = null;
            }
        }
        if (ok) {
            ok.onclick = function () {
                cleanup();
                workspace.dirty = false;
                done();
            };
        }
        if (cancel) {
            cancel.onclick = cleanup;
        }
    }

    function onLogin() {
        fetchNui('admin/assets/scan', {}).then(function (r) {
            if (r.ok && r.assets) {
                window.__jpSlotAssetLib = r.assets;
            }
        });
    }

    function onOpenAdmin(_payload) {
        workspace = createDefaultWorkspace();
        selectedKey = 'master';
        viewMode = 'master';
        window.__jpSlotPrevViewMode = undefined;
        activePresetId = 'default';
        suppressAutosave = true;
        buildLeftNav();
        buildRight();
        fetchNui('admin/preset/list')
            .then(function (res) {
                var aid = res && res.activeId ? res.activeId : 'default';
                activePresetId = aid;
                return fetchNui('admin/preset/get', { id: aid });
            })
            .then(function (r) {
                if (r && r.ok && r.data) {
                    mergePresetWorkspace(r.data);
                    activePresetLabel =
                        r.data.name != null && String(r.data.name).trim() !== ''
                            ? String(r.data.name).trim()
                            : activePresetId;
                } else {
                    activePresetLabel = activePresetId || 'default';
                }
                suppressAutosave = false;
                workspace.dirty = false;
                renderCenter();
                if (window.jpSlotApplyI18n) {
                    window.jpSlotApplyI18n();
                }
                updateBreadcrumbPreset();
            })
            .catch(function () {
                suppressAutosave = false;
                activePresetLabel = activePresetId || 'default';
                renderCenter();
                if (window.jpSlotApplyI18n) {
                    window.jpSlotApplyI18n();
                }
                updateBreadcrumbPreset();
            });
    }

    window.JpSlotAdminStudio = {
        onLogin: onLogin,
        onOpenAdmin: onOpenAdmin,
        markDirty: markDirty,
    };

    window.JpSlotTryConfirmDirtyExit = function (done) {
        tryConfirmExit(done || function () {});
    };
})();
