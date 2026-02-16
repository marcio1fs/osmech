package com.osmech.finance.service;

import com.osmech.config.ResourceNotFoundException;
import com.osmech.finance.dto.*;
import com.osmech.finance.entity.CategoriaFinanceira;
import com.osmech.finance.entity.FluxoCaixa;
import com.osmech.finance.entity.TransacaoFinanceira;
import com.osmech.finance.repository.CategoriaFinanceiraRepository;
import com.osmech.finance.repository.FluxoCaixaRepository;
import com.osmech.finance.repository.TransacaoFinanceiraRepository;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

/**
 * Serviço principal do módulo financeiro.
 * Gerencia transações, fluxo de caixa e resumo financeiro.
 */
@Service
@RequiredArgsConstructor
public class FinanceiroService {

    private final TransacaoFinanceiraRepository transacaoRepository;
    private final CategoriaFinanceiraRepository categoriaRepository;
    private final FluxoCaixaRepository fluxoRepository;
    private final UsuarioRepository usuarioRepository;

    // ==========================================
    // TRANSAÇÕES
    // ==========================================

    /**
     * Cria uma nova transação financeira (manual ou automática).
     */
    @Transactional
    public TransacaoResponse criarTransacao(String emailUsuario, TransacaoRequest request) {
        Usuario usuario = getUsuario(emailUsuario);
        validarTipo(request.getTipo());

        CategoriaFinanceira categoria = null;
        if (request.getCategoriaId() != null) {
            categoria = categoriaRepository.findById(request.getCategoriaId())
                    .orElseThrow(() -> new ResourceNotFoundException("Categoria não encontrada"));
        }

        TransacaoFinanceira tx = TransacaoFinanceira.builder()
                .usuarioId(usuario.getId())
                .tipo(request.getTipo())
                .categoria(categoria)
                .descricao(request.getDescricao())
                .valor(request.getValor())
                .referenciaTipo(request.getReferenciaTipo() != null ? request.getReferenciaTipo() : "MANUAL")
                .referenciaId(request.getReferenciaId())
                .metodoPagamento(request.getMetodoPagamento() != null ? request.getMetodoPagamento() : "DINHEIRO")
                .dataMovimentacao(request.getDataMovimentacao() != null ? request.getDataMovimentacao() : LocalDateTime.now())
                .observacoes(request.getObservacoes())
                .build();

        tx = transacaoRepository.save(tx);

        // Atualizar fluxo de caixa do dia
        atualizarFluxoCaixa(usuario.getId(), tx.getDataMovimentacao().toLocalDate());

        return toResponse(tx);
    }

    /**
     * Cria transação automática a partir de uma OS concluída.
     */
    @Transactional
    public TransacaoResponse criarEntradaOS(Long usuarioId, Long osId, BigDecimal valor,
                                             String clienteNome, String placa) {
        // Verifica se já existe transação para esta OS
        if (transacaoRepository.existsByUsuarioIdAndReferenciaTipoAndReferenciaIdAndEstornoFalse(
                usuarioId, "OS", osId)) {
            return null; // Já registrada, não duplicar
        }

        TransacaoFinanceira tx = TransacaoFinanceira.builder()
                .usuarioId(usuarioId)
                .tipo("ENTRADA")
                .descricao("OS #" + osId + " — " + clienteNome + " (" + placa + ")")
                .valor(valor)
                .referenciaTipo("OS")
                .referenciaId(osId)
                .metodoPagamento("DINHEIRO")
                .dataMovimentacao(LocalDateTime.now())
                .build();

        tx = transacaoRepository.save(tx);
        atualizarFluxoCaixa(usuarioId, tx.getDataMovimentacao().toLocalDate());
        return toResponse(tx);
    }

