package com.nologo.example.clock;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import org.junit.jupiter.api.Test;

class ClockWebSocketHandlerTest {

    @Test
    void serializesClockPayloadForWebSocketClients() throws Exception {
        Clock clock = Clock.fixed(Instant.parse("2026-08-10T12:34:56Z"), ZoneOffset.UTC);
        ClockService service = new ClockService(clock);
        ObjectMapper objectMapper = new ObjectMapper()
                .findAndRegisterModules()
                .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        ClockWebSocketHandler handler = new ClockWebSocketHandler(service, objectMapper);

        String json = handler.serialize(service.current());

        assertThat(json).contains("\"text\":\"Hello World, clock is 2026-08-10T12:34:56Z\"");
        assertThat(json).contains("\"timestamp\":\"2026-08-10T12:34:56Z\"");
    }
}
