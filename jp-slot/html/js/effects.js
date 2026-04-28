/* global window */
(function () {
    /**
     * フラッシュオーバーレイを再生
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

    /** 左キャラ枠のループ動画（当選・アイドル演出） */
    var CharFx = (function () {
        var videoEl = null;
        var cooldownUntil = 0;
        var playing = false;

        function init() {
            videoEl = document.querySelector('.char-video');
            if (!videoEl) {
                return;
            }
            videoEl.addEventListener('ended', stop);
            videoEl.addEventListener('error', stop);
        }

        function stop() {
            if (!videoEl) {
                return;
            }
            try {
                videoEl.pause();
            } catch (_) {}
            videoEl.removeAttribute('src');
            try {
                videoEl.load();
            } catch (_) {}
            videoEl.classList.remove('is-playing');
            playing = false;
            cooldownUntil = Date.now() + 4000;
            var imgEl =
                document.querySelector('.char-img.char-portrait') ||
                document.querySelector('.char-portrait');
            if (imgEl) {
                imgEl.classList.remove('is-returning');
                void imgEl.offsetWidth;
                imgEl.classList.add('is-returning');
                window.setTimeout(function () {
                    imgEl.classList.remove('is-returning');
                }, 600);
            }
        }

        /**
         * @param {string} srcAbs assetsRoot 付きの絶対パス（nui://…/assets/…）
         * @param {{ force?: boolean }} opt
         * @returns {boolean}
         */
        function play(srcAbs, opt) {
            opt = opt || {};
            if (!videoEl || !srcAbs) {
                return false;
            }
            var now = Date.now();
            if (!opt.force && (playing || now < cooldownUntil)) {
                return false;
            }
            var portraitEl =
                document.querySelector('.char-img.char-portrait') ||
                document.querySelector('.char-portrait');
            if (portraitEl) {
                portraitEl.classList.remove('is-returning');
            }
            try {
                videoEl.loop = false;
                videoEl.src = srcAbs;
                videoEl.currentTime = 0;
                var p = videoEl.play();
                if (p && p.catch) {
                    p.catch(function () {
                        stop();
                    });
                }
                videoEl.classList.add('is-playing');
                playing = true;
                return true;
            } catch (e) {
                stop();
                return false;
            }
        }

        function isPlaying() {
            return playing;
        }

        return { init: init, play: play, stop: stop, isPlaying: isPlaying };
    })();

    window.CharFx = CharFx;

    function charFxDomReady() {
        CharFx.init();
    }
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', charFxDomReady);
    } else {
        charFxDomReady();
    }
})();
