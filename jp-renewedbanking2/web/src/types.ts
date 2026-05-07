/** NUI / Lua から渡る取引 1 件（フィールド不足は将来拡張用に index signature なし） */
export interface Transaction {
    trans_id: string;
    title: string;
    amount: number;
    trans_type: string;
    receiver: string;
    message: string;
    issuer: string;
    time: number;
}

/** 口座エントリ（Lua getBankData の要素に概ね対応） */
export interface Account {
    id: string;
    type: string;
    name: string;
    frozen: boolean;
    amount: number;
    cash?: number;
    transactions: Transaction[];
    auth?: Record<string, boolean>;
    creator?: string | null;
}

export type Translations = Record<string, string>;

export type HelpTopic = "general" | "deposit" | "withdraw" | "transfer" | "create";
