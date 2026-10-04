package com.osmech.mecanico.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

/** Request para vincular uma conta de usuário (equipe) a uma ficha de mecânico. */
@Data
public class VincularContaRequest {

    /** ID da conta de usuário (módulo Equipe) a vincular. */
    @NotNull(message = "usuarioId é obrigatório")
    private Long usuarioId;
}
