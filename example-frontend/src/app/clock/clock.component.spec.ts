import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { vi } from 'vitest';

import { ClockComponent } from './clock.component';
import { ClockConnectionState, ClockPayload, ClockService } from './clock.service';

describe('ClockComponent', () => {
  it('renders HH:mm:ss and cleans up its service', () => {
    const service = {
      payload: signal<ClockPayload | null>({
        text: 'Hello World, clock is 2026-08-10T12:34:56Z',
        timestamp: '2026-08-10T12:34:56Z',
      }),
      connectionState: signal<ClockConnectionState>('connected'),
      error: signal<string | null>(null),
      start: vi.fn(),
      stop: vi.fn(),
    };
    TestBed.configureTestingModule({
      imports: [ClockComponent],
      providers: [{ provide: ClockService, useValue: service }],
    });

    const fixture = TestBed.createComponent(ClockComponent);
    fixture.detectChanges();

    const element = fixture.nativeElement as HTMLElement;
    expect(element.querySelector('[data-testid="clock-value"]')?.textContent?.trim())
      .toMatch(/^\d{2}:\d{2}:\d{2}$/);
    expect(element.querySelector('[data-testid="connection-state"]')?.textContent).toContain('connected');
    expect(service.start).toHaveBeenCalledOnce();

    fixture.destroy();
    expect(service.stop).toHaveBeenCalledOnce();
  });
});
