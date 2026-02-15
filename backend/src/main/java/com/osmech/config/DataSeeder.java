package com.osmech.config;

import com.osmech.finance.entity.CategoriaFinanceira;
import com.osmech.finance.repository.CategoriaFinanceiraRepository;
import com.osmech.plan.entity.Plano;
import com.osmech.plan.repository.PlanoRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

/**
 * Popula dados iniciais no banco (planos de assinatura e categorias financeiras).
 * Só insere se os dados ainda não existirem.
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DataSeeder implements CommandLineRunner {

    private final PlanoRepository planoRepository;
    private final CategoriaFinanceiraRepository categoriaRepository;

    @Override
    public void run(String... args) {
        if (planoRepository.count() == 0) {
            log.info("Inserindo planos de assinatura...");

            planoRepository.save(Plano.builder()
                    .codigo("FREE")
                    .nome("GRATUITO")
                    .preco(new BigDecimal("0.00"))
                    .limiteOs(10)
                    .whatsappHabilitado(false)
                    .iaHabilitada(false)
                    .descricao("Até 10 OS/mês. Ideal para começar. Sem custo.")
                    .ativo(true)
                    .build());

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

        // Seed categorias financeiras do sistema
        if (categoriaRepository.count() == 0) {
            log.info("Inserindo categorias financeiras do sistema...");

            // Categorias de ENTRADA
            criarCategoriaSistema("Serviço OS", "ENTRADA", "build");
            criarCategoriaSistema("Venda Balcão", "ENTRADA", "storefront");
            criarCategoriaSistema("Outros Recebimentos", "ENTRADA", "attach_money");

            // Categorias de SAÍDA
            criarCategoriaSistema("Peças e Materiais", "SAIDA", "settings");
            criarCategoriaSistema("Salários", "SAIDA", "people");
            criarCategoriaSistema("Aluguel", "SAIDA", "home");
            criarCategoriaSistema("Energia Elétrica", "SAIDA", "bolt");
            criarCategoriaSistema("Água", "SAIDA", "water_drop");
            criarCategoriaSistema("Internet/Telefone", "SAIDA", "wifi");
            criarCategoriaSistema("Impostos", "SAIDA", "receipt_long");
            criarCategoriaSistema("Manutenção", "SAIDA", "handyman");
            criarCategoriaSistema("Combustível", "SAIDA", "local_gas_station");
            criarCategoriaSistema("Outras Despesas", "SAIDA", "money_off");

            log.info("Categorias financeiras inseridas com sucesso!");
        }
    }

    private void criarCategoriaSistema(String nome, String tipo, String icone) {
        categoriaRepository.save(CategoriaFinanceira.builder()
                .nome(nome)
                .tipo(tipo)
                .icone(icone)
                .sistema(true)
                .usuarioId(null)
                .build());
    }
}
