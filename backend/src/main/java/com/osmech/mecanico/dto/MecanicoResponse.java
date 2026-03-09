package com.osmech.mecanico.dto;

import com.osmech.mecanico.entity.Mecanico;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class MecanicoResponse {
    private Long id;
    private String nome;
    private String telefone;
    private String especialidade;
    private Boolean ativo;
    private LocalDateTime criadoEm;
    private LocalDateTime atualizadoEm;

    public static MecanicoResponse fromEntity(Mecanico m) {
        return MecanicoResponse.builder()
                .id(m.getId())
                .nome(m.getNome())
                .telefone(m.getTelefone())
                .especialidade(m.getEspecialidade())
                .ativo(m.getAtivo())
                .criadoEm(m.getCriadoEm())
                .atualizadoEm(m.getAtualizadoEm())
                .build();
    }
}
