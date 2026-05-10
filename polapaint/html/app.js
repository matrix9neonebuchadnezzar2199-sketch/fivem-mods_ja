(function () {
  'use strict';

  const COLORS = [
    '#1a1a1a', '#ffffff', '#e53935', '#fb8c00', '#fdd835',
    '#43a047', '#1e88e5', '#5e35b1', '#d81b60', '#78909c'
  ];
  const MAX_UNDO = 16;

  const $ = (id) => document.getElementById(id);
  const els = {
    app: $('app'), viewer: $('viewer'), editor: $('editor'),
    viewerImg: $('viewer-img'), viewerTitle: $('viewer-title'), viewerClose: $('viewer-close'),
    cvBg: $('cv-bg'), cvDraw: $('cv-draw'), stage: $('stage'),
    palette: $('palette'), penSize: $('pen-size'), penLabel: $('pen-label-text'),
    btnUndo: $('btn-undo'), btnClear: $('btn-clear'), btnSave: $('btn-save'),
    editorClose: $('editor-close'),
    nameOverlay: $('name-overlay'), nameTitle: $('name-title'),
    nameInput: $('name-input'), nameConfirm: $('name-confirm'), nameCancel: $('name-cancel'),
  };

  let state = {
    jpegQuality: 0.85,
    pendingCaptureBlob: null,
    captureToken: null,
    paintSlot: null,
    paintEditToken: null,
    drawCtx: null,
    drawing: false,
    lastX: 0, lastY: 0,
    strokeDirty: false,
    undoStack: [],
    activeColor: COLORS[0],
    maxNameLen: 40,
  };

  function normalizeResourceHost(name) {
    if (!name || typeof name !== 'string') return '';
    var n = name;
    if (n.indexOf('cfx-nui-') === 0) n = n.slice('cfx-nui-'.length);
    return n;
  }

  function RES() {
    if (typeof GetParentResourceName === 'function') {
      try {
        var n = normalizeResourceHost(GetParentResourceName());
        if (n) return n;
      } catch (e) {}
    }
    if (typeof window !== 'undefined' && window.location && window.location.hostname) {
      var h = normalizeResourceHost(window.location.hostname);
      if (h) return h;
    }
    return 'polapaint';
  }

  /** NUI ページと同一オリジン（例: https://cfx-nui-polapaint）。fetch が SetHttpHandler に届くようにする */
  function NUI_ORIGIN() {
    if (typeof window !== 'undefined' && window.location && window.location.origin) {
      var o = window.location.origin;
      if (o && o.indexOf('http') === 0) return o;
    }
    return 'https://cfx-nui-' + RES();
  }

  function postNui(endpoint, data) {
    return fetch(NUI_ORIGIN() + '/' + endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data || {}),
    }).catch(() => nuiAlert('notify_nui_fetch_failed'));
  }

  async function postNuiBinary(endpoint, body, query) {
    const url = NUI_ORIGIN() + '/' + endpoint;
    const headers = { 'Content-Type': 'image/jpeg' };
    if (query) {
      if (query.token) headers['X-Polapaint-Token'] = String(query.token);
      if (query.name != null && query.name !== '') {
        headers['X-Polapaint-Name'] = encodeURIComponent(String(query.name));
      }
      if (query.slot != null) headers['X-Polapaint-Slot'] = String(query.slot);
    }
    nuiAlert('debug_url2_' + url);
    try {
      const r = await fetch(url, { method: 'POST', headers: headers, body: body });
      if (!r.ok && r.status !== 204) throw new Error('http_' + r.status);
      return r;
    } catch (e) {
      nuiAlert('debug_fetch_err_' + (e && e.message ? e.message : 'unknown'));
      nuiAlert('notify_nui_fetch_failed');
      throw e;
    }
  }

  function nuiAlert(key) { postNui('ppNuiAlert', { key }); }

  function graphemeCount(s) {
    if (typeof Intl !== 'undefined' && Intl.Segmenter) {
      const seg = new Intl.Segmenter('ja', { granularity: 'grapheme' });
      let n = 0;
      for (const _ of seg.segment(s)) n++;
      return n;
    }
    return Array.from(s).length;
  }

  function dataUriToScaledBlob(dataUri, maxW, quality) {
    return new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = () => {
        let w = img.naturalWidth, h = img.naturalHeight;
        if (!w || !h) return reject(new Error('badsize'));
        if (w > maxW) { h = Math.round((h * maxW) / w); w = maxW; }
        const c = document.createElement('canvas');
        c.width = w; c.height = h;
        c.getContext('2d').drawImage(img, 0, 0, w, h);
        c.toBlob((b) => b ? resolve(b) : reject(new Error('blob')), 'image/jpeg', quality);
      };
      img.onerror = () => reject(new Error('load'));
      img.src = dataUri;
    });
  }

  function canvasToJpegBlob(canvas, quality) {
    return new Promise((resolve, reject) => {
      canvas.toBlob((b) => b ? resolve(b) : reject(new Error('blob')), 'image/jpeg', quality);
    });
  }

  function hideAll() {
    els.app.classList.add('hidden');
    els.nameOverlay.classList.add('hidden');
    els.viewer.classList.add('hidden');
    els.editor.classList.add('hidden');
    els.viewerImg.removeAttribute('src');
    state.pendingCaptureBlob = null;
    state.captureToken = null;
    state.paintSlot = null;
    state.paintEditToken = null;
    state.undoStack = [];
    state.drawing = false;
    state.strokeDirty = false;
    els.nameInput.value = '';
  }

  function openCaptureNameDialog(blob, token, dialog, maxNameLen) {
    state.pendingCaptureBlob = blob;
    state.captureToken = token;
    state.maxNameLen = maxNameLen || 40;

    els.nameTitle.textContent = dialog.title || '';
    els.nameInput.placeholder = dialog.placeholder || '';
    els.nameConfirm.textContent = dialog.confirm || 'OK';
    els.nameCancel.textContent = dialog.cancel || 'Cancel';
    els.nameInput.value = '';

    els.app.classList.remove('hidden');
    els.nameOverlay.classList.remove('hidden');
    els.viewer.classList.add('hidden');
    els.editor.classList.add('hidden');
    setTimeout(() => els.nameInput.focus(), 50);
  }

  async function submitCaptureName() {
    if (!state.pendingCaptureBlob || !state.captureToken) return;
    const raw = els.nameInput.value.trim();
    if (!raw) return;
    if (graphemeCount(raw) > state.maxNameLen) {
      nuiAlert('notify_photo_name_too_long');
      return;
    }
    let buf;
    try {
      buf = await state.pendingCaptureBlob.arrayBuffer();
    } catch {
      nuiAlert('notify_nui_image_prepare_fail');
      postNui('close', {});
      return;
    }
    postNuiBinary('uploadCapture', buf, {
      token: state.captureToken,
      name: raw,
    }).catch(() => {});
    state.pendingCaptureBlob = null;
    state.captureToken = null;
    els.nameOverlay.classList.add('hidden');
    postNui('close', {});
  }

  function cancelCaptureName() {
    state.pendingCaptureBlob = null;
    state.captureToken = null;
    postNui('close', {});
  }

  function openViewerMode(payload) {
    els.viewerTitle.textContent = (payload.strings && payload.strings.title) || '';
    els.viewerClose.textContent = (payload.strings && payload.strings.close) || '閉じる';
    els.viewerImg.src = payload.imageUrl;
    els.nameOverlay.classList.add('hidden');
    els.app.classList.remove('hidden');
    els.viewer.classList.remove('hidden');
    els.editor.classList.add('hidden');
  }

  function pushUndo() {
    if (!state.drawCtx) return;
    state.undoStack.push(state.drawCtx.getImageData(0, 0, els.cvDraw.width, els.cvDraw.height));
    if (state.undoStack.length > MAX_UNDO) state.undoStack.shift();
  }
  function applyUndo() {
    if (!state.drawCtx || state.undoStack.length <= 1) return;
    state.undoStack.pop();
    const prev = state.undoStack[state.undoStack.length - 1];
    state.drawCtx.clearRect(0, 0, els.cvDraw.width, els.cvDraw.height);
    if (prev) state.drawCtx.putImageData(prev, 0, 0);
  }
  function clearDrawLayer() {
    if (!state.drawCtx) return;
    pushUndo();
    state.drawCtx.clearRect(0, 0, els.cvDraw.width, els.cvDraw.height);
  }

  function setupPaintCanvas(img, payload) {
    state.paintSlot = payload.slot;
    state.paintEditToken = payload.editToken;
    state.jpegQuality = typeof payload.quality === 'number' ? payload.quality : 0.85;

    const nw = img.naturalWidth, nh = img.naturalHeight;
    const maxDisp = Math.min(880, Math.floor(window.innerWidth * 0.6));
    const scale = Math.min(1, maxDisp / nw);
    const w = Math.max(1, Math.floor(nw * scale));
    const h = Math.max(1, Math.floor(nh * scale));

    [els.cvBg, els.cvDraw].forEach((c) => {
      c.width = w; c.height = h;
      c.style.width = w + 'px'; c.style.height = h + 'px';
    });
    els.stage.style.width = w + 'px';
    els.stage.style.height = h + 'px';

    els.cvBg.getContext('2d').drawImage(img, 0, 0, w, h);
    state.drawCtx = els.cvDraw.getContext('2d');
    state.drawCtx.lineCap = 'round';
    state.drawCtx.lineJoin = 'round';
    state.undoStack = [];
    pushUndo();

    const s = payload.strings || {};
    els.penLabel.textContent = s.penSize || '太さ';
    els.btnUndo.textContent = s.undo || '戻す';
    els.btnClear.textContent = s.clear || 'クリア';
    els.btnSave.textContent = s.save || '保存';
    els.editorClose.textContent = s.close || '閉じる';

    els.nameOverlay.classList.add('hidden');
    els.app.classList.remove('hidden');
    els.editor.classList.remove('hidden');
    els.viewer.classList.add('hidden');
  }

  function openPaintMode(payload) {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => setupPaintCanvas(img, payload);
    img.onerror = () => {
      nuiAlert('notify_nui_image_prepare_fail');
      postNui('close', {});
    };
    img.src = payload.imageUrl;
  }

  function localToCanvas(e) {
    const r = els.cvDraw.getBoundingClientRect();
    return {
      x: ((e.clientX - r.left) / r.width) * els.cvDraw.width,
      y: ((e.clientY - r.top) / r.height) * els.cvDraw.height,
    };
  }
  function onDown(e) {
    if (!state.drawCtx) return;
    e.preventDefault();
    els.cvDraw.setPointerCapture(e.pointerId);
    state.drawing = true; state.strokeDirty = false;
    const p = localToCanvas(e); state.lastX = p.x; state.lastY = p.y;
  }
  function onMove(e) {
    if (!state.drawing || !state.drawCtx) return;
    e.preventDefault();
    const p = localToCanvas(e);
    state.drawCtx.strokeStyle = state.activeColor;
    state.drawCtx.lineWidth = parseInt(els.penSize.value, 10) || 6;
    state.drawCtx.beginPath();
    state.drawCtx.moveTo(state.lastX, state.lastY);
    state.drawCtx.lineTo(p.x, p.y);
    state.drawCtx.stroke();
    state.lastX = p.x; state.lastY = p.y;
    state.strokeDirty = true;
  }
  function onUp(e) {
    if (!state.drawing) return;
    e.preventDefault();
    state.drawing = false;
    if (state.strokeDirty) { pushUndo(); state.strokeDirty = false; }
  }

  async function savePaint() {
    if (state.paintSlot == null || !state.drawCtx || !state.paintEditToken) return;
    try {
      const w = els.cvBg.width, h = els.cvBg.height;
      const out = document.createElement('canvas');
      out.width = w; out.height = h;
      const x = out.getContext('2d');
      x.drawImage(els.cvBg, 0, 0);
      x.drawImage(els.cvDraw, 0, 0);
      const blob = await canvasToJpegBlob(out, state.jpegQuality);
      const buf = await blob.arrayBuffer();
      await postNuiBinary('uploadEdit', buf, {
        token: state.paintEditToken,
        slot: String(state.paintSlot),
      });
      postNui('close', {});
    } catch {
      nuiAlert('notify_nui_image_prepare_fail');
      postNui('close', {});
    }
  }

  function initPalette() {
    COLORS.forEach((hex, idx) => {
      const b = document.createElement('button');
      b.type = 'button';
      b.className = 'swatch' + (idx === 0 ? ' active' : '');
      b.style.background = hex;
      b.addEventListener('click', () => {
        state.activeColor = hex;
        els.palette.querySelectorAll('.swatch').forEach((el) => el.classList.remove('active'));
        b.classList.add('active');
      });
      els.palette.appendChild(b);
    });
  }

  els.viewerClose.addEventListener('click', () => postNui('close', {}));
  els.editorClose.addEventListener('click', () => postNui('close', {}));
  els.btnUndo.addEventListener('click', applyUndo);
  els.btnClear.addEventListener('click', clearDrawLayer);
  els.btnSave.addEventListener('click', savePaint);
  els.nameCancel.addEventListener('click', cancelCaptureName);
  els.nameConfirm.addEventListener('click', submitCaptureName);
  els.nameInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') { e.preventDefault(); submitCaptureName(); }
    if (e.key === 'Escape') { e.preventDefault(); cancelCaptureName(); }
  });

  els.cvDraw.addEventListener('pointerdown', onDown);
  els.cvDraw.addEventListener('pointermove', onMove);
  els.cvDraw.addEventListener('pointerup', onUp);
  els.cvDraw.addEventListener('pointercancel', onUp);

  window.addEventListener('message', (ev) => {
    const msg = ev.data; if (!msg || !msg.action) return;
    if (msg.action === 'setMode' && msg.mode === 'hidden') return hideAll();

    if (msg.action === 'prepareCapture') {
      dataUriToScaledBlob(msg.dataUri, msg.maxWidth || 2560, msg.quality || 0.85)
        .then((blob) => openCaptureNameDialog(blob, msg.token, msg.nameDialog || {}, msg.maxNameLength))
        .catch(() => { nuiAlert('notify_nui_image_prepare_fail'); postNui('close', {}); });
      return;
    }
    if (msg.action === 'openViewer') return openViewerMode(msg);
    if (msg.action === 'openPaint') return openPaintMode(msg);
  });

  window.addEventListener('keydown', async (e) => {
    if (e.key !== 'F2') return;
    const jpegBuf = new Uint8Array([0xFF, 0xD8, 0xFF, 0xD9]).buffer;
    var targets = [
      NUI_ORIGIN() + '/uploadCapture',
      'https://' + RES() + '/uploadCapture',
      'https://cfx-nui-' + RES() + '/uploadCapture',
    ];
    for (var ti = 0; ti < targets.length; ti++) {
      var url = targets[ti];
      try {
        var r = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'image/jpeg' },
          body: jpegBuf,
        });
        nuiAlert('test_' + url + '_' + r.status);
      } catch (err) {
        nuiAlert('test_' + url + '_err_' + (err && err.message ? err.message : 'unknown'));
      }
    }
  });

  initPalette();
})();
