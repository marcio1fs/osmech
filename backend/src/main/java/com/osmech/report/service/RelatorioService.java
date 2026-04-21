package com.osmech.report.service;

import com.osmech.finance.entity.TransacaoFinanceira;
import com.osmech.finance.repository.TransacaoFinanceiraRepository;
import com.osmech.os.entity.OrdemServico;
import com.osmech.os.repository.OrdemServicoRepository;
import com.osmech.report.dto.*;
import com.osmech.stock.entity.StockItem;
import com.osmech.stock.entity.StockMovement;
import com.osmech.stock.repository.StockItemRepository;
import com.osmech.stock.repository.StockMovementRepository;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class RelatorioService {

    private final OrdemServicoRepository osRepository;
    private final TransacaoFinanceiraRepository transacaoRepository;
    private final UsuarioRepository usuarioRepository;
    private final StockItemRepository stockItemRepository;
    private final StockMovementRepository stockMovementRepository;

    // ==================== TIPOS DE RELATÓRIO ====================

    public List<Map<String, String>> getTiposRelatorioOs() {
        return List.of(
            Map.of("codigo", "periodo", "nome", "OS por Período", "descricao", "Relatório geral de OS por período"),
            Map.of("codigo", "mecanico", "nome", "OS por Mecânico", "descricao", "Relatório de OS agrupadas por mecânico"),
            Map.of("codigo", "veiculo", "nome", "OS por Veículo", "descricao", "Relatório de OS agrupadas por veículo"),
            Map.of("codigo", "cliente", "nome", "OS por Cliente", "descricao", "Relatório de OS agrupadas por cliente")
        );
    }

    public List<Map<String, String>> getTiposRelatorioFinanceiro() {
        return List.of(
            Map.of("codigo", "receitas", "nome", "Receitas", "descricao", "Relatório de receitas por período"),
            Map.of("codigo", "despesas", "nome", "Despesas", "descricao", "Relatório de despesas por período"),
            Map.of("codigo", "caixa", "nome", "Fluxo de Caixa", "descricao", "Relatório de fluxo de caixa"),
            Map.of("codigo", "metodo", "nome", "Por Método de Pagamento", "descricao", "Receitas agrupadas por método")
        );
    }

    public List<Map<String, String>> getTiposRelatorioCliente() {
        return List.of(
            Map.of("codigo", "gastos", "nome", "Clientes por Gasto", "descricao", "Ranking de clientes por total gasto"),
            Map.of("codigo", "quantidade", "nome", "Clientes por OS", "descricao", "Ranking de clientes por quantidade de OS"),
            Map.of("codigo", "contatos", "nome", "Lista de Contatos", "descricao", "Lista de contatos de todos os clientes")
        );
    }

    public List<Map<String, String>> getTiposRelatorioEstoque() {
        return List.of(
            Map.of("codigo", "valuation", "nome", "Valuation", "descricao", "Valor total do estoque"),
            Map.of("codigo", "baixo", "nome", "Estoque Baixo", "descricao", "Itens com estoque abaixo do mínimo"),
            Map.of("codigo", "movimentacoes", "nome", "Movimentações", "descricao", "Histórico de movimentações de estoque")
        );
    }

    // ==================== RELATÓRIOS DE OS ====================

    public RelatorioOsResponse gerarRelatorioOsPorPeriodo(Long usuarioId, LocalDate inicio, LocalDate fim, String status) {
        LocalDateTime inicioDt = inicio.atStartOfDay();
        LocalDateTime fimDt = fim.atTime(23, 59, 59);

        List<OrdemServico> ordens = osRepository.findByUsuarioIdAndCriadoEmBetweenOrderByCriadoEmDesc(usuarioId, inicioDt, fimDt);
        
        if (status != null && !status.isEmpty()) {
            ordens = ordens.stream()
                .filter(os -> status.equals(os.getStatus()))
                .collect(Collectors.toList());
        }

        long total = ordens.size();
        long abertas = ordens.stream().filter(os -> "ABERTA".equals(os.getStatus())).count();
        long emAndamento = ordens.stream().filter(os -> "EM_ANDAMENTO".equals(os.getStatus())).count();
        long concluidas = ordens.stream().filter(os -> "CONCLUIDA".equals(os.getStatus())).count();
        long canceladas = ordens.stream().filter(os -> "CANCELADA".equals(os.getStatus())).count();

        BigDecimal valorTotal = ordens.stream()
            .map(OrdemServico::getValor)
            .filter(Objects::nonNull)
            .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal valorMedio = total > 0 
            ? valorTotal.divide(BigDecimal.valueOf(total), 2, RoundingMode.HALF_UP) 
            : BigDecimal.ZERO;

        return RelatorioOsResponse.builder()
            .dataInicio(inicio)
            .dataFim(fim)
            .totalOs(total)
            .osAbertas(abertas)
            .osEmAndamento(emAndamento)
            .osConcluidas(concluidas)
            .osCanceladas(canceladas)
            .valorTotal(valorTotal)
            .valorMedioOs(valorMedio)
            .detalhamento(ordens.stream().map(os -> {
                Map<String, Object> map = new HashMap<>();
                map.put("id", os.getId());
                map.put("cliente", os.getClienteNome());
                map.put("placa", os.getPlaca());
                map.put("modelo", os.getModelo());
                map.put("status", os.getStatus());
                map.put("valor", os.getValor());
                map.put("data", os.getCriadoEm());
                return map;
            }).collect(Collectors.toList()))
            .build();
    }

    public List<RelatorioOsPorMecanico> gerarRelatorioOsPorMecanico(Long usuarioId, LocalDate inicio, LocalDate fim) {
        LocalDateTime inicioDt = inicio.atStartOfDay();
        LocalDateTime fimDt = fim.atTime(23, 59, 59);

        List<OrdemServico> ordens = osRepository.findByUsuarioIdAndCriadoEmBetweenOrderByCriadoEmDesc(usuarioId, inicioDt, fimDt);

        return ordens.stream()
            .filter(os -> os.getMecanicoResponsavel() != null && !os.getMecanicoResponsavel().isEmpty())
            .collect(Collectors.groupingBy(OrdemServico::getMecanicoResponsavel))
            .entrySet().stream()
            .map(entry -> {
                List<OrdemServico> grupo = entry.getValue();
                BigDecimal total = grupo.stream()
                    .map(OrdemServico::getValor)
                    .filter(Objects::nonNull)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
                long concluidas = grupo.stream()
                    .filter(os -> "CONCLUIDA".equals(os.getStatus()))
                    .count();
                
                return RelatorioOsPorMecanico.builder()
                    .mecanico(entry.getKey())
                    .totalOs((long) grupo.size())
                    .osConcluidas(concluidas)
                    .valorTotal(total)
                    .valorMedio(grupo.isEmpty() ? BigDecimal.ZERO : 
                        total.divide(BigDecimal.valueOf(grupo.size()), 2, RoundingMode.HALF_UP))
                    .build();
            })
            .sorted((a, b) -> b.getValorTotal().compareTo(a.getValorTotal()))
            .collect(Collectors.toList());
    }

    public List<RelatorioOsPorVeiculo> gerarRelatorioOsPorVeiculo(Long usuarioId, LocalDate inicio, LocalDate fim) {
        LocalDateTime inicioDt = inicio.atStartOfDay();
        LocalDateTime fimDt = fim.atTime(23, 59, 59);

        List<OrdemServico> ordens = osRepository.findByUsuarioIdAndCriadoEmBetweenOrderByCriadoEmDesc(usuarioId, inicioDt, fimDt);

        return ordens.stream()
            .filter(os -> os.getPlaca() != null && !os.getPlaca().isEmpty())
            .collect(Collectors.groupingBy(OrdemServico::getPlaca))
            .entrySet().stream()
            .map(entry -> {
                List<OrdemServico> grupo = entry.getValue();
                BigDecimal total = grupo.stream()
                    .map(OrdemServico::getValor)
                    .filter(Objects::nonNull)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
                LocalDate ultima = grupo.stream()
                    .map(OrdemServico::getCriadoEm)
                    .filter(Objects::nonNull)
                    .map(LocalDateTime::toLocalDate)
                    .max(LocalDate::compareTo)
                    .orElse(null);
                
                return RelatorioOsPorVeiculo.builder()
                    .placa(entry.getKey())
                    .modelo(grupo.get(0).getModelo())
                    .montadora(grupo.get(0).getMontadora())
                    .totalOs((long) grupo.size())
                    .valorTotal(total)
                    .ultimaOs(ultima)
                    .build();
            })
            .sorted((a, b) -> b.getTotalOs().compareTo(a.getTotalOs()))
            .collect(Collectors.toList());
    }

    public List<RelatorioOsPorCliente> gerarRelatorioOsPorCliente(Long usuarioId, LocalDate inicio, LocalDate fim) {
        LocalDateTime inicioDt = inicio.atStartOfDay();
        LocalDateTime fimDt = fim.atTime(23, 59, 59);

        List<OrdemServico> ordens = osRepository.findByUsuarioIdAndCriadoEmBetweenOrderByCriadoEmDesc(usuarioId, inicioDt, fimDt);

        return ordens.stream()
            .filter(os -> os.getClienteNome() != null && !os.getClienteNome().isEmpty())
            .collect(Collectors.groupingBy(OrdemServico::getClienteNome))
            .entrySet().stream()
            .map(entry -> {
                List<OrdemServico> grupo = entry.getValue();
                BigDecimal total = grupo.stream()
                    .map(OrdemServico::getValor)
                    .filter(Objects::nonNull)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
                LocalDate ultima = grupo.stream()
                    .map(OrdemServico::getCriadoEm)
                    .filter(Objects::nonNull)
                    .map(LocalDateTime::toLocalDate)
                    .max(LocalDate::compareTo)
                    .orElse(null);
                
                return RelatorioOsPorCliente.builder()
                    .clienteNome(entry.getKey())
                    .clienteCpf(grupo.get(0).getClienteCpf())
                    .clienteTelefone(grupo.get(0).getClienteTelefone())
                    .totalOs((long) grupo.size())
                    .valorTotal(total)
                    .ultimaOs(ultima)
                    .build();
            })
            .sorted((a, b) -> b.getValorTotal().compareTo(a.getValorTotal()))
            .collect(Collectors.toList());
    }

    // ==================== RELATÓRIOS FINANCEIROS ====================

    public RelatorioFinanceiroResponse gerarRelatorioReceitas(Long usuarioId, LocalDate inicio, LocalDate fim) {
        LocalDateTime inicioDt = inicio.atStartOfDay();
        LocalDateTime fimDt = fim.atTime(23, 59, 59);

        List<TransacaoFinanceira> transacoes = transacaoRepository
            .findByUsuarioIdAndDataMovimentacaoBetweenOrderByDataMovimentacaoDesc(usuarioId, inicioDt, fimDt)
            .stream()
            .filter(t -> "ENTRADA".equals(t.getTipo()))
            .collect(Collectors.toList());

        BigDecimal total = transacoes.stream()
            .map(TransacaoFinanceira::getValor)
            .filter(Objects::nonNull)
            .reduce(BigDecimal.ZERO, BigDecimal::add);

        return RelatorioFinanceiroResponse.builder()
            .dataInicio(inicio)
            .dataFim(fim)
            .totalReceitas(total)
            .totalTransacoes((long) transacoes.size())
            .transacoes(transacoes.stream().map(t -> 
                RelatorioFinanceiroResponse.TransacaoFinanceiraDTO.builder()
                    .id(t.getId())
                    .tipo(t.getTipo())
                    .descricao(t.getDescricao())
                    .valor(t.getValor())
                    .categoria(t.getCategoria() != null ? t.getCategoria().getNome() : null)
                    .metodoPagamento(t.getMetodoPagamento())
                    .data(t.getDataMovimentacao() != null ? t.getDataMovimentacao().toLocalDate() : null)
                    .build()
            ).collect(Collectors.toList()))
            .build();
    }

    public RelatorioDespesasResponse gerarRelatorioDespesas(Long usuarioId, LocalDate inicio, LocalDate fim) {
        LocalDateTime inicioDt = inicio.atStartOfDay();
        LocalDateTime fimDt = fim.atTime(23, 59, 59);

        List<TransacaoFinanceira> transacoes = transacaoRepository
            .findByUsuarioIdAndDataMovimentacaoBetweenOrderByDataMovimentacaoDesc(usuarioId, inicioDt, fimDt)
            .stream()
            .filter(t -> "SAIDA".equals(t.getTipo()))
            .collect(Collectors.toList());

        BigDecimal total = transacoes.stream()
            .map(TransacaoFinanceira::getValor)
            .filter(Objects::nonNull)
            .reduce(BigDecimal.ZERO, BigDecimal::add);

        return RelatorioDespesasResponse.builder()
            .dataInicio(inicio)
            .dataFim(fim)
            .totalDespesas(total)
            .totalTransacoes((long) transacoes.size())
            .despesas(transacoes.stream().map(t -> 
                RelatorioDespesasResponse.DespesaDTO.builder()
                    .id(t.getId())
                    .descricao(t.getDescricao())
                    .valor(t.getValor())
                    .categoria(t.getCategoria() != null ? t.getCategoria().getNome() : null)
                    .data(t.getDataMovimentacao() != null ? t.getDataMovimentacao().toLocalDate() : null)
                    .build()
            ).collect(Collectors.toList()))
            .build();
    }

    public RelatorioFluxoCaixaResponse gerarRelatorioFluxoCaixa(Long usuarioId, LocalDate inicio, LocalDate fim) {
        LocalDateTime inicioDt = inicio.atStartOfDay();
        LocalDateTime fimDt = fim.atTime(23, 59, 59);

        List<TransacaoFinanceira> todas = transacaoRepository
            .findByUsuarioIdAndDataMovimentacaoBetweenOrderByDataMovimentacaoDesc(usuarioId, inicioDt, fimDt);

        BigDecimal entradas = todas.stream()
            .filter(t -> "ENTRADA".equals(t.getTipo()))
            .map(TransacaoFinanceira::getValor)
            .filter(Objects::nonNull)
            .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal saidas = todas.stream()
            .filter(t -> "SAIDA".equals(t.getTipo()))
            .map(TransacaoFinanceira::getValor)
            .filter(Objects::nonNull)
            .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Calcula movimentações diárias
        Map<LocalDate, BigDecimal> entradasPorDia = todas.stream()
            .filter(t -> "ENTRADA".equals(t.getTipo()))
            .collect(Collectors.groupingBy(
                t -> t.getDataMovimentacao().toLocalDate(),
                Collectors.reducing(BigDecimal.ZERO, TransacaoFinanceira::getValor, BigDecimal::add)
            ));

        Map<LocalDate, BigDecimal> saidasPorDia = todas.stream()
            .filter(t -> "SAIDA".equals(t.getTipo()))
            .collect(Collectors.groupingBy(
                t -> t.getDataMovimentacao().toLocalDate(),
                Collectors.reducing(BigDecimal.ZERO, TransacaoFinanceira::getValor, BigDecimal::add)
            ));

        List<RelatorioFluxoCaixaResponse.MovimentacaoDiaria> movimentacoes = new ArrayList<>();
        BigDecimal saldoAcumulado = BigDecimal.ZERO;

        for (LocalDate data = inicio; !data.isAfter(fim); data = data.plusDays(1)) {
            BigDecimal ent = entradasPorDia.getOrDefault(data, BigDecimal.ZERO);
            BigDecimal sai = saidasPorDia.getOrDefault(data, BigDecimal.ZERO);
            saldoAcumulado = saldoAcumulado.add(ent).subtract(sai);

            movimentacoes.add(RelatorioFluxoCaixaResponse.MovimentacaoDiaria.builder()
                .data(data)
                .entradas(ent)
                .saidas(sai)
                .saldoDia(ent.subtract(sai))
                .build());
        }

        return RelatorioFluxoCaixaResponse.builder()
            .dataInicio(inicio)
            .dataFim(fim)
            .saldoInicial(BigDecimal.ZERO)
            .totalEntradas(entradas)
            .totalSaidas(saidas)
            .saldoFinal(saldoAcumulado)
            .movimentacoes(movimentacoes)
            .build();
    }

    public List<RelatorioPorMetodoPagamento> gerarRelatorioPorMetodoPagamento(Long usuarioId, LocalDate inicio, LocalDate fim) {
        LocalDateTime inicioDt = inicio.atStartOfDay();
        LocalDateTime fimDt = fim.atTime(23, 59, 59);

        List<TransacaoFinanceira> transacoes = transacaoRepository
            .findByUsuarioIdAndDataMovimentacaoBetweenOrderByDataMovimentacaoDesc(usuarioId, inicioDt, fimDt)
            .stream()
            .filter(t -> "ENTRADA".equals(t.getTipo()))
            .collect(Collectors.toList());

        return transacoes.stream()
            .filter(t -> t.getMetodoPagamento() != null)
            .collect(Collectors.groupingBy(TransacaoFinanceira::getMetodoPagamento))
            .entrySet().stream()
            .map(entry -> {
                BigDecimal total = entry.getValue().stream()
                    .map(TransacaoFinanceira::getValor)
                    .filter(Objects::nonNull)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
                
                return RelatorioPorMetodoPagamento.builder()
                    .metodoPagamento(entry.getKey())
                    .quantidade((long) entry.getValue().size())
                    .valorTotal(total)
                    .build();
            })
            .sorted((a, b) -> b.getValorTotal().compareTo(a.getValorTotal()))
            .collect(Collectors.toList());
    }

    // ==================== RELATÓRIOS DE CLIENTES ====================

    public List<RelatorioClienteGasto> gerarRelatorioClientesPorGasto(Long usuarioId, Integer limite) {
        int lim = limite != null ? limite : 50;
        
        // Pegar OS do usuário e agrupar por cliente
        List<OrdemServico> ordens = osRepository.findByUsuarioIdOrderByCriadoEmDesc(usuarioId);
        
        return ordens.stream()
            .filter(os -> os.getClienteNome() != null && !os.getClienteNome().isEmpty())
            .collect(Collectors.groupingBy(OrdemServico::getClienteNome))
            .entrySet().stream()
            .map(entry -> {
                List<OrdemServico> grupo = entry.getValue();
                BigDecimal total = grupo.stream()
                    .map(OrdemServico::getValor)
                    .filter(Objects::nonNull)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
                
                return RelatorioClienteGasto.builder()
                    .clienteId(grupo.get(0).getId())
                    .nome(entry.getKey())
                    .telefone(grupo.get(0).getClienteTelefone())
                    .totalGasto(total)
                    .quantidadeOs((long) grupo.size())
                    .build();
            })
            .filter(r -> r.getTotalGasto().compareTo(BigDecimal.ZERO) > 0)
            .sorted((a, b) -> b.getTotalGasto().compareTo(a.getTotalGasto()))
            .limit(lim)
            .collect(Collectors.toList());
    }

    public List<RelatorioClienteQuantidadeOs> gerarRelatorioClientesPorQuantidadeOs(Long usuarioId, Integer limite) {
        int lim = limite != null ? limite : 50;
        
        // Pegar OS do usuário e agrupar por cliente
        List<OrdemServico> ordens = osRepository.findByUsuarioIdOrderByCriadoEmDesc(usuarioId);
        
        return ordens.stream()
            .filter(os -> os.getClienteNome() != null && !os.getClienteNome().isEmpty())
            .collect(Collectors.groupingBy(OrdemServico::getClienteNome))
            .entrySet().stream()
            .map(entry -> {
                List<OrdemServico> grupo = entry.getValue();
                BigDecimal total = grupo.stream()
                    .map(OrdemServico::getValor)
                    .filter(Objects::nonNull)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
                LocalDate ultima = grupo.stream()
                    .map(OrdemServico::getCriadoEm)
                    .filter(Objects::nonNull)
                    .map(LocalDateTime::toLocalDate)
                    .max(LocalDate::compareTo)
                    .orElse(null);
                
                return RelatorioClienteQuantidadeOs.builder()
                    .clienteId(grupo.get(0).getId())
                    .nome(entry.getKey())
                    .telefone(grupo.get(0).getClienteTelefone())
                    .quantidadeOs((long) grupo.size())
                    .valorTotal(total)
                    .ultimaOs(ultima != null ? ultima.format(DateTimeFormatter.ofPattern("dd/MM/yyyy")) : null)
                    .build();
            })
            .sorted((a, b) -> Long.compare(b.getQuantidadeOs(), a.getQuantidadeOs()))
            .limit(lim)
            .collect(Collectors.toList());
    }

    public List<RelatorioContatoCliente> gerarRelatorioContatos(Long usuarioId) {
        // Pegar OS do usuário e extrair contatos únicos de clientes
        List<OrdemServico> ordens = osRepository.findByUsuarioIdOrderByCriadoEmDesc(usuarioId);
        
        return ordens.stream()
            .filter(os -> os.getClienteNome() != null && !os.getClienteNome().isEmpty())
            .collect(Collectors.groupingBy(OrdemServico::getClienteNome))
            .entrySet().stream()
            .map(entry -> {
                OrdemServico primeiro = entry.getValue().get(0);
                return RelatorioContatoCliente.builder()
                    .clienteId(primeiro.getId())
                    .nome(entry.getKey())
                    .telefone(primeiro.getClienteTelefone())
                    .build();
            })
            .sorted(Comparator.comparing(RelatorioContatoCliente::getNome))
            .collect(Collectors.toList());
    }

    // ==================== RELATÓRIOS DE ESTOQUE ====================

    public RelatorioValuationEstoque gerarRelatorioValuationEstoque(Long usuarioId) {
        List<StockItem> itens = stockItemRepository.findByUsuarioIdOrderByNomeAsc(usuarioId);
        
        long totalItens = itens.size();
        long totalQuantidade = itens.stream()
            .mapToLong(i -> i.getQuantidade() != null ? i.getQuantidade() : 0)
            .sum();
        
        BigDecimal valorTotal = itens.stream()
            .map(i -> {
                BigDecimal preco = i.getPrecoVenda() != null ? i.getPrecoVenda() : BigDecimal.ZERO;
                BigDecimal qtd = BigDecimal.valueOf(i.getQuantidade() != null ? i.getQuantidade() : 0);
                return preco.multiply(qtd);
            })
            .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal custoTotal = itens.stream()
            .map(i -> {
                BigDecimal custo = i.getPrecoCusto() != null ? i.getPrecoCusto() : BigDecimal.ZERO;
                BigDecimal qtd = BigDecimal.valueOf(i.getQuantidade() != null ? i.getQuantidade() : 0);
                return custo.multiply(qtd);
            })
            .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal margem = BigDecimal.ZERO;
        if (custoTotal.compareTo(BigDecimal.ZERO) > 0) {
            margem = valorTotal.subtract(custoTotal)
                .divide(custoTotal, 4, RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100));
        }

        return RelatorioValuationEstoque.builder()
            .totalItens(totalItens)
            .totalQuantidade(totalQuantidade)
            .valorTotalEstoque(valorTotal)
            .custoTotal(custoTotal)
            .margemEstimada(margem)
            .build();
    }

    public List<RelatorioEstoqueBaixo> gerarRelatorioEstoqueBaixo(Long usuarioId, Integer limite) {
        int lim = limite != null ? limite : 10;
        
        return stockItemRepository.findAlertItems(usuarioId).stream()
            .filter(i -> i.getQuantidade() != null && i.getQuantidadeMinima() != null)
            .map(i -> RelatorioEstoqueBaixo.builder()
                .id(i.getId())
                .nome(i.getNome())
                .codigo(i.getCodigo())
                .categoria(i.getCategoria())
                .quantidadeAtual(i.getQuantidade())
                .quantidadeMinima(i.getQuantidadeMinima())
                .build())
            .sorted(Comparator.comparingInt(RelatorioEstoqueBaixo::getQuantidadeAtual))
            .limit(lim)
            .collect(Collectors.toList());
    }

    public List<RelatorioMovimentacaoEstoque> gerarRelatorioMovimentacoes(Long usuarioId, LocalDate inicio, LocalDate fim) {
        LocalDateTime inicioDt = inicio.atStartOfDay();
        LocalDateTime fimDt = fim.atTime(23, 59, 59);

        return stockMovementRepository.findByPeriodo(usuarioId, inicioDt, fimDt).stream()
            .map(m -> {
                StockItem item = m.getStockItem();
                return RelatorioMovimentacaoEstoque.builder()
                    .id(m.getId())
                    .itemNome(item != null ? item.getNome() : null)
                    .itemCodigo(item != null ? item.getCodigo() : null)
                    .tipoMovimentacao(m.getTipo())
                    .quantidade(m.getQuantidade())
                    .saldoAnterior(m.getQuantidadeAnterior())
                    .saldoAtual(m.getQuantidadePosterior())
                    .motivo(m.getMotivo())
                    .data(m.getCriadoEm())
                    .build();
            })
            .sorted(Comparator.comparing(RelatorioMovimentacaoEstoque::getData).reversed())
            .collect(Collectors.toList());
    }

    // ==================== EXPORTAÇÃO ====================

    /**
     * Gera CSV real com dados do relatório solicitado.
     * PDF e Excel também geram CSV por ora (sem dependência extra).
     */
    public ByteArrayOutputStream exportarParaPdf(String tipo, LocalDate inicio, LocalDate fim, String formato) {
        String csv = exportarParaCsv(tipo, inicio, fim);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try { out.write(csv.getBytes("UTF-8")); } catch (Exception e) { log.error("Erro ao gerar PDF", e); }
        return out;
    }

    public ByteArrayOutputStream exportarParaExcel(String tipo, LocalDate inicio, LocalDate fim) {
        String csv = exportarParaCsv(tipo, inicio, fim);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try { out.write(csv.getBytes("UTF-8")); } catch (Exception e) { log.error("Erro ao gerar Excel", e); }
        return out;
    }

    public String exportarParaCsv(String tipo, LocalDate inicio, LocalDate fim) {
        // Busca o usuarioId a partir do contexto de segurança
        String email = org.springframework.security.core.context.SecurityContextHolder
                .getContext().getAuthentication().getName();
        Long uid = usuarioRepository.findByEmail(email).map(u -> u.getId()).orElse(null);
        if (uid == null) return "Usuário não encontrado\n";

        StringBuilder sb = new StringBuilder();
        sb.append("\uFEFF"); // BOM UTF-8 para Excel reconhecer acentos
        LocalDate ini = inicio != null ? inicio : LocalDate.now().withDayOfMonth(1);
        LocalDate fim2 = fim != null ? fim : LocalDate.now();

        switch (tipo.toLowerCase()) {
            case "os" -> {
                sb.append("ID,Cliente,Placa,Modelo,Status,Valor,Data\n");
                gerarRelatorioOsPorPeriodo(uid, ini, fim2, null).getDetalhamento()
                    .forEach(d -> sb.append(String.format("%s,%s,%s,%s,%s,%s,%s\n",
                        d.get("id"), csvEscape(d.get("cliente")), csvEscape(d.get("placa")),
                        csvEscape(d.get("modelo")), d.get("status"), d.get("valor"), d.get("data"))));
            }
            case "financeiro" -> {
                sb.append("Tipo,Descrição,Valor,Método,Data\n");
                gerarRelatorioReceitas(uid, ini, fim2).getTransacoes()
                    .forEach(t -> sb.append(String.format("%s,%s,%s,%s,%s\n",
                        t.getTipo(), csvEscape(t.getDescricao()), t.getValor(),
                        csvEscape(t.getMetodoPagamento()), t.getData())));
            }
            case "clientes" -> {
                sb.append("Cliente,Telefone,OS,Total Gasto\n");
                gerarRelatorioClientesPorGasto(uid, 1000)
                    .forEach(c -> sb.append(String.format("%s,%s,%s,%s\n",
                        csvEscape(c.getNome()), csvEscape(c.getTelefone()),
                        c.getQuantidadeOs(), c.getTotalGasto())));
            }
            case "estoque" -> {
                sb.append("Código,Nome,Categoria,Quantidade,Mínimo\n");
                gerarRelatorioEstoqueBaixo(uid, 1000)
                    .forEach(i -> sb.append(String.format("%s,%s,%s,%s,%s\n",
                        csvEscape(i.getCodigo()), csvEscape(i.getNome()),
                        csvEscape(i.getCategoria()), i.getQuantidadeAtual(), i.getQuantidadeMinima())));
            }
            default -> sb.append("Tipo de relatório não reconhecido: ").append(tipo).append("\n");
        }
        return sb.toString();
    }

    private String csvEscape(Object value) {
        if (value == null) return "";
        String s = value.toString().replace("\"", "\"\"");
        return s.contains(",") || s.contains("\n") ? "\"" + s + "\"" : s;
    }
}
