package com.nologo.example.clock;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Clock;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;

import org.junit.jupiter.api.Test;

class ClockServiceTest {

    @Test
    void createsExpectedPayloadFromClock() {
        Clock clock = Clock.fixed(Instant.parse("2026-08-10T12:34:56Z"), ZoneOffset.UTC);

        ClockPayload payload = new ClockService(clock).current();

        assertThat(payload.timestamp()).isEqualTo(OffsetDateTime.parse("2026-08-10T12:34:56Z"));
        assertThat(payload.text()).isEqualTo("Hello World, clock is 2026-08-10T12:34:56Z");
    }
}