    /**
     * Estorna uma transação existente (cria transação inversa).
     * A transação original NÃO é deletada.
     */
    @Transactional
    public TransacaoResponse estornarTransacao(String emailUsuario, Long transacaoId) {
        Usuario usuario = getUsuario(emailUsuario);
        TransacaoFinanceira original = transacaoRepository.findByIdAndUsuarioId(transacaoId, usuario.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Transação não encontrada"));

        if (Boolean.TRUE.equals(original.getEstorno())) {
            throw new IllegalArgumentException("Não é possível estornar uma transação de estorno");
        }

        // Tipo inverso
        String tipoEstorno = "ENTRADA".equals(original.getTipo()) ? "SAIDA" : "ENTRADA";

        TransacaoFinanceira estorno = TransacaoFinanceira.builder()
                .usuarioId(usuario.getId())
                .tipo(tipoEstorno)
                .categoria(original.getCategoria())
                .descricao("ESTORNO: " + original.getDescricao())
                .valor(original.getValor())
                .referenciaTipo("ESTORNO")
                .referenciaId(original.getId())
                .metodoPagamento(original.getMetodoPagamento())
                .dataMovimentacao(LocalDateTime.now())
                .observacoes("Estorno da transação #" + original.getId())
                .estorno(true)
                .transacaoEstornadaId(original.getId())
                .build();

        estorno = transacaoRepository.save(estorno);
        atualizarFluxoCaixa(usuario.getId(), estorno.getDataMovimentacao().toLocalDate());
        return toResponse(estorno);
    }

    /**
     * Lista transações do usuário, opcionalmente filtradas por período e tipo.
     */
    public List<TransacaoResponse> listarTransacoes(String emailUsuario,
                                                     LocalDate dataInicio,
                                                     LocalDate dataFim,
                                                     String tipo) {
        Usuario usuario = getUsuario(emailUsuario);

        List<TransacaoFinanceira> lista;
        if (dataInicio != null && dataFim != null) {
            lista = transacaoRepository.findByUsuarioIdAndDataMovimentacaoBetweenOrderByDataMovimentacaoDesc(
                    usuario.getId(),
                    dataInicio.atStartOfDay(),
                    dataFim.atTime(LocalTime.MAX));
        } else {
            lista = transacaoRepository.findByUsuarioIdOrderByDataMovimentacaoDesc(usuario.getId());
        }

        if (tipo != null && !tipo.isBlank()) {
            lista = lista.stream().filter(t -> tipo.equals(t.getTipo())).toList();
        }

        return lista.stream().map(this::toResponse).toList();
    }

    // ==========================================
    // FLUXO DE CAIXA
    // ==========================================

    /**
     * Retorna o fluxo de caixa em um período.
     */
    public List<FluxoCaixaResponse> getFluxoCaixa(String emailUsuario, LocalDate inicio, LocalDate fim) {
        Usuario usuario = getUsuario(emailUsuario);
        return fluxoRepository
                .findByUsuarioIdAndDataBetweenOrderByDataAsc(usuario.getId(), inicio, fim)
                .stream()
                .map(this::toFluxoResponse)
                .toList();
    }

    /**
     * Atualiza o fluxo de caixa de um dia específico.
     */
    @Transactional
    public void atualizarFluxoCaixa(Long usuarioId, LocalDate data) {
        LocalDateTime inicioDia = data.atStartOfDay();
        LocalDateTime fimDia = data.atTime(LocalTime.MAX);

        BigDecimal entradas = transacaoRepository.somaEntradasPeriodo(usuarioId, inicioDia, fimDia);
        BigDecimal saidas = transacaoRepository.somaSaidasPeriodo(usuarioId, inicioDia, fimDia);
        BigDecimal saldoDia = entradas.subtract(saidas);

        // Busca saldo acumulado do dia anterior
        BigDecimal saldoAnterior = fluxoRepository
                .findFirstByUsuarioIdAndDataBeforeOrderByDataDesc(usuarioId, data)
                .map(FluxoCaixa::getSaldoAcumulado)
                .orElse(BigDecimal.ZERO);

        BigDecimal saldoAcumulado = saldoAnterior.add(saldoDia);

        FluxoCaixa fluxo = fluxoRepository.findByUsuarioIdAndData(usuarioId, data)
                .orElse(FluxoCaixa.builder()
                        .usuarioId(usuarioId)
                        .data(data)
                        .build());

        fluxo.setTotalEntradas(entradas);
        fluxo.setTotalSaidas(saidas);
        fluxo.setSaldo(saldoDia);
        fluxo.setSaldoAcumulado(saldoAcumulado);

        fluxoRepository.save(fluxo);
    }

    // ==========================================
    // RESUMO FINANCEIRO (DASHBOARD)
    // ==========================================

    /**
     * Retorna resumo financeiro para o dashboard.
     */
    public ResumoFinanceiroDTO getResumoFinanceiro(String emailUsuario) {
        Usuario usuario = getUsuario(emailUsuario);
        Long uid = usuario.getId();

        LocalDate hoje = LocalDate.now();
        LocalDateTime inicioMes = hoje.withDayOfMonth(1).atStartOfDay();
        LocalDateTime fimMes = hoje.atTime(LocalTime.MAX);

        BigDecimal totalEntradas = transacaoRepository.somaTodasEntradas(uid);
        BigDecimal totalSaidas = transacaoRepository.somaTodasSaidas(uid);
        BigDecimal entradasMes = transacaoRepository.somaEntradasPeriodo(uid, inicioMes, fimMes);
        BigDecimal saidasMes = transacaoRepository.somaSaidasPeriodo(uid, inicioMes, fimMes);
        long qtdMes = transacaoRepository.contarTransacoesPeriodo(uid, inicioMes, fimMes);
        long qtdSemCat = transacaoRepository.countByUsuarioIdAndCategoriaIsNull(uid);

        return ResumoFinanceiroDTO.builder()
                .totalEntradas(totalEntradas)
                .totalSaidas(totalSaidas)
                .lucroTotal(totalEntradas.subtract(totalSaidas))
                .entradasMes(entradasMes)
                .saidasMes(saidasMes)
                .lucroMes(entradasMes.subtract(saidasMes))
                .saldoAtual(totalEntradas.subtract(totalSaidas))
                .qtdTransacoesMes(qtdMes)
                .qtdSemCategoria(qtdSemCat)
                .build();
    }

    // ==========================================
    // HELPERS
    // ==========================================

    private Usuario getUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));
    }

    private void validarTipo(String tipo) {
        if (!"ENTRADA".equals(tipo) && !"SAIDA".equals(tipo)) {
            throw new IllegalArgumentException("Tipo deve ser ENTRADA ou SAIDA");
        }
    }

    private TransacaoResponse toResponse(TransacaoFinanceira tx) {
        return TransacaoResponse.builder()
                .id(tx.getId())
                .tipo(tx.getTipo())
                .categoriaId(tx.getCategoria() != null ? tx.getCategoria().getId() : null)
                .categoriaNome(tx.getCategoria() != null ? tx.getCategoria().getNome() : null)
                .descricao(tx.getDescricao())
                .valor(tx.getValor())
                .referenciaTipo(tx.getReferenciaTipo())
                .referenciaId(tx.getReferenciaId())
                .metodoPagamento(tx.getMetodoPagamento())
                .dataMovimentacao(tx.getDataMovimentacao())
                .observacoes(tx.getObservacoes())
                .estorno(tx.getEstorno())
                .transacaoEstornadaId(tx.getTransacaoEstornadaId())
                .criadoEm(tx.getCriadoEm())
                .build();
    }

    private FluxoCaixaResponse toFluxoResponse(FluxoCaixa f) {
        return FluxoCaixaResponse.builder()
                .id(f.getId())
                .data(f.getData())
                .totalEntradas(f.getTotalEntradas())
                .totalSaidas(f.getTotalSaidas())
                .saldo(f.getSaldo())
                .saldoAcumulado(f.getSaldoAcumulado())
                .build();
    }
}
