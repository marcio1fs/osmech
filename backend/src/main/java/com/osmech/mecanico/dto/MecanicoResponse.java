package com.osmech.mecanico.dto;

import com.osmech.mecanico.entity.Mecanico;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
public class MecanicoResponse {
    private Long id;
    private String nome;
    private String telefone;
    private String especialidade;
    private BigDecimal percentualComissao;
    private Boolean ativo;
    private LocalDateTime criadoEm;
    private LocalDateTime atualizadoEm;
    private BigDecimal totalComissoes;

    /** Conta de usuário (equipe) vinculada a esta ficha de mecânico, se houver. */
    private Long usuarioContaId;
    private String contaEmail;

    public static MecanicoResponse fromEntity(Mecanico m) {
        return MecanicoResponse.builder()
                .id(m.getId())
                .usuarioContaId(m.getUsuarioContaId())
                .nome(m.getNome())
                .telefone(m.getTelefone())
                .especialidade(m.getEspecialidade())
                .percentualComissao(m.getPercentualComissao())
                .ativo(m.getAtivo())
                .criadoEm(m.getCriadoEm())
                .atualizadoEm(m.getAtualizadoEm())
                .totalComissoes(BigDecimal.ZERO)
                .build();
    }
}
