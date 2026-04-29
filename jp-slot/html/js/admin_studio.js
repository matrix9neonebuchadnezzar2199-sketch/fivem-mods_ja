/* global window, document, fetch, GetParentResourceName, Chart */
(function () {
    var RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'jp-slot';

    var STUDIO_NAV = [
        { key: 'master', icon: '🎲', i18n: 'admin.nav.master' },
        { key: 'idle', icon: '🎰', i18n: 'admin.nav.idle' },
        { key: 'win', icon: '🎯', i18n: 'admin.nav.win' },
        { key: 'bonus', icon: '🎁', i18n: 'admin.nav.bonus' },
        { key: 'bonus_streak', icon: '🔁', i18n: 'admin.nav.bonus_streak' },
        { key: 'bonus_big', icon: '💎', i18n: 'admin.nav.bonus_big' },
        { key: 'miss_tease', icon: '😅', i18n: 'admin.nav.miss_tease' },
        { key: 'theme', icon: '⚙️', i18n: 'admin.nav.theme' },
    ];

    var EFFECT_KEYS = ['idle', 'win', 'bonus', 'bonus_streak', 'bonus_big', 'miss_tease'];

    function defaultBlockText() {
        return {
            enabled: true,
            text: '',
            color: '#f4ead0',
            size_percent: 80,
            duration_ms: 600,
            fade: true,
            effect: 'none',
        };
    }

    function defaultEffectSection() {
        return {
            pre_text: defaultBlockText(),
            cutin_block: { kind: 'none', file: '', duration_ms: 1200 },
            post_text: (function () {
                var b = defaultBlockText();
                b.size_percent = 140;
                b.color = '#d4af37';
                b.effect = 'pulse';
                return b;
            })(),
            char_video: { enabled: true, file: '', fade_back: true },
            sound: { se: '', voice: '', bgm_change: false, bgm_file: '' },
            reel_fx: { mode: 'none', custom_color: '#d4af37' },
            payout: { enabled: true, duration_ms: 2000, animation: 'countup' },
            reaction: { reaction: 'confused', tease_strength: 'medium' },
            streak_intensity: {},
        };
    }

    function createDefaultWorkspace() {
        var effects = {};
        for (var i = 0; i < EFFECT_KEYS.length; i++) {
            effects[EFFECT_KEYS[i]] = defaultEffectSection();
        }
        effects.miss_tease.payout.enabled = false;
        return {
            master: {
                normal: { win: 25, bonus: 5, miss_tease: 70 },
                bonus_promote: { streak: 30, big: 5, max_streak: 3, big_multiplier: 10 },
                cooldown: { spins: 5 },
            },
            effects: effects,
            dirty: false,
        };
    }

    var workspace = createDefaultWorkspace();
    var viewMode = 'master';
    var selectedKey = 'master';
    var simCharts = { cumulative: null, hist: null };

    function $(id) {
        return document.getElementById(id);
    }

    function fetchNui(path, body) {
        var tok = window.JpSlotAdminAuth && window.JpSlotAdminAuth.token;
        body = body || {};
        if (tok) {
            body.token = tok;
        }
        return fetch('https://' + RES + '/' + path, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(body),
        })
            .then(function (r) {
                return r.json();
            })
            .catch(function () {
                return { ok: false };
            });
    }

    function markDirty() {
        workspace.dirty = true;
    }

    function escapeHtml(s) {
        return String(s || '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function masterSumOk(m) {
        var a = Number(m.normal.win) + Number(m.normal.bonus) + Number(m.normal.miss_tease);
        return Math.abs(a - 100) <= 0.1;
    }

    function masterPromoteSum(m) {
        return Number(m.bonus_promote.streak) + Number(m.bonus_promote.big);
    }

    function rowMaster(k, label, val) {
        return (
            '<div class="studio-row master-row" data-k="' +
            k +
            '"><div class="studio-row-label">' +
            escapeHtml(label) +
            '</div><div class="studio-row-control"><input type="range" min="0" max="100" step="0.1" class="studio-slider master-sl" data-k="' +
            k +
            '" value="' +
            val +
            '"><span class="studio-slider-value master-sl-val">' +
            Number(val).toFixed(1) +
            '%</span></div></div>'
        );
    }

    function rowPromote(k, label, val) {
        return (
            '<div class="studio-row">' +
            '<div class="studio-row-label">' +
            escapeHtml(label) +
            '</div><div class="studio-row-control">' +
            '<input type="range" min="0" max="100" step="0.1" class="studio-slider pr-sl" data-pk="' +
            k +
            '" value="' +
            val +
            '"><span class="studio-slider-value pr-sl-val">' +
            Number(val).toFixed(1) +
            '%</span></div></div>'
        );
    }

    function normalizeMaster() {
        var w = workspace.master.normal.win;
        var b = workspace.master.normal.bonus;
        var t = workspace.master.normal.miss_tease;
        var s = w + b + t;
        if (s <= 0) {
            return;
        }
        workspace.master.normal.win = (w / s) * 100;
        workspace.master.normal.bonus = (b / s) * 100;
        workspace.master.normal.miss_tease = (t / s) * 100;
        markDirty();
        renderCenter();
    }

    function renderMasterTab() {
        var m = workspace.master;
        var ok = masterSumOk(m);
        var ps = masterPromoteSum(m);
        var single = Math.max(0, 100 - ps);
        var sumNum = (Number(m.normal.win) + Number(m.normal.bonus) + Number(m.normal.miss_tease)).toFixed(1);
        var sumText = '合計 ' + sumNum + '%' + (ok ? ' ✓' : '');
        var titleStatusClass = 'studio-card-title-status' + (ok ? '' : ' is-error');

        var html = '<div class="studio-section studio-master-wrap">';
        html +=
            '<h3 class="studio-page-title" data-i18n-key="admin.master.title">' +
            escapeHtml('全体確率設定') +
            '</h3>';

        html += '<div class="studio-card">';
        html += '<div class="studio-card-title">';
        html += '<span data-i18n-key="admin.master.normal_section">通常中の抽選（合計100%）</span>';
        html +=
            '<span id="master-sum-val" class="' +
            titleStatusClass +
            '">' +
            escapeHtml(sumText) +
            '</span>';
        html += '</div>';
        html += rowMaster('win', 'WIN', m.normal.win);
        html += rowMaster('bonus', 'BONUS', m.normal.bonus);
        html += rowMaster('miss_tease', 'MISS', m.normal.miss_tease);
        html += '<div class="studio-card-actions studio-card-actions--end">';
        html +=
            '<button type="button" class="studio-btn-secondary" id="master-norm-go" data-i18n-key="admin.master.auto_normalize">自動正規化</button>';
        html += '</div></div>';

        html += '<div class="studio-card">';
        html += '<div class="studio-card-title">';
        html +=
            '<span data-i18n-key="admin.master.bonus_promote_section">ボーナス昇格抽選（ボーナス当選時）</span>';
        html += '</div>';
        html += rowPromote('streak', 'STREAK', m.bonus_promote.streak);
        html += rowPromote('big', 'BIG', m.bonus_promote.big);
        html += '<div class="studio-row studio-row--readonly">';
        html +=
            '<div class="studio-row-label" data-i18n-key="admin.master.single_auto_label">単発（自動）</div>';
        html +=
            '<div class="studio-row-control"><span id="master-single-pct" class="studio-slider-value studio-single-readonly">' +
            single.toFixed(2) +
            '%</span></div>';
        html += '</div>';
        html += '<div class="studio-row">';
        html +=
            '<div class="studio-row-label" data-i18n-key="admin.master.max_streak_label">最大連続回数</div>';
        html += '<div class="studio-row-control">';
        html +=
            '<input type="number" min="1" max="9" id="mx-str" value="' +
            escapeHtml(String(m.bonus_promote.max_streak)) +
            '">';
        html += ' <span class="studio-row-hint">(1〜9)</span>';
        html += '</div></div>';
        html += '<div class="studio-row">';
        html += '<div class="studio-row-label" data-i18n-key="admin.master.big_mul_label">ビッグ倍率</div>';
        html += '<div class="studio-row-control">';
        html +=
            '<input type="number" min="2" max="20" id="big-mul" value="' +
            escapeHtml(String(m.bonus_promote.big_multiplier)) +
            '">';
        html += ' <span class="studio-row-hint">(2〜20)</span>';
        html += '</div></div>';
        html += '</div>';

        html += '<div class="studio-card">';
        html += '<div class="studio-card-title">';
        html += '<span data-i18n-key="admin.master.cooldown_section">クールタイム</span>';
        html += '</div>';
        html +=
            '<p class="studio-note studio-card-note" data-i18n-key="admin.master.cooldown_note">ボーナス終了後、通常スピンN回まで全抽選をハズレ演出に置き換え</p>';
        html += '<div class="studio-row">';
        html += '<div class="studio-row-label" data-i18n-key="admin.master.spin_count_label">スピン数</div>';
        html += '<div class="studio-row-control">';
        html +=
            '<input type="number" min="0" max="50" id="cd-spins" value="' +
            m.cooldown.spins +
            '" />';
        html += ' <span class="studio-row-hint">(0〜50)</span>';
        html += '</div></div>';
        html += '</div>';

        html += '<div class="studio-master-primary-wrap">';
        html +=
            '<button type="button" class="studio-btn-primary" id="master-norm-btn" ' +
            (ok ? '' : 'disabled') +
            ' data-i18n-key="admin.master.save_master">💾 マスター設定を保存</button>';
        html += '</div>';

        html += '<div class="studio-card studio-card--sim">';
        html += '<div class="studio-card-title">';
        html += '<span data-i18n-key="admin.master.simulation_section">シミュレーション</span>';
        html += '</div>';
        html += '<div class="sim-toolbar">';
        html +=
            '<label class="sim-toolbar-field"><span data-i18n-key="admin.master.sim_trials">試行回数</span> ';
        html +=
            '<select id="sim-trials"><option>100</option><option>500</option><option selected>1000</option><option>5000</option><option>10000</option></select></label>';
        html +=
            '<label class="sim-toolbar-field"><span data-i18n-key="admin.master.bet_label">ベット</span> ';
        html += '<input type="number" id="sim-bet" value="100"></label>';
        html +=
            '<button type="button" class="studio-btn-primary studio-btn-sim-run" id="sim-run" data-i18n-key="admin.master.simulation_run">実行</button>';
        html += '</div>';
        html += '<div id="sim-warn-banner" class="sim-warn-banner" hidden></div>';
        html += '<pre id="sim-out" class="sim-out"></pre>';
        html +=
            '<div class="sim-chart-tabs"><button type="button" class="sim-tab-btn" data-sim-tab="cum">累積収支</button><button type="button" class="sim-tab-btn" data-sim-tab="hist">払戻分布</button></div>';
        html += '<canvas id="chart-cum" height="120"></canvas>';
        html += '<canvas id="chart-hist" height="120" hidden></canvas>';
        html += '</div>';

        html += '</div>';
        return html;
    }

    function wireMaster() {
        var rows = document.querySelectorAll('.master-sl');
        for (var i = 0; i < rows.length; i++) {
            rows[i].addEventListener('input', function () {
                var k = this.getAttribute('data-k');
                workspace.master.normal[k] = Number(this.value);
                var row = this.closest('.studio-row');
                var lab = row ? row.querySelector('.master-sl-val') : null;
                if (lab) {
                    lab.textContent = Number(this.value).toFixed(1) + '%';
                }
                var sum =
                    workspace.master.normal.win +
                    workspace.master.normal.bonus +
                    workspace.master.normal.miss_tease;
                var el = $('master-sum-val');
                var okNow = masterSumOk(workspace.master);
                if (el) {
                    el.textContent = '合計 ' + sum.toFixed(1) + '%' + (okNow ? ' ✓' : '');
                    el.className = 'studio-card-title-status' + (okNow ? '' : ' is-error');
                }
                var btn = $('master-norm-btn');
                if (btn) {
                    btn.disabled = !okNow;
                }
                markDirty();
            });
        }
        var pr = document.querySelectorAll('.pr-sl');
        for (var j = 0; j < pr.length; j++) {
            pr[j].addEventListener('input', function () {
                var k = this.getAttribute('data-pk');
                workspace.master.bonus_promote[k] = Number(this.value);
                var prow = this.closest('.studio-row');
                var pv = prow ? prow.querySelector('.pr-sl-val') : null;
                if (pv) {
                    pv.textContent = Number(this.value).toFixed(1) + '%';
                }
                var sp = $('master-single-pct');
                if (sp) {
                    var psu = masterPromoteSum(workspace.master);
                    sp.textContent = Math.max(0, 100 - psu).toFixed(2) + '%';
                }
                markDirty();
            });
        }
        var mx = $('mx-str');
        if (mx) {
            mx.addEventListener('change', function () {
                workspace.master.bonus_promote.max_streak = Number(mx.value);
                markDirty();
            });
        }
        var bm = $('big-mul');
        if (bm) {
            bm.addEventListener('change', function () {
                workspace.master.bonus_promote.big_multiplier = Number(bm.value);
                markDirty();
            });
        }
        var cds = $('cd-spins');
        if (cds) {
            cds.addEventListener('change', function () {
                workspace.master.cooldown.spins = Number(cds.value);
                markDirty();
            });
        }
        var nb = $('master-norm-btn');
        if (nb) {
            nb.addEventListener('click', function () {
                fetchNui('admin/preset/save', {
                    preset: buildPresetPayload(),
                }).then(function (r) {
                    if (r.ok) {
                        workspace.dirty = false;
                        alert('保存しました');
                    }
                });
            });
        }
        var ng = $('master-norm-go');
        if (ng) {
            ng.addEventListener('click', normalizeMaster);
        }
        var sr = $('sim-run');
        if (sr) {
            sr.addEventListener('click', runSimulationClick);
        }
        document.querySelectorAll('[data-sim-tab]').forEach(function (bt) {
            bt.addEventListener('click', function () {
                var t = bt.getAttribute('data-sim-tab');
                var c1 = $('chart-cum');
                var c2 = $('chart-hist');
                if (t === 'cum') {
                    if (c1) {
                        c1.hidden = false;
                    }
                    if (c2) {
                        c2.hidden = true;
                    }
                } else {
                    if (c1) {
                        c1.hidden = true;
                    }
                    if (c2) {
                        c2.hidden = false;
                    }
                }
            });
        });
    }

    function buildPresetPayload() {
        var name = ($('studio-preset-name') && $('studio-preset-name').value) || 'default';
        var id = name.replace(/[^a-zA-Z0-9_-]/g, '_') || 'preset';
        return {
            id: id,
            name: name,
            master: workspace.master,
            effects: workspace.effects,
            editor: 'studio-v2',
        };
    }

    function simWinPayout(bet) {
        return Math.floor(bet * 2.4);
    }
    function simBonusSpinPayout(bet, multB) {
        return Math.floor(bet * 3.2 * (multB || 2));
    }

    function runSimulation(trials, bet, s) {
        var inBonus = false;
        var bonusRemaining = 0;
        var pendingPromote = null;
        var currentStreak = 0;
        var cooldown = 0;
        var r = {
            win: 0,
            bonus: 0,
            bonus_single: 0,
            bonus_streak: 0,
            bonus_big: 0,
            miss_tease: 0,
            cooldown_blocked: 0,
            total_bet: 0,
            total_payout: 0,
            max_streak: 0,
            history: [],
        };
        var bonusMult = 2;
        var fs = 8;
        var maxStr = s.maxStreak || 3;
        var bigM = s.bigMultiplier || 10;
        for (var i = 0; i < trials; i++) {
            if (inBonus) {
                var win = simBonusSpinPayout(bet, bonusMult);
                r.total_payout += win;
                r.history.push({ type: 'bonus_spin', payout: win, bet: 0 });
                bonusRemaining--;
                if (bonusRemaining <= 0) {
                    if (pendingPromote === 'streak' && currentStreak < maxStr) {
                        currentStreak++;
                        bonusRemaining = fs;
                        r.bonus_streak++;
                        r.max_streak = Math.max(r.max_streak, currentStreak);
                    } else if (pendingPromote === 'big') {
                        bonusRemaining = fs * bigM;
                        pendingPromote = null;
                        r.bonus_big++;
                    } else {
                        inBonus = false;
                        pendingPromote = null;
                        currentStreak = 0;
                        cooldown = s.cooldownSpins || 5;
                    }
                }
                continue;
            }
            r.total_bet += bet;
            if (cooldown > 0) {
                cooldown--;
                r.cooldown_blocked++;
                r.miss_tease++;
                r.history.push({ type: 'miss_tease', payout: 0, bet: bet });
                continue;
            }
            var roll = Math.random() * 100;
            if (roll < s.normalWin) {
                var w = simWinPayout(bet);
                r.win++;
                r.total_payout += w;
                r.history.push({ type: 'win', payout: w, bet: bet });
            } else if (roll < s.normalWin + s.normalBonus) {
                r.bonus++;
                inBonus = true;
                bonusRemaining = fs;
                var sub = Math.random() * 100;
                if (sub < s.promoteStreak) {
                    pendingPromote = 'streak';
                    currentStreak = 1;
                } else if (sub < s.promoteStreak + s.promoteBig) {
                    pendingPromote = 'big';
                } else {
                    pendingPromote = null;
                    r.bonus_single++;
                }
                r.history.push({ type: 'bonus', payout: 0, bet: bet });
            } else {
                r.miss_tease++;
                r.history.push({ type: 'miss_tease', payout: 0, bet: bet });
            }
        }
        return r;
    }

    function runSimulationClick() {
        var trials = Number(($('sim-trials') && $('sim-trials').value) || 1000);
        var bet = Number(($('sim-bet') && $('sim-bet').value) || 100);
        var m = workspace.master;
        var s = {
            normalWin: Number(m.normal.win),
            normalBonus: Number(m.normal.bonus),
            promoteStreak: Number(m.bonus_promote.streak),
            promoteBig: Number(m.bonus_promote.big),
            maxStreak: Number(m.bonus_promote.max_streak),
            bigMultiplier: Number(m.bonus_promote.big_multiplier),
            cooldownSpins: Number(m.cooldown.spins),
        };
        var res = runSimulation(trials, bet, s);
        var rtp = res.total_bet > 0 ? (res.total_payout / res.total_bet) * 100 : 0;
        var out = $('sim-out');
        if (out) {
            out.textContent =
                JSON.stringify(
                    {
                        rtp: rtp.toFixed(2) + '%',
                        total_bet: res.total_bet,
                        total_payout: res.total_payout,
                        counts: {
                            win: res.win,
                            bonus: res.bonus,
                            bonus_single: res.bonus_single,
                            bonus_streak: res.bonus_streak,
                            bonus_big: res.bonus_big,
                            miss_tease: res.miss_tease,
                            cooldown_blocked: res.cooldown_blocked,
                        },
                        max_streak: res.max_streak,
                    },
                    null,
                    2
                );
        }
        var warn = $('sim-warn-banner');
        if (warn) {
            if (res.total_payout > res.total_bet) {
                warn.hidden = false;
                warn.textContent =
                    '⚠️ 警告：払い出しが入金を超えています！ RTP: ' + rtp.toFixed(1) + '%';
            } else {
                warn.hidden = true;
            }
        }
        drawSimCharts(res, bet);
    }

    function drawSimCharts(res, bet) {
        if (typeof Chart === 'undefined') {
            return;
        }
        var cum = [];
        var acc = 0;
        for (var i = 0; i < res.history.length; i++) {
            var h = res.history[i];
            acc += (h.payout || 0) - (h.bet || 0);
            cum.push({ x: i + 1, y: acc });
        }
        var ctx1 = $('chart-cum');
        if (simCharts.cumulative) {
            simCharts.cumulative.destroy();
        }
        if (ctx1) {
            simCharts.cumulative = new Chart(ctx1.getContext('2d'), {
                type: 'line',
                data: {
                    datasets: [
                        {
                            label: '累積収支',
                            data: cum.map(function (p) {
                                return p.y;
                            }),
                        },
                    ],
                },
                options: { animation: false },
            });
        }
        var buckets = [0, 0, 0, 0, 0, 0, 0];
        for (var j = 0; j < res.history.length; j++) {
            var p = res.history[j].payout || 0;
            var idx = 6;
            if (p <= 0) {
                idx = 0;
            } else if (p <= bet) {
                idx = 1;
            } else if (p <= bet * 5) {
                idx = 2;
            } else if (p <= bet * 10) {
                idx = 3;
            } else if (p <= bet * 50) {
                idx = 4;
            } else if (p <= bet * 100) {
                idx = 5;
            }
            buckets[idx]++;
        }
        var ctx2 = $('chart-hist');
        if (simCharts.hist) {
            simCharts.hist.destroy();
        }
        if (ctx2) {
            simCharts.hist = new Chart(ctx2.getContext('2d'), {
                type: 'bar',
                data: {
                    labels: ['0', '1x', '1-5x', '5-10x', '10-50x', '50-100x', '100x+'],
                    datasets: [{ data: buckets }],
                },
                options: { animation: false },
            });
        }
    }

    function renderEffectTab(key) {
        var sec = workspace.effects[key] || defaultEffectSection();
        workspace.effects[key] = sec;
        var html = '<div class="studio-section"><h3>' + escapeHtml(key) + '</h3>';
        html += '<p class="studio-note">7ブロック構成（簡易UI）。チェックでON/OFF。</p>';
        html += blockUi('① カットイン前テキスト', 'pre_text', sec.pre_text);
        html += '<h4>② カットイン本体</h4>';
        html +=
            '<select class="studio-select" data-ef="' +
            key +
            '" data-path="cutin_block.kind"><option value="none">none</option><option value="image">image</option><option value="video">video</option></select>';
        html += blockUi('③ カットイン後テキスト', 'post_text', sec.post_text);
        if (key === 'miss_tease') {
            html += '<p>⑦配当ブロック（miss_tease は無効）</p>';
            html +=
                '<label>reaction <select data-ef="' +
                key +
                '" data-path="reaction.reaction"><option>are</option><option>confused</option><option>disappointed</option></select></label>';
        } else if (key === 'bonus_streak') {
            html += '<p>段階別演出強度（プレースホルダ）</p>';
        } else if (key === 'bonus_big') {
            html +=
                '<p class="studio-note">ビッグ倍率は全体確率の big_multiplier を参照（読み取り専用）</p>';
        }
        html += '</div>';
        return html;
    }

    function blockUi(title, path, data) {
        var en = data.enabled !== false;
        return (
            '<div class="studio-layer"><h4>' +
            title +
            '</h4><label><input type="checkbox" class="blk-en" data-path="' +
            path +
            '"' +
            (en ? ' checked' : '') +
            '> 使用</label><input type="text" placeholder="テキスト" class="blk-txt" data-path="' +
            path +
            '.text" value="' +
            escapeHtml(data.text || '') +
            '"></div>'
        );
    }

    function wireEffectTab(key) {
        document.querySelectorAll('.blk-txt').forEach(function (inp) {
            inp.addEventListener('input', function () {
                var path = inp.getAttribute('data-path').split('.');
                var obj = workspace.effects[key];
                obj[path[0]][path[1]] = inp.value;
                markDirty();
            });
        });
    }

    function legacyHtml() {
        return (
            '<div class="admin-wrap studio-legacy-inner">' +
            '<h2 class="admin-title" data-i18n-key="admin.tab_design"></h2>' +
            '<ul class="admin-tabs">' +
            '<li><button type="button" class="admin-tab active" data-tab="design" data-i18n-key="admin.tab_design"></button></li>' +
            '<li><button type="button" class="admin-tab" data-tab="display" data-i18n-key="admin.tab_display"></button></li>' +
            '</ul>' +
            '<div class="admin-pane admin-pane-design" data-pane="design">' +
            '<label class="admin-row">bgPrimary <input type="color" id="adm-bgPrimary"></label>' +
            '<label class="admin-row">accent1 <input type="color" id="adm-accent1"></label>' +
            '<label class="admin-row">textPrimary <input type="color" id="adm-textPrimary"></label>' +
            '<label class="admin-row">theme name <input type="text" id="adm-themeName"></label>' +
            '<div class="admin-actions"><button type="button" id="adm-save" data-i18n-key="admin.save_theme"></button></div></div>' +
            '<div class="admin-pane admin-pane-display" data-pane="display" style="display:none">' +
            '<h3 class="admin-subtitle" data-i18n-key="admin.ui_size_title"></h3>' +
            '<p class="admin-hint" data-i18n-key="admin.ui_size_hint"></p>' +
            '<div class="form-row"><label for="ui-width" data-i18n-key="admin.ui_width"></label>' +
            '<input type="range" id="ui-width" min="30" max="100" value="90" step="5"><span id="ui-width-val">90</span>%</div>' +
            '<div class="form-row"><label for="ui-height" data-i18n-key="admin.ui_height"></label>' +
            '<input type="range" id="ui-height" min="30" max="100" value="90" step="5"><span id="ui-height-val">90</span>%</div>' +
            '<div class="form-row"><label for="ui-maxwidth" data-i18n-key="admin.ui_maxwidth"></label>' +
            '<input type="number" id="ui-maxwidth" min="0" max="7680" step="10" value="0"></div>' +
            '<div class="admin-actions">' +
            '<button type="button" id="ui-size-save" class="btn-primary" data-i18n-key="admin.ui_size_save"></button>' +
            '<button type="button" id="ui-size-reset" class="btn-secondary" data-i18n-key="admin.ui_size_reset"></button>' +
            '</div></div></div>'
        );
    }

    function buildLeftNav() {
        var left = $('admin-left');
        if (!left) {
            return;
        }
        var h = '';
        for (var i = 0; i < STUDIO_NAV.length; i++) {
            var it = STUDIO_NAV[i];
            h +=
                '<button type="button" class="studio-nav-item' +
                (selectedKey === it.key ? ' is-active' : '') +
                '" data-nav="' +
                it.key +
                '">' +
                it.icon +
                ' <span data-i18n-key="' +
                it.i18n +
                '"></span></button>';
        }
        left.innerHTML = h;
        var btns = left.querySelectorAll('[data-nav]');
        for (var j = 0; j < btns.length; j++) {
            btns[j].addEventListener('click', function () {
                selectedKey = this.getAttribute('data-nav');
                if (selectedKey === 'theme') {
                    viewMode = 'legacy';
                } else if (selectedKey === 'master') {
                    viewMode = 'master';
                } else {
                    viewMode = 'effect';
                }
                buildLeftNav();
                renderCenter();
                var cur = $('adm-current-state');
                if (cur) {
                    cur.textContent = selectedKey;
                }
            });
        }
    }

    function renderCenter() {
        var c = $('admin-center');
        if (!c) {
            return;
        }
        if (viewMode === 'master') {
            c.innerHTML = renderMasterTab();
            wireMaster();
        } else if (viewMode === 'legacy') {
            c.innerHTML = legacyHtml();
            if (window.__jpSlotAdminLegacyBind) {
                window.__jpSlotAdminLegacyBind();
            }
        } else {
            c.innerHTML = renderEffectTab(selectedKey);
            wireEffectTab(selectedKey);
        }
        if (window.jpSlotApplyI18n) {
            window.jpSlotApplyI18n();
        }
    }

    function buildRight() {
        var r = $('admin-right');
        if (!r) {
            return;
        }
        r.innerHTML =
            '<div class="studio-right-inner">' +
            '<button type="button" class="studio-preview-main" id="studio-preview-start">▶ プレビュー開始</button>' +
            '<button type="button" class="studio-preview-end" id="studio-preview-end">✕ プレビュー終了</button>' +
            '<p class="studio-mini">所持金∞</p>' +
            '<div class="studio-preset"><label>プリセット <input type="text" id="studio-preset-name" value="default"></label>' +
            '<button type="button" id="studio-preset-save">💾 上書き保存</button></div>' +
            '</div>';
        $('studio-preview-start').addEventListener('click', function () {
            fetchNui('admin/previewStart', {});
        });
        $('studio-preview-end').addEventListener('click', function () {
            tryConfirmExit(function () {
                fetchNui('admin/previewEnd', {});
            });
        });
        $('studio-preset-save').addEventListener('click', function () {
            fetchNui('admin/preset/save', { preset: buildPresetPayload() }).then(function (x) {
                if (x.ok) {
                    workspace.dirty = false;
                    alert('保存しました');
                }
            });
        });
    }

    function tryConfirmExit(done) {
        if (!workspace.dirty) {
            done();
            return;
        }
        var modal = $('admin-confirm-exit');
        if (!modal) {
            done();
            return;
        }
        var uns = modal && modal.querySelector('[data-unsaved]');
        if (uns) {
            uns.hidden = false;
        }
        if (modal) {
            modal.hidden = false;
        }
        var ok = $('admin-confirm-exit-ok');
        var cancel = $('admin-confirm-exit-cancel');
        function cleanup() {
            if (modal) {
                modal.hidden = true;
            }
            if (ok) {
                ok.onclick = null;
            }
            if (cancel) {
                cancel.onclick = null;
            }
        }
        if (ok) {
            ok.onclick = function () {
                cleanup();
                workspace.dirty = false;
                done();
            };
        }
        if (cancel) {
            cancel.onclick = cleanup;
        }
    }

    function onLogin() {
        fetchNui('admin/assets/scan', {}).then(function (r) {
            if (r.ok && r.assets) {
                window.__jpSlotAssetLib = r.assets;
            }
        });
    }

    function onOpenAdmin(_payload) {
        workspace = createDefaultWorkspace();
        selectedKey = 'master';
        viewMode = 'master';
        buildLeftNav();
        buildRight();
        renderCenter();
        fetchNui('admin/preset/get', { id: ($('studio-preset-name') && $('studio-preset-name').value) || 'default' }).then(
            function (r) {
                if (r.ok && r.data) {
                    if (r.data.master) {
                        workspace.master = r.data.master;
                    }
                    if (r.data.effects) {
                        workspace.effects = r.data.effects;
                    }
                    renderCenter();
                }
                if (window.jpSlotApplyI18n) {
                    window.jpSlotApplyI18n();
                }
            }
        );
    }

    window.JpSlotAdminStudio = {
        onLogin: onLogin,
        onOpenAdmin: onOpenAdmin,
        markDirty: markDirty,
    };

    window.JpSlotTryConfirmDirtyExit = function (done) {
        tryConfirmExit(done || function () {});
    };
})();
