package com.osmech.oficina.service;

import com.osmech.notification.service.WhatsAppService;
import com.osmech.oficina.dto.OficinaWhatsAppConfigDTO;
import com.osmech.oficina.entity.Oficina;
import com.osmech.oficina.repository.OficinaRepository;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class OficinaWhatsAppService {

    private final OficinaRepository oficinaRepository;
    private final UsuarioRepository usuarioRepository;
    private final WhatsAppService whatsAppService;

    @Transactional(readOnly = true)
    public OficinaWhatsAppConfigDTO obterConfiguracao(String emailUsuario) {
        Oficina oficina = getOficina(emailUsuario);

        boolean conectado = false;
        String statusDetalhe = "Desconectado ou credenciais não informadas";

        if (oficina.getZapiInstanceId() != null && !oficina.getZapiInstanceId().isBlank()
                && oficina.getZapiToken() != null && !oficina.getZapiToken().isBlank()) {
            Map<String, Object> status = whatsAppService.consultarStatusZApi(
                    oficina.getZapiInstanceId(), oficina.getZapiToken(), oficina.getZapiClientToken());
            if (Boolean.TRUE.equals(status.get("connected"))) {
                conectado = true;
                statusDetalhe = "Conectado ao WhatsApp";
            } else if (status.containsKey("error")) {
                statusDetalhe = "Erro: " + status.get("error");
            }
        }

        return OficinaWhatsAppConfigDTO.builder()
                .provider(oficina.getWhatsappProvider() != null ? oficina.getWhatsappProvider() : "ZAPI")
                .instanceId(oficina.getZapiInstanceId())
                .token(oficina.getZapiToken())
                .clientToken(oficina.getZapiClientToken())
                .ativo(Boolean.TRUE.equals(oficina.getWhatsappAtivo()))
                .connected(conectado)
                .statusDetalhe(statusDetalhe)
                .build();
    }

    @Transactional
    public OficinaWhatsAppConfigDTO salvarConfiguracao(String emailUsuario, OficinaWhatsAppConfigDTO dto) {
        Oficina oficina = getOficina(emailUsuario);

        if (dto.getProvider() != null && !dto.getProvider().isBlank()) {
            oficina.setWhatsappProvider(dto.getProvider().trim().toUpperCase());
        }
        oficina.setZapiInstanceId(dto.getInstanceId() != null ? dto.getInstanceId().trim() : null);
        oficina.setZapiToken(dto.getToken() != null ? dto.getToken().trim() : null);
        oficina.setZapiClientToken(dto.getClientToken() != null ? dto.getClientToken().trim() : null);
        oficina.setWhatsappAtivo(dto.getAtivo() != null ? dto.getAtivo() : false);

        oficinaRepository.save(oficina);
        log.info("Configuração WhatsApp Z-API atualizada para a oficina ID: {}", oficina.getId());

        return obterConfiguracao(emailUsuario);
    }

    public WhatsAppService.ResultadoEnvio testarEnvio(String emailUsuario, String telefoneDestino) {
        Oficina oficina = getOficina(emailUsuario);
        String mensagem = "Olá! Este é um teste de integração do WhatsApp com o sistema OSMECH para a oficina "
                + (oficina.getNome() != null ? oficina.getNome() : "") + ".";

        if (oficina.getZapiInstanceId() == null || oficina.getZapiToken() == null || oficina.getZapiClientToken() == null) {
            return new WhatsAppService.ResultadoEnvio(false, telefoneDestino, "Preencha todas as credenciais Z-API antes de testar.");
        }

        return whatsAppService.enviarViaZApi(
                oficina.getZapiInstanceId(),
                oficina.getZapiToken(),
                oficina.getZapiClientToken(),
                telefoneDestino,
                mensagem
        );
    }

    private Oficina getOficina(String emailUsuario) {
        Usuario usuario = usuarioRepository.findByEmail(emailUsuario)
                .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado: " + emailUsuario));
        return oficinaRepository.findById(usuario.getOficinaId())
                .orElseThrow(() -> new IllegalArgumentException("Oficina não encontrada para o usuário: " + emailUsuario));
    }
}
