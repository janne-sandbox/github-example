package com.nologo.example.clock;

import java.io.IOException;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Component
public class ClockWebSocketHandler extends TextWebSocketHandler {

    private static final Logger LOGGER = LoggerFactory.getLogger(ClockWebSocketHandler.class);

    private static final long MINIMUM_SEND_SPACING_NANOS = Duration.ofMillis(750).toNanos();

    private final Map<WebSocketSession, Long> sessions = new ConcurrentHashMap<>();
    private final ClockService clockService;
    private final ObjectMapper objectMapper;

    public ClockWebSocketHandler(ClockService clockService, ObjectMapper objectMapper) {
        this.clockService = clockService;
        this.objectMapper = objectMapper;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws IOException {
        sessions.put(session, 0L);
        send(session, serialize(clockService.current()));
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        sessions.remove(session);
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) {
        sessions.remove(session);
        LOGGER.debug("Removing failed WebSocket session {}", session.getId(), exception);
        closeQuietly(session);
    }

    @Scheduled(fixedRateString = "${example.clock.broadcast-interval:1s}")
    void broadcastCurrent() {
        if (sessions.isEmpty()) {
            return;
        }

        String payload;
        try {
            payload = serialize(clockService.current());
        } catch (JsonProcessingException exception) {
            LOGGER.error("Unable to serialize clock payload", exception);
            return;
        }

        for (WebSocketSession session : sessions.keySet()) {
            try {
                if (session.isOpen()) {
                    sendIfReady(session, payload);
                } else {
                    if (!session.isOpen()) {
                        sessions.remove(session);
                    }
                }
            } catch (IOException exception) {
                sessions.remove(session);
                LOGGER.debug("Unable to send clock update to session {}", session.getId(), exception);
                closeQuietly(session);
            }
        }
    }

    String serialize(ClockPayload payload) throws JsonProcessingException {
        return objectMapper.writeValueAsString(payload);
    }

    private void send(WebSocketSession session, String payload) throws IOException {
        synchronized (session) {
            session.sendMessage(new TextMessage(payload));
            sessions.put(session, System.nanoTime());
        }
    }

    private void sendIfReady(WebSocketSession session, String payload) throws IOException {
        synchronized (session) {
            long lastSent = sessions.getOrDefault(session, 0L);
            if (System.nanoTime() - lastSent >= MINIMUM_SEND_SPACING_NANOS) {
                session.sendMessage(new TextMessage(payload));
                sessions.put(session, System.nanoTime());
            }
        }
    }

    private void closeQuietly(WebSocketSession session) {
        try {
            session.close(CloseStatus.SERVER_ERROR);
        } catch (IOException closeException) {
            LOGGER.debug("Unable to close failed WebSocket session {}", session.getId(), closeException);
        }
    }
}
