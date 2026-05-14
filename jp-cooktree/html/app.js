const root = document.getElementById('root');
const svg  = document.getElementById('tree');
const lvEl = document.getElementById('lv');
const spEl = document.getElementById('sp');
const starsEl = document.getElementById('stars');
const closeBtn = document.getElementById('close-btn');
const popup = document.getElementById('spec-popup');
const specList = document.getElementById('spec-list');

const NS = 'http://www.w3.org/2000/svg';

let state = {
    specs: {},
    currentSpec: 'western',
    level: 1,
    sp: 0,
    xp: 0,
    nextLevelXp: null,
    stars: 0,
    starTotal: 0,
    recipeStars: {},
    generalTree: {},
    ranks: {},
    passiveRanks: {},
    recipeUnlocked: {},
};

const INITIAL_VIEWBOX = { x: -1400, y: -500, w: 2800, h: 1000 };
let viewBox = { ...INITIAL_VIEWBOX };

function applyViewBox() {
    svg.setAttribute('viewBox', `${viewBox.x} ${viewBox.y} ${viewBox.w} ${viewBox.h}`);
}

// 極座標 → 直交座標。-90 シフトで「真上=270°」を直感的に扱う。
function polarToXY(angleDeg, radius) {
    const rad = (angleDeg - 90) * Math.PI / 180;
    return { x: radius * Math.cos(rad), y: radius * Math.sin(rad) };
}

function isNodeUnlocked(nodeId, nodes, level) {
    const node = nodes[nodeId];
    if (!node) return false;
    if (level < node.lv) return false;
    for (const req of (node.requires || [])) {
        if (!isNodeUnlocked(req, nodes, level)) return false;
    }
    return true;
}

function isRecipeUnlockedNui(recipeId) {
    if (!recipeId || !state.recipeUnlocked) return false;
    return state.recipeUnlocked[recipeId] === true;
}

// SVG defs（グラデーションとフィルタ）
function ensureDefs() {
    let defs = svg.querySelector('defs');
    if (!defs) {
        defs = document.createElementNS(NS, 'defs');
        defs.innerHTML = `
        <radialGradient id="hubGrad" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stop-color="#d4823a"/>
            <stop offset="100%" stop-color="#6b4226"/>
        </radialGradient>
        <radialGradient id="nodeGradUnlocked" cx="50%" cy="50%" r="50%">
            <stop offset="0%" stop-color="#3d2817"/>
            <stop offset="100%" stop-color="#1a1208"/>
        </radialGradient>
        <linearGradient id="edgeGradUnlocked" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stop-color="#d4823a"/>
            <stop offset="100%" stop-color="#a8421a"/>
        </linearGradient>
        <filter id="nodeGlow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation="3" result="blur"/>
            <feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        <filter id="edgeGlow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation="2" result="blur"/>
            <feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        <filter id="hubGlow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation="6" result="blur"/>
            <feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
    `;
        svg.insertBefore(defs, svg.firstChild);
    }
    ensureP27Filters(defs);
}

function ensureP27Filters(defs) {
    if (!defs.querySelector('#silver-glow')) {
        const silverGlow = document.createElementNS(NS, 'filter');
        silverGlow.setAttribute('id', 'silver-glow');
        silverGlow.setAttribute('x', '-50%');
        silverGlow.setAttribute('y', '-50%');
        silverGlow.setAttribute('width', '200%');
        silverGlow.setAttribute('height', '200%');
        silverGlow.innerHTML = `
            <feGaussianBlur stdDeviation="3" result="blur"/>
            <feFlood flood-color="#c8c8d8" flood-opacity="0.7"/>
            <feComposite in2="blur" operator="in"/>
            <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
        `;
        defs.appendChild(silverGlow);
    }
    if (!defs.querySelector('#gold-glow-soft')) {
        const goldSoft = document.createElementNS(NS, 'filter');
        goldSoft.setAttribute('id', 'gold-glow-soft');
        goldSoft.setAttribute('x', '-50%');
        goldSoft.setAttribute('y', '-50%');
        goldSoft.setAttribute('width', '200%');
        goldSoft.setAttribute('height', '200%');
        goldSoft.innerHTML = `
            <feGaussianBlur stdDeviation="2.5" result="blur"/>
            <feFlood flood-color="#d4a574" flood-opacity="0.6"/>
            <feComposite in2="blur" operator="in"/>
            <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
        `;
        defs.appendChild(goldSoft);
    }
}

function appendIcon(parent, x, y, icon, cls) {
    if (!icon) return;
    if (icon.type === 'emoji') {
        const t = document.createElementNS(NS, 'text');
        t.setAttribute('x', x);
        t.setAttribute('y', y);
        t.setAttribute('class', cls);
        t.textContent = icon.value;
        parent.appendChild(t);
    } else if (icon.type === 'image') {
        const img = document.createElementNS(NS, 'image');
        const size = 36;
        img.setAttribute('x', x - size / 2);
        img.setAttribute('y', y - size / 2);
        img.setAttribute('width', size);
        img.setAttribute('height', size);
        img.setAttribute('href', icon.value);
        parent.appendChild(img);
    }
}

// 汎用ツリー: 六角形ノード
function drawHexNode(parent, cx, cy, r, className) {
    const points = [];
    for (let i = 0; i < 6; i++) {
        const ang = (Math.PI / 3) * i - Math.PI / 2;
        points.push(`${cx + r * Math.cos(ang)},${cy + r * Math.sin(ang)}`);
    }
    const poly = document.createElementNS(NS, 'polygon');
    poly.setAttribute('points', points.join(' '));
    poly.setAttribute('class', className);
    parent.appendChild(poly);
}

