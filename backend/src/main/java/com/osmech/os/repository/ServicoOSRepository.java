package com.osmech.os.repository;

import com.osmech.os.entity.ServicoOS;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ServicoOSRepository extends JpaRepository<ServicoOS, Long> {

    /** Busca serviços de uma OS */
    List<ServicoOS> findByOrdemServicoId(Long ordemServicoId);

    /** Remove todos os serviços de uma OS */
    void deleteByOrdemServicoId(Long ordemServicoId);
}
