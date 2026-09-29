package com.osmech.notification.service;


import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

/**
 * Serviço para envio de e-mails do sistema.
 */
@Service
@Slf4j
public class EmailService {


    // Em dev/local, podemos rodar sem SMTP/JavaMailSender.
    // Para isso, o bean pode ser ausente no contexto.
    @org.springframework.beans.factory.annotation.Autowired(required = false)
    private JavaMailSender mailSender;







    @Value("${spring.mail.username:noreply@osmech.com.br}")
    private String fromEmail;

    @Value("${app.frontend.url:https://www.osmech.com.br}")
    private String frontendUrl;

    @Value("${notification.email.enabled:false}")
    private boolean emailEnabled;

    public void enviarEmailRecuperacaoSenha(String to, String token) {
        if (!emailEnabled || mailSender == null) {
            log.warn("[EmailService] SMTP não configurado. Ignorando envio de recuperação para {}", to);
            return;
        }


        String subject = "Recuperação de Senha - OSMECH";
        String link = frontendUrl + "/reset-password?token=" + token;
        String message = "Olá,\n\nVocê solicitou a recuperação de senha da sua conta no OSMECH.\n" +
                "Clique no link abaixo para definir uma nova senha:\n\n" +
                link + "\n\n" +
                "Este link expira em 1 hora.\n\n" +
                "Se você não solicitou isso, ignore este e-mail.";

        enviarEmail(to, subject, message);
    }

    public void enviarEmailVerificacao(String to, String token) {
        if (!emailEnabled || mailSender == null) {
            log.warn("[EmailService] SMTP não configurado. Ignorando envio de verificação para {}", to);
            return;
        }

        String subject = "Verificação de E-mail - OSMECH";

        String link = frontendUrl + "/verify-email?token=" + token;
        String message = "Olá,\n\nObrigado por se cadastrar no OSMECH!\n" +
                "Para ativar sua conta e garantir que seu e-mail é real, clique no link abaixo:\n\n" +
                link + "\n\n" +
                "Se você não se cadastrou em nosso sistema, ignore este e-mail.";

        enviarEmail(to, subject, message);
    }

    public void enviarEmailConvite(String to, String nomeOficina, String papel, String token) {
        if (!emailEnabled || mailSender == null) {
            log.warn("[EmailService] SMTP não configurado. Ignorando envio de convite para {}", to);
            return;
        }

        String subject = "Convite para equipe - OSMECH";
        String link = frontendUrl + "/aceitar-convite?token=" + token;
        String message = "Olá,\n\nVocê foi convidado para entrar na equipe da oficina \"" + nomeOficina
                + "\" no OSMECH, com o papel " + papel + ".\n"
                + "Para aceitar o convite e criar o seu acesso, clique no link abaixo:\n\n"
                + link + "\n\n"
                + "Este convite expira em 7 dias.\n\n"
                + "Se você não esperava este convite, ignore este e-mail.";

        enviarEmail(to, subject, message);
    }

    private void enviarEmail(String to, String subject, String content) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(to);
            message.setSubject(subject);
            message.setText(content);
            mailSender.send(message);
            log.info("E-mail enviado com sucesso para: {}", to);
        } catch (Exception e) {
            log.error("Erro ao enviar e-mail para {}: {}", to, e.getMessage());
        }
    }
}
