(function () {
    'use strict';

    var isStandalone =
        typeof window.invokeNative !== 'function' &&
        typeof window.GetParentResourceName !== 'function';

    var root = document.getElementById('mrd9-result-root');
    if (!root) {
        return;
    }

    var elTitle = root.querySelector('.mrd9-result-title');
    var elSubtitle = root.querySelector('.mrd9-result-subtitle');
    var elVegaBlock = root.querySelector('.mrd9-vega-block');
    var elVegaLine = root.querySelector('.mrd9-vega-line');
    var elItemsList = root.querySelector('.mrd9-items-list');
    var elItemsEmpty = root.querySelector('.mrd9-items-empty');
    var elBdItem = root.querySelector('[data-bd="item"]');
    var elBdFiction = root.querySelector('[data-bd="fiction"]');
    var elBdBonus = root.querySelector('[data-bd="bonus"]');
    var elBdTotal = root.querySelector('[data-bd="total"]');
    var elPayout = root.querySelector('[data-bd="payout"]');
    var elBtn = root.querySelector('.mrd9-btn-continue');

    var animTimers = [];
    var skipRequested = false;
    var finalState = null;

    function fmtMoney(n) {
        return '$' + (n || 0).toLocaleString('en-US');
    }

    function clearTimers() {
        animTimers.forEach(function (t) {
            clearTimeout(t);
        });
        animTimers = [];
    }

    function schedule(fn, delay) {
        var t = setTimeout(fn, delay);
        animTimers.push(t);
        return t;
    }

    function typeWriter(el, text, speed, onDone) {
        if (speed === undefined) {
            speed = 28;
        }
        el.textContent = '';
        var i = 0;
        function step() {
            if (skipRequested) {
                el.textContent = text;
                if (onDone) {
                    onDone();
                }
                return;
            }
            el.textContent = text.slice(0, ++i);
            if (i < text.length) {
                animTimers.push(setTimeout(step, speed));
            } else if (onDone) {
                onDone();
            }
        }
        step();
    }

    function countUp(el, from, to, duration) {
        var start = performance.now();
        function frame(now) {
            if (skipRequested) {
                el.textContent = fmtMoney(to);
                return;
            }
            var t = Math.min(1, (now - start) / duration);
            var eased = 1 - Math.pow(1 - t, 3);
            var v = Math.floor(from + (to - from) * eased);
            el.textContent = fmtMoney(v);
            if (t < 1) {
                requestAnimationFrame(frame);
            }
        }
        requestAnimationFrame(frame);
    }

    function nuiAssetUrl(path) {
        if (!path || typeof path !== 'string') {
            return null;
        }
        var rel = path.replace(/^\//, '');
        if (isStandalone) {
            return '../' + rel;
        }
        if (typeof GetParentResourceName === 'function') {
            return 'https://cfx-nui-' + GetParentResourceName() + '/' + rel;
        }
        return rel;
    }

    function resolveIconUrl(item) {
        if (item.icon) {
            var ic = item.icon;
            if (/^https?:\/\//i.test(ic)) {
                return ic;
            }
            return nuiAssetUrl(ic) || ic;
        }
        var map = window.MRD9_ITEM_ICON_MAP || {};
        var path = map[item.itemId];
        if (!path) {
            return null;
        }
        return nuiAssetUrl(path);
    }

    function buildItemNode(item) {
        var li = document.createElement('li');
        if (item.confiscated) {
            li.classList.add('confiscated');
        }

        var icon = document.createElement('div');
        icon.className =
            'mrd9-item-icon ' +
            (item.confiscated ? 'confiscated' : item.tier || 'common');

        var url = resolveIconUrl(item);
        var letter = (item.label || item.itemId || '?').charAt(0).toUpperCase();
        if (url) {
            var img = document.createElement('img');
            img.src = url;
            img.alt = item.label || item.itemId || '';
            img.onerror = function () {
                if (img.parentNode === icon) {
                    icon.removeChild(img);
                }
                if (!icon.textContent) {
                    icon.textContent = letter;
                }
            };
            icon.appendChild(img);
        } else {
            icon.textContent = letter;
        }

        var label = document.createElement('div');
        label.className = 'mrd9-item-label';
        label.textContent = item.label || item.itemId;
        if (item.confiscated) {
            var tag = document.createElement('span');
            tag.className = 'mrd9-confiscated-tag';
            tag.textContent = 'CONFISCATED';
            label.appendChild(tag);
        }

        var meta = document.createElement('div');
        meta.className = 'mrd9-item-meta';
        meta.textContent = item.confiscated
            ? 'bounty +' + fmtMoney(item.bounty || 0)
            : '×' + item.count + '  @ ' + fmtMoney(item.unitValue || 0);

        var value = document.createElement('div');
        value.className = 'mrd9-item-value';
        value.textContent = fmtMoney(
            item.confiscated ? item.bounty || 0 : item.subtotal || 0
        );

        li.appendChild(icon);
        li.appendChild(label);
        li.appendChild(meta);
        li.appendChild(value);
        return li;
    }

    function applyFinalState() {
        if (!finalState) {
            return;
        }
        var p = finalState;
        elTitle.classList.add('show');
        elSubtitle.classList.add('show');
        elVegaBlock.classList.add('show');
        elVegaLine.textContent = p.vegaLine || '';

        elItemsList.innerHTML = '';
        if (!p.items || p.items.length === 0) {
            elItemsEmpty.classList.remove('mrd9-hidden');
        } else {
            elItemsEmpty.classList.add('mrd9-hidden');
            p.items.forEach(function (it) {
                var node = buildItemNode(it);
                node.classList.add('show');
                elItemsList.appendChild(node);
            });
        }

        var bd = p.breakdown || {};
        elBdItem.textContent = fmtMoney(bd.itemSubtotal || 0);
        elBdFiction.textContent = fmtMoney(bd.fictionBounty || 0);
        elBdBonus.textContent = fmtMoney(bd.extractionBonus || 0);
        elBdTotal.textContent = fmtMoney(bd.total || 0);

        if (p.payout) {
            elPayout.textContent =
                p.payout.mode === 'credit'
                    ? p.payout.creditCount + ' × mrd9_credit'
                    : fmtMoney(p.payout.cashAmount || 0) + ' (cash)';
        } else {
            elPayout.textContent = '—';
        }
        elBtn.disabled = false;
    }

    function playSequence(payload) {
        clearTimers();
        skipRequested = false;
        finalState = payload;

        root.classList.remove('failure');
        elTitle.classList.remove('show');
        elSubtitle.classList.remove('show');
        elVegaBlock.classList.remove('show');
        elVegaLine.textContent = '';
        elItemsList.innerHTML = '';
        elItemsEmpty.classList.add('mrd9-hidden');
        elBtn.disabled = true;
        elBdItem.textContent = '$0';
        elBdFiction.textContent = '$0';
        elBdBonus.textContent = '$0';
        elBdTotal.textContent = '$0';
        elPayout.textContent = '—';

        if (payload.result === 'extracted') {
            elTitle.textContent = 'EXTRACTION CONFIRMED';
            elSubtitle.textContent = 'Site-9 Recovery Report';
        } else if (payload.result === 'died') {
            elTitle.textContent = 'MISSION FAILED';
            elSubtitle.textContent = 'Operative KIA — Assets Lost';
            root.classList.add('failure');
        } else if (payload.result === 'timeout') {
            elTitle.textContent = 'TIME EXPIRED';
            elSubtitle.textContent = 'Contract Window Closed — Assets Forfeited';
            root.classList.add('failure');
        } else if (payload.result === 'out_of_zone') {
            elTitle.textContent = 'OUT OF ZONE';
            elSubtitle.textContent = 'Operative Strayed — Contract Voided';
            root.classList.add('failure');
        } else {
            elTitle.textContent = 'CONNECTION LOST';
            elSubtitle.textContent = 'Contract Forfeited';
            root.classList.add('failure');
        }

        root.classList.remove('mrd9-hidden');

        schedule(function () {
            elTitle.classList.add('show');
        }, 200);
        schedule(function () {
            elSubtitle.classList.add('show');
        }, 500);
        schedule(function () {
            elVegaBlock.classList.add('show');
            typeWriter(elVegaLine, payload.vegaLine || '', 28);
        }, 1100);

        var itemsStart = 2400;
        var items = payload.items || [];
        if (items.length === 0) {
            schedule(function () {
                elItemsEmpty.classList.remove('mrd9-hidden');
            }, itemsStart);
        }
        items.forEach(function (item, idx) {
            schedule(function () {
                var node = buildItemNode(item);
                elItemsList.appendChild(node);
                requestAnimationFrame(function () {
                    node.classList.add('show');
                });
            }, itemsStart + idx * 280);
        });

        var bdStart = itemsStart + items.length * 280 + 400;
        var bd = payload.breakdown || {};
        schedule(function () {
            countUp(elBdItem, 0, bd.itemSubtotal || 0, 600);
        }, bdStart);
        schedule(function () {
            countUp(elBdFiction, 0, bd.fictionBounty || 0, 600);
        }, bdStart + 500);
        schedule(function () {
            countUp(elBdBonus, 0, bd.extractionBonus || 0, 600);
        }, bdStart + 1000);
        schedule(function () {
            countUp(elBdTotal, 0, bd.total || 0, 900);
        }, bdStart + 1600);
        schedule(function () {
            if (payload.payout) {
                elPayout.textContent =
                    payload.payout.mode === 'credit'
                        ? payload.payout.creditCount + ' × mrd9_credit'
                        : fmtMoney(payload.payout.cashAmount || 0) + ' (cash)';
            }
            elBtn.disabled = false;
        }, bdStart + 2600);
    }

    function skipToFinal() {
        skipRequested = true;
        clearTimers();
        applyFinalState();
    }

    function closeUI() {
        root.classList.add('mrd9-hidden');
        clearTimers();
        if (!isStandalone && typeof GetParentResourceName === 'function') {
            fetch('https://' + GetParentResourceName() + '/result:close', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: '{}',
            }).catch(function () {});
        }
    }

    elBtn.addEventListener('click', function () {
        if (!elBtn.disabled) {
            closeUI();
        }
    });

    root.addEventListener(
        'pointerdown',
        function (e) {
            if (root.classList.contains('mrd9-hidden')) {
                return;
            }
            if (e.button === 2) {
                e.preventDefault();
                e.stopPropagation();
            }
        },
        true
    );

    document.addEventListener('keydown', function (e) {
        if (root.classList.contains('mrd9-hidden')) {
            return;
        }
        if (e.key === 'Escape' || e.key === ' ') {
            e.preventDefault();
            if (elBtn.disabled) {
                skipToFinal();
            } else {
                closeUI();
            }
        }
    });

    window.addEventListener('message', function (e) {
        var data = e.data || {};
        var type = data.type || data.action;
        if (type === 'result:show' || type === 'showResult') {
            playSequence(data.payload || {});
        } else if (type === 'result:hide' || type === 'hideResult') {
            closeUI();
        }
    });

    if (isStandalone) {
        document.body.classList.add('mrd9-standalone-preview');
        var mock = {
            result: 'extracted',
            vegaLine:
                'よく戻ってきた。今回の品は…悪くない。座って一杯どうだ。',
            items: [
                {
                    itemId: 'energy_cell',
                    label: 'Energy Cell',
                    count: 2,
                    tier: 'rare',
                    unitValue: 28000,
                    subtotal: 56000,
                },
                {
                    itemId: 'shield_booster',
                    label: 'Shield Booster',
                    count: 1,
                    tier: 'rare',
                    unitValue: 26000,
                    subtotal: 26000,
                },
                {
                    itemId: 'data_chip',
                    label: 'Data Chip',
                    count: 1,
                    confiscated: true,
                    bounty: 50000,
                },
            ],
            breakdown: {
                itemSubtotal: 82000,
                fictionBounty: 50000,
                extractionBonus: 5000,
                total: 137000,
            },
            payout: { mode: 'credit', creditCount: 137, cashAmount: 137000 },
        };
        var q = new URLSearchParams(location.search);
        if (q.has('dead')) {
            Object.assign(mock, {
                result: 'died',
                vegaLine:
                    '残念だ。次の契約者が見つかるまで、君の家族には連絡を入れておく。',
                items: [],
                breakdown: {
                    itemSubtotal: 0,
                    fictionBounty: 0,
                    extractionBonus: 0,
                    total: 0,
                },
                payout: null,
            });
        } else if (q.has('disconnect')) {
            Object.assign(mock, {
                result: 'disconnected',
                vegaLine: '通信が途切れたか。契約上、君の取り分は無効になる。',
                items: [],
                breakdown: {
                    itemSubtotal: 0,
                    fictionBounty: 0,
                    extractionBonus: 0,
                    total: 0,
                },
                payout: null,
            });
        } else if (q.has('empty')) {
            Object.assign(mock, {
                items: [],
                breakdown: {
                    itemSubtotal: 0,
                    fictionBounty: 0,
                    extractionBonus: 5000,
                    total: 5000,
                },
                payout: { mode: 'cash', cashAmount: 5000 },
                vegaLine: '手ぶらか。次は期待している。',
            });
        }
        setTimeout(function () {
            playSequence(mock);
        }, 300);
    }
})();
