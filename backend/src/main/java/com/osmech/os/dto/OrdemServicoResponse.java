package com.osmech.os.dto;

import com.osmech.os.OrdemServico;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrdemServicoResponse {
    private Long id;
    private Long clienteId;
    private String nomeCliente;
    private String telefone;
    private Long veiculoId;
    private String placa;
    private String modelo;
    private String descricaoProblema;
    private String servicosRealizados;
    private BigDecimal valor;
    private OrdemServico.StatusOS status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static OrdemServicoResponse fromEntity(OrdemServico os) {
        OrdemServicoResponse response = new OrdemServicoResponse();
        response.setId(os.getId());
        response.setClienteId(os.getCliente().getId());
        response.setNomeCliente(os.getCliente().getNome());
        response.setTelefone(os.getCliente().getTelefone());
        response.setVeiculoId(os.getVeiculo().getId());
        response.setPlaca(os.getVeiculo().getPlaca());
        response.setModelo(os.getVeiculo().getModelo());
        response.setDescricaoProblema(os.getDescricaoProblema());
        response.setServicosRealizados(os.getServicosRealizados());
        response.setValor(os.getValor());
        response.setStatus(os.getStatus());
        response.setCreatedAt(os.getCreatedAt());
        response.setUpdatedAt(os.getUpdatedAt());
        return response;
    }
}
