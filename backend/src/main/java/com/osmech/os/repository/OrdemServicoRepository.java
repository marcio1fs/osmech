package com.osmech.os.repository;

import com.osmech.os.entity.OrdemServico;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

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
}
