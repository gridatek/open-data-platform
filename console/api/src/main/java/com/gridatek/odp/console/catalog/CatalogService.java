package com.gridatek.odp.console.catalog;

import com.fasterxml.jackson.databind.JsonNode;
import com.gridatek.odp.console.config.ConsoleProperties;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.ArrayList;
import java.util.List;

/** Read-only browse of the shared Iceberg REST catalog. */
@Service
public class CatalogService {

    private final RestClient http;
    private final String restUrl;

    public CatalogService(RestClient http, ConsoleProperties props) {
        this.http = http;
        this.restUrl = props.catalog().restUrl();
    }

    /** Namespaces, each rendered as a dotted path (e.g. {@code smoke}, {@code a.b}). */
    public List<String> namespaces() {
        JsonNode root = http.get().uri(restUrl + "/v1/namespaces").retrieve().body(JsonNode.class);
        List<String> out = new ArrayList<>();
        if (root != null && root.has("namespaces")) {
            for (JsonNode ns : root.get("namespaces")) {
                List<String> levels = new ArrayList<>();
                ns.forEach(level -> levels.add(level.asText()));
                out.add(String.join(".", levels));
            }
        }
        return out;
    }

    /** Table names within a namespace. */
    public List<String> tables(String namespace) {
        JsonNode root = http.get()
                .uri(restUrl + "/v1/namespaces/{ns}/tables", namespace)
                .retrieve()
                .body(JsonNode.class);
        List<String> out = new ArrayList<>();
        if (root != null && root.has("identifiers")) {
            for (JsonNode id : root.get("identifiers")) {
                out.add(id.path("name").asText());
            }
        }
        return out;
    }
}
