// NUI köprüsü: Lua tarafına fetch, oyun dışı (tarayıcı dev modu) tespiti.

export const isEnvBrowser = (): boolean =>
  !(window as unknown as { invokeNative?: unknown }).invokeNative;

const resourceName =
  (window as unknown as { GetParentResourceName?: () => string }).GetParentResourceName?.() ??
  'fd-djkabin';

export async function fetchNui<T = unknown>(event: string, data?: unknown): Promise<T | null> {
  if (isEnvBrowser()) {
    // Tarayıcı dev modunda no-op
    console.log('[fetchNui]', event, data);
    return null;
  }
  try {
    const resp = await fetch(`https://${resourceName}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data ?? {}),
    });
    return (await resp.json()) as T;
  } catch {
    return null;
  }
}

export function sendControl(boothId: string, action: string, data?: unknown): void {
  void fetchNui('control', { boothId, action, data: data ?? {} });
}
