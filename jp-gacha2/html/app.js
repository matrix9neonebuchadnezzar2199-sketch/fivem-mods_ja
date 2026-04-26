const menuContainer = document.getElementById('menu-container');
const menuTitle = document.getElementById('menu-title');
const menuOptions = document.getElementById('menu-options');
const inputContainer = document.getElementById('input-container');
const inputTitle = document.getElementById('input-title');
const inputField = document.getElementById('input-field');
const gachaContainer = document.getElementById('gacha-container');
const bgLayer = document.getElementById('bg-layer');
const bgImage = document.getElementById('bg-image');
const flashLayer = document.getElementById('flash-layer');
const particleLayer = document.getElementById('particle-layer');
const singleCapsuleArea = document.getElementById('single-capsule-area');
const capsuleImg = document.getElementById('capsule-img');
const cutinLayer = document.getElementById('cutin-layer');
const cutinImg = document.getElementById('cutin-img');
const resultLayer = document.getElementById('result-layer');
const resultRarity = document.getElementById('result-rarity');
const resultItemName = document.getElementById('result-item-name');
const multiCapsuleArea = document.getElementById('multi-capsule-area');
const multiResultArea = document.getElementById('multi-result-area');
const multiResultList = document.getElementById('multi-result-list');
const inputSubmitButton = document.getElementById('input-submit');
const inputCancelButton = document.getElementById('input-cancel');
const topMenuContainer = document.getElementById('top-menu-container');
const topMenuTitle = document.getElementById('top-menu-title');
const btnGacha = document.getElementById('btn-gacha');
const btnTopAdmin = document.getElementById('btn-top-admin');
const passContainer = document.getElementById('pass-container');
const passField = document.getElementById('pass-field');
const passSubmit = document.getElementById('pass-submit');
const passCancel = document.getElementById('pass-cancel');
const passError = document.getElementById('pass-error');
const adminPassCur = document.getElementById('admin-pass-cur');
const adminPassNew = document.getElementById('admin-pass-new');
const adminPassChange = document.getElementById('admin-pass-change');
const adminContainer = document.getElementById('admin-container');
const adminBox = document.getElementById('admin-box');
const adminClose = document.getElementById('admin-close');
const adminTitle = document.getElementById('admin-title');
const adminCost = document.getElementById('admin-cost');
const adminTheme = document.getElementById('admin-theme');
const adminRarityFields = document.getElementById('admin-rarity-fields');
const adminRarityTotal = document.getElementById('admin-rarity-total');
const adminItemsList = document.getElementById('admin-items-list');
const adminSave = document.getElementById('admin-save');
const adminCancel = document.getElementById('admin-cancel');
const adminToast = document.getElementById('admin-toast');
const gachaMenuContainer = document.getElementById('gacha-menu-container');
const gachaMenuBox = document.getElementById('gacha-menu-box');
const gachaMenuClose = document.getElementById('gacha-menu-close');
const gachaMenuTitle = document.getElementById('gacha-menu-title');
const gachaMenuItems = document.getElementById('gacha-menu-items');
const gachaHopeInput = document.getElementById('gacha-hope-input');
const gachaHopePrice = document.getElementById('gacha-hope-price');
const btnSingle = document.getElementById('btn-single');
const btnMulti10 = document.getElementById('btn-multi10');
const btnHope = document.getElementById('btn-hope');
let inputFromGacha = false;
let lastGachaRarities = [];
let adminRarityKeyOrder = ['UR', 'SSR', 'SR', 'R'];
let lastMaxPull = 10;
let inPassFlow = false;

let allTimers = [];
let currentMultiData = null;
const supportsCalcMultiply = !!(window.CSS && CSS.supports && CSS.supports('width', 'calc(10px * 2)'));

function getResourceName() {
    try {
        if (typeof GetParentResourceName === 'function') {
            return GetParentResourceName();
        }
    } catch (e) {}
    return 'jp-gacha';
}

