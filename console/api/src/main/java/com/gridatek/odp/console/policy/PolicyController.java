package com.gridatek.odp.console.policy;

import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Governance panel — view and edit the Ranger policies on the Trino service. */
@RestController
@RequestMapping("/api/policies")
public class PolicyController {

    private final PolicyService policyService;

    public PolicyController(PolicyService policyService) {
        this.policyService = policyService;
    }

    @GetMapping
    public List<PolicySummary> policies() {
        return policyService.policies();
    }

    @PostMapping
    public PolicySummary create(@RequestBody JsonNode policy) {
        return policyService.create(policy);
    }

    @PutMapping("/{id}")
    public PolicySummary update(@PathVariable int id, @RequestBody JsonNode policy) {
        return policyService.update(id, policy);
    }

    /** Enable/disable a policy — the headline Phase 4 control-plane action. */
    @PostMapping("/{id}/enabled")
    public PolicySummary setEnabled(@PathVariable int id, @RequestBody EnabledRequest request) {
        return policyService.setEnabled(id, request.enabled());
    }

    public record EnabledRequest(boolean enabled) {}
}
