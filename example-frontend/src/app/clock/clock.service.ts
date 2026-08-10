import { HttpClient } from '@angular/common/http';
import { inject, Injectable, signal } from '@angular/core';
import { finalize } from 'rxjs';

import { CLOCK_CONFIG, WEB_SOCKET_FACTORY } from './clock-config';

export interface ClockPayload {
  readonly text: string;
  readonly timestamp: string;
}

export type ClockConnectionState = 'idle' | 'loading' | 'connecting' | 'connected' | 'reconnecting';

@Injectable({ providedIn: 'root' })
export class ClockService {
  private readonly http = inject(HttpClient);
  private readonly config = inject(CLOCK_CONFIG);
  private readonly webSocketFactory = inject(WEB_SOCKET_FACTORY);

  private socket: WebSocket | null = null;
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private stopped = true;
  private started = false;

  readonly payload = signal<ClockPayload | null>(null);
  readonly connectionState = signal<ClockConnectionState>('idle');
  readonly error = signal<string | null>(null);

  start(): void {
    if (this.started) {
      return;
    }

    this.started = true;
    this.stopped = false;
    this.connectionState.set('loading');

    this.http
      .get<ClockPayload>(`${this.config.restBaseUrl}/api/v1/clock`)
      .pipe(finalize(() => this.connect()))
      .subscribe({
        next: (payload) => this.applyPayload(payload),
        error: () => this.error.set('Initial clock request failed; waiting for WebSocket updates.'),
      });
  }

  stop(): void {
    this.stopped = true;
    this.started = false;
    if (this.reconnectTimer !== null) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }

    const socket = this.socket;
    this.socket = null;
    if (socket && socket.readyState < WebSocket.CLOSING) {
      socket.close(1000, 'Component destroyed');
    }
    this.connectionState.set('idle');
  }

  private connect(): void {
    if (this.stopped) {
      return;
    }

    this.connectionState.set(this.socket ? 'reconnecting' : 'connecting');
    const socket = this.webSocketFactory(`${this.config.webSocketBaseUrl}/ws/clock`);
    this.socket = socket;

    socket.onopen = () => this.connectionState.set('connected');
    socket.onmessage = (event) => this.receiveMessage(event.data);
    socket.onerror = () => this.error.set('WebSocket connection error; reconnecting.');
    socket.onclose = () => {
      if (this.socket === socket) {
        this.socket = null;
      }
      if (!this.stopped) {
        this.scheduleReconnect();
      }
    };
  }

  private receiveMessage(data: unknown): void {
    try {
      const parsed = JSON.parse(String(data)) as unknown;
      if (!this.isClockPayload(parsed)) {
        throw new Error('Invalid payload');
      }
      this.applyPayload(parsed);
    } catch {
      this.error.set('Received an invalid clock message; showing the last valid value.');
    }
  }

  private applyPayload(payload: ClockPayload): void {
    if (!this.isClockPayload(payload)) {
      this.error.set('Received an invalid clock payload; showing the last valid value.');
      return;
    }
    this.payload.set(payload);
    this.error.set(null);
  }

  private isClockPayload(value: unknown): value is ClockPayload {
    if (typeof value !== 'object' || value === null) {
      return false;
    }
    const candidate = value as Partial<ClockPayload>;
    return typeof candidate.text === 'string'
      && candidate.text.startsWith('Hello World, clock is ')
      && typeof candidate.timestamp === 'string'
      && !Number.isNaN(Date.parse(candidate.timestamp));
  }

  private scheduleReconnect(): void {
    if (this.reconnectTimer !== null) {
      return;
    }
    this.connectionState.set('reconnecting');
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      this.connect();
    }, this.config.reconnectDelayMs);
  }
}
