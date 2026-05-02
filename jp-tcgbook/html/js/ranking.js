/**
 * ランキングタブ（M5 骨格）
 */
(function (global) {
  const api = global.api;

  function tf(key, vars) {
    return global.I18n && global.I18n.tf ? global.I18n.tf(key, vars) : key;
  }

  function $(sel, root) {
    return (root || document).querySelector(sel);
  }

  function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, (c) =>
      ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]),
    );
  }

  function playerUnknownLabel() {
    return global.I18n && global.I18n.t ? global.I18n.t('player.unknown') : '不明なプレイヤー';
  }

  function renderPlayerNameInnerHtml(displayName) {
    const has = displayName != null && String(displayName).trim() !== '';
    if (has) {
      return `<span class="player-name-inner">${escapeHtml(String(displayName))}</span>`;
    }
    return (
      `<span class="player-name-inner"><span class="player-name-unknown">${escapeHtml(playerUnknownLabel())}</span></span>`
    );
  }

  function renderPlayerNameCellHtml(displayName) {
    return `<div class="player-name">${renderPlayerNameInnerHtml(displayName)}</div>`;
  }

  /** @param {string} [rankCode] @param {string} [badge] */
  function renderRankBadgeCell(rankCode, badge) {
    if (!rankCode || !badge) {
      return '<span class="rank-badge-empty">—</span>';
    }
    const safeRank = escapeHtml(rankCode);
    const safeBadge = escapeHtml(badge);
    const upperRank = safeRank.toUpperCase();
    return (
      `<span class="rank-badge-cell" title="${safeBadge}">` +
      `<img class="rank-badge" src="assets/ranc/${safeBadge}.png" alt="${upperRank}" ` +
      `onerror="this.style.display='none';var n=this.nextElementSibling;if(n)n.style.display='inline-block';">` +
      `<span class="rank-badge-fallback" style="display:none;">${upperRank}</span>` +
      `</span>`
    );
  }

  function tierDisplayName(rankCode) {
    if (!rankCode) return '—';
    const key = 'rank.' + rankCode;
    if (global.I18n && typeof global.I18n.t === 'function') {
      const tr = global.I18n.t(key);
      if (tr !== key) return tr;
    }
    return String(rankCode).toUpperCase();
  }

  function initialState() {
    return {
      loaded: false,
      loading: false,
      success: false,
      season: 'evergreen',
      top: [],
      my_info: null,
      my_in_top: false,
      around_me: [],
      my_citizenid: null,
    };
  }

  global.Ranking = {
    state: initialState(),

    onBookOpened() {
      this.state = initialState();
      const loadEl = $('.ranking-loading');
      const emptyEl = $('.ranking-empty');
      const sumEl = $('.ranking-my-summary');
      const tbody = $('.ranking-rows');
      if (loadEl) loadEl.hidden = true;
      if (emptyEl) emptyEl.hidden = true;
      if (sumEl) {
        sumEl.hidden = true;
        sumEl.textContent = '';
      }
      if (tbody) tbody.textContent = '';
    },

    ensureFetched() {
      if (!(global.AppState.ui && global.AppState.ui.enable_ranking_ui)) return;
      if (this.state.loaded || this.state.loading) return;
      this.fetch();
    },

    fetch() {
      if (!(global.AppState.ui && global.AppState.ui.enable_ranking_ui)) return;
      this.state.loading = true;
      const loadEl = $('.ranking-loading');
      const emptyEl = $('.ranking-empty');
      if (loadEl) loadEl.hidden = false;
      if (emptyEl) emptyEl.hidden = true;
      if (api && typeof api.requestRankingData === 'function') {
        api.requestRankingData();
      }
    },

    onData(payload) {
      this.state.loading = false;
      const loadEl = $('.ranking-loading');
      if (loadEl) loadEl.hidden = true;

      if (!payload || !payload.success) {
        this.state.loaded = true;
        this.state.success = false;
        const msg =
          (payload && payload.error) ||
          (global.I18n && global.I18n.t ? global.I18n.t('app_err_ranking') : 'ランキングを取得できませんでした');
        if (typeof global.jpTcgbookShowError === 'function') {
          global.jpTcgbookShowError(msg);
        }
        this.render();
        return;
      }

      this.state = Object.assign(this.state, {
        loaded: true,
        success: true,
        season: payload.season || 'evergreen',
        top: Array.isArray(payload.top) ? payload.top : [],
        my_info: payload.my_info || null,
        my_in_top: !!payload.my_in_top,
        around_me: Array.isArray(payload.around_me) ? payload.around_me : [],
        my_citizenid: payload.my_citizenid || null,
      });
      this.render();
    },

    buildDisplayRows() {
      const out = [];
      const top = Array.isArray(this.state.top) ? this.state.top : [];
      for (let i = 0; i < top.length; i++) {
        out.push({ kind: 'normal', row: top[i], rank: i + 1 });
      }
      const around = Array.isArray(this.state.around_me) ? this.state.around_me : [];
      if (!this.state.my_in_top && around.length > 0) {
        out.push({ kind: 'separator' });
        const mi = this.state.my_info;
        const myRank = mi && typeof mi.rank === 'number' ? mi.rank : null;
        const myId = this.state.my_citizenid;
        let myIdx = -1;
        if (myId) {
          myIdx = around.findIndex((r) => r && r.citizenid === myId);
        }
        for (let j = 0; j < around.length; j++) {
          const r = around[j];
          let rank = '—';
          if (myRank != null && myIdx >= 0) {
            rank = myRank + (j - myIdx);
          }
          out.push({ kind: 'normal', row: r, rank });
        }
      }
      return out;
    },

    renderMySummary() {
      const wrap = $('.ranking-my-summary');
      if (!wrap) return;
      const mi = this.state.my_info;
      const myId = this.state.my_citizenid;
      if (!mi || !myId || !this.state.success) {
        wrap.hidden = true;
        wrap.textContent = '';
        return;
      }
      const top = Array.isArray(this.state.top) ? this.state.top : [];
      const around = Array.isArray(this.state.around_me) ? this.state.around_me : [];
      let my =
        top.find((r) => r && r.citizenid === myId) || around.find((r) => r && r.citizenid === myId);
      if (!my) {
        wrap.hidden = true;
        wrap.textContent = '';
        return;
      }
      wrap.hidden = false;
      const lv = my.pvp_level != null ? my.pvp_level : 0;
      const xp = my.pvp_exp != null ? my.pvp_exp : 0;
      const st = my.pvp_win_streak != null ? my.pvp_win_streak : 0;
      const rating = mi.rating != null ? mi.rating : my.rating;
      const tierBadgeHtml = renderRankBadgeCell(mi.rank_code, mi.badge);
      const tierName = escapeHtml(tierDisplayName(mi.rank_code));
      const disp =
        my.display_name !== undefined && my.display_name !== null
          ? my.display_name
          : mi.display_name;
      const nameRow = `<div class="my-rank-name-row"><div class="player-name">${renderPlayerNameInnerHtml(disp)}</div></div>`;
      wrap.innerHTML = `
        <div class="my-rank-num">${tf('rank_my_rank', { rank: mi.rank, total: mi.total })}</div>
        ${nameRow}
        <div class="my-rank-tier-row">
          <span class="my-rank-tier-label">${escapeHtml(tf('rank_my_tier_label'))}</span>
          <span class="my-rank-tier">${tierBadgeHtml}<span class="my-rank-tier-name">${tierName}</span></span>
        </div>
        <div class="my-rank-detail">${tf('rank_my_detail', { rating, lv, exp: xp, streak: st })}</div>
      `;
    },

    render() {
      const tbody = $('.ranking-rows');
      const emptyEl = $('.ranking-empty');
      if (!tbody) return;

      tbody.textContent = '';
      this.renderMySummary();

      if (this.state.loading) {
        if (emptyEl) emptyEl.hidden = true;
        return;
      }

      if (!this.state.loaded) {
        if (emptyEl) emptyEl.hidden = true;
        return;
      }

      if (!this.state.success) {
        if (emptyEl) emptyEl.hidden = false;
        return;
      }
      if (emptyEl) emptyEl.hidden = true;

      const rows = this.buildDisplayRows();
      if (rows.length === 0) {
        if (emptyEl) emptyEl.hidden = false;
      } else {
        const frag = document.createDocumentFragment();
        for (let i = 0; i < rows.length; i++) {
          frag.appendChild(this.makeRow(rows[i]));
        }
        tbody.appendChild(frag);
      }
      if (typeof global.applyMarqueeIfOverflow === 'function') {
        global.applyMarqueeIfOverflow(document.getElementById('tab-ranking'));
      }
    },

    makeRow(item) {
      const tr = document.createElement('tr');
      if (item.kind === 'separator') {
        tr.className = 'ranking-row-sep';
        const td = document.createElement('td');
        td.colSpan = 7;
        td.textContent = global.I18n && global.I18n.t ? global.I18n.t('rank_sep') : '⋯ ⋯ ⋯';
        tr.appendChild(td);
        return tr;
      }

      const r = item.row || {};
      const myId = this.state.my_citizenid;
      if (myId && r.citizenid === myId) {
        tr.classList.add('ranking-row-me');
      }

      function addTd(className, text) {
        const td = document.createElement('td');
        if (className) td.className = className;
        td.textContent = text;
        tr.appendChild(td);
      }

      addTd('rank-no', String(item.rank));
      const tdTier = document.createElement('td');
      tdTier.className = 'rank-tier';
      tdTier.innerHTML = renderRankBadgeCell(r.rank_code, r.badge);
      tr.appendChild(tdTier);
      const tdName = document.createElement('td');
      tdName.className = 'rank-name-col';
      tdName.innerHTML = renderPlayerNameCellHtml(r.display_name);
      tr.appendChild(tdName);
      addTd('rating', String(r.rating != null ? r.rating : '—'));
      addTd('lv', String(r.pvp_level != null ? r.pvp_level : '—'));
      addTd('exp', String(r.pvp_exp != null ? r.pvp_exp : '—'));
      addTd('streak', String(r.pvp_win_streak != null ? r.pvp_win_streak : 0));

      return tr;
    },
  };
})(window);
