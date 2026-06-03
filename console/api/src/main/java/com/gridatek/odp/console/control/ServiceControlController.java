package com.gridatek.odp.console.control;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

/**
 * Service lifecycle (provision / scale / restart) — the K8s side of the Phase 4
 * control plane. The laptop subset has no Kubernetes, so these actions are not
 * implemented here; they return 501 with an explanation. Wiring the fabric8/
 * official K8s client (apply Helm release or scale a Deployment) is Phase 4b.
 */
@RestController
@RequestMapping("/api/services")
public class ServiceControlController {

    @PostMapping("/{name}/restart")
    public void restart(@PathVariable String name) {
        throw new ResponseStatusException(
                HttpStatus.NOT_IMPLEMENTED,
                "Service lifecycle for '" + name + "' requires the Kubernetes/Helm integration, "
                        + "not available in the laptop subset (Phase 4b).");
    }

    @PostMapping("/{name}/scale")
    public void scale(@PathVariable String name) {
        throw new ResponseStatusException(
                HttpStatus.NOT_IMPLEMENTED,
                "Scaling '" + name + "' requires the Kubernetes API (Phase 4b).");
    }
}
