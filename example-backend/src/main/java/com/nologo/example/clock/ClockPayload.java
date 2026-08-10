package com.nologo.example.clock;

import java.time.OffsetDateTime;

public record ClockPayload(String text, OffsetDateTime timestamp) {
}
