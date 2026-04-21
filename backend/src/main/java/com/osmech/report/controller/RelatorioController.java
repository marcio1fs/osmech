package com.osmech.report.controller;

import com.osmech.report.dto.*;
import com.osmech.report.service.RelatorioService;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * Controller para geração de relatórios do sistema.
 * Suporta múltiplos formatos: JSON (visualização), PDF, Excel, CSV
 */
@RestController
@RequestMapping("/relatorios")
@RequiredArgsConstructor
public class RelatorioController {

    private final RelatorioService relatorioService;
    private final UsuarioRepository usuarioRepository;

    private Long getUsuarioId(Authentication auth) {
        if (auth == null) return null;
        String email = auth.getName();
        return usuarioRepository.findByEmail(email)
            .map(Usuario::getId)
            .orElse(null);
    }

    // ==================== RELATÓRIOS DE OS ====================

    /**
     * Lista todos os relatórios de OS disponíveis
     */
    @GetMapping("/os/tipos")
    public List<Map<String, String>> getTiposRelatorioOs() {
        return relatorioService.getTiposRelatorioOs();
    }

    /**
     * Gera relatório de OS por período
     */
    @GetMapping("/os/periodo")
    public ResponseEntity<RelatorioOsResponse> relatorioOsPorPeriodo(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim,
            @RequestParam(required = false) String status,
            Authentication authentication) {
        Long usuarioId = getUsuarioId(authentication);
        return ResponseEntity.ok(relatorioService.gerarRelatorioOsPorPeriodo(usuarioId, inicio, fim, status));
    }

    /**
     * Gera relatório de OS por mecânico
     */
    @GetMapping("/os/mecanico")
    public ResponseEntity<List<RelatorioOsPorMecanico>> relatorioOsPorMecanico(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim,
            Authentication authentication) {
        Long usuarioId = getUsuarioId(authentication);
        return ResponseEntity.ok(relatorioService.gerarRelatorioOsPorMecanico(usuarioId, inicio, fim));
    }

    /**
     * Gera relatório de OS por veículo
     */
    @GetMapping("/os/veiculo")
    public ResponseEntity<List<RelatorioOsPorVeiculo>> relatorioOsPorVeiculo(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim,
            Authentication authentication) {
        Long usuarioId = getUsuarioId(authentication);
        return ResponseEntity.ok(relatorioService.gerarRelatorioOsPorVeiculo(usuarioId, inicio, fim));
    }

    /**
     * Gera relatório de OS por cliente
     */
    @GetMapping("/os/cliente")
    public ResponseEntity<List<RelatorioOsPorCliente>> relatorioOsPorCliente(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim,
            Authentication authentication) {
        Long usuarioId = getUsuarioId(authentication);
        return ResponseEntity.ok(relatorioService.gerarRelatorioOsPorCliente(usuarioId, inicio, fim));
    }

    // ==================== RELATÓRIOS FINANCEIROS ====================

    /**
     * Lista todos os relatórios financeiros disponíveis
     */
    @GetMapping("/financeiro/tipos")
    public List<Map<String, String>> getTiposRelatorioFinanceiro() {
        return relatorioService.getTiposRelatorioFinanceiro();
    }

    /**
     * Gera relatório de receitas por período
     */
    @GetMapping("/financeiro/receitas")
    public ResponseEntity<RelatorioFinanceiroResponse> relatorioReceitas(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim,
            Authentication authentication) {
        Long usuarioId = getUsuarioId(authentication);
        return ResponseEntity.ok(relatorioService.gerarRelatorioReceitas(usuarioId, inicio, fim));
    }

    /**
     * Gera relatório de despesas por período
     */
    @GetMapping("/financeiro/despesas")
    public ResponseEntity<RelatorioDespesasResponse> relatorioDespesas(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim,
            Authentication authentication) {
        Long usuarioId = getUsuarioId(authentication);
        return ResponseEntity.ok(relatorioService.gerarRelatorioDespesas(usuarioId, inicio, fim));
    }

    /**
     * Gera relatório de fluxo de caixa
     */
    @GetMapping("/financeiro/caixa")
    public ResponseEntity<RelatorioFluxoCaixaResponse> relatorioFluxoCaixa(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim,
            Authentication authentication) {
        Long usuarioId = getUsuarioId(authentication);
        return ResponseEntity.ok(relatorioService.gerarRelatorioFluxoCaixa(usuarioId, inicio, fim));
    }

    /**
     * Gera relatório de receitas por método de pagamento
     */
    @GetMapping("/financeiro/metodo-pagamento")
    public ResponseEntity<List<RelatorioPorMetodoPagamento>> relatorioPorMetodoPagamento(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim,
            Authentication authentication) {
        Long usuarioId = getUsuarioId(authentication);
        return ResponseEntity.ok(relatorioService.gerarRelatorioPorMetodoPagamento(usuarioId, inicio, fim));
    }

