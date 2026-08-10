package com.nologo.example.clock;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/clock")
public class ClockRestController {

    private final ClockService clockService;

    public ClockRestController(ClockService clockService) {
        this.clockService = clockService;
    }

    @GetMapping
    ClockPayload current() {
        return clockService.current();
    }
}
