/**
 * DVD Maker NUI — 状態: hidden / create / playerMenu / playing
 */

const app = document.getElementById('app');

let uiState = 'hidden';
let currentTitle = '';
let currentUrl = '';
let currentPack = 'clear';
let currentCoverUrl = '';
let ytPlayer = null;
/** 表紙拡大（body 直下のオーバーレイ） */
let coverLightboxEl = null;

/** リソース名（起動時に1回だけ取得）。同名の function を定義すると注入 API を上書きし再帰で落ちる */
const dvdMakerResourceName = (function () {
  var fn = window['GetParentResourceName'];
  if (typeof fn === 'function') {
    try {
      return fn();
    } catch (e) {
      return 'dvd-maker';
    }
  }
  return 'dvd-maker';
})();

/** XSS 対策（テキストを HTML に載せる場合のみ使用） */
function escapeHtml(str) {
  if (str == null) return '';
  return String(str).replace(/[&<>"']/g, function (ch) {
    return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch];
  });
}

function nuiPost(name, data) {
  fetch('https://' + dvdMakerResourceName + '/' + name, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  }).catch(function () {});
}

/** NUI コールバック（Lua の RegisterNUICallback と対応）。戻り値で完了を待てる */
function nuiPostAsync(name, data) {
  return fetch('https://' + dvdMakerResourceName + '/' + name, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data != null ? data : {}),
  });
}

/** YouTube 動画 ID 抽出（埋め込み用） */
/** Google フォト等「共有ページ」URLは img では読めないことが多い */
function isLikelyNonDirectImagePageUrl(u) {
  if (!u || typeof u !== 'string') return false;
  var s = u.toLowerCase();
  if (s.indexOf('photos.app.goo.gl') !== -1) return true;
  if (s.indexOf('photos.google.com') !== -1 && s.indexOf('/share') !== -1) return true;
  return false;
}

