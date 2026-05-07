import { isEnvBrowser } from "./misc";

/**
 * ブラウザ単体開発時に `SendNUIMessage` と同じ **フラット** な `event.data` を再現する。
 * 本番 Lua は `action` と口座・状態などを同一オブジェクトに載せるため、`useNuiEvent` は
 * `handler(event.data)` で参照する（`event.data.data` のネストは使わない）。
 */
export type NuiDebugMessage = { action: string; [key: string]: unknown };

/**
 * @param events - 各要素がそのまま `MessageEvent.data` になる
 * @param timer - 先頭イベントまでの遅延（ms）。複数件時は 50ms ずつずらして順に発火
 */
export const debugData = (events: NuiDebugMessage[], timer = 1000): void => {
  if (isEnvBrowser()) {
    events.forEach((event, index) => {
      setTimeout(() => {
        window.dispatchEvent(
          new MessageEvent("message", {
            data: event,
          })
        );
      }, timer + index * 50);
    });
  }
};
