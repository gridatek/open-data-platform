package com.gridatek.odp.console.health;

import com.gridatek.odp.console.config.ConsoleProperties;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.List;

/**
 * Probes each configured service's health endpoint. In the laptop subset there is
 * no K8s API, so "is the service up?" is a fast HTTP GET against its health URL.
 */
@Service
public class HealthService {

    private final RestClient http;
    private final ConsoleProperties props;

    public HealthService(RestClient http, ConsoleProperties props) {
        this.http = http;
        this.props = props;
    }

    public List<ServiceStatus> all() {
        var services = props.services() == null ? List.<ConsoleProperties.ServiceEndpoint>of() : props.services();
        return services.stream().map(this::probe).toList();
    }

    private ServiceStatus probe(ConsoleProperties.ServiceEndpoint endpoint) {
        try {
            var response = http.get().uri(endpoint.health()).retrieve().toBodilessEntity();
            boolean up = response.getStatusCode().is2xxSuccessful();
            return new ServiceStatus(
                    endpoint.name(),
                    up ? ServiceStatus.UP : ServiceStatus.DOWN,
                    "HTTP " + response.getStatusCode().value());
        } catch (Exception ex) {
            return new ServiceStatus(endpoint.name(), ServiceStatus.DOWN, ex.getClass().getSimpleName());
        }
    }
}