function setScale(scale) {
    const numeric = Number(scale) || 2;
    const appliedScale = numeric < 2 ? 2 : numeric;
    document.documentElement.style.setProperty('--scale', appliedScale);
    // FiveM の Chromium 環境で calc(10px * 2) が効かない場合は transform スケールへフォールバック
    document.documentElement.classList.toggle('scale-fallback', !supportsCalcMultiply);
}

function playSound(filename) {
    try {
        const audio = new Audio('sounds/' + filename);
        audio.volume = 0.6;
        audio.play().catch(function () {});
    } catch (e) {}
}

function spawnParticles(count, type) {
    for (let i = 0; i < count; i++) {
        const p = document.createElement('img');
        p.classList.add('particle');
        p.src = type === 'star' ? 'img/particles_star.png' : 'img/particles_circle.png';
        p.style.left = Math.random() * 100 + '%';
        p.style.width = 20 + Math.random() * 30 + 'px';
        p.style.animationDuration = 2 + Math.random() * 3 + 's';
        p.style.animationDelay = Math.random() + 's';
        particleLayer.appendChild(p);
    }
}

function clearParticles() {
    particleLayer.innerHTML = '';
}

function clearAllTimers() {
    allTimers.forEach(function (t) {
        clearTimeout(t);
    });
    allTimers = [];
}

function safeTimeout(fn, delay) {
    const t = setTimeout(fn, delay);
    allTimers.push(t);
    return t;
}

function resetAll() {
    clearAllTimers();
    gachaContainer.classList.add('hidden');
    gachaContainer.classList.remove('screen-shake');
    bgLayer.classList.remove('active');
    bgImage.src = '';
    flashLayer.classList.add('hidden');
    flashLayer.classList.remove('flash-anim');
    singleCapsuleArea.classList.add('hidden');
    capsuleImg.src = '';
    capsuleImg.className = '';
    cutinLayer.classList.add('hidden');
    cutinLayer.classList.remove('slide-in');
    cutinImg.src = '';
    resultLayer.classList.add('hidden');
    resultLayer.classList.remove('show');
    multiCapsuleArea.classList.add('hidden');
    multiCapsuleArea.innerHTML = '';
    multiResultArea.classList.add('hidden');
    multiResultList.innerHTML = '';
    clearParticles();
}

function notifyComplete() {
    fetch('https://' + getResourceName() + '/gachaComplete', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).catch(function () {});
}

function postNui(path, payload) {
    fetch('https://' + getResourceName() + '/' + path, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload || {})
    }).catch(function () {});
}

function formatYen(n) {
    const x = Math.floor(Number(n) || 0);
    return '¥' + x.toLocaleString('ja-JP');
}

function getRarityMeta(rarities, id) {
    if (!Array.isArray(rarities)) {
        return { label: id, color: '#999', icon: '' };
    }
    for (var i = 0; i < rarities.length; i += 1) {
        if (rarities[i].id === id) {
            return rarities[i];
        }
    }
    return { label: id, color: '#999', icon: '' };
}

function hideTopAndPass() {
    if (topMenuContainer) {
        topMenuContainer.classList.add('hidden');
    }
    if (passContainer) {
        passContainer.classList.add('hidden');
    }
    inPassFlow = false;
}

function showTopMenuView(data) {
    setScale((data && data.scale) || 2);
    inPassFlow = false;
    if (passContainer) {
        passContainer.classList.add('hidden');
    }
    if (passError) {
        passError.classList.add('hidden');
    }
    if (inputContainer) {
        inputContainer.classList.add('hidden');
    }
    gachaMenuContainer.classList.add('hidden');
    adminContainer.classList.add('hidden');
    menuContainer.classList.add('hidden');
    if (topMenuTitle) {
        topMenuTitle.textContent = 'ガチャマシン';
    }
    if (topMenuContainer) {
        topMenuContainer.classList.remove('hidden');
    }
}

