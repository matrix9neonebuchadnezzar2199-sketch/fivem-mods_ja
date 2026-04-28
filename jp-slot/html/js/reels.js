/* global window, Promise */
(function () {
    var LABELS = {
        cherry: '🍒',
        bell: '🔔',
        watermelon: '🍉',
        bar: '📊',
        seven: '7️⃣',
        wild: '⭐',
        character: '✨',
    };

    /** ペイテーブルと一致させるシンボル ID（サーバー seatGranted で上書き可能） */
    var SYMBOL_IDS = ['cherry', 'bell', 'watermelon', 'bar', 'seven', 'wild', 'character'];

    function setSymbolIds(arr) {
        if (Array.isArray(arr) && arr.length > 0) {
            SYMBOL_IDS = arr.slice();
        }
    }

    /** 縦に並べるマス数（多いほど長く流れる） */
    var STRIP_LENGTH = 28;

    /** ビューポートに見える行数（上・中・下） */
    var VISIBLE_CELLS = 3;

    /** 中段に確定シンボルを置くオフセット（末尾=下段なので末尾-1=中段） */
    var MIDDLE_INDEX_OFFSET = 1;

    function symLabel(id) {
        return LABELS[id] || id || '?';
    }

    function symImgSrc(id, assetsRoot) {
        return {
            luxury: assetsRoot + 'symbols/luxury/' + id + '.png',
            flat: assetsRoot + 'symbols/' + id + '.png',
        };
    }

    /**
     * @param {HTMLElement} cell
     * @param {string} id
     * @param {string} assetsRoot
     */
    function fillSymbolCell(cell, id, assetsRoot) {
        cell.innerHTML = '';
        id = id || 'cherry';
        if (!assetsRoot) {
            cell.textContent = symLabel(id);
            return;
        }
        var img = document.createElement('img');
        img.className = 'sym-img';
        img.alt = id;
        img.draggable = false;
        var paths = symImgSrc(id, assetsRoot);
        img.src = paths.luxury;
        img.onerror = function () {
            if (img.dataset.fb !== '1') {
                img.dataset.fb = '1';
                img.src = paths.flat;
                return;
            }
            cell.textContent = symLabel(id);
        };
        cell.appendChild(img);
    }

    /** .reel-inner の高さ（3段ビューポートの外寸） */
    function getReelInnerHeight(reelEl) {
        var inner = reelEl.querySelector('.reel-inner');
        var h = inner ? inner.clientHeight : 0;
        if (h < 8) {
            h = reelEl.clientHeight || 0;
        }
        return h;
    }

    /** 1 マスの高さ = ビューポート ÷ 3 */
    function getCellHeightPx(reelEl) {
        var vh = getReelInnerHeight(reelEl);
        if (vh < 12) {
            vh = 120;
        }
        return vh / VISIBLE_CELLS;
    }

    /**
     * @param {string} id
     * @param {string} assetsRoot
     * @param {number} cellHeightPx
     * @returns {HTMLElement}
     */
    function makeSymbolCell(id, assetsRoot, cellHeightPx) {
        var cell = document.createElement('div');
        cell.className = 'reel-symbol-cell';
        cell.style.height = cellHeightPx + 'px';
        cell.style.flexShrink = '0';
        fillSymbolCell(cell, id, assetsRoot);
        return cell;
    }

    /**
     * ストリップを構築。中段（見えている3つのうち中央）に確定シンボル。
     * @param {HTMLElement} reelEl
     * @param {string} finalSymbol
     * @param {string} assetsRoot
     */
    function buildStrip(reelEl, finalSymbol, assetsRoot) {
        var strip = reelEl.querySelector('.reel-strip');
        if (!strip) {
            return;
        }
        var cellH = getCellHeightPx(reelEl);
        strip.innerHTML = '';

        var ids = [];
        var i;
        for (i = 0; i < STRIP_LENGTH; i++) {
            ids.push(SYMBOL_IDS[Math.floor(Math.random() * SYMBOL_IDS.length)]);
        }
        ids[STRIP_LENGTH - 1 - MIDDLE_INDEX_OFFSET] = finalSymbol || 'cherry';

        for (i = 0; i < STRIP_LENGTH; i++) {
            strip.appendChild(makeSymbolCell(ids[i], assetsRoot, cellH));
        }
    }

    /**
     * 確定位置へジャンプ（アニメーションなし）— 中段に確定シンボル
     */
    function placeStripAtFinal(reelEl, finalSymbol, assetsRoot) {
        var strip = reelEl.querySelector('.reel-strip');
        if (!strip) {
            return;
        }
        buildStrip(reelEl, finalSymbol, assetsRoot);
        var cellH = getCellHeightPx(reelEl);
        var finalY = -(STRIP_LENGTH - VISIBLE_CELLS) * cellH;
        strip.style.transition = 'none';
        strip.style.transform = 'translateY(' + finalY + 'px)';
        void strip.offsetHeight;
    }

    /**
     * @param {HTMLElement} reelEl
     * @param {string} finalSymbol
     * @param {number} durationMs
     * @param {string} assetsRoot
     * @returns {Promise<void>}
     */
    function spinOneReel(reelEl, finalSymbol, durationMs, assetsRoot) {
        return new Promise(function (resolve) {
            if (!reelEl) {
                resolve();
                return;
            }
            var strip = reelEl.querySelector('.reel-strip');
            if (!strip) {
                resolve();
                return;
            }
            buildStrip(reelEl, finalSymbol, assetsRoot);
            var cellH = getCellHeightPx(reelEl);
            var finalY = -(STRIP_LENGTH - VISIBLE_CELLS) * cellH;

            strip.style.transition = 'none';
            strip.style.transform = 'translateY(0)';
            void strip.offsetHeight;

            reelEl.classList.add('is-spinning');

            var done = false;
            function cleanup() {
                if (done) {
                    return;
                }
                done = true;
                strip.removeEventListener('transitionend', onTransEnd);
                reelEl.classList.remove('is-spinning');
                resolve();
            }

            function onTransEnd(e) {
                if (e.propertyName === 'transform') {
                    cleanup();
                }
            }

            strip.addEventListener('transitionend', onTransEnd);
            window.setTimeout(cleanup, durationMs + 150);

            strip.style.transition =
                'transform ' + durationMs + 'ms cubic-bezier(0.2, 0.8, 0.3, 1)';

            window.requestAnimationFrame(function () {
                window.requestAnimationFrame(function () {
                    strip.style.transform = 'translateY(' + finalY + 'px)';
                });
            });
        });
    }

    /**
     * @param {number} totalMs
     * @returns {{ base: number, stagger: number }}
     */
    function computeStaggerTiming(totalMs) {
        var t = Math.max(400, Math.min(totalMs || 2500, 12000));
        var stagger = Math.min(300, Math.max(60, Math.floor(t / 8)));
        var base = t - 2 * stagger;
        if (base < 150) {
            stagger = Math.floor(t / 4);
            base = t - 2 * stagger;
        }
        base = Math.max(150, base);
        return { base: base, stagger: stagger };
    }

    /**
     * @param {string[]} reelsIds
     * @param {string} [assetsRoot]
     */
    function setReelSymbols(reelsIds, assetsRoot) {
        assetsRoot = assetsRoot || window.__jpSlotAssetsRoot || '';
        var i;
        for (i = 0; i < 3; i++) {
            var slot = document.querySelector('.reel[data-reel="' + i + '"]');
            if (!slot) {
                continue;
            }
            var rid = reelsIds && reelsIds[i] ? reelsIds[i] : 'cherry';
            placeStripAtFinal(slot, rid, assetsRoot);
        }
    }

    /**
     * @param {string} assetsRoot
     */
    function initIdle(assetsRoot) {
        setReelSymbols(['cherry', 'cherry', 'cherry'], assetsRoot);
    }

    /**
     * @param {number} durationMs
     * @param {string[]} finalReels
     * @param {function} onDone
     * @param {string} [assetsRoot]
     */
    function runSpin(durationMs, finalReels, onDone, assetsRoot) {
        assetsRoot = assetsRoot || window.__jpSlotAssetsRoot || '';
        var tm = computeStaggerTiming(durationMs || 2500);
        var base = tm.base;
        var stagger = tm.stagger;

        var reels = document.querySelectorAll('.reel');
        var promises = [];
        var idx;
        for (idx = 0; idx < 3; idx++) {
            var el = reels[idx];
            var sym = finalReels && finalReels[idx] ? finalReels[idx] : 'cherry';
            var ms = base + idx * stagger;
            promises.push(spinOneReel(el, sym, ms, assetsRoot));
        }

        Promise.all(promises).then(function () {
            if (typeof onDone === 'function') {
                onDone();
            }
        });
    }

    window.JpSlotReels = {
        symLabel: symLabel,
        setReelSymbols: setReelSymbols,
        setSymbolIds: setSymbolIds,
        initIdle: initIdle,
        runSpin: runSpin,
    };
})();
