package com.osmech;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Classe principal do OSMECH.
 * Sistema de controle de Ordens de Serviço para Oficinas Mecânicas.
 */
@SpringBootApplication
@EnableScheduling
public class OsmechApplication {

    public static void main(String[] args) {
        SpringApplication.run(OsmechApplication.class, args);
    }
}
