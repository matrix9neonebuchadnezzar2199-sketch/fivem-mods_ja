/* global window, document, fetch, GetParentResourceName */
(function jpSlotBootStamp() {
    var rn = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'jp-slot';
    try {
        fetch('https://' + rn + '/clientLog', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({
                level: 'log',
                message: '[BOOT] app.js evaluate start ' + new Date().toISOString(),
            }),
        }).catch(function () {});
    } catch (_) {}
})();

(function () {
    window.addEventListener('error', function (e) {
        try {
            var msg =
                (e && e.message ? e.message : 'error') +
                ' at ' +
                (e && e.filename ? e.filename : '?') +
                ':' +
                (e && e.lineno ? e.lineno : '?');
            fetch(
                'https://' + resourceName() + '/clientLog',
                {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                    body: JSON.stringify({ level: 'error', message: msg }),
                }
            ).catch(function () {});
        } catch (_) {}
    });

    function resourceName() {
        if (typeof GetParentResourceName === 'function') {
            return GetParentResourceName();
        }
        return 'jp-slot';
    }

    /** NUI 診断ログ（F8 client コンソールへ） */
    function nuiLog(level, msg) {
        fetch('https://' + resourceName() + '/clientLog', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({ level: level || 'log', message: String(msg || '') }),
        }).catch(function () {});
    }

    window.jpSlotNuiLog = nuiLog;

    /**
     * スロットパネル寸法（--ui-width / --ui-height / --ui-max-width）
     * @param {object} size widthPercent heightPercent maxWidthPx
     */
    function applyUISize(size) {
        if (!size) {
            return;
        }
        var root = document.documentElement;
        var w = Math.max(30, Math.min(100, Number(size.widthPercent) || 90));
        var h = Math.max(30, Math.min(100, Number(size.heightPercent) || 90));
        var mx = Math.max(0, Number(size.maxWidthPx) || 0);
        root.style.setProperty('--ui-width', w + 'vw');
        root.style.setProperty('--ui-height', h + 'vh');
        root.style.setProperty('--ui-max-width', mx > 0 ? mx + 'px' : 'none');
        if (window.__jpSlotEmbedPreview && typeof window.applyEmbedPreviewFit === 'function') {
            window.applyEmbedPreviewFit();
        }
    }

    window.applyUISize = applyUISize;

    function disconnectEmbedPreviewResize() {
        if (window.__jpSlotEmbedRo) {
            try {
                window.__jpSlotEmbedRo.disconnect();
            } catch (_) {}
            window.__jpSlotEmbedRo = null;
        }
        if (window.__jpSlotEmbedWinResize) {
            window.removeEventListener('resize', window.__jpSlotEmbedWinResize);
            window.__jpSlotEmbedWinResize = null;
        }
    }

    function bindEmbedPreviewResize() {
        disconnectEmbedPreviewResize();
        var host = document.getElementById('admin-slot-embed');
        if (!host) {
            return;
        }
        function onResize() {
            if (typeof window.applyEmbedPreviewFit === 'function') {
                window.applyEmbedPreviewFit();
            }
        }
        window.__jpSlotEmbedWinResize = onResize;
        window.addEventListener('resize', onResize);
        if (typeof ResizeObserver !== 'undefined') {
            window.__jpSlotEmbedRo = new ResizeObserver(onResize);
            window.__jpSlotEmbedRo.observe(host);
        }
    }

    /**
     * 管理プレビュー: #root のレイアウトを 1280×720 の論理ピクセルで固定し、枠に収まるよう scale（transform は描画のみなので先に「実寸」を確保する）
     */
    window.applyEmbedPreviewFit = function () {
        var frame = document.getElementById('admin-slot-embed');
        var inner = document.getElementById('jp-slot-embed-fit');
        var rootEl = document.getElementById('root');
        if (!frame || !inner || !rootEl || !inner.contains(rootEl)) {
            return;
        }
        inner.style.width = '1280px';
        inner.style.height = '720px';
        inner.style.position = 'absolute';
        inner.style.top = '0';
        inner.style.transformOrigin = 'top left';
        inner.style.pointerEvents = 'none';
        var baseW = 1280;
        var baseH = 720;
        var fw = frame.clientWidth;
        var fh = frame.clientHeight;
        nuiLog('log', '[embed] frame=' + (frame.id || frame.tagName) + ' size=' + fw + 'x' + fh);
        if (fw <= 4 || fh <= 4) {
            return;
        }
        var scale = Math.min(fw / baseW, fh / baseH, 1);
        var offsetX = (fw - baseW * scale) / 2;
        inner.style.left = offsetX + 'px';
        inner.style.transform = 'scale(' + scale + ')';
        if (window.jpSlotNuiLog) {
            window.jpSlotNuiLog(
                'log',
                '[embed] fit applied: frame=' +
                    fw +
                    'x' +
                    fh +
                    ' scale=' +
                    scale.toFixed(3) +
                    ' offsetX=' +
                    offsetX.toFixed(0)
            );
        }
    };

    window.jpSlotFitAdminEmbedScale = window.applyEmbedPreviewFit;
    window.fitAdminEmbedScale = window.applyEmbedPreviewFit;

    window.jpSlotBindEmbedPreviewResize = bindEmbedPreviewResize;
    window.jpSlotDisconnectEmbedPreviewResize = disconnectEmbedPreviewResize;

    var state = {
        machine: null,
        balance: 0,
        bet: 100,
        jackpot: 0,
        spinDuration: 2500,
        assetsRoot: '',
        locales: {},
        spinning: false,
        paytable: null,
        /** サーバー確定の UI サイズ（管理画面を閉じたときにプレビューを戻す） */
        serverUiSize: null,
        /** pushInit の debug（verbose 表示の判定に使用可能） */
        debug: null,
        /** サーバー FS 残り（>0 でベット不要スピン可） */
        bonusRemaining: 0,
        marquee: { hype: [], info: [] },
        symbolIds: null,
        /** サーバーから読んだ manifest.json 相当 */
        character: null,
        /** html/assets/ からのキャラサブパス（例: characters/luna/） */
        characterBasePath: '',
        /** プリセット優先後の実効キャラ ID（machine.characterId は変更しない） */
        effectiveCharacterId: '',
        /** サーバーから渡る演出プリセット effects（leftStage 等） */
        effects: null,
        /** 左側2スロット交互表示用インデックス（スピン毎に %2 で進む） */
        leftStageSlotIndex: 0,
    };

    window.__jpSlotSpinning = false;

    /**
     * プリセット・manifest の相対パスを nui URL にする（キャラルート基準。legacy の characters/... も可）
     * @param {string} rel
     * @param {string} [assetsRootOpt]
     */
    function jpSlotResolveAssetUrl(rel, assetsRootOpt) {
        var root = assetsRootOpt || state.assetsRoot || window.__jpSlotAssetsRoot || '';
        var r = String(rel || '')
            .trim()
            .replace(/^\/+/, '')
            .replace(/\\/g, '/');
        if (!r) {
            return '';
        }
        if (/^(symbols\/|frames\/|shared\/)/.test(r)) {
            return root + r;
        }
        if (/^characters\//.test(r)) {
            return root + r;
        }
        var base = state.characterBasePath || '';
        if (!base && state.effectiveCharacterId) {
            base = 'characters/' + state.effectiveCharacterId + '/';
        }
        if (!base && state.machine && state.machine.characterId) {
            base = 'characters/' + state.machine.characterId + '/';
        }
        if (!base) {
            base = 'characters/luna/';
        }
        if (base.slice(-1) !== '/') {
            base += '/';
        }
        return root + base + r;
    }
    window.jpSlotResolveAssetUrl = jpSlotResolveAssetUrl;

    function pickLeftStageForResult(p) {
        p = p || {};
        var tabKey = p.effectScene || 'idle';
        var eff = state.effects && state.effects[tabKey];
        var tabConfig = eff && eff.leftStage;
        var slots = (tabConfig && tabConfig.slots) || [];
        var enabledSlots = [];
        for (var i = 0; i < slots.length; i++) {
            var s = slots[i];
            if (s && s.enabled && String(s.file || '').trim() !== '') {
                enabledSlots.push(s);
            }
        }
        if (enabledSlots.length === 0) {
            if (tabKey !== 'idle') {
                nuiLog('log', '[leftStage] fallback from tab=' + tabKey + ' to idle (no enabled slots)');
                return pickLeftStageForResult({ effectScene: 'idle' });
            }
            return { tabKey: tabKey, slots: [] };
        }
        return { tabKey: tabKey, slots: enabledSlots };
    }

    function playLeftStageSlot(slot, tabKey, idx, assetsRoot) {
        if (!slot || !String(slot.file || '').trim()) {
            return;
        }
        var ar = assetsRoot || state.assetsRoot || '';
        var url = jpSlotResolveAssetUrl(slot.file, ar);
        nuiLog(
            'log',
            '[leftStage] play tab=' +
                tabKey +
                ' slotIdx=' +
                idx +
                ' kind=' +
                (slot.kind || '') +
                ' file=' +
                slot.file
        );
        var charPortrait =
            document.querySelector('.char-img.char-portrait') ||
            document.querySelector('.char-portrait');
        var charVideo = document.querySelector('.char-video');
        if (!charPortrait || !charVideo) {
            return;
        }
        var isVideo =
            slot.kind === 'video' || /\.(mp4|webm|mov|m4v)$/i.test(String(slot.file || ''));
        if (slot.fadeIn !== false) {
            charPortrait.classList.remove('is-fading-out');
            charPortrait.classList.add('is-returning');
            window.setTimeout(function () {
                charPortrait.classList.remove('is-returning');
            }, 50);
        }
        if (isVideo) {
            charPortrait.hidden = true;
            charPortrait.removeAttribute('src');
            var v = charVideo;
            v.muted = true;
            v.playsInline = true;
            try {
                v.setAttribute('playsinline', '');
            } catch (_) {}
            v.autoplay = true;
            v.loop = slot.loop !== false;
            v.src = url;
            v.classList.add('is-playing');
            var playPromise = v.play();
            if (playPromise && playPromise.catch) {
                playPromise.catch(function (err) {
                    nuiLog(
                        'log',
                        '[leftStage][err] video play failed tab=' +
                            tabKey +
                            ' slotIdx=' +
                            idx +
                            ' file=' +
                            (slot.file || 'null') +
                            ' err=' +
                            (err && err.name ? err.name : String(err))
                    );
                });
            }
            window.setTimeout(function () {
                nuiLog(
                    'log',
                    '[probe-video] tab=' +
                        tabKey +
                        ' slotIdx=' +
                        idx +
                        ' src=' +
                        (v.src || 'null').slice(-60) +
                        ' paused=' +
                        v.paused +
                        ' rs=' +
                        v.readyState +
                        ' muted=' +
                        v.muted +
                        ' w=' +
                        v.videoWidth +
                        'x' +
                        v.videoHeight
                );
            }, 200);
        } else {
            try {
                charVideo.pause();
            } catch (_) {}
            charVideo.removeAttribute('src');
            charVideo.classList.remove('is-playing');
            charPortrait.hidden = false;
            charPortrait.src = url;
        }
    }

    function applyLeftStageForSpinResult(p, assetsRoot) {
        var r = pickLeftStageForResult(p);
        if (!r.slots.length) {
            return;
        }
        var idx = state.leftStageSlotIndex % r.slots.length;
        playLeftStageSlot(r.slots[idx], r.tabKey || (p.effectScene || 'idle'), idx, assetsRoot);
    }

    function playIdleLeftStageFromPreset() {
        var r = pickLeftStageForResult({ effectScene: 'idle' });
        var ar = state.assetsRoot || '';
        if (!r.slots.length) {
            return;
        }
        var idx = state.leftStageSlotIndex % r.slots.length;
        playLeftStageSlot(r.slots[idx], 'idle', idx, ar);
    }

    function shouldSkipWinCharFxForLeftStage(p) {
        if (!state.effects || !p) {
            return false;
        }
        var sc = p.effectScene;
        if (!sc || sc === 'idle' || sc === 'miss_tease') {
            return false;
        }
        var x = pickLeftStageForResult(p);
        return x.slots.length > 0;
    }

    var IDLE_VIDEO_INTERVAL_MS = 5000;
    var IDLE_VIDEO_CHANCE = 0.5;

    function startIdleCharLoop() {
        if (window.__jpSlotIdleLoopStarted) {
            return;
        }
        window.__jpSlotIdleLoopStarted = true;
        window.setInterval(function () {
            var root = document.getElementById('root');
            if (!root || !root.classList.contains('is-visible')) {
                return;
            }
            if (window.__jpSlotSpinning) {
                return;
            }
            if (window.CharFx && window.CharFx.isPlaying && window.CharFx.isPlaying()) {
                return;
            }
            if (Math.random() > IDLE_VIDEO_CHANCE) {
                return;
            }
            if (window.__jpSlotNeutralPreviewChar) {
                return;
            }
            if (state.effects && state.effects.idle && state.effects.idle.leftStage) {
                return;
            }
            if (!(window.CharFx && window.CharFx.play)) {
                return;
            }
            var idleVs =
                state.character &&
                state.character.assets &&
                state.character.assets.idle &&
                state.character.assets.idle.videos;
            var pick = '';
            if (idleVs && idleVs.length) {
                pick = idleVs[Math.floor(Math.random() * idleVs.length)];
            } else {
                var wv =
                    state.character &&
                    state.character.assets &&
                    state.character.assets.win &&
                    state.character.assets.win.video;
                pick = wv || 'win/win.webm';
            }
            var url = jpSlotResolveAssetUrl(pick);
            if (url) {
                window.CharFx.play(url);
            }
        }, IDLE_VIDEO_INTERVAL_MS);
    }

    function clearWinFx() {
        var r = document.querySelector('.reel-frame.reels-container');
        if (!r) {
            return;
        }
        r.classList.remove('is-win', 'is-bigwin');
    }

    function ensureBonusBadge() {
        var el = document.getElementById('bonus-badge');
        if (el) {
            return el;
        }
        el = document.createElement('div');
        el.id = 'bonus-badge';
        el.className = 'bonus-badge';
        document.body.appendChild(el);
        return el;
    }

    function removeBonusBadge() {
        var el = document.getElementById('bonus-badge');
        if (el) {
            el.remove();
        }
    }

    /**
     * フリースピン残数バナー（#bonus-badge）とボーナス UI 状態を強制クリア。
     * 退席・hide メッセージ・ボーナス終了時に呼ぶ（body 直下のため #root の非表示だけでは残る）。
     */
    function hideFreeSpinBanner() {
        removeBonusBadge();
        var root = document.getElementById('root');
        if (root) {
            root.classList.remove('is-bonus');
        }
        state.bonusRemaining = 0;
        window.__jpSlotPrevBonusActive = false;
        var rct = document.getElementById('reel-center-text');
        if (rct) {
            rct.classList.remove('is-show', 'fx-pulse', 'fx-zoom');
            var content = rct.querySelector('.reel-center-text-content');
            if (content) {
                content.textContent = '';
            }
            rct.hidden = true;
        }
        nuiLog('log', '[hideFreeSpinBanner] cleared');
    }

    function flashToast(text) {
        if (!text) {
            return;
        }
        var t = document.createElement('div');
        t.className = 'toast-flash';
        t.textContent = text;
        document.body.appendChild(t);
        window.setTimeout(function () {
            if (t.parentNode) {
                t.remove();
            }
        }, 2200);
    }

    function applyBonusUi(bonus) {
        var root = document.getElementById('root');
        if (!root) {
            return;
        }
        if (!bonus || !bonus.active) {
            hideFreeSpinBanner();
            return;
        }
        if (bonus.ended) {
            var endTpl = resolveLocale('ui.bonus_toast_end');
            var endTxt = (endTpl || 'BONUS END  {amount}').replace(
                '{amount}',
                fmtMoney(bonus.totalWin || 0)
            );
            flashToast(endTxt);
            hideFreeSpinBanner();
            return;
        }
        root.classList.add('is-bonus');
        var badge = ensureBonusBadge();
        var tmpl = resolveLocale('ui.bonus_badge');
        var line =
            (tmpl || 'FREE SPIN  {n}  ×{m}')
                .replace('{n}', String(bonus.remaining != null ? bonus.remaining : '—'))
                .replace('{m}', String(bonus.multiplier != null ? bonus.multiplier : 1));
        badge.textContent = line;
        if (bonus.started) {
            flashToast(resolveLocale('ui.bonus_toast_start') || 'BONUS START!');
        }
        if (bonus.bonusRetrigger && bonus.retriggerAdd) {
            var rt = resolveLocale('ui.bonus_toast_retrigger') || '+{n} FREE SPIN!';
            flashToast(rt.replace('{n}', String(bonus.retriggerAdd)));
        }
    }

    /**
     * @param {object} p spinResult payload
     * @param {string} assetsRoot
     */
    function applyWinFx(p, assetsRoot) {
        var reels = document.querySelector('.reel-frame.reels-container');
        if (!reels) {
            return;
        }
        var tier = p.tier;
        var winAmt = p.winAmount != null ? p.winAmount : 0;
        reels.classList.remove('is-win', 'is-bigwin');
        if (!tier || winAmt <= 0) {
            return;
        }
        if (shouldSkipWinCharFxForLeftStage(p)) {
            reels.classList.add('is-win');
            if (tier === 'bigwin' || tier === 'jackpot') {
                reels.classList.add('is-bigwin');
            }
            window.setTimeout(function () {
                if (reels) {
                    reels.classList.remove('is-win', 'is-bigwin');
                }
            }, 1800);
            return;
        }
        var big = tier === 'bigwin' || tier === 'jackpot';
        if (big) {
            reels.classList.add('is-bigwin');
        }
        reels.classList.add('is-win');
        var winA = state.character && state.character.assets && state.character.assets.win;
        var winRel = winA && winA.video ? winA.video : 'win/win.webm';
        var bigRel = winA && winA.bigwin_video ? winA.bigwin_video : 'win/bigwin.webm';
        var src = big ? jpSlotResolveAssetUrl(bigRel, assetsRoot) : jpSlotResolveAssetUrl(winRel, assetsRoot);
        if (window.CharFx && window.CharFx.play && src) {
            window.CharFx.play(src, { force: true });
        }
        window.setTimeout(function () {
            if (reels) {
                reels.classList.remove('is-win', 'is-bigwin');
            }
        }, 1800);
    }

    function postNui(name, data) {
        return fetch('https://' + resourceName() + '/' + name, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data || {}),
        }).catch(function (err) {
            console.warn('[jp-slot] NUI callback failed:', name, err);
            return Promise.reject(err);
        });
    }

    function hidePlay() {
        showPlay(false);
        hideFreeSpinBanner();
        nuiLog('log', '[hidePlay] is-visible removed');
    }

    function handleExitClick() {
        nuiLog('log', '[exit] handleExitClick start');
        hidePlay();
        postNui('exit', {})
            .then(function (r) {
                var st = r && typeof r.status === 'number' ? r.status : '?';
                nuiLog('log', '[exit] fetch ok status=' + st);
            })
            .catch(function (err) {
                nuiLog('warn', '[exit] fetch error: ' + (err && err.message ? err.message : String(err)));
            });
    }

    function resolveLocale(path) {
        if (!path || !state.locales) {
            return null;
        }
        var parts = path.split('.');
        /* locales/ja.json の admin は "master.title" のようなフラットキー */
        if (parts[0] === 'admin' && parts.length >= 2) {
            var adm = state.locales.admin;
            if (adm && typeof adm === 'object') {
                var adminFlatKey = parts.slice(1).join('.');
                var flatStr = adm[adminFlatKey];
                if (typeof flatStr === 'string') {
                    return flatStr;
                }
            }
        }
        var cur = state.locales;
        for (var i = 0; i < parts.length; i++) {
            if (!cur || typeof cur !== 'object') {
                return null;
            }
            cur = cur[parts[i]];
        }
        return typeof cur === 'string' ? cur : null;
    }

    function applyI18n() {
        var nodes = document.querySelectorAll('[data-i18n-key]');
        for (var i = 0; i < nodes.length; i++) {
            var el = nodes[i];
            var key = el.getAttribute('data-i18n-key');
            var txt = resolveLocale(key);
            if (txt) {
                el.textContent = txt;
            }
        }
        var phNodes = document.querySelectorAll('[data-i18n-placeholder-key]');
        for (var j = 0; j < phNodes.length; j++) {
            var pel = phNodes[j];
            var pk = pel.getAttribute('data-i18n-placeholder-key');
            var ptxt = resolveLocale(pk);
            if (ptxt) {
                pel.setAttribute('placeholder', ptxt);
            }
        }
    }

    function fmtMoney(n) {
        n = Math.floor(Number(n) || 0);
        return '¥' + n.toLocaleString('ja-JP');
    }

    function updateFooter() {
        var bal = document.querySelector('.balance-value');
        var bet = document.querySelector('.bet-value');
        var win = document.querySelector('.win-value');
        if (bal) {
            bal.textContent = fmtMoney(state.balance);
        }
        if (bet) {
            bet.textContent = String(state.bet);
        }
        if (win) {
            win.textContent = fmtMoney(0);
        }
        var jp = document.querySelector('.jackpot-amount');
        if (jp) {
            jp.textContent = fmtMoney(state.jackpot);
        }
    }

    function renderPaytable() {
        var ul = document.querySelector('.paytable-list');
        if (!ul || !state.paytable || !state.paytable.payouts) {
            return;
        }
        ul.innerHTML = '';
        var rows = state.paytable.payouts;
        for (var i = 0; i < rows.length; i++) {
            var li = document.createElement('li');
            var r = rows[i];
            li.textContent = r.combo + ' → ×' + r.multiplier + ' (' + (r.tier || '') + ')';
            ul.appendChild(li);
        }
    }

    function renderMachineName() {
        var el = document.querySelector('.machine-name');
        if (!el || !state.machine) {
            return;
        }
        var key = state.machine.displayName;
        var txt = key ? resolveLocale(key) : null;
        el.textContent = txt || state.machine.id || '';
        var desc = document.querySelector('.machine-description');
        if (desc && state.machine.machineDescriptionLocaleKey) {
            var d = resolveLocale(state.machine.machineDescriptionLocaleKey);
            desc.textContent = d || '';
        }
    }

    function renderCharacterName() {
        var el = document.querySelector('.character-name');
        if (!el || !state.machine) {
            return;
        }
        if (state.character && state.character.displayName) {
            el.textContent = state.character.displayName;
            return;
        }
        var cid = state.machine.characterId || '';
        el.textContent = cid || '';
    }

    function clampBet() {
        var lo = (state.machine && state.machine.minBet) || 100;
        var hi = (state.machine && state.machine.maxBet) || 10000;
        if (state.bet < lo) {
            state.bet = lo;
        }
        if (state.bet > hi) {
            state.bet = hi;
        }
    }

    function getSpinButton() {
        return document.querySelector('.btn-spin') || document.getElementById('btn-spin');
    }

    function handleSpinClick() {
        clearWinFx();
        var spinBtn = getSpinButton();
        if (!spinBtn) {
            nuiLog('warn', '[handleSpinClick] .btn-spin missing');
            return;
        }
        if (state.spinning) {
            return;
        }
        var inFreeSpin = state.bonusRemaining > 0;
        var embedPv = window.__jpSlotEmbedPreview === true;
        if (!inFreeSpin && !embedPv && state.balance < state.bet) {
            nuiLog('log', '[handleSpinClick] balance < bet');
            return;
        }
        state.spinning = true;
        window.__jpSlotSpinning = true;
        spinBtn.disabled = true;
        nuiLog('log', '[handleSpinClick] post spin');
        postNui('spin', {
            bet: state.bet,
            machineId: state.machine && state.machine.id,
            embedPreview: embedPv,
        });
    }

    function bindFooter() {
        nuiLog('log', '[bindFooter] start');
        var down =
            document.querySelector('.bet-down') || document.getElementById('bet-down');
        var up = document.querySelector('.bet-up') || document.getElementById('bet-up');
        var maxBtn =
            document.querySelector('.btn-bet-max') || document.getElementById('btn-bet-max');
        var spinBtn =
            document.querySelector('.btn-spin') || document.getElementById('btn-spin');
        var exitBtn =
            document.querySelector('.btn-exit') || document.getElementById('btn-exit');

        var found = {
            down: !!down,
            up: !!up,
            maxBet: !!maxBtn,
            spin: !!spinBtn,
            exit: !!exitBtn,
        };
        nuiLog('log', '[bindFooter] found: ' + JSON.stringify(found));

        if (!down || !up || !maxBtn || !spinBtn || !exitBtn) {
            nuiLog('warn', '[bindFooter] footer controls missing (partial bind skipped)');
            return;
        }

        down.addEventListener('click', function () {
            nuiLog('log', '[bindFooter] bet-down clicked');
            state.bet -= 100;
            clampBet();
            updateFooter();
        });
        up.addEventListener('click', function () {
            nuiLog('log', '[bindFooter] bet-up clicked');
            state.bet += 100;
            clampBet();
            updateFooter();
        });
        maxBtn.addEventListener('click', function () {
            nuiLog('log', '[bindFooter] max clicked');
            var hi = (state.machine && state.machine.maxBet) || state.bet;
            state.bet = hi;
            clampBet();
            updateFooter();
        });
        spinBtn.addEventListener('click', function (e) {
            nuiLog('log', '[bindFooter] SPIN clicked');
            if (e && e.stopPropagation) {
                e.stopPropagation();
            }
            handleSpinClick();
        });
        exitBtn.addEventListener('click', function (e) {
            nuiLog('log', '[bindFooter] EXIT clicked');
            if (e && e.stopPropagation) {
                e.stopPropagation();
            }
            handleExitClick();
        });
    }

    function showPlay(show) {
        var root = document.getElementById('root');
        var adm = document.getElementById('panel-admin');
        if (root) {
            if (show) {
                root.classList.add('is-visible');
            } else {
                root.classList.remove('is-visible');
            }
        }
        if (adm && show) {
            adm.style.display = 'none';
        }
    }

    /**
     * nui://…/html/assets/ を前提にフレーム・キャラ・リール画像を適用
     * @param {object} payload init と同形
     */
    function applyVisualAssets(payload) {
        var root = (payload && payload.assetsRoot) || '';
        window.__jpSlotAssetsRoot = root;
        var rf = document.querySelector('.reel-frame');
        if (rf) {
            rf.style.backgroundImage = 'none';
        }
        var charImg = document.querySelector('.char-img');
        var machine = payload && payload.machine;
        var manifest = payload && payload.character;
        var portrait =
            manifest &&
            manifest.assets &&
            manifest.assets.idle &&
            manifest.assets.idle.portrait;
        var skipCharVisual =
            payload && payload.embedPreview && payload.neutralPreviewCharacter === true;
        if (skipCharVisual) {
            if (charImg) {
                charImg.hidden = true;
                charImg.removeAttribute('src');
            }
        } else if (charImg && root && portrait) {
            charImg.hidden = false;
            charImg.src = jpSlotResolveAssetUrl(portrait, root);
        } else if (charImg) {
            charImg.hidden = true;
            charImg.removeAttribute('src');
        }
    }

    function initPlay(payload) {
        payload = payload || {};
        state.machine = payload.machine;
        state.theme = payload.theme;
        state.balance = payload.balance || 0;
        state.jackpot = payload.jackpot || 0;
        state.spinDuration = (payload.spinDuration || 2.5) * 1000;
        state.paytable = payload.paytable;
        state.locales = payload.locales || {};
        state.assetsRoot = payload.assetsRoot || '';
        state.marquee = payload.marquee || { hype: [], info: [] };
        state.symbolIds = payload.symbolIds || null;
        state.debug = payload.debug || null;
        state.character = payload.character || null;
        state.effectiveCharacterId =
            (payload.characterId != null && String(payload.characterId)) ||
            (payload.machine && payload.machine.characterId) ||
            'luna';
        state.characterBasePath =
            (payload.characterBasePath != null && String(payload.characterBasePath)) ||
            ('characters/' + state.effectiveCharacterId + '/');
        state.effects = payload.effects || null;
        state.leftStageSlotIndex = 0;
        try {
            var idleLs = state.effects && state.effects.idle && state.effects.idle.leftStage;
            var idleSlots = (idleLs && idleLs.slots) || [];
            var winLs = state.effects && state.effects.win && state.effects.win.leftStage;
            var winSlots = (winLs && winLs.slots) || [];
            nuiLog(
                'log',
                '[probe3] idle.slots[0]=' +
                    JSON.stringify(idleSlots[0] || null) +
                    ' [1]=' +
                    JSON.stringify(idleSlots[1] || null)
            );
            nuiLog(
                'log',
                '[probe3] win.slots[0]=' +
                    JSON.stringify(winSlots[0] || null) +
                    ' [1]=' +
                    JSON.stringify(winSlots[1] || null)
            );
        } catch (e3) {
            nuiLog('log', '[probe3][err] ' + (e3 && e3.message ? e3.message : String(e3)));
        }
        window.__jpSlotState = state;
        if (window.JpSlotMarquee && window.JpSlotMarquee.refresh) {
            window.JpSlotMarquee.refresh();
        }
        if (window.JpSlotReels && state.symbolIds && window.JpSlotReels.setSymbolIds) {
            window.JpSlotReels.setSymbolIds(state.symbolIds);
        }

        if (payload.theme && window.JpSlotTheme) {
            window.JpSlotTheme.applyTheme(payload.theme);
        }
        var uis = payload.uiSize || { widthPercent: 90, heightPercent: 90, maxWidthPx: 0 };
        state.serverUiSize = uis;
        applyUISize(uis);
        applyVisualAssets(payload);
        if (state.effects) {
            playIdleLeftStageFromPreset();
        }
        applyI18n();
        state.bet = (state.machine && state.machine.minBet) || 100;
        clampBet();
        renderMachineName();
        if (payload.embedPreview && payload.neutralPreviewCharacter) {
            var cn = document.querySelector('.character-name');
            if (cn) {
                var tn = resolveLocale('admin.preview_char_neutral');
                cn.textContent = tn != null && tn !== '' ? tn : '\u2014';
            }
        } else {
            renderCharacterName();
        }
        updateFooter();
        window.__jpSlotEmbedPreview = !!payload.embedPreview;
        window.__jpSlotNeutralPreviewChar = !!(payload.embedPreview && payload.neutralPreviewCharacter);
        if (payload.embedPreview) {
            var rootPv = document.getElementById('root');
            var admPv = document.getElementById('panel-admin');
            if (rootPv) {
                rootPv.classList.add('is-visible');
            }
            if (admPv) {
                admPv.style.display = 'flex';
            }
        } else {
            showPlay(true);
        }

        if (window.JpSlotReels && typeof window.JpSlotReels.initIdle === 'function') {
            window.requestAnimationFrame(function () {
                window.requestAnimationFrame(function () {
                    window.JpSlotReels.initIdle(state.assetsRoot || '');
                });
            });
        }

        var ticker = document.querySelector('.ticker-marq');
        if (ticker) {
            var tw = resolveLocale('ticker');
            if (tw && tw[0]) {
                ticker.textContent = tw[0].replace('{topwin}', '---');
            }
        }

        if (!window._jpSlotFooterBound) {
            bindFooter();
            window._jpSlotFooterBound = true;
        }
        hideFreeSpinBanner();
        startIdleCharLoop();
        var charImg = document.querySelector('.char-stage img, .char-portrait');
        var charStage = document.querySelector('.char-stage');
        var charSrc = charImg && charImg.src ? charImg.src : 'null';
        var charDisplay = charStage ? getComputedStyle(charStage).display : 'null';
        var charRect = 'null';
        if (charStage) {
            var cr = charStage.getBoundingClientRect();
            charRect = JSON.stringify({
                l: Math.round(cr.left),
                w: Math.round(cr.width),
                h: Math.round(cr.height),
            });
        }
        nuiLog(
            'log',
            '[probe] charSrc=' + charSrc + ' charDisplay=' + charDisplay + ' charRect=' + charRect
        );
        if (payload.embedPreview) {
            var colLeft = document.querySelector('.admin-slot-embed .col-left');
            var probe2 =
                colLeft && colLeft.outerHTML ? colLeft.outerHTML.slice(0, 150) : 'null';
            nuiLog('log', '[probe2] colLeft=' + probe2);
        }
        nuiLog('log', '[initPlay] done');
    }

    function showWinPopup(amount) {
        var popup = document.querySelector('.win-popup');
        if (!popup) {
            return;
        }
        var n = typeof amount === 'number' ? amount : parseInt(amount, 10) || 0;
        if (n <= 0) {
            return;
        }
        popup.textContent = '+¥' + n.toLocaleString('ja-JP');
        popup.classList.remove('is-active');
        void popup.offsetWidth;
        popup.classList.add('is-active');
        window.setTimeout(function () {
            popup.classList.remove('is-active');
        }, 1200);
    }

    function onSpinResult(p) {
        if (!p || !p.ok) {
            state.spinning = false;
            window.__jpSlotSpinning = false;
            var sb0 = getSpinButton();
            if (sb0) {
                sb0.disabled = false;
            }
            return;
        }
        var reels = p.reels || ['cherry', 'cherry', 'cherry'];
        var dur = state.spinDuration;
        var ar = state.assetsRoot || window.__jpSlotAssetsRoot || '';
        window.JpSlotReels.runSpin(dur, reels, function () {
            var winPreview = p.winAmount != null ? p.winAmount : 0;
            var pl = document.querySelector('.payline');
            if (pl && winPreview > 0) {
                pl.classList.add('hit');
                window.setTimeout(function () {
                    pl.classList.remove('hit');
                }, 500);
            }
            var fxChain =
                window.JpSlotEffects.runEffectChain &&
                typeof window.JpSlotEffects.runEffectChain === 'function'
                    ? window.JpSlotEffects.runEffectChain(p, state.assetsRoot || ar)
                    : window.JpSlotEffects.playCutin(p.cutin || { kind: 'none' }, state.assetsRoot);
            fxChain.then(function () {
                    applyLeftStageForSpinResult(p, ar);
                    state.leftStageSlotIndex = (state.leftStageSlotIndex + 1) % 2;
                    applyWinFx(p, ar);
                    var previewUi =
                        p.previewMode === true || window.__jpSlotEmbedPreview === true;
                    if (previewUi) {
                        var betCost =
                            typeof p.effectiveBet === 'number'
                                ? p.effectiveBet
                                : state.bonusRemaining > 0
                                  ? 0
                                  : Number(state.bet) || 0;
                        var winAmtNum =
                            typeof p.winAmount === 'number' ? p.winAmount : 0;
                        state.balance = Math.max(
                            0,
                            Number(state.balance || 0) - betCost + winAmtNum
                        );
                    } else {
                        state.balance =
                            p.balance != null ? p.balance : state.balance;
                    }
                    state.jackpot = p.jackpot != null ? p.jackpot : state.jackpot;
                    window.__jpSlotState = state;
                    if (window.JpSlotMarquee && window.JpSlotMarquee.refresh) {
                        window.JpSlotMarquee.refresh();
                    }
                    var winAmt = p.winAmount != null ? p.winAmount : 0;
                    var winEl = document.querySelector('.win-value');
                    if (winEl) {
                        winEl.textContent = fmtMoney(winAmt);
                    }
                    if (winAmt > 0) {
                        showWinPopup(winAmt);
                    }
                    updateFooter();
                    if (p.bonus && p.bonus.active) {
                        if (p.bonus.ended) {
                            state.bonusRemaining = 0;
                        } else if (typeof p.bonus.remaining === 'number') {
                            state.bonusRemaining = p.bonus.remaining;
                        }
                    }
                    applyBonusUi(p.bonus);
                    window.__jpSlotPrevBonusActive = !!(p.bonus && p.bonus.active && !p.bonus.ended);
                    state.spinning = false;
                    window.__jpSlotSpinning = false;
                    var sb1 = getSpinButton();
                    if (sb1) {
                        sb1.disabled = false;
                    }
                    var restoreDelay =
                        p.effectScene === 'idle' || p.effectScene === 'miss_tease' ? 0 : 2800;
                    window.setTimeout(function () {
                        playIdleLeftStageFromPreset();
                    }, restoreDelay);
                });
        }, ar);
    }

    function openAdmin(payload) {
        payload = payload || {};
        if (payload.locales) {
            state.locales = payload.locales;
        }
        if (payload.uiSize) {
            state.serverUiSize = payload.uiSize;
        }
        applyI18n();
        showPlay(false);
        var adm = document.getElementById('panel-admin');
        if (adm) {
            adm.style.display = 'flex';
        }
        window.__jpSlotLastAdminPayload = payload;
        window.setTimeout(function () {
            if (window.__jpSlotFillTheme && payload.theme && document.getElementById('adm-bgPrimary')) {
                window.__jpSlotFillTheme(payload.theme);
            }
            if (window.__jpSlotSyncUiSliders && payload.uiSize) {
                window.__jpSlotSyncUiSliders(payload.uiSize);
            }
            if (window.jpSlotWireLegacyAdmin) {
                window.jpSlotWireLegacyAdmin(payload);
            }
        }, 80);
    }

    document.addEventListener(
        'keydown',
        function (e) {
            if (e.key !== 'Escape') {
                return;
            }
            var adm = document.getElementById('panel-admin');
            if (adm && adm.style.display === 'flex') {
                postNui('closeAdmin', {});
                e.preventDefault();
                return;
            }
            var root = document.getElementById('root');
            if (root && root.classList.contains('is-visible')) {
                nuiLog('log', '[keydown] Escape → handleExitClick');
                handleExitClick();
                e.preventDefault();
            }
        },
        true
    );

    window.addEventListener('message', function (e) {
        try {
            if (e && e.data && e.data.type === 'init') {
                var p = e.data.payload || {};
                var mid = (p.machine && p.machine.id) || 'nil';
                var cid =
                    (p.character && p.character.id) || p.characterId || 'nil';
                nuiLog(
                    'log',
                    '[nui] init received: machine=' +
                        mid +
                        ' character=' +
                        cid +
                        ' embedPreview=' +
                        !!p.embedPreview
                );
            }
        } catch (errInitLog) {}
        var d = e.data || {};
        var type = d.type;
        var payload = d.payload || {};
        if (type === 'hide') {
            nuiLog('log', '[message] hide received');
            hidePlay();
            return;
        }
        if (type === 'init') {
            try {
                initPlay(payload);
            } catch (err) {
                console.error('[jp-slot] initPlay failed:', err);
            }
        } else if (type === 'spinResult') {
            onSpinResult(payload);
        } else if (type === 'theme') {
            if (window.JpSlotTheme) {
                window.JpSlotTheme.applyTheme(payload);
            }
        } else if (type === 'openAdmin') {
            openAdmin(payload);
        } else if (type === 'applyUISize') {
            state.serverUiSize = payload;
            applyUISize(payload);
        } else if (type === 'adminClosed') {
            if (typeof window.jpSlotMoveRootToBody === 'function') {
                window.jpSlotMoveRootToBody();
            }
            window.__jpSlotEmbedPreview = false;
            window.__jpSlotNeutralPreviewChar = false;
            if (typeof window.jpSlotRemovePreviewBadge === 'function') {
                window.jpSlotRemovePreviewBadge();
            }
            var admTok = window.JpSlotAdminAuth && window.JpSlotAdminAuth.token;
            postNui('admin/previewEnd', admTok ? { token: admTok } : {});
            var adm = document.getElementById('panel-admin');
            if (adm) {
                adm.style.display = 'none';
            }
            if (state.serverUiSize) {
                applyUISize(state.serverUiSize);
            }
        } else if (type === 'previewMode') {
            var active = payload.active === true;
            var b = document.getElementById('preview-badge');
            if (active) {
                if (!b) {
                    b = document.createElement('div');
                    b.id = 'preview-badge';
                    b.className = 'preview-badge';
                    b.textContent =
                        '🎬 プレビューモード ・所持金∞ ・獲得金反映なし';
                    document.body.appendChild(b);
                }
            } else if (b) {
                b.remove();
            }
        } else if (type === 'clipboard') {
            var txt = payload.text || d.text;
            if (txt && navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(txt).catch(function () {});
            }
        } else if (type === 'forceLeave') {
            var root = document.getElementById('root');
            if (root) {
                root.classList.remove('is-visible');
            }
            state.spinning = false;
            window.__jpSlotSpinning = false;
            hideFreeSpinBanner();
            var spinBtn = getSpinButton();
            if (spinBtn) {
                spinBtn.disabled = false;
            }
        }
    });

    function bootDomReady() {
        nuiLog('log', '[BOOT] DOMContentLoaded fired');
    }
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', bootDomReady);
    } else {
        bootDomReady();
    }

    document.addEventListener(
        'keydown',
        function (e) {
            var adm = document.getElementById('panel-admin');
            if (adm && adm.style.display === 'flex') {
                return;
            }
            var root = document.getElementById('root');
            if (!root || !root.classList.contains('is-visible')) {
                return;
            }
            var tag = e.target && e.target.tagName;
            if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') {
                return;
            }
            var k = e.key;
            if (k === ' ' || k === 'Enter') {
                e.preventDefault();
                handleSpinClick();
            } else if (k === 'm' || k === 'M') {
                e.preventDefault();
                var hi = (state.machine && state.machine.maxBet) || state.bet;
                state.bet = hi;
                clampBet();
                updateFooter();
                nuiLog('log', '[keyboard] max bet');
            }
        },
        true
    );

    /** 管理プレビュー：#root を埋め込みホストへ移動（innerHTML 破棄前に必ず jpSlotMoveRootToBody） */
    window.jpSlotMoveRootToEmbed = function (host) {
        var root = document.getElementById('root');
        var panel = document.getElementById('panel-admin');
        if (!root || !host) {
            return;
        }
        var fit = document.getElementById('jp-slot-embed-fit');
        if (!fit) {
            fit = document.createElement('div');
            fit.id = 'jp-slot-embed-fit';
            fit.className = 'jp-slot-embed-fit';
        }
        fit.appendChild(root);
        host.appendChild(fit);
        root.classList.add('is-visible');
        window.__jpSlotEmbedPreview = true;
        if (panel) {
            panel.style.display = 'flex';
        }
        if (typeof window.applyEmbedPreviewFit === 'function') {
            window.applyEmbedPreviewFit();
        }
        if (typeof window.jpSlotBindEmbedPreviewResize === 'function') {
            window.jpSlotBindEmbedPreviewResize();
        }
        window.setTimeout(function () {
            if (typeof window.applyEmbedPreviewFit === 'function') {
                window.applyEmbedPreviewFit();
            }
        }, 50);
    };

    window.jpSlotMoveRootToBody = function () {
        var root = document.getElementById('root');
        var panel = document.getElementById('panel-admin');
        var fit = document.getElementById('jp-slot-embed-fit');
        if (!root || !panel || !panel.parentNode) {
            return;
        }
        if (typeof window.jpSlotDisconnectEmbedPreviewResize === 'function') {
            window.jpSlotDisconnectEmbedPreviewResize();
        }
        panel.parentNode.insertBefore(root, panel);
        if (fit && fit.parentNode) {
            fit.parentNode.removeChild(fit);
        }
        root.classList.remove('is-visible');
        window.__jpSlotEmbedPreview = false;
    };

    window.jpSlotApplyI18n = applyI18n;

    /** プレビューモードバッジを除去（管理サイドナビ離脱・サーバー非依存のフォールバック用） */
    window.jpSlotRemovePreviewBadge = function () {
        var b = document.getElementById('preview-badge');
        if (b) {
            b.remove();
        }
    };
})();

