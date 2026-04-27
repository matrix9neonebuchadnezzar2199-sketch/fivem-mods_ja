/* global YT */
(function () {
    'use strict';

    const resName = () =>
        typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'jp-ddm';

    let catalog = [];
    let maxSlots = 64;
    let defaultDuration = 10;
    let ytPlayer = null;
    let ytReady = false;
    let miniPaused = false;
    let pendingYoutube = null;

    const $ = (id) => document.getElementById(id);

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

    function getSetlistItems() {
        const ul = $('setlist');
        const out = [];
        ul.querySelectorAll('li[data-dict]').forEach((li) => {
            const sec = parseInt(li.querySelector('.set-item-sec')?.value, 10) || 10;
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
        li.innerHTML = `<span class="set-item-label">${item.name || item.clip}</span>
            <input class="set-item-sec" type="number" min="1" max="600" value="${item.duration || defaultDuration}" />
            <span class="set-item-btns">
                <button type="button" class="up">↑</button>
                <button type="button" class="down">↓</button>
                <button type="button" class="prev">▶</button>
                <button type="button" class="remove danger">×</button>
            </span>`;
        ul.appendChild(li);
        li.querySelector('.set-item-sec').addEventListener('input', renumberSetlist);
        li.querySelector('.up').addEventListener('click', () => {
            if (li.previousElementSibling) ul.insertBefore(li, li.previousElementSibling);
        });
        li.querySelector('.down').addEventListener('click', () => {
            if (li.nextElementSibling) ul.insertBefore(li.nextElementSibling, li);
        });
        li.querySelector('.prev').addEventListener('click', () => {
            nuiPost('preview', { dict: item.dict, clip: item.clip });
        });
        li.querySelector('.remove').addEventListener('click', () => {
            li.remove();
            renumberSetlist();
        });
        renumberSetlist();
    }

    function clearSetlist() {
        $('setlist').innerHTML = '';
        renumberSetlist();
    }

    function renderCatalog() {
        const list = $('catalog-list');
        const q = ($('catalog-search').value || '').toLowerCase();
        const cat = $('catalog-cat').value;
        list.innerHTML = '';
        catalog.forEach((c) => {
            if (cat !== 'all' && c.category !== cat) return;
            if (q && !c.name.toLowerCase().includes(q) && !c.dict.toLowerCase().includes(q)) return;
            const li = document.createElement('li');
            li.textContent = `${c.name} (${c.defaultDuration}秒)`;
            li.addEventListener('click', () => {
                addSetlistItem({
                    name: c.name,
                    dict: c.dict,
                    clip: c.clip,
                    duration: c.defaultDuration || defaultDuration,
                });
            });
            list.appendChild(li);
        });
    }

    window.addEventListener('message', (e) => {
        const d = e.data;
        if (!d || !d.type) return;
        if (d.type === 'openDdm') {
            catalog = d.catalog || [];
            maxSlots = d.maxSlots || 64;
            defaultDuration = d.defaultDuration || 10;
            $('set-max').textContent = String(maxSlots);
            $('c-dur').value = String(defaultDuration);
            $('app-wrap').classList.remove('hidden');
            renderCatalog();
            loadPresetList();
        } else if (d.type === 'hideManager') {
            $('app-wrap').classList.add('hidden');
        } else if (d.type === 'showMini') {
            $('mini-hud').classList.remove('hidden');
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
        } else if (d.type === 'playYoutube') {
            pendingYoutube = { url: d.url, startSeconds: d.startSeconds || 0 };
            if (ytReady) {
                startYouTube(pendingYoutube.url, pendingYoutube.startSeconds);
                pendingYoutube = null;
            }
        } else if (d.type === 'stopYoutube') {
            stopYouTube();
        } else if (d.type === 'playbackEnded' || d.type === 'uiClosed') {
            /* no-op */
        }
    });

    // listPresets — use fetch and read body? NUI callback returns in lua cb() - we need to use NUI callback from fetch
    // FiveM: RegisterNUICallback 'listPresets' with cb - the fetch doesn't return JSON in browser - actually it does! 
    // https://docs.fivem.net/docs/scripting-manual/nui-development/nui-callbacks/ - the response is in res.json()
    // Actually the fetch to NUI returns empty - need to use $.post with promise - in CEF fetch returns 200 and body is json from cb({ })

    /**
     * @param {string} name
     * @param {object} [payload]
     * @returns {Promise<any>}
     */
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

    $('btn-close').addEventListener('click', () => nuiPost('close', {}));
    $('catalog-search').addEventListener('input', renderCatalog);
    $('catalog-cat').addEventListener('change', renderCatalog);

    $('btn-c-add').addEventListener('click', () => {
        const dict = ($('c-dict').value || '').trim();
        const clip = ($('c-clip').value || '').trim();
        if (!dict || !clip) {
            showToast('⚠ Dict と Clip を入れてください', true);
            return;
        }
        const name = ($('c-name').value || '').trim() || clip;
        const dur = parseInt($('c-dur').value, 10) || defaultDuration;
        addSetlistItem({ name, dict, clip, duration: dur });
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
        await nuiFetch('startPlayback', { setlist, youtubeUrl, youtubeStart, loop });
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

    function startYouTube(url, startSeconds) {
        if (!ytReady || !ytPlayer) {
            return;
        }
        const id = extractVideoId(url);
        if (!id) {
            return;
        }
        ytPlayer.loadVideoById({ videoId: id, startSeconds: startSeconds || 0 });
        try {
            ytPlayer.playVideo();
        } catch (e) { /* cef */ }
    }

    function stopYouTube() {
        if (ytReady && ytPlayer) {
            try {
                ytPlayer.stopVideo();
            } catch (e) { /* cef */ }
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
                        startYouTube(pendingYoutube.url, pendingYoutube.startSeconds);
                        pendingYoutube = null;
                    }
                },
            },
        });
    };

    // --- エクスポート / インポート
    function utf8ToB64(s) {
        return btoa(unescape(encodeURIComponent(s)));
    }
    function b64ToUtf8(s) {
        return decodeURIComponent(escape(atob(s)));
    }

    function exportPreset() {
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
            youtube: { url: youtubeUrl, start: youtubeStart },
            loop: loop,
            setlist: items,
        };
        const base64 = utf8ToB64(JSON.stringify(jsonData));

        let md = '# 🎬 jp-DDM プリセット\n';
        md += `## プリセット名: ${presetName}\n\n`;
        md += '### 🎵 音楽\n';
        md += `- URL: ${youtubeUrl || 'なし'}\n`;
        md += `- 開始位置: ${youtubeStart}秒\n\n`;
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

        if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(md).then(
                () => showToast('📋 クリップボードにコピー'),
                () => showToast('コピー失敗。手で選択してください', true)
            );
        } else {
            showToast('Clipboard 未対応', true);
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
            $('youtube-start').value = String(json.youtube?.start || 0);
            $('loop-toggle').checked = !!json.loop;
            $('preset-name').value = json.name || '';
            closeImportModal();
            showToast('📥 完了: ' + (json.name || '無題'));
        } catch (e) {
            showToast('⚠ 解析に失敗: ' + e.message, true);
        }
    }

    $('btn-export').addEventListener('click', exportPreset);
    $('btn-import').addEventListener('click', showImportDialog);
    $('btn-import-execute').addEventListener('click', executeImport);
    $('btn-import-cancel').addEventListener('click', closeImportModal);

    // mini
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
})();
