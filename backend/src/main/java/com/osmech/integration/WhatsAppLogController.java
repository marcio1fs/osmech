package com.osmech.integration;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/whatsapp/logs")
@CrossOrigin
public class WhatsAppLogController {
    @Autowired
    private WhatsAppLogRepository logRepository;

    @GetMapping
    public List<WhatsAppLog> getAllLogs() {
        return logRepository.findAll();
    }
}
