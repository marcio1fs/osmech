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

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.text.NumberFormat;
import java.util.List;
import java.util.Locale;
import com.osmech.security.PapeisSeguranca;
import org.springframework.security.access.prepost.PreAuthorize;

@RestController
@RequestMapping("/os")
@PreAuthorize(PapeisSeguranca.MEMBROS_OFICINA)
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

        if (!os.getUsuarioId().equals(usuario.getOficinaId())) {
            throw new IllegalArgumentException("Acesso negado a esta Ordem de Servico");
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

    /**
     * GET /api/os/{id}/recibo
     * Retorna o texto do recibo da OS formatado (para reimpressão/visualização).
     */
    @GetMapping("/{id}/recibo")
    public ResponseEntity<?> obterRecibo(Authentication auth, @PathVariable Long id) {
        String email = auth.getName();
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Usuario nao encontrado"));

        OrdemServico os = osRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Ordem de Servico nao encontrada"));

        if (!os.getUsuarioId().equals(usuario.getOficinaId())) {
            throw new IllegalArgumentException("Acesso negado a esta Ordem de Servico");
        }

        List<ServicoOS> servicos = servicoOSRepository.findByOrdemServicoId(os.getId());
        List<ItemOS> itens = itemOSRepository.findByOrdemServicoId(os.getId());

        String recibo = montarReciboExtrato(usuario, os, servicos, itens);
        return ResponseEntity.ok(java.util.Map.of("recibo", recibo));
    }

    private String montarReciboExtrato(Usuario usuario, OrdemServico os,
                                       List<ServicoOS> servicos, List<ItemOS> itens) {
        NumberFormat moeda = NumberFormat.getCurrencyInstance(new Locale("pt", "BR"));
        StringBuilder sb = new StringBuilder();

        boolean isOrçamento = !"CONCLUIDA".equals(os.getStatus());
        sb.append("========================================\n");
        if (isOrçamento) {
            sb.append("          ORÇAMENTO - ORDEM DE SERVICO\n");
        } else {
            sb.append("            RECIBO - ORDEM DE SERVICO\n");
        }
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
                BigDecimal valorUnitario = servico.getValorUnitario() != null ? servico.getValorUnitario() : BigDecimal.ZERO;
                BigDecimal valorTotal = servico.getValorTotal() != null ? servico.getValorTotal() : BigDecimal.ZERO;
                sb.append("- ").append(defaultText(servico.getDescricao())).append("\n");
                sb.append("  Qtd: ").append(servico.getQuantidade())
                        .append(" x ").append(moeda.format(valorUnitario))
                        .append(" = ").append(moeda.format(valorTotal))
                        .append("\n");
            }
            sb.append("\n");
        }

        if (itens != null && !itens.isEmpty()) {
            sb.append("----------------------------------------\n");
            sb.append("PECAS\n");
            sb.append("----------------------------------------\n");
            for (ItemOS item : itens) {
                BigDecimal valorUnitario = item.getValorUnitario() != null ? item.getValorUnitario() : BigDecimal.ZERO;
                BigDecimal valorTotal = item.getValorTotal() != null ? item.getValorTotal() : BigDecimal.ZERO;
                sb.append("- ").append(defaultText(item.getNomeItem())).append("\n");
                sb.append("  Qtd: ").append(item.getQuantidade())
                        .append(" x ").append(moeda.format(valorUnitario))
                        .append(" = ").append(moeda.format(valorTotal))
                        .append("\n");
            }
            sb.append("\n");
        }

        BigDecimal totalServicos = somarServicos(servicos);
        BigDecimal totalPecas = somarItens(itens);
        BigDecimal valorBruto = os.getValor() != null ? os.getValor() : totalServicos.add(totalPecas);
        // Compatibilidade com modelo atual (modo local rápido)
        BigDecimal descontoPercentual = BigDecimal.ZERO;
        BigDecimal descontoValor = BigDecimal.ZERO;
        BigDecimal valorFinal = valorBruto;


        sb.append("----------------------------------------\n");
        sb.append("RESUMO FINANCEIRO\n");
        sb.append("----------------------------------------\n");
        sb.append("SERVICOS: ").append(moeda.format(totalServicos)).append("\n");
        sb.append("PECAS: ").append(moeda.format(totalPecas)).append("\n");
        sb.append("SUBTOTAL: ").append(moeda.format(valorBruto)).append("\n");
        if (descontoPercentual.compareTo(BigDecimal.ZERO) > 0) {
            sb.append("DESCONTO (")
                    .append(descontoPercentual.stripTrailingZeros().toPlainString())
                    .append("%): -")
                    .append(moeda.format(descontoValor))
                    .append("\n");
        }
        if (isOrçamento) {
            sb.append("TOTAL ESTIMADO: ").append(moeda.format(valorFinal)).append("\n");
        } else {
            sb.append("TOTAL RECEBIDO: ").append(moeda.format(valorFinal)).append("\n");
        }
        sb.append("========================================\n");
        if (isOrçamento) {
            sb.append("Este documento é apenas um orçamento preliminar.\n");
            sb.append("Valores sujeitos a alteração.\n");
        } else {
            sb.append("Obrigado pela preferencia.\n\n");
            sb.append("Agradecemos pela confiança e preferência!\n");
            sb.append("Seu veículo em boas mãos. Volte sempre!");
        }
        return sb.toString();
    }

    private BigDecimal somarServicos(List<ServicoOS> servicos) {
        if (servicos == null || servicos.isEmpty()) {
            return BigDecimal.ZERO;
        }
        return servicos.stream()
                .map(servico -> servico.getValorTotal() != null ? servico.getValorTotal() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private BigDecimal somarItens(List<ItemOS> itens) {
        if (itens == null || itens.isEmpty()) {
            return BigDecimal.ZERO;
        }
        return itens.stream()
                .map(item -> item.getValorTotal() != null ? item.getValorTotal() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
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
