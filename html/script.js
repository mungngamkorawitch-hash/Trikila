(function () {
    'use strict';
    const DOM = {
        container: document.getElementById('trisport-container'),
        raceHud: document.getElementById('race-hud'),
        raceTimer: document.getElementById('race-timer'),
        posCurrent: document.getElementById('position-current'),
        posTotal: document.getElementById('position-total'),
        cpCurrent: document.getElementById('checkpoint-current'),
        cpTotal: document.getElementById('checkpoint-total'),
        progressBar: document.getElementById('progress-bar'),
        boostSection: document.getElementById('boost-section'),
        boostStatus: document.getElementById('boost-status'),
        leaderboardBody: document.getElementById('leaderboard-body'),
        countdownOverlay: document.getElementById('countdown-overlay'),
        countdownNumber: document.getElementById('countdown-number'),
        finishOverlay: document.getElementById('finish-overlay'),
        finishPos: document.getElementById('finish-pos'),
        finishTime: document.getElementById('finish-time'),
        waitingOverlay: document.getElementById('waiting-overlay'),
        waitingRoomId: document.getElementById('waiting-room-id'),
    };
    let countdownTimer = null;
    let lastPosition = null;
    function show(el) {
        if (el) el.classList.remove('hidden');
    }
    function hide(el) {
        if (el) el.classList.add('hidden');
    }
    function setText(el, text) {
        if (el && el.textContent !== String(text)) {
            el.textContent = text;
        }
    }
    function pulse(el) {
        if (!el) return;
        el.classList.remove('pulse');
        void el.offsetWidth;
        el.classList.add('pulse');
    }
    function playSound(name) {
        const audio = document.getElementById('sound-' + name);
        if (audio) {
            audio.currentTime = 0;
            audio.play().catch(function () { });
        }
    }
    const actions = {
        show: function (data) {
            show(DOM.container);
            if (data.state === 'waiting') {
                lastPosition = null;
                show(DOM.waitingOverlay);
                hide(DOM.raceHud);
                hide(DOM.countdownOverlay);
                hide(DOM.finishOverlay);
                setText(DOM.waitingRoomId, data.roomId || '?');
            } else if (data.state === 'racing') {
                hide(DOM.waitingOverlay);
                show(DOM.raceHud);
                hide(DOM.countdownOverlay);
                hide(DOM.finishOverlay);
            }
        },
        hide: function () {
            hide(DOM.container);
            hide(DOM.waitingOverlay);
            hide(DOM.raceHud);
            hide(DOM.countdownOverlay);
            hide(DOM.finishOverlay);
            if (countdownTimer) {
                clearInterval(countdownTimer);
                countdownTimer = null;
            }
        },
        countdown: function (data) {
            show(DOM.container);
            hide(DOM.waitingOverlay);
            show(DOM.countdownOverlay);
            let remaining = data.seconds || 10;
            updateCountdownDisplay(remaining);
            if (countdownTimer) clearInterval(countdownTimer);
            countdownTimer = setInterval(function () {
                remaining--;
                if (remaining > 0) {
                    updateCountdownDisplay(remaining);
                } else if (remaining === 0) {
                    DOM.countdownNumber.textContent = 'GO!';
                    DOM.countdownNumber.className = 'countdown-number countdown-go';
                    void DOM.countdownNumber.offsetWidth;
                    DOM.countdownNumber.style.animation = 'none';
                    void DOM.countdownNumber.offsetWidth;
                    DOM.countdownNumber.style.animation = 'countdown-pop 0.8s ease-out';
                } else {
                    clearInterval(countdownTimer);
                    countdownTimer = null;
                    hide(DOM.countdownOverlay);
                    show(DOM.raceHud);
                }
            }, 1000);
        },
        updatePosition: function (data) {
            if (lastPosition !== null && data.position < lastPosition) {
                actions.showOvertake(data.position);
            }
            lastPosition = data.position;
            setText(DOM.posCurrent, data.position);
            setText(DOM.posTotal, data.total);
            DOM.posCurrent.className = 'position-num';
            if (data.position === 1) DOM.posCurrent.classList.add('pos-1');
            else if (data.position === 2) DOM.posCurrent.classList.add('pos-2');
            else if (data.position === 3) DOM.posCurrent.classList.add('pos-3');
            setText(DOM.cpCurrent, data.checkpoint);
            setText(DOM.cpTotal, data.totalCp);
            var progress = data.totalCp > 0
                ? (data.checkpoint / data.totalCp) * 100
                : 0;
            DOM.progressBar.style.width = progress + '%';
            if (data.raceTime) {
                setText(DOM.raceTimer, data.raceTime);
            }
            if (data.leaderboard) {
                updateLeaderboard(data.leaderboard, data.position);
            }
        },
        updateBoost: function (data) {
            show(DOM.boostSection);
            if (data.active) {
                DOM.boostStatus.textContent = 'ACTIVE!';
                DOM.boostStatus.className = 'boost-active';
            } else if (data.charges > 0) {
                DOM.boostStatus.textContent = 'READY (' + data.charges + '/' + data.max + ')';
                DOM.boostStatus.className = 'boost-ready';
            } else {
                DOM.boostStatus.textContent = 'EMPTY';
                DOM.boostStatus.className = 'boost-empty';
            }
        },
        finished: function (data) {
            show(DOM.container);
            hide(DOM.raceHud);
            show(DOM.finishOverlay);
            setText(DOM.finishPos, data.position);
            setText(DOM.finishTime, data.time);
            setTimeout(function () {
                hide(DOM.finishOverlay);
                hide(DOM.container);
            }, 3000);
        },
        showOvertake: function (newPos) {
            const popup = document.getElementById('overtake-popup');
            if (!popup) return;
            document.getElementById('overtake-new-pos').textContent = newPos;
            popup.classList.remove('hidden');
            popup.classList.remove('overtake-anim');
            void popup.offsetWidth;
            popup.classList.add('overtake-anim');
            if (popup.hideTimeout) clearTimeout(popup.hideTimeout);
            popup.hideTimeout = setTimeout(function () {
                popup.classList.add('hidden');
                popup.classList.remove('overtake-anim');
            }, 1500);
        },
        playSound: function (data) {
            playSound(data.sound);
        },
    };
    function updateLeaderboard(entries, myPosition) {
        var html = '';
        for (var i = 0; i < entries.length; i++) {
            var entry = entries[i];
            var isSelf = (entry.pos === myPosition);
            var posClass = '';
            if (entry.pos === 1) posClass = 'gold';
            else if (entry.pos === 2) posClass = 'silver';
            else if (entry.pos === 3) posClass = 'bronze';
            html += '<div class="lb-row' + (isSelf ? ' is-self' : '') + '">'
                + '<span class="lb-pos ' + posClass + '">' + entry.pos + '</span>'
                + '<span class="lb-name' + (isSelf ? ' is-self-name' : '') + '">'
                + escapeHtml(entry.name) + (isSelf ? ' ★' : '') + '</span>'
                + '<span class="lb-cp">CP' + entry.cp + '</span>'
                + '<span class="lb-time">' + entry.time + '</span>'
                + '</div>';
        }
        DOM.leaderboardBody.innerHTML = html;
    }
    function updateCountdownDisplay(num) {
        DOM.countdownNumber.textContent = num;
        DOM.countdownNumber.className = 'countdown-number';
        void DOM.countdownNumber.offsetWidth;
        DOM.countdownNumber.style.animation = 'none';
        void DOM.countdownNumber.offsetWidth;
        DOM.countdownNumber.style.animation = 'countdown-pop 0.8s ease-out';
    }
    function escapeHtml(text) {
        var div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
    window.addEventListener('message', function (event) {
        var data = event.data;
        if (!data || !data.action) return;
        var handler = actions[data.action];
        if (handler) {
            handler(data);
        }
    });
    fetch(`https://${GetParentResourceName()}/ready`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
    }).catch(function () { });
})();