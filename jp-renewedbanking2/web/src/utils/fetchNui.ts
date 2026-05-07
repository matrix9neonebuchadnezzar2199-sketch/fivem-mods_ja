/**
 * NUI コールバックへ POST する。リソース名は本家 export 互換のため Renewed-Banking 固定（フォルダ名を変えても URL はこの名前）。
 *
 * @param eventName - コールバック名
 * @param data - 送信ペイロード
 */
const RESOURCE_NAME = "Renewed-Banking";

export async function fetchNui<T = unknown>(
  eventName: string,
  data: unknown = {}
): Promise<T> {
  const url = `https://${RESOURCE_NAME}/${eventName}`;
  const options: RequestInit = {
    method: "post",
    headers: {
      "Content-Type": "application/json; charset=UTF-8",
    },
    body: JSON.stringify(data),
  };

  try {
    const resp = await fetch(url, options);
    const text = await resp.text();

    if (!resp.ok) {
      throw new Error(`fetchNui HTTP ${resp.status} ${resp.statusText} (${eventName})`);
    }

    if (text.length === 0) {
      return undefined as unknown as T;
    }

    const contentType = resp.headers.get("content-type") || "";
    if (contentType.includes("application/json")) {
      return JSON.parse(text) as T;
    }

    return text as unknown as T;
  } catch (err) {
    console.error("[fetchNui]", eventName, err);
    throw err;
  }
}
