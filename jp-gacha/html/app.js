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

let allTimers = [];
let currentMultiData = null;

function getResourceName() {
    try {
        if (typeof GetParentResourceName === 'function') {
            return GetParentResourceName();
        }
    } catch (e) {}
    return 'jp-gacha';
}

function setScale(scale) {
    document.documentElement.style.setProperty('--scale', scale || 2);
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

function showMenu(data) {
    setScale(data.scale);
    menuTitle.textContent = data.title;
    menuOptions.innerHTML = '';

    data.options.forEach(function (opt) {
        const btn = document.createElement('button');
        btn.classList.add('menu-option');
        btn.textContent = opt.label;
        btn.addEventListener('click', function () {
            hideMenu();
            postNui('menuSelect', { value: opt.value });
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
    hideInput();
    postNui('menuClose', {});
});

document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') {
        if (!menuContainer.classList.contains('hidden')) {
            hideMenu();
            postNui('menuClose', {});
        }
        if (!inputContainer.classList.contains('hidden')) {
            hideInput();
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
            const cutinMap = { SR: 'cutin_sr.png', SSR: 'cutin_ssr.png', UR: 'cutin_ur.png' };
            const cutinFile = cutinMap[data.rarityId];
            if (cutinFile) {
                cutinImg.src = 'img/' + cutinFile;
                cutinLayer.classList.remove('hidden');
                cutinLayer.classList.add('slide-in');
                playSound('cutin.mp3');
                safeTimeout(function () {
                    cutinLayer.classList.add('hidden');
                    cutinLayer.classList.remove('slide-in');
                }, timing.cutinDuration);
            }
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
        case 'startMultiGacha':
            setScale(data.scale);
            currentMultiData = data;
            startMultiGacha(data);
            break;
        default:
            break;
    }
});
