import { InjectionToken } from '@angular/core';

export interface ClockRuntimeConfig {
  readonly restBaseUrl: string;
  readonly webSocketBaseUrl: string;
  readonly reconnectDelayMs: number;
}

interface ClockConfigOverride {
  readonly restBaseUrl?: string;
  readonly webSocketBaseUrl?: string;
  readonly reconnectDelayMs?: number;
}

declare global {
  interface Window {
    __CLOCK_CONFIG__?: ClockConfigOverride;
  }
}

function defaultBackendOrigin(): string {
  if (globalThis.location.port === '4200') {
    return `${globalThis.location.protocol}//${globalThis.location.hostname}:8080`;
  }
  return globalThis.location.origin;
}

function createClockConfig(): ClockRuntimeConfig {
  const override = globalThis.window.__CLOCK_CONFIG__ ?? {};
  const restBaseUrl = override.restBaseUrl ?? defaultBackendOrigin();
  const defaultWebSocketBaseUrl = restBaseUrl.replace(/^http/, 'ws');
  const reconnectDelayMs = Math.max(250, Math.min(10_000, override.reconnectDelayMs ?? 1_000));

  return {
    restBaseUrl: restBaseUrl.replace(/\/$/, ''),
    webSocketBaseUrl: (override.webSocketBaseUrl ?? defaultWebSocketBaseUrl).replace(/\/$/, ''),
    reconnectDelayMs,
  };
}

export const CLOCK_CONFIG = new InjectionToken<ClockRuntimeConfig>('CLOCK_CONFIG', {
  providedIn: 'root',
  factory: createClockConfig,
});

export type WebSocketFactory = (url: string) => WebSocket;

export const WEB_SOCKET_FACTORY = new InjectionToken<WebSocketFactory>('WEB_SOCKET_FACTORY', {
  providedIn: 'root',
  factory: () => (url: string) => new WebSocket(url),
});
