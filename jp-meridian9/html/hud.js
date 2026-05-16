(function () {
    'use strict';

    var isStandalone = !window.invokeNative && typeof GetParentResourceName === 'undefined';
    var root = document.getElementById('mrd9-hud-root');
    if (!root) {
        return;
    }

    var elSelfName = root.querySelector('.mrd9-self-name');
    var elSelfHpValue = root.querySelector('.mrd9-self-hp-value');
    var elSelfHpFill = root.querySelector('.mrd9-self-hp-fill');
    var elMissionTitle = root.querySelector('.mrd9-mission-title');
    var elMissionId = root.querySelector('.mrd9-mission-id');
    var elPartyList = root.querySelector('#mrd9-party-list');
    var elLootList = root.querySelector('#mrd9-loot-list');
    var elLootEmpty = root.querySelector('#mrd9-loot-empty');
    var elClock = root.querySelector('#mrd9-clock');
    var elKills = root.querySelector('#m-kills');
    var elKillsTarget = root.querySelector('#m-kills-target');
    var elLoot = root.querySelector('#m-loot');
    var elLootMax = root.querySelector('#m-loot-max');
    var elExtract = root.querySelector('#m-extract');
    var elPickupArea = document.getElementById('mrd9-pickup-toast-area');
    var elLeaveArea = document.getElementById('mrd9-leave-banner-area');

    var extractWarnSec = 60;

    // 制限時間ローカル補間: サーバ `hud:state` の `extractSeconds` を受信した時刻を基準に、
    // クライアント側で performance.now() ベースで減算する。次の broadcast で上書き同期する。
    // ネットワーク遅延・パケットロスで HUD が止まって見える事故を抑える。
    var extractLocal = {
        lastSync: 0,
        lastValue: 0,
        active: false,
    };

    var STATUS_LABEL = {
        dead: '戦死',
        disconnected: '通信途絶',
    };

    var ICON_MAP = window.MRD9_ITEM_ICON_MAP || {};
    var lastPartySig = '';
    var lastLootSig = '';

    function nuiAssetUrl(path) {
        if (!path || typeof path !== 'string') {
            return null;
        }
        var rel = path.replace(/^\//, '');
        if (isStandalone) {
            return new URL('../' + rel, location.href).toString();
        }
        if (typeof GetParentResourceName === 'function') {
            return 'https://cfx-nui-' + GetParentResourceName() + '/' + rel;
        }
        return rel;
    }

    function resolveIconUrl(itemId) {
        var path = ICON_MAP[itemId];
        if (!path) {
            return null;
        }
        return nuiAssetUrl(path);
    }

    function renderSelfBlock(payload) {
        if (payload.self && elSelfName) {
            elSelfName.textContent = payload.self.name || '';
        }
        if (payload.mission) {
            if (elMissionTitle) {
                elMissionTitle.textContent = payload.mission.title || '';
            }
            if (elMissionId) {
                elMissionId.textContent = payload.mission.contractId || '';
            }
        }
    }

    function renderSelfHp(hp, maxHp) {
        if (!elSelfHpValue || !elSelfHpFill) {
            return;
        }
        var pct = maxHp > 0 ? (hp / maxHp) * 100 : 0;
        elSelfHpValue.innerHTML = hp + '<span class="max"> / ' + maxHp + '</span>';
        elSelfHpFill.style.width = pct + '%';
        elSelfHpFill.classList.remove('warn', 'danger');
        if (pct <= 30) {
            elSelfHpFill.classList.add('danger');
        } else if (pct <= 60) {
            elSelfHpFill.classList.add('warn');
        }
    }

    function renderParty(party) {
        if (!elPartyList) {
            return;
        }
        var sig = JSON.stringify(party || []);
        if (sig === lastPartySig) {
            return;
        }
        lastPartySig = sig;
        elPartyList.innerHTML = '';
        (party || []).forEach(function (m) {
            var li = document.createElement('li');
            li.dataset.id = String(m.id);
            var name = document.createElement('span');
            name.className = 'mrd9-party-name';
            if (m.leader) {
                name.classList.add('leader');
            }
            name.textContent = m.name;
            li.appendChild(name);
            elPartyList.appendChild(li);
        });
    }

    function renderLoot(lootList) {
        if (!elLootList || !elLootEmpty) {
            return;
        }
        var list = lootList || [];
        var sig = JSON.stringify(list);
        if (sig === lastLootSig) {
            return;
        }
        lastLootSig = sig;
        elLootList.innerHTML = '';
        if (list.length === 0) {
            elLootEmpty.classList.remove('mrd9-hidden');
            return;
        }
        elLootEmpty.classList.add('mrd9-hidden');
        list.forEach(function (item) {
            var li = document.createElement('li');
            var name = document.createElement('span');
            name.className = 'mrd9-loot-name tier-' + (item.tier || 'common');
            if (item.confiscated) {
                name.classList.add('confiscated');
            }
            name.textContent = item.label;
            var count = document.createElement('span');
            count.className = 'mrd9-loot-count';
            count.textContent = '×' + item.count;
            li.appendChild(name);
            li.appendChild(count);
            elLootList.appendChild(li);
        });
    }

    function renderExtractValue(sec) {
        if (!elExtract) {
            return;
        }
        var row = elExtract.closest('.mrd9-metric-row');
        if (sec <= 0) {
            elExtract.textContent = '時間切れ';
            if (row) {
                row.classList.add('warning');
            }
            return;
        }
        var mm = Math.floor(sec / 60);
        var ss = sec % 60;
        elExtract.textContent =
            String(mm).padStart(2, '0') + ':' + String(ss).padStart(2, '0');
        if (row) {
            if (sec <= extractWarnSec) {
                row.classList.add('warning');
            } else {
                row.classList.remove('warning');
            }
        }
    }

    function renderMetrics(m) {
        if (!m) {
            return;
        }
        if (typeof m.extractWarningSec === 'number' && m.extractWarningSec > 0) {
            extractWarnSec = m.extractWarningSec;
        }
        if (m.kills) {
            if (elKills) {
                elKills.textContent = m.kills.current;
            }
            if (elKillsTarget) {
                elKillsTarget.textContent = m.kills.target;
            }
        }
        if (m.loot) {
            if (elLoot) {
                elLoot.textContent = m.loot.current;
            }
            if (elLootMax) {
                elLootMax.textContent = m.loot.max;
            }
        }
        if (typeof m.extractSeconds === 'number' && elExtract) {
            extractLocal.lastSync = performance.now();
            extractLocal.lastValue = m.extractSeconds;
            extractLocal.active = true;
            renderExtractValue(m.extractSeconds);
        }
    }

    function extractLocalTick() {
        if (!extractLocal.active) {
            return;
        }
        var elapsed = Math.floor(
            (performance.now() - extractLocal.lastSync) / 1000
        );
        var sec = Math.max(0, extractLocal.lastValue - elapsed);
        renderExtractValue(sec);
    }
    setInterval(extractLocalTick, 250);

    function renderClock(clock) {
        if (elClock && clock) {
            elClock.textContent = clock;
        }
    }

    function showPickup(item) {
        if (!elPickupArea) {
            return;
        }
        var toast = document.createElement('div');
        toast.className = 'mrd9-pickup-toast';

        var rawLabel = item.label != null ? String(item.label).trim() : '';
        var displayLabel =
            rawLabel ||
            (item.itemId != null && String(item.itemId)) ||
            '?';
        var initialLetter = displayLabel.charAt(0) || '?';

        var icon = document.createElement('div');
        icon.className =
            'mrd9-pickup-icon ' +
            (item.confiscated ? 'confiscated' : item.tier || 'common');
        var url = resolveIconUrl(item.itemId);
        if (url) {
            var img = document.createElement('img');
            img.src = url;
            img.onerror = function () {
                if (img.parentNode === icon) {
                    icon.removeChild(img);
                }
                icon.textContent = initialLetter;
            };
            icon.appendChild(img);
        } else {
            icon.textContent = initialLetter;
        }

        var body = document.createElement('div');
        body.className = 'mrd9-pickup-body';
        var label = document.createElement('div');
        label.className =
            'mrd9-pickup-label ' +
            (item.confiscated ? 'confiscated' : item.tier || 'common');
        label.textContent = '+ ' + displayLabel;
        var sub = document.createElement('div');
        sub.className = 'mrd9-pickup-sub';
        sub.textContent = item.confiscated ? '帰還時没収' : '回収';
        body.appendChild(label);
        body.appendChild(sub);

        toast.appendChild(icon);
        toast.appendChild(body);
        elPickupArea.appendChild(toast);
        setTimeout(function () {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 5000);
    }

    function showLeaveBanner(payload) {
        if (!elLeaveArea) {
            return;
        }
        var banner = document.createElement('div');
        banner.className = 'mrd9-leave-banner';
        var nameSpan = document.createElement('span');
        nameSpan.className = 'name';
        nameSpan.textContent = payload.name || '';
        var reasonSpan = document.createElement('span');
        reasonSpan.className = 'reason';
        var reasonLabel = STATUS_LABEL[payload.reason] || payload.reason || '';
        reasonSpan.textContent = ' が「' + reasonLabel + '」により分隊を離脱';
        banner.appendChild(nameSpan);
        banner.appendChild(reasonSpan);
        elLeaveArea.appendChild(banner);
        setTimeout(function () {
            if (banner.parentNode) {
                banner.parentNode.removeChild(banner);
            }
        }, 4500);
    }

    function showHud() {
        lastPartySig = '';
        lastLootSig = '';
        extractLocal.active = false;
        extractLocal.lastValue = 0;
        root.classList.remove('mrd9-hidden');
        document.body.classList.add('mrd9-hud-phasec-active');
    }

    function hideHud() {
        extractLocal.active = false;
        root.classList.add('mrd9-hidden');
        document.body.classList.remove('mrd9-hud-phasec-active');
    }

    window.addEventListener('message', function (e) {
        var data = e.data || {};
        var type = data.type || data.action;
        var p = data.payload || {};
        switch (type) {
            case 'hud:state':
                renderSelfBlock(p);
                renderParty(p.party);
                renderLoot(p.loot);
                renderMetrics(p.metrics);
                renderClock(p.clock);
                break;
            case 'hud:selfHp':
                renderSelfHp(p.hp || 0, p.maxHp || 100);
                break;
            case 'hud:pickup':
                showPickup(p);
                break;
            case 'hud:partyLeave':
                showLeaveBanner(p);
                break;
            case 'hud:show':
                showHud();
                break;
            case 'hud:hide':
                hideHud();
                break;
            default:
                break;
        }
    });

    hideHud();
})();
