(function () {
  'use strict';

  const COLORS = [
    '#1a1a1a',
    '#ffffff',
    '#e53935',
    '#fb8c00',
    '#fdd835',
    '#43a047',
    '#1e88e5',
    '#5e35b1',
    '#d81b60',
    '#78909c',
  ];

  const app = document.getElementById('app');
  const viewer = document.getElementById('viewer');
  const editor = document.getElementById('editor');
  const viewerImg = document.getElementById('viewer-img');
  const viewerTitle = document.getElementById('viewer-title');
  const viewerClose = document.getElementById('viewer-close');
  const cvBg = document.getElementById('cv-bg');
  const cvDraw = document.getElementById('cv-draw');
  const stage = document.getElementById('stage');
  const paletteEl = document.getElementById('palette');
  const penSize = document.getElementById('pen-size');
  const penLabelText = document.getElementById('pen-label-text');
  const btnUndo = document.getElementById('btn-undo');
  const btnClear = document.getElementById('btn-clear');
  const btnSave = document.getElementById('btn-save');
  const editorClose = document.getElementById('editor-close');

  let jpegQuality = 0.85;
  let paintSlot = null;
  let drawCtx = null;
  let drawing = false;
  let lastX = 0;
  let lastY = 0;
  let strokeDirty = false;
  let undoStack = [];
  let activeColor = COLORS[0];
  const MAX_UNDO = 28;

  function resourceName() {
    return typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'PolaPaint';
  }

  function postNui(endpoint, data) {
    fetch('https://' + resourceName() + '/' + endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data || {}),
    }).catch(function () {});
  }

  function stripBase64Prefix(dataUrl) {
    if (typeof dataUrl !== 'string') return '';
    const i = dataUrl.indexOf('base64,');
    return i >= 0 ? dataUrl.slice(i + 7) : dataUrl;
  }

  function downscaleDataUri(dataUri, maxW, quality) {
    return new Promise(function (resolve, reject) {
      const img = new Image();
      img.onload = function () {
        let w = img.naturalWidth;
        let h = img.naturalHeight;
        if (!w || !h) {
          reject(new Error('badsize'));
          return;
        }
        if (w > maxW) {
          h = Math.round((h * maxW) / w);
          w = maxW;
        }
        const c = document.createElement('canvas');
        c.width = w;
        c.height = h;
        const ctx = c.getContext('2d');
        ctx.drawImage(img, 0, 0, w, h);
        resolve(stripBase64Prefix(c.toDataURL('image/jpeg', quality)));
      };
      img.onerror = function () {
        reject(new Error('load'));
      };
      img.src = dataUri;
    });
  }

  function hideAll() {
    app.classList.add('hidden');
    viewer.classList.add('hidden');
    editor.classList.add('hidden');
    viewerImg.removeAttribute('src');
    paintSlot = null;
    undoStack = [];
    drawing = false;
    strokeDirty = false;
  }

  function openViewerMode(payload) {
    const url = payload.imageUrl;
    const strings = payload.strings || {};
    viewerTitle.textContent = strings.title || '';
    viewerClose.textContent = strings.close || '閉じる';
    viewerImg.src = url;
    app.classList.remove('hidden');
    viewer.classList.remove('hidden');
    editor.classList.add('hidden');
  }

  function pushUndo() {
    if (!drawCtx || !cvDraw.width || !cvDraw.height) return;
    const data = drawCtx.getImageData(0, 0, cvDraw.width, cvDraw.height);
    undoStack.push(data);
    if (undoStack.length > MAX_UNDO) undoStack.shift();
  }

  function applyUndo() {
    if (!drawCtx || undoStack.length <= 1) return;
    undoStack.pop();
    const prev = undoStack.length > 0 ? undoStack[undoStack.length - 1] : null;
    drawCtx.clearRect(0, 0, cvDraw.width, cvDraw.height);
    if (prev) {
      drawCtx.putImageData(prev, 0, 0);
    }
  }

  function clearDrawLayer() {
    if (!drawCtx) return;
    pushUndo();
    drawCtx.clearRect(0, 0, cvDraw.width, cvDraw.height);
    pushUndo();
  }

  function setupPaintCanvas(img, slot, strings, quality) {
    paintSlot = slot;
    jpegQuality = typeof quality === 'number' ? quality : 0.85;

    const nw = img.naturalWidth;
    const nh = img.naturalHeight;
    const maxDisplay = Math.min(880, Math.floor(window.innerWidth * 0.88));
    const scale = Math.min(1, maxDisplay / nw);
    const w = Math.max(1, Math.floor(nw * scale));
    const h = Math.max(1, Math.floor(nh * scale));

    cvBg.width = w;
    cvBg.height = h;
    cvDraw.width = w;
    cvDraw.height = h;
    cvBg.style.width = w + 'px';
    cvBg.style.height = h + 'px';
    cvDraw.style.width = w + 'px';
    cvDraw.style.height = h + 'px';
    stage.style.width = w + 'px';
    stage.style.height = h + 'px';

    const bgCtx = cvBg.getContext('2d');
    bgCtx.clearRect(0, 0, w, h);
    bgCtx.drawImage(img, 0, 0, w, h);

    drawCtx = cvDraw.getContext('2d');
    drawCtx.clearRect(0, 0, w, h);
    drawCtx.lineCap = 'round';
    drawCtx.lineJoin = 'round';
    undoStack = [];
    pushUndo();

    penLabelText.textContent = strings.penSize || '太さ';
    btnUndo.textContent = strings.undo || '戻す';
    btnClear.textContent = strings.clear || 'クリア';
    btnSave.textContent = strings.save || '保存';
    editorClose.textContent = strings.close || '閉じる';

    app.classList.remove('hidden');
    editor.classList.remove('hidden');
    viewer.classList.add('hidden');
  }

  function openPaintMode(payload) {
    const url = payload.imageUrl;
    const slot = payload.slot;
    const strings = payload.strings || {};
    const quality = typeof payload.quality === 'number' ? payload.quality : undefined;

    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = function () {
      setupPaintCanvas(img, slot, strings, quality);
    };
    img.onerror = function () {
      const img2 = new Image();
      img2.onload = function () {
        setupPaintCanvas(img2, slot, strings, quality);
      };
      img2.onerror = function () {
        postNui('close', {});
      };
      img2.src = url;
    };
    img.src = url;
  }

  function localToCanvas(e) {
    const rect = cvDraw.getBoundingClientRect();
    const x = ((e.clientX - rect.left) / rect.width) * cvDraw.width;
    const y = ((e.clientY - rect.top) / rect.height) * cvDraw.height;
    return { x: x, y: y };
  }

  function onDrawDown(e) {
    if (!drawCtx) return;
    e.preventDefault();
    drawing = true;
    strokeDirty = false;
    const p = localToCanvas(e);
    lastX = p.x;
    lastY = p.y;
  }

  function onDrawMove(e) {
    if (!drawing || !drawCtx) return;
    e.preventDefault();
    const p = localToCanvas(e);
    drawCtx.strokeStyle = activeColor;
    drawCtx.lineWidth = parseInt(penSize.value, 10) || 6;
    drawCtx.beginPath();
    drawCtx.moveTo(lastX, lastY);
    drawCtx.lineTo(p.x, p.y);
    drawCtx.stroke();
    lastX = p.x;
    lastY = p.y;
    strokeDirty = true;
  }

  function onDrawUp(e) {
    if (!drawing) return;
    e.preventDefault();
    drawing = false;
    if (strokeDirty) {
      pushUndo();
      strokeDirty = false;
    }
  }

  function savePaint() {
    if (paintSlot == null || !drawCtx) return;
    try {
      const w = cvBg.width;
      const h = cvBg.height;
      const out = document.createElement('canvas');
      out.width = w;
      out.height = h;
      const x = out.getContext('2d');
      x.drawImage(cvBg, 0, 0);
      x.drawImage(cvDraw, 0, 0);
      const dataUrl = out.toDataURL('image/jpeg', jpegQuality);
      const b64 = stripBase64Prefix(dataUrl);
      if (!b64) return;
      postNui('savePaint', { slot: paintSlot, base64: b64 });
    } catch (err) {
      postNui('close', {});
    }
  }

  function initPalette() {
    COLORS.forEach(function (hex, idx) {
      const b = document.createElement('button');
      b.type = 'button';
      b.className = 'swatch' + (idx === 0 ? ' active' : '');
      b.style.background = hex;
      b.addEventListener('click', function () {
        activeColor = hex;
        paletteEl.querySelectorAll('.swatch').forEach(function (el) {
          el.classList.remove('active');
        });
        b.classList.add('active');
      });
      paletteEl.appendChild(b);
    });
  }

  viewerClose.addEventListener('click', function () {
    postNui('close', {});
  });
  editorClose.addEventListener('click', function () {
    postNui('close', {});
  });
  btnUndo.addEventListener('click', function () {
    applyUndo();
  });
  btnClear.addEventListener('click', function () {
    clearDrawLayer();
  });
  btnSave.addEventListener('click', function () {
    savePaint();
  });

  cvDraw.addEventListener('mousedown', onDrawDown);
  window.addEventListener('mousemove', onDrawMove);
  window.addEventListener('mouseup', onDrawUp);

  window.addEventListener('message', function (ev) {
    const msg = ev.data;
    if (!msg || !msg.action) return;
    if (msg.action === 'setMode' && msg.mode === 'hidden') {
      hideAll();
      return;
    }
    if (msg.action === 'downscaleScreenshot') {
      downscaleDataUri(msg.dataUri, msg.maxWidth || 2560, msg.quality || 0.85)
        .then(function (b64) {
          postNui('captureDownscaled', { base64: b64 });
        })
        .catch(function () {
          postNui('captureDownscaled', { base64: '' });
        });
      return;
    }
    if (msg.action === 'openViewer') {
      openViewerMode(msg);
      return;
    }
    if (msg.action === 'openPaint') {
      openPaintMode(msg);
    }
  });

  initPalette();
})();

