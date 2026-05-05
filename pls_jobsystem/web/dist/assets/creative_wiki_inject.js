/**
 * pls_jobsystem クリエイティブモード用: ジョブ一覧下に「説明書」を差し込み、WIKI モーダルを表示する。
 * React バンドル非改変（index.html からのみ読込）
 */
(function () {
  'use strict';

  var ROW_ID = 'pls-wiki-inject-row';
  var MODAL_ID = 'pls-wiki-modal-root';

  function ensureWikiStyles() {
    if (document.getElementById('pls-wiki-styles')) return;
    var s = document.createElement('style');
    s.id = 'pls-wiki-styles';
    s.textContent =
      '#pls-wiki-scroll .pls-wiki-inner h1{font-size:1.35rem;margin:0 0 12px;font-weight:700;color:#fff;}' +
      '#pls-wiki-scroll .pls-wiki-inner h2{font-size:1.05rem;margin:18px 0 8px;color:#a5b4fc;font-weight:600;}' +
      '#pls-wiki-scroll .pls-wiki-inner p{margin:8px 0;color:#cbd5e1;}' +
      '#pls-wiki-scroll .pls-wiki-inner .pls-wiki-lead{font-size:0.95rem;opacity:.9;}' +
      '#pls-wiki-scroll .pls-wiki-inner ul,#pls-wiki-scroll .pls-wiki-inner dl{margin:6px 0 6px 1rem;padding:0;}' +
      '#pls-wiki-scroll .pls-wiki-inner li{margin:6px 0;color:#e2e8f0;}' +
      '#pls-wiki-scroll .pls-wiki-inner dt{margin-top:10px;font-weight:600;color:#e2e8f0;}' +
      '#pls-wiki-scroll .pls-wiki-inner dd{margin:4px 0 8px 0;color:#94a3b8;}' +
      '#pls-wiki-scroll .pls-wiki-inner code{background:rgba(255,255,255,.08);padding:2px 6px;border-radius:4px;font-size:.88em;}' +
      '#pls-wiki-scroll .pls-wiki-inner .pls-wiki-foot{margin-top:20px;font-size:.82rem;opacity:.6;}';
    document.head.appendChild(s);
  }

  function isCreativeVisible() {
    var t = document.body.innerText || '';
    return t.indexOf('CREATIVE MODE') !== -1 || t.indexOf('BY PLS SCRIPTS') !== -1;
  }

  function wikiHtml() {
    return (
      '<div class="pls-wiki-inner">' +
      '<h1>PLS Job System 説明書（運営向け）</h1>' +
      '<p class="pls-wiki-lead">クリエイティブモードでジョブの置き場所・機能を編集する手順と用語です。</p>' +

      '<h2>ジョブ一覧と保存</h2>' +
      '<ul>' +
      '<li><strong>新しいジョブ</strong> … フレームワーク側に登録済みの<strong>内部ジョブ名</strong>でジョブを追加します。</li>' +
      '<li>各ジョブを開くと、右パネルで<strong>設定・各機能</strong>を編集できます。</li>' +
      '<li>変更後は<strong>保存</strong>を忘れずに。データはサーバーの <code>server/jobs.json</code> に保存されます。</li>' +
      '</ul>' +

      '<h2>Set Position（位置の決め方）</h2>' +
      '<ul>' +
      '<li><strong>Set Position</strong> は、その機能を<strong>ゲーム内のどこに出すか</strong>を決めるボタンです。</li>' +
      '<li>押したあと、置きたい場所に移動し、案内に従って <strong>[ E ]</strong> などで座標を確定します。</li>' +
      '<li><strong>Not created</strong> はまだ座標が未登録です。Set Position で作成済みにできます。</li>' +
      '</ul>' +

      '<h2>主な機能（FEATURES 周り）</h2>' +
      '<dl>' +
      '<dt>レジ（Cash register）</dt><dd>会計・売上まわりのインタラクト地点。従業員ジョブでのみ利用する想定です。</dd>' +
      '<dt>アラーム</dt><dd>通報用。<code>config.lua</code> の <code>SendDispatch</code> に接続し、警察向け通知を飛ばせます。</dd>' +
      '<dt>Boss menu</dt><dd>ボスメニュー。<code>openBossmenu</code> でお使いの社会系スクリプトを呼び出します。</dd>' +
      '</dl>' +

      '<h2>作業台・クラフト（Craftings）</h2>' +
      '<ul>' +
      '<li>レシピ・材料・時間・アニメーションを設定します。</li>' +
      '<li><strong>インタラクティブクラフト</strong>は手順式のクラフト演出にも対応します。</li>' +
      '</ul>' +

      '<h2>ショップ / スタッシュ / NPC / ブリップ / プロップ</h2>' +
      '<ul>' +
      '<li><strong>ショップ</strong> … 販売アイテム・価格・通貨（現金/銀行など）。</li>' +
      '<li><strong>スタッシュ</strong> … 倉庫。従業員のみ／全員などアクセス範囲を設定。インベントリは BRIDGE 設定に依存します。</li>' +
      '<li><strong>NPC</strong> … ペドモデルと位置。話しかけ導線の起点に使えます。</li>' +
      '<li><strong>ブリップ</strong> … マップ表示。スプライト・色・名前を設定します。</li>' +
      '<li><strong>プロップ</strong> … オブジェクト配置（ギズモで調整）。</li>' +
      '</ul>' +

      '<h2>Pull / バックアップ</h2>' +
      '<ul>' +
      '<li><strong>Pull for ME / ALL</strong> … サーバー側のジョブ定義を再読込し、スタッシュ登録などを同期します。</li>' +
      '<li><strong>Create Backup / Restore</strong> … <code>server/backup.json</code> の作成・復元。編集前の保険に使います。</li>' +
      '</ul>' +

      '<h2>困ったとき</h2>' +
      '<ul>' +
      '<li>フォルダ名は必ず <code>pls_jobsystem</code>（リソース名チェックあり）。</li>' +
      '<li>フレームワークは <code>BRIDGE/config.lua</code> の <code>BRIDGE.Framework</code> をサーバーに合わせる（Qbox なら QB 等）。</li>' +
      '<li>詳細ドキュメント: リポジトリの <code>pls_jobsystem/docs/</code>（INSTALL_JA / USAGE_JA など）。</li>' +
      '</ul>' +

      '<p class="pls-wiki-foot">日本語化フォーク用の説明です。原作: polisek / PLS SCRIPTS</p>' +
      '</div>'
    );
  }

  function openModal() {
    if (document.getElementById(MODAL_ID)) return;
    ensureWikiStyles();
    var wrap = document.createElement('div');
    wrap.id = MODAL_ID;
    wrap.setAttribute('style',
      'position:fixed;inset:0;z-index:2147483646;display:flex;align-items:center;justify-content:center;' +
      'background:rgba(0,0,0,.55);padding:16px;box-sizing:border-box;');
    wrap.innerHTML =
      '<div style="position:relative;width:min(920px,96vw);max-height:88vh;overflow:hidden;display:flex;' +
      'flex-direction:column;background:linear-gradient(145deg,#1a1a2eee,#12121cfa);border:1px solid rgba(255,255,255,.12);' +
      'border-radius:16px;box-shadow:0 24px 80px rgba(0,0,0,.5);font-family:Inter,system-ui,sans-serif;color:#e8e8ef;">' +
      '<div style="display:flex;align-items:center;justify-content:space-between;padding:14px 18px;border-bottom:1px solid rgba(255,255,255,.1);">' +
      '<span style="font-size:1.1rem;font-weight:600;">📖 説明書（全機能 WIKI）</span>' +
      '<button type="button" id="pls-wiki-close" style="cursor:pointer;background:rgba(255,255,255,.08);border:1px solid rgba(255,255,255,.15);' +
      'color:#fff;border-radius:8px;padding:6px 14px;font-size:0.9rem;">閉じる</button></div>' +
      '<div id="pls-wiki-scroll" style="overflow-y:auto;padding:18px 22px 24px;line-height:1.55;font-size:0.95rem;">' +
      wikiHtml() + '</div></div>';
    document.body.appendChild(wrap);
    document.getElementById('pls-wiki-close').onclick = function () {
      wrap.remove();
    };
    wrap.onclick = function (ev) {
      if (ev.target === wrap) wrap.remove();
    };
  }

  function makeRow() {
    var row = document.createElement('div');
    row.id = ROW_ID;
    row.setAttribute('style',
      'display:flex;align-items:center;gap:10px;margin-top:10px;padding:12px 14px;cursor:pointer;' +
      'background:rgba(99,102,241,.12);border:1px solid rgba(99,102,241,.35);border-radius:12px;color:#e8e8ef;' +
      'font-family:Inter,system-ui,sans-serif;font-size:0.95rem;user-select:none;');
    row.innerHTML =
      '<span style="font-size:1.35rem;line-height:1;" aria-hidden="true">📖</span>' +
      '<div style="flex:1;"><div style="font-weight:600;">説明書</div>' +
      '<div style="opacity:.75;font-size:0.82rem;margin-top:2px;">全機能の見方・Set Position・保存</div></div>' +
      '<span style="opacity:.5;">›</span>';
    row.onclick = function (e) {
      e.stopPropagation();
      openModal();
    };
    return row;
  }

  function findJobSectionAnchor() {
    var nodes = document.querySelectorAll('#root *');
    var i;
    var el;
    var txt;
    for (i = 0; i < nodes.length; i++) {
      el = nodes[i];
      if (el.children.length > 0) continue;
      txt = (el.textContent || '').trim();
      if (txt === 'ジョブ' || txt === 'Jobs' || txt === 'JOBS') {
        var next = el.nextElementSibling;
        if (next) return next;
        return el.parentElement;
      }
    }
    var buttons = document.querySelectorAll('#root button');
    for (i = 0; i < buttons.length; i++) {
      txt = (buttons[i].textContent || '').trim();
      if (/新しいジョブ|New Job|Create new job/i.test(txt)) {
        var p = buttons[i].parentElement;
        if (p && p.nextElementSibling) {
          var sib = p.nextElementSibling;
          var scroll = sib.querySelector('[class*="overflow-y"]');
          return scroll || sib;
        }
      }
    }
    return null;
  }

  function tryInject() {
    if (!isCreativeVisible()) return;
    if (document.getElementById(ROW_ID)) return;

    var anchor = findJobSectionAnchor();
    if (!anchor) return;

    anchor.appendChild(makeRow());
  }

  var root = document.getElementById('root');
  if (!root) return;

  var t = null;
  var obs = new MutationObserver(function () {
    clearTimeout(t);
    t = setTimeout(tryInject, 120);
  });
  obs.observe(root, { childList: true, subtree: true });

  document.addEventListener('DOMContentLoaded', function () {
    setTimeout(tryInject, 400);
  });
  setTimeout(tryInject, 800);
})();
