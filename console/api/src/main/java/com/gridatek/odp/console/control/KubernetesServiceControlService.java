package com.gridatek.odp.console.control;

import com.gridatek.odp.console.config.ConsoleProperties;
import io.fabric8.kubernetes.api.model.ObjectMeta;
import io.fabric8.kubernetes.api.model.apps.Deployment;
import io.fabric8.kubernetes.client.KubernetesClient;
import io.fabric8.kubernetes.client.KubernetesClientException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.HashMap;

/**
 * Fabric8-backed lifecycle: rolling-restart and scale Deployments in the
 * platform's namespace. Active only when {@code odp.k8s.enabled=true}.
 */
@Service
@ConditionalOnProperty(prefix = "odp.k8s", name = "enabled", havingValue = "true")
public class KubernetesServiceControlService implements ServiceControlService {

    private static final Logger log = LoggerFactory.getLogger(KubernetesServiceControlService.class);

    private final KubernetesClient client;
    private final String namespace;

    public KubernetesServiceControlService(KubernetesClient client, ConsoleProperties props) {
        this.client = client;
        // Prefer the configured namespace; fall back to the client's (the pod's).
        String configured = props.k8s() == null ? null : props.k8s().namespace();
        this.namespace = StringUtils.hasText(configured) ? configured : client.getNamespace();
    }

    @Override
    public void restart(String name) {
        // Same effect as `kubectl rollout restart`: stamp the pod template with a
        // restartedAt annotation so the Deployment rolls its pods.
        Deployment d = requireDeployment(name);
        ObjectMeta tplMeta = d.getSpec().getTemplate().getMetadata();
        if (tplMeta.getAnnotations() == null) {
            tplMeta.setAnnotations(new HashMap<>());
        }
        tplMeta.getAnnotations().put("kubectl.kubernetes.io/restartedAt", Instant.now().toString());
        log.info("rolling-restart deployment {}/{}", namespace, name);
        client.apps().deployments().inNamespace(namespace).resource(d).update();
    }

    @Override
    public void scale(String name, int replicas) {
        if (replicas < 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "replicas must be >= 0");
        }
        requireDeployment(name);
        log.info("scaling deployment {}/{} to {}", namespace, name, replicas);
        client.apps().deployments().inNamespace(namespace).withName(name).scale(replicas);
    }

    /** Returns the Deployment, or 404 if absent; 502 if the API call itself fails. */
    private Deployment requireDeployment(String name) {
        Deployment d;
        try {
            d = client.apps().deployments().inNamespace(namespace).withName(name).get();
        } catch (KubernetesClientException e) {
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY,
                    "Kubernetes API error for deployment '" + name + "': " + e.getMessage(), e);
        }
        if (d == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                    "No deployment '" + name + "' in namespace '" + namespace + "'");
        }
        return d;
    }
}
