/**
 * Renewed-Banking NUI 用ストア（jp-renewedbanking2: showHelp を追加）
 * 原作: Renewed-Banking — CC BY-NC-SA 4.0
 */
import { writable } from "svelte/store";
import type { Account, HelpTopic, Translations } from "../types";

/** ヘルプモーダル: null で非表示。トピック名は HelpModal / locales の _help_* と対応 */
export const showHelp = writable<HelpTopic | null>(null);

export const visibility = writable(false);
export const loading = writable(false);
export const notify = writable("");
export const activeAccount = writable<string | null>(null);
export const atm = writable(false);
export const currency = writable("USD");

export const popupDetails = writable({
    account: {} as Partial<Account>,
    actionType: "",
});

export const accounts = writable<Account[]>([]);

export const translations = writable<Translations>({});