function drawRankIndicator(parent, cx, cy, currentRank, maxRank) {
    if (maxRank <= 1) return;
    const dotR = 4;
    const gap = 12;
    const dotY = cy - 52;
    const totalW = (maxRank - 1) * gap;
    const startX = cx - totalW / 2;
    for (let i = 0; i < maxRank; i++) {
        const dot = document.createElementNS(NS, 'circle');
        dot.setAttribute('cx', startX + i * gap);
        dot.setAttribute('cy', dotY);
        dot.setAttribute('r', dotR);
        dot.setAttribute('class', i < currentRank ? 'rank-dot filled' : 'rank-dot empty');
        parent.appendChild(dot);
    }
}

function drawGeneralNodes() {
    const tree = state.generalTree;
    if (!tree || typeof tree !== 'object') return;

    for (const [id, node] of Object.entries(tree)) {
        if (!node || node.angle == null || node.radius == null) continue;
        const pos = polarToXY(node.angle, node.radius);
        const isRecipe = node.type === 'recipe';
        const isStaged = node.nodeType === 'staged' && (node.maxRank || 0) > 0;
        let kind = null;
        if (isStaged) kind = 'staged';
        else if (isRecipe) kind = 'recipe_unlock';
        const cls = isRecipe
            ? 'hex-node recipe hex-interactive'
            : ('hex-node status' + (isStaged ? ' hex-interactive' : ''));

        const grp = document.createElementNS(NS, 'g');
        grp.setAttribute('class', 'general-node-group');
        grp.setAttribute('data-node-id', id);
        if (kind) {
            grp.style.cursor = 'pointer';
            grp.addEventListener('mousedown', (ev) => { ev.stopPropagation(); });
            grp.addEventListener('click', (ev) => {
                ev.stopPropagation();
                showPopover(id, grp, kind);
            });
        }

        drawHexNode(grp, pos.x, pos.y, 36, cls);
        appendIcon(grp, pos.x, pos.y + 2, node.icon, 'node-icon');

        const label = document.createElementNS(NS, 'text');
        label.setAttribute('x', pos.x);
        label.setAttribute('y', pos.y + 68);
        label.setAttribute('class', 'node-label');
        label.textContent = node.label || id;
        grp.appendChild(label);

        svg.appendChild(grp);

        if (!isRecipe && node.maxRank && node.maxRank > 1) {
            let rk = 0;
            if (isStaged) {
                rk = (state.passiveRanks && state.passiveRanks[id]) || 0;
            } else {
                rk = (state.ranks && state.ranks[id]) || 0;
            }
            drawRankIndicator(svg, pos.x, pos.y, rk, node.maxRank);
        }
    }
}

// 蜘蛛の巣の枠（同心円と放射線）
function drawWeb() {
    const radii = [320, 480, 640, 800, 960];
    for (const r of radii) {
        const c = document.createElementNS(NS, 'circle');
        c.setAttribute('cx', 0);
        c.setAttribute('cy', 0);
        c.setAttribute('r', r);
        c.setAttribute('class', 'web-circle');
        svg.appendChild(c);
    }
    // 8 方向の放射線
    const innerR = 280, outerR = 920;
    for (let i = 0; i < 8; i++) {
        const a = (i * 45 - 90) * Math.PI / 180;
        const line = document.createElementNS(NS, 'line');
        line.setAttribute('x1', innerR * Math.cos(a));
        line.setAttribute('y1', innerR * Math.sin(a));
        line.setAttribute('x2', outerR * Math.cos(a));
        line.setAttribute('y2', outerR * Math.sin(a));
        line.setAttribute('class', 'web-spoke');
        svg.appendChild(line);
    }
}

// 中心の職業マス
function drawSpecHub() {
    const spec = state.specs[state.currentSpec];
    if (!spec) return;

    const g = document.createElementNS(NS, 'g');
    g.setAttribute('class', 'spec-hub-group');
    g.style.cursor = 'pointer';

    const circle = document.createElementNS(NS, 'circle');
    circle.setAttribute('cx', 0);
    circle.setAttribute('cy', 0);
    circle.setAttribute('r', 50);
    circle.setAttribute('class', 'spec-hub');
    g.appendChild(circle);

    appendIcon(g, 0, -5, spec.icon, 'spec-hub-icon');

    const label = document.createElementNS(NS, 'text');
    label.setAttribute('x', 0);
    label.setAttribute('y', 22);
    label.setAttribute('class', 'spec-hub-label');
    label.textContent = spec.label;
    g.appendChild(label);

    g.addEventListener('click', (ev) => {
        ev.stopPropagation();
        showSpecPopup();
    });

    svg.appendChild(g);
}

