package com.osmech;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.scheduling.annotation.EnableScheduling;

import com.osmech.integration.IAService;
import com.osmech.integration.OpenAIService;

@SpringBootApplication
@EnableScheduling
public class OsmechApplication {
    public static void main(String[] args) {
        SpringApplication.run(OsmechApplication.class, args);
    }

    @Bean
    public IAService iaService() {
        return new OpenAIService();
    }
}
