package com.nologo.example.clock;

import java.time.Clock;
import java.time.OffsetDateTime;

import org.springframework.stereotype.Service;

@Service
public class ClockService {

    private final Clock clock;

    public ClockService(Clock clock) {
        this.clock = clock;
    }

    public ClockPayload current() {
        OffsetDateTime timestamp = OffsetDateTime.now(clock);
        return new ClockPayload("Hello World, clock is " + timestamp, timestamp);
    }
}
