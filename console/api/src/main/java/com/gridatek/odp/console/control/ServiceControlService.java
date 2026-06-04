package com.gridatek.odp.console.control;

/**
 * Service lifecycle actions against the platform's Deployments. Implemented only
 * when Kubernetes access is enabled ({@code odp.k8s.enabled=true}); in the
 * docker-compose subset no bean exists and the controller returns 501.
 */
public interface ServiceControlService {

    /** Rolling-restart the Deployment named {@code name}. */
    void restart(String name);

    /** Scale the Deployment named {@code name} to {@code replicas}. */
    void scale(String name, int replicas);
}
