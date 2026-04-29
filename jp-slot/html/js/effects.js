/* global window */
(function () {
    /**
     * フラッシュオーバーレイを再生（当選演出などから任意で呼ぶ）
     * @param {HTMLElement|null} el
     */
    function flash(el) {
        if (!el) {
            el = document.querySelector('.flash-overlay');
        }
        if (!el) {
            return;
        }
        el.classList.remove('flash');
        void el.offsetWidth;
        el.classList.add('flash');
    }

    /**
     * カットインを再生（画像または動画）。読込失敗時はスキップ。
     * サーバーは kind に cutin_image / cutin_video / none（Lua の返却）を渡す。
     * @param {object} cutin kind + asset
     * @param {string} assetsRoot nui://.../html/assets/
     * @returns {Promise<void>}
     */
    function playCutin(cutin, assetsRoot) {
        var overlay = document.querySelector('.cutin-overlay');
        var img = document.querySelector('.cutin-img');
        var vid = document.querySelector('.cutin-video');
        if (!overlay || !cutin || cutin.kind === 'none') {
            return Promise.resolve();
        }
        if (!assetsRoot) {
            assetsRoot = '';
        }
        var asset = cutin.asset || {};
        var path = asset.file || '';

        return new Promise(function (resolve) {
            function hideCutin() {
                overlay.classList.remove('is-active');
                overlay.classList.remove('is-playing');
                if (img) {
                    img.hidden = true;
                    img.removeAttribute('src');
                }
                if (vid) {
                    vid.hidden = true;
                    vid.pause();
                    vid.removeAttribute('src');
                }
            }

            function done() {
                hideCutin();
                resolve();
            }

            overlay.classList.add('is-active');

            if (cutin.kind === 'cutin_image' && img && path) {
                img.onload = function () {
                    window.setTimeout(done, 1200);
                };
                img.onerror = done;
                img.src = assetsRoot + path;
                img.hidden = false;
                if (vid) {
                    vid.hidden = true;
                }
                return;
            }

            if (cutin.kind === 'cutin_video' && vid && path) {
                overlay.classList.add('is-playing');
                vid.onended = done;
                vid.onerror = done;
                vid.src = assetsRoot + path;
                vid.hidden = false;
                if (img) {
                    img.hidden = true;
                }
                vid.play().catch(done);
                var ms = (asset.duration || 3) * 1000;
                window.setTimeout(function () {
                    if (!vid.ended) {
                        done();
                    }
                }, ms + 500);
                return;
            }

            done();
        });
    }

    /**
     * リール中央テキスト（半透明背景＋大文字）
     * @param {{ text:string, color?:string, sizePercent?:number, duration?:number, effect?:string }} opts
     * @returns {Promise<void>}
     */
    function showCenterText(opts) {
        opts = opts || {};
        var el = document.getElementById('reel-center-text');
        if (!el) {
            return Promise.resolve();
        }
        var content = el.querySelector('.reel-center-text-content');
        if (!content) {
            return Promise.resolve();
        }
        var pct = opts.sizePercent != null ? Number(opts.sizePercent) : 100;
        el.style.setProperty('--rct-size', String(Math.max(50, Math.min(200, pct))));
        content.textContent = opts.text || '';
        content.style.color = opts.color || '#f4ead0';
        el.className = 'reel-center-text';
        if (opts.effect && opts.effect !== 'none') {
            el.classList.add('fx-' + opts.effect);
        }
        el.hidden = false;
        window.requestAnimationFrame(function () {
            el.classList.add('is-show');
        });
        var ms = Math.max(200, Number(opts.duration) || 1500);
        return new Promise(function (resolve) {
            window.setTimeout(function () {
                el.classList.remove('is-show');
                window.setTimeout(function () {
                    el.hidden = true;
                    el.classList.remove('fx-pulse', 'fx-zoom');
                    resolve();
                }, 250);
            }, ms);
        });
    }

    /**
     * effectBlocks（サーバー）に沿って 前テキスト→カットイン→後テキスト の順に再生し、最後にサーバー cutin をフォールバック
     * @param {object} p spinResult
     * @param {string} assetsRoot
     * @returns {Promise<void>}
     */
    function runEffectChain(p, assetsRoot) {
        var eb = p.effectBlocks;
        var serverCutin = (p && p.cutin) || { kind: 'none' };
        assetsRoot = assetsRoot || '';
        if (!eb || typeof eb !== 'object') {
            return playCutin(serverCutin, assetsRoot);
        }
        var seq = Promise.resolve();

        var pre = eb.pre_text || eb.preText;
        if (pre && pre.enabled !== false && pre.text) {
            seq = seq.then(function () {
                return showCenterText({
                    text: pre.text,
                    color: pre.color || '#f4ead0',
                    sizePercent: pre.size_percent != null ? pre.size_percent : pre.sizePercent || 80,
                    duration: pre.duration_ms != null ? pre.duration_ms : pre.durationMs || 600,
                    effect: 'none',
                });
            });
        }

        var cb = eb.cutin_block || eb.cutinBlock || eb.cutin;
        if (cb && cb.kind && cb.kind !== 'none' && cb.file) {
            seq = seq.then(function () {
                var kind = cb.kind === 'video' ? 'cutin_video' : 'cutin_image';
                return playCutin({ kind: kind, asset: { file: cb.file, duration: (cb.duration_ms || 1200) / 1000 } }, assetsRoot);
            });
        } else {
            seq = seq.then(function () {
                return playCutin(serverCutin, assetsRoot);
            });
        }

        var post = eb.post_text || eb.postText;
        if (post && post.enabled !== false && post.text) {
            seq = seq.then(function () {
                return showCenterText({
                    text: post.text,
                    color: post.color || '#d4af37',
                    sizePercent: post.size_percent != null ? post.size_percent : post.sizePercent || 140,
                    duration: post.duration_ms != null ? post.duration_ms : post.durationMs || 800,
                    effect: post.effect && post.effect !== 'none' ? post.effect : 'pulse',
                });
            });
        }

        return seq.catch(function () {});
    }

    window.JpSlotEffects = {
        flash: flash,
        playCutin: playCutin,
        showCenterText: showCenterText,
        runEffectChain: runEffectChain,
    };
})();
