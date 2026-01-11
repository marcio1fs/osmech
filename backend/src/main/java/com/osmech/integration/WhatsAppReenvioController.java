package com.osmech.integration;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/whatsapp/reenviar")
@CrossOrigin
public class WhatsAppReenvioController {
    @Autowired
    private WhatsAppReenvioService reenvioService;

    @PostMapping
    public String reenviar(@RequestParam(defaultValue = "3") int maxTentativas) {
        int total = reenvioService.reenviarFalhas(maxTentativas);
        return total + " mensagens reenviadas.";
    }
}
