import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { vi } from 'vitest';

import { CLOCK_CONFIG, WEB_SOCKET_FACTORY, WebSocketFactory } from './clock-config';
import { ClockPayload, ClockService } from './clock.service';

class FakeWebSocket {
  readonly url: string;
  readyState: number = WebSocket.CONNECTING;
  onopen: ((event: Event) => void) | null = null;
  onmessage: ((event: MessageEvent) => void) | null = null;
  onerror: ((event: Event) => void) | null = null;
  onclose: ((event: CloseEvent) => void) | null = null;
  readonly close = vi.fn((code?: number, reason?: string) => {
    this.readyState = WebSocket.CLOSED;
    this.onclose?.(new CloseEvent('close', { code, reason }));
  });

  constructor(url: string) {
    this.url = url;
  }

  open(): void {
    this.readyState = WebSocket.OPEN;
    this.onopen?.(new Event('open'));
  }

  message(payload: unknown): void {
    this.onmessage?.(new MessageEvent('message', { data: JSON.stringify(payload) }));
  }

  disconnect(): void {
    this.readyState = WebSocket.CLOSED;
    this.onclose?.(new CloseEvent('close'));
  }
}

describe('ClockService', () => {
  let service: ClockService;
  let http: HttpTestingController;
  let sockets: FakeWebSocket[];

  beforeEach(() => {
    sockets = [];
    const factory: WebSocketFactory = (url) => {
      const socket = new FakeWebSocket(url);
      sockets.push(socket);
      return socket as unknown as WebSocket;
    };

    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        {
          provide: CLOCK_CONFIG,
          useValue: {
            restBaseUrl: 'http://localhost:8080',
            webSocketBaseUrl: 'ws://localhost:8080',
            reconnectDelayMs: 1_000,
          },
        },
        { provide: WEB_SOCKET_FACTORY, useValue: factory },
      ],
    });
    service = TestBed.inject(ClockService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    service.stop();
    http.verify();
    vi.useRealTimers();
  });

  it('loads REST state and applies WebSocket updates', () => {
    const initial: ClockPayload = {
      text: 'Hello World, clock is 2026-08-10T12:34:56Z',
      timestamp: '2026-08-10T12:34:56Z',
    };
    const update: ClockPayload = {
      text: 'Hello World, clock is 2026-08-10T12:34:57Z',
      timestamp: '2026-08-10T12:34:57Z',
    };

    service.start();
    http.expectOne('http://localhost:8080/api/v1/clock').flush(initial);
    expect(service.payload()).toEqual(initial);
    expect(sockets).toHaveLength(1);
    expect(sockets[0].url).toBe('ws://localhost:8080/ws/clock');

    sockets[0].open();
    sockets[0].message(update);
    expect(service.connectionState()).toBe('connected');
    expect(service.payload()).toEqual(update);
    expect(service.error()).toBeNull();
  });

  it('keeps the last valid value when a message is invalid', () => {
    const initial: ClockPayload = {
      text: 'Hello World, clock is 2026-08-10T12:34:56Z',
      timestamp: '2026-08-10T12:34:56Z',
    };
    service.start();
    http.expectOne('http://localhost:8080/api/v1/clock').flush(initial);

    sockets[0].message({ text: 'wrong', timestamp: 'not-a-date' });

    expect(service.payload()).toEqual(initial);
    expect(service.error()).toContain('invalid clock message');
  });

  it('reconnects after a close and cancels work when stopped', () => {
    vi.useFakeTimers();
    service.start();
    http.expectOne('http://localhost:8080/api/v1/clock').flush({
      text: 'Hello World, clock is 2026-08-10T12:34:56Z',
      timestamp: '2026-08-10T12:34:56Z',
    });

    sockets[0].disconnect();
    expect(service.connectionState()).toBe('reconnecting');
    vi.advanceTimersByTime(1_000);
    expect(sockets).toHaveLength(2);

    service.stop();
    sockets[1].disconnect();
    vi.advanceTimersByTime(2_000);
    expect(sockets).toHaveLength(2);
    expect(service.connectionState()).toBe('idle');
  });
});