if (btnGacha) {
    btnGacha.addEventListener('click', function (e) {
        if (e) {
            e.preventDefault();
        }
        if (topMenuContainer) {
            topMenuContainer.classList.add('hidden');
        }
        postNui('topMenuSelect', { value: 'gacha' });
    });
}
if (btnTopAdmin) {
    btnTopAdmin.addEventListener('click', function (e) {
        if (e) {
            e.preventDefault();
        }
        if (topMenuContainer) {
            topMenuContainer.classList.add('hidden');
        }
        if (passField) {
            passField.value = '';
        }
        if (passError) {
            passError.classList.add('hidden');
        }
        inPassFlow = true;
        if (passContainer) {
            passContainer.classList.remove('hidden');
        }
        if (passField) {
            passField.focus();
        }
    });
}
if (passSubmit) {
    passSubmit.addEventListener('click', function (e) {
        if (e) {
            e.preventDefault();
        }
        const pw = (passField && passField.value) || '';
        postNui('topMenuSelect', { value: 'admin', password: pw });
    });
}
if (passCancel) {
    passCancel.addEventListener('click', function (e) {
        if (e) {
            e.preventDefault();
        }
        inPassFlow = false;
        if (passContainer) {
            passContainer.classList.add('hidden');
        }
        if (passError) {
            passError.classList.add('hidden');
        }
        if (topMenuContainer) {
            topMenuContainer.classList.remove('hidden');
        }
    });
}
if (passField) {
    passField.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' && passSubmit) {
            passSubmit.click();
        }
    });
}
if (adminPassChange) {
    adminPassChange.addEventListener('click', function (e) {
        if (e) {
            e.preventDefault();
        }
        const cur = (adminPassCur && adminPassCur.value) || '';
        const nw = (adminPassNew && adminPassNew.value) || '';
        postNui('changeAdminPassword', { current: cur, newPassword: nw });
    });
}

function showGachaMenuView(data) {
    setScale(data.scale);
    lastGachaRarities = data.rarities || [];
    hideTopAndPass();
    gachaMenuContainer.classList.remove('hidden');
    adminContainer.classList.add('hidden');
    menuContainer.classList.add('hidden');
    gachaMenuTitle.textContent = data.title || 'ガチャ';
    lastMaxPull = data.maxPull != null ? data.maxPull : 10;
    gachaHopeInput.max = lastMaxPull;
    gachaHopeInput.value = 1;
    gachaMenuItems.innerHTML = '';
    var th = (data.themes && data.themes[data.theme]) || null;
    gachaMenuBox.className = 'gacha-themes-' + (data.theme || 'neon');
    if (th) {
        gachaMenuBox.style.setProperty('--tm-bg', th.bg);
        gachaMenuBox.style.setProperty('--tm-accent', th.accent);
        gachaMenuBox.style.setProperty('--tm-text', th.text);
    }
    const list = data.items || [];
    if (list.length === 0) {
        const em = document.createElement('div');
        em.className = 'gacha-items-empty';
        em.textContent = '排出有効の景品がありません（管理画面を確認、またはConfigへフォールバックします）';
        gachaMenuItems.appendChild(em);
    }
    list.forEach(function (it) {
        const card = document.createElement('div');
        card.className = 'gacha-item-card';
        const m = getRarityMeta(data.rarities, it.rarity);
        const badge = document.createElement('span');
        badge.className = 'gacha-rare-badge';
        badge.textContent = m.icon + ' ' + m.label;
        badge.style.background = m.color;
        const img = document.createElement('img');
        img.className = 'gacha-item-img';
        img.src = (it.image && it.image.length) ? it.image : 'img/capsule_normal.png';
        img.alt = it.label || it.name;
        const nm = document.createElement('div');
        nm.className = 'gacha-item-name';
        nm.textContent = it.label || it.name;
        const st = document.createElement('div');
        st.className = 'gacha-item-stock';
        st.textContent = (it.count === -1) ? '在庫: —' : '在庫: ' + it.count;
        const pr = document.createElement('div');
        pr.className = 'gacha-item-prob';
        pr.textContent = '排出率: ' + (it.prob != null ? (Math.round(it.prob * 100) / 100) : 0) + '%';
        card.appendChild(badge);
        card.appendChild(img);
        card.appendChild(nm);
        card.appendChild(st);
        card.appendChild(pr);
        gachaMenuItems.appendChild(card);
    });
    var c = Number(data.cost) || 0;
    btnSingle.innerHTML = '🎰 ガチャを引く<br><span class="btn-price-lbl">' + formatYen(c) + '</span>';
    btnMulti10.innerHTML = '🎲 10連<br><span class="btn-price-lbl">' + formatYen(c * 10) + '</span>';
    function setHope() {
        var h = Math.min(lastMaxPull, Math.max(1, parseInt(gachaHopeInput.value, 10) || 1));
        gachaHopeInput.value = h;
        gachaHopePrice.textContent = '合計 ' + formatYen(c * h);
    }
    setHope();
    gachaHopeInput.oninput = setHope;
    btnSingle.onclick = function (e) {
        if (e) {
            e.preventDefault();
        }
        gachaMenuContainer.classList.add('hidden');
        postNui('menuSelect', { value: 1 });
    };
    btnMulti10.onclick = function (e) {
        if (e) {
            e.preventDefault();
        }
        gachaMenuContainer.classList.add('hidden');
        postNui('menuSelect', { value: 10 });
    };
    btnHope.onclick = function (e) {
        if (e) {
            e.preventDefault();
        }
        var h = Math.min(lastMaxPull, Math.max(1, parseInt(gachaHopeInput.value, 10) || 1));
        gachaMenuContainer.classList.add('hidden');
        postNui('inputSubmit', { count: h });
    };
    gachaMenuClose.onclick = function (e) {
        if (e) {
            e.preventDefault();
        }
        gachaMenuContainer.classList.add('hidden');
        postNui('menuClose', {});
    };
}

