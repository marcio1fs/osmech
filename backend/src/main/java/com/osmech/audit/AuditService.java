package com.osmech.audit;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Servico de auditoria para registrar operacoes sensiveis no sistema.
 * Inclui: alteracoes de assinatura, pagamentos, mudancas de plano, etc.
 * 
 * Os logs sao persistidos no banco de dados e tambem registrados no log.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AuditService {

    private final AuditLogRepository auditLogRepository;

    /**
     * Registra uma operacao de auditoria.
     * 
     * @param acao Tipo da acao (ex: ASSINATURA_CRIADA, PAGAMENTO_CONFIRMADO, USUARIO_LOGIN)
     * @param entidade Tipo de entidade afetada (ex: ASSINATURA, PAGAMENTO, USUARIO)
     * @param entidadeId ID da entidade
     * @param usuarioEmail Email do usuario que realizou a acao (pode ser null para acoes do sistema)
     * @param detalhes Detalhes adicionais em formato JSON
     */
    public void registrar(String acao, String entidade, Long entidadeId, String usuarioEmail, String detalhes) {
        String auditId = UUID.randomUUID().toString();
        
        try {
            // Persiste no banco de dados
            AuditLog auditLog = AuditLog.builder()
                    .auditId(auditId)
                    .acao(acao)
                    .entidade(entidade)
                    .entidadeId(entidadeId)
                    .usuarioEmail(usuarioEmail)
                    .detalhes(detalhes)
                    .criadoEm(LocalDateTime.now())
                    .build();
            
            auditLogRepository.save(auditLog);
            
            log.info("AUDIT[{}] acao={} entidade={} entidadeId={} usuario={} detalhes={}",
                    auditId, acao, entidade, entidadeId, usuarioEmail, detalhes);
        } catch (Exception e) {
            // Se falhar persistencia, ainda registra no log
            log.error("Falha ao persistir audit log: {}", e.getMessage());
            log.warn("AUDIT[FALLBACK] acao={} entidade={} entidadeId={} usuario={} detalhes={}",
                    acao, entidade, entidadeId, usuarioEmail, detalhes);
        }
    }

    // Metodos de conveniencia para operacoes comuns

    public void registrarAssinaturaCriada(Long assinaturaId, String usuarioEmail, String planoCodigo) {
        registrar("ASSINATURA_CRIADA", "ASSINATURA", assinaturaId, usuarioEmail, 
                "{\"plano\":\"" + planoCodigo + "\"}");
    }

    public void registrarAssinaturaAtivada(Long assinaturaId, String usuarioEmail, Long pagamentoId) {
        registrar("ASSINATURA_ATIVADA", "ASSINATURA", assinaturaId, usuarioEmail,
                "{\"pagamentoId\":" + pagamentoId + "}");
    }

    public void registrarAssinaturaCancelada(Long assinaturaId, String usuarioEmail) {
        registrar("ASSINATURA_CANCELADA", "ASSINATURA", assinaturaId, usuarioEmail, "{}");
    }

    public void registrarPagamentoConfirmado(Long pagamentoId, String usuarioEmail, String valor) {
        registrar("PAGAMENTO_CONFIRMADO", "PAGAMENTO", pagamentoId, usuarioEmail,
                "{\"valor\":\"" + valor + "\"}");
    }

    public void registrarPagamentoFalhou(Long pagamentoId, String usuarioEmail, String motivo) {
        registrar("PAGAMENTO_FALHOU", "PAGAMENTO", pagamentoId, usuarioEmail,
                "{\"motivo\":\"" + motivo + "\"}");
    }

    public void registrarPlanoAlterado(String usuarioEmail, String planoAnterior, String novoPlano) {
        registrar("PLANO_ALTERADO", "USUARIO", null, usuarioEmail,
                "{\"plano_anterior\":\"" + planoAnterior + "\",\"novo_plano\":\"" + novoPlano + "\"}");
    }

    public void registrarLogin(String usuarioEmail, boolean sucesso, String ip) {
        String acao = sucesso ? "LOGIN_SUCESSO" : "LOGIN_FALHA";
        registrar(acao, "USUARIO", null, usuarioEmail, "{\"ip\":\"" + ip + "\",\"sucesso\":" + sucesso + "}");
    }

    public void registrarLogout(String usuarioEmail) {
        registrar("LOGOUT", "USUARIO", null, usuarioEmail, "{}");
    }

    public void registrarTentativaLoginExcedida(String ip, String email) {
        registrar("LOGIN_TENTATIVAS_EXCEDIDAS", "USUARIO", null, email,
                "{\"ip\":\"" + ip + "\",\"motivo\":\"muitas_tentativas\"}");
    }
}