// 専門職ノード描画
function drawSpecNodes() {
    const spec = state.specs[state.currentSpec];
    if (!spec || !spec.nodes) return;

    // 依存線（ノードより先に描いて下に置く）
    for (const [id, node] of Object.entries(spec.nodes)) {
        for (const reqId of (node.requires || [])) {
            const from = spec.nodes[reqId];
            if (!from) continue;
            const a = polarToXY(from.angle, from.radius);
            const b = polarToXY(node.angle, node.radius);
            const mx = (a.x + b.x) / 2;
            const my = (a.y + b.y) / 2;
            const ctrlScale = 0.7;
            const ctrlX = mx * ctrlScale;
            const ctrlY = my * ctrlScale;
            const path = document.createElementNS(NS, 'path');
            path.setAttribute('d', `M ${a.x} ${a.y} Q ${ctrlX} ${ctrlY} ${b.x} ${b.y}`);
            path.setAttribute('class',
                isNodeUnlocked(id, spec.nodes, state.level) ? 'edge unlocked' : 'edge');
            svg.appendChild(path);
        }
    }

    for (const [id, node] of Object.entries(spec.nodes)) {
        const pos = polarToXY(node.angle, node.radius);
        const unlocked = isNodeUnlocked(id, spec.nodes, state.level);

        const grp = document.createElementNS(NS, 'g');
        grp.setAttribute('class', 'spec-node-group');
        grp.setAttribute('data-node-id', id);
        grp.style.cursor = 'pointer';
        grp.addEventListener('mousedown', (ev) => { ev.stopPropagation(); });
        grp.addEventListener('click', (ev) => {
            ev.stopPropagation();
            showPopover(id, grp, 'spec_leaf');
        });

        const circle = document.createElementNS(NS, 'circle');
        circle.setAttribute('cx', pos.x);
        circle.setAttribute('cy', pos.y);
        circle.setAttribute('r', 38);
        circle.setAttribute('class',
            'node-circle ' + (unlocked ? 'unlocked' : 'locked'));
        grp.appendChild(circle);

        appendIcon(grp, pos.x, pos.y + 2, node.icon, 'node-icon');

        const lv = document.createElementNS(NS, 'text');
        lv.setAttribute('x', pos.x);
        lv.setAttribute('y', pos.y - 50);
        lv.setAttribute('class', 'node-lv');
        lv.textContent = 'Lv ' + node.lv;
        grp.appendChild(lv);

        const label = document.createElementNS(NS, 'text');
        label.setAttribute('x', pos.x);
        label.setAttribute('y', pos.y + 65);
        label.setAttribute('class', 'node-label');
        label.textContent = node.label;
        grp.appendChild(label);

        svg.appendChild(grp);
    }
}

function render() {
    svg.innerHTML = '';
    ensureDefs();
    lvEl.textContent = state.level;
    spEl.textContent = state.sp;
    starsEl.textContent = (typeof state.starTotal === 'number' ? state.starTotal : state.stars) ?? 0;

    drawWeb();              // 外側の蜘蛛の巣枠（最背面）
    drawSpecNodes();       // 専門職ノード
    drawGeneralNodes();    // 汎用ツリー（六角・専門職の外周）
    drawSpecHub();         // 中心の職業マス（最前面）
    applyViewBox();
    refreshPopoverContent();
}

// 専門職選択ポップアップ
function showSpecPopup() {
    specList.innerHTML = '';
    for (const [id, spec] of Object.entries(state.specs)) {
        const div = document.createElement('div');
        div.className = 'spec-option' + (id === state.currentSpec ? ' current' : '');
        const iconValue = spec.icon ? spec.icon.value : '?';
        div.innerHTML = `
            <span class="spec-option-icon">${iconValue}</span>
            <span class="spec-option-label">${spec.label}</span>
            ${id === state.currentSpec ? '<span class="spec-option-current-mark">選択中</span>' : ''}
        `;
        div.addEventListener('click', () => selectSpec(id));
        specList.appendChild(div);
    }
    popup.classList.remove('hidden');
}

function hideSpecPopup() { popup.classList.add('hidden'); }

function selectSpec(specId) {
    state.currentSpec = specId;
    fetch(`https://${GetParentResourceName()}/selectSpec`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ specId }),
    });
    hideSpecPopup();
    hidePopover();
    render();
    renderEffects();
}

// 専門職選択ポップアップ: 外クリックで閉じる
document.addEventListener('click', (ev) => {
    if (!popup.classList.contains('hidden') && !popup.contains(ev.target)) {
        hideSpecPopup();
    }
});

// ノード詳細ポップオーバー: 外クリック（mousedown）で閉じる
document.addEventListener('mousedown', (ev) => {
    const popover = document.getElementById('node-popover');
    if (!popover || popover.classList.contains('hidden')) return;
    if (popover.contains(ev.target)) return;
    hidePopover();
});

// ============ ズーム & パン ============
const ZOOM_MIN = 0.4, ZOOM_MAX = 2.5;
function getCurrentZoom() { return INITIAL_VIEWBOX.w / viewBox.w; }
function mouseToSvg(ev) {
    const rect = svg.getBoundingClientRect();
    const px = (ev.clientX - rect.left) / rect.width;
    const py = (ev.clientY - rect.top) / rect.height;
    return { x: viewBox.x + px * viewBox.w, y: viewBox.y + py * viewBox.h };
}
svg.addEventListener('wheel', (ev) => {
    ev.preventDefault();
    const zoomFactor = ev.deltaY < 0 ? 0.85 : 1.18;
    const newZoom = getCurrentZoom() / zoomFactor;
    if (newZoom < ZOOM_MIN || newZoom > ZOOM_MAX) return;
    const cursor = mouseToSvg(ev);
    viewBox.w *= zoomFactor;
    viewBox.h *= zoomFactor;
    viewBox.x = cursor.x - (ev.offsetX / svg.clientWidth) * viewBox.w;
    viewBox.y = cursor.y - (ev.offsetY / svg.clientHeight) * viewBox.h;
    applyViewBox();
}, { passive: false });

let dragging = false, dragStart = null;
svg.addEventListener('mousedown', (ev) => {
    if (ev.button !== 0) return;
    dragging = true;
    dragStart = { x: ev.clientX, y: ev.clientY, vx: viewBox.x, vy: viewBox.y };
    svg.style.cursor = 'grabbing';
});
window.addEventListener('mousemove', (ev) => {
    if (!dragging) return;
    const rect = svg.getBoundingClientRect();
    const dx = (ev.clientX - dragStart.x) / rect.width  * viewBox.w;
    const dy = (ev.clientY - dragStart.y) / rect.height * viewBox.h;
    viewBox.x = dragStart.vx - dx;
    viewBox.y = dragStart.vy - dy;
    applyViewBox();
});
window.addEventListener('mouseup', () => { dragging = false; svg.style.cursor = ''; });
svg.addEventListener('dblclick', () => {
    viewBox = { ...INITIAL_VIEWBOX };
    applyViewBox();
});

