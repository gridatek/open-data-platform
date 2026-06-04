package com.gridatek.odp.console.control;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * With a {@link ServiceControlService} present (Kubernetes enabled), the
 * controller delegates and returns 202 Accepted.
 */
@WebMvcTest(ServiceControlController.class)
class ServiceControlControllerK8sTest {

    @Autowired
    MockMvc mvc;

    @MockBean
    ServiceControlService control;

    @Test
    void restartDelegatesAndAccepts() throws Exception {
        mvc.perform(post("/api/services/trino/restart"))
                .andExpect(status().isAccepted());
        verify(control).restart("trino");
    }

    @Test
    void scaleDelegatesAndAccepts() throws Exception {
        mvc.perform(post("/api/services/minio/scale")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"replicas\":3}"))
                .andExpect(status().isAccepted());
        verify(control).scale("minio", 3);
    }
}
