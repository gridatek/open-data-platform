package com.gridatek.odp.console.control;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.Optional;

/**
 * Service lifecycle (restart / scale) — the Kubernetes side of the Phase 4
 * control plane. When Kubernetes access is enabled ({@code odp.k8s.enabled=true})
 * the actions run against the cluster; otherwise (the docker-compose laptop
 * subset) there is no {@link ServiceControlService} bean and they return 501.
 */
@RestController
@RequestMapping("/api/services")
public class ServiceControlController {

    private final Optional<ServiceControlService> control;

    public ServiceControlController(Optional<ServiceControlService> control) {
        this.control = control;
    }

    @PostMapping("/{name}/restart")
    public ResponseEntity<Void> restart(@PathVariable String name) {
        service("Restarting", name).restart(name);
        return ResponseEntity.accepted().build();
    }

    @PostMapping("/{name}/scale")
    public ResponseEntity<Void> scale(@PathVariable String name, @RequestBody ScaleRequest request) {
        service("Scaling", name).scale(name, request.replicas());
        return ResponseEntity.accepted().build();
    }

    private ServiceControlService service(String action, String name) {
        return control.orElseThrow(() -> new ResponseStatusException(
                HttpStatus.NOT_IMPLEMENTED,
                action + " '" + name + "' requires the Kubernetes integration "
                        + "(set odp.k8s.enabled=true), not available in the laptop subset."));
    }

    public record ScaleRequest(int replicas) {}
}
