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
        StockMovementResponse r = new StockMovementResponse();
        r.setId(mov.getId());
        r.setStockItemId(mov.getStockItem().getId());
        r.setStockItemNome(mov.getStockItem().getNome());
        r.setStockItemCodigo(mov.getStockItem().getCodigo());
        r.setTipo(mov.getTipo());
        r.setQuantidade(mov.getQuantidade());
        r.setQuantidadeAnterior(mov.getQuantidadeAnterior());
        r.setQuantidadePosterior(mov.getQuantidadePosterior());
        r.setMotivo(mov.getMotivo());
        r.setDescricao(mov.getDescricao());
        r.setOrdemServicoId(mov.getOrdemServicoId());
        r.setCriadoEm(mov.getCriadoEm());
        return r;
    }
}