// ============ 通信 ============
function close() {
    hidePopover();
    root.classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: '{}',
    });
}

window.addEventListener('message', (ev) => {
    const data = ev.data;
    if (data.action === 'open') {
        if (cookResultHideTimer) {
            clearTimeout(cookResultHideTimer);
            cookResultHideTimer = null;
        }
        if (cookResultEl) {
            cookResultEl.classList.add('hidden');
            cookResultEl.textContent = '';
        }
        hidePopover();
        state = {
            specs: data.specializations,
            currentSpec: data.currentSpec,
            level: typeof data.level === 'number' ? data.level : Number(data.level) || 1,
            sp: typeof data.sp === 'number' ? data.sp : Number(data.sp) || 0,
            xp: typeof data.xp === 'number' ? data.xp : Number(data.xp) || 0,
            nextLevelXp: data.nextLevelXp,
            recipeStars: data.recipeStars || {},
            starTotal: typeof data.starTotal === 'number' ? data.starTotal : (Number(data.stars) || 0),
            stars: typeof data.starTotal === 'number' ? data.starTotal : (Number(data.stars) || 0),
            generalTree: data.generalTree || {},
            ranks: data.generalRanks || {},
            cookRecipeBook: data.cookRecipeBook || {},
            passiveRanks: data.passiveRanks || {},
            recipeUnlocked: data.recipeUnlocked || {},
        };
        viewBox = { ...INITIAL_VIEWBOX };
        render();
        renderEffects();
        root.classList.remove('hidden');
        if (data.cookResult) showFlashCookResult(data.cookResult);
    } else if (data.action === 'updateStars') {
        state.recipeStars = data.recipeStars || {};
        state.starTotal = typeof data.starTotal === 'number' ? data.starTotal : 0;
        state.stars = state.starTotal;
        starsEl.textContent = state.starTotal;
        renderEffects();
        refreshPopoverContent();
    } else if (data.action === 'updatePlayerState') {
        state.level = typeof data.level === 'number' ? data.level : Number(data.level) || 1;
        state.sp = typeof data.sp === 'number' ? data.sp : Number(data.sp) || 0;
        state.xp = typeof data.xp === 'number' ? data.xp : Number(data.xp) || 0;
        state.nextLevelXp = data.nextLevelXp;
        state.recipeStars = data.recipeStars || {};
        state.starTotal = typeof data.starTotal === 'number' ? data.starTotal : 0;
        state.stars = state.starTotal;
        state.passiveRanks = data.passiveRanks || {};
        state.recipeUnlocked = data.recipeUnlocked || state.recipeUnlocked || {};
        render();
        renderEffects();
        refreshPopoverContent();
    } else if (data.action === 'rankUpResponse') {
        if (data.ok) {
            if (data.nodeId && typeof data.newRank === 'number') {
                state.passiveRanks = state.passiveRanks || {};
                state.passiveRanks[data.nodeId] = data.newRank;
            }
            if (typeof data.spLeft === 'number') state.sp = data.spLeft;
            showRankUpFeedback(`ランクアップ！ → 段階 ${data.newRank != null ? data.newRank : ''}`, 'success');
        } else {
            let label = 'ランクアップに失敗しました';
            switch (data.reason) {
                case 'insufficient_sp': label = 'SP が不足しています'; break;
                case 'max_rank': label = '最大ランクです'; break;
                case 'unknown_node': label = 'ノードが見つかりません'; break;
                case 'not_staged': label = 'このノードはランクアップできません'; break;
                case 'consume_failed': label = '処理競合が発生しました、もう一度お試しください'; break;
                case 'invalid_node': label = '無効なノードIDです'; break;
                default: break;
            }
            showRankUpFeedback(label, 'denied');
        }
        render();
        renderEffects();
        refreshPopoverContent();
    } else if (data.action === 'cookDenied') {
        showFlashCookDenied(data.reason);
    } else if (data.action === 'close') {
        hidePopover();
        root.classList.add('hidden');
    }
});

document.addEventListener('keydown', (ev) => {
    if (ev.key === 'Escape' && !root.classList.contains('hidden')) close();
});

closeBtn.addEventListener('click', close);

// ============ 効果パネル（常時表示） ============
// P3b で state.totals をサーバー statebag 経由で受け取る予定。
// 現状はダミー値表示で UI 構造だけ確定。
const effectsPanel = document.getElementById('effects-panel');
const effectsSpecList = document.getElementById('effects-spec-list');
const effectsGeneralList = document.getElementById('effects-general-list');
const effectsStarsList = document.getElementById('effects-stars-list');
const effectsTotalsList = document.getElementById('effects-totals-list');
const cookResultEl = document.getElementById('cook-result');

let cookResultHideTimer = null;

function showRankUpFeedback(text, kind) {
    if (!cookResultEl) return;
    cookResultEl.className = 'cook-result ' + (kind === 'success' ? 'success' : 'denied');
    cookResultEl.textContent = text;
    cookResultEl.classList.remove('hidden');
    if (cookResultHideTimer) clearTimeout(cookResultHideTimer);
    cookResultHideTimer = setTimeout(() => {
        cookResultEl.classList.add('hidden');
        cookResultEl.textContent = '';
        cookResultHideTimer = null;
    }, 3000);
}

