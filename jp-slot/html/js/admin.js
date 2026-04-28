/* global window, document, GetParentResourceName, fetch */
(function () {
    function resourceName() {
        if (typeof GetParentResourceName === 'function') {
            return GetParentResourceName();
        }
        return 'jp-slot';
    }

    function syncSlidersFromSize(s) {
        if (!s) {
            return;
        }
        var wEl = document.getElementById('ui-width');
        var hEl = document.getElementById('ui-height');
        var mEl = document.getElementById('ui-maxwidth');
        var wVal = document.getElementById('ui-width-val');
        var hVal = document.getElementById('ui-height-val');
        if (wEl) {
            wEl.value = String(s.widthPercent != null ? s.widthPercent : 90);
        }
        if (hEl) {
            hEl.value = String(s.heightPercent != null ? s.heightPercent : 90);
        }
        if (mEl) {
            mEl.value = String(s.maxWidthPx != null ? s.maxWidthPx : 0);
        }
        if (wVal) {
            wVal.textContent = wEl ? wEl.value : '90';
        }
        if (hVal) {
            hVal.textContent = hEl ? hEl.value : '90';
        }
    }

    function previewLocal() {
        var wEl = document.getElementById('ui-width');
        var hEl = document.getElementById('ui-height');
        var mEl = document.getElementById('ui-maxwidth');
        if (!wEl || !hEl || !mEl) {
            return;
        }
        var size = {
            widthPercent: Number(wEl.value),
            heightPercent: Number(hEl.value),
            maxWidthPx: Number(mEl.value),
        };
        if (window.applyUISize) {
            window.applyUISize(size);
        }
    }

    function initTabs() {
        var tabs = document.querySelectorAll('.admin-tab');
        var panes = document.querySelectorAll('.admin-pane');
        for (var i = 0; i < tabs.length; i++) {
            tabs[i].addEventListener('click', function () {
                var tabName = this.getAttribute('data-tab');
                for (var j = 0; j < tabs.length; j++) {
                    tabs[j].classList.remove('active');
                }
                this.classList.add('active');
                for (var k = 0; k < panes.length; k++) {
                    var p = panes[k];
                    if (p.getAttribute('data-pane') === tabName) {
                        p.style.display = 'block';
                    } else {
                        p.style.display = 'none';
                    }
                }
            });
        }
    }

    function initUISizeControls() {
        var wEl = document.getElementById('ui-width');
        var hEl = document.getElementById('ui-height');
        var mEl = document.getElementById('ui-maxwidth');
        var wVal = document.getElementById('ui-width-val');
        var hVal = document.getElementById('ui-height-val');
        var saveBtn = document.getElementById('ui-size-save');
        var resetBtn = document.getElementById('ui-size-reset');
        if (!wEl || !hEl || !mEl) {
            return;
        }

        wEl.addEventListener('input', function () {
            if (wVal) {
                wVal.textContent = wEl.value;
            }
            previewLocal();
        });
        hEl.addEventListener('input', function () {
            if (hVal) {
                hVal.textContent = hEl.value;
            }
            previewLocal();
        });
        mEl.addEventListener('input', previewLocal);

        if (saveBtn) {
            saveBtn.addEventListener('click', function () {
                var body = {
                    widthPercent: Number(wEl.value),
                    heightPercent: Number(hEl.value),
                    maxWidthPx: Number(mEl.value),
                };
                fetch('https://' + resourceName() + '/admin/setUISize', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                    body: JSON.stringify(body),
                }).catch(function (err) {
                    console.warn('[jp-slot] setUISize failed', err);
                });
            });
        }
        if (resetBtn) {
            resetBtn.addEventListener('click', function () {
                wEl.value = '90';
                hEl.value = '90';
                mEl.value = '0';
                if (wVal) {
                    wVal.textContent = '90';
                }
                if (hVal) {
                    hVal.textContent = '90';
                }
                previewLocal();
                fetch('https://' + resourceName() + '/admin/resetUISize', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                    body: '{}',
                }).catch(function (err) {
                    console.warn('[jp-slot] resetUISize failed', err);
                });
            });
        }
    }

    window.addEventListener('message', function (e) {
        var d = e.data || {};
        if (d.type === 'openAdmin' && d.payload && d.payload.uiSize) {
            syncSlidersFromSize(d.payload.uiSize);
        }
        if (d.type === 'applyUISize' && d.payload) {
            syncSlidersFromSize(d.payload);
        }
    });

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function () {
            initTabs();
            initUISizeControls();
        });
    } else {
        initTabs();
        initUISizeControls();
    }
})();
