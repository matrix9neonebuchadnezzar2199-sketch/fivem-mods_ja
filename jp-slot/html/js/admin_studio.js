/* global window, document, fetch, GetParentResourceName */
(function () {
    var RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'jp-slot';

    var STUDIO_NAV = [
        { key: 'master', icon: '🎲', i18n: 'admin.nav.master' },
        { key: 'idle', icon: '🎰', i18n: 'admin.nav.idle' },
        { key: 'win', icon: '🎯', i18n: 'admin.nav.win' },
        { key: 'bonus', icon: '🎁', i18n: 'admin.nav.bonus' },
        { key: 'bonus_streak', icon: '🔁', i18n: 'admin.nav.bonus_streak' },
        { key: 'bonus_big', icon: '💎', i18n: 'admin.nav.bonus_big' },
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
                b.enabled = false;
                b.text = '';
                b.effect = 'none';
                return b;
            })(),
            char_video: { enabled: true, file: '', fade_back: true },
            sound: {
                se: '',
                voice: '',
                bgm_change: false,
                bgm_file: '',
                bgm_duration_ms: 0,
            },
            reel_fx: { mode: 'none', custom_color: '#d4af37' },
            payout: { enabled: true, duration_ms: 2000, animation: 'countup' },
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
     * 保存時は buildPresetDataObject → admin/preset/saveNew 等でサーバー KVP に入る。
     */
    function studioReferenceEffects() {
        var effects = {};
        for (var i = 0; i < EFFECT_KEYS.length; i++) {
            effects[EFFECT_KEYS[i]] = defaultEffectSection();
        }

        var idle = effects.idle;
        idle.pre_text.text = 'おかえりなさい、マスター♪';
        idle.char_video.file = 'idle/portrait.png';

        var win = effects.win;
        win.pre_text.text = '当たり！';
        win.cutin_block = { kind: 'image', file: 'cutins/cutin_win_01.png', duration_ms: 1400 };
        win.char_video.file = 'win/win.webm';

        var bonus = effects.bonus;
        bonus.pre_text.text = 'ボーナスタイム！';
        bonus.cutin_block = { kind: 'image', file: 'cutins/cutin_bonus_01.png', duration_ms: 1800 };
        bonus.char_video.file = 'win/bigwin.webm';

        var bst = effects.bonus_streak;
        bst.pre_text.text = '連チャン！';
        bst.cutin_block = { kind: 'image', file: 'cutins/cutin_win_01.png', duration_ms: 1400 };
        bst.char_video.file = 'win/win.webm';

        var bbig = effects.bonus_big;
        bbig.pre_text.text = 'メガボーナス！';
        bbig.cutin_block = { kind: 'image', file: 'cutins/cutin_big_01.png', duration_ms: 2000 };
        bbig.char_video.file = 'win/bigwin.webm';

        var miss = effects.miss_tease;
        miss.pre_text.text = 'おかえりなさい、マスター♪';
        miss.char_video.file = 'idle/portrait.png';
        miss.payout.enabled = false;

        return effects;
    }

    function createDefaultWorkspace() {
        return {
            master: defaultMaster(),
            effects: studioReferenceEffects(),
            dirty: false,
            characterId: 'luna',
        };
    }

    function cloneJson(obj) {
        return JSON.parse(JSON.stringify(obj));
    }

    /** 当たり・ボーナス入口のみ編集し、通常は 100 − win − bonus に同期 */
    function clampMasterNormalInvariant(master) {
        var n = master.normal || {};
        var w = Math.max(0, Math.min(100, Number(n.win) || 0));
        var b = Math.max(0, Math.min(100 - w, Number(n.bonus) || 0));
        n.win = Math.round(w * 10) / 10;
        n.bonus = Math.round(b * 10) / 10;
        n.miss_tease = Math.round((100 - n.win - n.bonus) * 10) / 10;
        master.normal = n;
    }

    /** 連続・ビッグのみ編集し、単発の抽選内は 100 − streak − big（読み取り専用表示） */
    function clampBonusPromoteInvariant(master) {
        var bp = master.bonus_promote || {};
        var s = Math.max(0, Math.min(100, Number(bp.streak) || 0));
        var g = Math.max(0, Math.min(100 - s, Number(bp.big) || 0));
        bp.streak = Math.round(s * 10) / 10;
        bp.big = Math.round(g * 10) / 10;
        master.bonus_promote = bp;
    }

    function mergeMasterData(incoming) {
        var def = defaultMaster();
        if (!incoming || typeof incoming !== 'object') {
            return def;
        }
        var out = {
            normal: Object.assign({}, def.normal, incoming.normal || {}),
            bonus_promote: Object.assign({}, def.bonus_promote, incoming.bonus_promote || {}),
            cooldown: Object.assign({}, def.cooldown, incoming.cooldown || {}),
        };
        clampMasterNormalInvariant(out);
        clampBonusPromoteInvariant(out);
        return out;
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

    /**
     * 古いプリセット・effects 欠落 KVP でも欠落キーを埋める。
     * ベースは studioReferenceEffects（運営が default から編集する想定の文言・ファイル例）。
     * 保存済みの値は incoming が優先される。
     */
    function mergeEffectsData(incoming) {
        var baseShape = studioReferenceEffects();
        if (!incoming || typeof incoming !== 'object') {
            return cloneJson(baseShape);
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
    /** 「通常 / Idle」ナビ選択時のみ：idle 本体か通常結果（旧 miss_tease）編集かの切替 */
    var idleEffectMode = 'idle';
    /** プリセットヘッダーで選択中のキャラ（フォルダスキャン由来の ID） */
    var selectedCharacterId = 'luna';
    /** 選択中プリセット名。null は新規未保存（自動保存しない） */
    var selectedPresetName = 'default';
    /** エディタに載っているデータの元（読み込み時に更新） */
    var loadedCharacterId = 'luna';
    var loadedPresetName = 'default';
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
                return r.text().then(function (text) {
                    var parsed = null;
                    if (text && String(text).trim()) {
                        try {
                            parsed = JSON.parse(text);
                        } catch (e) {
                            return { ok: false, reason: 'parse_error' };
                        }
                    }
                    if (!r.ok) {
                        if (parsed && typeof parsed === 'object') {
                            parsed.ok = false;
                            return parsed;
                        }
                        return { ok: false, status: r.status };
                    }
                    if (parsed && typeof parsed === 'object') {
                        return parsed;
                    }
                    return { ok: true };
                });
            })
            .catch(function () {
                return { ok: false, reason: 'network' };
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
        if (suppressAutosave) {
            return;
        }
        if (selectedPresetName === null || selectedPresetName === '') {
            return;
        }
        fetchNui('admin/preset/saveOverwrite', {
            characterId: selectedCharacterId,
            presetName: selectedPresetName,
            data: buildPresetDataObject(),
        })
            .then(function (r) {
                if (r && r.ok) {
                    workspace.dirty = false;
                    loadedCharacterId = selectedCharacterId;
                    loadedPresetName = selectedPresetName;
                    updateBreadcrumbPreset();
                    updatePresetActionButtonsDisabled();
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
        if (data.characterId != null && String(data.characterId).trim() !== '') {
            workspace.characterId = String(data.characterId).trim();
        }
    }

    /** ホーム › 演出 › （読み込み中のプリセット名）。applyI18n で上書きされないよう data-i18n-key は付けない */
    function updateBreadcrumbPreset() {
        var el = $('adm-current-state');
        if (!el) {
            return;
        }
        el.removeAttribute('data-i18n-key');
        var label =
            loadedPresetName !== null && loadedPresetName !== ''
                ? loadedCharacterId + '/' + loadedPresetName
                : '—';
        el.textContent = label;
    }

    /** default プリセット時はプレビューで Config 既定キャラ（ルナ等）の名前・画像を出さない */
    function embedSlotInitOpts() {
        return {
            neutralPreviewCharacter: loadedPresetName === 'default',
            characterId: workspace.characterId || selectedCharacterId || 'luna',
        };
    }

    function buildPresetDataObject() {
        return {
            master: workspace.master,
            effects: workspace.effects,
            characterId: workspace.characterId || selectedCharacterId || 'luna',
            name: selectedPresetName || loadedPresetName || 'preset',
            editor: 'studio-v2',
        };
    }

    function updatePresetActionButtonsDisabled() {
        var ow = $('btn-preset-save-overwrite');
        var del = $('btn-preset-delete');
        var dis = selectedPresetName === null || selectedPresetName === '';
        if (ow) {
            ow.disabled = dis;
        }
        if (del) {
            del.disabled = dis;
        }
    }

    function openPresetConfirmModal(title, body, onOk) {
        var modal = $('preset-confirm-modal');
        var tEl = $('preset-confirm-modal-title');
        var bEl = $('preset-confirm-modal-body');
        var okBtn = $('preset-confirm-ok');
        var cancelBtn = $('preset-confirm-cancel');
        if (!modal || !okBtn || !cancelBtn) {
            if (onOk) {
                onOk();
            }
            return;
        }
        if (tEl) {
            tEl.textContent = title || '';
        }
        if (bEl) {
            bEl.textContent = body || '';
        }
        modal.hidden = false;
        function cleanup() {
            modal.hidden = true;
            okBtn.onclick = null;
            cancelBtn.onclick = null;
        }
        cancelBtn.onclick = cleanup;
        okBtn.onclick = function () {
            cleanup();
            if (onOk) {
                onOk();
            }
        };
    }

    function tryNavigatePresetSwitch(next) {
        if (!workspace.dirty) {
            next();
            return;
        }
        var modal = $('preset-dirty-modal');
        var okBtn = $('preset-dirty-ok');
        var cancelBtn = $('preset-dirty-cancel');
        if (!modal || !okBtn || !cancelBtn) {
            next();
            return;
        }
        modal.hidden = false;
        function cleanup() {
            modal.hidden = true;
            okBtn.onclick = null;
            cancelBtn.onclick = null;
        }
        cancelBtn.onclick = cleanup;
        okBtn.onclick = function () {
            cleanup();
            workspace.dirty = false;
            next();
        };
        if (window.jpSlotApplyI18n) {
            window.jpSlotApplyI18n();
        }
    }

    /** キャラ一覧が空のときのフォールバック（サーバー util のフォールバックと二重化してもよい） */
    function ensureAdminCharacterListFallback() {
        if (window.__jpSlotAdminCharacters && window.__jpSlotAdminCharacters.length) {
            return;
        }
        var id =
            (workspace && workspace.characterId && String(workspace.characterId).trim()) || 'luna';
        window.__jpSlotAdminCharacters = [{ id: id, displayName: id }];
    }

    function fillCharacterDropdown(selectEl, list, selectedId) {
        if (!selectEl || !list) {
            return;
        }
        selectEl.innerHTML = '';
        var i;
        for (i = 0; i < list.length; i++) {
            var e = list[i];
            if (!e || !e.id) {
                continue;
            }
            var opt = document.createElement('option');
            opt.value = e.id;
            opt.textContent = e.displayName || e.id;
            selectEl.appendChild(opt);
        }
        if (selectedId) {
            selectEl.value = selectedId;
        }
        if (selectEl.selectedIndex < 0 && selectEl.options.length) {
            selectEl.value = selectEl.options[0].value;
        }
    }

    function applyPresetListToSelect(sel, plist, selectedName) {
        if (!sel) {
            return;
        }
        sel.innerHTML = '';
        var j;
        for (j = 0; j < plist.length; j++) {
            var row = plist[j];
            if (!row || !row.name) {
                continue;
            }
            var o = document.createElement('option');
            o.value = row.name;
            o.textContent = row.name;
            sel.appendChild(o);
        }
        if (selectedName) {
            sel.value = selectedName;
        }
        if (sel.selectedIndex < 0 && sel.options.length) {
            sel.value = sel.options[0].value;
        }
    }

    function loadPresetWorkspaceFromServer(characterId, presetName, opts) {
        opts = opts || {};
        suppressAutosave = true;
        fetchNui('admin/preset/get', {
            characterId: characterId,
            presetName: presetName,
        })
            .then(function (r) {
                if (!r || !r.ok || !r.data) {
                    suppressAutosave = false;
                    showAdminToast('プリセットを読み込めませんでした', true);
                    return;
                }
                mergePresetWorkspace(r.data);
                selectedCharacterId = characterId;
                selectedPresetName = presetName;
                loadedCharacterId = characterId;
                loadedPresetName = presetName;
                workspace.characterId = r.data.characterId || characterId;
                suppressAutosave = false;
                workspace.dirty = false;
                updateBreadcrumbPreset();
                updatePresetActionButtonsDisabled();
                if (!opts.skipRender) {
                    renderCenter();
                }
                if (window.jpSlotApplyI18n) {
                    window.jpSlotApplyI18n();
                }
            })
            .catch(function () {
                suppressAutosave = false;
                showAdminToast('プリセットの読み込みに失敗しました（通信エラー）', true);
            });
    }

    function hydratePresetHeaderUi() {
        var chars = window.__jpSlotAdminCharacters;
        if (!chars || !chars.length) {
            fetchNui('admin/characters/list').then(function (cr) {
                window.__jpSlotAdminCharacters = cr && cr.ok && cr.list ? cr.list : [];
                ensureAdminCharacterListFallback();
                hydratePresetHeaderUi();
            });
            return;
        }
        fillCharacterDropdown($('preset-character-select'), chars, selectedCharacterId);
        var cid = ($('preset-character-select') && $('preset-character-select').value) || selectedCharacterId;
        selectedCharacterId = cid;
        fetchNui('admin/preset/listByCharacter', { characterId: cid }).then(function (lr) {
            var plist = lr && lr.ok && lr.list ? lr.list : [];
            applyPresetListToSelect($('preset-name-select'), plist, selectedPresetName);
            var ns = $('preset-name-select');
            if (ns && ns.value) {
                selectedPresetName = ns.value;
            }
            updatePresetActionButtonsDisabled();
            if (window.jpSlotApplyI18n) {
                window.jpSlotApplyI18n();
            }
        });
    }

    function renderPresetBarHtml() {
        return (
            '<div class="preset-header-studio studio-card">' +
            '<div class="preset-header-row">' +
            '<label class="preset-header-label"><span data-i18n-key="admin.preset.character_label">キャラクター</span></label>' +
            '<select id="preset-character-select" class="studio-preset-select"></select>' +
            '</div>' +
            '<div class="preset-header-row">' +
            '<label class="preset-header-label"><span data-i18n-key="admin.preset.preset_label">プリセット</span></label>' +
            '<select id="preset-name-select" class="studio-preset-select"></select>' +
            '</div>' +
            '<div class="preset-header-actions">' +
            '<button type="button" class="studio-btn-primary" id="btn-preset-save-new" data-i18n-key="admin.preset.btn_save_new">新規保存</button> ' +
            '<button type="button" class="studio-btn-secondary" id="btn-preset-save-overwrite" data-i18n-key="admin.preset.btn_save_overwrite">上書き保存</button> ' +
            '<button type="button" class="studio-btn-danger" id="btn-preset-delete" data-i18n-key="admin.preset.btn_delete">削除</button> ' +
            '<button type="button" class="studio-btn-secondary" id="btn-preset-set-active" data-i18n-key="admin.preset.btn_set_active">本番反映</button>' +
            '</div></div>'
        );
    }

    function wirePresetBar() {
        var ch = $('preset-character-select');
        var ns = $('preset-name-select');
        if (ch) {
            ch.onchange = function () {
                var cid = ch.value || 'luna';
                tryNavigatePresetSwitch(function () {
                    selectedCharacterId = cid;
                    workspace.characterId = cid;
                    fetchNui('admin/assets/scan', { characterId: cid, kind: 'all' }).then(function (r) {
                        if (r && r.ok && r.assets) {
                            window.__jpSlotAssetLib = r.assets;
                            ensureAssetDatalists();
                        }
                    });
                    fetchNui('admin/preset/listByCharacter', { characterId: cid }).then(function (lr) {
                        var plist = lr && lr.ok && lr.list ? lr.list : [];
                        var ns2 = $('preset-name-select');
                        applyPresetListToSelect(ns2, plist, null);
                        var pick = ns2 && ns2.value ? ns2.value : null;
                        if (pick) {
                            loadPresetWorkspaceFromServer(cid, pick, {});
                        } else {
                            workspace = createDefaultWorkspace();
                            workspace.characterId = cid;
                            selectedPresetName = null;
                            loadedPresetName = null;
                            suppressAutosave = false;
                            workspace.dirty = false;
                            renderCenter();
                        }
                    });
                });
            };
        }
        if (ns) {
            ns.onchange = function () {
                var pname = ns.value;
                tryNavigatePresetSwitch(function () {
                    if (!pname) {
                        selectedPresetName = null;
                        return;
                    }
                    loadPresetWorkspaceFromServer(selectedCharacterId, pname, {});
                });
            };
        }
        var bn = $('btn-preset-save-new');
        if (bn) {
            bn.onclick = function () {
                openPresetNameModal('', function (val) {
                    if (!val || String(val).trim() === '') {
                        return;
                    }
                    val = String(val).trim();
                    fetchNui('admin/preset/saveNew', {
                        characterId: selectedCharacterId,
                        presetName: val,
                        data: buildPresetDataObject(),
                    }).then(function (r) {
                        if (window.jpSlotNuiLog) {
                            window.jpSlotNuiLog('log', '[admin] saveNew result: ' + JSON.stringify(r));
                        }
                        if (r && r.ok) {
                            selectedPresetName = val;
                            loadedPresetName = val;
                            loadedCharacterId = selectedCharacterId;
                            workspace.dirty = false;
                            hydratePresetHeaderUi();
                            updateBreadcrumbPreset();
                            updatePresetActionButtonsDisabled();
                            if (viewMode === 'preview') {
                                fetchNui('admin/embedSlotInit', embedSlotInitOpts());
                            }
                            showAdminToast('保存しました', false);
                            return;
                        }
                        if (r && r.reason === 'duplicate') {
                            showAdminToast('同名のプリセットがあります', true);
                            return;
                        }
                        if (r && r.reason === 'invalid_name') {
                            showAdminToast('プリセット名が不正です（1〜32文字・許容文字のみ）', true);
                            return;
                        }
                        showAdminToast('保存に失敗しました', true);
                    });
                });
            };
        }
        var bo = $('btn-preset-save-overwrite');
        if (bo) {
            bo.onclick = function () {
                if (selectedPresetName === null || selectedPresetName === '') {
                    return;
                }
                var msg = '"' + selectedPresetName + '" を上書きしますか?';
                openPresetConfirmModal('', msg, function () {
                    fetchNui('admin/preset/saveOverwrite', {
                        characterId: selectedCharacterId,
                        presetName: selectedPresetName,
                        data: buildPresetDataObject(),
                    }).then(function (r) {
                        if (r && r.ok) {
                            workspace.dirty = false;
                            showAdminToast('保存しました', false);
                            updateBreadcrumbPreset();
                        } else {
                            showAdminToast('保存に失敗しました', true);
                        }
                    });
                });
            };
        }
        var bd = $('btn-preset-delete');
        if (bd) {
            bd.onclick = function () {
                if (selectedPresetName === null || selectedPresetName === '') {
                    return;
                }
                var msg = '"' + selectedPresetName + '" を削除しますか?';
                openPresetConfirmModal('', msg, function () {
                    fetchNui('admin/preset/delete', {
                        characterId: selectedCharacterId,
                        presetName: selectedPresetName,
                    }).then(function (r) {
                        if (r && r.ok) {
                            workspace.dirty = false;
                            fetchNui('admin/preset/listByCharacter', {
                                characterId: selectedCharacterId,
                            }).then(function (lr) {
                                var plist = lr && lr.ok && lr.list ? lr.list : [];
                                var ns3 = $('preset-name-select');
                                applyPresetListToSelect(ns3, plist, null);
                                var pick = ns3 && ns3.value ? ns3.value : null;
                                if (pick) {
                                    loadPresetWorkspaceFromServer(selectedCharacterId, pick, {});
                                } else {
                                    workspace = createDefaultWorkspace();
                                    workspace.characterId = selectedCharacterId;
                                    selectedPresetName = null;
                                    loadedPresetName = null;
                                    renderCenter();
                                }
                            });
                            showAdminToast('削除しました', false);
                            return;
                        }
                        showAdminToast('削除に失敗しました', true);
                    });
                });
            };
        }
        var ba = $('btn-preset-set-active');
        if (ba) {
            ba.onclick = function () {
                if (selectedPresetName === null || selectedPresetName === '') {
                    showAdminToast('プリセットを選択してください', true);
                    return;
                }
                fetchNui('admin/preset/setActive', {
                    characterId: selectedCharacterId,
                    presetName: selectedPresetName,
                }).then(function (r) {
                    if (r && r.ok) {
                        showAdminToast(
                            selectedCharacterId + '/' + selectedPresetName + ' を本番反映しました',
                            false
                        );
                        return;
                    }
                    showAdminToast('本番反映に失敗しました', true);
                });
            };
        }
        updatePresetActionButtonsDisabled();
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

    /**
     * 通常抽選の第1段（通常・当たり・ボーナス入口）の行。glyph でツリー表示。
     * @param {object} [opts]
     * @param {string} [opts.glyph]
     * @param {string} [opts.labelKey] admin.master.* （jpSlotApplyI18n 用）
     */
    function rowMaster(k, label, val, opts) {
        opts = opts || {};
        var glyph = opts.glyph != null ? opts.glyph : '';
        var labelKey = opts.labelKey;
        var labelInner =
            labelKey && String(labelKey).indexOf('admin.') === 0
                ? '<span data-i18n-key="' + labelKey + '">' + escapeHtml(label) + '</span>'
                : escapeHtml(label);
        return (
            '<div class="studio-row master-row studio-master-tree-node" data-k="' +
            k +
            '">' +
            '<div class="studio-row-label studio-master-tree-label-cell">' +
            '<span class="studio-master-tree-glyph">' +
            escapeHtml(glyph) +
            '</span>' +
            '<span class="studio-master-tree-label-text">' +
            labelInner +
            '</span>' +
            '</div>' +
            '<div class="studio-row-control studio-master-row-control">' +
            '<button type="button" class="studio-step-btn js-master-nudge" data-k="' +
            k +
            '" data-delta="-0.1" title="-0.1%" aria-label="-0.1%">' +
            '−</button>' +
            '<input type="range" min="0" max="100" step="0.1" class="studio-slider master-sl" data-k="' +
            k +
            '" value="' +
            val +
            '">' +
            '<button type="button" class="studio-step-btn js-master-nudge" data-k="' +
            k +
            '" data-delta="0.1" title="+0.1%" aria-label="+0.1%">' +
            '+</button>' +
            '<span class="studio-slider-value master-sl-val">' +
            Number(val).toFixed(1) +
            '%</span>' +
            '</div></div>'
        );
    }

    /** 通常（miss_tease）— スライダーなし・当たり・ボーナスから自動算出 */
    function rowMasterMissReadonly(val, label, opts) {
        opts = opts || {};
        var glyph = opts.glyph != null ? opts.glyph : '';
        var labelKey = opts.labelKey;
        var labelInner =
            labelKey && String(labelKey).indexOf('admin.') === 0
                ? '<span data-i18n-key="' + labelKey + '">' + escapeHtml(label) + '</span>'
                : escapeHtml(label);
        return (
            '<div class="studio-row master-row master-row--miss-auto studio-master-tree-node" data-k="miss_tease">' +
            '<div class="studio-row-label studio-master-tree-label-cell">' +
            '<span class="studio-master-tree-glyph">' +
            escapeHtml(glyph) +
            '</span>' +
            '<span class="studio-master-tree-label-text">' +
            labelInner +
            '</span>' +
            '</div>' +
            '<div class="studio-row-control studio-master-row-control studio-master-row-control--miss-auto">' +
            '<span class="studio-master-auto-hint" data-i18n-key="admin.master.tree_miss_auto">自動</span>' +
            '<span id="master-miss-display" class="studio-slider-value master-sl-val">' +
            Number(val).toFixed(1) +
            '%</span>' +
            '</div></div>'
        );
    }

    /** ボーナス昇格（STREAK / BIG）の行＋実効確率ピル */
    function rowPromoteBonusChild(pk, label, val, jointAbs, opts) {
        opts = opts || {};
        var glyph = opts.glyph != null ? opts.glyph : '';
        var labelKey = opts.labelKey;
        var labelInner =
            labelKey && String(labelKey).indexOf('admin.') === 0
                ? '<span data-i18n-key="' + labelKey + '">' + escapeHtml(label) + '</span>'
                : escapeHtml(label);
        var jid = 'master-joint-' + pk;
        return (
            '<div class="studio-row studio-master-promote-row studio-master-tree-node studio-master-tree-node--bonus-child">' +
            '<div class="studio-row-label studio-master-tree-label-cell">' +
            '<span class="studio-master-tree-glyph">' +
            escapeHtml(glyph) +
            '</span>' +
            '<span class="studio-master-tree-label-text">' +
            labelInner +
            '</span>' +
            '</div>' +
            '<div class="studio-row-control studio-master-row-control">' +
            '<button type="button" class="studio-step-btn js-promote-nudge" data-pk="' +
            pk +
            '" data-delta="-0.1" title="-0.1%" aria-label="-0.1%">' +
            '−</button>' +
            '<input type="range" min="0" max="100" step="0.1" class="studio-slider pr-sl" data-pk="' +
            pk +
            '" value="' +
            val +
            '">' +
            '<button type="button" class="studio-step-btn js-promote-nudge" data-pk="' +
            pk +
            '" data-delta="0.1" title="+0.1%" aria-label="+0.1%">' +
            '+</button>' +
            '<span class="studio-slider-value pr-sl-val">' +
            Number(val).toFixed(1) +
            '%</span>' +
            '<span class="studio-master-joint-pill" id="' +
            jid +
            '" title="全スピンに対する実効確率">' +
            jointAbs.toFixed(2) +
            '%</span>' +
            '</div></div>'
        );
    }

    /** 単発（昇格なし）— 抽選内％と実効％は自動算出（読み取り専用） */
    function renderPlainBonusChildRow(m) {
        var b = Number(m.normal.bonus);
        var ps = Number(m.bonus_promote.streak);
        var pb = Number(m.bonus_promote.big);
        var inner = Math.max(0, 100 - ps - pb);
        var jp = (b * inner) / 100;
        var label = '単発（昇格なし）';
        return (
            '<div class="studio-row studio-master-tree-node studio-master-tree-node--bonus-child studio-master-tree-node--readonly">' +
            '<div class="studio-row-label studio-master-tree-label-cell">' +
            '<span class="studio-master-tree-glyph">' +
            escapeHtml('├─') +
            '</span>' +
            '<span class="studio-master-tree-label-text">' +
            '<span data-i18n-key="admin.master.tree_plain">' +
            escapeHtml(label) +
            '</span>' +
            '</span>' +
            '</div>' +
            '<div class="studio-row-control studio-master-tree-plain-joint">' +
            '<span class="studio-master-joint-label" data-i18n-key="admin.master.joint_effective_short">' +
            escapeHtml('実効') +
            '</span> ' +
            '<span id="master-joint-plain" class="studio-slider-value studio-single-readonly">' +
            jp.toFixed(2) +
            '%</span>' +
            '<span class="studio-master-joint-sep"></span>' +
            '<span class="studio-master-inner-label" data-i18n-key="admin.master.weight_inner_short">' +
            escapeHtml('抽選内') +
            '</span> ' +
            '<span id="master-inner-plain" class="studio-slider-value studio-single-readonly">' +
            inner.toFixed(2) +
            '%</span>' +
            '</div></div>'
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

    function getAssetLib() {
        return window.__jpSlotAssetLib || {};
    }

    /**
     * html/assets スキャン結果から相対パスを選ぶ select（空・一覧・一覧外の保存値）
     * @param {string} dataPath data-path
     * @param {string} currentValue 現在値
     * @param {string[]} relPathList サーバーが返す相対パス配列
     */
    function buildAssetPathSelect(dataPath, currentValue, relPathList) {
        var cur = currentValue != null ? String(currentValue).trim() : '';
        var list = relPathList || [];
        var seen = {};
        var h =
            '<select class="studio-input-wide studio-select-asset" data-path="' +
            dataPath +
            '" autocomplete="off">';
        h += '<option value=""' + selAttr(cur, '') + '>' + escapeHtml('（未指定）') + '</option>';
        var i;
        for (i = 0; i < list.length; i++) {
            var p = list[i];
            if (p == null || String(p).trim() === '') {
                continue;
            }
            var ps = String(p).trim();
            if (seen[ps]) {
                continue;
            }
            seen[ps] = true;
            h +=
                '<option value="' +
                escAttr(ps) +
                '"' +
                selAttr(cur, ps) +
                '>' +
                escapeHtml(ps) +
                '</option>';
        }
        if (cur && !seen[cur]) {
            h +=
                '<option value="' +
                escAttr(cur) +
                '" selected>' +
                escapeHtml(cur + ' （一覧外・保存済み）') +
                '</option>';
        }
        h += '</select>';
        return h;
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
            miss_tease: 'admin.scene.miss_tease_title',
        };
        return map[key] || '';
    }

    /**
     * @param {boolean} [idleStudioNav] 「通常/Idle」ナビ時はプレ・配当を時系列に含めない（中央列を出さないため）
     */
    function estimateTimelineSec(sec, sceneKey, idleStudioNav) {
        var ms = 0;
        if (!idleStudioNav) {
            if (sec.pre_text && sec.pre_text.enabled !== false && (sec.pre_text.text || '').trim()) {
                ms += Number(sec.pre_text.duration_ms) || 600;
            }
        }
        var cb = sec.cutin_block || {};
        if (cb.kind && cb.kind !== 'none' && (cb.file || '').trim()) {
            ms += Number(cb.duration_ms) || 1200;
        }
        if (!idleStudioNav && sceneKey !== 'miss_tease' && sec.payout && sec.payout.enabled !== false) {
            ms += Number(sec.payout.duration_ms) || 2000;
        }
        return (ms / 1000).toFixed(1);
    }

    function normalizeMaster() {
        clampMasterNormalInvariant(workspace.master);
        clampBonusPromoteInvariant(workspace.master);
        markDirty();
        renderCenter();
    }

    function syncMasterNormalDom() {
        var n = workspace.master.normal;
        ['win', 'bonus'].forEach(function (k) {
            var row = document.querySelector('.master-row[data-k="' + k + '"]');
            if (!row) {
                return;
            }
            var sl = row.querySelector('.master-sl');
            var lab = row.querySelector('.master-sl-val');
            if (sl) {
                sl.value = String(n[k]);
            }
            if (lab) {
                lab.textContent = Number(n[k]).toFixed(1) + '%';
            }
        });
        var md = $('master-miss-display');
        if (md) {
            md.textContent = Number(n.miss_tease).toFixed(1) + '%';
        }
    }

    function syncPromoteDom() {
        var bp = workspace.master.bonus_promote;
        ['streak', 'big'].forEach(function (pk) {
            var sl = document.querySelector('.pr-sl[data-pk="' + pk + '"]');
            if (!sl) {
                return;
            }
            sl.value = String(bp[pk]);
            var prow = sl.closest('.studio-row');
            var pv = prow ? prow.querySelector('.pr-sl-val') : null;
            if (pv) {
                pv.textContent = Number(bp[pk]).toFixed(1) + '%';
            }
        });
    }

    function updateMasterSumDisplay() {
        var sum =
            workspace.master.normal.win +
            workspace.master.normal.bonus +
            workspace.master.normal.miss_tease;
        var okNow = masterSumOk(workspace.master);
        var el = $('master-sum-val');
        if (el) {
            el.textContent = '合計 ' + sum.toFixed(1) + '%' + (okNow ? ' ✓' : '');
            el.className = 'studio-card-title-status' + (okNow ? '' : ' is-error');
        }
    }

    /** ボーナス配下の「実効％」（全スピンに対する結合確率）と単発の抽選内％を更新 */
    function refreshMasterJointLabels() {
        var m = workspace.master;
        var b = Number(m.normal.bonus);
        var ps = Number(m.bonus_promote.streak);
        var pb = Number(m.bonus_promote.big);
        var inner = Math.max(0, 100 - ps - pb);
        var jp = (b * inner) / 100;
        var jst = (b * ps) / 100;
        var jbg = (b * pb) / 100;
        var el;
        el = $('master-joint-plain');
        if (el) {
            el.textContent = jp.toFixed(2) + '%';
        }
        el = $('master-inner-plain');
        if (el) {
            el.textContent = inner.toFixed(2) + '%';
        }
        el = $('master-joint-streak');
        if (el) {
            el.textContent = jst.toFixed(2) + '%';
        }
        el = $('master-joint-big');
        if (el) {
            el.textContent = jbg.toFixed(2) + '%';
        }
    }

    /** 当たり・ボーナス入口のみ。通常は 100 − 両者で自動（合計は常に 100% 以内にキャップ） */
    function applyMasterNormalValue(k, raw) {
        if (k !== 'win' && k !== 'bonus') {
            return;
        }
        var v = Math.round(Number(raw) * 10) / 10;
        if (isNaN(v)) {
            return;
        }
        v = Math.max(0, Math.min(100, v));
        var n = workspace.master.normal;
        if (k === 'win') {
            n.win = v;
            n.bonus = Math.round(Math.min(Number(n.bonus), 100 - v) * 10) / 10;
            n.miss_tease = Math.round((100 - n.win - n.bonus) * 10) / 10;
        } else {
            n.bonus = v;
            n.win = Math.round(Math.min(Number(n.win), 100 - v) * 10) / 10;
            n.miss_tease = Math.round((100 - n.win - n.bonus) * 10) / 10;
        }
        syncMasterNormalDom();
        updateMasterSumDisplay();
        refreshMasterJointLabels();
        markDirty();
    }

    /** 連続・ビッグのみ。単発の抽選内は残り（合計 100% 以内にキャップ） */
    function applyPromoteValue(pk, raw) {
        if (pk !== 'streak' && pk !== 'big') {
            return;
        }
        var v = Math.round(Number(raw) * 10) / 10;
        if (isNaN(v)) {
            return;
        }
        v = Math.max(0, Math.min(100, v));
        var bp = workspace.master.bonus_promote;
        if (pk === 'streak') {
            bp.streak = v;
            bp.big = Math.round(Math.min(Number(bp.big), 100 - v) * 10) / 10;
        } else {
            bp.big = v;
            bp.streak = Math.round(Math.min(Number(bp.streak), 100 - v) * 10) / 10;
        }
        syncPromoteDom();
        refreshMasterJointLabels();
        markDirty();
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
                buildAssetPathSelect('cutin_block.file', cb.file, getAssetLib().cutins)
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
                buildAssetPathSelect('char_video.file', cv.file, getAssetLib().characters)
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

    /** Idle／通常結果：台左の縦長エリア（左キャラ）のみ */
    function renderLeftVerticalStripColumn(sec) {
        var cv = sec.char_video || { enabled: true, file: '', fade_back: true };
        var lib = getAssetLib();
        var body = '';
        body +=
            '<div class="studio-row studio-row--check"><div class="studio-row-label"></div><div class="studio-row-control">' +
            '<label class="studio-inline-check"><input type="checkbox" data-path="char_video.enabled"' +
            chkAttr(cv.enabled !== false) +
            '> <span data-i18n-key="admin.effect.field_use_block">左キャラを使用</span></label>' +
            '</div></div>';
        body +=
            studioRowField(
                'admin.effect.char_file',
                '左キャラ画像または動画',
                buildAssetPathSelect('char_video.file', cv.file, lib.characters)
            );
        body +=
            studioRowField(
                'admin.effect.char_fade_back',
                '静止画フェード復帰',
                '<label class="studio-inline-check"><input type="checkbox" data-path="char_video.fade_back"' +
                chkAttr(cv.fade_back !== false) +
                '> ON</label>'
            );
        body +=
            '<p class="studio-note studio-cutin-hint" data-i18n-key="admin.effect.left_vertical_hint"></p>';
        body +=
            '<div class="studio-effect-asset-preview" id="studio-effect-asset-preview" aria-label="素材プレビュー">' +
            '<span class="studio-effect-preview-placeholder">ファイルを入力すると表示されます</span>' +
            '</div>';
        return (
            '<div class="studio-card studio-effect-block studio-effect-col-main">' +
            '<div class="studio-card-title"><span data-i18n-key="admin.effect.block_left_vertical"></span></div>' +
            body +
            '</div>'
        );
    }

    /** 当たり・ボーナス系：カットイン（種別・ファイル・時間）＋プレビュー */
    function renderLeftCutinOnlyColumn(sec) {
        var cb = sec.cutin_block || { kind: 'none', file: '', duration_ms: 1200 };
        var kind = cb.kind || 'none';
        var dm = cb.duration_ms != null ? cb.duration_ms : 1200;
        var lib = getAssetLib();
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
                'カットイン素材',
                buildAssetPathSelect('cutin_block.file', cb.file, lib.cutins)
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
            '<p class="studio-note studio-cutin-hint" data-i18n-key="admin.effect.cutin_preview_hint"></p>';
        body +=
            '<div class="studio-effect-asset-preview" id="studio-effect-asset-preview" aria-label="カットインプレビュー">' +
            '<span class="studio-effect-preview-placeholder">ファイルを入力すると表示されます</span>' +
            '</div>';
        return (
            '<div class="studio-card studio-effect-block studio-effect-col-main">' +
            '<div class="studio-card-title"><span data-i18n-key="admin.effect.block_cutin_panel"></span></div>' +
            body +
            '</div>'
        );
    }

    function renderLeftEffectColumn(sceneKey, sec) {
        if (sceneKey === 'idle' || sceneKey === 'miss_tease') {
            return renderLeftVerticalStripColumn(sec);
        }
        return renderLeftCutinOnlyColumn(sec);
    }

    /** 右列：BGM＋再生時間を主に表示、SE/ボイスは折りたたみ */
    function renderSoundRightColumn(snd) {
        snd = snd || {
            se: '',
            voice: '',
            bgm_change: false,
            bgm_file: '',
            bgm_duration_ms: 0,
        };
        var bgmDur = snd.bgm_duration_ms != null ? Number(snd.bgm_duration_ms) : 0;
        var lib = getAssetLib();
        var body = '';
        body +=
            '<div class="studio-row"><div class="studio-row-label"><span data-i18n-key="admin.effect.sound_bgm">BGM切替</span></div><div class="studio-row-control">' +
            '<label class="studio-inline-check"><input type="checkbox" data-path="sound.bgm_change"' +
            chkAttr(snd.bgm_change === true) +
            '> <span data-i18n-key="admin.effect.sound_bgm_use">別BGMに切替</span></label>' +
            '</div></div>';
        body +=
            studioRowField(
                'admin.effect.sound_bgm_file_main',
                '再生する音楽（sound/bgm/ に配置）',
                buildAssetPathSelect('sound.bgm_file', snd.bgm_file, lib.bgm)
            );
        body +=
            studioRowField(
                'admin.effect.sound_bgm_duration',
                '再生時間 (ms)',
                '<input type="range" min="0" max="180000" step="500" class="studio-slider" data-path="sound.bgm_duration_ms" value="' +
                    escAttr(bgmDur) +
                    '"><span class="studio-slider-value ef-range-val">' +
                    (bgmDur <= 0 ? 'フル' : Math.round(Number(bgmDur)) + ' ms') +
                    '</span>'
            );
        body +=
            '<p class="studio-note">0 のときは曲全体（またはゲーム側既定）。演出プリセット保存で記録されます。</p>';
        body +=
            '<details class="studio-sound-advanced">' +
            '<summary class="studio-sound-advanced-sum">SE・ボイス（詳細）</summary>' +
            '<div class="studio-sound-advanced-body">';
        body +=
            studioRowField(
                'admin.effect.sound_se',
                'SE',
                '<input type="text" class="studio-input-wide" data-path="sound.se" value="' +
                    escAttr(snd.se) +
                    '" list="jp-slot-dl-se" placeholder="sound/se/..." autocomplete="off">'
            );
        body +=
            studioRowField(
                'admin.effect.sound_voice',
                'ボイス',
                '<input type="text" class="studio-input-wide" data-path="sound.voice" value="' +
                    escAttr(snd.voice) +
                    '" list="jp-slot-dl-voice" placeholder="sound/voice/..." autocomplete="off">'
            );
        body += '</div></details>';
        return (
            '<div class="studio-card studio-effect-block studio-effect-col-main">' +
            '<div class="studio-card-title">音楽・サウンド</div>' +
            body +
            '</div>'
        );
    }

    function renderSoundCard(snd) {
        return renderSoundRightColumn(snd);
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
            '<span class="studio-effect-block-num">③</span> <span data-i18n-key="admin.effect.block_reel_fx"></span>';
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
                '<p class="studio-note studio-payout-miss" data-i18n-key="admin.effect.payout_miss_note">通常演出では配当表示は使いません。</p>';
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
            '<span class="studio-effect-block-num">②</span> <span data-i18n-key="admin.effect.block_payout"></span>';
        return (
            '<div class="studio-card studio-effect-block">' +
            '<div class="studio-card-title">' +
            titleHtml +
            '</div>' +
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

    function renderTimelineCard(sec, sceneKey, idleStudioNav) {
        var est = estimateTimelineSec(sec, sceneKey, idleStudioNav);
        var subKey = idleStudioNav ? 'admin.effect.timeline_sub_idle' : 'admin.effect.timeline_sub';
        return (
            '<div class="studio-card studio-card--timeline">' +
            '<div class="studio-card-title"><span data-i18n-key="admin.effect.timeline">タイムライン</span></div>' +
            '<p class="studio-timeline-body"><span data-i18n-key="admin.effect.timeline_estimate_label">概算合計</span>　<strong id="effect-timeline-val">' +
            est +
            '</strong> <span data-i18n-key="admin.effect.timeline_sec">秒</span> <span class="studio-timeline-sub" data-i18n-key="' +
            subKey +
            '">' +
            (idleStudioNav ? '（カットイン表示時間の目安）' : '（①〜③の表示時間の目安）') +
            '</span></p>' +
            '</div>'
        );
    }

    function renderMasterTab() {
        var m = workspace.master;
        var ok = masterSumOk(m);
        var sumNum = (Number(m.normal.win) + Number(m.normal.bonus) + Number(m.normal.miss_tease)).toFixed(1);
        var sumText = '合計 ' + sumNum + '%' + (ok ? ' ✓' : '');
        var titleStatusClass = 'studio-card-title-status' + (ok ? '' : ' is-error');

        var html = '<div class="studio-editor-sheet studio-editor-sheet--master"><div class="studio-section studio-master-wrap">';
        html +=
            '<h3 class="studio-page-title" data-i18n-key="admin.master.title">' +
            escapeHtml('全体確率設定') +
            '</h3>';

        html += '<div class="studio-master-grid">';
        html += '<div class="studio-card studio-card--master-tree">';
        html += '<div class="studio-card-title">';
        html += '<span data-i18n-key="admin.master.normal_section">通常スピン時の抽選（ツリー・合計100%）</span>';
        html +=
            '<span id="master-sum-val" class="' +
            titleStatusClass +
            '">' +
            escapeHtml(sumText) +
            '</span>';
        html += '</div>';
        html +=
            '<p class="studio-note studio-master-tree-intro" data-i18n-key="admin.master.tree_intro_note">' +
            escapeHtml(
                '「通常」「当たり」「ボーナス入口」が合計100%。ボーナス入口のあと、単発／連続／ビッグを抽選内で振り分けます（例：入口10%・連続20%・ビッグ10%なら、実効はそれぞれ約7%・2%・1%）。'
            ) +
            '</p>';

        var jst0 = (Number(m.normal.bonus) * Number(m.bonus_promote.streak)) / 100;
        var jbg0 = (Number(m.normal.bonus) * Number(m.bonus_promote.big)) / 100;

        html += rowMasterMissReadonly(m.normal.miss_tease, '通常', {
            glyph: '－',
            labelKey: 'admin.master.tree_miss',
        });
        html += rowMaster('win', '当たり', m.normal.win, {
            glyph: '┃',
            labelKey: 'admin.master.tree_win',
        });
        html += rowMaster('bonus', 'ボーナス入口（フリースピン獲得）', m.normal.bonus, {
            glyph: '┃',
            labelKey: 'admin.master.tree_bonus_gate',
        });

        html += '<div class="studio-master-tree-branch">';
        html +=
            '<p class="studio-note studio-master-tree-branch-hint" data-i18n-key="admin.master.tree_branch_hint">' +
            escapeHtml('▼ ボーナス当選後の振り分け（抽選内で合計100%。右の確率は「ボーナス入口×各行」の実効）') +
            '</p>';
        html += renderPlainBonusChildRow(m);
        html += rowPromoteBonusChild(
            'streak',
            '連続ボーナス（昇格）',
            m.bonus_promote.streak,
            jst0,
            {
                glyph: '├─',
                labelKey: 'admin.master.tree_streak',
            }
        );
        html += rowPromoteBonusChild(
            'big',
            'ビッグボーナス（昇格）',
            m.bonus_promote.big,
            jbg0,
            {
                glyph: '└─',
                labelKey: 'admin.master.tree_big',
            }
        );

        html += '<div class="studio-master-tree-params">';
        html +=
            '<div class="studio-master-tree-params-title" data-i18n-key="admin.master.tree_params_title">' +
            escapeHtml('昇格パラメータ') +
            '</div>';
        html += '<div class="studio-row">';
        html +=
            '<div class="studio-row-label" data-i18n-key="admin.master.max_streak_label">最大連続回数（1〜9回ランダム）</div>';
        html += '<div class="studio-row-control">';
        html +=
            '<input type="number" min="1" max="9" id="mx-str" value="' +
            escapeHtml(String(m.bonus_promote.max_streak)) +
            '">';
        html += ' <span class="studio-row-hint">(1〜9)</span>';
        html += '</div></div>';
        html += '<div class="studio-row">';
        html +=
            '<div class="studio-row-label" data-i18n-key="admin.master.big_mul_label">ビッグ時フリースピン倍率（例：10＝通常の10倍）</div>';
        html += '<div class="studio-row-control">';
        html +=
            '<input type="number" min="2" max="20" id="big-mul" value="' +
            escapeHtml(String(m.bonus_promote.big_multiplier)) +
            '">';
        html += ' <span class="studio-row-hint">(2〜20)</span>';
        html += '</div></div>';
        html += '</div>';

        html += '<div class="studio-card-actions studio-card-actions--end">';
        html +=
            '<button type="button" class="studio-btn-secondary" id="master-norm-go" data-i18n-key="admin.master.auto_normalize">自動正規化</button>';
        html += '</div>';
        html += '</div>';
        html += '</div>';

        html += '<div class="studio-card">';
        html += '<div class="studio-card-title">';
        html += '<span data-i18n-key="admin.master.cooldown_section">クールタイム</span>';
        html += '</div>';
        html +=
            '<p class="studio-note studio-card-note" data-i18n-key="admin.master.cooldown_note">ボーナス終了後、通常スピンN回まで全抽選を通常演出に置き換え</p>';
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
        html +=
            '<div id="sim-result-body" class="sim-result-body" data-i18n-key="admin.master.sim_result_placeholder"></div>';
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
                applyMasterNormalValue(k, this.value);
            });
        }
        var nudges = document.querySelectorAll('.js-master-nudge');
        for (var ni = 0; ni < nudges.length; ni++) {
            nudges[ni].addEventListener('click', function () {
                var k = this.getAttribute('data-k');
                var delta = Number(this.getAttribute('data-delta'));
                if (!k || isNaN(delta)) {
                    return;
                }
                applyMasterNormalValue(k, Number(workspace.master.normal[k]) + delta);
            });
        }
        var pr = document.querySelectorAll('.pr-sl');
        for (var j = 0; j < pr.length; j++) {
            pr[j].addEventListener('input', function () {
                var pk = this.getAttribute('data-pk');
                applyPromoteValue(pk, this.value);
            });
        }
        var pn = document.querySelectorAll('.js-promote-nudge');
        for (var pj = 0; pj < pn.length; pj++) {
            pn[pj].addEventListener('click', function () {
                var pk = this.getAttribute('data-pk');
                var delta = Number(this.getAttribute('data-delta'));
                if (!pk || isNaN(delta)) {
                    return;
                }
                applyPromoteValue(pk, Number(workspace.master.bonus_promote[pk]) + delta);
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
        var ng = $('master-norm-go');
        if (ng) {
            ng.addEventListener('click', normalizeMaster);
        }
        var sr = $('sim-run');
        if (sr) {
            sr.addEventListener('click', runSimulationClick);
        }
        refreshMasterJointLabels();
    }

    /** FiveM NUI では window.prompt がフリーズしやすいためモーダルを使う */
    function openPresetNameModal(defaultName, onDone) {
        var modal = $('preset-new-name-modal');
        var inp = $('preset-new-name-input');
        var okBtn = $('preset-new-name-ok');
        var cancelBtn = $('preset-new-name-cancel');
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
            '<p class="studio-note studio-preview-hint" data-i18n-key="admin.preview.preset_hint">' +
            'プリセットの選択・保存は「全体確率設定」タブのヘッダーから行ってください。' +
            '</p>' +
            '<div id="admin-slot-embed" class="admin-slot-embed"></div>' +
            '<p class="studio-note studio-preview-hint" data-i18n-key="admin.preview.embed_hint"></p>' +
            '</div>'
        );
    }

    /**
     * プレビュータブ: サーバーでプレビューモードを有効化 → #root を埋め込みホストへ移してから embedSlotInit
     * （init が先に届きスケルトン状態のまま固まるレースを避ける）
     */
    function activatePreviewTab() {
        var host = $('admin-slot-embed');
        if (!host) {
            if (typeof console !== 'undefined' && console.warn) {
                console.warn('[admin] admin-slot-embed host missing');
            }
            return;
        }
        function dbg(level, msg) {
            if (typeof window.jpSlotNuiLog === 'function') {
                window.jpSlotNuiLog(level, msg);
            } else if (typeof console !== 'undefined' && console.log) {
                console.log(msg);
            }
        }
        dbg('log', '[admin] preview tab activated, previewStart then embed after DOM mount');
        fetchNui('admin/previewStart', {})
            .then(function (r0) {
                if (r0 && r0.ok === false) {
                    throw new Error('previewStart');
                }
                window.requestAnimationFrame(function () {
                    var h = $('admin-slot-embed');
                    if (!h) {
                        dbg('warn', '[admin] admin-slot-embed missing after rAF');
                        return;
                    }
                    if (typeof window.jpSlotMoveRootToEmbed === 'function') {
                        window.jpSlotMoveRootToEmbed(h);
                    }
                    fetchNui('admin/embedSlotInit', embedSlotInitOpts())
                        .then(function (r1) {
                            dbg('log', '[admin] embedSlotInit fetch result: ' + JSON.stringify(r1 || {}));
                            if (r1 && r1.ok === false) {
                                throw new Error('embedInit');
                            }
                            if (typeof window.fitAdminEmbedScale === 'function') {
                                window.fitAdminEmbedScale();
                            }
                            window.setTimeout(function () {
                                if (typeof window.fitAdminEmbedScale === 'function') {
                                    window.fitAdminEmbedScale();
                                }
                            }, 50);
                        })
                        .catch(function () {
                            showAdminToast('プレビューの開始に失敗しました（認証・通信を確認）', true);
                        });
                });
            })
            .catch(function () {
                showAdminToast('プレビューの開始に失敗しました（認証・通信を確認）', true);
            });
    }

    function wirePreviewTab() {
        activatePreviewTab();
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

    /** シミュレーション結果を読みやすい表 HTML に整形（モンテカルロ・近似） */
    function buildSimulationResultTableHtml(res, trials, rtp) {
        function fmt(n) {
            return String(Math.round(Number(n) || 0));
        }
        return (
            '<table class="sim-result-table">' +
            '<tbody>' +
            '<tr><th scope="row">試行回数</th><td>' +
            fmt(trials) +
            ' 回</td></tr>' +
            '<tr><th scope="row">通常</th><td>' +
            fmt(res.miss_tease) +
            ' 回</td></tr>' +
            '<tr><th scope="row">当たり</th><td>' +
            fmt(res.win) +
            ' 回</td></tr>' +
            '<tr><th scope="row">ボーナス入口</th><td>' +
            fmt(res.bonus) +
            ' 回</td></tr>' +
            '<tr><th scope="row">　└ 単発（昇格なし）</th><td>' +
            fmt(res.bonus_single) +
            ' 回</td></tr>' +
            '<tr><th scope="row">　└ 連続昇格</th><td>' +
            fmt(res.bonus_streak) +
            ' 回</td></tr>' +
            '<tr><th scope="row">　└ ビッグ昇格</th><td>' +
            fmt(res.bonus_big) +
            ' 回</td></tr>' +
            '<tr><th scope="row">クールタイム中スピン</th><td>' +
            fmt(res.cooldown_blocked) +
            ' 回</td></tr>' +
            '<tr><th scope="row">連続記録（最大）</th><td>' +
            fmt(res.max_streak) +
            ' 回</td></tr>' +
            '<tr><th scope="row">RTP（参考）</th><td>' +
            rtp.toFixed(2) +
            '%</td></tr>' +
            '<tr><th scope="row">総ベット／総払戻</th><td>' +
            fmt(res.total_bet) +
            ' ／ ' +
            fmt(res.total_payout) +
            '</td></tr>' +
            '</tbody></table>' +
            '<p class="sim-result-note">※ 簡易モデルによる近似です。実機・サーバー RNG と完全一致しません。</p>'
        );
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
        var body = $('sim-result-body');
        if (body) {
            body.removeAttribute('data-i18n-key');
            body.innerHTML = buildSimulationResultTableHtml(res, trials, rtp);
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
    }

    function wireIdleSubmodeBar() {
        var root = $('admin-center');
        if (!root) {
            return;
        }
        root.querySelectorAll('[data-idle-sub]').forEach(function (btn) {
            btn.addEventListener('click', function () {
                var m = btn.getAttribute('data-idle-sub');
                if (m !== 'idle' && m !== 'miss_tease') {
                    return;
                }
                idleEffectMode = m;
                renderCenter();
            });
        });
    }

    function renderEffectTab(key, idleSubBar) {
        var sec = workspace.effects[key] || defaultEffectSection();
        workspace.effects[key] = sec;

        var html = '<div class="studio-editor-sheet"><div class="studio-section studio-effect-wrap">';
        if (idleSubBar) {
            html +=
                '<div class="studio-idle-subbar" role="tablist">' +
                '<button type="button" role="tab" class="studio-idle-subbtn' +
                (key === 'idle' ? ' is-active' : '') +
                '" data-idle-sub="idle" data-i18n-key="admin.nav.idle_sub_idle">Idle</button>' +
                '<button type="button" role="tab" class="studio-idle-subbtn' +
                (key === 'miss_tease' ? ' is-active' : '') +
                '" data-idle-sub="miss_tease" data-i18n-key="admin.nav.idle_sub_result">通常結果</button>' +
                '</div>';
        }
        var titleKey = sceneTitleI18n(key);
        html +=
            '<h3 class="studio-page-title"' +
            (titleKey ? ' data-i18n-key="' + titleKey + '"' : '') +
            '>' +
            escapeHtml(key) +
            '</h3>';
        html +=
            '<p class="studio-note studio-effect-intro" data-i18n-key="' +
            (idleSubBar ? 'admin.effect.intro_idle' : 'admin.effect.intro_compact') +
            '">' +
            (idleSubBar
                ? '左：キャラとプレビュー／右：BGMと再生時間（SE・ボイスは詳細）。プリセット保存で反映されます。'
                : '左：カットインとプレビュー／中央：テキスト→配当→リール枠／右：BGMと再生時間（SE・ボイスは詳細）。プリセット保存で反映されます。') +
            '</p>';

        html +=
            '<div class="studio-effect-flow' +
            (idleSubBar ? ' studio-effect-flow--idle-only' : '') +
            '">';
        html += '<div class="studio-effect-col studio-effect-col-left">';
        html += renderLeftEffectColumn(key, sec);
        html += '</div>';
        if (!idleSubBar) {
            html += '<div class="studio-effect-col studio-effect-col-center">';
            html += renderTextBlockCard('①', 'admin.effect.block_pre_text', 'pre_text', sec.pre_text, true, false);
            html += renderPayoutCard(sec.payout, key);
            html += renderReelFxCard(sec.reel_fx);
            html += '</div>';
        }
        html += '<div class="studio-effect-col studio-effect-col-right">';
        html += renderSoundRightColumn(sec.sound);
        html += '</div>';
        html += '</div>';

        if (key === 'bonus_streak') {
            html += '<div class="studio-effect-full-width">' + renderBonusStreakNote() + '</div>';
        } else if (key === 'bonus_big') {
            html += '<div class="studio-effect-full-width">' + renderBonusBigNote() + '</div>';
        }

        html += '<div class="studio-effect-timeline-wrap">';
        html += renderTimelineCard(sec, key, idleSubBar);
        html += '</div>';

        html += '</div></div>';
        return html;
    }

    /** Idle／通常結果は左縦長（キャラ）。それ以外はカットイン優先でプレビュー */
    function isVerticalStripScene(sceneKey) {
        return sceneKey === 'idle' || sceneKey === 'miss_tease';
    }

    function refreshEffectAssetPreview(sceneKey) {
        var wrap = $('studio-effect-asset-preview');
        if (!wrap) {
            return;
        }
        var sec = workspace.effects[sceneKey];
        if (!sec) {
            return;
        }
        var cv = sec.char_video || {};
        var cb = sec.cutin_block || {};
        var charPath = (cv.enabled !== false && cv.file && String(cv.file).trim()) ? String(cv.file).trim() : '';
        var cutPath = (cb.file && String(cb.file).trim()) ? String(cb.file).trim() : '';
        var path = '';
        if (isVerticalStripScene(sceneKey)) {
            path = charPath;
        } else if (cutPath) {
            path = cutPath;
        } else {
            path = charPath;
        }
        function studioCharacterBasePrefix() {
            var cid = (workspace && workspace.characterId) || 'luna';
            return 'characters/' + cid + '/';
        }
        function assetUrl(rel) {
            var r = String(rel || '').trim().replace(/^\/+/, '').replace(/\\/g, '/');
            if (!r) {
                return '';
            }
            if (/^(characters\/|symbols\/|frames\/|shared\/)/.test(r)) {
                return 'nui://' + RES + '/html/assets/' + r;
            }
            return 'nui://' + RES + '/html/assets/' + studioCharacterBasePrefix() + r;
        }
        wrap.innerHTML = '';
        if (!path) {
            wrap.innerHTML =
                '<span class="studio-effect-preview-placeholder">ファイルを入力すると表示されます</span>';
            return;
        }
        var lower = path.toLowerCase();
        var url = assetUrl(path);
        if (/\.(webm|mp4|ogg)(\?.*)?$/i.test(lower)) {
            var stage = document.createElement('div');
            stage.className = 'studio-effect-preview-video-stage';
            stage.setAttribute(
                'title',
                'アルファ付きWebMは透明部が背景と同化するため、チェッカーで表示しています'
            );
            var v = document.createElement('video');
            v.setAttribute('class', 'studio-effect-preview-media');
            v.setAttribute('preload', 'auto');
            v.setAttribute('playsinline', '');
            v.controls = true;
            v.muted = true;
            v.playsInline = true;
            v.setAttribute('aria-label', 'プレビュー動画');
            v.src = url;
            v.addEventListener('error', function () {
                wrap.innerHTML =
                    '<span class="studio-effect-preview-err">動画を読み込めません（パス・コーデック・ファイルを確認）</span>';
            });
            stage.appendChild(v);
            wrap.appendChild(stage);
            return;
        }
        var im = document.createElement('img');
        im.className = 'studio-effect-preview-media';
        im.decoding = 'async';
        im.loading = 'eager';
        im.src = url;
        im.alt = '';
        im.onerror = function () {
            wrap.innerHTML =
                '<span class="studio-effect-preview-err">読み込み失敗（パス・種別・拡張子を確認）</span>';
        };
        wrap.appendChild(im);
    }

    function wireEffectTab(key, idleStudioNav) {
        var root = $('admin-center');
        if (!root) {
            return;
        }

        function refreshTimeline() {
            var tl = $('effect-timeline-val');
            if (tl && workspace.effects[key]) {
                tl.textContent = estimateTimelineSec(workspace.effects[key], key, idleStudioNav);
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
                    } else if (path === 'sound.bgm_duration_ms') {
                        var bv = Number(el.value);
                        disp.textContent = bv <= 0 ? 'フル' : Math.round(bv) + ' ms';
                    } else {
                        disp.textContent = Math.round(Number(el.value)) + ' ms';
                    }
                }
            }
            if (
                path === 'char_video.file' ||
                path === 'cutin_block.file' ||
                path === 'cutin_block.kind' ||
                path === 'char_video.enabled'
            ) {
                refreshEffectAssetPreview(key);
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
        refreshEffectAssetPreview(key);
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
                if (selectedKey === 'idle') {
                    idleEffectMode = 'idle';
                }
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

    /** html/assets スキャン結果を datalist に反映（カットイン・キャラ・SE 等の入力補助） */
    function ensureAssetDatalists() {
        var panel = $('panel-admin');
        if (!panel) {
            return;
        }
        var root = $('jp-slot-asset-datalists');
        if (!root) {
            root = document.createElement('div');
            root.id = 'jp-slot-asset-datalists';
            root.setAttribute('hidden', '');
            root.setAttribute('aria-hidden', 'true');
            panel.appendChild(root);
        }
        var lib = window.__jpSlotAssetLib || {};
        function opts(arr) {
            var h = '';
            var a = arr || [];
            var i;
            for (i = 0; i < a.length; i++) {
                h += '<option value="' + escapeHtml(a[i]) + '">';
            }
            return h;
        }
        root.innerHTML =
            '<datalist id="jp-slot-dl-cutins">' +
            opts(lib.cutins) +
            '</datalist>' +
            '<datalist id="jp-slot-dl-characters">' +
            opts(lib.characters) +
            '</datalist>' +
            '<datalist id="jp-slot-dl-se">' +
            opts(lib.se) +
            '</datalist>' +
            '<datalist id="jp-slot-dl-voice">' +
            opts(lib.voice) +
            '</datalist>' +
            '<datalist id="jp-slot-dl-bgm">' +
            opts(lib.bgm) +
            '</datalist>';
    }

    function renderCenter() {
        var c = $('admin-center');
        if (!c) {
            return;
        }
        try {
            ensureAssetDatalists();
            /* admin-center を innerHTML で潰す前に #root を埋め込みから外す（破棄・取り残し防止） */
            var rootDetach = document.getElementById('root');
            var fitEl = document.getElementById('jp-slot-embed-fit');
            if (
                rootDetach &&
                fitEl &&
                fitEl.contains(rootDetach) &&
                typeof window.jpSlotMoveRootToBody === 'function'
            ) {
                window.jpSlotMoveRootToBody();
            }
            var prev = window.__jpSlotPrevViewMode;
            var curr = viewMode;
            if (prev === 'preview' && curr !== 'preview') {
                if (typeof window.jpSlotMoveRootToBody === 'function') {
                    window.jpSlotMoveRootToBody();
                }
                if (typeof window.jpSlotRemovePreviewBadge === 'function') {
                    window.jpSlotRemovePreviewBadge();
                }
                fetchNui('admin/previewEnd', {}).then(function (r) {
                    if (!r || r.ok === false) {
                        showAdminToast('プレビュー終了の同期に失敗しました（再読込で解除されます）', true);
                    }
                });
            }
            window.__jpSlotPrevViewMode = curr;

            if (curr === 'preview') {
                c.innerHTML = renderPresetBarHtml() + renderPreviewTab();
                hydratePresetHeaderUi();
                wirePresetBar();
                wirePreviewTab();
            } else if (curr === 'master') {
                c.innerHTML = renderPresetBarHtml() + renderMasterTab();
                wirePresetBar();
                wireMaster();
                hydratePresetHeaderUi();
            } else if (curr === 'legacy') {
                c.innerHTML = legacyHtml();
                if (window.__jpSlotAdminLegacyBind) {
                    window.__jpSlotAdminLegacyBind();
                }
            } else {
                var effectKey = selectedKey === 'idle' ? idleEffectMode : selectedKey;
                c.innerHTML = renderEffectTab(effectKey, selectedKey === 'idle');
                wireEffectTab(effectKey, selectedKey === 'idle');
                if (selectedKey === 'idle') {
                    wireIdleSubmodeBar();
                }
            }
            if (window.jpSlotApplyI18n) {
                window.jpSlotApplyI18n();
            }
            updateBreadcrumbPreset();
        } catch (err) {
            console.error('[jp-slot studio] renderCenter', err);
            showAdminToast('画面の表示でエラーが発生しました', true);
        }
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
        var cid = (workspace && workspace.characterId) || 'luna';
        fetchNui('admin/assets/scan', { characterId: cid, kind: 'all' }).then(
            function (r) {
                if (r.ok && r.assets) {
                    window.__jpSlotAssetLib = r.assets;
                }
                ensureAssetDatalists();
            }
        );
    }

    function onOpenAdmin(_payload) {
        workspace = createDefaultWorkspace();
        selectedKey = 'master';
        viewMode = 'master';
        window.__jpSlotPrevViewMode = undefined;
        selectedCharacterId = 'luna';
        selectedPresetName = 'default';
        loadedCharacterId = 'luna';
        loadedPresetName = 'default';
        suppressAutosave = true;
        buildLeftNav();
        buildRight();
        fetchNui('admin/assets/scan', { characterId: workspace.characterId || 'luna', kind: 'all' })
            .then(function (ares) {
                if (ares && ares.ok && ares.assets) {
                    window.__jpSlotAssetLib = ares.assets;
                }
                ensureAssetDatalists();
                return fetchNui('admin/characters/list', {});
            })
            .then(function (cr) {
                window.__jpSlotAdminCharacters = cr && cr.ok && cr.list ? cr.list : [];
                ensureAdminCharacterListFallback();
                var chars = window.__jpSlotAdminCharacters;
                var ac = cr && cr.activeCharacterId;
                var ap = cr && cr.activePresetName;
                var cid = ac || (chars[0] && chars[0].id) || 'luna';
                selectedCharacterId = cid;
                workspace.characterId = cid;
                return fetchNui('admin/preset/listByCharacter', { characterId: cid }).then(function (lr) {
                    return { ap: ap, lr: lr };
                });
            })
            .then(function (pack) {
                var lr = pack.lr;
                var ap = pack.ap;
                var plist = lr && lr.ok && lr.list ? lr.list : [];
                var names = [];
                var i;
                for (i = 0; i < plist.length; i++) {
                    if (plist[i] && plist[i].name) {
                        names.push(plist[i].name);
                    }
                }
                var pick = ap && names.indexOf(ap) >= 0 ? ap : names[0];
                if (!pick) {
                    selectedPresetName = null;
                    loadedPresetName = null;
                    suppressAutosave = false;
                    workspace.dirty = false;
                    renderCenter();
                    if (window.jpSlotApplyI18n) {
                        window.jpSlotApplyI18n();
                    }
                    updateBreadcrumbPreset();
                    return Promise.resolve(null);
                }
                selectedPresetName = pick;
                return fetchNui('admin/preset/get', {
                    characterId: selectedCharacterId,
                    presetName: pick,
                });
            })
            .then(function (r) {
                if (r === null) {
                    return;
                }
                if (r && r.ok && r.data) {
                    mergePresetWorkspace(r.data);
                    loadedCharacterId = selectedCharacterId;
                    loadedPresetName = selectedPresetName;
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
                ensureAssetDatalists();
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
