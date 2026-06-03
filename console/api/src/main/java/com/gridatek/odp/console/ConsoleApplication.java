package com.gridatek.odp.console;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

/** Read-only control plane for the Open Data Platform (≈ Cloudera Manager). */
@SpringBootApplication
@ConfigurationPropertiesScan
public class ConsoleApplication {
    public static void main(String[] args) {
        SpringApplication.run(ConsoleApplication.class, args);
    }
}
