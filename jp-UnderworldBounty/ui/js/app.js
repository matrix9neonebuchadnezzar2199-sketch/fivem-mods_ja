/* global GetParentResourceName */

(function () {
  const hud = document.getElementById('hud-bounty');
  const hudLabel = document.getElementById('hud-bounty-label');
  const notifyStack = document.getElementById('notify-stack');
  const mgRoot = document.getElementById('minigame');
  const mgTitle = document.getElementById('mg-title');
  const mgDesc = document.getElementById('mg-desc');
  const mgBody = document.getElementById('mg-body');
  const mgStatus = document.getElementById('mg-status');

  let mgTimer = null;
  let mgCleanup = null;

  function resName() {
    try {
      return GetParentResourceName();
    } catch (e) {
      return 'jp-UnderworldBounty';
    }
  }

  function postMinigame(ok) {
    fetch(`https://${resName()}/ub_minigame_result`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({ ok: !!ok }),
    });
  }

  function clearMinigame() {
    if (mgTimer) {
      clearInterval(mgTimer);
      mgTimer = null;
    }
    if (mgCleanup) {
      mgCleanup();
      mgCleanup = null;
    }
    mgBody.innerHTML = '';
    mgStatus.textContent = '';
  }

  function pushNotify(msg, typ) {
    if (!notifyStack) return;
    const t = typ === 'error' || typ === 'success' || typ === 'info' ? typ : 'info';
    const el = document.createElement('div');
    el.className = 'notify-item notify-item--' + t;
    el.textContent = msg || '';
    notifyStack.appendChild(el);
    while (notifyStack.children.length > 6) {
      notifyStack.removeChild(notifyStack.firstChild);
    }
    setTimeout(() => {
      if (el.parentNode === notifyStack) notifyStack.removeChild(el);
    }, 5200);
  }

  function runLockpick(payload) {
    const ms = payload.lockpickMs || 8000;
    let done = false;
    const finish = (ok) => {
      if (done) return;
      done = true;
      clearMinigame();
      postMinigame(ok);
    };
    mgDesc.textContent = '緑ゾーンで SPACE を押す（英語UIでは同様）';
    const wrap = document.createElement('div');
    wrap.className = 'mg-bar-wrap';
    const greenW = 28;
    const greenLo = 4 + Math.random() * Math.max(0, 88 - greenW - 4);
    const greenHi = greenLo + greenW;
    const zone = document.createElement('div');
    zone.className = 'mg-target-zone';
    zone.style.left = greenLo + '%';
    zone.style.width = greenW + '%';
    wrap.appendChild(zone);
    const marker = document.createElement('div');
    marker.className = 'mg-bar';
    wrap.appendChild(marker);
    mgBody.appendChild(wrap);
    let pos = 0;
    let dir = 1;
    const speed = 3.2;
    mgTimer = setInterval(() => {
      pos += dir * speed;
      if (pos >= 88 || pos <= 0) dir *= -1;
      marker.style.width = pos + '%';
    }, 40);
    mgStatus.textContent = 'タイミングを合わせて SPACE';
    const onKey = (e) => {
      if (e.code !== 'Space') return;
      e.preventDefault();
      const hit = pos >= greenLo && pos <= greenHi;
      window.removeEventListener('keydown', onKey);
      finish(hit);
    };
    window.addEventListener('keydown', onKey);
    mgCleanup = () => window.removeEventListener('keydown', onKey);
    setTimeout(() => finish(false), ms);
  }

  function runHack(payload) {
    const steps = payload.hackSteps || 5;
    const keys = ['KeyW', 'KeyA', 'KeyS', 'KeyD'];
    let seq = [];
    for (let i = 0; i < steps; i++) seq.push(keys[Math.floor(Math.random() * keys.length)]);
    mgDesc.textContent = '表示順にキーを入力';
    const box = document.createElement('div');
    box.className = 'mg-keys';
    box.textContent = seq.map((k) => k.replace('Key', '')).join(' ');
    mgBody.appendChild(box);
    let idx = 0;
    mgStatus.textContent = payload.success || '入力中…';
    const onKey = (e) => {
      if (seq[idx] === e.code) {
        idx++;
        if (idx >= seq.length) {
          window.removeEventListener('keydown', onKey);
          clearMinigame();
          postMinigame(true);
        }
      } else {
        window.removeEventListener('keydown', onKey);
        clearMinigame();
        postMinigame(false);
      }
    };
    window.addEventListener('keydown', onKey);
    mgCleanup = () => window.removeEventListener('keydown', onKey);
  }

  function runTimingWheel(payload) {
    const ms = payload.timingWheelMs || 9000;
    let done = false;
    const finish = (ok) => {
      if (done) return;
      done = true;
      clearMinigame();
      postMinigame(ok);
    };
    const span = 52;
    const startAngle = Math.random() * (360 - span);
    let needle = Math.random() * 360;
    const speed = 125;
    mgDesc.textContent = payload.descTimingWheel || '';
    const wrap = document.createElement('div');
    wrap.className = 'mg-wheel-wrap';
    const wheel = document.createElement('div');
    wheel.className = 'mg-wheel';
    const disk = document.createElement('div');
    disk.className = 'mg-wheel-disk';
    disk.style.background = `conic-gradient(from 0deg, #2a2226 0deg, #2a2226 ${startAngle}deg, rgba(40, 180, 90, 0.92) ${startAngle}deg, rgba(40, 180, 90, 0.92) ${startAngle + span}deg, #2a2226 ${startAngle + span}deg, #2a2226 360deg)`;
    const hub = document.createElement('div');
    hub.className = 'mg-wheel-hub';
    const needleEl = document.createElement('div');
    needleEl.className = 'mg-wheel-needle';
    wheel.appendChild(disk);
    wheel.appendChild(needleEl);
    wheel.appendChild(hub);
    wrap.appendChild(wheel);
    mgBody.appendChild(wrap);
    needleEl.style.transform = `rotate(${needle}deg)`;
    const inArc = () => {
      const n = ((needle % 360) + 360) % 360;
      const s = ((startAngle % 360) + 360) % 360;
      const rel = (n - s + 360) % 360;
      return rel >= 0 && rel <= span;
    };
    mgStatus.textContent = payload.statusTimingWheel || '';
    const tick = () => {
      needle = (((needle + speed * 0.044) % 360) + 360) % 360;
      needleEl.style.transform = `rotate(${needle}deg)`;
    };
    mgTimer = setInterval(tick, 44);
    const onKey = (e) => {
      if (e.code !== 'Space') return;
      e.preventDefault();
      window.removeEventListener('keydown', onKey);
      finish(inArc());
    };
    window.addEventListener('keydown', onKey);
    mgCleanup = () => window.removeEventListener('keydown', onKey);
    setTimeout(() => finish(false), ms);
  }

  function runBrute(payload) {
    const need = payload.bruteHits || 12;
    let done = false;
    const finish = (ok) => {
      if (done) return;
      done = true;
      window.removeEventListener('keydown', onKey);
      clearMinigame();
      postMinigame(ok);
    };
    mgDesc.textContent = 'SPACE を連打';
    const wrap = document.createElement('div');
    wrap.className = 'mg-bar-wrap';
    const bar = document.createElement('div');
    bar.className = 'mg-bar';
    wrap.appendChild(bar);
    mgBody.appendChild(wrap);
    let hits = 0;
    const onKey = (e) => {
      if (e.code !== 'Space') return;
      e.preventDefault();
      hits++;
      bar.style.width = Math.min(100, (hits / need) * 100) + '%';
      if (hits >= need) finish(true);
    };
    window.addEventListener('keydown', onKey);
    mgCleanup = () => window.removeEventListener('keydown', onKey);
    const ms = payload.lockpickMs || 8000;
    setTimeout(() => {
      if (!done && hits < need) finish(false);
    }, ms + 4000);
  }

  function openMinigame(payload) {
    clearMinigame();
    mgRoot.classList.remove('mg-hidden');
    const kind = payload.kind;
    if (kind === 'lockpick') {
      mgTitle.textContent = payload.titleLock || 'Lockpick';
      runLockpick(payload);
    } else if (kind === 'hacking') {
      mgTitle.textContent = payload.titleHack || 'Hack';
      runHack(payload);
    } else if (kind === 'brute') {
      mgTitle.textContent = payload.titleBrute || 'Force';
      runBrute(payload);
    } else if (kind === 'timing_wheel') {
      mgTitle.textContent = payload.titleTimingWheel || 'Timing';
      runTimingWheel(payload);
    } else {
      postMinigame(true);
    }
  }

  window.addEventListener('message', (event) => {
    const d = event.data;
    if (!d || !d.action) return;
    if (d.action === 'bountyHud') {
      if (d.active) {
        hud.classList.remove('hud-hidden');
        hudLabel.textContent = d.label || '';
      } else {
        hud.classList.add('hud-hidden');
      }
    }
    if (d.action === 'toast') {
      pushNotify(d.message, 'info');
    }
    if (d.action === 'notify') {
      pushNotify(d.message, d.typ || 'info');
    }
    if (d.action === 'openMinigame') {
      openMinigame(d.payload || {});
    }
    if (d.action === 'closeMinigame') {
      clearMinigame();
      mgRoot.classList.add('mg-hidden');
    }
  });
})();
