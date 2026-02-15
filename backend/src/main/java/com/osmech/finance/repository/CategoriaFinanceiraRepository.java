package com.osmech.finance.repository;

import com.osmech.finance.entity.CategoriaFinanceira;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

/**
 * Repositório de Categorias Financeiras.
 */
public interface CategoriaFinanceiraRepository extends JpaRepository<CategoriaFinanceira, Long> {

    /** Categorias da oficina + categorias do sistema */
    List<CategoriaFinanceira> findByUsuarioIdOrSistemaTrueOrderByNomeAsc(Long usuarioId);

    /** Categorias de um tipo específico (ENTRADA ou SAIDA) */
    List<CategoriaFinanceira> findByUsuarioIdAndTipoOrSistemaTrueAndTipoOrderByNomeAsc(
            Long usuarioId, String tipo1, String tipo2);

    /** Verifica se já existe categoria com mesmo nome para o usuário */
    boolean existsByUsuarioIdAndNomeIgnoreCase(Long usuarioId, String nome);
}
