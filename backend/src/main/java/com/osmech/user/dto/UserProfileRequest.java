package com.osmech.user.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * DTO para atualização de perfil do usuário.
 */
@Data
public class UserProfileRequest {

    @NotBlank(message = "Nome é obrigatório")
    @Size(max = 100, message = "Nome deve ter no máximo 100 caracteres")
    private String nome;

    @Size(max = 20, message = "Telefone deve ter no máximo 20 caracteres")
    private String telefone;

    @Size(max = 100, message = "Nome da oficina deve ter no máximo 100 caracteres")
    private String nomeOficina;

    @Size(max = 18, message = "CNPJ deve ter no máximo 18 caracteres")
    private String cnpjOficina;

    @Size(max = 120, message = "Logradouro deve ter no máximo 120 caracteres")
    private String enderecoLogradouro;

    @Size(max = 20, message = "Número deve ter no máximo 20 caracteres")
    private String enderecoNumero;

    @Size(max = 120, message = "Complemento deve ter no máximo 120 caracteres")
    private String enderecoComplemento;

    @Size(max = 80, message = "Bairro deve ter no máximo 80 caracteres")
    private String enderecoBairro;

    @Size(max = 80, message = "Cidade deve ter no máximo 80 caracteres")
    private String enderecoCidade;

    @Size(max = 2, message = "UF deve ter 2 caracteres")
    private String enderecoEstado;

    @Size(max = 10, message = "CEP deve ter no máximo 10 caracteres")
    private String enderecoCep;

    @Size(max = 120, message = "Site deve ter no máximo 120 caracteres")
    private String siteOficina;
}