function showFlashCookDenied(reason) {
    if (!cookResultEl) return;
    let text = 'エラーが発生しました';
    switch (reason) {
        case 'inventory_full':
            text = 'インベントリに空きがありません';
            break;
        case 'locked':
            text = 'レベルが足りません';
            break;
        case 'unknown_recipe':
            text = 'レシピが見つかりません';
            break;
        default:
            break;
    }
    cookResultEl.className = 'cook-result denied';
    cookResultEl.textContent = text;
    cookResultEl.classList.remove('hidden');
    if (cookResultHideTimer) clearTimeout(cookResultHideTimer);
    cookResultHideTimer = setTimeout(() => {
        cookResultEl.classList.add('hidden');
        cookResultEl.textContent = '';
        cookResultHideTimer = null;
    }, 3000);
}

function showFlashCookResult(cookResult) {
    if (!cookResultEl || !cookResult) return;
    const map = {
        success: { cls: 'success', text: '成功！' },
        critical: { cls: 'critical', text: 'クリティカル！' },
        failed: { cls: 'failed', text: '失敗…' },
        cooldown: { cls: 'failed', text: 'クールダウン中です' },
        unlock_denied: { cls: 'failed', text: '未解放のため調理できません' },
        inventory_full: { cls: 'failed', text: 'インベントリに空きがありません' },
        error: { cls: 'failed', text: 'エラーが発生しました' },
        busy: { cls: 'failed', text: '調理処理中です' },
    };
    const m = map[cookResult.result] || map.error;
    cookResultEl.className = 'cook-result ' + m.cls;
    cookResultEl.textContent = m.text;
    cookResultEl.classList.remove('hidden');
    if (cookResultHideTimer) clearTimeout(cookResultHideTimer);
    cookResultHideTimer = setTimeout(() => {
        cookResultEl.classList.add('hidden');
        cookResultEl.textContent = '';
        cookResultHideTimer = null;
    }, 3000);
}

async function onCookButtonClick(recipeId, btn) {
    if (btn.disabled) return;
    btn.disabled = true;
    const prev = btn.textContent;
    btn.textContent = '…';
    try {
        const res = await fetch(`https://${GetParentResourceName()}/cook`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ recipeId }),
        });
        const j = await res.json().catch(() => ({}));
        if (j && j.busy) {
            showFlashCookResult({ result: 'busy', recipeId });
        }
    } catch (_) {
        showFlashCookResult({ result: 'error', recipeId });
    } finally {
        btn.textContent = prev;
        btn.disabled = false;
    }
}

function findRecipeLabel(recipeId) {
    if (!recipeId || !state.specs) return recipeId || '';
    for (const spec of Object.values(state.specs)) {
        for (const node of Object.values(spec.nodes || {})) {
            if (node.recipe === recipeId) return node.label || recipeId;
        }
    }
    return recipeId;
}

function getRecipeStarCount(recipeId) {
    if (!recipeId || !state.recipeStars) return 0;
    const n = state.recipeStars[recipeId];
    return typeof n === 'number' ? n : 0;
}

// ============ ノード詳細ポップオーバー ============

// staged ノードの効果値表示（rank=0 でも現効果として表示できる文字列）
const NODE_EFFECT_FORMAT = {
    hp_node:         (r) => `+${r * 5} HP`,
    carry_node:      (r) => `+${r * 1} kg 所持重量`,
    crit_node:       (r) => `+${r * 1}% クリ率`,
    exp_node:        (r) => `+${r * 5}% EXP`,
    armor_cap_node:  (r) => `+${r * 10} 防具上限`,
    buff_dur_node:   (r) => `+${r * 5}% バフ時間`,
    cook_speed_node: (r) => `+${r * 5}% 調理速度`,
    cooldown_node:   (r) => (r === 0 ? '0秒短縮' : `-${r * 5}秒 CD`),
    save_node:       (r) => `+${r * 2}% 食材節約`,
    star_mult_node:  (r) => `+${r * 10}% ★獲得`,
    armor_regen_node:(r) => `+${(r * 0.5).toFixed(1)}/s 防具回復`,
    hp_regen_node:   (r) => `+${r * 50}% HP回復`,
    heat_vision_node:(r) => (r === 0 ? '未解放' : '熱視野解放'),
    max_hp_big_node: (r) => `+${r * 20} max HP`,
};

/** 次段階へ +1 したときの増分（括弧内表示用） */
const NODE_EFFECT_INCREMENT = {
    hp_node: '+5 HP',
    carry_node: '+1 kg',
    crit_node: '+1%',
    exp_node: '+5%',
    armor_cap_node: '+10',
    buff_dur_node: '+5%',
    cook_speed_node: '+5%',
    cooldown_node: '-5秒',
    save_node: '+2%',
    star_mult_node: '+10%',
    armor_regen_node: '+0.5/s',
    hp_regen_node: '+50%',
    heat_vision_node: '解放',
    max_hp_big_node: '+20 max HP',
};

function formatStagedEffect(nodeId, rank) {
    const fn = NODE_EFFECT_FORMAT[nodeId];
    return fn ? fn(rank) : '—';
}

function formatStagedIncrementParen(nodeId) {
    const s = NODE_EFFECT_INCREMENT[nodeId];
    return s || '';
}

function formatNodeListNames(ids, nodes) {
    if (!ids || !ids.length) return 'なし';
    return ids.map((rid) => {
        const n = nodes[rid];
        return (n && n.label) || rid;
    }).join('、');
}

let activePopoverNodeId = null;
let activePopoverIconEl = null;
let activePopoverKind = null;

