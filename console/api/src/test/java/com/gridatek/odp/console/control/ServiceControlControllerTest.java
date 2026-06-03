package com.gridatek.odp.console.control;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ServiceControlController.class)
class ServiceControlControllerTest {

    @Autowired
    MockMvc mvc;

    @Test
    void restartIsNotImplementedInLaptopSubset() throws Exception {
        mvc.perform(post("/api/services/trino/restart"))
                .andExpect(status().isNotImplemented());
    }
}
