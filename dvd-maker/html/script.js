/**
 * DVD Maker NUI — 状態: hidden / create / playerMenu / playing
 */

const app = document.getElementById('app');

let uiState = 'hidden';
let currentTitle = '';
let currentUrl = '';
let ytPlayer = null;

function GetParentResourceName() {
  return window.GetParentResourceName ? window.GetParentResourceName() : 'dvd-maker';
}

/** XSS 対策（テキストを HTML に載せる場合のみ使用） */
function escapeHtml(str) {
  if (str == null) return '';
  return String(str).replace(/[&<>"']/g, function (ch) {
    return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch];
  });
}

function nuiPost(name, data) {
  fetch('https://' + GetParentResourceName() + '/' + name, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  }).catch(function () {});
}

/** YouTube 動画 ID 抽出（埋め込み用） */
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

function setHidden() {
  uiState = 'hidden';
  destroyPlayer();
  app.classList.add('state-hidden');
  app.innerHTML = '';
  app.setAttribute('aria-hidden', 'true');
}

function showCreate() {
  uiState = 'create';
  destroyPlayer();
  app.classList.remove('state-hidden');
  app.setAttribute('aria-hidden', 'false');
  app.innerHTML = '';

  var panel = document.createElement('div');
  panel.className = 'overlay-panel';

  var img = document.createElement('img');
  img.className = 'dvd-img';
  img.src = 'img/disc_128_tight.png';
  img.alt = '空のDVD';

  var col = document.createElement('div');
  col.className = 'menu-col';

  var h = document.createElement('h2');
  h.textContent = 'DVD に記録';

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
  urlIn.type = 'url';
  urlIn.id = 'dm-url';
  urlIn.placeholder = 'https://www.youtube.com/watch?v=...';

  var bSave = document.createElement('button');
  bSave.className = 'btn btn-primary';
  bSave.textContent = '保存';
  bSave.onclick = onSaveClick;

  var bCancel = document.createElement('button');
  bCancel.className = 'btn btn-secondary';
  bCancel.textContent = '取り消し';
  bCancel.onclick = onCloseClick;

  col.appendChild(h);
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

function showPlayerMenu() {
  uiState = 'playerMenu';
  destroyPlayer();
  app.classList.remove('state-hidden');
  app.setAttribute('aria-hidden', 'false');
  app.innerHTML = '';

  var panel = document.createElement('div');
  panel.className = 'overlay-panel';

  var img = document.createElement('img');
  img.className = 'dvd-img';
  img.src = 'img/dvd_case_128_tight.png';
  img.alt = 'DVD';

  var col = document.createElement('div');
  col.className = 'menu-col';

  var h = document.createElement('h2');
  h.innerHTML = 'タイトル: ' + escapeHtml(currentTitle || '（無題）');

  var bPlay = document.createElement('button');
  bPlay.className = 'btn btn-primary';
  bPlay.textContent = '再生';
  bPlay.onclick = onPlayClick;

  var bCancel = document.createElement('button');
  bCancel.className = 'btn btn-secondary';
  bCancel.textContent = '取り消し';
  bCancel.onclick = onCloseClick;

  col.appendChild(h);
  col.appendChild(bPlay);
  col.appendChild(bCancel);

  panel.appendChild(img);
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
  uiState = 'playing';
  app.classList.remove('state-hidden');
  app.setAttribute('aria-hidden', 'false');
  app.innerHTML = '';

  var wrap = document.createElement('div');
  wrap.className = 'playing-wrap';

  var holder = document.createElement('div');
  holder.id = 'yt-player';

  var stopBtn = document.createElement('button');
  stopBtn.className = 'btn btn-secondary btn-stop';
  stopBtn.textContent = '停止してメニューに戻る';
  stopBtn.onclick = onStopPlayback;

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
  var title = tEl ? tEl.value.trim() : '';
  var url = uEl ? uEl.value.trim() : '';
  if (!title || !url) return;
  nuiPost('save', { title: title, url: url });
}

function onCloseClick() {
  nuiPost('close', {});
  setHidden();
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
    showPlayerMenu();
  }
});
