package com.osmech.os.repository;

import com.osmech.os.entity.OrdemServico;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Repositório para operações de persistência de Ordem de Serviço.
 */
@Repository
public interface OrdemServicoRepository extends JpaRepository<OrdemServico, Long> {

    /** Busca todas as OS de um usuário (oficina) */
    List<OrdemServico> findByUsuarioIdOrderByCriadoEmDesc(Long usuarioId);

    /** Busca OS por status de um usuário */
    List<OrdemServico> findByUsuarioIdAndStatusOrderByCriadoEmDesc(Long usuarioId, String status);

    /** Busca OS pela placa do veículo de um usuário */
    List<OrdemServico> findByUsuarioIdAndPlacaContainingIgnoreCase(Long usuarioId, String placa);

    /** Conta total de OS de um usuário */
    long countByUsuarioId(Long usuarioId);

    /** Conta OS por status de um usuário */
    long countByUsuarioIdAndStatus(Long usuarioId, String status);

    /** Conta OS de um usuário criadas em um período (para limite mensal do plano) */
    long countByUsuarioIdAndCriadoEmBetween(Long usuarioId, LocalDateTime inicio, LocalDateTime fim);

    /** Busca OS por usuário e período */
    List<OrdemServico> findByUsuarioIdAndCriadoEmBetweenOrderByCriadoEmDesc(Long usuarioId, LocalDateTime inicio, LocalDateTime fim);

    /** Busca o maior número de OS atribuído a uma oficina */
    @org.springframework.data.jpa.repository.Query("SELECT COALESCE(MAX(os.numero), 0) FROM OrdemServico os WHERE os.usuarioId = :usuarioId")
    Long findMaxNumeroByUsuarioId(@org.springframework.data.repository.query.Param("usuarioId") Long usuarioId);

    /** Busca OS por oficina e seu número sequencial */
    java.util.Optional<OrdemServico> findByUsuarioIdAndNumero(Long usuarioId, Long numero);
}
