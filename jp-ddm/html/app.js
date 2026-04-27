/* global YT */
(function () {
    'use strict';

    const resName = () =>
        typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'jp-ddm';

    let catalog = [];
    let historyCatalog = [];
    let maxSlots = 64;
    let defaultDuration = 10;
    let ytPlayer = null;
    let ytReady = false;
    let miniPaused = false;
    let pendingYoutube = null;
    let audioEnabled = true;

    const $ = (id) => document.getElementById(id);

    function updateAudioButton() {
        const b = $('btn-youtube-audio');
        if (!b) return;
        b.textContent = audioEnabled ? '🔊 音声ON' : '🔇 音声OFF';
        b.classList.toggle('muted', !audioEnabled);
    }

    function toggleMuteUser() {
        audioEnabled = !audioEnabled;
        if (ytReady && ytPlayer) {
            try {
                if (audioEnabled) {
                    ytPlayer.unMute();
                } else {
                    ytPlayer.mute();
                }
            } catch (e) {
                /* cef */
            }
        }
        updateAudioButton();
    }

    async function nuiPost(name, data) {
        try {
            await fetch(`https://${resName()}/${name}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(data || {}),
            });
        } catch (e) {
            console.warn('nui', name, e);
        }
    }

    function showToast(msg, err) {
        const t = $('toast');
        t.textContent = msg;
        t.classList.remove('hidden', 'error');
        if (err) t.classList.add('error');
        t.classList.remove('hidden');
        setTimeout(() => t.classList.add('hidden'), 2800);
    }

    function formatTotal(sec) {
        const m = Math.floor(sec / 60);
        const s = sec % 60;
        return `${m}'${s.toString().padStart(2, '0')}`;
    }

    function setMiniReopenHint(reopenKey, openCommand) {
        const el = $('mini-hint');
        if (!el) return;
        const k = reopenKey && String(reopenKey).trim() ? String(reopenKey).trim() : 'F12';
        const c = openCommand && String(openCommand).trim() ? String(openCommand).trim() : 'ddm';
        const esc = (s) =>
            s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
        el.innerHTML = `<strong>${esc(k)}</strong> または <code>/${esc(c)}</code> で管理に戻る（<span class="mini-hint-sub">本番中はマウス操作できません</span>）`;
    }

    function refreshSetlistRowNumbers() {
        const items = document.querySelectorAll('#setlist li');
        items.forEach((li, i) => {
            const n = li.querySelector('.set-num');
            if (n) n.textContent = `#${i + 1}`;
        });
    }

    function getSetlistItems() {
        const ul = $('setlist');
        const out = [];
        ul.querySelectorAll('li[data-dict]').forEach((li) => {
            const sec = parseInt(li.querySelector('.set-sec')?.value, 10) || 1;
            out.push({
                name: li.getAttribute('data-name') || li.getAttribute('data-clip'),
                dict: li.getAttribute('data-dict'),
                clip: li.getAttribute('data-clip'),
                duration: sec,
            });
        });
        return out;
    }

    function renumberSetlist() {
        const items = getSetlistItems();
        let total = 0;
        items.forEach((x) => {
            total += x.duration || 0;
        });
        $('total-dur').textContent = formatTotal(total);
        $('set-count').textContent = String(items.length);
        refreshSetlistRowNumbers();
    }

    /** 1モーションをゲーム内で試聴（カタログ行／セット行のクリック用） */
    async function playMotionPreview(dict, clip, nameLabel) {
        if (!dict || !clip) return;
        const r = await nuiFetch('preview', { dict, clip });
        if (r && r.err === 'noload') {
            showToast('⚠ このモーションは読み込めません: ' + (nameLabel || clip), true);
        } else if (r && r.err) {
            showToast('⚠ 試聴に失敗しました', true);
        } else {
            showToast('▶ 試聴: ' + (nameLabel || clip));
        }
    }

    function addSetlistItem(item) {
        if (getSetlistItems().length >= maxSlots) {
            showToast('⚠ 上限に達しています', true);
            return;
        }
        const ul = $('setlist');
        const li = document.createElement('li');
        li.setAttribute('data-dict', item.dict);
        li.setAttribute('data-clip', item.clip);
        li.setAttribute('data-name', item.name || item.clip);
        const dur0 = item.duration || defaultDuration;
        li.innerHTML = `<span class="set-num">#</span><span class="sep">|</span>
            <span class="set-name"></span>
            <span class="sep">|</span>
            <div class="set-dur-ctrl">
                <button type="button" class="step" data-step="-1">-</button>
                <input class="set-sec" type="number" min="1" max="600" value="${dur0}" />
                <button type="button" class="step" data-step="1">+</button>
            </div>
            <span class="sep">|</span>
            <button type="button" class="set-remove" title="削除">🗑</button>`;
        ul.appendChild(li);
        li.querySelector('.set-name').textContent = item.name || item.clip;

        const input = li.querySelector('.set-sec');
        li.querySelectorAll('.step').forEach((b) => {
            b.addEventListener('click', () => {
                const d = parseInt(b.getAttribute('data-step'), 10) || 0;
                let v = parseInt(input.value, 10) || 1;
                v = Math.min(600, Math.max(1, v + d));
                input.value = String(v);
                renumberSetlist();
            });
        });
        input.addEventListener('input', renumberSetlist);
        li.querySelector('.set-remove').addEventListener('click', () => {
            li.remove();
            renumberSetlist();
        });
        renumberSetlist();
    }

    function clearSetlist() {
        $('setlist').innerHTML = '';
        renumberSetlist();
    }

    function matchCatalogQuery(c, q) {
        if (!q) return true;
        const n = (c.name || '').toLowerCase();
        const d = (c.dict || '').toLowerCase();
        const cl = (c.clip || '').toLowerCase();
        return n.includes(q) || d.includes(q) || cl.includes(q);
    }

    function appendCatalogRow(c) {
        const list = $('catalog-list');
        const li = document.createElement('li');
        const sp = document.createElement('span');
        sp.className = 'cat-name';
        const dur0 = c.defaultDuration || defaultDuration;
        sp.textContent = `${c.name}（${dur0}秒）`;
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'btn-add-cat';
        btn.textContent = '＋追加';
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            addSetlistItem({
                name: c.name,
                dict: c.dict,
                clip: c.clip,
                duration: dur0,
            });
        });
        li.appendChild(sp);
        li.appendChild(btn);
        li.title = '行をクリックで試聴 ／ ＋追加でリストへ';
        li.addEventListener('click', (e) => {
            if (e.target.closest('.btn-add-cat')) return;
            playMotionPreview(c.dict, c.clip, c.name);
        });
        list.appendChild(li);
    }

    function renderCatalog() {
        const list = $('catalog-list');
        const q = ($('catalog-search').value || '').toLowerCase();
        const cat = $('catalog-cat').value;
        list.innerHTML = '';
        (catalog || []).forEach((c) => {
            if (cat !== 'all' && c.category !== cat) return;
            if (!matchCatalogQuery(c, q)) return;
            appendCatalogRow(c);
        });
        if (cat === 'all' || cat === 'other') {
            const hItems = (historyCatalog || []).filter(
                (h) => h && h.dict && h.clip && matchCatalogQuery(h, q)
            );
            if (hItems.length > 0) {
                const sub = document.createElement('li');
                sub.className = 'cat-subhead';
                sub.setAttribute('role', 'separator');
                sub.setAttribute('aria-label', '過去に入力したモーション');
                sub.textContent = '過去に入力したモーション';
                list.appendChild(sub);
                hItems.forEach((c) => appendCatalogRow(c));
            }
        }
    }

    function extractVideoId(url) {
        if (!url || typeof url !== 'string') return null;
        const patterns = [
            /(?:youtube\.com\/watch\?v=)([^&\s]+)/,
            /(?:youtu\.be\/)([^?\s]+)/,
            /(?:youtube\.com\/embed\/)([^?\s]+)/,
        ];
        for (let i = 0; i < patterns.length; i++) {
            const m = url.match(patterns[i]);
            if (m) return m[1];
        }
        return null;
    }

    function applyYouTube(p) {
        if (!p || !p.url) return;
        if (!ytReady || !ytPlayer) {
            pendingYoutube = p;
            return;
        }
        const id = extractVideoId(p.url);
        if (!id) {
            return;
        }
        ytPlayer.loadVideoById({ videoId: id, startSeconds: p.startSeconds || 0 });
        try {
            ytPlayer.playVideo();
        } catch (e) { /* cef */ }
        try {
            if (p.audioEnabled === false) {
                ytPlayer.mute();
            } else {
                ytPlayer.unMute();
            }
        } catch (e) { /* cef */ }
        updateAudioButton();
    }

    function stopYouTube() {
        if (ytReady && ytPlayer) {
            try {
                ytPlayer.stopVideo();
            } catch (e) { /* cef */ }
        }
    }

    window.addEventListener('message', (e) => {
        const d = e.data;
        if (!d || !d.type) return;
        if (d.type === 'openDdm') {
            catalog = d.catalog || [];
            historyCatalog = Array.isArray(d.historyCatalog) ? d.historyCatalog : [];
            maxSlots = d.maxSlots || 64;
            defaultDuration = d.defaultDuration || 10;
            $('set-max').textContent = String(maxSlots);
            $('c-dur').value = String(defaultDuration);
            $('ddm-container').classList.remove('hidden');
            const ps0 = $('preview-status');
            if (ps0) {
                ps0.classList.add('hidden');
                ps0.textContent = '';
            }
            renderCatalog();
            loadPresetList();
        } else if (d.type === 'hideManager') {
            $('ddm-container').classList.add('hidden');
        } else if (d.type === 'showManager') {
            $('ddm-container').classList.remove('hidden');
        } else if (d.type === 'uiClosed') {
            $('ddm-container').classList.add('hidden');
            $('mini-hud').classList.add('hidden');
            const ps = $('preview-status');
            if (ps) {
                ps.classList.add('hidden');
                ps.textContent = '';
            }
        } else if (d.type === 'showMini') {
            $('mini-hud').classList.remove('hidden');
            setMiniReopenHint(d.reopenKey, d.openCommand);
            miniPaused = false;
            updateMiniPauseLabel();
        } else if (d.type === 'hideMini') {
            $('mini-hud').classList.add('hidden');
        } else if (d.type === 'miniTick') {
            const tot = d.total || 0;
            const cur = d.current || 0;
            $('mini-index').textContent = tot ? `${cur}/${tot}` : '0/0';
            $('mini-name').textContent = d.name || '—';
            $('mini-remain').textContent = String(d.remain != null ? d.remain : 0);
            $('mini-loop').textContent = d.loop ? 'ループ: ON' : 'ループ: OFF';
        } else if (d.type === 'previewTick') {
            const tot = d.total || 0;
            const cur = d.current || 0;
            const el = $('preview-status');
            if (el) {
                el.classList.remove('hidden');
                el.textContent = `🎭 プレビュー  ${cur}/${tot || 1}  ${d.name || '—'}  ·  残り${d.remain != null ? d.remain : 0}秒  ${d.loop ? '（ループON）' : ''}`;
            }
        } else if (d.type === 'previewEnd') {
            const el = $('preview-status');
            if (el) {
                el.classList.add('hidden');
                el.textContent = '';
            }
        } else if (d.type === 'playYoutube') {
            const audio = d.audioEnabled !== false;
            audioEnabled = audio;
            updateAudioButton();
            applyYouTube({ url: d.url, startSeconds: d.startSeconds || 0, audioEnabled: audio });
        } else if (d.type === 'stopYoutube') {
            stopYouTube();
        }
    });

    async function nuiFetch(name, payload) {
        const r = await fetch(`https://${resName()}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(payload || {}),
        });
        const t = await r.text();
        try {
            return JSON.parse(t);
        } catch {
            return t;
        }
    }

    function populatePresetSelect(presets) {
        const sel = $('load-select');
        const cur = sel.value;
        sel.innerHTML = '<option value="">-- 読込 --</option>';
        (presets || []).forEach((p) => {
            const o = document.createElement('option');
            o.value = p;
            o.textContent = p;
            sel.appendChild(o);
        });
        if (cur && Array.from(sel.options).some((o) => o.value === cur)) sel.value = cur;
    }

    async function loadPresetList() {
        const res = await nuiFetch('listPresets', {});
        if (res && res.presets) {
            populatePresetSelect(res.presets);
        }
    }

    window.onYouTubeIframeAPIReady = function () {
        ytPlayer = new YT.Player('yt-player', {
            width: 1,
            height: 1,
            playerVars: {
                autoplay: 0,
                controls: 0,
                disablekb: 1,
                playsinline: 1,
                enablejsapi: 1,
            },
            events: {
                onReady: function () {
                    ytReady = true;
                    if (pendingYoutube) {
                        applyYouTube(pendingYoutube);
                        pendingYoutube = null;
                    }
                },
            },
        });
    };

    if ($('btn-panel-close')) {
        $('btn-panel-close').addEventListener('click', () => nuiPost('close', {}));
    }
    if ($('btn-start-preview')) {
        $('btn-start-preview').addEventListener('click', async () => {
            const setlist = getSetlistItems();
            if (setlist.length < 1) {
                showToast('⚠ セットリストが空です', true);
                return;
            }
            const loop = $('loop-toggle').checked;
            await nuiFetch('startPreview', { setlist, loop });
        });
    }
    if ($('btn-mini-reopen')) {
        $('btn-mini-reopen').addEventListener('click', () => nuiPost('reopenManager', {}));
    }
    if ($('btn-mini-close')) {
        $('btn-mini-close').addEventListener('click', () => nuiPost('closeFromMini', {}));
    }
    if ($('btn-youtube-audio')) {
        $('btn-youtube-audio').addEventListener('click', () => toggleMuteUser());
    }
    $('catalog-search').addEventListener('input', renderCatalog);
    $('catalog-cat').addEventListener('change', renderCatalog);

    /** 中段セットリスト: 行クリック＝試聴（数値・🗑・± 以外） */
    $('setlist').addEventListener('click', (e) => {
        const li = e.target.closest('#setlist li[data-dict]');
        if (!li) return;
        if (e.target.closest('button, .set-sec, .set-dur-ctrl')) return;
        const dict = li.getAttribute('data-dict');
        const clip = li.getAttribute('data-clip');
        const name = li.getAttribute('data-name') || clip;
        playMotionPreview(dict, clip, name);
    });

    $('btn-c-add').addEventListener('click', async () => {
        const dict = ($('c-dict').value || '').trim();
        const clip = ($('c-clip').value || '').trim();
        if (!dict || !clip) {
            showToast('⚠ Dict と Clip を入れてください', true);
            return;
        }
        const name = ($('c-name').value || '').trim() || clip;
        const dur = parseInt($('c-dur').value, 10) || defaultDuration;
        addSetlistItem({ name, dict, clip, duration: dur });
        const r = await nuiFetch('rememberCustomMotion', { name, dict, clip, defaultDuration: dur });
        if (r && r.ok && r.historyCatalog) {
            historyCatalog = r.historyCatalog;
            renderCatalog();
        }
    });

    $('btn-start').addEventListener('click', async () => {
        const setlist = getSetlistItems();
        if (setlist.length < 1) {
            showToast('⚠ セットリストが空です', true);
            return;
        }
        const youtubeUrl = ($('youtube-url').value || '').trim();
        const youtubeStart = parseInt($('youtube-start').value, 10) || 0;
        const loop = $('loop-toggle').checked;
        await nuiFetch('startPlayback', { setlist, youtubeUrl, youtubeStart, loop, audioEnabled: audioEnabled });
    });

    $('btn-stop-ui').addEventListener('click', () => nuiPost('stopPlayback', {}));
    $('btn-pause').addEventListener('click', () => nuiPost('togglePause', {}));
    $('btn-next').addEventListener('click', () => nuiPost('nextStep', {}));

    $('btn-save').addEventListener('click', async () => {
        const name = ($('preset-name').value || '').trim();
        if (!name) {
            showToast('⚠ プリセット名を入力', true);
            return;
        }
        const r = await nuiFetch('savePreset', {
            name,
            setlist: getSetlistItems(),
            youtubeUrl: ($('youtube-url').value || '').trim(),
            youtubeStart: parseInt($('youtube-start').value, 10) || 0,
            loop: $('loop-toggle').checked,
            audioEnabled: audioEnabled,
        });
        if (r && r.ok) {
            showToast('💾 保存しました');
            loadPresetList();
        } else showToast('保存に失敗', true);
    });

    $('btn-load').addEventListener('click', async () => {
        const name = $('load-select').value;
        if (!name) {
            showToast('読込名を選んでください', true);
            return;
        }
        const r = await nuiFetch('loadPreset', { name });
        clearSetlist();
        (r.setlist || []).forEach((it) => addSetlistItem(it));
        $('youtube-url').value = r.youtubeUrl || '';
        $('youtube-start').value = r.youtubeStart != null ? String(r.youtubeStart) : '0';
        $('loop-toggle').checked = !!r.loop;
        if (r.audioEnabled === false) {
            audioEnabled = false;
        } else {
            audioEnabled = true;
        }
        if (r.audioEnabled === undefined && r.youtube && r.youtube.audio === false) {
            audioEnabled = false;
        }
        updateAudioButton();
        $('preset-name').value = name;
        showToast('📂 読込: ' + name);
    });

    $('btn-delete').addEventListener('click', async () => {
        const name = ($('preset-name').value || '').trim();
        if (!name) {
            showToast('削除する名を入れてください', true);
            return;
        }
        const r = await nuiFetch('deletePreset', { name });
        if (r && r.ok) {
            showToast('🗑 削除: ' + name);
            loadPresetList();
        }
    });

    function utf8ToB64(s) {
        return btoa(unescape(encodeURIComponent(s)));
    }
    function b64ToUtf8(s) {
        return decodeURIComponent(escape(atob(s)));
    }

    /** FiveM NUI では `navigator.clipboard` が弾かれることが多い → 同期の execCommand を先に */
    function copyTextExecCommand(text) {
        const ta = document.createElement('textarea');
        ta.value = text;
        ta.setAttribute('readonly', '');
        ta.setAttribute('tabindex', '-1');
        ta.setAttribute('aria-hidden', 'true');
        ta.style.cssText = 'position:fixed;inset:0;opacity:0;pointer-events:none;';
        document.body.appendChild(ta);
        ta.select();
        ta.setSelectionRange(0, text.length);
        let ok = false;
        try {
            ok = document.execCommand('copy') === true;
        } catch (e) {
            ok = false;
        }
        document.body.removeChild(ta);
        return ok;
    }

    async function copyStringToClipboard(text) {
        if (copyTextExecCommand(text)) {
            return true;
        }
        if (typeof navigator !== 'undefined' && navigator.clipboard && typeof navigator.clipboard.writeText === 'function') {
            try {
                await navigator.clipboard.writeText(text);
                return true;
            } catch (e) {
                return false;
            }
        }
        return false;
    }

    function openExportFallbackModal(text) {
        const wrap = $('export-fallback-modal');
        const el = $('export-fallback-text');
        if (!wrap || !el) {
            return false;
        }
        el.value = text;
        wrap.classList.remove('hidden');
        setTimeout(() => {
            el.focus();
            el.select();
        }, 100);
        return true;
    }

    function closeExportFallbackModal() {
        const w = $('export-fallback-modal');
        if (w) w.classList.add('hidden');
    }

    async function exportPreset() {
        const presetName = ($('preset-name').value || '').trim() || '無題';
        const youtubeUrl = ($('youtube-url').value || '').trim();
        const youtubeStart = parseInt($('youtube-start').value, 10) || 0;
        const loop = $('loop-toggle').checked;
        const items = getSetlistItems();
        const totalSeconds = items.reduce((sum, i) => sum + (i.duration || 0), 0);
        const totalMin = Math.floor(totalSeconds / 60);
        const totalSec = totalSeconds % 60;

        const jsonData = {
            name: presetName,
            youtube: { url: youtubeUrl, start: youtubeStart, audio: audioEnabled },
            loop: loop,
            setlist: items,
            audioEnabled: audioEnabled,
        };
        const base64 = utf8ToB64(JSON.stringify(jsonData));

        let md = '# 🎬 jp-DDM プリセット\n';
        md += `## プリセット名: ${presetName}\n\n`;
        md += '### 🎵 音楽\n';
        md += `- URL: ${youtubeUrl || 'なし'}\n`;
        md += `- 開始位置: ${youtubeStart}秒\n`;
        md += `- 音声: ${audioEnabled ? 'ON' : 'OFF（ミュート）'}\n\n`;
        md += `### 📋 セットリスト (全${items.length}モーション / 合計 ${totalMin}分${String(totalSec).padStart(2, '0')}秒)\n`;
        md += '| # | モーション | 秒数 | Dict | Clip |\n';
        md += '|---|-----------|------|------|------|\n';
        items.forEach((item, i) => {
            md += `| ${i + 1} | ${item.name} | ${item.duration}秒 | ${item.dict} | ${item.clip} |\n`;
        });
        md += '\n### ⚙ 設定\n';
        md += `- ループ: ${loop ? 'ON' : 'OFF'}\n`;
        md += `- 合計再生時間: ${totalMin}分${String(totalSec).padStart(2, '0')}秒\n\n`;
        md += `<!-- jp-ddm-data:${base64} -->\n`;

        if (await copyStringToClipboard(md)) {
            showToast('📋 クリップボードにコピー');
        } else if (openExportFallbackModal(md)) {
            showToast('下の窓を Ctrl+A → Ctrl+C（自動コピー失敗）');
        } else {
            showToast('コピーに失敗。もう一度お試しください', true);
        }
    }

    function closeImportModal() {
        $('import-modal').classList.add('hidden');
    }

    function showImportDialog() {
        $('import-textarea').value = '';
        $('import-modal').classList.remove('hidden');
        setTimeout(() => $('import-textarea').focus(), 100);
    }

    function executeImport() {
        const text = $('import-textarea').value;
        let m = text.match(/<!--\s*jp-ddm-data:([A-Za-z0-9+/=]+)\s*-->/);
        if (!m) m = text.match(/jp-ddm-data:([A-Za-z0-9+/=]+)/);
        if (!m) {
            showToast('⚠ 有効なプリセットデータが見つかりません', true);
            return;
        }
        const b64 = m[1];
        try {
            const json = JSON.parse(b64ToUtf8(b64));
            clearSetlist();
            (json.setlist || []).forEach((it) =>
                addSetlistItem({
                    name: it.name,
                    dict: it.dict,
                    clip: it.clip,
                    duration: Number(it.duration) || defaultDuration,
                })
            );
            $('youtube-url').value = json.youtube?.url || '';
            $('youtube-start').value = String(json.youtube?.start ?? 0);
            if (json.audioEnabled === false) {
                audioEnabled = false;
            } else {
                audioEnabled = true;
            }
            if (json.youtube && json.youtube.audio === false) {
                audioEnabled = false;
            }
            updateAudioButton();
            $('loop-toggle').checked = !!json.loop;
            $('preset-name').value = json.name || '';
            closeImportModal();
            showToast('📥 完了: ' + (json.name || '無題'));
        } catch (e) {
            showToast('⚠ 解析に失敗: ' + e.message, true);
        }
    }

    $('btn-export').addEventListener('click', () => {
        void exportPreset();
    });
    if ($('btn-export-fallback-close')) {
        $('btn-export-fallback-close').addEventListener('click', () => {
            closeExportFallbackModal();
        });
    }
    $('btn-import').addEventListener('click', showImportDialog);
    $('btn-import-execute').addEventListener('click', executeImport);
    $('btn-import-cancel').addEventListener('click', closeImportModal);

    function updateMiniPauseLabel() {
        const b = $('btn-mini-pause');
        if (b) b.textContent = miniPaused ? '▶' : '⏸';
    }
    $('btn-mini-pause').addEventListener('click', async () => {
        miniPaused = !miniPaused;
        updateMiniPauseLabel();
        await nuiFetch('togglePause', { pause: miniPaused });
    });
    $('btn-mini-next').addEventListener('click', () => nuiPost('nextStep', {}));
    $('btn-mini-stop').addEventListener('click', () => nuiPost('miniStop', {}));

    (function initFoldLeft() {
        const leftAside = document.querySelector('.ddm-left');
        if (!leftAside) return;
        leftAside.addEventListener('click', (e) => {
            const head = e.target.closest('.fold-head');
            if (!head) return;
            e.preventDefault();
            const block = head.closest('.fold-block');
            if (!block) return;
            const nowCollapsed = block.classList.toggle('is-collapsed');
            head.setAttribute('aria-expanded', String(!nowCollapsed));
            const ico = head.querySelector('.fold-ico');
            if (ico) ico.textContent = nowCollapsed ? '▶' : '▼';
        });
    })();

    updateAudioButton();
})();
