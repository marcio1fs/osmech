package com.osmech.config;

import com.osmech.plan.entity.Plano;
import com.osmech.plan.repository.PlanoRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

/**
 * Popula dados iniciais no banco (planos de assinatura).
 * Só insere se os planos ainda não existirem.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DataSeeder implements CommandLineRunner {

    private final PlanoRepository planoRepository;

    @Override
    public void run(String... args) {
        if (planoRepository.count() == 0) {
            log.info("Inserindo planos de assinatura...");

            planoRepository.save(Plano.builder()
                    .codigo("PRO")
                    .nome("PRO")
                    .preco(new BigDecimal("49.90"))
                    .limiteOs(50)
                    .whatsappHabilitado(false)
                    .iaHabilitada(false)
                    .descricao("Até 50 OS/mês. Gestão básica de ordens de serviço.")
                    .ativo(true)
                    .build());

            planoRepository.save(Plano.builder()
                    .codigo("PRO_PLUS")
                    .nome("PRO+")
                    .preco(new BigDecimal("79.90"))
                    .limiteOs(200)
                    .whatsappHabilitado(true)
                    .iaHabilitada(false)
                    .descricao("Até 200 OS/mês. WhatsApp automático incluso.")
                    .ativo(true)
                    .build());

            planoRepository.save(Plano.builder()
                    .codigo("PREMIUM")
                    .nome("PREMIUM")
                    .preco(new BigDecimal("149.90"))
                    .limiteOs(0) // ilimitado
                    .whatsappHabilitado(true)
                    .iaHabilitada(true)
                    .descricao("OS ilimitadas. WhatsApp + IA incluso. Suporte prioritário.")
                    .ativo(true)
                    .build());

            log.info("Planos inseridos com sucesso!");
        }
    }
}