function showAdminView(data) {
    setScale(data.scale);
    hideTopAndPass();
    if (adminPassCur) {
        adminPassCur.value = '';
    }
    if (adminPassNew) {
        adminPassNew.value = '';
    }
    adminContainer.classList.remove('hidden');
    gachaMenuContainer.classList.add('hidden');
    menuContainer.classList.add('hidden');
    const s = data.settings || {};
    adminTitle.value = s.title != null ? s.title : 'ガチャマシン';
    adminCost.value = s.cost != null ? s.cost : 0;
    adminTheme.value = s.theme || 'neon';
    const rp = s.rarityPct || { UR: 0, SSR: 0, SR: 0, R: 0 };
    const order = (data.rarities && data.rarities.length) ? data.rarities.map(function (x) { return x.id; }) : ['UR', 'SSR', 'SR', 'R'];
    adminRarityKeyOrder = order;
    adminRarityFields.innerHTML = '';
    (data.rarities || []).forEach(function (def) {
        const id = 'admin-rare-' + def.id;
        const row = document.createElement('div');
        row.className = 'admin-rare-row';
        const lab = document.createElement('label');
        lab.htmlFor = id;
        lab.innerHTML = '<span class="admin-r-ico" style="color:' + (def.color || '#fff') + '">' + (def.icon || '') + '</span> ' + (def.label || def.id);
        const inp = document.createElement('input');
        inp.type = 'number';
        inp.id = id;
        inp.className = 'admin-rare-input';
        inp.min = 0;
        inp.max = 100;
        inp.step = 0.1;
        inp.value = (rp[def.id] != null) ? rp[def.id] : 0;
        const pct = document.createElement('span');
        pct.className = 'admin-pct-suff';
        pct.textContent = '%';
        row.appendChild(lab);
        row.appendChild(inp);
        row.appendChild(pct);
        adminRarityFields.appendChild(row);
    });
    function rtotal() {
        var t = 0;
        (data.rarities || []).forEach(function (d) {
            const el = document.getElementById('admin-rare-' + d.id);
            t += parseFloat((el && el.value) || '0') || 0;
        });
        adminRarityTotal.textContent = (Math.round(t * 10) / 10).toFixed(1);
    }
    (data.rarities || []).forEach(function (d) {
        const el = document.getElementById('admin-rare-' + d.id);
        if (el) {
            el.addEventListener('input', rtotal);
        }
    });
    rtotal();
    adminItemsList.innerHTML = '';
    (data.items || []).forEach(function (it) {
        const line = document.createElement('div');
        line.className = 'admin-item-line';
        const cb = document.createElement('input');
        cb.type = 'checkbox';
        cb.className = 'admin-item-cb';
        cb.dataset.id = it.id;
        cb.checked = (it.enabled !== false);
        const t = document.createElement('span');
        t.className = 'admin-item-title';
        t.textContent = (it.label || it.name) + (it.count >= 0 ? ' (在庫' + it.count + ')' : '');
        const sel = document.createElement('select');
        sel.className = 'admin-item-sel';
        (data.rarities || []).forEach(function (r) {
            const o = document.createElement('option');
            o.value = r.id;
            o.textContent = (r.label || r.id);
            if ((it.rarity || 'R') === r.id) {
                o.selected = true;
            }
            sel.appendChild(o);
        });
        sel.dataset.id = it.id;
        line.appendChild(cb);
        line.appendChild(t);
        line.appendChild(sel);
        adminItemsList.appendChild(line);
    });
    adminSave.disabled = false;
    adminSave.textContent = '保存';
}