function getNodeIconRect(grp) {
    if (!grp) return null;
    const shape = grp.querySelector('polygon, circle');
    return (shape || grp).getBoundingClientRect();
}

function positionPopover(popover, iconRect) {
    if (!popover || !iconRect) return;
    const popoverRect = popover.getBoundingClientRect();
    const margin = 16;
    let left = iconRect.right + 12;
    if (left + popoverRect.width > window.innerWidth - margin) {
        left = iconRect.left - popoverRect.width - 12;
    }
    if (left < margin) left = margin;
    let top = iconRect.top + iconRect.height / 2 - popoverRect.height / 2;
    if (top < margin) top = margin;
    if (top + popoverRect.height > window.innerHeight - margin) {
        top = window.innerHeight - popoverRect.height - margin;
    }
    popover.style.left = left + 'px';
    popover.style.top = top + 'px';
}

function showPopover(nodeId, iconEl, kind) {
    const popover = document.getElementById('node-popover');
    if (!popover) return;
    popover.innerHTML = '';
    if (kind === 'staged') renderStagedPopover(popover, nodeId);
    else if (kind === 'recipe_unlock') renderRecipeUnlockPopover(popover, nodeId);
    else if (kind === 'spec_leaf') renderSpecLeafPopover(popover, nodeId);
    else return;
    popover.classList.remove('hidden');
    activePopoverNodeId = nodeId;
    activePopoverIconEl = iconEl;
    activePopoverKind = kind;
    const anchor = () => positionPopover(popover, getNodeIconRect(iconEl));
    anchor();
    requestAnimationFrame(anchor);
}

function hidePopover() {
    const popover = document.getElementById('node-popover');
    if (popover) {
        popover.classList.add('hidden');
        popover.innerHTML = '';
    }
    activePopoverNodeId = null;
    activePopoverIconEl = null;
    activePopoverKind = null;
}

// SVG が再描画されると iconEl は別インスタンスに置き換わるため、
// data-node-id でグループを引き直して位置と中身を更新する。
function refreshPopoverContent() {
    if (!activePopoverNodeId || !activePopoverKind) return;
    const popover = document.getElementById('node-popover');
    if (!popover || popover.classList.contains('hidden')) return;
    const nid = activePopoverNodeId;
    let grp = null;
    if (activePopoverKind === 'spec_leaf') {
        grp = svg.querySelector('.spec-node-group[data-node-id="' + nid + '"]');
    } else {
        grp = svg.querySelector('.general-node-group[data-node-id="' + nid + '"]');
    }
    activePopoverIconEl = grp;
    popover.innerHTML = '';
    if (activePopoverKind === 'staged') renderStagedPopover(popover, nid);
    else if (activePopoverKind === 'recipe_unlock') renderRecipeUnlockPopover(popover, nid);
    else if (activePopoverKind === 'spec_leaf') renderSpecLeafPopover(popover, nid);
    if (grp) {
        requestAnimationFrame(() => {
            positionPopover(popover, getNodeIconRect(grp));
        });
    }
}

function appendTitleRow(container, node, fallbackId) {
    const titleEl = document.createElement('div');
    titleEl.className = 'popover-title';
    const iconSpan = document.createElement('span');
    iconSpan.className = 'popover-title-icon';
    iconSpan.textContent = node && node.icon ? node.icon.value : '?';
    const nameSpan = document.createElement('span');
    nameSpan.textContent = (node && node.label) || fallbackId;
    titleEl.appendChild(iconSpan);
    titleEl.appendChild(nameSpan);
    container.appendChild(titleEl);
}

function appendDivider(container) {
    const div = document.createElement('div');
    div.className = 'popover-divider';
    container.appendChild(div);
}

function renderStagedPopover(container, nodeId) {
    const node = state.generalTree && state.generalTree[nodeId];
    if (!node) return;

    const currentRank = (state.passiveRanks && state.passiveRanks[nodeId]) || 0;
    const maxRank = node.maxRank || 0;
    const cost = Math.max(1, Math.floor(Number(node.spCostPerRank) || 1));
    const atMaxRank = currentRank >= maxRank;
    const canRankUp = !atMaxRank && state.sp >= cost;

    appendTitleRow(container, node, nodeId);

    const rankLine = document.createElement('div');
    rankLine.className = 'popover-rank-line';
    rankLine.textContent = `段階 ${currentRank}/${maxRank}`;
    container.appendChild(rankLine);

    appendDivider(container);

    const curRow = document.createElement('div');
    curRow.className = 'popover-effect-row';
    curRow.innerHTML = `<span class="popover-effect-label">現効果</span><span class="popover-effect-value">${formatStagedEffect(nodeId, currentRank)}</span>`;
    container.appendChild(curRow);

    if (!atMaxRank) {
        const inc = formatStagedIncrementParen(nodeId);
        const nextVal = formatStagedEffect(nodeId, currentRank + 1);
        const nextRow = document.createElement('div');
        nextRow.className = 'popover-effect-row';
        const nextInner = inc
            ? `<span class="popover-effect-label">次効果</span><span class="popover-effect-value next">${nextVal} <span class="popover-effect-delta">(${inc})</span></span>`
            : `<span class="popover-effect-label">次効果</span><span class="popover-effect-value next">${nextVal}</span>`;
        nextRow.innerHTML = nextInner;
        container.appendChild(nextRow);
    }

    appendDivider(container);

    const metaRow = document.createElement('div');
    metaRow.className = 'popover-meta';
    metaRow.innerHTML = atMaxRank
        ? `<span>必要 SP</span><span>—（最大）</span><span>残 SP</span><span>${state.sp}</span>`
        : `<span>必要 SP</span><span>${cost}</span><span>残 SP</span><span>${state.sp}</span>`;
    container.appendChild(metaRow);

    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'popover-button rankup' + (canRankUp ? '' : ' locked');
    btn.disabled = !canRankUp;
    btn.textContent = atMaxRank ? '最大ランク' : 'ランクアップ';
    if (!canRankUp && !atMaxRank) {
        btn.title = `SP が不足しています（必要 ${cost} / 残 ${state.sp}）`;
    } else if (atMaxRank) {
        btn.title = '最大段階です';
    }
    btn.addEventListener('click', async () => {
        if (!canRankUp || btn.disabled) return;
        btn.disabled = true;
        btn.textContent = '…';
        try {
            await fetch(`https://${GetParentResourceName()}/rankUp`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ nodeId }),
            });
        } catch (_) { /* 結果は rankUpResponse */ }
    });
    container.appendChild(btn);
}

