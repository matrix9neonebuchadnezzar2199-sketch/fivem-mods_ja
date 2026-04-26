/* global GetParentResourceName */
(() => {
  const root = document.getElementById('root');
  const meterSection = document.getElementById('meterSection');
  const statsSection = document.getElementById('statsSection');
  const statsDivider = document.getElementById('statsDivider');
  const summary = document.getElementById('summary');

  const vCurrentFare = document.getElementById('v_current_fare');
  const vCurrentDistance = document.getElementById('v_current_distance');

  const vTotalCustomers = document.getElementById('v_total_customers');
  const vTotalEarnings = document.getElementById('v_total_earnings');
  const vTotalDistance = document.getElementById('v_total_distance');

  const vSCustomers = document.getElementById('v_s_customers');
  const vSEarnings = document.getElementById('v_s_earnings');
  const vSDistance = document.getElementById('v_s_distance');

  let endShiftTimeout = null;

  function setHidden(el, on) {
    if (!el) return;
    el.classList.toggle('is-hidden', !!on);
  }

  function setPosition(pos) {
    if (!pos) return;
    root.dataset.position = pos;
    if (pos === 'top-left') {
      root.style.transformOrigin = 'top left';
      root.style.left = '18px';
      root.style.top = '18px';
      root.style.right = 'auto';
    } else if (pos === 'top-right') {
      root.style.transformOrigin = 'top right';
      root.style.right = '18px';
      root.style.top = '18px';
      root.style.left = 'auto';
    }
  }

  function setLabels(payload) {
    if (!payload || typeof payload !== 'object') return;
    const map = [
      ['title', 'hud_title'],
      ['hud_title', 'title'], // support either key
      ['k_current_fare', 'hud_current_fare'],
      ['k_current_distance', 'hud_current_distance'],
      ['k_total_customers', 'hud_total_customers'],
      ['k_total_earnings', 'hud_total_earnings'],
      ['k_total_distance', 'hud_total_distance'],
      ['summaryTitle', 'hud_summary_title'],
      ['summaryGreat', 'hud_summary_great_job'],
      ['k_s_customers', 'hud_total_customers'],
      ['k_s_earnings', 'hud_total_earnings'],
      ['k_s_distance', 'hud_total_distance'],
    ];
    for (const [id, k] of map) {
      const el = document.getElementById(id);
      if (!el) continue;
      if (payload[k]) el.textContent = String(payload[k]);
    }
  }

  function showRoot(on) {
    root.classList.toggle('is-hidden', !on);
  }

  function resetHudDom() {
    vCurrentFare.textContent = '$0';
    vCurrentDistance.textContent = '0.0 mi';
    vTotalCustomers.textContent = '0';
    vTotalEarnings.textContent = '$0';
    vTotalDistance.textContent = '0.0 mi';
  }

  window.addEventListener('message', (event) => {
    const msg = event.data;
    if (!msg || !msg.action) return;

    // qbx 互換（メーター）
    if (msg.action === 'openMeter') {
      const on = !!msg.toggle;
      setHidden(meterSection, !on);
      return;
    }
    if (msg.action === 'updateMeter' && msg.meterData) {
      const d = msg.meterData;
      vCurrentFare.textContent = '$' + String(d.currentFare ?? 0);
      vCurrentDistance.textContent = (Number(d.distanceTraveled) || 0).toFixed(1) + ' mi';
      return;
    }
    if (msg.action === 'resetMeter') {
      vCurrentFare.textContent = '$0';
      vCurrentDistance.textContent = '0.0 mi';
      return;
    }

    if (msg.action === 'setRootVisible') {
      showRoot(!!msg.visible);
      return;
    }

    if (msg.action === 'setLayout') {
      if (msg.hud) {
        setPosition(msg.hud.position);
        if (typeof msg.hud.scale === 'number') {
          document.documentElement.style.setProperty('--scale', String(msg.hud.scale));
        }
        setHidden(meterSection, !msg.hud.showMeter);
        setHidden(statsSection, !msg.hud.showStats);
        setHidden(statsDivider, !msg.hud.showMeter || !msg.hud.showStats);
      }
      if (msg.labels) setLabels(msg.labels);
      return;
    }

    if (msg.action === 'setLabels') {
      setLabels(msg);
      return;
    }

    if (msg.action === 'startShift') {
      if (endShiftTimeout) {
        clearTimeout(endShiftTimeout);
        endShiftTimeout = null;
      }
      setHidden(summary, true);
      showRoot(true);
      resetHudDom();
      if (msg.mode) {
        // 将来: mode 表記
      }
      return;
    }

    if (msg.action === 'toggleMeter') {
      // qbx: メーター計測トグル
      // HUDでは「メーター表示中」扱いにしておく（可視性は start/open に任せる）
      return;
    }

    if (msg.action === 'updateStats' && msg.data) {
      const c = msg.data;
      vTotalCustomers.textContent = String(c.customers ?? 0);
      vTotalEarnings.textContent = '$' + String(c.totalEarnings ?? 0);
      vTotalDistance.textContent = (Number(c.totalDistance) || 0).toFixed(1) + ' mi';
      return;
    }

    if (msg.action === 'endShift' && msg.data) {
      const c = msg.data;
      vSCustomers.textContent = String(c.customers ?? 0);
      vSEarnings.textContent = '$' + String(c.totalEarnings ?? 0);
      vSDistance.textContent = (Number(c.totalDistance) || 0).toFixed(1) + ' mi';
      setHidden(summary, false);
      endShiftTimeout = setTimeout(() => {
        setHidden(summary, true);
        showRoot(false);
        resetHudDom();
        endShiftTimeout = null;
      }, 3000);
      return;
    }
  });

  // NUI debug
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      // no focus by default; ignore
    }
  });
})();
