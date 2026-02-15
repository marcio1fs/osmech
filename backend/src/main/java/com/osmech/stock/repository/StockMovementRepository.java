package com.osmech.stock.repository;

import com.osmech.stock.entity.StockMovement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface StockMovementRepository extends JpaRepository<StockMovement, Long> {

    /** Lista movimentações de um item específico */
    List<StockMovement> findByStockItemIdOrderByCriadoEmDesc(Long stockItemId);

    /** Lista todas as movimentações da oficina */
    List<StockMovement> findByUsuarioIdOrderByCriadoEmDesc(Long usuarioId);

    /** Movimentações por período */
    @Query("SELECT m FROM StockMovement m WHERE m.usuarioId = :uid " +
           "AND m.criadoEm >= :inicio AND m.criadoEm <= :fim " +
           "ORDER BY m.criadoEm DESC")
    List<StockMovement> findByPeriodo(@Param("uid") Long usuarioId,
                                      @Param("inicio") LocalDateTime inicio,
                                      @Param("fim") LocalDateTime fim);

    /** Movimentações por OS */
    List<StockMovement> findByOrdemServicoIdOrderByCriadoEmDesc(Long ordemServicoId);

    /** Contagem de saídas por item em período (para relatório de consumo) */
    @Query("SELECT m.stockItem.id, m.stockItem.nome, SUM(m.quantidade) " +
           "FROM StockMovement m WHERE m.usuarioId = :uid AND m.tipo = 'SAIDA' " +
           "AND m.criadoEm >= :inicio AND m.criadoEm <= :fim " +
           "GROUP BY m.stockItem.id, m.stockItem.nome " +
           "ORDER BY SUM(m.quantidade) DESC")
    List<Object[]> findTopConsumo(@Param("uid") Long usuarioId,
                                   @Param("inicio") LocalDateTime inicio,
                                   @Param("fim") LocalDateTime fim);
}
