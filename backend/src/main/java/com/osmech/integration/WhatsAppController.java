package com.osmech.integration;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/whatsapp")
public class WhatsAppController {
    @Autowired
    private WhatsAppService whatsAppService; // Alterado para usar a interface

    @PostMapping("/send")
    public ResponseEntity<String> sendWhatsApp(@RequestParam String to, @RequestParam String message) {
        try {
            whatsAppService.sendMessage(to, message);
            return ResponseEntity.ok("Mensagem enviada com sucesso!");
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Erro ao enviar mensagem: " + e.getMessage());
        }
    }
}
