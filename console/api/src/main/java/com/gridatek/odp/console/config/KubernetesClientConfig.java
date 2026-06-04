package com.gridatek.odp.console.config;

import io.fabric8.kubernetes.client.KubernetesClient;
import io.fabric8.kubernetes.client.KubernetesClientBuilder;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Provides a {@link KubernetesClient} only when {@code odp.k8s.enabled=true}. In
 * a pod the default builder picks up the in-cluster config (the mounted
 * ServiceAccount token + namespace), so no explicit wiring is needed.
 */
@Configuration
@ConditionalOnProperty(prefix = "odp.k8s", name = "enabled", havingValue = "true")
public class KubernetesClientConfig {

    @Bean(destroyMethod = "close")
    @ConditionalOnMissingBean
    public KubernetesClient kubernetesClient() {
        return new KubernetesClientBuilder().build();
    }
}
