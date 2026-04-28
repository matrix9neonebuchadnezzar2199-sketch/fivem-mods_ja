/* global window, document */
(function () {
    function shuffle(a) {
        a = a.slice();
        for (var i = a.length - 1; i > 0; i--) {
            var j = Math.floor(Math.random() * (i + 1));
            var t = a[i];
            a[i] = a[j];
            a[j] = t;
        }
        return a;
    }

    function buildContent(messages, jackpot) {
        var items = shuffle(messages || []);
        var html = '';
        if (typeof jackpot === 'number' && jackpot > 0) {
            html +=
                '<span class="mq-item">💰 現在のジャックポット ¥' +
                jackpot.toLocaleString() +
                '</span><span class="mq-sep">◆</span>';
        }
        for (var i = 0; i < items.length; i++) {
            html += '<span class="mq-item">' + items[i] + '</span><span class="mq-sep">◆</span>';
        }
        return html + html;
    }

    function refresh() {
        var st = window.__jpSlotState || {};
        var hype = (st.marquee && st.marquee.hype) || [];
        var info = (st.marquee && st.marquee.info) || [];
        var jp = st.jackpot || 0;
        var top = document.getElementById('marquee-top');
        var bot = document.getElementById('marquee-bottom');
        if (top) {
            top.innerHTML = buildContent(hype, jp);
        }
        if (bot) {
            bot.innerHTML = buildContent(info, 0);
        }
    }

    function start() {
        if (window.__jpSlotMarqueeStarted) {
            return;
        }
        window.__jpSlotMarqueeStarted = true;
        refresh();
        window.setInterval(refresh, 30000);
    }

    window.JpSlotMarquee = { refresh: refresh, start: start };

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', start);
    } else {
        start();
    }
})();
