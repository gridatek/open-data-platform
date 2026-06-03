package com.gridatek.odp.console.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.List;

/** Where the console finds the platform's backing services. Bound from {@code odp.*}. */
@ConfigurationProperties(prefix = "odp")
public record ConsoleProperties(
        List<ServiceEndpoint> services,
        Catalog catalog,
        Ranger ranger
) {
    /** A data service the console probes for health. */
    public record ServiceEndpoint(String name, String health) {}

    /** Iceberg REST catalog the console browses. */
    public record Catalog(String restUrl) {}

    /** Ranger admin whose policies the console reads. */
    public record Ranger(String url, String serviceName, String username, String password) {}
}