function readAdminSavePayload() {
    const rarityPct = { UR: 0, SSR: 0, SR: 0, R: 0 };
    (adminRarityFields.querySelectorAll('input') || []).forEach(function (inp) {
        if (inp.id && inp.id.indexOf('admin-rare-') === 0) {
            const k = inp.id.replace('admin-rare-', '');
            if (k in rarityPct) {
                rarityPct[k] = parseFloat(inp.value) || 0;
            }
        }
    });
    const items = [];
    (adminItemsList.querySelectorAll('.admin-item-cb') || []).forEach(function (cb) {
        const id = cb.dataset.id;
        const line = cb.closest ? cb.closest('.admin-item-line') : null;
        const sel = line ? line.querySelector('select') : null;
        items.push({
            id: id,
            enabled: cb.checked,
            rarity: (sel && sel.value) || 'R'
        });
    });
    return {
        title: adminTitle.value,
        cost: parseInt(adminCost.value, 10) || 0,
        theme: adminTheme.value,
        rarityPct: rarityPct,
        items: items
    };
}

if (adminSave) {
    adminSave.addEventListener('click', function () {
        adminSave.textContent = '保存中...';
        adminSave.disabled = true;
        postNui('adminSave', readAdminSavePayload());
    });
}
if (adminCancel) {
    adminCancel.addEventListener('click', function () {
        adminContainer.classList.add('hidden');
        postNui('adminClose', {});
    });
}
if (adminClose) {
    adminClose.addEventListener('click', function () {
        adminContainer.classList.add('hidden');
        postNui('adminClose', {});
    });
}

function showMenu(data) {
    setScale(data.scale);
    menuTitle.textContent = data.title;
    menuOptions.innerHTML = '';

    data.options.forEach(function (opt) {
        const btn = document.createElement('button');
        btn.classList.add('menu-option');
        btn.textContent = opt.label;
        btn.addEventListener('click', function (e) {
            if (e) {
                e.preventDefault();
            }
            hideMenu();
            const v = (opt.value === 'custom') ? 'custom' : Number(opt.value);
            postNui('menuSelect', { value: v });
        });
        menuOptions.appendChild(btn);
    });

    menuContainer.classList.remove('hidden');
}

function hideMenu() {
    menuContainer.classList.add('hidden');
}

function showInput(data) {
    setScale(data.scale);
    inputFromGacha = !!(data && data.fromGacha);
    inputTitle.textContent = data.title;
    inputField.max = data.max;
    inputField.value = 1;
    inputContainer.classList.remove('hidden');
    inputField.focus();
}

function hideInput() {
    inputContainer.classList.add('hidden');
}

inputSubmitButton.addEventListener('click', function () {
    const count = parseInt(inputField.value, 10);
    hideInput();
    postNui('inputSubmit', { count: count });
});

inputCancelButton.addEventListener('click', function () {
    if (inputFromGacha) {
        inputFromGacha = false;
        hideInput();
        postNui('gachaInputCancel', {});
        return;
    }
    hideInput();
    postNui('menuClose', {});
});

