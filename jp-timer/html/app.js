let timerInterval = null;
let expireTimeout = null;
let remainingSeconds = 0;
let hideAfterFadeTimeout = null;

const container = document.getElementById('timer-container');
const display = document.getElementById('timer-display');

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.type === 'startTimer') {
        startTimer(data.minutes);
    }

    if (data.type === 'stopTimer') {
        stopTimer();
    }
});

function startTimer(minutes) {
    clearAll();

    remainingSeconds = Math.floor(minutes * 60);

    container.style.display = 'block';
    container.classList.remove('fadeout');
    updateDisplay();

    timerInterval = setInterval(() => {
        remainingSeconds -= 1;

        if (remainingSeconds <= 0) {
            remainingSeconds = 0;
            updateDisplay();
            if (timerInterval) {
                clearInterval(timerInterval);
                timerInterval = null;
            }

            display.className = 'expired';

            expireTimeout = setTimeout(() => {
                container.classList.add('fadeout');
                hideAfterFadeTimeout = setTimeout(() => {
                    container.style.display = 'none';
                    display.className = '';
                }, 1000);
            }, 10000);

            return;
        }

        updateDisplay();
    }, 1000);
}

function updateDisplay() {
    const min = Math.floor(remainingSeconds / 60);
    const sec = remainingSeconds % 60;
    display.textContent = `${min}'${sec.toString().padStart(2, '0')}`;

    if (remainingSeconds <= 0) {
        display.className = 'expired';
    } else if (remainingSeconds <= 10) {
        display.className = 'critical';
    } else if (remainingSeconds <= 30) {
        display.className = 'warning';
    } else {
        display.className = 'running';
    }
}

function stopTimer() {
    clearAll();
    container.style.display = 'none';
    display.className = '';
}

function clearAll() {
    if (timerInterval) {
        clearInterval(timerInterval);
        timerInterval = null;
    }
    if (expireTimeout) {
        clearTimeout(expireTimeout);
        expireTimeout = null;
    }
    if (hideAfterFadeTimeout) {
        clearTimeout(hideAfterFadeTimeout);
        hideAfterFadeTimeout = null;
    }
}
