/**
 * FiveM NUI 通信（方式B: 結果は message イベント）
 * グローバル window.NUI（スクリプト読込順のため export なし）
 */
(function (global) {
  const RESOURCE_NAME =
    typeof global.GetParentResourceName === 'function'
      ? global.GetParentResourceName()
      : 'jp-tcgbook';

  const IS_FIVEM =
    typeof global.GetParentResourceName === 'function' ||
    (typeof navigator !== 'undefined' &&
      String(navigator.userAgent || '').includes('CitizenFX'));

  /** @type {Map<string, Function[]>} */
  const listeners = new Map();

  /** F8 コンソールはオブジェクトを [object Object] に潰すため、wire 用に JSON 化する */
  const WIRE_JSON_MAX = 2400;

  /**
   * @param {unknown} x
   * @returns {string}
   */
  function tcgWireJson(x) {
    if (x === null || x === undefined) return String(x);
    if (typeof x !== 'object') return String(x);
    try {
      let s = JSON.stringify(x);
      if (s.length > WIRE_JSON_MAX) s = s.slice(0, WIRE_JSON_MAX) + '…';
      return s;
    } catch (_e) {
      return '[unserializable]';
    }
  }

  function dispatch(action, payload) {
    if (global.__tcgWireLog && typeof action === 'string') {
      const a = action;
      if (
        a === 'battleWaitingAck' ||
        a === 'battleLobbyError' ||
        a === 'virtualBattleMatched' ||
        a === 'virtualBattleEnded' ||
        a === 'battleDebugState' ||
        a === 'battleDebugLookupAck' ||
        a === 'battleDebugEnded' ||
        a === 'battlePvpState' ||
        a === 'battlePvpEnded'
      ) {
        console.log('[jp-tcgbook][wire] NUI message <- ' + a + ' ' + tcgWireJson(payload));
      }
    }
    const cbs = listeners.get(action);
    if (!cbs || !cbs.length) return;
    cbs.forEach((cb) => {
      try {
        cb(payload);
      } catch (e) {
        console.error('[jp-tcgbook NUI]', action, e);
      }
    });
  }

  global.addEventListener('message', (event) => {
    const msg = event.data;
    if (!msg || typeof msg !== 'object') return;
    const payload =
      msg.payload !== undefined ? msg.payload : msg.data !== undefined ? msg.data : msg;
    dispatch(msg.action, payload);
  });

  global.NUI = {
    RESOURCE_NAME,
    IS_FIVEM,

    /**
     * @param {string} action
     * @param {(payload: unknown) => void} callback
     */
    on(action, callback) {
      if (!listeners.has(action)) listeners.set(action, []);
      listeners.get(action).push(callback);
    },

    /**
     * NUI コールバック名を FiveM に POST
     * @param {string} eventName
     * @param {Record<string, unknown>} data
     */
    send(eventName, data) {
      const body = data || {};
      if (global.__tcgWireLog && typeof eventName === 'string' && eventName.startsWith('battle')) {
        console.log(
          '[jp-tcgbook][wire] NUI fetch -> ' + eventName + ' ' + tcgWireJson(body),
        );
      }
      if (IS_FIVEM) {
        fetch(`https://${RESOURCE_NAME}/${eventName}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json; charset=UTF-8' },
          body: JSON.stringify(body),
        }).catch(() => {});
      } else if (typeof global.mockDispatchServerEvent === 'function') {
        global.mockDispatchServerEvent(eventName, body);
      }
    },
  };
})(window);
