import { currency } from "../store/stores";

export const isEnvBrowser = (): boolean => !(window as any).invokeNative;

let activeCurrency: string = "USD";

currency.subscribe((value: string) => {
    activeCurrency = value || "USD";
});

export function formatMoney(number: number | null | undefined) {
    const n =
        number == null || Number.isNaN(Number(number)) ? 0 : Number(number);
    const code = activeCurrency || "USD";
    return n.toLocaleString("en-US", { style: "currency", currency: code });
}