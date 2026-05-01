/**
 * jp-tcgbook 管理者 UI
 */
(function () {
  var N = window.NUI;

  var FOLDER_ORDER = ['character', 'monster', 'item', 'uncategorized'];
  var FOLDER_LABEL = {
    character: 'キャラクター',
    monster: 'モンスター',
    item: 'アイテム',
    uncategorized: '未分類',
  };

  var state = {
    masters: [],
    assets: { paths: [] },
    audit: [],
    selectedId: null,
    isNew: false,
    baseline: null,
    pins: [null, null, null],
    collapsed: {},
    pendingDeleteId: null,
  };

  function $(id) {
    return document.getElementById(id);
  }

  function folderOfPath(path) {
    var p = path || '';
    if (p.indexOf('assets/cards/character/') !== -1) return 'character';
    if (p.indexOf('assets/cards/monster/') !== -1) return 'monster';
    if (p.indexOf('assets/cards/item/') !== -1) return 'item';
    return 'uncategorized';
  }

  function filteredTreeMasters() {
    var q = ($('admTreeSearch').value || '').trim().toLowerCase();
    var rk = $('admFilterRank').value;
    var tp = $('admFilterType').value;
    return state.masters.filter(function (m) {
      if (rk && m.rank !== rk) return false;
      if (tp && m.type !== tp) return false;
      if (!q) return true;
      var id = (m.card_id || '').toLowerCase();
      var nm = (m.name || '').toLowerCase();
      return id.indexOf(q) !== -1 || nm.indexOf(q) !== -1;
    });
  }

  function filteredCompareMasters() {
    var q = ($('admCmpSearch').value || '').trim().toLowerCase();
    var rk = $('admCmpRank').value;
    var tp = $('admCmpType').value;
    return state.masters.filter(function (m) {
      if (rk && m.rank !== rk) return false;
      if (tp && m.type !== tp) return false;
      if (!q) return true;
      var id = (m.card_id || '').toLowerCase();
      var nm = (m.name || '').toLowerCase();
      return id.indexOf(q) !== -1 || nm.indexOf(q) !== -1;
    });
  }

  function snapshotForm() {
    return JSON.stringify({
      card_id: ($('admCardId').value || '').trim(),
      name: ($('admName').value || '').trim(),
      no: $('admNo').value,
      image_path: $('admImagePath').value || '',
      rank: $('admRank').value,
      type: $('admType').value,
      description: $('admDesc').value || '',
      stat_top: $('admStatTop').value,
      stat_right: $('admStatRight').value,
      stat_bottom: $('admStatBottom').value,
      stat_left: $('admStatLeft').value,
    });
  }

  function isDirty() {
    if (!$('admFormWrap').hidden && state.baseline !== null) {
      return snapshotForm() !== state.baseline;
    }
    return false;
  }

  function setDirtyBadge() {
    $('admDirtyBadge').style.display = isDirty() ? 'inline' : 'none';
  }

  function confirmLeave() {
    if (!isDirty()) return true;
    return window.confirm('未保存の変更があります。破棄してよいですか？');
  }

  function renderAudit() {
    var host = $('admAuditLog');
    if (!host) return;
    host.innerHTML = '';
    (state.audit || []).forEach(function (row) {
      var div = document.createElement('div');
      div.className = 'adm-audit-row';
      var t = row.created_at || '';
      div.textContent =
        t + ' | ' + (row.action || '') + ' | ' + (row.card_id || '—') + ' | ' + (row.actor_uid || '').slice(0, 24);
      host.appendChild(div);
    });
  }

  function renderTree() {
    var wrap = $('admTreeWrap');
    wrap.innerHTML = '';
    var list = filteredTreeMasters();
    var byFolder = {};
    FOLDER_ORDER.forEach(function (k) {
      byFolder[k] = [];
    });
    list.forEach(function (m) {
      var fk = m.folder_key || folderOfPath(m.image_path);
      if (!byFolder[fk]) byFolder[fk] = [];
      byFolder[fk].push(m);
    });

    FOLDER_ORDER.forEach(function (fk) {
      var items = byFolder[fk] || [];
      if (!items.length) return;

      var fold = document.createElement('div');
      fold.className = 'adm-tree-folder' + (state.collapsed[fk] ? ' collapsed' : '');
      fold.textContent = FOLDER_LABEL[fk] || fk;
      fold.dataset.folder = fk;
      fold.addEventListener('click', function () {
        state.collapsed[fk] = !state.collapsed[fk];
        renderTree();
      });

      var ul = document.createElement('div');
      ul.className = 'adm-tree-list';
      if (state.collapsed[fk]) ul.hidden = true;

      items.forEach(function (m) {
        var div = document.createElement('div');
        div.className = 'adm-tree-item';
        if (state.selectedId === m.card_id) div.classList.add('selected');
        div.textContent = (m.name || m.card_id) + ' (' + m.card_id + ')';
        div.addEventListener('click', function () {
          if (!confirmLeave()) return;
          selectMaster(m.card_id, false);
        });
        ul.appendChild(div);
      });

      wrap.appendChild(fold);
      wrap.appendChild(ul);
    });
  }

  function imgUrlForPath(imagePath) {
    var p = (imagePath || '').trim();
    if (!p) return '';
    if (/^https?:\/\//i.test(p)) return p;
    return '../' + p.replace(/^\/+/, '');
  }

  function refreshPreview() {
    var p = $('admImagePath').value || '';
    var img = $('admImgPreview');
    var fb = $('admImgFallback');
    var url = imgUrlForPath(p);
    if (!url) {
      img.hidden = true;
      img.removeAttribute('src');
      fb.style.display = 'block';
      return;
    }
    img.onerror = function () {
      img.hidden = true;
      fb.style.display = 'block';
    };
    img.onload = function () {
      img.hidden = false;
      fb.style.display = 'none';
    };
    img.src = url;
  }

  function populateImageSelect() {
    var sel = $('admImagePath');
    var cur = sel.value;
    sel.innerHTML = '';
    var o0 = document.createElement('option');
    o0.value = '';
    o0.textContent = '— 画像なし —';
    sel.appendChild(o0);
    (state.assets.paths || []).forEach(function (rel) {
      var o = document.createElement('option');
      o.value = rel;
      o.textContent = rel;
      sel.appendChild(o);
    });
    if (cur && Array.prototype.some.call(sel.options, function (opt) { return opt.value === cur; })) {
      sel.value = cur;
    }
  }

  function masterById(cardId) {
    for (var i = 0; i < state.masters.length; i++) {
      if (state.masters[i].card_id === cardId) return state.masters[i];
    }
    return null;
  }

  function selectMaster(cardId, isNew) {
    state.selectedId = cardId;
    state.isNew = !!isNew;
    $('admMainEmpty').hidden = true;
    $('admFormWrap').hidden = false;

    if (isNew) {
      $('admCardId').disabled = false;
      $('admBtnDelete').disabled = true;
      clearFormValues();
      N.send('adminSuggestNo', {});
    } else {
      $('admBtnDelete').disabled = false;
      var m = masterById(cardId);
      if (!m) return;
      $('admCardId').disabled = true;
      fillForm(m);
    }
    state.baseline = snapshotForm();
    hideValWarn();
    clearWarnings();
    setDirtyBadge();
    renderTree();
    renderCompare();
  }

  function clearFormValues() {
    $('admCardId').value = '';
    $('admName').value = '';
    $('admNo').value = '1';
    $('admImagePath').value = '';
    $('admRank').value = 'C';
    $('admType').value = 'free';
    $('admDesc').value = '';
    $('admStatTop').value = '5';
    $('admStatRight').value = '5';
    $('admStatBottom').value = '5';
    $('admStatLeft').value = '5';
    $('admCardIdHint').textContent = '英数字と _ のみ、1〜32 文字';
    $('admCardIdHint').className = 'adm-id-status';
    populateImageSelect();
    refreshPreview();
  }

  function fillForm(m) {
    $('admCardId').value = m.card_id || '';
    $('admName').value = m.name || '';
    $('admNo').value = String(m.no != null ? m.no : 1);
    $('admRank').value = m.rank || 'C';
    $('admType').value = m.type || 'free';
    $('admDesc').value = m.description || '';
    $('admStatTop').value = String(m.stat_top != null ? m.stat_top : 5);
    $('admStatRight').value = String(m.stat_right != null ? m.stat_right : 5);
    $('admStatBottom').value = String(m.stat_bottom != null ? m.stat_bottom : 5);
    $('admStatLeft').value = String(m.stat_left != null ? m.stat_left : 5);
    populateImageSelect();
    var ip = m.image_path || '';
    if (ip && !Array.prototype.some.call($('admImagePath').options, function (opt) { return opt.value === ip; })) {
      var ox = document.createElement('option');
      ox.value = ip;
      ox.textContent = ip + '（DB）';
      $('admImagePath').appendChild(ox);
    }
    $('admImagePath').value = ip;
    refreshPreview();
  }

  function hideValWarn() {
    $('admValList').hidden = true;
    $('admValList').innerHTML = '';
  }

  function clearWarnings() {
    $('admWarnList').hidden = true;
    $('admWarnList').innerHTML = '';
  }

  function showValidation(errs) {
    var el = $('admValList');
    el.hidden = !errs.length;
    el.innerHTML = errs.map(function (e) { return '<div>' + e + '</div>'; }).join('');
  }

  function showWarnings(warns) {
    var el = $('admWarnList');
    el.hidden = !warns.length;
    el.innerHTML = warns.map(function (w) { return '<div>⚠ ' + w + '</div>'; }).join('');
  }

  function localValidate() {
    var errs = [];
    var id = ($('admCardId').value || '').trim();
    if (!id.match(/^[a-zA-Z0-9_]{1,32}$/)) errs.push('card_id は英数字とアンダースコアのみ、1〜32 文字');
    var st = +$('admStatTop').value;
    var sr = +$('admStatRight').value;
    var sb = +$('admStatBottom').value;
    var sl = +$('admStatLeft').value;
    [st, sr, sb, sl].forEach(function (v, i) {
      var lab = ['上', '右', '下', '左'][i];
      if (!Number.isInteger(v) || v < 1 || v > 10) errs.push(lab + 'の数値は 1〜10 の整数');
    });
    return errs;
  }

  function renderCompare() {
    var host = $('admCmpList');
    host.innerHTML = '';
    filteredCompareMasters().forEach(function (m) {
      var pinIx = state.pins.indexOf(m.card_id);
      var row = document.createElement('div');
      row.className = 'adm-mini-card';
      if (pinIx !== -1) row.classList.add('pinned');

      var img = document.createElement('img');
      img.className = 'adm-mini-img';
      img.alt = '';
      var url = imgUrlForPath(m.image_path);
      if (url) img.src = url;
      img.onerror = function () {
        img.style.visibility = 'hidden';
      };

      var mid = document.createElement('div');
      mid.className = 'adm-mini-stats';
      mid.innerHTML =
        '<strong>' +
        (m.name || '') +
        '</strong><br>' +
        m.card_id +
        '<br>' +
        m.rank +
        ' / ' +
        (m.type === 'shitei' ? '指定' : 'フリー') +
        '<br>' +
        '↑' +
        m.stat_top +
        ' →' +
        m.stat_right +
        ' ↓' +
        m.stat_bottom +
        ' ←' +
        m.stat_left;

      var actions = document.createElement('div');
      actions.className = 'adm-mini-actions';
      var b1 = document.createElement('button');
      b1.type = 'button';
      b1.className = 'btn';
      b1.textContent = '選択';
      b1.addEventListener('click', function () {
        if (!confirmLeave()) return;
        selectMaster(m.card_id, false);
      });
      var b2 = document.createElement('button');
      b2.type = 'button';
      b2.className = 'btn';
      b2.textContent = 'ピン';
      b2.addEventListener('click', function () {
        togglePin(m.card_id);
      });
      actions.appendChild(b1);
      actions.appendChild(b2);

      row.appendChild(img);
      row.appendChild(mid);
      row.appendChild(actions);
      host.appendChild(row);
    });
    renderPins();
  }

  function togglePin(cardId) {
    var ix = state.pins.indexOf(cardId);
    if (ix !== -1) {
      state.pins[ix] = null;
    } else {
      var empty = state.pins.indexOf(null);
      if (empty === -1) {
        state.pins[2] = cardId;
      } else {
        state.pins[empty] = cardId;
      }
    }
    renderCompare();
  }

  function renderPins() {
    document.querySelectorAll('.adm-pin-slot').forEach(function (slot) {
      var i = +slot.dataset.slot;
      var cid = state.pins[i];
      slot.classList.toggle('filled', !!cid);
      if (!cid) {
        slot.textContent = 'ピン' + (i + 1) + '（空）';
      } else {
        var m = masterById(cid);
        slot.textContent = m ? m.card_id : cid;
      }
      slot.onclick = function () {
        if (cid) {
          state.pins[i] = null;
          renderCompare();
        }
      };
    });
  }

  function mergeMasterRow(row) {
    var found = false;
    state.masters = state.masters.map(function (m) {
      if (m.card_id === row.card_id) {
        found = true;
        return row;
      }
      return m;
    });
    if (!found) state.masters.push(row);
  }

  function onAdminData(msg) {
    if (!msg || !msg.kind) return;
    var kind = msg.kind;
    if (!msg.success) {
      if (kind !== 'checkCardId') window.alert(msg.error || 'エラー');
      if (kind === 'checkCardId') {
        $('admCardIdHint').textContent = msg.error || '検証エラー';
        $('admCardIdHint').className = 'adm-id-status bad';
      }
      return;
    }
    var d = msg.data;

    if (kind === 'bootstrap') {
      state.masters = d.masters || [];
      state.assets = d.assets || { paths: [] };
      state.audit = d.audit || [];
      populateImageSelect();
      renderTree();
      renderCompare();
      renderAudit();
      return;
    }
    if (kind === 'checkCardId') {
      var hint = $('admCardIdHint');
      if (!d.valid) {
        hint.textContent = d.error || 'card_id が不正です';
        hint.className = 'adm-id-status bad';
        return;
      }
      if (d.exists) {
        hint.textContent = '既に DB に存在します（上書き保存になります）';
        hint.className = 'adm-id-status bad';
      } else {
        hint.textContent = '新規として保存できます';
        hint.className = 'adm-id-status';
      }
      return;
    }
    if (kind === 'impact') {
      var el = $('admDelImpact');
      el.innerHTML =
        '所持インスタンス: <strong>' +
        d.owned +
        '</strong> 件<br>デッキ内スロット: <strong>' +
        d.deck_slots +
        '</strong> 件<br>削除するとこれらも消えます。';
      return;
    }
    if (kind === 'saveCard') {
      mergeMasterRow(d.row);
      $('admLastSaved').textContent = '最終保存: ' + (d.saved_at || '');
      state.selectedId = d.row.card_id;
      state.isNew = false;
      $('admMainEmpty').hidden = true;
      $('admFormWrap').hidden = false;
      $('admCardId').disabled = true;
      $('admBtnDelete').disabled = false;
      fillForm(d.row);
      hideValWarn();
      showWarnings(d.warnings || []);
      state.baseline = snapshotForm();
      setDirtyBadge();
      renderTree();
      renderCompare();
      N.send('adminListAudit', { limit: 15 });
      return;
    }
    if (kind === 'deleteCard') {
      state.masters = state.masters.filter(function (m) {
        return m.card_id !== d.card_id;
      });
      $('admModalDelete').hidden = true;
      state.pendingDeleteId = null;
      state.selectedId = null;
      $('admFormWrap').hidden = true;
      $('admMainEmpty').hidden = false;
      state.baseline = null;
      setDirtyBadge();
      N.send('adminListAudit', { limit: 15 });
      renderTree();
      renderCompare();
      return;
    }
    if (kind === 'listAudit') {
      state.audit = d || [];
      renderAudit();
      return;
    }
    if (kind === 'suggestNo') {
      $('admNo').value = String(d.no || 1);
      state.baseline = snapshotForm();
      setDirtyBadge();
      return;
    }
  }

  function wire() {
    $('admBtnNew').addEventListener('click', function () {
      if (!confirmLeave()) return;
      state.selectedId = null;
      selectMaster(null, true);
    });

    $('admBtnClose').addEventListener('click', function () {
      if (!confirmLeave()) return;
      N.send('adminClose', {});
    });

    $('admBtnSave').addEventListener('click', function () {
      hideValWarn();
      var errs = localValidate();
      if (errs.length) {
        showValidation(errs);
        return;
      }
      var payload = {
        card_id: ($('admCardId').value || '').trim(),
        name: ($('admName').value || '').trim(),
        no: parseInt($('admNo').value, 10),
        image_path: $('admImagePath').value || '',
        rank: $('admRank').value,
        type: $('admType').value,
        description: $('admDesc').value || '',
        stat_top: parseInt($('admStatTop').value, 10),
        stat_right: parseInt($('admStatRight').value, 10),
        stat_bottom: parseInt($('admStatBottom').value, 10),
        stat_left: parseInt($('admStatLeft').value, 10),
      };
      N.send('adminSaveCard', payload);
    });

    $('admBtnDelete').addEventListener('click', function () {
      var id = ($('admCardId').value || '').trim();
      if (!id || state.isNew) return;
      state.pendingDeleteId = id;
      $('admDelText').textContent = 'card_id 「' + id + '」をデータベースから削除します。';
      $('admDelImpact').innerHTML = '影響件数を取得中…';
      $('admModalDelete').hidden = false;
      N.send('adminImpact', { card_id: id });
    });

    $('admDelCancel').addEventListener('click', function () {
      $('admModalDelete').hidden = true;
      state.pendingDeleteId = null;
    });

    $('admDelConfirm').addEventListener('click', function () {
      var id = state.pendingDeleteId;
      if (!id) return;
      if (!window.confirm('本当に削除しますか？（2段階確認）')) return;
      N.send('adminDeleteCard', { card_id: id });
    });

    ['admTreeSearch', 'admFilterRank', 'admFilterType'].forEach(function (id) {
      $(id).addEventListener('input', renderTree);
      $(id).addEventListener('change', renderTree);
    });

    ['admCmpSearch', 'admCmpRank', 'admCmpType'].forEach(function (id) {
      $(id).addEventListener('input', renderCompare);
      $(id).addEventListener('change', renderCompare);
    });

    $('admImagePath').addEventListener('change', function () {
      refreshPreview();
      setDirtyBadge();
    });

    [
      'admCardId',
      'admName',
      'admNo',
      'admRank',
      'admType',
      'admDesc',
      'admStatTop',
      'admStatRight',
      'admStatBottom',
      'admStatLeft',
    ].forEach(function (id) {
      $(id).addEventListener('input', setDirtyBadge);
      $(id).addEventListener('change', setDirtyBadge);
    });

    $('admCardId').addEventListener('blur', function () {
      var id = ($('admCardId').value || '').trim();
      if (!id || $('admCardId').disabled) return;
      N.send('adminCheckCardId', { card_id: id });
    });

    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') {
        if (!$('admModalDelete').hidden) {
          $('admModalDelete').hidden = true;
          state.pendingDeleteId = null;
          return;
        }
        $('admBtnClose').click();
      }
    });
  }

  N.on('adminData', onAdminData);

  N.on('forceClose', function () {
    N.send('adminClose', {});
  });

  document.addEventListener('DOMContentLoaded', function () {
    wire();
    N.send('adminBootstrap', {});
  });
})();
