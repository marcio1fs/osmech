package com.osmech.plan.service;

import com.osmech.plan.dto.PlanoResponse;
import com.osmech.plan.entity.Plano;
import com.osmech.plan.repository.PlanoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Serviço responsável pela lógica de Planos de assinatura.
 */
@Service
@RequiredArgsConstructor
public class PlanoService {

    private final PlanoRepository planoRepository;

    /**
     * Lista todos os planos ativos.
     */
    public List<PlanoResponse> listarAtivos() {
        return planoRepository.findByAtivoTrue().stream()
                .map(this::toResponse)
                .toList();
    }

    /**
     * Busca um plano pelo código.
     */
    public PlanoResponse buscarPorCodigo(String codigo) {
        Plano plano = planoRepository.findByCodigo(codigo)
                .orElseThrow(() -> new IllegalArgumentException("Plano não encontrado: " + codigo));
        return toResponse(plano);
    }

    private PlanoResponse toResponse(Plano plano) {
        return PlanoResponse.builder()
                .id(plano.getId())
                .codigo(plano.getCodigo())
                .nome(plano.getNome())
                .preco(plano.getPreco())
                .limiteOs(plano.getLimiteOs())
                .whatsappHabilitado(plano.getWhatsappHabilitado())
                .iaHabilitada(plano.getIaHabilitada())
                .descricao(plano.getDescricao())
                .build();
    }
}
