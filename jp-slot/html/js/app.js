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
    }

    window.applyUISize = applyUISize;

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
    };

    window.__jpSlotSpinning = false;

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
            var base = state.assetsRoot || window.__jpSlotAssetsRoot || '';
            if (base && window.CharFx && window.CharFx.play) {
                window.CharFx.play(base + 'characters/luna/win.webm');
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
            root.classList.remove('is-bonus');
            removeBonusBadge();
            return;
        }
        if (bonus.ended) {
            var endTpl = resolveLocale('ui.bonus_toast_end');
            var endTxt = (endTpl || 'BONUS END  {amount}').replace(
                '{amount}',
                fmtMoney(bonus.totalWin || 0)
            );
            flashToast(endTxt);
            root.classList.remove('is-bonus');
            removeBonusBadge();
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
        var big = tier === 'bigwin' || tier === 'jackpot';
        if (big) {
            reels.classList.add('is-bigwin');
        }
        reels.classList.add('is-win');
        var src = big
            ? assetsRoot + 'characters/luna/bigwin.webm'
            : assetsRoot + 'characters/luna/win.webm';
        if (window.CharFx && window.CharFx.play) {
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
        var cid = state.machine.characterId;
        if (!cid || !state.locales) {
            return;
        }
        var ch = window.ConfigCharacters || {};
        var ref = ch[cid] && ch[cid].displayName;
        var name = ref ? resolveLocale(ref) : cid;
        el.textContent = name || cid;
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
        if (!inFreeSpin && state.balance < state.bet) {
            nuiLog('log', '[handleSpinClick] balance < bet');
            return;
        }
        state.spinning = true;
        window.__jpSlotSpinning = true;
        spinBtn.disabled = true;
        nuiLog('log', '[handleSpinClick] post spin');
        postNui('spin', { bet: state.bet });
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
        var cid = machine && machine.characterId;
        var chMap = (payload && payload.characters) || {};
        var ch = cid ? chMap[cid] : null;
        var idle = ch && ch.idle;
        if (charImg && root && idle && idle.file && idle.type === 'image') {
            charImg.hidden = false;
            charImg.src = root + idle.file;
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
        window.ConfigCharacters = payload.characters || {};
        state.marquee = payload.marquee || { hype: [], info: [] };
        state.symbolIds = payload.symbolIds || null;
        state.debug = payload.debug || null;
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
        applyI18n();
        state.bet = (state.machine && state.machine.minBet) || 100;
        clampBet();
        renderMachineName();
        renderCharacterName();
        updateFooter();
        showPlay(true);

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
        state.bonusRemaining = 0;
        var rootInit = document.getElementById('root');
        if (rootInit) {
            rootInit.classList.remove('is-bonus');
        }
        removeBonusBadge();
        startIdleCharLoop();
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
                    applyWinFx(p, ar);
                    state.balance = p.balance != null ? p.balance : state.balance;
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
                    state.spinning = false;
                    window.__jpSlotSpinning = false;
                    var sb1 = getSpinButton();
                    if (sb1) {
                        sb1.disabled = false;
                    }
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
            var adm = document.getElementById('panel-admin');
            if (adm) {
                adm.style.display = 'none';
            }
            if (state.serverUiSize) {
                applyUISize(state.serverUiSize);
            }
        } else if (type === 'previewMode') {
            var active = payload.active;
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
            state.bonusRemaining = 0;
            removeBonusBadge();
            var root2 = document.getElementById('root');
            if (root2) {
                root2.classList.remove('is-bonus');
            }
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

    window.jpSlotApplyI18n = applyI18n;
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
