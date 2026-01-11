package com.osmech.integration;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class WhatsAppReenvioService {
    @Autowired
    private WhatsAppLogRepository logRepository;
    @Autowired
    private WhatsAppService whatsAppService; // Alterado para usar a interface

    public int reenviarFalhas(int maxTentativas) {
        List<WhatsAppLog> falhas = logRepository.findByStatusAndTentativasLessThan("ERRO", maxTentativas);
        int reenviados = 0;
        for (WhatsAppLog log : falhas) {
            try {
                whatsAppService.sendMessage(log.getTelefone(), log.getMensagem());
                log.setStatus("SUCESSO");
                log.setErro(null);
                log.setReenviar(false);
                reenviados++;
            } catch (Exception e) {
                log.setTentativas(log.getTentativas() + 1);
                log.setErro(e.getMessage());
                log.setReenviar(log.getTentativas() < maxTentativas);
            }
            logRepository.save(log);
        }
        return reenviados;
    }
}
