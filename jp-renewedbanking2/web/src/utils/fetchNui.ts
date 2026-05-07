/**
 * NUI コールバックへ POST する。
 * ゲーム内では FiveM の GetParentResourceName()（実フォルダ名＝ensure 名）を使う。
 * ブラウザ単体デバッグ時のみ Renewed-Banking にフォールバック。
 */
const RESOURCE_NAME_FALLBACK = "Renewed-Banking";

function nuiResourceName(): string {
  if (typeof window !== "undefined" && window.GetParentResourceName) {
    return window.GetParentResourceName();
  }
  return RESOURCE_NAME_FALLBACK;
}

export async function fetchNui<T = unknown>(
  eventName: string,
  data: unknown = {}
): Promise<T> {
  const url = `https://${nuiResourceName()}/${eventName}`;
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
