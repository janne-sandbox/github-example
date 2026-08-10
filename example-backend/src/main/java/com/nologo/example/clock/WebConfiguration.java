package com.nologo.example.clock;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
public class WebConfiguration implements WebSocketConfigurer, WebMvcConfigurer {

    private final ClockWebSocketHandler clockHandler;
    private final String frontendOrigin;

    public WebConfiguration(
            ClockWebSocketHandler clockHandler,
            @Value("${example.frontend-origin:http://localhost:4200}") String frontendOrigin) {
        this.clockHandler = clockHandler;
        this.frontendOrigin = frontendOrigin;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(clockHandler, "/ws/clock").setAllowedOrigins(frontendOrigin);
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**").allowedOrigins(frontendOrigin).allowedMethods("GET");
    }
}
