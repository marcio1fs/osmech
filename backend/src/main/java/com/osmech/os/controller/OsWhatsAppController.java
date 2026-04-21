package com.osmech.os.controller;

import com.osmech.notification.service.WhatsAppService;
import com.osmech.os.entity.ItemOS;
import com.osmech.os.entity.OrdemServico;
import com.osmech.os.entity.ServicoOS;
import com.osmech.os.repository.ItemOSRepository;
import com.osmech.os.repository.OrdemServicoRepository;
import com.osmech.os.repository.ServicoOSRepository;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/os")
public class OsWhatsAppController {

    @Autowired
    private OrdemServicoRepository osRepository;

    @Autowired
    private ServicoOSRepository servicoOSRepository;

    @Autowired
    private ItemOSRepository itemOSRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private WhatsAppService whatsAppService;

    /**
     * POST /api/os/{id}/enviar-recibo-whatsapp
     * Envia o recibo da OS via WhatsApp sem modificar o status.
     */
    @PostMapping("/{id}/enviar-recibo-whatsapp")
    public ResponseEntity<?> enviarReciboWhatsApp(
            Authentication auth,
            @PathVariable Long id,
            @RequestBody EnviarReciboWhatsAppRequest request) {

        String email = auth.getName();
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Usuario nao encontrado"));

        OrdemServico os = osRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Ordem de Servico nao encontrada"));

        if (!os.getUsuarioId().equals(usuario.getId())) {
            throw new IllegalArgumentException("Acesso negado a esta Ordem de Servico");
        }

        if (!Boolean.TRUE.equals(os.getWhatsappConsentimento())) {
            return ResponseEntity.badRequest().body(
                    java.util.Map.of("error", "Cliente nao autorizou envio de mensagens via WhatsApp"));
        }

        String telefoneWhatsapp = request.getTelefoneWhatsapp();
        if (telefoneWhatsapp == null || telefoneWhatsapp.isBlank()) {
            telefoneWhatsapp = os.getClienteTelefone();
        }
        if (telefoneWhatsapp == null || telefoneWhatsapp.isBlank()) {
            return ResponseEntity.badRequest().body(
                    java.util.Map.of("error", "Telefone do cliente nao informado"));
        }

        List<ServicoOS> servicos = servicoOSRepository.findByOrdemServicoId(os.getId());
        List<ItemOS> itens = itemOSRepository.findByOrdemServicoId(os.getId());

        String recibo = montarReciboExtrato(usuario, os, servicos, itens);
        WhatsAppService.ResultadoEnvio resultado = whatsAppService.enviarMensagem(telefoneWhatsapp, recibo);

        return ResponseEntity.ok(java.util.Map.of(
                "enviado", resultado.enviado(),
                "destino", resultado.destino(),
                "detalhe", resultado.detalhe(),
                "recibo", recibo));
    }

