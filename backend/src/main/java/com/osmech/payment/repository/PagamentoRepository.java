package com.osmech.payment.repository;

import com.osmech.payment.entity.Pagamento;
import com.osmech.payment.entity.StatusPagamento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Repository para Pagamentos.
 */
@Repository
public interface PagamentoRepository extends JpaRepository<Pagamento, Long> {

    /** Lista pagamentos por usuario (mais recente primeiro) */
    List<Pagamento> findByUsuarioIdOrderByCriadoEmDesc(Long usuarioId);

    /** Lista pagamentos por tipo (ASSINATURA ou OS) */
    List<Pagamento> findByUsuarioIdAndTipoOrderByCriadoEmDesc(Long usuarioId, String tipo);

    /** Lista pagamentos por status */
    List<Pagamento> findByUsuarioIdAndStatusOrderByCriadoEmDesc(Long usuarioId, StatusPagamento status);

    /** Busca pagamentos de uma referencia especifica */
    List<Pagamento> findByUsuarioIdAndTipoAndReferenciaId(Long usuarioId, String tipo, Long referenciaId);

    /** Busca último pagamento por referência e status */
    Optional<Pagamento> findFirstByUsuarioIdAndTipoAndReferenciaIdAndStatusOrderByCriadoEmDesc(
            Long usuarioId, String tipo, Long referenciaId, StatusPagamento status);

    /** Busca pagamento pela referencia externa do gateway */
    Optional<Pagamento> findByTransacaoExternaId(String transacaoExternaId);

    /** Conta pagamentos por status */
    long countByUsuarioIdAndStatus(Long usuarioId, StatusPagamento status);

    /** Conta pagamentos por tipo e status em um periodo */
    long countByUsuarioIdAndTipoAndStatusAndCriadoEmBetween(
            Long usuarioId, String tipo, StatusPagamento status, LocalDateTime inicio, LocalDateTime fim);

    /** Soma valores de pagamentos confirmados */
    @Query("SELECT COALESCE(SUM(p.valor), 0) FROM Pagamento p WHERE p.usuarioId = :uid AND p.status = 'PAGO'")
    BigDecimal somaReceitaTotal(@Param("uid") Long usuarioId);

    /** Soma valores de pagamentos confirmados em um periodo */
    @Query("SELECT COALESCE(SUM(p.valor), 0) FROM Pagamento p WHERE p.usuarioId = :uid AND p.status = 'PAGO' AND p.pagoEm BETWEEN :inicio AND :fim")
    BigDecimal somaReceitaPeriodo(@Param("uid") Long usuarioId, @Param("inicio") LocalDateTime inicio, @Param("fim") LocalDateTime fim);

    /** Soma valores pendentes */
    @Query("SELECT COALESCE(SUM(p.valor), 0) FROM Pagamento p WHERE p.usuarioId = :uid AND p.status = 'PENDENTE'")
    BigDecimal somaPendentes(@Param("uid") Long usuarioId);
}
