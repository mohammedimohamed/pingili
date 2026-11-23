/**
 * Client Device Identity & Soft Fingerprinting
 * Persists client_session_id across localStorage, IndexedDB, and Cookies,
 * and computes a non-sensitive device fingerprint + metadata as a fallback.
 */

const STORAGE_KEY = 'pingili_client_session_id';
const IDB_NAME = 'pingili_identity_db';
const IDB_STORE = 'identity';

export interface DeviceMeta {
  screen: string;
  pixelRatio: number;
  timezone: string;
  language: string;
  platform: string;
  cores: number;
  gpu?: string;
}

function getCookie(name: string): string | null {
  const match = document.cookie.match(new RegExp('(^| )' + name + '=([^;]+)'));
  return match ? decodeURIComponent(match[2]) : null;
}

function setCookie(name: string, value: string, days = 365): void {
  const expires = new Date(Date.now() + days * 864e5).toUTCString();
  document.cookie = `${name}=${encodeURIComponent(value)}; expires=${expires}; path=/; SameSite=Lax`;
}

function readFromIndexedDB(): Promise<string | null> {
  return new Promise((resolve) => {
    if (!('indexedDB' in window)) return resolve(null);
    try {
      const req = indexedDB.open(IDB_NAME, 1);
      req.onupgradeneeded = () => {
        if (!req.result.objectStoreNames.contains(IDB_STORE)) {
          req.result.createObjectStore(IDB_STORE);
        }
      };
      req.onsuccess = () => {
        try {
          const tx = req.result.transaction(IDB_STORE, 'readonly');
          const getReq = tx.objectStore(IDB_STORE).get(STORAGE_KEY);
          getReq.onsuccess = () => resolve((getReq.result as string) || null);
          getReq.onerror = () => resolve(null);
        } catch {
          resolve(null);
        }
      };
      req.onerror = () => resolve(null);
    } catch {
      resolve(null);
    }
  });
}

function writeToIndexedDB(value: string): void {
  if (!('indexedDB' in window)) return;
  try {
    const req = indexedDB.open(IDB_NAME, 1);
    req.onupgradeneeded = () => {
      if (!req.result.objectStoreNames.contains(IDB_STORE)) {
        req.result.createObjectStore(IDB_STORE);
      }
    };
    req.onsuccess = () => {
      try {
        const tx = req.result.transaction(IDB_STORE, 'readwrite');
        tx.objectStore(IDB_STORE).put(value, STORAGE_KEY);
      } catch {
        // ignore
      }
    };
  } catch {
    // ignore
  }
}

/**
 * Multi-storage session ID: checks localStorage, Cookie, and IndexedDB,
 * restoring across all three if any one survives.
 */
export async function getOrRestoreClientSessionId(): Promise<string> {
  let id = localStorage.getItem(STORAGE_KEY) || getCookie(STORAGE_KEY);

  if (!id) {
    id = await readFromIndexedDB();
  }

  if (!id) {
    id = 'client_' + Math.random().toString(36).substring(2, 11) + Date.now().toString(36).slice(-4);
  }

  // Sync to all 3 storage layers
  try {
    localStorage.setItem(STORAGE_KEY, id);
  } catch {
    // ignore
  }
  setCookie(STORAGE_KEY, id);
  writeToIndexedDB(id);

  return id;
}

function getWebGLRenderer(): string | undefined {
  try {
    const canvas = document.createElement('canvas');
    const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
    if (!gl) return undefined;
    const debugInfo = (gl as WebGLRenderingContext).getExtension('WEBGL_debug_renderer_info');
    if (!debugInfo) return undefined;
    return (gl as WebGLRenderingContext).getParameter(debugInfo.UNMASKED_RENDERER_WEBGL) as string;
  } catch {
    return undefined;
  }
}

export function getDeviceMeta(): DeviceMeta {
  return {
    screen: `${window.screen.width}x${window.screen.height}`,
    pixelRatio: window.devicePixelRatio || 1,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || 'unknown',
    language: navigator.language || 'en',
    platform: navigator.platform || 'unknown',
    cores: navigator.hardwareConcurrency || 0,
    gpu: getWebGLRenderer(),
  };
}

export async function getDeviceFingerprint(): Promise<{ fingerprint: string; meta: DeviceMeta }> {
  const meta = getDeviceMeta();
  const raw = JSON.stringify(meta);

  if (window.crypto?.subtle) {
    const buf = await window.crypto.subtle.digest('SHA-256', new TextEncoder().encode(raw));
    const hash = Array.from(new Uint8Array(buf))
      .map((b) => b.toString(16).padStart(2, '0'))
      .join('')
      .slice(0, 24);
    return { fingerprint: `fp_${hash}`, meta };
  }

  // Simple fallback hash
  let h = 0;
  for (let i = 0; i < raw.length; i++) {
    h = (Math.imul(31, h) + raw.charCodeAt(i)) | 0;
  }
  return { fingerprint: `fp_${Math.abs(h).toString(16)}`, meta };
}
