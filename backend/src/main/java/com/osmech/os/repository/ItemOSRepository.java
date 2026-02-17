package com.osmech.os.repository;

import com.osmech.os.entity.ItemOS;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ItemOSRepository extends JpaRepository<ItemOS, Long> {

    /** Busca itens de estoque de uma OS */
    List<ItemOS> findByOrdemServicoId(Long ordemServicoId);

    /** Remove todos os itens de uma OS */
    void deleteByOrdemServicoId(Long ordemServicoId);
}
