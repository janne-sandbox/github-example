import { ChangeDetectionStrategy, Component } from '@angular/core';

import { ClockComponent } from './clock/clock.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [ClockComponent],
  template: '<app-clock />',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