document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') {
        if (passContainer && !passContainer.classList.contains('hidden')) {
            if (passCancel) {
                passCancel.click();
            } else {
                inPassFlow = false;
                passContainer.classList.add('hidden');
                if (topMenuContainer) {
                    topMenuContainer.classList.remove('hidden');
                }
                if (passError) {
                    passError.classList.add('hidden');
                }
            }
            return;
        }
        if (topMenuContainer && !topMenuContainer.classList.contains('hidden')) {
            topMenuContainer.classList.add('hidden');
            postNui('menuClose', {});
            return;
        }
        if (!inputContainer.classList.contains('hidden')) {
            if (inputFromGacha) {
                inputFromGacha = false;
                hideInput();
                postNui('gachaInputCancel', {});
            } else {
                hideInput();
                postNui('menuClose', {});
            }
            return;
        }
        if (!gachaMenuContainer.classList.contains('hidden')) {
            gachaMenuContainer.classList.add('hidden');
            postNui('menuClose', {});
            return;
        }
        if (!adminContainer.classList.contains('hidden')) {
            adminContainer.classList.add('hidden');
            postNui('adminClose', {});
            return;
        }
        if (!menuContainer.classList.contains('hidden')) {
            hideMenu();
            postNui('menuClose', {});
        }
    }
});

inputField.addEventListener('keydown', function (e) {
    if (e.key === 'Enter') {
        inputSubmitButton.click();
    }
});

function showSingleResult(data) {
    singleCapsuleArea.classList.add('hidden');
    resultRarity.textContent = data.rarityId;
    resultRarity.style.color = data.rarityColor;
    resultItemName.textContent = data.itemName;
    resultLayer.classList.remove('hidden');
    resultLayer.classList.add('show');
    playSound(data.cutin ? 'result_rare.mp3' : 'result_normal.mp3');
}

function showCutinByRarity(rarityId, duration) {
    const cutinMap = { SR: 'cutin_sr.png', SSR: 'cutin_ssr.png', UR: 'cutin_ur.png' };
    const cutinFile = cutinMap[rarityId];
    if (!cutinFile) {
        return;
    }
    cutinImg.src = 'img/' + cutinFile;
    cutinLayer.classList.remove('hidden');
    cutinLayer.classList.add('slide-in');
    playSound('cutin.mp3');
    safeTimeout(function () {
        cutinLayer.classList.add('hidden');
        cutinLayer.classList.remove('slide-in');
    }, duration);
}

function findBestResult(results) {
    const order = { N: 1, R: 2, SR: 3, SSR: 4, UR: 5 };
    let best = results[0];
    results.forEach(function (r) {
        if ((order[r.rarityId] || 1) > (order[best.rarityId] || 1)) {
            best = r;
        }
    });
    return best;
}

function startSingleGacha(data, timing) {
    resetAll();
    gachaContainer.classList.remove('hidden');

    bgImage.src = 'img/bg_normal.png';
    bgLayer.classList.add('active');

    singleCapsuleArea.classList.remove('hidden');
    capsuleImg.src = 'img/capsule_' + data.capsule + '.png';
    capsuleImg.classList.add('drop');
    playSound('gacha_roll.mp3');

    const hasCutin = data.rarityId === 'SR' || data.rarityId === 'SSR' || data.rarityId === 'UR';

    safeTimeout(function () {
        capsuleImg.src = 'img/capsule_crack1.png';
        capsuleImg.classList.remove('drop');
        capsuleImg.classList.add('shake');
        playSound('crack.mp3');
    }, timing.crack1Delay);

    if (hasCutin) {
        safeTimeout(function () {
            capsuleImg.src = 'img/capsule_crack2.png';
            capsuleImg.classList.remove('shake');
            void capsuleImg.offsetWidth;
            capsuleImg.classList.add('shake');
        }, timing.crack2Delay);
    }

    safeTimeout(function () {
        capsuleImg.src = 'img/capsule_open.png';
        capsuleImg.classList.remove('shake');
        capsuleImg.classList.add('explode');
        playSound('break_open.mp3');

        flashLayer.classList.remove('hidden');
        flashLayer.classList.add('flash-anim');
        safeTimeout(function () {
            flashLayer.classList.add('hidden');
            flashLayer.classList.remove('flash-anim');
        }, timing.flashDuration);

        bgImage.src = 'img/bg_' + data.bg + '.png';

        if (data.rarityId === 'SSR' || data.rarityId === 'UR') {
            gachaContainer.classList.add('screen-shake');
            safeTimeout(function () {
                gachaContainer.classList.remove('screen-shake');
            }, 500);
        }

        if (data.rarityId === 'SR' || data.rarityId === 'SSR' || data.rarityId === 'UR') {
            spawnParticles(30, 'star');
        } else {
            spawnParticles(10, 'circle');
        }
    }, timing.breakDelay);

    if (hasCutin) {
        safeTimeout(function () {
            showCutinByRarity(data.rarityId, timing.cutinDuration);
        }, timing.breakDelay + timing.flashDuration + 100);
    }

    safeTimeout(function () {
        showSingleResult(data);
    }, timing.resultDelay);

    safeTimeout(function () {
        resetAll();
        notifyComplete();
    }, timing.totalDuration);
}

