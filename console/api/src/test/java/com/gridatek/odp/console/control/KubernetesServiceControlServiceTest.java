package com.gridatek.odp.console.control;

import com.gridatek.odp.console.config.ConsoleProperties;
import io.fabric8.kubernetes.api.model.apps.DeploymentBuilder;
import io.fabric8.kubernetes.client.KubernetesClient;
import io.fabric8.kubernetes.client.server.mock.EnableKubernetesMockClient;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Exercises the fabric8 lifecycle against an in-memory API server (no real
 * cluster).
 */
@EnableKubernetesMockClient(crud = true)
class KubernetesServiceControlServiceTest {

    static final String NS = "odp";

    KubernetesClient client;   // injected by the mock-client extension

    private KubernetesServiceControlService service() {
        return new KubernetesServiceControlService(
                client, new ConsoleProperties(null, null, null, new ConsoleProperties.K8s(true, NS)));
    }

    private void createDeployment(String name, int replicas) {
        client.apps().deployments().inNamespace(NS).resource(new DeploymentBuilder()
                .withNewMetadata().withName(name).withNamespace(NS).endMetadata()
                .withNewSpec()
                    .withReplicas(replicas)
                    .withNewTemplate()
                        .withNewMetadata().addToLabels("app", name).endMetadata()
                        .withNewSpec()
                            .addNewContainer().withName("c").withImage("nginx").endContainer()
                        .endSpec()
                    .endTemplate()
                .endSpec()
                .build()).create();
    }

    @Test
    void scaleUpdatesReplicas() {
        createDeployment("minio", 1);

        service().scale("minio", 3);

        assertThat(client.apps().deployments().inNamespace(NS).withName("minio").get()
                .getSpec().getReplicas()).isEqualTo(3);
    }

    @Test
    void restartStampsThePodTemplate() {
        createDeployment("trino", 1);

        service().restart("trino");

        var annotations = client.apps().deployments().inNamespace(NS).withName("trino").get()
                .getSpec().getTemplate().getMetadata().getAnnotations();
        assertThat(annotations).containsKey("kubectl.kubernetes.io/restartedAt");
    }

    @Test
    void scaleOnMissingDeploymentIs404() {
        assertThatThrownBy(() -> service().scale("nope", 2))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("404");
    }

    @Test
    void negativeReplicasIsRejected() {
        createDeployment("minio", 1);
        assertThatThrownBy(() -> service().scale("minio", -1))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("400");
    }
}
