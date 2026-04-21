package com.osmech.config;

import com.osmech.finance.entity.CategoriaFinanceira;
import com.osmech.finance.repository.CategoriaFinanceiraRepository;
import com.osmech.plan.entity.Plano;
import com.osmech.plan.repository.PlanoRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.Objects;

/**
 * Popula dados iniciais no banco (planos de assinatura e categorias financeiras).
 * Garante que dados essenciais existam.
 */
@Component
@Profile("!prod & !production")
@RequiredArgsConstructor
@Slf4j
public class DataSeeder implements CommandLineRunner {

    private final PlanoRepository planoRepository;
    private final CategoriaFinanceiraRepository categoriaRepository;

    @Override
    public void run(String... args) {
        // Garante que o plano FREE exista (cria se não existir)
        if (planoRepository.findByCodigo("FREE").isEmpty()) {
            log.info("Inserindo plano FREE...");
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
        }

        // Seed outros planos apenas se não existirem (para não duplicar)
        if (planoRepository.count() <= 1) {
            log.info("Inserindo planos de assinatura...");

            // FREE já foi criado acima se não existia

            planoRepository.save(Plano.builder()
                    .codigo("PRO")
                    .nome("PRO")
                    .preco(new BigDecimal("49.90"))
                    .limiteOs(30)
                    .whatsappHabilitado(false)
                    .iaHabilitada(false)
                    .descricao("Até 30 OS/mês. Gestão básica de ordens de serviço.")
                    .ativo(true)
                    .build());

            planoRepository.save(Plano.builder()
                    .codigo("PRO_PLUS")
                    .nome("PRO+")
                    .preco(new BigDecimal("79.90"))
                    .limiteOs(80)
                    .whatsappHabilitado(true)
                    .iaHabilitada(false)
                    .descricao("Até 80 OS/mês. WhatsApp automático incluso.")
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

        // Ajusta limites/descrições em bancos que já tinham planos cadastrados
        atualizarPlanoSeNecessario("PRO", 30,
                "Até 30 OS/mês. Gestão básica de ordens de serviço.");
        atualizarPlanoSeNecessario("PRO_PLUS", 80,
                "Até 80 OS/mês. WhatsApp automático incluso.");
        // PREMIUM permanece inalterado

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

    private void atualizarPlanoSeNecessario(String codigo, int novoLimite, String novaDescricao) {
        planoRepository.findByCodigo(codigo).ifPresent(plano -> {
            boolean alterado = false;

            if (!Objects.equals(plano.getLimiteOs(), novoLimite)) {
                plano.setLimiteOs(novoLimite);
                alterado = true;
            }

            if (!Objects.equals(plano.getDescricao(), novaDescricao)) {
                plano.setDescricao(novaDescricao);
                alterado = true;
            }

            if (alterado) {
                planoRepository.save(plano);
                log.info("Plano {} atualizado: limiteOs={}", codigo, novoLimite);
            }
        });
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
