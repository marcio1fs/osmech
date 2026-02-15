package com.osmech.stock.dto;

import com.osmech.stock.entity.StockItem;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * DTO de resposta de item de estoque.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockItemResponse {

    private Long id;
    private String codigo;
    private String nome;
    private String categoria;
    private Integer quantidade;
    private Integer quantidadeMinima;
    private BigDecimal precoCusto;
    private BigDecimal precoVenda;
    private String localizacao;
    private Boolean ativo;
    private Boolean estoqueBaixo;
    private Boolean estoqueZerado;
    private LocalDateTime criadoEm;
    private LocalDateTime atualizadoEm;

    public static StockItemResponse fromEntity(StockItem item) {
        return StockItemResponse.builder()
                .id(item.getId())
                .codigo(item.getCodigo())
                .nome(item.getNome())
                .categoria(item.getCategoria())
                .quantidade(item.getQuantidade())
                .quantidadeMinima(item.getQuantidadeMinima())
                .precoCusto(item.getPrecoCusto())
                .precoVenda(item.getPrecoVenda())
                .localizacao(item.getLocalizacao())
                .ativo(item.getAtivo())
                .estoqueBaixo(item.isEstoqueBaixo())
                .estoqueZerado(item.isEstoqueZerado())
                .criadoEm(item.getCriadoEm())
                .atualizadoEm(item.getAtualizadoEm())
                .build();
    }
}
