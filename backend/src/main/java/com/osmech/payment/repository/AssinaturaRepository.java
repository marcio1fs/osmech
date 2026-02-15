package com.osmech.payment.repository;

import com.osmech.payment.entity.Assinatura;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * Repository para Assinaturas.
 */
@Repository
public interface AssinaturaRepository extends JpaRepository<Assinatura, Long> {

    /** Busca assinatura ativa do usuário */
    Optional<Assinatura> findByUsuarioIdAndStatusIn(Long usuarioId, List<String> statuses);

    /** Busca última assinatura do usuário (mais recente) */
    Optional<Assinatura> findFirstByUsuarioIdOrderByCriadoEmDesc(Long usuarioId);

    /** Busca todas as assinaturas do usuário */
    List<Assinatura> findByUsuarioIdOrderByCriadoEmDesc(Long usuarioId);

    /** Busca assinaturas com cobrança vencida (para automatização) */
    List<Assinatura> findByStatusAndProximaCobrancaBefore(String status, LocalDate data);

    /** Busca assinaturas ativas */
    List<Assinatura> findByStatus(String status);

    /** Conta assinaturas ativas */
    long countByStatus(String status);
}
