package com.osmech.mecanico.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class MecanicoRequest {
    @NotBlank(message = "Nome do mecânico é obrigatório")
    @Size(max = 120, message = "Nome deve ter no máximo 120 caracteres")
    private String nome;

    @Size(max = 20, message = "Telefone deve ter no máximo 20 caracteres")
    private String telefone;

    @Size(max = 120, message = "Especialidade deve ter no máximo 120 caracteres")
    private String especialidade;

    private Boolean ativo;
}
