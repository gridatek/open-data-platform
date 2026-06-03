package com.gridatek.odp.console.health;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Service catalog & health (≈ the Cloudera Manager landing page). */
@RestController
@RequestMapping("/api/services")
public class HealthController {

    private final HealthService healthService;

    public HealthController(HealthService healthService) {
        this.healthService = healthService;
    }

    @GetMapping
    public List<ServiceStatus> services() {
        return healthService.all();
    }
}
