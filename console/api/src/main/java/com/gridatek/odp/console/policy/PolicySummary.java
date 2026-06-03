package com.gridatek.odp.console.policy;

/** A Ranger policy as the console surfaces it. */
public record PolicySummary(String name, String type, boolean enabled) {}
