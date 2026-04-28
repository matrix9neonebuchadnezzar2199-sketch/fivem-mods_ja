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

    window.JpSlotEffects = {
        flash: flash,
        playCutin: playCutin,
    };
})();
