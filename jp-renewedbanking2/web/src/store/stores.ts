/**
 * Renewed-Banking NUI 用ストア（jp-renewedbanking2: showHelp を追加）
 * 原作: Renewed-Banking — CC BY-NC-SA 4.0
 */
import { writable } from "svelte/store";

/** ヘルプモーダル: null で非表示。トピック名は HelpModal / locales の _help_* と対応 */
export const showHelp = writable<null | "general" | "deposit" | "withdraw" | "transfer" | "create">(null);

export const visibility = writable(false);
export const loading = writable(false);
export const notify = writable("");
export let activeAccount = writable(null);
export const atm = writable(false);
export const currency = writable("USD");

export let popupDetails = writable({
    account: {},
    actionType: "",
});

export const accounts = writable<any>([

]);

export const translations = writable<any>();
