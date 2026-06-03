package com.gridatek.odp.console.health;

/** Health of one data service as seen by the console. */
public record ServiceStatus(String name, String status, String detail) {
    public static final String UP = "UP";
    public static final String DOWN = "DOWN";
}
