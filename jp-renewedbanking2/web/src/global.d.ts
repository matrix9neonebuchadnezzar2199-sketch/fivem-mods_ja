/// <reference types="svelte" />

interface Window {
    invokeNative?: (name: string, ...args: unknown[]) => void;
    GetParentResourceName?: () => string;
}