function showMultiResult(results) {
    multiCapsuleArea.classList.add('hidden');
    multiResultList.innerHTML = '';

    results.forEach(function (r, i) {
        const card = document.createElement('div');
        card.classList.add('multi-result-card');
        card.style.borderColor = r.rarityColor;
        card.style.animationDelay = i * 0.1 + 's';

        const rarityDiv = document.createElement('div');
        rarityDiv.classList.add('card-rarity');
        rarityDiv.textContent = r.rarityId;
        rarityDiv.style.color = r.rarityColor;

        const itemDiv = document.createElement('div');
        itemDiv.classList.add('card-item');
        itemDiv.textContent = r.itemName;

        card.appendChild(rarityDiv);
        card.appendChild(itemDiv);
        multiResultList.appendChild(card);
    });

    multiResultArea.classList.remove('hidden');
    playSound('result_rare.mp3');

    const displayTime = currentMultiData && currentMultiData.timing
        ? (currentMultiData.timing.multiResultDisplay || 5000)
        : 5000;
    safeTimeout(function () {
        resetAll();
        notifyComplete();
    }, displayTime);
}

function startMultiGacha(data) {
    resetAll();
    const results = data.results;
    const count = data.count;
    const timing = data.timing;

    setScale(data.scale);
    gachaContainer.classList.remove('hidden');

    const bestResult = findBestResult(results);
    bgImage.src = 'img/bg_normal.png';
    bgLayer.classList.add('active');

    if (count === 1) {
        startSingleGacha(results[0], timing);
        return;
    }

    multiCapsuleArea.classList.remove('hidden');
    multiCapsuleArea.innerHTML = '';

    const slots = [];
    for (let i = 0; i < count; i++) {
        const slot = document.createElement('div');
        slot.classList.add('multi-capsule-slot');

        const img = document.createElement('img');
        img.classList.add('multi-capsule-img', 'unopened');
        img.src = 'img/capsule_' + results[i].capsule + '.png';

        const label = document.createElement('div');
        label.classList.add('multi-capsule-label');
        label.style.color = results[i].rarityColor;

        slot.appendChild(img);
        slot.appendChild(label);
        multiCapsuleArea.appendChild(slot);
        slots.push({ img: img, label: label, result: results[i] });
    }

    let currentIndex = 0;
    function openNext() {
        if (currentIndex >= count) {
            return;
        }

        const slot = slots[currentIndex];
        slot.img.classList.remove('unopened');
        slot.img.classList.add('opening');
        playSound('crack.mp3');

        safeTimeout(function () {
            slot.img.classList.remove('opening');
            slot.img.classList.add('opened');
            playSound('break_open.mp3');

            if (slot.result.rarityId === 'SR' || slot.result.rarityId === 'SSR' || slot.result.rarityId === 'UR') {
                flashLayer.classList.remove('hidden');
                flashLayer.classList.add('flash-anim');
                safeTimeout(function () {
                    flashLayer.classList.add('hidden');
                    flashLayer.classList.remove('flash-anim');
                }, 200);
            }

            safeTimeout(function () {
                slot.img.style.opacity = '0';
                slot.label.textContent = '[' + slot.result.rarityId + '] ' + slot.result.itemName;
                slot.label.classList.add('visible');

                currentIndex = currentIndex + 1;
                if (currentIndex < count) {
                    safeTimeout(openNext, timing.multiCapsuleInterval * 0.3);
                } else {
                    bgImage.src = 'img/bg_' + bestResult.bg + '.png';
                    if (bestResult.rarityId === 'SSR' || bestResult.rarityId === 'UR') {
                        gachaContainer.classList.add('screen-shake');
                        safeTimeout(function () {
                            gachaContainer.classList.remove('screen-shake');
                        }, 500);
                        spawnParticles(40, 'star');
                    } else if (bestResult.rarityId === 'SR') {
                        spawnParticles(20, 'star');
                    }

                    if (bestResult.rarityId === 'SR' || bestResult.rarityId === 'SSR' || bestResult.rarityId === 'UR') {
                        showCutinByRarity(bestResult.rarityId, timing.cutinDuration);
                    }

                    safeTimeout(function () {
                        showMultiResult(results);
                    }, 1500);
                }
            }, 300);
        }, 400);
    }

    safeTimeout(openNext, 800);

    const maxTime = timing.multiCapsuleInterval * count + timing.multiResultDisplay + 5000;
    safeTimeout(function () {
        resetAll();
        notifyComplete();
    }, maxTime);
}

