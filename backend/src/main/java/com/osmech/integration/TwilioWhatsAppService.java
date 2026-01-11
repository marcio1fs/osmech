package com.osmech.integration;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Service;

import com.twilio.Twilio;
import com.twilio.rest.api.v2010.account.Message;

@Service
public class TwilioWhatsAppService implements WhatsAppService {
            @Autowired
            private WhatsAppLogRepository logRepository;
        @Autowired
        private Environment env;
        public String getTemplate(String key) {
            return env.getProperty("twilio.templates." + key, "");
        }

        public String interpolate(String template, String descricao, String status) {
            return template.replace("{{descricao}}", descricao).replace("{{status}}", status);
        }

        public void sendWhatsAppTemplate(String toNumber, String templateKey, String descricao, String status) {
            String template = getTemplate(templateKey);
            String body = interpolate(template, descricao, status);
            sendWhatsAppMessage(toNumber, body);
        }
    @Value("${twilio.account.sid}")
    private String accountSid;

    @Value("${twilio.auth.token}")
    private String authToken;

    @Value("${twilio.whatsapp.from}")
    private String fromNumber;

    @Override
    public void sendMessage(String toNumber, String message) {
        Twilio.init(accountSid, authToken);
        WhatsAppLog log = new WhatsAppLog();
        log.setTelefone(toNumber);
        log.setMensagem(message);
        try {
            Message.creator(
                new com.twilio.type.PhoneNumber("whatsapp:" + toNumber),
                new com.twilio.type.PhoneNumber("whatsapp:" + fromNumber),
                message
            ).create();
            log.setStatus("SUCESSO");
            log.setErro(null);
        } catch (Exception e) {
            log.setStatus("ERRO");
            log.setErro(e.getMessage());
        }
        logRepository.save(log);
    }

    public void sendWhatsAppMessage(String toNumber, String body) {
        sendMessage(toNumber, body);
    }
}
