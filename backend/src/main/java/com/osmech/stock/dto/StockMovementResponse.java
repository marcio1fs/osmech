package com.osmech.stock.dto;

import com.osmech.stock.entity.StockMovement;
import lombok.*;
import java.time.LocalDateTime;

/**
 * DTO de resposta de movimentação de estoque.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockMovementResponse {

    private Long id;
    private Long stockItemId;
    private String stockItemNome;
    private String stockItemCodigo;
    private String tipo;
    private Integer quantidade;
    private Integer quantidadeAnterior;
    private Integer quantidadePosterior;
    private String motivo;
    private String descricao;
    private Long ordemServicoId;
    private LocalDateTime criadoEm;

    public static StockMovementResponse fromEntity(StockMovement mov) {
        return StockMovementResponse.builder()
                .id(mov.getId())
                .stockItemId(mov.getStockItem().getId())
                .stockItemNome(mov.getStockItem().getNome())
                .stockItemCodigo(mov.getStockItem().getCodigo())
                .tipo(mov.getTipo())
                .quantidade(mov.getQuantidade())
                .quantidadeAnterior(mov.getQuantidadeAnterior())
                .quantidadePosterior(mov.getQuantidadePosterior())
                .motivo(mov.getMotivo())
                .descricao(mov.getDescricao())
                .ordemServicoId(mov.getOrdemServicoId())
                .criadoEm(mov.getCriadoEm())
                .build();
    }
}
