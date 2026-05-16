(function () {
    'use strict';

    /** プレビュー用定数（実機は `Config.HUD` 等へ移行予定） */
    var HUD_PREVIEW = {
        /** 回収数ラベルの意味: L2 = 任務全体の残りスロット系（案・ドキュメント参照） */
        lootMetricMode: 'L2',
        partyLeaveDelayMs: 5000,
    };

    // ===== モックデータ =====
    var state = {
        party: [
            { id: 1, name: 'あなた',   leader: true,  self: true,  hp: 180, maxHp: 200, status: 'alive' },
            { id: 2, name: 'サイトウ', leader: false, self: false, hp: 145, maxHp: 200, status: 'alive' },
            { id: 3, name: 'クロダ',   leader: false, self: false, hp: 60,  maxHp: 200, status: 'alive' },
            { id: 4, name: 'ワタナベ', leader: false, self: false, hp: 95,  maxHp: 200, status: 'alive' },
        ],
        loot: [
            { itemId: 'dimensional_scanner', label: 'Dimensional Scanner', tier: 'rare', count: 1 },
            { itemId: 'energy_cell', label: 'Energy Cell', tier: 'rare', count: 2 },
        ],
    };

    var STATUS_LABEL = {
        dead: '戦死',
        disconnected: '通信途絶',
        forced: '強制終了',
    };

    var STATUS_CLASS = {
        dead: 'dead',
        disconnected: 'disconnected',
        forced: 'forced',
    };

    var ICON_MAP = (typeof window !== 'undefined' && window.MRD9_ITEM_ICON_MAP) || {};

    function resolveIconUrl(itemId) {
        var path = ICON_MAP[itemId];
        if (!path || typeof path !== 'string') return null;
        try {
            return new URL('../' + path.replace(/^\//, ''), window.location.href).href;
        } catch (_) {
            return '../' + path.replace(/^\//, '');
        }
    }

    // ===== パーティ描画 =====
    function renderParty() {
        var ul = document.getElementById('mrd9-party-list');
        if (!ul) return;
        ul.innerHTML = '';
        state.party.forEach(function (m) {
            var li = document.createElement('li');
            li.dataset.id = String(m.id);
            if (m.status !== 'alive') {
                var sc = STATUS_CLASS[m.status];
                if (sc) li.classList.add(sc);
            }

            var header = document.createElement('div');
            header.className = 'mrd9-party-row-header';

            var name = document.createElement('span');
            name.className = 'mrd9-party-name';
            if (m.leader) name.classList.add('leader');
            if (m.self) name.classList.add('self');
            name.textContent = m.name;

            var hpText = document.createElement('span');
            hpText.className = 'mrd9-party-hp-text';
            var showHp = m.status === 'alive' ? m.hp : 0;
            hpText.innerHTML = showHp + '<span class="max"> / ' + m.maxHp + '</span>';

            header.appendChild(name);
            header.appendChild(hpText);
            li.appendChild(header);

            var bar = document.createElement('div');
            bar.className = 'mrd9-party-hp-bar';
            var fill = document.createElement('div');
            fill.className = 'mrd9-party-hp-fill';
            var pct = m.status === 'alive' ? (m.hp / m.maxHp) * 100 : 0;
            fill.style.width = pct + '%';
            if (pct <= 30) fill.classList.add('danger');
            else if (pct <= 60) fill.classList.add('warn');
            bar.appendChild(fill);
            li.appendChild(bar);

            ul.appendChild(li);
        });
    }

    // ===== 回収物リスト描画 =====
    function renderLoot() {
        var ul = document.getElementById('mrd9-loot-list');
        var empty = document.getElementById('mrd9-loot-empty');
        if (!ul || !empty) return;
        ul.innerHTML = '';
        if (state.loot.length === 0) {
            empty.classList.remove('mrd9-hidden');
            return;
        }
        empty.classList.add('mrd9-hidden');
        state.loot.forEach(function (item) {
            var li = document.createElement('li');
            var name = document.createElement('span');
            name.className = 'mrd9-loot-name tier-' + (item.tier || 'common');
            if (item.confiscated) name.classList.add('confiscated');
            name.textContent = item.label;
            var count = document.createElement('span');
            count.className = 'mrd9-loot-count';
            count.textContent = '×' + item.count;
            li.appendChild(name);
            li.appendChild(count);
            ul.appendChild(li);
        });
    }

    // ===== 入手通知 =====
    function showPickupToast(item) {
        var area = document.getElementById('mrd9-pickup-toast-area');
        if (!area) return;
        var toast = document.createElement('div');
        toast.className = 'mrd9-pickup-toast';

        var tierClass = item.confiscated ? 'confiscated' : (item.tier || 'common');
        var icon = document.createElement('div');
        icon.className = 'mrd9-pickup-icon ' + tierClass;
        var url = resolveIconUrl(item.itemId);
        if (url) {
            var img = document.createElement('img');
            img.src = url;
            img.alt = '';
            img.onerror = function () {
                if (img.parentNode === icon) icon.removeChild(img);
                icon.textContent = item.label.charAt(0);
            };
            icon.appendChild(img);
        } else {
            icon.textContent = item.label.charAt(0);
        }

        var body = document.createElement('div');
        body.className = 'mrd9-pickup-body';
        var label = document.createElement('div');
        label.className = 'mrd9-pickup-label ' + tierClass;
        label.textContent = '+ ' + item.label;
        var sub = document.createElement('div');
        sub.className = 'mrd9-pickup-sub';
        sub.textContent = item.confiscated ? '帰還時没収' : '回収';
        body.appendChild(label);
        body.appendChild(sub);

        toast.appendChild(icon);
        toast.appendChild(body);
        area.appendChild(toast);

        setTimeout(function () {
            if (toast.parentNode) toast.parentNode.removeChild(toast);
        }, 5000);
    }

    // ===== パーティ離脱バナー =====
    function showLeaveBanner(member, reason) {
        var area = document.getElementById('mrd9-leave-banner-area');
        if (!area) return;
        var label = STATUS_LABEL[reason] || reason;
        var banner = document.createElement('div');
        banner.className = 'mrd9-leave-banner';

        var nameSpan = document.createElement('span');
        nameSpan.className = 'name';
        nameSpan.textContent = member.name;

        var reasonSpan = document.createElement('span');
        reasonSpan.className = 'reason';
        reasonSpan.textContent = ' が「' + label + '」により分隊を離脱';

        banner.appendChild(nameSpan);
        banner.appendChild(reasonSpan);
        area.appendChild(banner);

        setTimeout(function () {
            if (banner.parentNode) banner.parentNode.removeChild(banner);
        }, 4500);
    }

    // ===== パーティ離脱処理 =====
    function partyLeave(memberId, reason) {
        var member = state.party.find(function (m) { return m.id === memberId; });
        if (!member || member.status !== 'alive') return;
        if (!STATUS_CLASS[reason]) return;

        member.status = reason;
        renderParty();
        showLeaveBanner(member, reason);

        var delay = HUD_PREVIEW.partyLeaveDelayMs;
        var animMs = 1600;

        setTimeout(function () {
            var li = document.querySelector('.mrd9-party-list li[data-id="' + String(memberId) + '"]');
            if (li) li.classList.add('leaving');
        }, Math.max(0, delay - animMs));

        setTimeout(function () {
            var idx = state.party.findIndex(function (m) { return m.id === memberId; });
            if (idx >= 0) state.party.splice(idx, 1);
            renderParty();
        }, delay);
    }

    // ===== 時刻 =====
    function tickClock() {
        var el = document.getElementById('mrd9-clock');
        if (!el) return;
        var now = new Date();
        var hh = String(now.getHours()).padStart(2, '0');
        var mm = String(now.getMinutes()).padStart(2, '0');
        el.textContent = hh + ':' + mm;
    }

    // ===== 制限時間 =====
    var extractSeconds = 4 * 60 + 32;

    function tickExtract() {
        var el = document.getElementById('m-extract');
        if (!el) return;
        var row = el.closest('.mrd9-metric-row');
        if (!row) return;

        if (extractSeconds <= 0) {
            el.textContent = '時間切れ';
            row.classList.add('warning');
            return;
        }
        extractSeconds--;
        var m = Math.floor(extractSeconds / 60);
        var s = extractSeconds % 60;
        el.textContent = String(m).padStart(2, '0') + ':' + String(s).padStart(2, '0');
        if (extractSeconds <= 60) row.classList.add('warning');
        else row.classList.remove('warning');
    }

    // ===== グローバル操作 =====
    window.mockPickup = function (itemId, label, tier, confiscated) {
        showPickupToast({ itemId: itemId, label: label, tier: tier, confiscated: !!confiscated });
        var existing = state.loot.find(function (l) { return l.itemId === itemId; });
        if (existing) {
            existing.count++;
            if (confiscated) existing.confiscated = true;
        } else {
            state.loot.push({
                itemId: itemId,
                label: label,
                tier: tier,
                count: 1,
                confiscated: !!confiscated,
            });
        }
        var elLoot = document.getElementById('m-loot');
        if (elLoot) elLoot.textContent = String(parseInt(elLoot.textContent, 10) + 1);
        renderLoot();
    };

    window.mockDamage = function () {
        var alive = state.party.filter(function (m) { return m.status === 'alive'; });
        if (alive.length === 0) return;
        var target = alive[Math.floor(Math.random() * alive.length)];
        target.hp = Math.max(0, target.hp - 35);
        if (target.hp === 0) {
            partyLeave(target.id, 'dead');
        } else {
            renderParty();
        }
    };

    window.mockHeal = function () {
        state.party.forEach(function (m) {
            if (m.status === 'alive') m.hp = m.maxHp;
        });
        renderParty();
    };

    window.mockKill = function () {
        var alive = state.party.filter(function (m) { return m.status === 'alive' && !m.self; });
        if (alive.length === 0) return;
        var t = alive[Math.floor(Math.random() * alive.length)];
        t.hp = 0;
        partyLeave(t.id, 'dead');
    };

    window.mockDisconnect = function () {
        var alive = state.party.filter(function (m) { return m.status === 'alive' && !m.self; });
        if (alive.length === 0) return;
        var t = alive[Math.floor(Math.random() * alive.length)];
        partyLeave(t.id, 'disconnected');
    };

    window.mockForceLeave = function () {
        var alive = state.party.filter(function (m) { return m.status === 'alive' && !m.self; });
        if (alive.length === 0) return;
        var t = alive[Math.floor(Math.random() * alive.length)];
        partyLeave(t.id, 'forced');
    };

    // ===== 初期化 =====
    renderParty();
    renderLoot();
    tickClock();
    setInterval(tickClock, 30 * 1000);
    setInterval(tickExtract, 1000);

    setTimeout(function () {
        window.mockPickup('nanite_repair_paste', 'Nanite Repair Paste', 'legendary');
    }, 1500);
})();
