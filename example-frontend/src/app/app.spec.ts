import { provideHttpClient } from '@angular/common/http';
import { TestBed } from '@angular/core/testing';

import { App } from './app';

describe('App', () => {
  it('creates the application shell', () => {
    TestBed.configureTestingModule({ providers: [provideHttpClient()] });
    const fixture = TestBed.createComponent(App);
    expect(fixture.componentInstance).toBeTruthy();
  });
});