function renderRecipeUnlockPopover(container, nodeId) {
    const node = state.generalTree && state.generalTree[nodeId];
    if (!node) return;

    const rid = node.recipe;
    const gTree = state.generalTree || {};
    const hasDef = !!(state.cookRecipeBook && rid && state.cookRecipeBook[rid]);
    const recipeOpened = rid ? isRecipeUnlockedNui(rid) : false;
    const stars = getRecipeStarCount(rid);

    appendTitleRow(container, node, nodeId);

    const sub = document.createElement('div');
    sub.className = 'popover-rank-line';
    sub.textContent = rid ? `レシピ: ${rid}` : 'レシピ未設定';
    container.appendChild(sub);

    appendDivider(container);

    const reqRow = document.createElement('div');
    reqRow.className = 'popover-meta';
    reqRow.innerHTML = `<span>前提ノード</span><span>${formatNodeListNames(node.requires || [], gTree)}</span>`;
    container.appendChild(reqRow);

    const lvNeed = node.lv != null ? Number(node.lv) : null;
    const lvRow = document.createElement('div');
    lvRow.className = 'popover-meta';
    lvRow.innerHTML = lvNeed != null
        ? `<span>必要 Lv</span><span>${lvNeed}（現 ${state.level}）</span>`
        : `<span>必要 Lv</span><span>—（現 ${state.level}）</span>`;
    container.appendChild(lvRow);

    if (node.description) {
        const desc = document.createElement('div');
        desc.className = 'popover-description';
        desc.textContent = node.description;
        container.appendChild(desc);
    }

    appendDivider(container);

    const starRow = document.createElement('div');
    starRow.className = 'popover-effect-row';
    starRow.innerHTML = `<span class="popover-effect-label">★獲得</span><span class="popover-effect-value">★${stars}</span>`;
    container.appendChild(starRow);

    const unlockRow = document.createElement('div');
    unlockRow.className = 'popover-meta';
    unlockRow.innerHTML = `<span>調理</span><span>${recipeOpened ? '解放済み' : '未解放'}</span>`;
    container.appendChild(unlockRow);

    appendDivider(container);

    const spCost = node.spCost != null ? node.spCost : '—';
    const metaSp = document.createElement('div');
    metaSp.className = 'popover-meta';
    metaSp.innerHTML = `<span>ツリー解放 SP（予定）</span><span>${spCost}</span><span>残 SP</span><span>${state.sp}</span>`;
    container.appendChild(metaSp);

    let btnLabel = '調理する';
    let btnDisabled = true;
    let btnTitle = '';
    if (!hasDef) {
        btnLabel = '未実装';
        btnTitle = 'Config.Recipes に未定義';
    } else if (!recipeOpened) {
        btnLabel = '未解放';
        btnTitle = '専門職ツリーのレシピ解放後に調理可能';
    } else {
        btnDisabled = false;
    }

    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'popover-button cook' + (btnDisabled ? ' locked' : '');
    btn.textContent = btnLabel;
    btn.disabled = btnDisabled;
    if (btnTitle) btn.title = btnTitle;
    if (rid) btn.dataset.recipeId = rid;
    btn.addEventListener('click', () => {
        if (btnDisabled) return;
        onCookButtonClick(rid, btn);
    });
    container.appendChild(btn);
}