    // ==================== RELATÓRIOS DE CLIENTES ====================

    /**
     * Lista todos os relatórios de clientes disponíveis
     */
    @GetMapping("/cliente/tipos")
    public List<Map<String, String>> getTiposRelatorioCliente() {
        return relatorioService.getTiposRelatorioCliente();
    }

    /**
     * Gera relatório de clientes por total gasto
     */
    @GetMapping("/cliente/gastos")
    public ResponseEntity<List<RelatorioClienteGasto>> relatorioClientesPorGasto(
            @RequestParam(required = false) Integer limite,
            Authentication authentication) {
        Long usuarioId = getUsuarioId(authentication);
        return ResponseEntity.ok(relatorioService.gerarRelatorioClientesPorGasto(usuarioId, limite));
    }

    /**
     * Gera relatório de clientes por número de OS
     */
    @GetMapping("/cliente/quantidade-os")
    public ResponseEntity<List<RelatorioClienteQuantidadeOs>> relatorioClientesPorQuantidadeOs(
            @RequestParam(required = false) Integer limite,
            Authentication authentication) {
        Long usuarioId = getUsuarioId(authentication);
        return ResponseEntity.ok(relatorioService.gerarRelatorioClientesPorQuantidadeOs(usuarioId, limite));
    }

    /**
     * Gera lista de contatos de clientes
     */
    @GetMapping("/cliente/contatos")
    public ResponseEntity<List<RelatorioContatoCliente>> relatorioContatos(Authentication authentication) {
        Long usuarioId = getUsuarioId(authentication);
        return ResponseEntity.ok(relatorioService.gerarRelatorioContatos(usuarioId));
    }

    // ==================== RELATÓRIOS DE ESTOQUE ====================

    /**
     * Lista todos os relatórios de estoque disponíveis
     */
    @GetMapping("/estoque/tipos")
    public List<Map<String, String>> getTiposRelatorioEstoque() {
        return relatorioService.getTiposRelatorioEstoque();
    }

    /**
     * Gera relatório de valuation de estoque
     */
    @GetMapping("/estoque/valuation")
    public ResponseEntity<RelatorioValuationEstoque> relatorioValuationEstoque(Authentication authentication) {
        Long usuarioId = getUsuarioId(authentication);
        return ResponseEntity.ok(relatorioService.gerarRelatorioValuationEstoque(usuarioId));
    }

    /**
     * Gera relatório de itens com estoque baixo
     */
    @GetMapping("/estoque/baixo-estoque")
    public ResponseEntity<List<RelatorioEstoqueBaixo>> relatorioEstoqueBaixo(
            @RequestParam(defaultValue = "10") Integer limite,
            Authentication authentication) {
        Long usuarioId = getUsuarioId(authentication);
        return ResponseEntity.ok(relatorioService.gerarRelatorioEstoqueBaixo(usuarioId, limite));
    }

    /**
     * Gera relatório de movimentações de estoque
     */
    @GetMapping("/estoque/movimentacoes")
    public ResponseEntity<List<RelatorioMovimentacaoEstoque>> relatorioMovimentacoes(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim,
            Authentication authentication) {
        Long usuarioId = getUsuarioId(authentication);
        return ResponseEntity.ok(relatorioService.gerarRelatorioMovimentacoes(usuarioId, inicio, fim));
    }

    // ==================== EXPORTAÇÃO ====================

    /**
     * Exporta relatório para PDF (gera CSV com dados reais)
     */
    @GetMapping("/exportar/pdf")
    public ResponseEntity<byte[]> exportarPdf(
            @RequestParam String tipo,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim,
            @RequestParam(required = false) String formato) {

        String csv = relatorioService.exportarParaCsv(tipo, inicio, fim);
        String filename = String.format("relatorio_%s_%s.csv", tipo, LocalDate.now());

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(csv.getBytes(java.nio.charset.StandardCharsets.UTF_8));
    }

    /**
     * Exporta relatório para Excel (gera CSV com dados reais)
     */
    @GetMapping("/exportar/excel")
    public ResponseEntity<byte[]> exportarExcel(
            @RequestParam String tipo,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim) {

        String csv = relatorioService.exportarParaCsv(tipo, inicio, fim);
        String filename = String.format("relatorio_%s_%s.csv", tipo, LocalDate.now());

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(csv.getBytes(java.nio.charset.StandardCharsets.UTF_8));
    }

    /**
     * Exporta relatório para CSV com dados reais
     */
    @GetMapping("/exportar/csv")
    public ResponseEntity<byte[]> exportarCsv(
            @RequestParam String tipo,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate inicio,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fim) {

        String csv = relatorioService.exportarParaCsv(tipo, inicio, fim);
        String filename = String.format("relatorio_%s_%s.csv", tipo, LocalDate.now());

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
                .body(csv.getBytes(java.nio.charset.StandardCharsets.UTF_8));
    }
}
