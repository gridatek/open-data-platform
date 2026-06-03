package com.gridatek.odp.console.policy;

import com.fasterxml.jackson.databind.JsonNode;
import com.gridatek.odp.console.config.ConsoleProperties;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.ArrayList;
import java.util.List;

/** Read-only view of the Ranger policies governing the Trino service. */
@Service
public class PolicyService {

    private final RestClient http;
    private final ConsoleProperties.Ranger ranger;

    public PolicyService(RestClient http, ConsoleProperties props) {
        this.http = http;
        this.ranger = props.ranger();
    }

    public List<PolicySummary> policies() {
        JsonNode arr = http.get()
                .uri(ranger.url() + "/service/public/v2/api/service/{svc}/policy", ranger.serviceName())
                .headers(h -> h.setBasicAuth(ranger.username(), ranger.password()))
                .retrieve()
                .body(JsonNode.class);

        List<PolicySummary> out = new ArrayList<>();
        if (arr != null && arr.isArray()) {
            for (JsonNode p : arr) {
                out.add(new PolicySummary(
                        p.path("name").asText(),
                        typeName(p.path("policyType").asInt(0)),
                        p.path("isEnabled").asBoolean(true)));
            }
        }
        return out;
    }

    private static String typeName(int policyType) {
        return switch (policyType) {
            case 1 -> "MASKING";
            case 2 -> "ROW_FILTER";
            default -> "ACCESS";
        };
    }
}
