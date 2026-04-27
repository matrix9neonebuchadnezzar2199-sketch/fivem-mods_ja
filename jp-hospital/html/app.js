/* jp-hospital NUI */
(function () {
    const app = document.getElementById('app');
    const diffView = document.getElementById('diffView');
    const gameView = document.getElementById('gameView');
    const diffButtons = document.getElementById('diffButtons');
    const btnDiffCancel = document.getElementById('btnDiffCancel');
    const toast = document.getElementById('toast');
    const successFlash = document.getElementById('successFlash');
    const karteNo = document.getElementById('karteNo');
    const symptom = document.getElementById('symptom');
    const diagnosis = document.getElementById('diagnosis');
    const requiredMeds = document.getElementById('requiredMeds');
    const medList = document.getElementById('medList');
    const btnPack = document.getElementById('btnPack');
    const btnQuit = document.getElementById('btnQuit');
    const comboN = document.getElementById('comboN');
    const totalG = document.getElementById('totalG');
    const dayReport = document.getElementById('dayReport');
    const dayClose = document.getElementById('dayClose');
    const repK = document.getElementById('repK');
    const repMaxC = document.getElementById('repMaxC');
    const repTot = document.getElementById('repTot');
    const repMin = document.getElementById('repMin');

    var currentSession = null; // { id, requiredIds, rows }
    var expectedIds = []; // 正解ID（多集合比較用配列）
    var toastT = 0;

    function getName() {
        try {
            if (typeof GetParentResourceName === 'function') {
                return GetParentResourceName();
            }
        } catch (e) { /* empty */ }
        return 'jp-hospital';
    }

    function errMsgForShift(reason) {
        if (reason === 'noplayer') {
            return 'QBXで認識できません（qbx_core・キャラの読込を確認）';
        }
        if (reason === 'nokarte') {
            return '出題庫が空です（kartes_*.lua 読込を確認）';
        }
        if (reason === 'noconfig') {
            return '難易度設定に失敗しました';
        }
        return '勤務を開始できません';
    }

    function postcb(path, data) {
        return fetch('https://' + getName() + '/' + path, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data || {}),
        }).catch(function () {
            showToast('NUI 通信に失敗しました', true);
        });
    }

    function showToast(msg, isWarn) {
        toast.classList.remove('hidden');
        toast.classList.toggle('warn', !!isWarn);
        toast.textContent = msg;
        if (toastT) {
            clearTimeout(toastT);
        }
        toastT = setTimeout(function () {
            toast.classList.add('hidden');
        }, 1500);
    }

    function idMultisetEqual(a, b) {
        if (!a || !b || a.length !== b.length) {
            return false;
        }
        var c = {};
        var d = {};
        a.forEach(function (x) { c[x] = (c[x] || 0) + 1; });
        b.forEach(function (x) { d[x] = (d[x] || 0) + 1; });
        var k;
        for (k in c) {
            if (c[k] !== (d[k] || 0)) {
                return false;
            }
        }
        for (k in d) {
            if (d[k] !== (c[k] || 0)) {
                return false;
            }
        }
        return true;
    }

    function getSelectedIds() {
        var boxes = medList.querySelectorAll('input[type="checkbox"][data-mid]');
        var s = [];
        for (var i = 0; i < boxes.length; i += 1) {
            if (boxes[i].checked) {
                s.push(boxes[i].getAttribute('data-mid'));
            }
        }
        return s;
    }

    function setPhaseDiff() {
        if (diffView) {
            diffView.classList.remove('hidden');
        }
        if (gameView) {
            gameView.classList.add('hidden');
        }
    }

    function setPhaseGame() {
        if (diffView) {
            diffView.classList.add('hidden');
        }
        if (gameView) {
            gameView.classList.remove('hidden');
        }
    }

    function renderDifficulties(list) {
        if (!diffButtons) {
            return;
        }
        diffButtons.innerHTML = '';
        (list || []).forEach(function (d) {
            if (!d || !d.id) {
                return;
            }
            var b = document.createElement('button');
            b.type = 'button';
            b.className = 'btn-diff';
            b.setAttribute('data-diff-id', d.id);
            b.innerHTML = '<span class="btn-diff-label">' + (d.label || d.id) + '</span>' + (d.description
                ? '<span class="btn-diff-desc">' + d.description + '</span>'
                : '');
            b.addEventListener('click', function (e) {
                e.preventDefault();
                postcb('hospitalSelectDifficulty', { id: d.id });
            });
            diffButtons.appendChild(b);
        });
    }

    function renderKarte(p) {
        if (!p) {
            return;
        }
        var no = p.karteNo != null ? p.karteNo : 1;
        karteNo.textContent = '#' + no;
        symptom.textContent = p.symptom || '—';
        diagnosis.textContent = p.diagnosis || '—';
        requiredMeds.innerHTML = '';
        var req = p.requiredMeds || [];
        expectedIds = req.map(function (m) { return m.id; });
        req.forEach(function (m) {
            var li = document.createElement('li');
            li.textContent = (m.icon || '') + ' ' + (m.name || m.id);
            requiredMeds.appendChild(li);
        });
        comboN.textContent = String(p.combo != null ? p.combo : 0);
        totalG.textContent = '$' + String(p.totalReward != null ? p.totalReward : 0);

        medList.innerHTML = '';
        var rows = p.rightListMeds || [];
        rows.forEach(function (m) {
            if (!m || !m.id) {
                return;
            }
            var row = document.createElement('div');
            row.className = 'med-row';
            var cb = document.createElement('input');
            cb.type = 'checkbox';
            cb.setAttribute('data-mid', m.id);
            var ico = document.createElement('span');
            ico.className = 'med-ico';
            ico.textContent = m.icon || '💊';
            var nm = document.createElement('span');
            nm.className = 'med-name';
            nm.textContent = m.name || m.id;
            row.appendChild(cb);
            row.appendChild(ico);
            row.appendChild(nm);
            medList.appendChild(row);
        });

        currentSession = { id: p.sessionId, rows: rows.length };
    }

    function doPack() {
        if (!currentSession || !currentSession.id) {
            showToast('カルテデータが無いです。', true);
            return;
        }
        var sel = getSelectedIds();
        if (!idMultisetEqual(sel, expectedIds)) {
            showToast('正しい組み合わせではありません', true);
            return;
        }
        postcb('hospitalKarteSubmit', { sessionId: currentSession.id, selectedIds: sel });
    }

    function showSuccessAndNext() {
        successFlash.classList.remove('hidden');
        successFlash.classList.add('ok');
        setTimeout(function () {
            successFlash.classList.add('hidden');
            successFlash.classList.remove('ok');
            postcb('hospitalRequestNextKarte', {});
        }, 800);
    }

    btnPack.addEventListener('click', function (e) {
        e.preventDefault();
        doPack();
    });
    btnQuit.addEventListener('click', function (e) {
        e.preventDefault();
        postcb('hospitalEndShift', {});
    });
    dayClose.addEventListener('click', function (e) {
        e.preventDefault();
        dayReport.classList.add('hidden');
        postcb('hospitalDayReportClose', {});
    });
    if (btnDiffCancel) {
        btnDiffCancel.addEventListener('click', function (e) {
            e.preventDefault();
            postcb('hospitalDifficultyCancel', {});
        });
    }

    window.addEventListener('message', function (ev) {
        var d = ev.data;
        if (!d || !d.type) {
            return;
        }
        switch (d.type) {
            case 'open': {
                app.classList.remove('hidden');
                dayReport.classList.add('hidden');
                var pl = d.payload;
                if (pl && pl.difficulties && pl.difficulties.length) {
                    renderDifficulties(pl.difficulties);
                    setPhaseDiff();
                } else {
                    setPhaseGame();
                }
                break;
            }
            case 'beginGame':
                setPhaseGame();
                break;
            case 'shiftStartFailed': {
                var f = d.payload || {};
                showToast(errMsgForShift(f.reason), true);
                break;
            }
            case 'karteData':
                renderKarte(d.payload);
                break;
            case 'verify': {
                var p = d.payload;
                if (p && p.ok) {
                    comboN.textContent = String(p.combo != null ? p.combo : 0);
                    totalG.textContent = '$' + String(p.totalReward != null ? p.totalReward : 0);
                    showSuccessAndNext();
                } else {
                    if (p && p.combo != null) {
                        comboN.textContent = String(p.combo);
                    }
                    if (p && p.totalReward != null) {
                        totalG.textContent = '$' + String(p.totalReward);
                    }
                    showToast('正しい組み合わせではありません', true);
                }
                break;
            }
            case 'dayReport': {
                var r = d.payload || {};
                repK.textContent = String(r.karteCount != null ? r.karteCount : 0);
                repMaxC.textContent = String(r.maxCombo != null ? r.maxCombo : 0);
                repTot.textContent = '$' + String(r.totalReward != null ? r.totalReward : 0);
                repMin.textContent = String(r.minutes != null ? r.minutes : 0);
                app.classList.add('hidden');
                dayReport.classList.remove('hidden');
                dayReport.setAttribute('aria-hidden', 'false');
                break;
            }
            case 'dayReportClose':
                dayReport.classList.add('hidden');
                break;
            case 'dayReportEsc':
                if (!dayReport.classList.contains('hidden')) {
                    dayReport.classList.add('hidden');
                    postcb('hospitalDayReportClose', {});
                }
                break;
            case 'forceClose':
            case 'jobEnding':
                app.classList.add('hidden');
                break;
            default:
                break;
        }
    });
})();
