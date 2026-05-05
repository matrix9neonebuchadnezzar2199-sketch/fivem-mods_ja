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
      '#pls-wiki-scroll .pls-wiki-inner p{margin:8px 0;color:#cbd5e1;}' +
      '#pls-wiki-scroll .pls-wiki-inner .pls-wiki-lead{font-size:0.95rem;opacity:.92;margin-bottom:14px;}' +
      '#pls-wiki-scroll .pls-wiki-inner code{background:rgba(255,255,255,.08);padding:2px 6px;border-radius:4px;font-size:.88em;}' +
      '#pls-wiki-scroll .pls-wiki-inner .pls-wiki-foot{margin-top:22px;font-size:.82rem;opacity:.55;}' +
      '#pls-wiki-scroll .pls-wiki-tree{margin:12px 0;border:1px solid rgba(255,255,255,.1);border-radius:12px;padding:6px 10px;background:rgba(0,0,0,.22);}' +
      '#pls-wiki-scroll .pls-wiki-tree > summary{font-size:1.05rem;font-weight:700;color:#a5b4fc;padding:10px 8px;cursor:pointer;list-style:none;}' +
      '#pls-wiki-scroll .pls-wiki-tree > summary::-webkit-details-marker{display:none;}' +
      '#pls-wiki-scroll .pls-wiki-tree details{margin:8px 0 8px 8px;border-left:2px solid rgba(99,102,241,.45);padding:4px 0 4px 14px;}' +
      '#pls-wiki-scroll .pls-wiki-tree details > summary{font-weight:600;color:#e2e8f0;cursor:pointer;padding:6px 4px;list-style:none;font-size:0.95rem;}' +
      '#pls-wiki-scroll .pls-wiki-tree details > summary::-webkit-details-marker{display:none;}' +
      '#pls-wiki-scroll .pls-wiki-tree .pls-wiki-body{padding:4px 4px 10px 4px;color:#cbd5e1;font-size:0.92rem;line-height:1.55;}' +
      '#pls-wiki-scroll .pls-wiki-tree ol,#pls-wiki-scroll .pls-wiki-tree ul{margin:6px 0;padding-left:1.25rem;}' +
      '#pls-wiki-scroll .pls-wiki-tree li{margin:5px 0;}' +
      '#pls-wiki-scroll .pls-wiki-tree dl{margin:6px 0;}' +
      '#pls-wiki-scroll .pls-wiki-tree dt{font-weight:600;color:#e2e8f0;margin-top:8px;}' +
      '#pls-wiki-scroll .pls-wiki-tree dd{margin:4px 0 6px 12px;color:#94a3b8;}';
    document.head.appendChild(s);
  }

  function isCreativeVisible() {
    var t = document.body.innerText || '';
    return t.indexOf('CREATIVE MODE') !== -1 || t.indexOf('BY PLS SCRIPTS') !== -1;
  }

  function wikiHtml() {
    return (
      '<div class="pls-wiki-inner">' +
      '<h1>PLS Job System 説明書（WIKI）</h1>' +
      '<p class="pls-wiki-lead">下のツリーを開きながら読むと迷いにくいです。<strong>「やりたいことから逆引き」</strong>で手順を追えます。</p>' +

      '<details class="pls-wiki-tree" open>' +
      '<summary>1. はじめに — 誰が・何のために使う？</summary>' +
      '<div class="pls-wiki-body">' +
      '<details><summary>このツールは何？</summary><div class="pls-wiki-body">' +
      '<p><strong>クリエイティブモード</strong>（<code>/open_jobs</code>）は、サーバー上の<strong>ジョブ拠点のデータ</strong>（作業台・ショップ・スタッシュ・NPC・ブリップ・レジ・アラーム等）を<strong>編集・配置するマスタ管理UI</strong>です。' +
      'ここで決めた内容は <code>server/jobs.json</code> に保存され、プレイヤーがゲーム内で触れるインタラクションの土台になります。</p></div></details>' +
      '<details><summary>店長が使うもの？</summary><div class="pls-wiki-body">' +
      '<p><strong>デフォルトの想定は「店長（RP）」ではなく、サーバー運営・開発者（管理者権限）です。</strong></p>' +
      '<ul>' +
      '<li>通常、<code>/open_jobs</code> は <strong>admin / 運営アカウント</strong>だけが実行できるようフレームワーク側で縛ります。</li>' +
      '<li>IC の「店長」が現場で触るのは、運営がここで配置した<strong>レジ・倉庫・クラフト台・ボスメニュー地点</strong>など<strong>ゲーム内のインタラクション</strong>です。</li>' +
      '<li>RP 上の店長に設定画面まで任せたい場合は、<strong>その人に管理者権限を渡す</strong>などの設計になります（セキュリティは運営判断）。</li>' +
      '</ul></div></details>' +
      '<details><summary>プレイヤー向けとの違い</summary><div class="pls-wiki-body">' +
      '<ul>' +
      '<li><strong>クリエイティブUI</strong> … 運営が「どこに何を出すか」を決める。</li>' +
      '<li><strong>ゲーム内メニュー</strong> … 一般プレイヤー／従業員が買い物・クラフト・スタッシュ等を使う。</li>' +
      '</ul></div></details>' +
      '</div></details>' +

      '<details class="pls-wiki-tree" open>' +
      '<summary>2. やりたいことから逆引き（フロー）</summary>' +
      '<div class="pls-wiki-body">' +
      '<p style="opacity:.85;margin-top:0;">目的を選び、手順を上から順に進めます。</p>' +

      '<details><summary>新しい店・会社の「ジョブ拠点」をゼロから作りたい</summary><div class="pls-wiki-body">' +
      '<ol>' +
      '<li>ESX / QBCore / OX などで<strong>ジョブ名を先に登録</strong>（本スクリプトはDBへ自動登録しません）。</li>' +
      '<li><code>BRIDGE/config.lua</code> でフレームワーク・インベントリ・ターゲットをサーバーに合わせる。</li>' +
      '<li>クリエイティブで <strong>新しいジョブ</strong> → 内部ジョブ名・表示ラベル・エリアを入力。</li>' +
      '<li>右パネルで <strong>Craftings / Shops / Stashes …</strong> を追加し、それぞれ <strong>Set Position</strong> で座標確定。</li>' +
      '<li><strong>FEATURES</strong> でレジ・アラーム・ボス地点を必要なら配置。</li>' +
      '<li><strong>保存</strong>。問題があれば <strong>Pull</strong> や <code>restart pls_jobsystem</code>。</li>' +
      '</ol></div></details>' +

      '<details><summary>カウンターにレジ（会計地点）を置きたい</summary><div class="pls-wiki-body">' +
      '<ol>' +
      '<li>対象ジョブを開く → <strong>FEATURES</strong> の <strong>レジ（Cash register）</strong>。</li>' +
      '<li><strong>Set Position</strong> → カウンター前などに移動 → <strong>[ E ]</strong> で確定。</li>' +
      '<li><strong>保存</strong>。</li>' +
      '</ol></div></details>' +

      '<details><summary>倉庫（スタッシュ）を置きたい</summary><div class="pls-wiki-body">' +
      '<ol>' +
      '<li><strong>Stashes</strong> でスタッシュを追加 → <strong>Set Position</strong>。</li>' +
      '<li>従業員のみ／全員などアクセス範囲・スロット・重量を設定。</li>' +
      '<li>インベントリ種別は <code>BRIDGE</code> 依存（ox / qb / quasar 等）。</li>' +
      '</ol></div></details>' +

      '<details><summary>クラフト台を置きたい</summary><div class="pls-wiki-body">' +
      '<ol>' +
      '<li><strong>Craftings</strong> でステーション追加 → 位置確定。</li>' +
      '<li>レシピ・材料・時間・アニメーションを設定。</li>' +
      '<li>手順式にしたい場合は <strong>Interactive Craftings</strong> を検討。</li>' +
      '</ol></div></details>' +

      '<details><summary>地図に店のマークを出したい</summary><div class="pls-wiki-body">' +
      '<ol>' +
      '<li><strong>Blips</strong> を追加 → 位置・スプライト・色・名前を設定。</li>' +
      '</ol></div></details>' +

      '<details><summary>NPC を置いてメニュー導線を作りたい</summary><div class="pls-wiki-body">' +
      '<ol>' +
      '<li><strong>NPCs</strong> でモデル名・位置・アニメ等を設定。</li>' +
      '</ol></div></details>' +

      '<details><summary>強盗・事件で警察に通報させたい</summary><div class="pls-wiki-body">' +
      '<ol>' +
      '<li><strong>アラーム</strong> を Set Position。</li>' +
      '<li><code>config.lua</code> の <code>SendDispatch</code> を、使っている通報スクリプトに合わせて実装。</li>' +
      '</ol></div></details>' +

      '<details><summary>ボスメニューをこのジョブから開きたい</summary><div class="pls-wiki-body">' +
      '<ol>' +
      '<li><strong>Boss menu</strong> 地点を Set Position。</li>' +
      '<li><code>config.lua</code> の <code>openBossmenu</code> を esx_society / qb-management 等に接続。</li>' +
      '</ol></div></details>' +

      '<details><summary>編集前に逃げ道（バックアップ）を残したい</summary><div class="pls-wiki-body">' +
      '<ol>' +
      '<li>サイドバー下の <strong>Create Backup</strong>。</li>' +
      '<li>事故ったら <strong>Restore Backup</strong>（<code>server/backup.json</code>）。</li>' +
      '</ol></div></details>' +

      '<details><summary>設定を変えたのにゲーム内で古いまま</summary><div class="pls-wiki-body">' +
      '<ol>' +
      '<li>クリエイティブで <strong>保存</strong>したか確認。</li>' +
      '<li><strong>Pull for ME / ALL</strong> で再同期。</li>' +
      '<li><code>refresh</code> → <code>restart pls_jobsystem</code>、プレイヤーは再接続や NUI 再読込。</li>' +
      '</ol></div></details>' +

      '</div></details>' +

      '<details class="pls-wiki-tree">' +
      '<summary>3. 機能別インデックス（ツリー）</summary>' +
      '<div class="pls-wiki-body">' +

      '<details><summary>クリエイティブ画面の左サイドバー</summary><div class="pls-wiki-body">' +
      '<ul>' +
      '<li><strong>新しいジョブ</strong> … データ上のジョブエントリを追加（フレームワーク登録は別作業）。</li>' +
      '<li><strong>ジョブ一覧</strong> … 選択中ジョブの右パネルが切り替わる。</li>' +
      '<li><strong>Pull for ME / ALL</strong> … サーバーの定義をクライアント側へ再配布・スタッシュ再登録等。</li>' +
      '<li><strong>Backup / Restore</strong> … <code>jobs.json</code> の保険。</li>' +
      '<li><strong>説明書（本件）</strong> … この WIKI。</li>' +
      '</ul></div></details>' +

      '<details><summary>右パネル — 設定（Rename / エリアサイズ）</summary><div class="pls-wiki-body">' +
      '<p>表示名・作業エリア半径など。変更後は<strong>保存</strong>。</p></div></details>' +

      '<details><summary>FEATURES（レジ / アラーム / Boss menu）</summary><div class="pls-wiki-body">' +
      '<dl>' +
      '<dt>レジ</dt><dd>売上・会計インタラクト。Set Position で設置。</dd>' +
      '<dt>アラーム</dt><dd>通報フック。Dispatch は <code>SendDispatch</code>。</dd>' +
      '<dt>Boss menu</dt><dd>経営メニュー。実体は <code>openBossmenu</code> 連携。</dd>' +
      '</dl></div></details>' +

      '<details><summary>Craftings / Interactive Craftings</summary><div class="pls-wiki-body">' +
      '<p>クラフトステーションとレシピ。インタラクティブは手順式演出向け。</p></div></details>' +

      '<details><summary>Shops / Stashes / NPCs / Blips / Props</summary><div class="pls-wiki-body">' +
      '<ul>' +
      '<li><strong>Shops</strong> … 販売品・価格・通貨。</li>' +
      '<li><strong>Stashes</strong> … 倉庫。公開範囲と容量。</li>' +
      '<li><strong>NPCs</strong> … ペド配置。</li>' +
      '<li><strong>Blips</strong> … マップアイコン。</li>' +
      '<li><strong>Props</strong> … オブジェクト。ギズモで姿勢調整。</li>' +
      '</ul></div></details>' +

      '<details><summary>Set Position（共通）</summary><div class="pls-wiki-body">' +
      '<p>ワールド座標の登録。<strong>Not created</strong> → ボタンで移動 → <strong>[ E ]</strong> 確定 → 保存、の流れが基本です。</p>' +
      '</div></details>' +

      '</div></details>' +

      '<details class="pls-wiki-tree">' +
      '<summary>4. ファイル・設定の参照先</summary>' +
      '<div class="pls-wiki-body">' +
      '<ul>' +
      '<li><code>server/jobs.json</code> … ジョブ定義本体。</li>' +
      '<li><code>server/backup.json</code> … バックアップ。</li>' +
      '<li><code>BRIDGE/config.lua</code> … ESX/QB/OX・インベントリ・ターゲット。</li>' +
      '<li><code>config.lua</code> … ロケール・Dispatch・Bossmenu・画像パス等。</li>' +
      '<li>リポジトリの <code>docs/INSTALL_JA.md</code> <code>docs/USAGE_JA.md</code> も併読推奨。</li>' +
      '</ul></div></details>' +

      '<p class="pls-wiki-foot">日本語化フォーク用 WIKI（注入スクリプト: creative_wiki_inject.js）／原作: polisek · PLS SCRIPTS</p>' +
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
      'background:rgba(0,0,0,.55);padding:12px;box-sizing:border-box;');
    wrap.innerHTML =
      '<div style="position:relative;width:min(1840px,98vw);max-height:90vh;overflow:hidden;display:flex;' +
      'flex-direction:column;background:linear-gradient(145deg,#1a1a2eee,#12121cfa);border:1px solid rgba(255,255,255,.12);' +
      'border-radius:16px;box-shadow:0 24px 80px rgba(0,0,0,.5);font-family:Inter,system-ui,sans-serif;color:#e8e8ef;">' +
      '<div style="display:flex;align-items:center;justify-content:space-between;padding:14px 18px;border-bottom:1px solid rgba(255,255,255,.1);">' +
      '<span style="font-size:1.1rem;font-weight:600;">📖 説明書（全機能 WIKI · ツリー）</span>' +
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
      '<div style="opacity:.75;font-size:0.82rem;margin-top:2px;">運営向け · 逆引きフロー · 機能ツリー</div></div>' +
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
