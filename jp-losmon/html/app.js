(function () {
  'use strict';

  var res = 'jp-losmon';
  var state = null;
  var tick = null;
  var currentAction = 'idle';
  var actionTimer = null;
  var miniDrag = { active: false, sx: 0, sy: 0, sl: 0, st: 0, acc: 0 };
  var lastDragPx = 0;
  var tickerTimer = null;
  var tickerList = [];
  var tickerIdx = 0;
  var lastTickerKey = '';

  function post(name, data) {
    return fetch('https://' + res + '/' + name, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data || {})
    });
  }

  function nuiUrl(file) {
    if (!file) { return 'about:blank'; }
    return 'nui://' + res + '/html/img/' + file;
  }

  function secondsToHMS(sec) {
    var s = Math.max(0, Math.floor(sec));
    var m = Math.floor(s / 60);
    var r = s % 60;
    return (m < 10 ? '0' : '') + m + ':' + (r < 10 ? '0' : '') + r;
  }

  function elapseText(sec) {
    var s = Math.max(0, Math.floor(sec));
    var d = Math.floor(s / 86400);
    var h = Math.floor((s % 86400) / 3600);
    if (d > 0) { return d + '日' + h + '時間'; }
    h = Math.floor(s / 3600);
    var m = Math.floor((s % 3600) / 60);
    if (h > 0) { return h + '時間' + m + '分'; }
    return m + '分';
  }

  function setSpriteDiv(div, def, act) {
    if (!def) { return; }
    act = act || 'idle';
    if (def.mode === 'egg' && def.egg) {
      var f = (state && state.pet && state.pet.phase === 'egg' && (state.hatchLeftSec != null) && state.hatchLeftSec < 12) ? (def.crack && def.crack[act] ? def.crack[act] : def.egg.idle) : (def.egg[act] || def.egg.idle);
      div.style.backgroundImage = 'url(' + nuiUrl(f) + ')';
      return;
    }
    if (def.set) {
      var f2 = def.set[act] || def.set.idle;
      div.style.backgroundImage = 'url(' + nuiUrl(f2) + ')';
    }
  }

  function setSprite(spr, def, act) {
    setSpriteDiv(spr, def, act);
  }

  function applySpriteWithMode(div, def, isMini) {
    if (!def) { return; }
    if (isMini) {
      div.classList.add('mini-sprite');
    }
    if (def.mode === 'id' && def.set) {
      div.style.backgroundSize = (isMini ? 256 : 512) + 'px ' + (isMini ? 64 : 128) + 'px';
    } else {
      div.style.backgroundSize = (isMini ? 256 : 512) + 'px ' + (isMini ? 64 : 128) + 'px';
    }
  }

  function getSpriteSet() {
    return state && state.sprite;
  }

  function showFlash() {
    var f = document.getElementById('flash-fx');
    if (!f) { return; }
    f.classList.remove('on');
    void f.offsetWidth;
    f.classList.add('on');
  }

  var TIP = '💡 ミニペットの位置はドラッグで移動できます';

  function buildTickerMessages(st) {
    if (!st) { return [TIP]; }
    if (st.showEgg) { return [TIP, '🥚 卵の種類をタップしてはじめよう']; }
    var p = st.pet;
    if (!p) { return [TIP]; }
    if (p.phase === 'dead') { return [TIP, 'また新しい出会いを /losmon から']; }
    if (p.phase === 'sick') { return ['🚨 病気です！ごはんと掃除で治療してください', TIP]; }
    var h = (p.stats && p.stats.hunger) | 0;
    if (h < 35) { return ['⚠ お腹が空いています！ごはんをあげましょう', TIP]; }
    if (h >= 88) { return ['😊 お腹いっぱいで満足そうです', TIP]; }
    var g = (st.config && st.config.growth) | 0; if (!g) { g = 14400; }
    var tP = (st.config && st.config.tickerNearPhase) | 0; if (!tP) { tP = 600; }
    var maxNear = Math.min(tP, (g * 0.2) | 0);
    var hl = (st.hatchLeftSec | 0);
    var np = (st.nextPhaseInSec | 0);
    var tH = (st.config && st.config.tickerNearHatch) | 0; if (!tH) { tH = 90; }
    if ((hl > 0 && hl <= tH) || (np > 0 && np <= maxNear)) {
      return ['✨ もうすぐ進化しそうです…', TIP];
    }
    return [TIP];
  }

  function restartTickerAnim() {
    var el = document.getElementById('ticker-marq');
    if (!el) { return; }
    el.style.animation = 'none';
    void el.offsetWidth;
    el.style.animation = '';
  }

  function applyTickerSlide() {
    if (!tickerList.length) { return; }
    var el = document.getElementById('ticker-marq');
    if (!el) { return; }
    el.textContent = tickerList[tickerIdx % tickerList.length];
    restartTickerAnim();
  }

  function applyTickerIfNeeded() {
    if (!state || !state.expanded) {
      if (tickerTimer) { clearInterval(tickerTimer); tickerTimer = null; }
      lastTickerKey = '';
      return;
    }
    var list = buildTickerMessages(state);
    var key = list.join('‖');
    if (key === lastTickerKey) { return; }
    lastTickerKey = key;
    if (tickerTimer) { clearInterval(tickerTimer); tickerTimer = null; }
    tickerList = list;
    tickerIdx = 0;
    applyTickerSlide();
    if (tickerList.length > 1) {
      tickerTimer = setInterval(function () { tickerIdx += 1; applyTickerSlide(); }, 7000);
    }
  }

  function render() {
    if (!state) { return; }
    if (state.showEgg) {
      document.getElementById('egg-select').classList.remove('hidden');
      buildEggList();
    } else {
      document.getElementById('egg-select').classList.add('hidden');
    }
    var m = state.pet;
    var ex = state.expanded;
    document.getElementById('main-expanded').classList.toggle('hidden', !ex);
    if (m && m.phase !== 'dead' && !state.showEgg) {
      document.getElementById('mini-pet').classList.remove('hidden');
      posMini();
      setSprite(document.getElementById('mini-sprite'), getSpriteSet(), currentAction);
      applySpriteWithMode(document.getElementById('mini-sprite'), getSpriteSet(), true);
      document.getElementById('mini-n').textContent = state.charName || 'ぼく';
      var h = m.stats ? (m.stats.hunger || 0) : 0;
      document.getElementById('mini-bh').style.width = h + '%';
    } else {
      document.getElementById('mini-pet').classList.add('hidden');
    }
    var mpetE = document.getElementById('mini-pet');
    if (mpetE) {
      mpetE.classList.toggle('mini--drag', Boolean(ex && m && !state.showEgg && m.phase !== 'dead'));
      /* 拡大パネルより下のレイヤーにし、お世話操作を最優先。常駐時は前面のまま */
      mpetE.style.zIndex = (ex && !state.showEgg) ? '10020' : '10040';
    }
    if (m && m.stats) {
      document.getElementById('b-h').style.width = m.stats.hunger + '%';
      document.getElementById('b-m').style.width = m.stats.mood + '%';
      document.getElementById('b-s').style.width = m.stats.stamina + '%';
      document.getElementById('b-c').style.width = m.stats.clean + '%';
      document.getElementById('v-h').textContent = Math.floor(m.stats.hunger);
      document.getElementById('v-m').textContent = Math.floor(m.stats.mood);
      document.getElementById('v-s').textContent = Math.floor(m.stats.stamina);
      document.getElementById('v-c').textContent = Math.floor(m.stats.clean);
    }
    if (m) {
      document.getElementById('meta-n').textContent = '名前: ' + (state.charName || 'ぼく');
      document.getElementById('meta-st').textContent = '成長: ' + (state.stageLabel || '—') + (m.evolutionId && m.evolutionId !== 'egg' && m.evolutionId !== 'grave' ? ' (' + (state.evName || '') + ')' : '');
      document.getElementById('meta-time').textContent = '経過: ' + elapseText(state.elapseSec || 0);
      var sickE = m.phase === 'sick';
      document.getElementById('meta-sick').hidden = !sickE;
      if (m.phase === 'sick' && (state.deathLeftSec | 0) > 0) {
        document.getElementById('meta-dhead').hidden = false;
        document.getElementById('meta-dhead').textContent = '悪化まで: ' + elapseText(state.deathLeftSec) + '（残: ' + secondsToHMS(state.deathLeftSec) + '）';
      } else {
        document.getElementById('meta-dhead').hidden = true;
      }
    }
    var htxt = document.getElementById('hatch-text');
    if (htxt) {
      htxt.textContent = (m && m.phase === 'egg' && (state.hatchLeftSec | 0) > 0) ? ('あと ' + secondsToHMS(state.hatchLeftSec)) : '';
    }
    var spr = document.getElementById('sprite-el');
    setSprite(spr, getSpriteSet(), m && m.phase === 'egg' ? 'idle' : currentAction);
    applySpriteWithMode(spr, getSpriteSet(), false);
    spr.classList.remove('grayscale-imp');
    if (m && m.phase === 'dead') {
      document.getElementById('btn-new').hidden = false;
      document.getElementById('btn-travel').hidden = true;
    } else {
      document.getElementById('btn-new').hidden = true;
      document.getElementById('btn-travel').hidden = m && m.phase && m.phase !== 'egg' ? false : true;
    }
    var c = state.cooldowns || {};
    ['feed', 'play', 'sleep', 'clean'].forEach(function (a) {
      var b = document.querySelector('.cd[data-cd=\"' + a + '\"]');
      if (!b) { return; }
      var t = c[a] | 0;
      b.textContent = t > 0 ? ('(' + t + 's)') : '';
    });
    ['feed', 'play', 'sleep', 'clean'].forEach(function (a) {
      var t = c[a] | 0;
      var b = document.querySelector('.care[data-a=\"' + a + '\"]');
      if (!b) { return; }
      var sck = m && m.phase === 'sick' && (a === 'play' || a === 'sleep');
      b.disabled = t > 0 || sck;
      b.classList.toggle('disabled', t > 0 || sck);
    });
    applyTickerIfNeeded();
  }

  function posMini() {
    var p = (state && state.miniPos) || { x: 0.85, y: 0.8 };
    var el = document.getElementById('mini-pet');
    if (!el) { return; }
    if (p.x < 0.05) { p.x = 0.05; }
    if (p.y < 0.05) { p.y = 0.05; }
    el.style.left = Math.max(0, (window.innerWidth * p.x) - 60) + 'px';
    el.style.top = Math.max(0, (window.innerHeight * p.y) - 120) + 'px';
  }

  function buildEggList() {
    var g = document.getElementById('egg-list');
    g.innerHTML = '';
    (state && state.eggList ? state.eggList : [
      { id: 'green', name: '竜の卵' },
      { id: 'cute', name: '精霊の卵' },
      { id: 'navy', name: '獣の卵' }
    ]).forEach(function (e) {
      var d = document.createElement('div');
      d.className = 'egg-cell';
      d.setAttribute('data-egg', e.id);
      var i = document.createElement('div');
      i.className = 'egg-img';
      i.style.backgroundImage = 'url(' + nuiUrl('01_egg_idle.png') + ')';
      d.appendChild(i);
      var t = document.createElement('div');
      t.className = 't';
      t.textContent = e.name;
      t.style.fontSize = '0.6rem';
      t.style.color = '#ccc';
      d.appendChild(t);
      d.addEventListener('click', function () {
        var nm = document.getElementById('new-name');
        post('selectEgg', { eggType: e.id, name: nm && nm.value ? String(nm.value) : 'ぼく' });
      });
      g.appendChild(d);
    });
  }

  function onMsg(e) {
    var d = e.data;
    if (!d || !d.type) { return; }
    if (d.type === 'state') {
      state = d;
      if (!d.eggList) {
        d.eggList = [
          { id: 'green', name: '竜の卵' },
          { id: 'cute', name: '精霊の卵' },
          { id: 'navy', name: '獣の卵' }
        ];
      }
      if (d.resName) { res = d.resName; }
      render();
      if (d.expanded) {
        nuiSetFocus(1);
      } else {
        nuiSetFocus(0);
      }
    } else if (d.type === 'playAction' && d.name) {
      currentAction = d.name;
      if (d.name === 'feed' || d.name === 'play') { currentAction = d.name === 'feed' ? 'eat' : 'happy'; }
      if (d.name === 'sleep') { currentAction = 'sleep'; }
      if (d.name === 'clean') { currentAction = 'happy'; }
      if (d.sprite) { state.sprite = d.sprite; }
      if (d.pet) { state.pet = d.pet; }
      setSprite(document.getElementById('sprite-el'), getSpriteSet(), currentAction);
      setSprite(document.getElementById('mini-sprite'), getSpriteSet(), currentAction);
      showFlash();
      if (actionTimer) { clearTimeout(actionTimer); }
      actionTimer = setTimeout(function () { currentAction = 'idle'; render(); }, 2800);
    } else if (d.type === 'zukan' && d.open === true) {
      if (d.zukan) { state = state || {}; state.zukan = d.zukan; }
      document.getElementById('zukan-modal').classList.remove('hidden');
      var zb = document.getElementById('zukan-body');
      zb.innerHTML = '';
      var have = (state && state.zukan) || [];
      if (typeof have.indexOf !== 'function') { have = Object.keys(have || {}); }
      var m = (state && state.zukanMap) || {};
      var order = (state && state.zukanIds) || Object.keys(m);
      order.forEach(function (k) {
        if (!m[k]) { return; }
        var c = document.createElement('div');
        c.className = 'zk-cell' + (have.indexOf(k) < 0 ? ' zk-sil' : '');
        c.style.backgroundImage = 'url(' + nuiUrl(m[k]) + ')';
        c.title = k;
        zb.appendChild(c);
      });
    } else if (d.type === 'zukan' && d.open === false) {
      document.getElementById('zukan-modal').classList.add('hidden');
    }
  }
  function nuiSetFocus(on) { /* ゲーム側。プレースホルダ。 */ }
  window.addEventListener('message', onMsg);

  document.getElementById('close-ex').addEventListener('click', function () {
    post('closeExpanded', {});
  });
  document.getElementById('btn-zukan').addEventListener('click', function () {
    post('zukan', { open: true });
  });
  document.getElementById('zukan-close').addEventListener('click', function () {
    post('zukan', { open: false });
  });
  document.getElementById('btn-travel').addEventListener('click', function () {
    document.getElementById('travel-confirm').classList.remove('hidden');
  });
  document.getElementById('travel-yes').addEventListener('click', function () {
    document.getElementById('travel-confirm').classList.add('hidden');
    post('travel', { yes: true, confirmed: true });
  });
  document.getElementById('travel-no').addEventListener('click', function () {
    document.getElementById('travel-confirm').classList.add('hidden');
  });
  document.getElementById('btn-new').addEventListener('click', function () { post('newPetAfterDead', {}); });
  document.querySelectorAll('.care[data-a=\"feed\"],.care[data-a=\"play\"],.care[data-a=\"sleep\"],.care[data-a=\"clean\"]').forEach(function (b) {
    b.addEventListener('click', function () {
      var a = b.getAttribute('data-a');
      if (a && a !== 'openTravel') { post('action', { name: a }); }
    });
  });
  document.querySelectorAll('.care.travel, .care[data-a=\"openTravel\"]').forEach(function (b) {
    b.addEventListener('click', function () { document.getElementById('btn-travel').click(); });
  });

  var mpet = document.getElementById('mini-pet');
  mpet.addEventListener('mousedown', function (ev) {
    if (!state || !state.expanded || state.showEgg) { return; }
    if (state.pet && state.pet.phase === 'dead') { return; }
    if (!mpet.classList.contains('mini--drag')) { return; }
    ev.preventDefault();
    miniDrag.active = true; miniDrag.sx = ev.clientX; miniDrag.sy = ev.clientY; miniDrag.acc = 0;
  });
  window.addEventListener('mousemove', function (ev) {
    if (!miniDrag.active) { return; }
    if (!state || !state.expanded) { return; }
    var dx = ev.clientX - miniDrag.sx, dy = ev.clientY - miniDrag.sy;
    var el = mpet; var r = el.getBoundingClientRect();
    el.style.left = (r.left + dx) + 'px';
    el.style.top = (r.top + dy) + 'px';
    miniDrag.sx = ev.clientX; miniDrag.sy = ev.clientY;
    miniDrag.acc += Math.sqrt(dx * dx + dy * dy);
  });
  window.addEventListener('mouseup', function (ev) {
    if (!miniDrag.active) { return; }
    miniDrag.active = false;
    lastDragPx = miniDrag.acc;
    if (!state || !state.expanded) { return; }
    if (lastDragPx < 3) { return; }
    var el = mpet, r = el.getBoundingClientRect();
    var rw = window.innerWidth || 1, rh = window.innerHeight || 1;
    var rx = (r.left + 60) / rw;
    var ry = (r.top + 100) / rh;
    rx = Math.max(0.01, Math.min(0.99, rx));
    ry = Math.max(0.01, Math.min(0.99, ry));
    post('setMiniPos', { x: rx, y: ry, dragPx: lastDragPx });
  });

  if (tick) { clearInterval(tick); }
  tick = setInterval(function () {
    if (state && state.pet && state.pet.stats && (state.pet.stats.hunger|0) > 0) {
      var c = (state && state.config) || { statDecay: 0.07 };
      if (c.statDecay) {
        state.pet.stats.hunger = Math.max(0, (state.pet.stats.hunger || 0) - c.statDecay);
        state.pet.stats.mood = Math.max(0, (state.pet.stats.mood || 0) - c.statDecay);
        state.pet.stats.stamina = Math.max(0, (state.pet.stats.stamina || 0) - c.statDecay);
        state.pet.stats.clean = Math.max(0, (state.pet.stats.clean || 0) - c.statDecay);
        render();
      }
    }
  }, 60000);
  window.addEventListener('resize', posMini);
})();