/** GitHub の /blob/ ページ URL → raw.githubusercontent.com（img で読める直リンク） */
function normalizeCoverImageUrl(u) {
  if (u == null || typeof u !== 'string') return '';
  u = u.trim();
  if (!u) return '';
  if (/^http:\/\//i.test(u)) u = 'https://' + u.slice(7);
  if (/^https:\/\/raw\.githubusercontent\.com\//i.test(u)) return u;
  var m =
    u.match(/^https:\/\/github\.com\/([^/]+)\/([^/]+)\/blob\/([^/]+)\/(.+)$/i) ||
    u.match(/^https:\/\/www\.github\.com\/([^/]+)\/([^/]+)\/blob\/([^/]+)\/(.+)$/i);
  if (m) {
    var path = m[4].replace(/\?.*$/, '').replace(/#.*$/, '');
    return 'https://raw.githubusercontent.com/' + m[1] + '/' + m[2] + '/' + m[3] + '/' + path;
  }
  return u;
}

function extractYouTubeId(url) {
  if (!url || typeof url !== 'string') return '';
  var p = [
    /^https:\/\/www\.youtube\.com\/watch\?v=([\w\-_]+)/,
    /^https:\/\/youtube\.com\/watch\?v=([\w\-_]+)/,
    /^https:\/\/youtu\.be\/([\w\-_]+)/,
    /^https:\/\/m\.youtube\.com\/watch\?v=([\w\-_]+)/,
  ];
  for (var i = 0; i < p.length; i++) {
    var m = url.match(p[i]);
    if (m) return m[1];
  }
  return '';
}

function destroyPlayer() {
  if (ytPlayer && typeof ytPlayer.destroy === 'function') {
    try {
      ytPlayer.destroy();
    } catch (e) {}
  }
  ytPlayer = null;
}

function closeCoverLightbox() {
  if (coverLightboxEl && coverLightboxEl.parentNode) {
    coverLightboxEl.parentNode.removeChild(coverLightboxEl);
  }
  coverLightboxEl = null;
}

/** 表紙 URL を別レイヤーで大きく表示（インベントリとは別の NUI 内ウィンドウ） */
function openCoverLightbox(imageUrl) {
  if (!imageUrl || typeof imageUrl !== 'string') return;
  imageUrl = normalizeCoverImageUrl(imageUrl);
  if (!imageUrl) return;
  closeCoverLightbox();
  var root = document.createElement('div');
  root.className = 'cover-lightbox';
  root.setAttribute('role', 'dialog');
  root.setAttribute('aria-modal', 'true');
  root.setAttribute('aria-label', '表紙拡大表示');

  var inner = document.createElement('div');
  inner.className = 'cover-lightbox-inner';

  var img = document.createElement('img');
  img.className = 'cover-lightbox-img';
  img.src = imageUrl;
  img.alt = '表紙';

  var btn = document.createElement('button');
  btn.type = 'button';
  btn.className = 'cover-lightbox-close btn btn-secondary';
  btn.textContent = '閉じる';

  function shutdown() {
    closeCoverLightbox();
  }
  btn.addEventListener('click', shutdown);
  root.addEventListener('click', function (ev) {
    if (ev.target === root) shutdown();
  });

  inner.appendChild(img);
  inner.appendChild(btn);
  root.appendChild(inner);
  document.body.appendChild(root);
  coverLightboxEl = root;
}

function setHidden() {
  closeCoverLightbox();
  uiState = 'hidden';
  destroyPlayer();
  app.classList.add('state-hidden');
  app.innerHTML = '';
  app.setAttribute('aria-hidden', 'true');
}

function syncCoverFieldVisibility() {
  var sel = document.getElementById('dm-pack');
  var wrap = document.getElementById('dm-cover-wrap');
  var coverIn = document.getElementById('dm-cover');
  if (!sel || !wrap) return;
  var tall = sel.value === 'tall';
  wrap.style.display = tall ? 'block' : 'none';
  if (!tall && coverIn) coverIn.value = '';
}

function showCreate() {
  closeCoverLightbox();
  uiState = 'create';
  destroyPlayer();
  app.classList.remove('state-hidden');
  app.setAttribute('aria-hidden', 'false');
  app.innerHTML = '';

  var panel = document.createElement('div');
  panel.className = 'overlay-panel';

  var img = document.createElement('img');
  /* pointer-events: none … 左の大きい装飾画像が保存ボタンの上に重なるとクリックが届かない（flex-shrink:0 のため） */
  img.className = 'dvd-img dvd-img--decorative';
  img.src = 'img/disc_128_tight.png';
  img.alt = '空のDVD';

  var col = document.createElement('div');
  col.className = 'menu-col';

  var h = document.createElement('h2');
  h.textContent = 'DVD に記録';

  var lp = document.createElement('label');
  lp.setAttribute('for', 'dm-pack');
  lp.textContent = 'DVD種類';
  var packSel = document.createElement('select');
  packSel.id = 'dm-pack';
  packSel.style.padding = '16px 20px';
  packSel.style.fontSize = '26px';
  packSel.style.borderRadius = '12px';
  packSel.style.background = '#1a1a1a';
  packSel.style.color = '#fff';
  packSel.style.border = '2px solid #444';
  [['fushokufu', '不織布スリーブ'], ['clear', 'クリアケース'], ['tall', 'トールケース（表紙URL可）']].forEach(function (o) {
    var opt = document.createElement('option');
    opt.value = o[0];
    opt.textContent = o[1];
    packSel.appendChild(opt);
  });
  packSel.addEventListener('change', syncCoverFieldVisibility);

  var coverWrap = document.createElement('div');
  coverWrap.id = 'dm-cover-wrap';
  coverWrap.style.display = 'none';
  var lc = document.createElement('label');
  lc.setAttribute('for', 'dm-cover');
  lc.textContent = '表紙画像URL（https・トールのみ任意）';
  var coverIn = document.createElement('input');
  coverIn.type = 'text';
  coverIn.inputMode = 'url';
  coverIn.id = 'dm-cover';
  coverIn.maxLength = 768;
  coverIn.placeholder = 'https://raw.githubusercontent.com/…/main/covers/jacket.png';
  var coverHint = document.createElement('p');
  coverHint.className = 'cover-url-hint';
  coverHint.textContent =
    '※GitHub の「ファイルを開いたページ」（…/blob/main/…）でも保存時に raw 直リンクへ変換します。Google フォト共有・Drive 閲覧ページは読み込めません。';
  coverWrap.appendChild(lc);
  coverWrap.appendChild(coverIn);
  coverWrap.appendChild(coverHint);

  var lt = document.createElement('label');
  lt.textContent = 'タイトル（最大40文字）';
  var titleIn = document.createElement('input');
  titleIn.type = 'text';
  titleIn.maxLength = 40;
  titleIn.id = 'dm-title';
  titleIn.placeholder = 'タイトル';

  var lu = document.createElement('label');
  lu.textContent = 'YouTube 動画のURL';
  var urlIn = document.createElement('input');
  urlIn.type = 'text';
  urlIn.inputMode = 'url';
  urlIn.id = 'dm-url';
  urlIn.placeholder = 'https://www.youtube.com/watch?v=...';

  var bSave = document.createElement('button');
  bSave.type = 'button';
  bSave.className = 'btn btn-primary';
  bSave.textContent = '保存';
  bSave.addEventListener('click', onSaveClick);

  var bCancel = document.createElement('button');
  bCancel.type = 'button';
  bCancel.className = 'btn btn-secondary';
  bCancel.textContent = '取り消し';
  bCancel.addEventListener('click', onCloseClick);

  col.appendChild(h);
  col.appendChild(lp);
  col.appendChild(packSel);
  col.appendChild(coverWrap);
  col.appendChild(lt);
  col.appendChild(titleIn);
  col.appendChild(lu);
  col.appendChild(urlIn);
  col.appendChild(bSave);
  col.appendChild(bCancel);

  panel.appendChild(img);
  panel.appendChild(col);
  app.appendChild(panel);
}

/** 再生メニュー左側のパッケージビジュアル */
function buildPlayerArtWrap() {
  var pack = currentPack || 'clear';
  var cover = normalizeCoverImageUrl(typeof currentCoverUrl === 'string' ? currentCoverUrl : '');

  if (pack === 'tall') {
    var row = document.createElement('div');
    row.className = 'tall-player-layout';

    var left = document.createElement('div');
    left.className = 'cover-preview-window';

    var lab = document.createElement('div');
    lab.className = 'cover-preview-label';
    lab.textContent = '表紙プレビュー';
    left.appendChild(lab);

    if (cover) {
      var hint = document.createElement('div');
      hint.className = 'cover-preview-hint';
      hint.textContent = '画像をクリックすると拡大表示します';
      left.appendChild(hint);
      var wrapImg = document.createElement('div');
      wrapImg.className = 'cover-preview-img-wrap';
      var cimg = document.createElement('img');
      cimg.className = 'cover-preview-img cover-preview-img--clickable';
      cimg.src = cover;
      cimg.alt = '表紙画像';
      cimg.title = 'クリックで拡大';
      cimg.addEventListener('click', function () {
        openCoverLightbox(cover);
      });
      var err = document.createElement('div');
      err.className = 'cover-preview-error';
      err.style.display = 'none';
      err.textContent =
        'この URL からは画像を読み込めませんでした（共有ページ・CORS 等）。画像直リンク（例: .png の URL）を試してください。';
      cimg.addEventListener('error', function () {
        wrapImg.style.display = 'none';
        err.style.display = 'flex';
      });
      wrapImg.appendChild(cimg);
      left.appendChild(wrapImg);
      left.appendChild(err);
    } else {
      var ph = document.createElement('div');
      ph.className = 'cover-preview-placeholder';
      ph.textContent = '表紙画像は未設定です';
      left.appendChild(ph);
    }

    var right = document.createElement('div');
    right.className = 'tall-case-column';
    var wrap = document.createElement('div');
    wrap.className = 'tall-case-wrap';
    var caseImg = document.createElement('img');
    caseImg.className = 'tall-case-img tall-case-img--decorative';
    caseImg.src = 'img/dvd_case_text_transparent_128.png';
    caseImg.alt = 'DVDトールケース';
    wrap.appendChild(caseImg);
    right.appendChild(wrap);

    row.appendChild(left);
    row.appendChild(right);
    return row;
  }

  var img = document.createElement('img');
  img.className = 'dvd-img dvd-img--decorative';
  if (pack === 'fushokufu') {
    img.src = 'img/dvd_case_128_tight.png';
    img.alt = 'DVD（不織布）';
  } else {
    img.src = 'img/dvd_jewel_transparent_128.png';
    img.alt = 'DVD（クリア）';
  }
  return img;
}

function showPlayerMenu() {
  closeCoverLightbox();
  uiState = 'playerMenu';
  destroyPlayer();
  app.classList.remove('state-hidden');
  app.setAttribute('aria-hidden', 'false');
  app.innerHTML = '';

  var panel = document.createElement('div');
  panel.className = 'overlay-panel';
  if (currentPack === 'tall') {
    panel.classList.add('overlay-panel--tall');
  }

  panel.appendChild(buildPlayerArtWrap());

  var col = document.createElement('div');
  col.className = 'menu-col';

  var h = document.createElement('h2');
  h.innerHTML = 'タイトル: ' + escapeHtml(currentTitle || '（無題）');

  var bPlay = document.createElement('button');
  bPlay.type = 'button';
  bPlay.className = 'btn btn-primary';
  bPlay.textContent = '再生';
  bPlay.addEventListener('click', onPlayClick);

  var bCancel = document.createElement('button');
  bCancel.type = 'button';
  bCancel.className = 'btn btn-secondary';
  bCancel.textContent = '取り消し';
  bCancel.addEventListener('click', onCloseClick);

  col.appendChild(h);
  col.appendChild(bPlay);
  col.appendChild(bCancel);

  panel.appendChild(col);
  app.appendChild(panel);
}

function onPlayClick() {
  var id = extractYouTubeId(currentUrl);
  if (!id) {
    showPlayerMenu();
    return;
  }
  showPlaying(id);
}

function loadYouTubeApi() {
  return new Promise(function (resolve) {
    if (window.YT && window.YT.Player) {
      resolve();
      return;
    }
    var tag = document.createElement('script');
    tag.src = 'https://www.youtube.com/iframe_api';
    window.onYouTubeIframeAPIReady = function () {
      resolve();
    };
    document.head.appendChild(tag);
  });
}

function showPlaying(videoId) {
  closeCoverLightbox();
  uiState = 'playing';
  app.classList.remove('state-hidden');
  app.setAttribute('aria-hidden', 'false');
  app.innerHTML = '';

  var wrap = document.createElement('div');
  wrap.className = 'playing-wrap';

  var holder = document.createElement('div');
  holder.id = 'yt-player';

  var stopBtn = document.createElement('button');
  stopBtn.type = 'button';
  stopBtn.className = 'btn btn-secondary btn-stop';
  stopBtn.textContent = '停止してメニューに戻る';
  stopBtn.addEventListener('click', onStopPlayback);

  wrap.appendChild(holder);
  wrap.appendChild(stopBtn);
  app.appendChild(wrap);

  loadYouTubeApi().then(function () {
    destroyPlayer();
    ytPlayer = new YT.Player('yt-player', {
      videoId: videoId,
      playerVars: {
        autoplay: 1,
        rel: 0,
        modestbranding: 1,
      },
      events: {
        onStateChange: function (ev) {
          if (ev.data === YT.PlayerState.ENDED) {
            onStopPlayback();
          }
        },
      },
    });
  });
}

function onStopPlayback() {
  nuiPost('playbackEnded', {});
  destroyPlayer();
  showPlayerMenu();
}

function onSaveClick() {
  var tEl = document.getElementById('dm-title');
  var uEl = document.getElementById('dm-url');
  var pEl = document.getElementById('dm-pack');
  var cEl = document.getElementById('dm-cover');
  var title = tEl ? tEl.value.trim() : '';
  var url = uEl ? uEl.value.trim() : '';
  var pack = pEl ? pEl.value : 'clear';
  var coverUrl = cEl && pEl && pEl.value === 'tall' ? normalizeCoverImageUrl(cEl.value) : '';
  if (!title || !url) return;
  if (pack === 'tall' && coverUrl && isLikelyNonDirectImagePageUrl(coverUrl)) {
    var ok = window.confirm(
      '表紙に指定した URL は Google フォトの「共有アルバム／共有ページ」に見えます。\n' +
        'この種の URL は画像ファイルそのものではないため、ゲーム内では表示できないことがほとんどです。\n' +
        '（対応には画像の直リンクが必要です。imgbb や自サーバーの .png などを推奨します。）\n\n' +
        'それでも保存を試しますか？'
    );
    if (!ok) return;
  }
  /* dvdPack / pack 両方送る（Lua 側でいずれかを採用） */
  nuiPost('save', { title: title, url: url, dvdPack: pack, pack: pack, coverUrl: coverUrl });
}

function onCloseClick(ev) {
  if (ev) {
    ev.preventDefault();
    ev.stopPropagation();
  }
  if (uiState === 'hidden') return;
  nuiPostAsync('close', {})
    .catch(function () {})
    .finally(function () {
      setHidden();
    });
}

window.addEventListener('message', function (event) {
  var d = event.data;
  if (!d || typeof d !== 'object') return;

  if (d.action === 'setState' && d.state === 'hidden') {
    setHidden();
    return;
  }
  if (d.action === 'openCreate') {
    showCreate();
    return;
  }
  if (d.action === 'openPlayer') {
    currentTitle = typeof d.title === 'string' ? d.title : '';
    currentUrl = typeof d.url === 'string' ? d.url : '';
    currentPack = typeof d.pack === 'string' ? d.pack : 'clear';
    if (currentPack !== 'fushokufu' && currentPack !== 'clear' && currentPack !== 'tall') {
      currentPack = 'clear';
    }
    currentCoverUrl = normalizeCoverImageUrl(typeof d.coverUrl === 'string' ? d.coverUrl : '');
    showPlayerMenu();
  }
});

/** ESC: CEF 側。iframe 内フォーカス時は効かない場合があるため client でも拾う */
window.addEventListener(
  'keydown',
  function (e) {
    if (e.key !== 'Escape') return;
    if (coverLightboxEl) {
      e.preventDefault();
      e.stopPropagation();
      closeCoverLightbox();
      return;
    }
    if (uiState === 'hidden') return;
    e.preventDefault();
    e.stopPropagation();
    if (uiState === 'playing') {
      onStopPlayback();
    } else {
      onCloseClick();
    }
  },
  true
);
