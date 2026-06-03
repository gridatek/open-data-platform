package com.gridatek.odp.console.health;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(HealthController.class)
class HealthControllerTest {

    @Autowired
    MockMvc mvc;

    @MockBean
    HealthService healthService;

    @Test
    void listsServicesWithStatus() throws Exception {
        when(healthService.all()).thenReturn(List.of(
                new ServiceStatus("trino", ServiceStatus.UP, "HTTP 200"),
                new ServiceStatus("atlas", ServiceStatus.DOWN, "ResourceAccessException")));

        mvc.perform(get("/api/services"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].name").value("trino"))
                .andExpect(jsonPath("$[0].status").value("UP"))
                .andExpect(jsonPath("$[1].name").value("atlas"))
                .andExpect(jsonPath("$[1].status").value("DOWN"));
    }
}
