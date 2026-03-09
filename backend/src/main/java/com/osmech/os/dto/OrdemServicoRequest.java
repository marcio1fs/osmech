package com.osmech.os.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

/**
 * DTO para criação/atualização de Ordem de Serviço.
 * Suporta múltiplos serviços e itens de estoque.
 */
@Data
public class OrdemServicoRequest {

    @NotBlank(message = "Nome do cliente é obrigatório")
    private String clienteNome;

    private String clienteCpf;
    private String clienteCnpj;

    private String clienteTelefone;

    @NotBlank(message = "Placa é obrigatória")
    private String placa;

    @NotBlank(message = "Modelo é obrigatório")
    private String modelo;

    private String montadora;
    private String corVeiculo;

    @Min(value = 1900, message = "Ano deve ser no mínimo 1900")
    @Max(value = 2100, message = "Ano deve ser no máximo 2100")
    private Integer ano;

    @Min(value = 0, message = "Quilometragem não pode ser negativa")
    private Integer quilometragem;

    /** Descrição geral (campo legado, opcional se enviar servicos[]) */
    private String descricao;

    private String diagnostico;
    private String mecanicoResponsavel;

    /** Peças (campo legado, opcional se enviar itens[]) */
    private String pecas;

    /** Valor total (campo legado, calculado automaticamente se servicos/itens presentes) */
    @DecimalMin(value = "0.0", message = "Valor não pode ser negativo")
    private BigDecimal valor;

    private String status;

    private Boolean whatsappConsentimento;

    /** Lista de serviços da OS */
    @Valid
    private List<ServicoOSRequest> servicos;

    /** Lista de itens de estoque para a OS */
    @Valid
    private List<ItemOSRequest> itens;

    @AssertTrue(message = "Telefone do cliente deve ter 10 ou 11 dÃ­gitos")
    public boolean isClienteTelefoneValido() {
        if (clienteTelefone == null || clienteTelefone.isBlank()) {
            return true;
        }
        String digits = digitsOnly(clienteTelefone);
        return digits.length() == 10 || digits.length() == 11;
    }

    @AssertTrue(message = "CPF invÃ¡lido")
    public boolean isClienteCpfValido() {
        if (clienteCpf == null || clienteCpf.isBlank()) {
            return true;
        }
        return validarCpf(digitsOnly(clienteCpf));
    }

    @AssertTrue(message = "CNPJ invÃ¡lido")
    public boolean isClienteCnpjValido() {
        if (clienteCnpj == null || clienteCnpj.isBlank()) {
            return true;
        }
        return validarCnpj(digitsOnly(clienteCnpj));
    }

    private String digitsOnly(String value) {
        return value == null ? "" : value.replaceAll("\\D", "");
    }

    private boolean validarCpf(String cpf) {
        if (cpf.length() != 11) return false;
        if (cpf.chars().distinct().count() == 1) return false;

        int d1 = calcularDigito(cpf.substring(0, 9), new int[]{10, 9, 8, 7, 6, 5, 4, 3, 2});
        int d2 = calcularDigito(cpf.substring(0, 10), new int[]{11, 10, 9, 8, 7, 6, 5, 4, 3, 2});
        return cpf.charAt(9) == Character.forDigit(d1, 10)
                && cpf.charAt(10) == Character.forDigit(d2, 10);
    }

    private boolean validarCnpj(String cnpj) {
        if (cnpj.length() != 14) return false;
        if (cnpj.chars().distinct().count() == 1) return false;

        int d1 = calcularDigito(cnpj.substring(0, 12), new int[]{5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2});
        int d2 = calcularDigito(cnpj.substring(0, 13), new int[]{6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2});
        return cnpj.charAt(12) == Character.forDigit(d1, 10)
                && cnpj.charAt(13) == Character.forDigit(d2, 10);
    }

    private int calcularDigito(String base, int[] pesos) {
        int soma = 0;
        for (int i = 0; i < pesos.length; i++) {
            soma += Character.getNumericValue(base.charAt(i)) * pesos[i];
        }
        int mod = soma % 11;
        return mod < 2 ? 0 : 11 - mod;
    }
}
