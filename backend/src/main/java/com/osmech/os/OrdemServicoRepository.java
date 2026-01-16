package com.osmech.os;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface OrdemServicoRepository extends JpaRepository<OrdemServico, Long> {
    List<OrdemServico> findByUsuarioIdOrderByCreatedAtDesc(Long usuarioId);
    List<OrdemServico> findByUsuarioIdAndStatus(Long usuarioId, OrdemServico.StatusOS status);
    Optional<OrdemServico> findByIdAndUsuarioId(Long id, Long usuarioId);
}