    private String montarReciboExtrato(Usuario usuario, OrdemServico os,
                                       List<ServicoOS> servicos, List<ItemOS> itens) {
        StringBuilder sb = new StringBuilder();

        sb.append("========================================\n");
        sb.append("            RECIBO - ORDEM DE SERVICO\n");
        sb.append("========================================\n\n");

        sb.append("OFICINA: ").append(defaultText(usuario.getNomeOficina())).append("\n");
        sb.append("CNPJ: ").append(defaultText(usuario.getCnpjOficina())).append("\n");
        sb.append("ENDERECO: ").append(defaultText(montarEnderecoOficina(usuario))).append("\n");
        sb.append("TELEFONE: ").append(defaultText(usuario.getTelefone())).append("\n");
        sb.append("EMAIL: ").append(defaultText(usuario.getEmail())).append("\n");
        sb.append("SITE: ").append(defaultText(usuario.getSiteOficina())).append("\n\n");

        sb.append("----------------------------------------\n");
        sb.append("DADOS DA OS\n");
        sb.append("----------------------------------------\n");
        sb.append("OS: #").append(os.getId()).append("\n");
        sb.append("DATA: ").append(os.getCriadoEm() != null ? os.getCriadoEm().toLocalDate() : "-").append("\n");
        if (os.getConcluidoEm() != null) {
            sb.append("CONCLUIDO: ").append(os.getConcluidoEm().toLocalDate()).append("\n");
        }
        sb.append("STATUS: ").append(defaultText(os.getStatus())).append("\n\n");

        sb.append("----------------------------------------\n");
        sb.append("CLIENTE\n");
        sb.append("----------------------------------------\n");
        sb.append("NOME: ").append(defaultText(os.getClienteNome())).append("\n");
        sb.append("CPF: ").append(defaultText(os.getClienteCpf())).append("\n");
        sb.append("CNPJ: ").append(defaultText(os.getClienteCnpj())).append("\n");
        sb.append("TELEFONE: ").append(defaultText(os.getClienteTelefone())).append("\n\n");

        sb.append("----------------------------------------\n");
        sb.append("VEICULO\n");
        sb.append("----------------------------------------\n");
        sb.append("MODELO: ").append(defaultText(os.getModelo())).append("\n");
        sb.append("MONTADORA: ").append(defaultText(os.getMontadora())).append("\n");
        sb.append("PLACA: ").append(defaultText(os.getPlaca())).append("\n");
        sb.append("COR: ").append(defaultText(os.getCorVeiculo())).append("\n");
        sb.append("ANO: ").append(os.getAno() != null ? os.getAno() : "-").append("\n");
        sb.append("KM: ").append(os.getQuilometragem() != null ? os.getQuilometragem() : "-").append("\n\n");

        if (servicos != null && !servicos.isEmpty()) {
            sb.append("----------------------------------------\n");
            sb.append("SERVICOS\n");
            sb.append("----------------------------------------\n");
            for (ServicoOS servico : servicos) {
                sb.append("- ").append(defaultText(servico.getDescricao())).append("\n");
                sb.append("  Qtd: ").append(servico.getQuantidade())
                        .append(" x R$ ").append(String.format("%.2f", servico.getValorUnitario()))
                        .append(" = R$ ").append(String.format("%.2f", servico.getValorTotal()))
                        .append("\n");
            }
            sb.append("\n");
        }

        if (itens != null && !itens.isEmpty()) {
            sb.append("----------------------------------------\n");
            sb.append("PECAS\n");
            sb.append("----------------------------------------\n");
            for (ItemOS item : itens) {
                sb.append("- ").append(defaultText(item.getNomeItem())).append("\n");
                sb.append("  Qtd: ").append(item.getQuantidade())
                        .append(" x R$ ").append(String.format("%.2f", item.getValorUnitario()))
                        .append(" = R$ ").append(String.format("%.2f", item.getValorTotal()))
                        .append("\n");
            }
            sb.append("\n");
        }

        sb.append("----------------------------------------\n");
        sb.append("VALOR TOTAL: R$ ").append(String.format("%.2f", os.getValor() != null ? os.getValor() : 0)).append("\n");
        sb.append("========================================\n");
        sb.append("Obrigado pela preferencia.");
        return sb.toString();
    }

    private String montarEnderecoOficina(Usuario usuario) {
        StringBuilder endereco = new StringBuilder();

        if (usuario.getEnderecoLogradouro() != null && !usuario.getEnderecoLogradouro().isBlank()) {
            endereco.append(usuario.getEnderecoLogradouro().trim());
            if (usuario.getEnderecoNumero() != null && !usuario.getEnderecoNumero().isBlank()) {
                endereco.append(", ").append(usuario.getEnderecoNumero().trim());
            }
        }

        if (usuario.getEnderecoComplemento() != null && !usuario.getEnderecoComplemento().isBlank()) {
            if (!endereco.isEmpty()) endereco.append(" - ");
            endereco.append(usuario.getEnderecoComplemento().trim());
        }

        if (usuario.getEnderecoBairro() != null && !usuario.getEnderecoBairro().isBlank()) {
            if (!endereco.isEmpty()) endereco.append(" | ");
            endereco.append(usuario.getEnderecoBairro().trim());
        }

        if (usuario.getEnderecoCidade() != null && !usuario.getEnderecoCidade().isBlank()) {
            if (!endereco.isEmpty()) endereco.append(" | ");
            endereco.append(usuario.getEnderecoCidade().trim());
            if (usuario.getEnderecoEstado() != null && !usuario.getEnderecoEstado().isBlank()) {
                endereco.append(" - ").append(usuario.getEnderecoEstado().trim().toUpperCase());
            }
        }

        if (usuario.getEnderecoCep() != null && !usuario.getEnderecoCep().isBlank()) {
            if (!endereco.isEmpty()) endereco.append(" | ");
            endereco.append("CEP ").append(usuario.getEnderecoCep().trim());
        }

        return endereco.toString();
    }

    private String defaultText(String value) {
        return (value == null || value.isBlank()) ? "-" : value.trim();
    }

    static class EnviarReciboWhatsAppRequest {
        private String telefoneWhatsapp;

        public String getTelefoneWhatsapp() {
            return telefoneWhatsapp;
        }

        public void setTelefoneWhatsapp(String telefoneWhatsapp) {
            this.telefoneWhatsapp = telefoneWhatsapp;
        }
    }
}
