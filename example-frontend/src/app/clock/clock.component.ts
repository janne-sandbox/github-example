import { ChangeDetectionStrategy, Component, computed, inject, OnDestroy, OnInit } from '@angular/core';

import { ClockService } from './clock.service';

@Component({
  selector: 'app-clock',
  standalone: true,
  templateUrl: './clock.component.html',
  styleUrl: './clock.component.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ClockComponent implements OnInit, OnDestroy {
  protected readonly clock = inject(ClockService);
  protected readonly formattedTime = computed(() => {
    const timestamp = this.clock.payload()?.timestamp;
    if (!timestamp) {
      return '--:--:--';
    }
    return new Intl.DateTimeFormat('en-GB', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false,
    }).format(new Date(timestamp));
  });

  ngOnInit(): void {
    this.clock.start();
  }

  ngOnDestroy(): void {
    this.clock.stop();
  }
}
