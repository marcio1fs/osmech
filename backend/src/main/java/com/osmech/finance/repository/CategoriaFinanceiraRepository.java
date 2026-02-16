package com.osmech.finance.repository;

import com.osmech.finance.entity.CategoriaFinanceira;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repositório de Categorias Financeiras.
 */
@Repository
public interface CategoriaFinanceiraRepository extends JpaRepository<CategoriaFinanceira, Long> {

    /** Categorias da oficina + categorias do sistema */
    List<CategoriaFinanceira> findByUsuarioIdOrSistemaTrueOrderByNomeAsc(Long usuarioId);

    /** Categorias de um tipo específico (ENTRADA ou SAIDA) para o usuário ou do sistema */
    @Query("SELECT c FROM CategoriaFinanceira c WHERE (c.usuarioId = :usuarioId AND c.tipo = :tipo) OR (c.sistema = true AND c.tipo = :tipo) ORDER BY c.nome ASC")
    List<CategoriaFinanceira> findByUsuarioIdAndTipoOrSistemaAndTipo(
            @Param("usuarioId") Long usuarioId, @Param("tipo") String tipo);

    /** Verifica se já existe categoria com mesmo nome para o usuário */
    boolean existsByUsuarioIdAndNomeIgnoreCase(Long usuarioId, String nome);
}
