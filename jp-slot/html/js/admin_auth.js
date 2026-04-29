/* global window, document, fetch, GetParentResourceName */
(function () {
    var RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'jp-slot';
    var state = { token: null, attempts: 0, maxAttempts: 5, lockedUntil: 0 };

    function $(id) {
        return document.getElementById(id);
    }

    function setLocked(locked) {
        var app = $('admin-app');
        if (!app) {
            return;
        }
        app.dataset.locked = locked ? 'true' : 'false';
    }

    function showAuth() {
        var ov = $('admin-auth-overlay');
        if (!ov) {
            return;
        }
        ov.style.display = 'flex';
        setLocked(true);
        var input = $('admin-auth-pw');
        if (input) {
            input.value = '';
            window.setTimeout(function () {
                input.focus();
            }, 50);
        }
        clearError();
    }

    function hideAuth() {
        var ov = $('admin-auth-overlay');
        if (ov) {
            ov.style.display = 'none';
        }
    }

    function showError(msg) {
        var box = $('admin-auth-error');
        if (!box) {
            return;
        }
        box.textContent = msg;
        box.removeAttribute('hidden');
        var modal = document.querySelector('#admin-auth-overlay .admin-auth-modal');
        if (modal) {
            modal.classList.remove('is-error');
            void modal.offsetWidth;
            modal.classList.add('is-error');
        }
    }

    function clearError() {
        var box = $('admin-auth-error');
        if (box) {
            box.textContent = '';
            box.setAttribute('hidden', '');
            box.classList.remove('admin-auth-lockout');
        }
    }

    function startCountdown(remainSec) {
        clearError();
        var box = $('admin-auth-error');
        if (!box) {
            return;
        }
        box.classList.add('admin-auth-lockout');
        box.removeAttribute('hidden');
        var until = Date.now() + remainSec * 1000;
        function tick() {
            var rem = Math.max(0, Math.floor((until - Date.now()) / 1000));
            var mm = String(Math.floor(rem / 60)).padStart(2, '0');
            var ss = String(rem % 60).padStart(2, '0');
            box.innerHTML = '🚫 ロック中<br>残り ' + mm + ':' + ss + ' 後に再試行できます';
            if (rem <= 0) {
                box.classList.remove('admin-auth-lockout');
                clearError();
                var sub = $('admin-auth-submit');
                var pw = $('admin-auth-pw');
                if (sub) {
                    sub.disabled = false;
                }
                if (pw) {
                    pw.disabled = false;
                }
                return;
            }
            window.setTimeout(tick, 500);
        }
        var sub2 = $('admin-auth-submit');
        var pw2 = $('admin-auth-pw');
        if (sub2) {
            sub2.disabled = true;
        }
        if (pw2) {
            pw2.disabled = true;
        }
        tick();
    }

    function fetchNui(path, body) {
        return fetch('https://' + RES + '/' + path, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(body || {}),
        })
            .then(function (r) {
                return r.json();
            })
            .catch(function () {
                return { ok: false, reason: 'network' };
            });
    }

    function login() {
        var pwEl = $('admin-auth-pw');
        var pw = pwEl ? pwEl.value || '' : '';
        var keep = $('admin-auth-keep') && $('admin-auth-keep').checked;
        if (!pw) {
            showError('パスワードを入力してください');
            return;
        }
        var sub = $('admin-auth-submit');
        if (sub) {
            sub.disabled = true;
        }
        fetchNui('admin/login', { password: pw, keep: keep }).then(function (res) {
            if (sub) {
                sub.disabled = false;
            }
            if (res.ok) {
                state.token = res.token;
                window.JpSlotAdminAuth.token = res.token;
                successFlashThenUnlock();
                if (window.JpSlotAdminStudio && window.JpSlotAdminStudio.onLogin) {
                    window.JpSlotAdminStudio.onLogin(res);
                }
                var st = $('adm-status-left');
                if (st) {
                    st.textContent = 'ログイン済み';
                }
            } else if (res.reason === 'locked') {
                startCountdown(res.lockRemain || 300);
            } else if (res.reason === 'no_ace') {
                showError('権限がありません (ACE: jp-slot.admin)');
            } else if (res.reason === 'wrong') {
                state.attempts++;
                showError('パスワードが正しくありません (' + state.attempts + ' / ' + state.maxAttempts + ' 回失敗)');
            } else {
                showError('エラー: ' + (res.reason || 'unknown'));
            }
        });
    }

    function successFlashThenUnlock() {
        var modal = document.querySelector('#admin-auth-overlay .admin-auth-modal');
        if (modal) {
            var fx = document.createElement('div');
            fx.className = 'admin-auth-success';
            fx.textContent = '✓';
            modal.appendChild(fx);
            window.setTimeout(function () {
                fx.remove();
            }, 700);
        }
        window.setTimeout(function () {
            hideAuth();
            setLocked(false);
        }, 350);
    }

    function logout() {
        var t = state.token;
        state.token = null;
        window.JpSlotAdminAuth.token = null;
        fetchNui('admin/logout', { token: t });
        showAuth();
        var st = $('adm-status-left');
        if (st) {
            st.textContent = '未ログイン';
        }
    }

    function closeApp() {
        function doClose() {
            fetchNui('admin/close', { token: state.token });
            var p = $('panel-admin');
            if (p) {
                p.style.display = 'none';
            }
        }
        if (window.JpSlotTryConfirmDirtyExit) {
            window.JpSlotTryConfirmDirtyExit(doClose);
        } else {
            doClose();
        }
    }

    function togglePwVisibility() {
        var inp = $('admin-auth-pw');
        if (!inp) {
            return;
        }
        inp.type = inp.type === 'password' ? 'text' : 'password';
    }

    function openPwChange() {
        var o = $('admin-pw-overlay');
        if (o) {
            o.removeAttribute('hidden');
        }
    }

    function closePwChange() {
        var o = $('admin-pw-overlay');
        if (o) {
            o.setAttribute('hidden', '');
        }
        var err = $('admin-pw-error');
        if (err) {
            err.setAttribute('hidden', '');
        }
    }

    function submitPwChange() {
        var oldP = $('adm-pw-old').value || '';
        var n1 = $('adm-pw-new').value || '';
        var n2 = $('adm-pw-new2').value || '';
        var err = $('admin-pw-error');
        if (n1.length < 8) {
            err.textContent = '新しいパスワードは8文字以上にしてください';
            err.removeAttribute('hidden');
            return;
        }
        if (n1 !== n2) {
            err.textContent = '新しいパスワード（確認）が一致しません';
            err.removeAttribute('hidden');
            return;
        }
        fetchNui('admin/changePassword', {
            token: state.token,
            oldPassword: oldP,
            newPassword: n1,
        }).then(function (res) {
            if (res.ok) {
                closePwChange();
                $('adm-pw-old').value = '';
                $('adm-pw-new').value = '';
                $('adm-pw-new2').value = '';
                window.alert('パスワードを変更しました。次回から新しいパスワードを使用します。');
            } else {
                err.textContent = '変更失敗: ' + (res.reason || 'unknown');
                err.removeAttribute('hidden');
            }
        });
    }

    function bind() {
        var s = $('admin-auth-submit');
        if (s) {
            s.addEventListener('click', login);
        }
        var c = $('admin-auth-cancel');
        if (c) {
            c.addEventListener('click', closeApp);
        }
        var cx = $('admin-auth-close-btn');
        if (cx) {
            cx.addEventListener('click', closeApp);
        }
        var eye = $('admin-auth-eye');
        if (eye) {
            eye.addEventListener('click', togglePwVisibility);
        }
        var pwi = $('admin-auth-pw');
        if (pwi) {
            pwi.addEventListener('keydown', function (e) {
                if (e.key === 'Enter') {
                    login();
                }
            });
        }
        document.addEventListener(
            'keydown',
            function (e) {
                var ov = $('admin-auth-overlay');
                if (ov && ov.style.display !== 'none' && e.key === 'Escape') {
                    closeApp();
                }
            },
            true
        );
        var cp = $('adm-changepw-open');
        if (cp) {
            cp.addEventListener('click', openPwChange);
        }
        var lo = $('adm-logout');
        if (lo) {
            lo.addEventListener('click', logout);
        }
        var cl = $('adm-close-app');
        if (cl) {
            cl.addEventListener('click', closeApp);
        }
        var pwc = $('admin-pw-close');
        if (pwc) {
            pwc.addEventListener('click', closePwChange);
        }
        var pwx = $('admin-pw-cancel');
        if (pwx) {
            pwx.addEventListener('click', closePwChange);
        }
        var pws = $('admin-pw-submit');
        if (pws) {
            pws.addEventListener('click', submitPwChange);
        }
    }

    function onMessage(e) {
        var d = e.data || {};
        if (d.type === 'openAdmin') {
            var p = $('panel-admin');
            if (p) {
                p.style.display = 'flex';
            }
            var pay = d.payload || {};
            if (pay.requirePassword) {
                showAuth();
            } else {
                setLocked(false);
                hideAuth();
                window.JpSlotAdminAuth.token = null;
                state.token = null;
                var st = $('adm-status-left');
                if (st) {
                    st.textContent = '認証スキップ';
                }
            }
            if (window.JpSlotAdminStudio && window.JpSlotAdminStudio.onOpenAdmin) {
                window.JpSlotAdminStudio.onOpenAdmin(pay);
            }
        } else if (d.type === 'closeAdmin' || d.type === 'adminClosed') {
            var p2 = $('panel-admin');
            if (p2) {
                p2.style.display = 'none';
            }
        } else if (d.type === 'adminLoginResult') {
            /* server push fallback */
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', bind);
    } else {
        bind();
    }
    window.addEventListener('message', onMessage);

    window.JpSlotAdminAuth = {
        token: null,
        showAuth: showAuth,
        logout: logout,
        getToken: function () {
            return state.token;
        },
    };
})();
