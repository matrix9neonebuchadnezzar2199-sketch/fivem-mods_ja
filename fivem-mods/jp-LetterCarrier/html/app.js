(function () {
  'use strict';
  const R = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'jp-LetterCarrier';

  const nuiRoot = document.getElementById('nuiRoot');
  const el = {
    title: document.getElementById('screenTitle'),
    sub: document.getElementById('subText'),
    idle: document.getElementById('idlePanel'),
    work: document.getElementById('workPanel'),
    wProg: document.getElementById('workProgress'),
    wBar: document.getElementById('workBar'),
    earn: document.getElementById('earnText'),
  };

  function setNuiHostVisible(visible) {
    if (!nuiRoot) return;
    if (visible) {
      nuiRoot.classList.remove('nui-hidden');
      nuiRoot.classList.add('nui-visible');
      nuiRoot.style.display = 'block';
    } else {
      nuiRoot.classList.remove('nui-visible');
      nuiRoot.classList.add('nui-hidden');
      nuiRoot.style.display = 'none';
    }
  }

  function nui(name, data) {
    return fetch('https://' + R + '/' + name, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data || {}),
    });
  }

  function showIdle() {
    el.title.textContent = 'クイックデリバリー';
    el.sub.textContent = '荷物を届けて報酬をもらおう！ コースを選んでスタート！';
    el.idle.classList.remove('is-hidden');
    el.work.classList.add('is-hidden');
    el.work.setAttribute('aria-hidden', 'true');
  }

  function showWork(total, done, totalEarn) {
    el.title.textContent = '配達中';
    el.sub.textContent = '地図の集配所・配達先へ向かいます。';
    el.idle.classList.add('is-hidden');
    el.work.classList.remove('is-hidden');
    el.work.setAttribute('aria-hidden', 'false');
    el.wProg.textContent = '配達状況: ' + String(done) + ' / ' + String(total) + ' 件完了';
    const pct = total > 0 ? (done / total) * 100 : 0;
    el.wBar.style.width = pct + '%';
    el.earn.textContent = '今回の累計: $' + String(totalEarn || 0);
  }

  function onOpenMsg(s) {
    setNuiHostVisible(true);
    if (s && s.hasJob) {
      showWork(s.total || 0, s.completed || 0, s.totalEarned || 0);
    } else {
      showIdle();
    }
  }

  function onState(msg) {
    if (msg.state === 'idle') {
      showIdle();
    }
  }

  function onJob(msg) {
    if (!nuiRoot || nuiRoot.classList.contains('nui-hidden')) {
      setNuiHostVisible(true);
    }
    showWork(msg.total || 0, msg.completed || 0, msg.totalEarned || 0);
  }

  function onCloseMsg() {
    setNuiHostVisible(false);
  }

  window.addEventListener('message', function (ev) {
    let m = ev.data;
    if (m == null) return;
    if (typeof m === 'string') {
      try {
        m = JSON.parse(m);
      } catch (e) {
        return;
      }
    }
    if (typeof m !== 'object' || m.type == null) return;
    if (m.type === 'open') {
      onOpenMsg(m);
      return;
    }
    if (m.type === 'close') {
      onCloseMsg();
      return;
    }
    if (m.type === 'state') {
      onState(m);
      return;
    }
    if (m.type === 'job') {
      onJob(m);
    }
  });

  document.getElementById('btnClose').addEventListener('click', function () {
    onCloseMsg();
    nui('uiClose', {});
  });
  document.getElementById('btnRestart').addEventListener('click', function () {
    nui('actionReset', {});
  });
  document.getElementById('btnAbort').addEventListener('click', function () {
    nui('actionCancel', {});
  });
  [5, 10, 20].forEach(function (n) {
    var b = document.getElementById('btn' + n);
    if (b) b.addEventListener('click', function () {
      nui('courseStart', { count: n });
    });
  });

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') {
      onCloseMsg();
      nui('uiClose', {});
    }
  });
})();
