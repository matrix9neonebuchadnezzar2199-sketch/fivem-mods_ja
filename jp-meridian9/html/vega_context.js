(function () {
  var root = document.getElementById('mrd9-vega-ctx');
  if (!root) {
    return;
  }

  var backdrop = root.querySelector('.mrd9-vega-ctx__backdrop');
  var panel = root.querySelector('.mrd9-vega-ctx__panel');
  var btnBack = root.querySelector('.mrd9-vega-ctx__back');
  var btnClose = root.querySelector('.mrd9-vega-ctx__close');
  var titleEl = root.querySelector('.mrd9-vega-ctx__title');
  var listEl = root.querySelector('.mrd9-vega-ctx__list');

  var ICON_GLYPH = {
    play: '\u25B6',
    briefcase: '\u25A0',
    gavel: '\u2696',
    'door-open': '\u2302',
    'arrow-right': '\u2192',
    times: '\u2715',
    'file-signature': '\u2261',
    clock: '\u231A',
    check: '\u2713',
    user: '\u25CF',
    users: '\u25CF\u25CF',
    'info-circle': '\u24D8',
  };

  function resName() {
    if (typeof GetParentResourceName === 'function') {
      return GetParentResourceName();
    }
    return 'jp-meridian9';
  }

  function post(action, body) {
    return fetch('https://' + resName() + '/' + action, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(body || {}),
    }).catch(function () {});
  }

  function iconGlyph(name) {
    if (!name || typeof name !== 'string') {
      return '\u00A0';
    }
    return ICON_GLYPH[name] || '\u00A0';
  }

  function hide() {
    root.classList.add('mrd9-hidden');
    root.setAttribute('aria-hidden', 'true');
    listEl.innerHTML = '';
  }

  function show(data) {
    var scale = typeof data.scale === 'number' && data.scale > 0 ? data.scale : 2;
    panel.style.setProperty('--mrd9-vega-ctx-scale', String(scale));

    titleEl.textContent = data.title || '';
    if (data.showBack) {
      btnBack.classList.remove('mrd9-hidden');
    } else {
      btnBack.classList.add('mrd9-hidden');
    }

    listEl.innerHTML = '';
    var opts = data.options || [];
    for (var i = 0; i < opts.length; i++) {
      (function (idx, o) {
        var li = document.createElement('button');
        li.type = 'button';
        li.className = 'mrd9-vega-ctx__opt';
        if (o.disabled) {
          li.classList.add('mrd9-vega-ctx__opt--disabled');
          li.disabled = true;
        }

        var ic = document.createElement('span');
        ic.className = 'mrd9-vega-ctx__opt-icon';
        ic.textContent = iconGlyph(o.icon);
        ic.setAttribute('aria-hidden', 'true');

        var body = document.createElement('div');
        body.className = 'mrd9-vega-ctx__opt-body';
        var t = document.createElement('div');
        t.className = 'mrd9-vega-ctx__opt-title';
        t.textContent = o.title || '';
        body.appendChild(t);
        if (o.description) {
          var d = document.createElement('div');
          d.className = 'mrd9-vega-ctx__opt-desc';
          d.textContent = o.description;
          body.appendChild(d);
        }

        li.appendChild(ic);
        li.appendChild(body);
        li.addEventListener('click', function () {
          if (li.disabled) {
            return;
          }
          post('mrd9_vega_ctx_select', { index: idx });
        });
        listEl.appendChild(li);
      })(i + 1, opts[i]);
    }

    root.classList.remove('mrd9-hidden');
    root.setAttribute('aria-hidden', 'false');
  }

  window.addEventListener('message', function (e) {
    var msg = e.data || {};
    if (msg.type === 'vegaContextOpen') {
      show(msg);
    } else if (msg.type === 'vegaContextClose') {
      hide();
    }
  });

  if (backdrop) {
    backdrop.addEventListener('click', function () {
      post('mrd9_vega_ctx_close', {});
    });
  }
  if (btnClose) {
    btnClose.addEventListener('click', function () {
      post('mrd9_vega_ctx_close', {});
    });
  }
  if (btnBack) {
    btnBack.addEventListener('click', function () {
      post('mrd9_vega_ctx_back', {});
    });
  }

  document.addEventListener('keydown', function (e) {
    if (e.key !== 'Escape' || root.classList.contains('mrd9-hidden')) {
      return;
    }
    e.preventDefault();
    post('mrd9_vega_ctx_close', {});
  });
})();
