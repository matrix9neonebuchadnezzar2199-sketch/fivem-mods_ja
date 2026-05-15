(function () {
  const app = document.getElementById('app');
  const toastRoot = document.getElementById('m9-toasts');
  const waveBanner = document.getElementById('m9-wave-banner');
  const partyBlock = document.getElementById('m9-party');
  const partyList = document.getElementById('m9-party-list');
  const partyLabel = document.getElementById('m9-party-label');
  const timerBlock = document.getElementById('m9-timer');
  const timerValue = document.getElementById('m9-timer-value');
  const timerLabel = document.getElementById('m9-timer-label');
  const invBlock = document.getElementById('m9-inventory');
  const invLabel = document.getElementById('m9-inv-label');
  const invTotalLine = document.getElementById('m9-inv-total-line');
  const invRarity = document.getElementById('m9-inv-rarity');

  const STR_FALLBACK = {
    ja: {
      hud_timer_remaining: '残り',
      hud_party_label: 'パーティ',
      hud_inv_label: 'インベントリ',
      hud_inv_total: '合計',
      hud_inv_common: 'C',
      hud_inv_uncommon: 'U',
      hud_inv_rare: 'R',
      hud_inv_legendary: 'L',
      hud_wave_banner: 'WAVE {wave} / {total} — {alive} 体残存',
      hud_leader_badge: '★',
      hud_self_badge: '●',
      hud_event_wave_start: 'ウェーブ {wave} / {total} 開始（敵 {alive} 体）',
      hud_event_wave_cleared: 'ウェーブ {wave} クリア（次まで {label} 秒）',
      hud_event_mission_success: 'ミッション成功',
      hud_event_mission_failed: 'ミッション失敗',
      hud_event_extract_success: '脱出に成功',
      hud_event_countdown: 'ウェーブ開始まで {seconds} 秒',
    },
  };

  let STR = STR_FALLBACK.ja;

  function t(key, params) {
    const s = (STR && STR[key]) || STR_FALLBACK.ja[key] || key;
    if (!params) {
      return s;
    }
    return String(s).replace(/\{(\w+)\}/g, function (_, k) {
      return params[k] != null ? String(params[k]) : '';
    });
  }

  function formatTime(sec) {
    const s = Math.max(0, Math.floor(Number(sec) || 0));
    const m = Math.floor(s / 60);
    const r = s % 60;
    return (m < 10 ? '0' : '') + m + ':' + (r < 10 ? '0' : '') + r;
  }

  function applyLocale(payload) {
    const loc = (payload && payload.locale) || 'ja';
    const pack = STR_FALLBACK[loc] || STR_FALLBACK.ja;
    STR = Object.assign({}, pack, (payload && payload.strings) || {});
  }

  function renderWaveBanner(arena, cfg) {
    if (!cfg.showWaveBanner || !arena || !arena.active) {
      waveBanner.hidden = true;
      waveBanner.textContent = '';
      return;
    }
    waveBanner.hidden = false;
    waveBanner.textContent = t('hud_wave_banner', {
      wave: arena.wave || 0,
      total: arena.totalWaves || 0,
      alive: arena.zombiesAlive || 0,
    });
  }

  function renderParty(members, cfg) {
    if (!cfg.showPartyHP) {
      partyBlock.hidden = true;
      partyList.innerHTML = '';
      return;
    }
    partyBlock.hidden = false;
    partyLabel.textContent = t('hud_party_label');
    partyList.innerHTML = '';
    (members || []).forEach(function (row) {
      const li = document.createElement('li');
      li.className = 'm9-hud__member' + (row.alive === false ? ' m9-hud__member--dead' : '');
      const badge =
        (row.isSelf ? t('hud_self_badge') + ' ' : '') + (row.isLeader ? t('hud_leader_badge') + ' ' : '');
      li.innerHTML =
        '<span class="m9-hud__badge">' +
        badge +
        '</span>' +
        '<span class="m9-hud__member-name">' +
        escapeHtml(row.name || '') +
        '</span>' +
        '<span class="m9-hud__member-meta">' +
        (row.hp != null ? row.hp : 0) +
        '/' +
        (row.maxHp != null ? row.maxHp : 0) +
        ' AP' +
        (row.armor != null ? row.armor : 0) +
        '</span>';
      partyList.appendChild(li);
    });
  }

  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function renderTimer(timerSec, cfg) {
    if (!cfg.showTimer) {
      timerBlock.hidden = true;
      return;
    }
    timerBlock.hidden = false;
    timerValue.textContent = formatTime(timerSec);
    timerLabel.textContent = t('hud_timer_remaining');
  }

  function renderInventory(inv, cfg) {
    if (!cfg.showInventory) {
      invBlock.hidden = true;
      return;
    }
    invBlock.hidden = false;
    invLabel.textContent = t('hud_inv_label');
    const mode = cfg.inventoryMode || 'byRarity';
    const total = (inv && inv.total) || 0;
    if (mode === 'totalOnly') {
      invTotalLine.textContent = t('hud_inv_total') + ' ' + total;
      invRarity.textContent = '';
      return;
    }
    invTotalLine.textContent = t('hud_inv_total') + ' ' + total + ' ';
    if (mode === 'byRarity' && inv && inv.byRarity) {
      const br = inv.byRarity;
      invRarity.innerHTML =
        '<span>' +
        t('hud_inv_common') +
        ' ' +
        (br.common || 0) +
        '</span> <span>' +
        t('hud_inv_uncommon') +
        ' ' +
        (br.uncommon || 0) +
        '</span> <span>' +
        t('hud_inv_rare') +
        ' ' +
        (br.rare || 0) +
        '</span> <span>' +
        t('hud_inv_legendary') +
        ' ' +
        (br.legendary || 0) +
        '</span>';
    } else {
      invRarity.textContent = '';
    }
  }

  function renderState(payload) {
    if (!payload) {
      return;
    }
    const cfg = payload.hudConfig || {};
    renderWaveBanner(payload.arena, cfg);
    renderParty(payload.members, cfg);
    renderTimer(payload.timerSec, cfg);
    renderInventory(payload.inventory, cfg);
  }

  function pushToast(text, variant, ms) {
    const el = document.createElement('div');
    el.className = 'm9-hud__toast' + (variant === 'success' ? ' m9-hud__toast--success' : '') + (variant === 'fail' ? ' m9-hud__toast--fail' : '');
    el.textContent = text;
    toastRoot.appendChild(el);
    window.setTimeout(function () {
      el.remove();
    }, ms || 4500);
  }

  function handleEvent(payload) {
    if (!payload || !payload.kind) {
      return;
    }
    const ms = payload.ms || 4500;
    const k = payload.kind;
    if (k === 'wave_start') {
      pushToast(
        t('hud_event_wave_start', {
          wave: payload.wave || 0,
          total: payload.total || 0,
          alive: payload.alive || 0,
        }),
        'inform',
        ms
      );
    } else if (k === 'wave_cleared') {
      pushToast(
        t('hud_event_wave_cleared', {
          wave: payload.wave || 0,
          label: payload.label || '0',
        }),
        'success',
        ms
      );
    } else if (k === 'mission_success') {
      pushToast(t('hud_event_mission_success'), 'success', ms);
    } else if (k === 'mission_failed') {
      pushToast(t('hud_event_mission_failed'), 'fail', ms);
    } else if (k === 'extract_success') {
      pushToast(t('hud_event_extract_success', { label: payload.label || '' }), 'success', ms);
    } else if (k === 'countdown') {
      pushToast(t('hud_event_countdown', { seconds: payload.seconds || 0 }), 'inform', Math.min(ms, 3200));
    }
  }

  window.addEventListener('message', function (ev) {
    const data = ev.data;
    if (!data || typeof data !== 'object') {
      return;
    }
    const type = data.type;
    const payload = data.payload;
    if (type === 'm9_hud_locale') {
      applyLocale(payload || {});
      return;
    }
    if (type === 'm9_hud_show') {
      app.classList.remove('hidden');
      return;
    }
    if (type === 'm9_hud_hide') {
      app.classList.add('hidden');
      return;
    }
    if (type === 'm9_hud_state') {
      renderState(payload);
      return;
    }
    if (type === 'm9_hud_event') {
      handleEvent(payload || {});
      return;
    }
    if (type === 'open') {
      app.classList.remove('hidden');
    }
    if (type === 'close') {
      app.classList.add('hidden');
    }
  });
})();
