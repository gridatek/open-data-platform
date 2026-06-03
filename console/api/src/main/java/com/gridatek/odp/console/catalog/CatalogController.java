package com.gridatek.odp.console.catalog;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Data catalog browser — Iceberg namespaces and tables via the REST catalog. */
@RestController
@RequestMapping("/api/catalog")
public class CatalogController {

    private final CatalogService catalogService;

    public CatalogController(CatalogService catalogService) {
        this.catalogService = catalogService;
    }

    @GetMapping("/namespaces")
    public List<String> namespaces() {
        return catalogService.namespaces();
    }

    @GetMapping("/namespaces/{namespace}/tables")
    public List<String> tables(@PathVariable String namespace) {
        return catalogService.tables(namespace);
    }
}
