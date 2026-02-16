package com.osmech.finance.repository;

import com.osmech.finance.entity.TransacaoFinanceira;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Repositório de Transações Financeiras.
 */
@Repository
public interface TransacaoFinanceiraRepository extends JpaRepository<TransacaoFinanceira, Long> {

    /** Todas as transações da oficina, ordenadas por data desc */
    List<TransacaoFinanceira> findByUsuarioIdOrderByDataMovimentacaoDesc(Long usuarioId);

    /** Transações por tipo (ENTRADA ou SAIDA) */
    List<TransacaoFinanceira> findByUsuarioIdAndTipoOrderByDataMovimentacaoDesc(Long usuarioId, String tipo);

    /** Transações em um período */
    List<TransacaoFinanceira> findByUsuarioIdAndDataMovimentacaoBetweenOrderByDataMovimentacaoDesc(
            Long usuarioId, LocalDateTime inicio, LocalDateTime fim);

    /** Transações por referência (ex: OS) */
    List<TransacaoFinanceira> findByUsuarioIdAndReferenciaTipoAndReferenciaId(
            Long usuarioId, String referenciaTipo, Long referenciaId);

    /** Verificar se já existe transação para uma OS */
    boolean existsByUsuarioIdAndReferenciaTipoAndReferenciaIdAndEstornoFalse(
            Long usuarioId, String referenciaTipo, Long referenciaId);

    /** Soma de entradas em um período */
    @Query("SELECT COALESCE(SUM(t.valor), 0) FROM TransacaoFinanceira t " +
           "WHERE t.usuarioId = :uid AND t.tipo = 'ENTRADA' " +
           "AND t.dataMovimentacao BETWEEN :inicio AND :fim")
    BigDecimal somaEntradasPeriodo(@Param("uid") Long usuarioId,
                                   @Param("inicio") LocalDateTime inicio,
                                   @Param("fim") LocalDateTime fim);

    /** Soma de saídas em um período */
    @Query("SELECT COALESCE(SUM(t.valor), 0) FROM TransacaoFinanceira t " +
           "WHERE t.usuarioId = :uid AND t.tipo = 'SAIDA' " +
           "AND t.dataMovimentacao BETWEEN :inicio AND :fim")
    BigDecimal somaSaidasPeriodo(@Param("uid") Long usuarioId,
                                 @Param("inicio") LocalDateTime inicio,
                                 @Param("fim") LocalDateTime fim);

    /** Total de entradas de todos os tempos */
    @Query("SELECT COALESCE(SUM(t.valor), 0) FROM TransacaoFinanceira t " +
           "WHERE t.usuarioId = :uid AND t.tipo = 'ENTRADA'")
    BigDecimal somaTodasEntradas(@Param("uid") Long usuarioId);

    /** Total de saídas de todos os tempos */
    @Query("SELECT COALESCE(SUM(t.valor), 0) FROM TransacaoFinanceira t " +
           "WHERE t.usuarioId = :uid AND t.tipo = 'SAIDA'")
    BigDecimal somaTodasSaidas(@Param("uid") Long usuarioId);

    /** Contagem de transações no mês */
    @Query("SELECT COUNT(t) FROM TransacaoFinanceira t " +
           "WHERE t.usuarioId = :uid " +
           "AND t.dataMovimentacao BETWEEN :inicio AND :fim")
    long contarTransacoesPeriodo(@Param("uid") Long usuarioId,
                                 @Param("inicio") LocalDateTime inicio,
                                 @Param("fim") LocalDateTime fim);

    /** Contagem de transações sem categoria */
    long countByUsuarioIdAndCategoriaIsNull(Long usuarioId);

    /** Buscar por ID e usuário */
    Optional<TransacaoFinanceira> findByIdAndUsuarioId(Long id, Long usuarioId);
}