window.addEventListener('message', function (event) {
    const data = event.data;
    switch (data.type) {
        case 'showMenu':
            showMenu(data);
            break;
        case 'showInput':
            showInput(data);
            break;
        case 'showTopMenu':
            showTopMenuView(data);
            break;
        case 'showGachaMenu':
            showGachaMenuView(data);
            break;
        case 'showAdmin':
            showAdminView(data);
            break;
        case 'adminDenied':
            if (passError) {
                passError.classList.remove('hidden');
            }
            if (passContainer) {
                passContainer.classList.remove('hidden');
            }
            if (topMenuContainer) {
                topMenuContainer.classList.add('hidden');
            }
            inPassFlow = true;
            break;
        case 'changePasswordResult':
            if (adminToast) {
                if (data && data.ok) {
                    adminToast.textContent = 'パスワードを変更しました';
                    adminToast.classList.add('ok');
                    if (adminPassCur) {
                        adminPassCur.value = '';
                    }
                    if (adminPassNew) {
                        adminPassNew.value = '';
                    }
                } else {
                    var pm = 'パスワードの変更に失敗しました';
                    if (data && data.reason === 'mismatch') {
                        pm = '現在のパスワードが違います';
                    } else if (data && data.reason === 'empty') {
                        pm = '新しいパスワードを入力してください';
                    }
                    adminToast.textContent = pm;
                    adminToast.classList.remove('ok');
                }
                adminToast.classList.remove('hidden');
                setTimeout(function () {
                    adminToast.classList.add('hidden');
                }, 2200);
            }
            break;
        case 'adminSaveResult':
            if (adminSave) {
                adminSave.disabled = false;
                adminSave.textContent = '保存';
            }
            if (adminToast) {
                if (data && data.ok) {
                    adminToast.textContent = '保存しました';
                    adminToast.classList.add('ok');
                } else {
                    var msg = '保存に失敗しました';
                    if (data && data.reason === 'rarity') {
                        msg = '合計%が 100% 付近になるよう調整してください';
                    } else if (data && data.reason === 'invalid') {
                        msg = '送信中に不整合が発生しました';
                    }
                    adminToast.textContent = msg;
                    adminToast.classList.remove('ok');
                }
                adminToast.classList.remove('hidden');
                setTimeout(function () {
                    adminToast.classList.add('hidden');
                }, 2200);
            }
            break;
        case 'startMultiGacha':
            setScale(data.scale);
            currentMultiData = data;
            startMultiGacha(data);
            break;
        default:
            break;
    }
});
