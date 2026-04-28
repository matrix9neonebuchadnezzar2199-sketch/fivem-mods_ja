(function () {
  'use strict';
  var UI_S = 3; /* 画面・文字の拡大倍率（NUI 全体） */

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
  var hatchInterval = null;
  var nameEditMode = false;
  var lvupTimer = null;

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
    if (!div) { return; }
    if (!def) {
      div.style.backgroundImage = 'none';
      return;
    }
    act = act || 'idle';
    if (def.mode === 'egg' && def.egg) {
      var sec = (state && (state.eggShowCrackSec|0)) || 30;
      /* 殻: 直前 N 秒、または 0 以下でまだ phase=卵（Lua の孵化まち）。NUI 先走りで「また通常卵」に戻るのを防ぐ */
      var hL = (state && state.pet && state.pet.phase === 'egg' && (state.hatchLeftSec != null)) ? (state.hatchLeftSec|0) : 99999;
      if (state && state.pet && state.pet.phase === 'egg' && hL <= sec) {
        var cf = def.crack && (def.crack[act] || def.crack.idle);
        if (cf) { div.style.backgroundImage = 'url(' + nuiUrl(cf) + ')'; return; }
      }
      var ef = def.egg[act] || def.egg.idle;
      div.style.backgroundImage = 'url(' + nuiUrl(ef) + ')';
      return;
    }
    if (def.set) {
      var f2;
      if (act === 'play') {
        f2 = def.set.play || def.set.happy || def.set.idle;
      } else if (act === 'clean') {
        /* 掃除を happy に載せると原画差で「アクション毎に別のキャラ」に見える。差分を config.Sprites.*.clean で上書き可 */
        f2 = def.set.clean || def.set.idle;
      } else {
        f2 = def.set[act] || def.set.idle;
      }
      div.style.backgroundImage = 'url(' + nuiUrl(f2) + ')';
    }
  }

  function setSprite(spr, def, act) {
    setSpriteDiv(spr, def, act);
  }

  function applySpriteWithMode(div, def, isMini) {
    if (!div) { return; }
    if (isMini) { div.classList.add('mini-sprite'); }
    if (!def) { return; }
    /* background-size / keyframes: syncSpriteLayout（LCD 枠に合わせ可変） */
  }

  function syncSpriteLayout() {
    var frames = 1;
    if (state && state.config && (state.config.spriteStripFrames|0) > 0) { frames = state.config.spriteStripFrames|0; }
    if (frames < 1) { frames = 1; }
    var mEl = document.getElementById('sprite-el');
    var iEl = document.getElementById('mini-sprite');
    var wM = 200;
    var wI = 120;
    if (mEl) {
      var rw = mEl.getBoundingClientRect();
      wM = Math.max(1, Math.floor(rw.width));
      var hM = Math.max(1, Math.floor(rw.height));
      if (wM < 3) {
        var lcdE = document.getElementById('device-lcd');
        if (lcdE) {
          var b = lcdE.getBoundingClientRect();
          wM = Math.max(20, Math.floor(0.98 * Math.min(b.width, b.height)));
          hM = wM;
        }
      }
      if (frames <= 1) {
        mEl.style.backgroundSize = wM + 'px ' + hM + 'px';
        mEl.classList.remove('sprite-anim');
        mEl.style.animation = 'none';
      } else {
        mEl.classList.add('sprite-anim');
        mEl.style.backgroundSize = (frames * wM) + 'px ' + hM + 'px';
        mEl.style.animation = 'sprite-play 0.8s steps(' + frames + ') infinite';
      }
    }
    if (iEl) {
      var rI = iEl.getBoundingClientRect();
      wI = Math.max(1, Math.floor(rI.width));
      var hI = Math.max(1, Math.floor(rI.height));
      if (wI < 3) {
        var mL = document.getElementById('mini-lcd');
        if (mL) {
          var b2 = mL.getBoundingClientRect();
          wI = hI = Math.max(16, Math.floor(0.98 * Math.min(b2.width, b2.height)));
        }
      }
      if (frames <= 1) {
        iEl.style.backgroundSize = wI + 'px ' + hI + 'px';
        iEl.style.animation = 'none';
      } else {
        iEl.style.backgroundSize = (frames * wI) + 'px ' + hI + 'px';
        iEl.style.animation = 'sprite-min 0.8s steps(' + frames + ') infinite';
      }
    }
    var st = document.getElementById('dyn-sprite-kf');
    if (!st) {
      st = document.createElement('style');
      st.id = 'dyn-sprite-kf';
      document.head.appendChild(st);
    }
    if (frames <= 1) {
      st.textContent = '@keyframes sprite-play{from{background-position:0}to{background-position:0}}@keyframes sprite-min{from{background-position:0}to{background-position:0}}';
    } else {
      st.textContent = '@keyframes sprite-play{from{background-position:0 0}to{background-position:' + (-frames * wM) + 'px 0}}' +
        '@keyframes sprite-min{from{background-position:0 0}to{background-position:' + (-frames * wI) + 'px 0}}';
    }
  }

  function getSpriteSet() {
    return state && state.sprite;
  }

  function liveHatchLeftSec() {
    if (!state) { return 0; }
    if (state._hatchSyncAt == null) { return (state.hatchLeftSec | 0); }
    var elapsed = Math.floor((Date.now() - state._hatchSyncAt) / 1000);
    return Math.max(0, (state._hatchBaseSec | 0) - elapsed);
  }

  function stopHatchCountdownTicker() {
    if (hatchInterval) { clearInterval(hatchInterval); hatchInterval = null; }
  }

  function tickHatchCountdown() {
    if (!state || !state.pet || state.pet.phase !== 'egg' || state._hatchSyncAt == null) {
      stopHatchCountdownTicker();
      return;
    }
    var left = liveHatchLeftSec();
    state.hatchLeftSec = left;
    var htxt = document.getElementById('hatch-text');
    if (htxt) { htxt.textContent = left > 0 ? ('あと ' + secondsToHMS(left)) : ''; }
    setSprite(document.getElementById('sprite-el'), getSpriteSet(), 'idle');
    setSprite(document.getElementById('mini-sprite'), getSpriteSet(), currentAction);
    applySpriteWithMode(document.getElementById('sprite-el'), getSpriteSet(), false);
    applySpriteWithMode(document.getElementById('mini-sprite'), getSpriteSet(), true);
    applyTickerIfNeeded();
    requestAnimationFrame(function () { requestAnimationFrame(syncSpriteLayout); });
    if (left <= 0) { stopHatchCountdownTicker(); }
  }

  function startHatchCountdownTicker() {
    stopHatchCountdownTicker();
    if (!state || !state.pet || state.pet.phase !== 'egg' || state._hatchSyncAt == null) { return; }
    if (liveHatchLeftSec() <= 0) { return; }
    hatchInterval = setInterval(tickHatchCountdown, 1000);
    tickHatchCountdown();
  }

  function showMiniLevelUp() {
    var el = document.getElementById('mini-lvup');
    if (!el) { return; }
    el.classList.remove('lvup-pulse');
    if (lvupTimer) { clearTimeout(lvupTimer); lvupTimer = null; }
    el.hidden = false;
    el.setAttribute('aria-hidden', 'false');
    void el.offsetWidth;
    el.classList.add('lvup-pulse');
    lvupTimer = setTimeout(function () {
      el.classList.remove('lvup-pulse');
      el.hidden = true;
      el.setAttribute('aria-hidden', 'true');
      lvupTimer = null;
    }, 2800);
  }

  function endPetNameEdit(commit) {
    var inp = document.getElementById('meta-n-input');
    var tx = document.getElementById('meta-n-text');
    var pe = document.getElementById('btn-name-edit');
    if (!inp) { return; }
    if (commit) { post('setPetName', { name: (inp && inp.value) || '' }); }
    else { inp.value = (state && state.charName) ? String(state.charName) : 'ぼく'; }
    inp.classList.add('hidden');
    if (tx) { tx.classList.remove('hidden'); }
    if (pe) { pe.classList.remove('hidden'); }
    nameEditMode = false;
  }

  function startPetNameEdit() {
    if (!state || !state.expanded) { return; }
    var inp = document.getElementById('meta-n-input');
    var tx = document.getElementById('meta-n-text');
    var pe = document.getElementById('btn-name-edit');
    if (!inp || !tx) { return; }
    nameEditMode = true;
    inp.value = (state && state.charName) ? String(state.charName) : 'ぼく';
    var nmx = (state.petNameMaxLength | 0) || 12;
    if (nmx < 1) { nmx = 12; }
    inp.setAttribute('maxlength', nmx);
    tx.classList.add('hidden');
    if (pe) { pe.classList.add('hidden'); }
    inp.classList.remove('hidden');
    setTimeout(function () { try { inp.focus(); inp.select(); } catch (e1) { /*  */ } }, 0);
  }

  function updateSickSkulls() {
    var m = state && state.pet;
    var ex = state && state.expanded;
    var skM = document.getElementById('sick-skull-main');
    var skI = document.getElementById('sick-skull-mini');
    var sick = m && m.phase === 'sick';
    if (skM) { skM.hidden = !sick || !ex; skM.setAttribute('aria-hidden', sick && ex ? 'false' : 'true'); }
    if (skI) { skI.hidden = !sick; skI.setAttribute('aria-hidden', sick ? 'false' : 'true'); }
  }

  function showFlash() {
    var f = document.getElementById('flash-fx');
    if (!f) { return; }
    f.classList.remove('on');
    void f.offsetWidth;
    f.classList.add('on');
  }

  function openDebugEvolveModal() {
    if (!state || !state.debugEnabled) { return; }
    var modal = document.getElementById('debug-evolve-modal');
    var list = document.getElementById('debug-evolve-list');
    if (!modal || !list) { return; }
    list.innerHTML = '';
    var targets = state.debugTargets || [];
    var ph = state.pet && state.pet.phase;
    targets.forEach(function (t) {
      var b = document.createElement('button');
      b.type = 'button';
      b.className = 'btn-sec debug-evolve-btn';
      b.textContent = t;
      b.setAttribute('data-target', t);
      if (t === 'sick' && (ph === 'egg' || ph === 'dead' || ph === 'sick')) {
        b.disabled = true;
        b.title = '現在のフェーズでは病気にできません';
      }
      b.addEventListener('click', function () {
        if (b.disabled) { return; }
        post('debugForceEvolve', { target: t });
      });
      list.appendChild(b);
    });
    refreshDebugEvolveStatus();
    modal.classList.remove('hidden');
  }

  function refreshDebugEvolveStatus() {
    var stat = document.getElementById('debug-evolve-status');
    var cancel = document.getElementById('debug-evolve-cancel');
    if (!stat || !cancel) { return; }
    if (state && state.debugForceEvolve) {
      var dfe = state.debugForceEvolve;
      stat.textContent = '⏱ ' + dfe.target + ' に進化まで ' + (dfe.remainSec | 0) + ' 秒';
      stat.hidden = false;
      cancel.hidden = false;
    } else {
      stat.hidden = true;
      cancel.hidden = true;
    }
  }

  var TIP = '💡 ミニペットの位置はドラッグで移動できます';

  function buildTickerMessages(st) {
    if (!st) { return [TIP]; }
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

  function renderPoops() {
    var layer = document.getElementById('poop-layer');
    if (!layer || !state) { return; }
    layer.innerHTML = '';
    var poops = (state.pet && state.pet.poops) || [];
    if (!poops.length) { return; }
    var path = (state.poopSpritePath != null && String(state.poopSpritePath) !== '') ? String(state.poopSpritePath) : 'un.png';
    var posList = [
      { left: '20%', bottom: '8%' },
      { left: '50%', bottom: '5%' },
      { left: '78%', bottom: '10%' }
    ];
    var now = Date.now() / 1000;
    var sickAfter = (state.poopSickAfterSec != null) ? (state.poopSickAfterSec | 0) : 3600;
    for (var i = 0; i < poops.length; i++) {
      var p = poops[i];
      var pos = posList[i] || posList[posList.length - 1];
      var div = document.createElement('div');
      div.className = 'poop';
      div.setAttribute('aria-hidden', 'true');
      div.style.left = pos.left;
      div.style.bottom = pos.bottom;
      div.style.backgroundImage = 'url(' + nuiUrl(path) + ')';
      var elap = now - (Number(p && p.bornAt) || now);
      if (elap > sickAfter * 0.5) {
        div.classList.add('poop-old');
      }
      layer.appendChild(div);
    }
  }

  function render() {
    if (!state) { return; }
    if (state.pet && state.pet.phase === 'egg' && state._hatchSyncAt != null) {
      state.hatchLeftSec = liveHatchLeftSec();
    }
    var m = state.pet;
    var ex = state.expanded;
    var showExp = ex;
    document.getElementById('main-expanded').classList.toggle('hidden', !showExp);
    var mpetE = document.getElementById('mini-pet');
    if (mpetE) {
      /* 拡大表示中もミニを表示。死んだペットだけ is-hidden（初回 /losmon 前は is-ready 未付与のまま CSS で非表示） */
      var showMini = Boolean(m && m.phase !== 'dead');
      if (showMini) {
        mpetE.classList.remove('is-hidden');
        posMini();
        setSprite(document.getElementById('mini-sprite'), getSpriteSet(), currentAction);
        applySpriteWithMode(document.getElementById('mini-sprite'), getSpriteSet(), true);
        var mef = document.getElementById('mini-exp-fill');
        if (mef) {
          var lmaxM = (state.levelMax | 0) || 999;
          var lcurM = (state.level | 0) || 1;
          var epcM = Number(state.expLevelPct);
          if (isNaN(epcM)) { epcM = 0; }
          if (lcurM >= lmaxM) { epcM = 100; }
          mef.style.width = Math.max(0, Math.min(100, epcM)) + '%';
        }
      } else {
        mpetE.classList.add('is-hidden');
      }
      mpetE.classList.toggle('mini--drag', Boolean(ex && m && m.phase !== 'dead'));
      mpetE.style.zIndex = (ex && m) ? '10020' : '10040';
    }
    if (m && m.stats) {
      document.getElementById('b-h').style.width = m.stats.hunger + '%';
      document.getElementById('b-m').style.width = m.stats.mood + '%';
      document.getElementById('b-s').style.width = m.stats.stamina + '%';
      document.getElementById('b-c').style.width = m.stats.clean + '%';
      document.getElementById('v-h').textContent = Math.floor(m.stats.hunger) + '%';
      document.getElementById('v-m').textContent = Math.floor(m.stats.mood) + '%';
      document.getElementById('v-s').textContent = Math.floor(m.stats.stamina) + '%';
      document.getElementById('v-c').textContent = Math.floor(m.stats.clean) + '%';
    }
    if (m) {
      if (!nameEditMode) {
        var mnt = document.getElementById('meta-n-text');
        if (mnt) { mnt.textContent = (state.charName || 'ぼく'); }
        var mni0 = document.getElementById('meta-n-input');
        if (mni0) { mni0.setAttribute('maxlength', String((state.petNameMaxLength | 0) || 12)); }
      }
      var mnl = document.getElementById('meta-lv');
      if (mnl) {
        var lmax = (state.levelMax | 0) || 999;
        var lcur = (state.level | 0) || 1;
        var eTotF = (state.expTotal != null) ? Math.floor(Number(state.expTotal) + 0) : 0;
        if (eTotF < 0) { eTotF = 0; }
        if (lcur >= lmax) {
          mnl.textContent = 'LV ' + lcur + ' (MAX)  ·  累計 EXP ' + eTotF;
        } else {
          var tnx = (state.expToNext != null) ? Math.max(0, Math.floor(Number(state.expToNext) + 0.5)) : 0;
          mnl.textContent = 'LV ' + lcur + '  次: ' + tnx + ' EXP  ·  累計 ' + eTotF;
        }
      }
      var bExp = document.getElementById('b-exp');
      if (bExp) {
        var epc = Number(state.expLevelPct);
        if (isNaN(epc)) { epc = 0; }
        bExp.style.width = Math.max(0, Math.min(100, epc)) + '%';
      }
      var mwk = document.getElementById('meta-walk');
      if (mwk) {
        mwk.textContent = '🚶 ' + ((state.stepCount | 0) || 0) + ' / 🚗 ' + (Math.max(0, (state.driveMeters|0) + 0) | 0) + ' m';
      }
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
      document.getElementById('btn-travel').hidden = !m || m.phase === 'dead';
    }
    var btnDbg = document.getElementById('btn-debug-evolve');
    if (btnDbg) { btnDbg.hidden = !(state && state.debugEnabled); }
    var c = state.cooldowns || {};
    ['feed', 'play', 'sleep', 'clean'].forEach(function (a) {
      var b = document.querySelector('.cd[data-cd=\"' + a + '\"]');
      if (!b) { return; }
      var t = c[a] | 0;
      b.textContent = t > 0 ? ('(' + t + 's)') : '';
    });
    ['feed', 'play', 'sleep', 'clean'].forEach(function (a) {
      var t = c[a] | 0;
      var b = document.querySelector('.care-tile[data-a=\"' + a + '\"]');
      if (!b) { return; }
      var sck = m && m.phase === 'sick' && (a === 'play' || a === 'sleep');
      var eggB = m && m.phase === 'egg';
      b.disabled = t > 0 || sck || eggB;
      b.classList.toggle('disabled', t > 0 || sck || eggB);
    });
    applyTickerIfNeeded();
    var lottElem = document.getElementById('meta-lottery');
    if (lottElem) {
      if (m && m.phase === 'child' && state.adultLottery) {
        var al = state.adultLottery;
        if (!al.eligible) {
          var parts = [];
          if (al.currentLevel < al.minLevel) { parts.push('Lv' + al.currentLevel + '/' + al.minLevel); }
          if (al.currentSteps < al.minSteps) { parts.push(al.currentSteps + '/' + al.minSteps + '歩'); }
          if (al.currentChildSec < al.minChildSec) { parts.push('滞在' + Math.floor(al.currentChildSec / 60) + '/' + Math.floor(al.minChildSec / 60) + '分'); }
          lottElem.textContent = '成熟期まで: ' + parts.join(' · ');
          lottElem.hidden = false;
        } else {
          lottElem.textContent = '次の進化抽選: ' + secondsToHMS(al.nextLotteryInSec) + ' (毎回' + al.chancePercent + '%)';
          lottElem.hidden = false;
        }
      } else {
        lottElem.hidden = true;
      }
    }
    updateSickSkulls();
    renderPoops();
    requestAnimationFrame(function () { requestAnimationFrame(syncSpriteLayout); });
  }

  function posMini() {
    var d = (state && state.miniPosDefault) || { x: 0.12, y: 0.88 };
    var p = (state && state.miniPos) || d;
    var el = document.getElementById('mini-pet');
    if (!el) { return; }
    if (p.x < 0.05) { p.x = 0.05; }
    if (p.y < 0.05) { p.y = 0.05; }
    var hW, hH;
    if (el.offsetWidth > 0 && el.offsetHeight > 0) {
      hW = el.offsetWidth * 0.5;
      hH = el.offsetHeight * 0.5;
    } else {
      hW = 100 * UI_S;
      hH = 100 * UI_S;
    }
    el.style.left = Math.max(0, (window.innerWidth * p.x) - hW) + 'px';
    el.style.top = Math.max(0, (window.innerHeight * p.y) - hH) + 'px';
  }

  function onMsg(e) {
    var d = e.data;
    if (!d || !d.type) { return; }
    if (d.type === 'state') {
      state = d; state._uiS = UI_S;
      if (d.pet && d.pet.phase === 'egg' && d.hatchLeftSec != null) {
        state._hatchSyncAt = Date.now();
        state._hatchBaseSec = d.hatchLeftSec | 0;
      } else {
        state._hatchSyncAt = null;
        state._hatchBaseSec = null;
      }
      stopHatchCountdownTicker();
      if (d.pet && d.pet.phase === 'egg' && (d.hatchLeftSec | 0) > 0) {
        startHatchCountdownTicker();
      }
      if (d.resName) { res = d.resName; }
      var mpu = document.getElementById('mini-pet');
      if (mpu) { mpu.classList.add('is-ready'); }
      render();
      refreshDebugEvolveStatus();
      if (d.expanded) {
        nuiSetFocus(1);
      } else {
        nuiSetFocus(0);
      }
    } else if (d.type === 'debugEvolveScheduled') {
      showFlash();
      if (state) {
        var dmsg = '🛠 ' + d.target + ' に ' + (d.delaySec | 0) + ' 秒後に進化…';
        tickerList = [dmsg, TIP];
        tickerIdx = 0;
        applyTickerSlide();
        lastTickerKey = '';
      }
      refreshDebugEvolveStatus();
    } else if (d.type === 'debugEvolveCancelled') {
      if (state) { state.debugForceEvolve = null; }
      refreshDebugEvolveStatus();
    } else if (d.type === 'debugEvolveRejected') {
      if (state) {
        var rej = '⚠ 現在のフェーズでは病気にできません';
        if (d.reason && d.reason !== 'invalid_phase') { rej = '⚠ 強制進化を実行できません (' + d.reason + ')'; }
        tickerList = [rej, TIP];
        tickerIdx = 0;
        applyTickerSlide();
        lastTickerKey = '';
      }
    } else if (d.type === 'evolve') {
      showFlash();
      if (state) {
        var evName = d.evName || '次の段階';
        var msg = '✨ ' + evName + ' に進化しました！';
        tickerList = [msg, TIP];
        tickerIdx = 0;
        applyTickerSlide();
        lastTickerKey = '';
      }
    } else if (d.type === 'playAction' && d.name) {
      currentAction = d.name;
      if (d.name === 'feed') { currentAction = 'eat'; }
      else if (d.name === 'play') { currentAction = 'play'; }
      else if (d.name === 'sleep') { currentAction = 'sleep'; }
      else if (d.name === 'clean') { currentAction = 'clean'; }
      if (d.sprite) { state.sprite = d.sprite; }
      if (d.pet) { state.pet = d.pet; }
      updateSickSkulls();
      setSprite(document.getElementById('sprite-el'), getSpriteSet(), currentAction);
      setSprite(document.getElementById('mini-sprite'), getSpriteSet(), currentAction);
      applySpriteWithMode(document.getElementById('sprite-el'), getSpriteSet(), false);
      applySpriteWithMode(document.getElementById('mini-sprite'), getSpriteSet(), true);
      syncSpriteLayout();
      showFlash();
      if (actionTimer) { clearTimeout(actionTimer); }
      actionTimer = setTimeout(function () { currentAction = 'idle'; render(); }, 2800);
    } else if (d.type === 'levelUp') {
      showMiniLevelUp();
    } else if (d.type === 'zukan' && d.open === true) {
      var zModal = document.getElementById('zukan-modal');
      var zb = document.getElementById('zukan-body');
      if (!zModal || !zb) { return; }
      zModal.classList.remove('hidden');
      zb.innerHTML = '';
      var have = d.zukan || [];
      if (typeof have.indexOf !== 'function') { have = Object.keys(have || {}); }
      var zMap = d.zukanMap || {};
      var zFrames = d.zukanFrames || {};
      var order = d.zukanIds || Object.keys(zMap);
      var formNames = d.formNames || (state && state.formNames) || {};
      order.forEach(function (k) {
        if (!zMap[k]) { return; }
        var isUnknown = have.indexOf(k) < 0;
        var displayName = formNames[k] || k;
        var cell = document.createElement('div');
        if (zMap[k] === '__SKULL__') {
          cell.className = 'zk-cell zk-skull' + (isUnknown ? ' zk-sil' : '');
          cell.textContent = '☠';
        } else {
          var isStrip = (zFrames[k] | 0) > 1;
          cell.className = 'zk-cell' + (isUnknown ? ' zk-sil' : '') + (isStrip ? ' zk-strip' : '');
          cell.style.backgroundImage = 'url(' + nuiUrl(zMap[k]) + ')';
        }
        cell.setAttribute('aria-label', displayName);
        cell.title = displayName;
        zb.appendChild(cell);
      });
      if (state) {
        state.zukan = have;
        state.zukanMap = zMap;
        state.zukanIds = order;
        state.zukanFrames = zFrames;
        if (d.formNames) { state.formNames = d.formNames; }
      }
    } else if (d.type === 'zukan' && d.open === false) {
      document.getElementById('zukan-modal').classList.add('hidden');
    }
  }
  function nuiSetFocus(on) { /* ゲーム側。プレースホルダ。 */ }
  window.addEventListener('message', onMsg);

  document.getElementById('close-ex').addEventListener('click', function () {
    post('closeExpanded', {});
  });
  var btnR = document.getElementById('btn-reset-mini');
  if (btnR) { btnR.addEventListener('click', function () { post('resetMiniPos', {}); }); }
  document.getElementById('btn-zukan').addEventListener('click', function () {
    post('zukan', { open: true });
  });
  var zukMo = document.getElementById('zukan-modal');
  if (zukMo) {
    zukMo.addEventListener('click', function (ev) {
      if (ev.target === zukMo) { post('zukan', { open: false }); }
    });
  }
  document.getElementById('zukan-close').addEventListener('click', function () {
    post('zukan', { open: false });
  });
  var bde = document.getElementById('btn-debug-evolve');
  if (bde) { bde.addEventListener('click', openDebugEvolveModal); }
  (function () {
    var b = document.getElementById('debug-evolve-close');
    var m = document.getElementById('debug-evolve-modal');
    if (b && m) {
      b.addEventListener('click', function () { m.classList.add('hidden'); });
    }
  })();
  (function () {
    var c = document.getElementById('debug-evolve-cancel');
    if (c) { c.addEventListener('click', function () { post('debugCancelForceEvolve', {}); }); }
  })();
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
  (function nameEditUi() {
    var bpe = document.getElementById('btn-name-edit');
    var mni = document.getElementById('meta-n-input');
    if (bpe) {
      bpe.addEventListener('click', function (ev) { ev.stopPropagation(); startPetNameEdit(); });
    }
    if (mni) {
      mni.addEventListener('keydown', function (ev) {
        if (ev.key === 'Enter') { ev.preventDefault(); endPetNameEdit(true); }
        else if (ev.key === 'Escape') { ev.preventDefault(); endPetNameEdit(false); }
      });
      mni.addEventListener('blur', function () { if (nameEditMode) { endPetNameEdit(true); } });
    }
  })();
  document.querySelectorAll('.care-tile[data-a=\"feed\"],.care-tile[data-a=\"play\"],.care-tile[data-a=\"sleep\"],.care-tile[data-a=\"clean\"]').forEach(function (b) {
    b.addEventListener('click', function () {
      var a = b.getAttribute('data-a');
      if (a) { post('action', { name: a }); }
    });
  });

  var mpet = document.getElementById('mini-pet');
  mpet.addEventListener('mousedown', function (ev) {
    if (!state || !state.expanded) { return; }
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
    var hx = r.width * 0.5, hy = r.height * 0.5;
    var rx = (r.left + hx) / rw;
    var ry = (r.top + hy) / rh;
    rx = Math.max(0.01, Math.min(0.99, rx));
    ry = Math.max(0.01, Math.min(0.99, ry));
    post('setMiniPos', { x: rx, y: ry, dragPx: lastDragPx });
  });

  if (tick) { clearInterval(tick); }
  tick = setInterval(function () { render(); }, 30000);
  function armSpriteResize() {
    if (window.ResizeObserver) {
      var r = new ResizeObserver(function () { syncSpriteLayout(); });
      var dw = document.getElementById('device-wrap');
      var md = document.getElementById('mini-device');
      if (dw) { r.observe(dw); }
      if (md) { r.observe(md); }
    }
    requestAnimationFrame(function () { requestAnimationFrame(syncSpriteLayout); });
  }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', armSpriteResize);
  } else {
    armSpriteResize();
  }
  window.addEventListener('resize', function () { posMini(); syncSpriteLayout(); });
})();
