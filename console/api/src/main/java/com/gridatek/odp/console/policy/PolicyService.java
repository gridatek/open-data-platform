package com.gridatek.odp.console.policy;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.gridatek.odp.console.config.ConsoleProperties;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

/**
 * View <em>and edit</em> the Ranger policies governing the Trino service.
 * Phase 4: the console is now a write-capable control plane for governance.
 */
@Service
public class PolicyService {

    private final RestClient http;
    private final ConsoleProperties.Ranger ranger;

    public PolicyService(RestClient http, ConsoleProperties props) {
        this.http = http;
        this.ranger = props.ranger();
    }

    private Consumer<HttpHeaders> auth() {
        return h -> h.setBasicAuth(ranger.username(), ranger.password());
    }

    public List<PolicySummary> policies() {
        JsonNode arr = http.get()
                .uri(ranger.url() + "/service/public/v2/api/service/{svc}/policy", ranger.serviceName())
                .headers(auth())
                .retrieve()
                .body(JsonNode.class);

        List<PolicySummary> out = new ArrayList<>();
        if (arr != null && arr.isArray()) {
            for (JsonNode p : arr) {
                out.add(toSummary(p));
            }
        }
        return out;
    }

    /** Create a new policy from a raw Ranger policy document. */
    public PolicySummary create(JsonNode policy) {
        JsonNode created = http.post()
                .uri(ranger.url() + "/service/public/v2/api/policy")
                .headers(auth())
                .contentType(MediaType.APPLICATION_JSON)
                .body(policy)
                .retrieve()
                .body(JsonNode.class);
        return toSummary(created);
    }

    /** Replace an existing policy by id. */
    public PolicySummary update(int id, JsonNode policy) {
        JsonNode updated = http.put()
                .uri(ranger.url() + "/service/public/v2/api/policy/{id}", id)
                .headers(auth())
                .contentType(MediaType.APPLICATION_JSON)
                .body(policy)
                .retrieve()
                .body(JsonNode.class);
        return toSummary(updated);
    }

    /** Enable/disable a policy — fetch it, flip {@code isEnabled}, put it back. */
    public PolicySummary setEnabled(int id, boolean enabled) {
        JsonNode policy = http.get()
                .uri(ranger.url() + "/service/public/v2/api/policy/{id}", id)
                .headers(auth())
                .retrieve()
                .body(JsonNode.class);
        if (policy instanceof ObjectNode obj) {
            obj.put("isEnabled", enabled);
        }
        return update(id, policy);
    }

    private PolicySummary toSummary(JsonNode p) {
        return new PolicySummary(
                p.path("id").asInt(),
                p.path("name").asText(),
                typeName(p.path("policyType").asInt(0)),
                p.path("isEnabled").asBoolean(true));
    }

    private static String typeName(int policyType) {
        return switch (policyType) {
            case 1 -> "MASKING";
            case 2 -> "ROW_FILTER";
            default -> "ACCESS";
        };
    }
}
