/* global GetParentResourceName */
(function () {
    'use strict';

    const container = document.getElementById('gacha-container');
    const bgLayer = document.getElementById('bg-layer');
    const bgImage = document.getElementById('bg-image');
    const flashLayer = document.getElementById('flash-layer');
    const particleLayer = document.getElementById('particle-layer');
    const capsuleImg = document.getElementById('capsule-img');
    const cutinLayer = document.getElementById('cutin-layer');
    const cutinImg = document.getElementById('cutin-img');
    const resultLayer = document.getElementById('result-layer');
    const resultRarity = document.getElementById('result-rarity');
    const resultItemName = document.getElementById('result-item-name');

    const resourceName = typeof GetParentResourceName === 'function'
        ? GetParentResourceName()
        : 'jp-gacha';

    // HEAD で存在を確認し、あるときだけ再生（失敗時は従来の new Audio も黙って失敗）
    function playSound(filename) {
        const url = 'sounds/' + filename;
        function tryPlayFromAudio() {
            try {
                const audio = new Audio(url);
                audio.volume = 0.6;
                audio.addEventListener('error', function () {}, { once: true });
                const p = audio.play();
                if (p) {
                    p.catch(function () {});
                }
            } catch (e) {}
        }
        if (typeof fetch !== 'function') {
            tryPlayFromAudio();
            return;
        }
        fetch(url, { method: 'HEAD' })
            .then(function (res) {
                if (res && res.ok) {
                    try {
                        const a = new Audio(url);
                        a.volume = 0.6;
                        const p = a.play();
                        if (p) {
                            p.catch(function () {});
                        }
                    } catch (e) {}
                } else {
                    tryPlayFromAudio();
                }
            })
            .catch(tryPlayFromAudio);
    }

    function spawnParticles(count, type) {
        for (var i = 0; i < count; i++) {
            const p = document.createElement('img');
            p.classList.add('particle');
            p.src = type === 'star' ? 'img/particles_star.png' : 'img/particles_circle.png';
            p.style.left = Math.random() * 100 + '%';
            p.style.width = (20 + Math.random() * 30) + 'px';
            p.style.animationDuration = (2 + Math.random() * 3) + 's';
            p.style.animationDelay = Math.random() * 1 + 's';
            particleLayer.appendChild(p);
        }
    }

    function clearParticles() {
        particleLayer.innerHTML = '';
    }

    function resetAll() {
        container.classList.add('hidden');
        container.classList.remove('screen-shake');
        bgLayer.classList.remove('active');
        bgImage.src = '';
        flashLayer.classList.add('hidden');
        flashLayer.classList.remove('flash-anim');
        capsuleImg.src = '';
        capsuleImg.className = '';
        cutinLayer.classList.add('hidden');
        cutinLayer.classList.remove('slide-in');
        cutinImg.src = '';
        resultLayer.classList.add('hidden');
        resultLayer.classList.remove('show');
        clearParticles();
    }

    function startGachaSequence(data) {
        resetAll();
        const t = data.timing;

        container.classList.remove('hidden');

        bgImage.src = 'img/bg_normal.png';
        bgLayer.classList.add('active');

        const capsuleFile = 'img/capsule_' + data.capsule + '.png';
        capsuleImg.src = capsuleFile;
        capsuleImg.classList.add('drop');
        playSound('gacha_roll.mp3');

        setTimeout(function () {
            capsuleImg.src = 'img/capsule_crack1.png';
            capsuleImg.classList.remove('drop');
            capsuleImg.classList.add('shake');
            playSound('crack.mp3');
        }, t.crack1Delay);

        const hasCutin = data.cutin;
        if (hasCutin) {
            setTimeout(function () {
                capsuleImg.src = 'img/capsule_crack2.png';
                capsuleImg.classList.remove('shake');
                void capsuleImg.offsetWidth;
                capsuleImg.classList.add('shake');
            }, t.crack2Delay);
        }

        setTimeout(function () {
            capsuleImg.src = 'img/capsule_open.png';
            capsuleImg.classList.remove('shake');
            capsuleImg.classList.add('explode');
            playSound('break_open.mp3');

            flashLayer.classList.remove('hidden');
            flashLayer.classList.add('flash-anim');
            setTimeout(function () {
                flashLayer.classList.add('hidden');
                flashLayer.classList.remove('flash-anim');
            }, t.flashDuration);

            bgImage.src = 'img/bg_' + data.bg + '.png';

            if (data.rarity === 'SSR' || data.rarity === 'UR') {
                container.classList.add('screen-shake');
                setTimeout(function () {
                    container.classList.remove('screen-shake');
                }, 500);
            }

            if (data.rarity === 'SR' || data.rarity === 'SSR' || data.rarity === 'UR') {
                spawnParticles(30, 'star');
            } else {
                spawnParticles(10, 'circle');
            }
        }, t.breakDelay);

        if (hasCutin) {
            setTimeout(function () {
                const cutinMap = { SR: 'cutin_sr.png', SSR: 'cutin_ssr.png', UR: 'cutin_ur.png' };
                const cutinFile = cutinMap[data.rarity];
                if (cutinFile) {
                    cutinImg.src = 'img/' + cutinFile;
                    cutinLayer.classList.remove('hidden');
                    cutinLayer.classList.add('slide-in');
                    playSound('cutin.mp3');
                    setTimeout(function () {
                        cutinLayer.classList.add('hidden');
                        cutinLayer.classList.remove('slide-in');
                    }, t.cutinDuration);
                }
            }, t.breakDelay + t.flashDuration + 100);
        }

        setTimeout(function () {
            capsuleImg.classList.add('hidden');
            resultRarity.textContent = data.rarityName;
            resultRarity.style.color = data.rarityColor;
            resultItemName.textContent = data.itemName;
            resultLayer.classList.remove('hidden');
            resultLayer.classList.add('show');
            playSound(hasCutin ? 'result_rare.mp3' : 'result_normal.mp3');
        }, t.resultDelay);

        setTimeout(function () {
            resetAll();
            fetch('https://' + resourceName + '/gachaComplete', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({}),
            }).catch(function () {});
        }, t.totalDuration);
    }

    window.addEventListener('message', function (event) {
        const data = event.data;
        if (data && data.type === 'startGacha') {
            startGachaSequence(data);
        }
    });
}());