/* CLICK_TARGET / F1 は常にリスナー 1 組のみ。ログ出力は init の payload.debug.nuiVerbose が true のときだけ（毎回更新） */
(function () {
    var RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'jp-slot';
    window.__jpSlotNuiVerbose = false;

    function dlog(msg) {
        if (!window.__jpSlotNuiVerbose) {
            return;
        }
        fetch('https://' + RES + '/clientLog', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify({ level: 'log', message: String(msg) }),
        }).catch(function () {});
    }

    document.addEventListener(
        'click',
        function (e) {
            if (!window.__jpSlotNuiVerbose) {
                return;
            }
            var t = e.target;
            var r = t.getBoundingClientRect();
            dlog(
                '[CLICK_TARGET] tag=' +
                    t.tagName +
                    ' class="' +
                    t.className +
                    '" id="' +
                    t.id +
                    '" rect=' +
                    Math.round(r.left) +
                    ',' +
                    Math.round(r.top) +
                    ',' +
                    Math.round(r.width) +
                    'x' +
                    Math.round(r.height)
            );
        },
        true
    );

    window.addEventListener('keydown', function (e) {
        if (!window.__jpSlotNuiVerbose || e.key !== 'F1') {
            return;
        }
        var spin = document.getElementById('btn-spin') || document.querySelector('.btn-spin');
        if (!spin) {
            dlog('[F1] spin button not found');
            return;
        }
        var r = spin.getBoundingClientRect();
        var cx = r.left + r.width / 2;
        var cy = r.top + r.height / 2;
        var stack = document.elementsFromPoint(cx, cy);
        dlog(
            '[F1] spin rect=' +
                Math.round(r.left) +
                ',' +
                Math.round(r.top) +
                ',' +
                Math.round(r.width) +
                'x' +
                Math.round(r.height) +
                ' center=' +
                Math.round(cx) +
                ',' +
                Math.round(cy)
        );
        for (var i = 0; i < Math.min(6, stack.length); i++) {
            var el = stack[i];
            dlog(
                '[F1] [' +
                    i +
                    '] ' +
                    el.tagName +
                    '.' +
                    (el.className || '(no-class)') +
                    ' id=' +
                    (el.id || '(no-id)')
            );
        }
    });

    window.addEventListener('message', function (e) {
        var msg = e.data;
        if (!msg || msg.type !== 'init' || !msg.payload || !msg.payload.debug) {
            return;
        }
        var next = !!msg.payload.debug.nuiVerbose;
        window.__jpSlotNuiVerbose = next;
        if (next) {
            dlog('[DEBUG] verbose logging active (CLICK_TARGET / F1)');
        }
    });
})();

