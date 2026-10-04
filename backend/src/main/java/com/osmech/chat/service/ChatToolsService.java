package com.osmech.chat.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.osmech.finance.repository.TransacaoFinanceiraRepository;
import com.osmech.os.entity.OrdemServico;
import com.osmech.os.repository.OrdemServicoRepository;
import com.osmech.rbac.PermissionService;
import com.osmech.stock.entity.StockItem;
import com.osmech.stock.repository.StockItemRepository;
import com.osmech.user.entity.Usuario;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Ferramentas SOMENTE LEITURA expostas ao agente (function calling).
 * Sempre filtradas pela oficina do usuario e pelas permissoes RBAC.
 * Nao retornam dados pessoais de clientes (nome, CPF, telefone).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ChatToolsService {

    private static final int MAX_RESULTADOS = 10;

    private final OrdemServicoRepository osRepository;
    private final StockItemRepository stockRepository;
    private final TransacaoFinanceiraRepository transacaoRepository;
    private final PermissionService permissionService;
    private final ObjectMapper objectMapper;

    /** Definicao das ferramentas no formato OpenAI/Gemini. */
    public List<Map<String, Object>> definicoes() {
        return List.of(
                tool("buscar_os",
                        "Busca ordens de servico da oficina por placa e/ou status. Retorna no maximo 10.",
                        Map.of(
                                "placa", Map.of("type", "string", "description", "Placa ou parte dela"),
                                "status", Map.of("type", "string", "description",
                                        "Status: ABERTA, ORCAMENTO, EM_ANDAMENTO ou CONCLUIDA"))),
                tool("buscar_peca",
                        "Busca pecas no estoque pelo nome. Retorna quantidade, minimo e preco de venda.",
                        Map.of("termo", Map.of("type", "string", "description", "Parte do nome da peca"))),
                tool("resumo_financeiro",
                        "Resume entradas, saidas e saldo dos ultimos N dias (1 a 365).",
                        Map.of("dias", Map.of("type", "integer", "description", "Numero de dias, padrao 30"))));
    }

    public String executar(String nome, String argsJson, Usuario user, boolean admin) {
        try {
            Set<String> perms = admin ? Set.of() : Set.copyOf(permissionService.getPermissionsForUser(user));
            JsonNode args = objectMapper.readTree(argsJson == null || argsJson.isBlank() ? "{}" : argsJson);
            Long uid = user.getOficinaId();

            switch (nome) {
                case "buscar_os":
                    if (!admin && !perms.contains("os.visualizar")) return negado();
                    return buscarOs(uid, texto(args, "placa"), texto(args, "status"));
                case "buscar_peca":
                    if (!admin && !perms.contains("estoque.visualizar")) return negado();
                    return buscarPeca(uid, texto(args, "termo"));
                case "resumo_financeiro":
                    if (!admin && !perms.contains("financeiro.visualizar")) return negado();
                    int dias = args.has("dias") ? Math.max(1, Math.min(365, args.get("dias").asInt(30))) : 30;
                    return resumoFinanceiro(uid, dias);
                default:
                    return "Ferramenta desconhecida.";
            }
        } catch (Exception e) {
            log.warn("Erro na ferramenta {}: {}", nome, e.getMessage());
            return "Erro ao consultar os dados.";
        }
    }

    private String buscarOs(Long uid, String placa, String status) {
        List<OrdemServico> lista;
        if (placa != null) {
            lista = osRepository.findByUsuarioIdAndPlacaContainingIgnoreCase(uid, placa);
            if (status != null) {
                lista = lista.stream().filter(o -> status.equalsIgnoreCase(o.getStatus())).collect(Collectors.toList());
            }
        } else if (status != null) {
            lista = osRepository.findByUsuarioIdAndStatusOrderByCriadoEmDesc(uid, status.toUpperCase());
        } else {
            lista = osRepository.findByUsuarioIdOrderByCriadoEmDesc(uid);
        }
        if (lista.isEmpty()) return "Nenhuma OS encontrada.";
        String linhas = lista.stream().limit(MAX_RESULTADOS)
                .map(o -> "OS #" + o.getId() + " | placa " + o.getPlaca() + " | " + o.getMontadora() + " " + o.getModelo()
                        + " | status " + o.getStatus() + " | valor final R$ " + o.getValorFinal()
                        + " | criada em " + o.getCriadoEm().toLocalDate()
                        + " | problema: " + corta(o.getDescricao(), 80))
                .collect(Collectors.joining("\n"));
        return "Encontradas " + lista.size() + " OS (exibindo ate " + MAX_RESULTADOS + "):\n" + linhas;
    }

    private String buscarPeca(Long uid, String termo) {
        if (termo == null) return "Informe o nome da peca.";
        List<StockItem> itens = stockRepository.searchByNome(uid, termo);
        if (itens.isEmpty()) return "Nenhuma peca encontrada.";
        return itens.stream().limit(MAX_RESULTADOS)
                .map(i -> i.getNome() + " (cod " + i.getCodigo() + ") | qtd " + i.getQuantidade()
                        + " | minimo " + i.getQuantidadeMinima() + " | venda R$ " + i.getPrecoVenda())
                .collect(Collectors.joining("\n"));
    }

    private String resumoFinanceiro(Long uid, int dias) {
        LocalDateTime fim = LocalDateTime.now();
        LocalDateTime ini = fim.minusDays(dias);
        BigDecimal ent = transacaoRepository.somaEntradasPeriodo(uid, ini, fim);
        BigDecimal sai = transacaoRepository.somaSaidasPeriodo(uid, ini, fim);
        return "Ultimos " + dias + " dias: entradas R$ " + ent + ", saidas R$ " + sai + ", saldo R$ " + ent.subtract(sai);
    }

    private static String negado() {
        return "O usuario nao tem permissao para consultar esses dados.";
    }

    private static String texto(JsonNode args, String campo) {
        if (!args.hasNonNull(campo)) return null;
        String v = args.get(campo).asText().trim();
        return v.isEmpty() ? null : v;
    }

    private static String corta(String s, int max) {
        if (s == null) return "";
        return s.length() <= max ? s : s.substring(0, max) + "...";
    }

    private static Map<String, Object> tool(String nome, String descricao, Map<String, Object> props) {
        return Map.of("type", "function", "function", Map.of(
                "name", nome,
                "description", descricao,
                "parameters", Map.of("type", "object", "properties", props)));
    }
}
