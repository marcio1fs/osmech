package com.osmech.payment.service;

import com.osmech.payment.dto.PagamentoRequest;
import com.osmech.payment.dto.PagamentoResponse;
import com.osmech.payment.dto.ResumoFinanceiroResponse;
import com.osmech.payment.entity.Assinatura;
import com.osmech.payment.entity.Pagamento;
import com.osmech.payment.repository.AssinaturaRepository;
import com.osmech.payment.repository.PagamentoRepository;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.util.List;

/**
 * Serviço responsável pelas regras de negócio de Pagamentos.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PagamentoService {

    private final PagamentoRepository pagamentoRepository;
    private final AssinaturaRepository assinaturaRepository;
    private final UsuarioRepository usuarioRepository;

    /**
     * Registra um novo pagamento.
     */
    @Transactional
    public PagamentoResponse criar(String emailUsuario, PagamentoRequest request) {
        Usuario usuario = getUsuario(emailUsuario);

        Pagamento pagamento = Pagamento.builder()
                .usuarioId(usuario.getId())
                .tipo(request.getTipo())
                .referenciaId(request.getReferenciaId())
                .descricao(request.getDescricao())
                .metodoPagamento(request.getMetodoPagamento())
                .valor(request.getValor())
                .status("PENDENTE")
                .observacoes(request.getObservacoes())
                .build();

        pagamento = pagamentoRepository.save(pagamento);
        log.info("Pagamento {} criado - tipo {} valor R${}", pagamento.getId(), request.getTipo(), request.getValor());

        return toResponse(pagamento);
    }

    /**
     * Confirma um pagamento (marca como PAGO).
     */
    @Transactional
    public PagamentoResponse confirmar(String emailUsuario, Long pagamentoId) {
        Usuario usuario = getUsuario(emailUsuario);
        Pagamento pagamento = pagamentoRepository.findById(pagamentoId)
                .orElseThrow(() -> new IllegalArgumentException("Pagamento não encontrado"));

        if (!pagamento.getUsuarioId().equals(usuario.getId())) {
            throw new IllegalArgumentException("Acesso negado a este pagamento");
        }

        if (!"PENDENTE".equals(pagamento.getStatus())) {
            throw new IllegalArgumentException("Pagamento não está pendente");
        }

        pagamento.setStatus("PAGO");
        pagamento.setPagoEm(LocalDateTime.now());
        pagamento = pagamentoRepository.save(pagamento);

        // Se for pagamento de assinatura, atualiza a próxima cobrança
        if ("ASSINATURA".equals(pagamento.getTipo()) && pagamento.getReferenciaId() != null) {
            assinaturaRepository.findById(pagamento.getReferenciaId()).ifPresent(assinatura -> {
                assinatura.setStatus("ACTIVE");
                assinatura.setProximaCobranca(LocalDate.now().plusMonths(1));
                assinaturaRepository.save(assinatura);

                // Reativa o usuário se estava suspenso
                usuario.setAtivo(true);
                usuarioRepository.save(usuario);

                log.info("Assinatura {} reativada após pagamento", assinatura.getId());
            });
        }

        log.info("Pagamento {} confirmado", pagamentoId);
        return toResponse(pagamento);
    }

    /**
     * Cancela um pagamento pendente.
     */
    @Transactional
    public PagamentoResponse cancelar(String emailUsuario, Long pagamentoId) {
        Usuario usuario = getUsuario(emailUsuario);
        Pagamento pagamento = pagamentoRepository.findById(pagamentoId)
                .orElseThrow(() -> new IllegalArgumentException("Pagamento não encontrado"));

        if (!pagamento.getUsuarioId().equals(usuario.getId())) {
            throw new IllegalArgumentException("Acesso negado a este pagamento");
        }

        if (!"PENDENTE".equals(pagamento.getStatus())) {
            throw new IllegalArgumentException("Apenas pagamentos pendentes podem ser cancelados");
        }

        pagamento.setStatus("CANCELADO");
        pagamento = pagamentoRepository.save(pagamento);

        log.info("Pagamento {} cancelado", pagamentoId);
        return toResponse(pagamento);
    }

    /**
     * Lista todos os pagamentos do usuário.
     */
    public List<PagamentoResponse> listar(String emailUsuario) {
        Usuario usuario = getUsuario(emailUsuario);
        return pagamentoRepository.findByUsuarioIdOrderByCriadoEmDesc(usuario.getId())
                .stream()
                .map(this::toResponse)
                .toList();
    }

    /**
     * Lista pagamentos por tipo (ASSINATURA ou OS).
     */
    public List<PagamentoResponse> listarPorTipo(String emailUsuario, String tipo) {
        Usuario usuario = getUsuario(emailUsuario);
        return pagamentoRepository.findByUsuarioIdAndTipoOrderByCriadoEmDesc(usuario.getId(), tipo)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    /**
     * Busca pagamento por ID.
     */
    public PagamentoResponse buscarPorId(String emailUsuario, Long id) {
        Usuario usuario = getUsuario(emailUsuario);
        Pagamento pagamento = pagamentoRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Pagamento não encontrado"));

        if (!pagamento.getUsuarioId().equals(usuario.getId())) {
            throw new IllegalArgumentException("Acesso negado a este pagamento");
        }

        return toResponse(pagamento);
    }

    /**
     * Retorna resumo financeiro do usuário.
     */
    public ResumoFinanceiroResponse getResumoFinanceiro(String emailUsuario) {
        Usuario usuario = getUsuario(emailUsuario);
        Long uid = usuario.getId();

        // Período do mês atual
        YearMonth mesAtual = YearMonth.now();
        LocalDateTime inicioMes = mesAtual.atDay(1).atStartOfDay();
        LocalDateTime fimMes = mesAtual.atEndOfMonth().atTime(LocalTime.MAX);

        BigDecimal receitaTotal = pagamentoRepository.somaReceitaTotal(uid);
        BigDecimal receitaMes = pagamentoRepository.somaReceitaPeriodo(uid, inicioMes, fimMes);
        BigDecimal totalPendente = pagamentoRepository.somaPendentes(uid);
        long qtdPendentes = pagamentoRepository.countByUsuarioIdAndStatus(uid, "PENDENTE");
        long qtdPagamentosMes = pagamentoRepository.countByUsuarioIdAndTipoAndStatusAndCriadoEmBetween(
                uid, "OS", "PAGO", inicioMes, fimMes);

        // Dados da assinatura
        var assinatura = assinaturaRepository
                .findByUsuarioIdAndStatusIn(uid, List.of("ACTIVE", "PAST_DUE", "SUSPENDED"))
                .orElse(null);

        return ResumoFinanceiroResponse.builder()
                .receitaTotal(receitaTotal)
                .receitaMesAtual(receitaMes)
                .totalPendente(totalPendente)
                .qtdPagamentosMes(qtdPagamentosMes)
                .qtdPendentes(qtdPendentes)
                .qtdOsPagasMes(qtdPagamentosMes)
                .statusAssinatura(assinatura != null ? assinatura.getStatus() : (usuario.getAtivo() ? "ACTIVE" : "NONE"))
                .planoAtual(usuario.getPlano())
                .valorAssinatura(assinatura != null ? assinatura.getValorMensal() : BigDecimal.ZERO)
                .build();
    }

    // --- Helpers ---

    private Usuario getUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado"));
    }

    private PagamentoResponse toResponse(Pagamento p) {
        return PagamentoResponse.builder()
                .id(p.getId())
                .usuarioId(p.getUsuarioId())
                .tipo(p.getTipo())
                .referenciaId(p.getReferenciaId())
                .descricao(p.getDescricao())
                .metodoPagamento(p.getMetodoPagamento())
                .valor(p.getValor())
                .status(p.getStatus())
                .pagoEm(p.getPagoEm())
                .transacaoExternaId(p.getTransacaoExternaId())
                .observacoes(p.getObservacoes())
                .criadoEm(p.getCriadoEm())
                .atualizadoEm(p.getAtualizadoEm())
                .build();
    }
}
