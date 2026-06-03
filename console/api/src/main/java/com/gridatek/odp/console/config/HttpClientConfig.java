package com.gridatek.odp.console.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

import java.time.Duration;

/** Shared outbound HTTP client. Short timeouts — health probes must fail fast. */
@Configuration
public class HttpClientConfig {

    @Bean
    RestClient restClient(RestClient.Builder builder) {
        var factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(2));
        factory.setReadTimeout(Duration.ofSeconds(4));
        return builder.requestFactory(factory).build();
    }
}
