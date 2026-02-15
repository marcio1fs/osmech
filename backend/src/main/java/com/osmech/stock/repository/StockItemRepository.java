package com.osmech.stock.repository;

import com.osmech.stock.entity.StockItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StockItemRepository extends JpaRepository<StockItem, Long> {

    /** Lista todos os itens ativos da oficina, ordenados por nome */
    List<StockItem> findByUsuarioIdAndAtivoTrueOrderByNomeAsc(Long usuarioId);

    /** Lista todos (incluindo inativos) */
    List<StockItem> findByUsuarioIdOrderByNomeAsc(Long usuarioId);

    /** Busca por código dentro da oficina */
    Optional<StockItem> findByUsuarioIdAndCodigoIgnoreCase(Long usuarioId, String codigo);

    /** Verifica se já existe código na oficina */
    boolean existsByUsuarioIdAndCodigoIgnoreCase(Long usuarioId, String codigo);

    /** Itens com estoque abaixo do mínimo */
    @Query("SELECT s FROM StockItem s WHERE s.usuarioId = :uid AND s.ativo = true " +
           "AND s.quantidade <= s.quantidadeMinima ORDER BY s.quantidade ASC")
    List<StockItem> findAlertItems(@Param("uid") Long usuarioId);

    /** Itens com estoque zerado */
    @Query("SELECT s FROM StockItem s WHERE s.usuarioId = :uid AND s.ativo = true " +
           "AND s.quantidade <= 0 ORDER BY s.nome ASC")
    List<StockItem> findZeroStock(@Param("uid") Long usuarioId);

    /** Contagem de itens ativos */
    long countByUsuarioIdAndAtivoTrue(Long usuarioId);

    /** Contagem de itens em alerta */
    @Query("SELECT COUNT(s) FROM StockItem s WHERE s.usuarioId = :uid AND s.ativo = true " +
           "AND s.quantidade <= s.quantidadeMinima")
    long countAlertItems(@Param("uid") Long usuarioId);

    /** Busca o maior número sequencial do código (PCA-XXX) por oficina */
    @Query("SELECT MAX(CAST(SUBSTRING(s.codigo, 5) AS int)) FROM StockItem s WHERE s.usuarioId = :uid AND s.codigo LIKE 'PCA-%'")
    Integer findMaxCodigoSequencial(@Param("uid") Long usuarioId);

    /** Busca por categoria */
    List<StockItem> findByUsuarioIdAndCategoriaAndAtivoTrueOrderByNomeAsc(Long usuarioId, String categoria);

    /** Busca por nome (like) */
    @Query("SELECT s FROM StockItem s WHERE s.usuarioId = :uid AND s.ativo = true " +
           "AND LOWER(s.nome) LIKE LOWER(CONCAT('%', :termo, '%')) ORDER BY s.nome ASC")
    List<StockItem> searchByNome(@Param("uid") Long usuarioId, @Param("termo") String termo);
}
