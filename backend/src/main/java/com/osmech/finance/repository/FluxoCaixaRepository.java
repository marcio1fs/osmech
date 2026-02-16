package com.osmech.finance.repository;

import com.osmech.finance.entity.FluxoCaixa;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * Repositório de Fluxo de Caixa.
 */
@Repository
public interface FluxoCaixaRepository extends JpaRepository<FluxoCaixa, Long> {

    /** Fluxo de caixa de um dia específico */
    Optional<FluxoCaixa> findByUsuarioIdAndData(Long usuarioId, LocalDate data);

    /** Fluxo de caixa em um período, ordenado por data */
    List<FluxoCaixa> findByUsuarioIdAndDataBetweenOrderByDataAsc(
            Long usuarioId, LocalDate inicio, LocalDate fim);

    /** Último registro de fluxo de caixa antes de uma data */
    Optional<FluxoCaixa> findFirstByUsuarioIdAndDataBeforeOrderByDataDesc(
            Long usuarioId, LocalDate data);
}