function renderSpecLeafPopover(container, nodeId) {
    const spec = state.specs && state.specs[state.currentSpec];
    if (!spec || !spec.nodes) return;
    const node = spec.nodes[nodeId];
    if (!node) return;

    appendTitleRow(container, node, nodeId);

    const specLine = document.createElement('div');
    specLine.className = 'popover-rank-line';
    specLine.textContent = `専門職: ${spec.label}`;
    container.appendChild(specLine);

    if (spec.description) {
        const sd = document.createElement('div');
        sd.className = 'popover-description';
        sd.textContent = spec.description;
        container.appendChild(sd);
    }

    appendDivider(container);

    const treeUnlocked = isNodeUnlocked(nodeId, spec.nodes, state.level);
    const reqLine = document.createElement('div');
    reqLine.className = 'popover-meta';
    reqLine.innerHTML = `<span>前提ノード</span><span>${formatNodeListNames(node.requires || [], spec.nodes)}</span>`;
    container.appendChild(reqLine);

    const lvRow = document.createElement('div');
    lvRow.className = 'popover-meta';
    lvRow.innerHTML = `<span>必要 Lv（共通）</span><span>${node.lv}（現 ${state.level}）</span>`;
    container.appendChild(lvRow);

    if (node.description) {
        const desc = document.createElement('div');
        desc.className = 'popover-description';
        desc.textContent = node.description;
        container.appendChild(desc);
    }

    if (!node.recipe) {
        return;
    }

    const starN = getRecipeStarCount(node.recipe);
    appendDivider(container);
    const starRow = document.createElement('div');
    starRow.className = 'popover-effect-row';
    starRow.innerHTML = `<span class="popover-effect-label">★獲得</span><span class="popover-effect-value">★${starN}</span>`;
    container.appendChild(starRow);

    appendDivider(container);

    const hasDef = !!(state.cookRecipeBook && state.cookRecipeBook[node.recipe]);
    const recipeOk = isRecipeUnlockedNui(node.recipe);

    let btnLabel = '調理する';
    let btnDisabled = false;
    let btnTitle = '';
    if (!treeUnlocked) {
        btnLabel = 'ツリー未解放';
        btnDisabled = true;
        btnTitle = '前提ノード／Lv 条件を満たしてください';
    } else if (!hasDef) {
        btnLabel = '未実装';
        btnDisabled = true;
        btnTitle = 'Config.Recipes に未定義';
    } else if (!recipeOk) {
        btnLabel = '調理未解放';
        btnDisabled = true;
        btnTitle = 'レシピの解放条件を満たしてください';
    }

    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'popover-button cook' + (btnDisabled ? ' locked' : '');
    btn.textContent = btnLabel;
    btn.disabled = btnDisabled;
    if (btnTitle) btn.title = btnTitle;
    btn.dataset.recipeId = node.recipe;
    btn.addEventListener('click', () => {
        if (btnDisabled) return;
        onCookButtonClick(node.recipe, btn);
    });
    container.appendChild(btn);
}

function renderEffects() {
    // 🎯 専門職スキル: 解放済みレシピのみ情報表示（調理はポップオーバー）
    effectsSpecList.innerHTML = '';
    const spec = state.specs[state.currentSpec];
    if (!spec || !spec.nodes) {
        effectsSpecList.innerHTML = '<div class="effect-item-empty">—</div>';
    } else {
        let unlockedCount = 0;
        for (const [nodeId, node] of Object.entries(spec.nodes)) {
            if (!node.recipe) continue;
            if (!isNodeUnlocked(nodeId, spec.nodes, state.level)) continue;
            unlockedCount++;
            const div = document.createElement('div');
            div.className = 'effect-item';
            const icon = node.icon ? node.icon.value : '?';
            const starN = getRecipeStarCount(node.recipe);
            div.innerHTML = `
                <span class="effect-item-icon">${icon}</span>
                <span class="effect-item-label">${node.label || nodeId}</span>
                <span class="effect-item-value">★${starN}</span>
            `;
            effectsSpecList.appendChild(div);
        }
        if (unlockedCount === 0) {
            effectsSpecList.innerHTML = '<div class="effect-item-empty">未解放（Lv 必要）</div>';
        }
    }

    // ⚙️ 汎用スキル（パッシブ）: 取得済み（rank≥1）のみ表示。クリックはツリー側。
    effectsGeneralList.innerHTML = '';
    let acquiredCount = 0;
    for (const [id, node] of Object.entries(state.generalTree || {})) {
        if (!node || node.nodeType !== 'staged') continue;
        const rk = (state.passiveRanks && state.passiveRanks[id]) || 0;
        if (rk < 1) continue;
        acquiredCount++;
        const div = document.createElement('div');
        div.className = 'effect-item';
        const icon = node.icon ? node.icon.value : '?';
        const maxRank = node.maxRank || 0;
        const meta = maxRank > 1 ? `段階 ${rk}/${maxRank}` : '解放済';
        div.innerHTML = `
            <span class="effect-item-icon">${icon}</span>
            <span class="effect-item-label">${node.label || id}</span>
            <span class="effect-item-value">${meta}</span>
        `;
        effectsGeneralList.appendChild(div);
    }
    if (acquiredCount === 0) {
        effectsGeneralList.innerHTML = '<div class="effect-item-empty">未取得（ツリーのノードアイコンをクリック）</div>';
    }

    // ★パッシブ（P3e）／レシピ別 ★ カウント（P3b）
    effectsStarsList.innerHTML = '';
    const starEntries = Object.entries(state.recipeStars || {}).filter(([, c]) => typeof c === 'number' && c > 0);
    if (starEntries.length === 0) {
        effectsStarsList.innerHTML = '<div class="effect-item-empty">調理成功でレシピごとに ★ が増えます</div>';
    } else {
        starEntries.sort((a, b) => b[1] - a[1]);
        for (const [rid, cnt] of starEntries) {
            const div = document.createElement('div');
            div.className = 'effect-item';
            div.innerHTML = `
                <span class="effect-item-icon">⭐</span>
                <span class="effect-item-label">${findRecipeLabel(rid)}</span>
                <span class="effect-item-value">★${cnt}</span>
            `;
            effectsStarsList.appendChild(div);
        }
    }

    // 合計ステータス（P3b で state.totals 経由に切替）
    effectsTotalsList.innerHTML = `
        <div class="effects-totals-item"><span class="label">料理XP</span><span class="value">${typeof state.xp === 'number' ? state.xp : 0}${state.nextLevelXp != null ? ` / 次Lv ${state.nextLevelXp}` : '（最大）'}</span></div>
        <div class="effects-totals-item"><span class="label">クリティカル率</span><span class="value">+0%</span></div>
        <div class="effects-totals-item"><span class="label">最大HP</span><span class="value">200 (基本)</span></div>
        <div class="effects-totals-item"><span class="label">所持重量</span><span class="value">標準</span></div>
        <div class="effects-totals-item"><span class="label">EXP獲得倍率</span><span class="value">×1.0</span></div>
    `;
}

