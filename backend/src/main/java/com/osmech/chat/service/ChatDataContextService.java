package com.osmech.chat.service;

import com.osmech.finance.repository.TransacaoFinanceiraRepository;
import com.osmech.os.repository.OrdemServicoRepository;
import com.osmech.rbac.PermissionService;
import com.osmech.stock.entity.StockItem;
import com.osmech.stock.repository.StockItemRepository;
import com.osmech.user.entity.Usuario;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Monta um resumo SOMENTE LEITURA e AGREGADO dos dados da oficina para o agente de IA.
 * Respeita o escopo da oficina (oficinaId) e as permissoes RBAC do usuario.
 * Nao inclui dados pessoais de clientes.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ChatDataContextService {

    private static final List<String> STATUS_OS = List.of("ABERTA", "ORCAMENTO", "EM_ANDAMENTO", "CONCLUIDA");

    private final OrdemServicoRepository osRepository;
    private final StockItemRepository stockRepository;
    private final TransacaoFinanceiraRepository transacaoRepository;
    private final PermissionService permissionService;

    public String montarResumo(Usuario user, boolean admin) {
        Long uid = user.getOficinaId();
        Set<String> perms;
        try {
            perms = Set.copyOf(permissionService.getPermissionsForUser(user));
        } catch (Exception e) {
            perms = Set.of();
        }
        StringBuilder sb = new StringBuilder();

        try {
            if (admin || perms.contains("os.visualizar")) {
                sb.append("- OS total: ").append(osRepository.countByUsuarioId(uid)).append('\n');
                sb.append("- OS por status: ").append(STATUS_OS.stream()
                        .map(s -> s + "=" + osRepository.countByUsuarioIdAndStatus(uid, s))
                        .collect(Collectors.joining(", "))).append('\n');
            }
            if (admin || perms.contains("estoque.visualizar")) {
                sb.append("- Pecas ativas: ").append(stockRepository.countByUsuarioIdAndAtivoTrue(uid)).append('\n');
                sb.append("- Pecas em alerta (abaixo do minimo): ").append(stockRepository.countAlertItems(uid)).append('\n');
                List<StockItem> alertas = stockRepository.findAlertItems(uid);
                if (!alertas.isEmpty()) {
                    sb.append("- Principais alertas: ").append(alertas.stream().limit(10)
                            .map(i -> i.getNome() + " (" + i.getQuantidade() + "/min " + i.getQuantidadeMinima() + ")")
                            .collect(Collectors.joining("; "))).append('\n');
                }
            }
            if (admin || perms.contains("financeiro.visualizar")) {
                LocalDate hoje = LocalDate.now();
                LocalDateTime ini = hoje.withDayOfMonth(1).atStartOfDay();
                LocalDateTime fim = LocalDateTime.now();
                BigDecimal ent = transacaoRepository.somaEntradasPeriodo(uid, ini, fim);
                BigDecimal sai = transacaoRepository.somaSaidasPeriodo(uid, ini, fim);
                sb.append("- Financeiro do mes atual: entradas R$ ").append(ent)
                        .append(", saidas R$ ").append(sai)
                        .append(", saldo R$ ").append(ent.subtract(sai)).append('\n');
            }
        } catch (Exception e) {
            log.warn("Falha ao montar contexto de dados do chat: {}", e.getMessage());
        }

        return sb.length() == 0 ? "" : sb.toString();
    }
}