/* デバッグ: DOM 状態を起動約3秒後に clientLog 経由で Live Console（txAdmin）へ — F8 手動入力不要 */
setTimeout(function () {
    var f = document.getElementById('admin-slot-embed');
    var fit = document.getElementById('jp-slot-embed-fit');
    var r = document.getElementById('root');
    var log = window.jpSlotNuiLog;
    if (log) {
        log(
            'log',
            '[debug] host=' +
                !!f +
                ' hostSize=' +
                (f ? f.clientWidth + 'x' + f.clientHeight : 'null') +
                ' fit=' +
                !!fit +
                ' fitSize=' +
                (fit ? fit.clientWidth + 'x' + fit.clientHeight : 'null') +
                ' rootParent=' +
                (r && r.parentElement && r.parentElement.id ? r.parentElement.id : 'null') +
                ' rootChildren=' +
                (r && r.children ? r.children.length : -1)
        );
    }
    var big = [];
    var all = document.querySelectorAll('*');
    var i;
    for (i = 0; i < all.length; i++) {
        if (all[i].clientWidth > 3000) {
            big.push(all[i]);
        }
    }
    for (i = 0; i < Math.min(3, big.length); i++) {
        var e = big[i];
        if (log) {
            log(
                'log',
                '[debug] big=' +
                    e.tagName +
                    '#' +
                    (e.id || '') +
                    '.' +
                    String(e.className || '') +
                    ' ' +
                    e.clientWidth +
                    'x' +
                    e.clientHeight
            );
        }
    }
}, 3000);
