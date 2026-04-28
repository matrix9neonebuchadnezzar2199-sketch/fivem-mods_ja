/* global window, document */
(function () {
    var videoEl = null;
    var imgEl = null;
    var cooldownUntil = 0;
    var playing = false;
    var COOLDOWN_MS = 4000;

    function getImg() {
        return (
            document.querySelector('.char-img.char-portrait') ||
            document.querySelector('.char-portrait')
        );
    }

    function init() {
        videoEl = document.querySelector('.char-video');
        imgEl = getImg();
        if (!videoEl) {
            return;
        }
        videoEl.addEventListener('ended', stop);
        videoEl.addEventListener('error', stop);
        videoEl.addEventListener('playing', onPlaying);
    }

    function onPlaying() {
        var el = getImg();
        if (!el || el.dataset.placeholder === 'true') {
            return;
        }
        el.classList.remove('is-returning');
        el.classList.add('is-fading-out');
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
        cooldownUntil = Date.now() + COOLDOWN_MS;

        var el = getImg();
        if (el && el.dataset.placeholder !== 'true') {
            el.classList.remove('is-fading-out');
            el.classList.remove('is-returning');
            void el.offsetWidth;
            el.classList.add('is-returning');
            window.setTimeout(function () {
                if (el) {
                    el.classList.remove('is-returning');
                }
            }, 750);
        }
    }

    function play(srcAbs, opt) {
        opt = opt || {};
        if (!videoEl || !srcAbs) {
            return false;
        }
        var now = Date.now();
        if (!opt.force && (playing || now < cooldownUntil)) {
            return false;
        }
        try {
            videoEl.loop = false;
            videoEl.src = srcAbs;
            videoEl.currentTime = 0;
            var p = videoEl.play();
            if (p && p.catch) {
                p.catch(stop);
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

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    window.CharFx = { init: init, play: play, stop: stop, isPlaying: isPlaying };
})();
