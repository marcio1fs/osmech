package com.osmech.oficina.controller;

import com.osmech.notification.service.WhatsAppService;
import com.osmech.oficina.dto.OficinaWhatsAppConfigDTO;
import com.osmech.oficina.service.OficinaWhatsAppService;
import com.osmech.security.PapeisSeguranca;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/oficina/whatsapp")
@RequiredArgsConstructor
public class OficinaWhatsAppController {

    private final OficinaWhatsAppService oficinaWhatsAppService;

    /** GET /api/oficina/whatsapp - Obter credenciais e status de conexão Z-API */
    @GetMapping
    @PreAuthorize(PapeisSeguranca.MEMBROS_OFICINA)
    public ResponseEntity<OficinaWhatsAppConfigDTO> obterConfiguracao(Authentication auth) {
        return ResponseEntity.ok(oficinaWhatsAppService.obterConfiguracao(auth.getName()));
    }

    /** PUT /api/oficina/whatsapp - Salvar credenciais Z-API */
    @PutMapping
    @PreAuthorize(PapeisSeguranca.GESTORES)
    public ResponseEntity<OficinaWhatsAppConfigDTO> salvarConfiguracao(
            Authentication auth,
            @RequestBody OficinaWhatsAppConfigDTO dto) {
        return ResponseEntity.ok(oficinaWhatsAppService.salvarConfiguracao(auth.getName(), dto));
    }

    /** POST /api/oficina/whatsapp/testar - Disparar mensagem de teste */
    @PostMapping("/testar")
    @PreAuthorize(PapeisSeguranca.GESTORES)
    public ResponseEntity<WhatsAppService.ResultadoEnvio> testarEnvio(
            Authentication auth,
            @RequestBody Map<String, String> request) {
        String telefone = request.get("telefone");
        if (telefone == null || telefone.isBlank()) {
            return ResponseEntity.badRequest().body(
                    new WhatsAppService.ResultadoEnvio(false, "", "Telefone de destino é obrigatório"));
        }
        return ResponseEntity.ok(oficinaWhatsAppService.testarEnvio(auth.getName(), telefone));
    }
}
