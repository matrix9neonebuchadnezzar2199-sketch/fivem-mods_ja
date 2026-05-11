const root = document.getElementById('root');
const svg  = document.getElementById('tree');
const lvEl = document.getElementById('lv');
const spEl = document.getElementById('sp');
const starsEl = document.getElementById('stars');
const closeBtn = document.getElementById('close-btn');
const popup = document.getElementById('spec-popup');
const specList = document.getElementById('spec-list');

const NS = 'http://www.w3.org/2000/svg';

let state = { specs: {}, currentSpec: 'western', level: 0, sp: 0, stars: 0, generalTree: {}, ranks: {} };

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
    const dotY = cy + 52;
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
        const cls = isRecipe ? 'hex-node recipe' : 'hex-node status';
        drawHexNode(svg, pos.x, pos.y, 36, cls);

        appendIcon(svg, pos.x, pos.y + 2, node.icon, 'node-icon');

        const label = document.createElementNS(NS, 'text');
        label.setAttribute('x', pos.x);
        label.setAttribute('y', pos.y + 68);
        label.setAttribute('class', 'node-label');
        label.textContent = node.label || id;
        svg.appendChild(label);

        if (!isRecipe && node.maxRank && node.maxRank > 1) {
            const rk = (state.ranks && state.ranks[id]) || 0;
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
            // 中心方向にやや膨らむ曲線（らせん感を強調）
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

    // ノード本体
    for (const [id, node] of Object.entries(spec.nodes)) {
        const pos = polarToXY(node.angle, node.radius);
        const unlocked = isNodeUnlocked(id, spec.nodes, state.level);

        const circle = document.createElementNS(NS, 'circle');
        circle.setAttribute('cx', pos.x);
        circle.setAttribute('cy', pos.y);
        circle.setAttribute('r', 38);
        circle.setAttribute('class',
            'node-circle ' + (unlocked ? 'unlocked' : 'locked'));
        svg.appendChild(circle);

        appendIcon(svg, pos.x, pos.y + 2, node.icon, 'node-icon');

        const lv = document.createElementNS(NS, 'text');
        lv.setAttribute('x', pos.x);
        lv.setAttribute('y', pos.y - 50);
        lv.setAttribute('class', 'node-lv');
        lv.textContent = 'Lv ' + node.lv;
        svg.appendChild(lv);

        const label = document.createElementNS(NS, 'text');
        label.setAttribute('x', pos.x);
        label.setAttribute('y', pos.y + 65);
        label.setAttribute('class', 'node-label');
        label.textContent = node.label;
        svg.appendChild(label);
    }
}

function render() {
    svg.innerHTML = '';
    ensureDefs();
    lvEl.textContent = state.level;
    spEl.textContent = state.sp;
    starsEl.textContent = state.stars;

    drawWeb();              // 外側の蜘蛛の巣枠（最背面）
    drawSpecNodes();       // 専門職ノード
    drawGeneralNodes();    // 汎用ツリー（六角・専門職の外周）
    drawSpecHub();         // 中心の職業マス（最前面）
    applyViewBox();
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
    render();
}

// ポップアップ外クリックで閉じる
document.addEventListener('click', (ev) => {
    if (!popup.classList.contains('hidden') && !popup.contains(ev.target)) {
        hideSpecPopup();
    }
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
        state = {
            specs: data.specializations,
            currentSpec: data.currentSpec,
            level: data.level,
            sp: data.sp || 0,
            stars: data.stars || 0,
            generalTree: data.generalTree || {},
            ranks: data.generalRanks || {},
        };
        viewBox = { ...INITIAL_VIEWBOX };
        render();
        renderEffects();
        root.classList.remove('hidden');
    } else if (data.action === 'close') {
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

function renderEffects() {
    // 専門職で解放済みのレシピ
    effectsSpecList.innerHTML = '';
    let specCount = 0;
    for (const [specId, spec] of Object.entries(state.specs)) {
        for (const [nodeId, node] of Object.entries(spec.nodes || {})) {
            if (isNodeUnlocked(nodeId, spec.nodes, state.level)) {
                const div = document.createElement('div');
                div.className = 'effect-item';
                div.innerHTML = `
                    <span class="effect-item-icon">${node.icon ? node.icon.value : '?'}</span>
                    <span class="effect-item-label">${node.label}</span>
                    <span class="effect-item-value">[${spec.label}] Lv${node.lv}</span>
                `;
                effectsSpecList.appendChild(div);
                specCount++;
            }
        }
    }
    if (specCount === 0) {
        effectsSpecList.innerHTML = '<div class="effect-item-empty">未解放</div>';
    }

    // 汎用スキル（汎用ツリー）
    effectsGeneralList.innerHTML = '';
    let gcount = 0;
    for (const [id, node] of Object.entries(state.generalTree || {})) {
        if (!node) continue;
        const div = document.createElement('div');
        div.className = 'effect-item';
        const icon = node.icon ? node.icon.value : '?';
        let meta = '';
        if (node.type === 'recipe') {
            meta = `SP${node.spCost != null ? node.spCost : '—'} · レシピ`;
        } else if (node.maxRank > 1) {
            const rk = (state.ranks && state.ranks[id]) || 0;
            meta = `段階 ${rk}/${node.maxRank}`;
        } else {
            meta = '単段';
        }
        div.innerHTML = `
            <span class="effect-item-icon">${icon}</span>
            <span class="effect-item-label">${node.label || id}</span>
            <span class="effect-item-value">${meta}</span>
        `;
        effectsGeneralList.appendChild(div);
        gcount++;
    }
    if (gcount === 0) {
        effectsGeneralList.innerHTML = '<div class="effect-item-empty">未解放</div>';
    }

    // ★パッシブ（P3 で実装）
    effectsStarsList.innerHTML = '<div class="effect-item-empty">未実装（P3 で追加予定）</div>';

    // 合計ステータス（P3b で state.totals 経由に切替）
    effectsTotalsList.innerHTML = `
        <div class="effects-totals-item"><span class="label">クリティカル率</span><span class="value">+0%</span></div>
        <div class="effects-totals-item"><span class="label">最大HP</span><span class="value">200 (基本)</span></div>
        <div class="effects-totals-item"><span class="label">所持重量</span><span class="value">標準</span></div>
        <div class="effects-totals-item"><span class="label">EXP獲得倍率</span><span class="value">×1.0</span></div>
    `;
}

