package com.osmech.os.service;

import com.osmech.finance.service.FinanceiroService;
import com.osmech.os.dto.OrdemServicoRequest;
import com.osmech.os.dto.OrdemServicoResponse;
import com.osmech.os.entity.OrdemServico;
import com.osmech.os.entity.StatusOS;
import com.osmech.os.repository.OrdemServicoRepository;
import com.osmech.plan.entity.Plano;
import com.osmech.plan.repository.PlanoRepository;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Serviço responsável pelas regras de negócio das Ordens de Serviço.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class OrdemServicoService {

    private final OrdemServicoRepository osRepository;
    private final UsuarioRepository usuarioRepository;
    private final FinanceiroService financeiroService;
    private final PlanoRepository planoRepository;

    /**
     * Cria uma nova Ordem de Serviço.
     * Verifica limites do plano antes de criar.
     */
    @Transactional
    public OrdemServicoResponse criar(String emailUsuario, OrdemServicoRequest request) {
        Usuario usuario = getUsuario(emailUsuario);

        // Verificar limite do plano
        verificarLimitePlano(usuario);

        OrdemServico os = OrdemServico.builder()
                .usuarioId(usuario.getId())
                .clienteNome(request.getClienteNome())
                .clienteTelefone(request.getClienteTelefone())
                .placa(request.getPlaca().toUpperCase())
                .modelo(request.getModelo())
                .ano(request.getAno())
                .quilometragem(request.getQuilometragem())
                .descricao(request.getDescricao())
                .diagnostico(request.getDiagnostico())
                .pecas(request.getPecas())
                .valor(request.getValor())
                .status("ABERTA")
                .whatsappConsentimento(request.getWhatsappConsentimento() != null ? request.getWhatsappConsentimento() : false)
                .build();

        os = osRepository.save(os);
        return toResponse(os);
    }

    /**
     * Lista todas as OS do usuário logado.
     */
    public List<OrdemServicoResponse> listarPorUsuario(String emailUsuario) {
        Usuario usuario = getUsuario(emailUsuario);
        return osRepository.findByUsuarioIdOrderByCriadoEmDesc(usuario.getId())
                .stream()
                .map(this::toResponse)
                .toList();
    }

    /**
     * Busca uma OS por ID (validando que pertence ao usuário).
     */
    public OrdemServicoResponse buscarPorId(String emailUsuario, Long osId) {
        Usuario usuario = getUsuario(emailUsuario);
        OrdemServico os = osRepository.findById(osId)
                .orElseThrow(() -> new IllegalArgumentException("Ordem de Serviço não encontrada"));

        if (!os.getUsuarioId().equals(usuario.getId())) {
            throw new IllegalArgumentException("Acesso negado a esta Ordem de Serviço");
        }

        return toResponse(os);
    }

    /**
     * Atualiza uma OS existente.
     * Valida transições de status.
     */
    @Transactional
    public OrdemServicoResponse atualizar(String emailUsuario, Long osId, OrdemServicoRequest request) {
        Usuario usuario = getUsuario(emailUsuario);
        OrdemServico os = osRepository.findById(osId)
                .orElseThrow(() -> new IllegalArgumentException("Ordem de Serviço não encontrada"));

        if (!os.getUsuarioId().equals(usuario.getId())) {
            throw new IllegalArgumentException("Acesso negado a esta Ordem de Serviço");
        }

        // Captura status anterior para detectar mudança para CONCLUIDA
        String statusAnterior = os.getStatus();

        // Atualiza campos
        if (request.getClienteNome() != null) os.setClienteNome(request.getClienteNome());
        if (request.getClienteTelefone() != null) os.setClienteTelefone(request.getClienteTelefone());
        if (request.getPlaca() != null) os.setPlaca(request.getPlaca().toUpperCase());
        if (request.getModelo() != null) os.setModelo(request.getModelo());
        if (request.getAno() != null) os.setAno(request.getAno());
        if (request.getQuilometragem() != null) os.setQuilometragem(request.getQuilometragem());
        if (request.getDescricao() != null) os.setDescricao(request.getDescricao());
        if (request.getDiagnostico() != null) os.setDiagnostico(request.getDiagnostico());
        if (request.getPecas() != null) os.setPecas(request.getPecas());
        if (request.getValor() != null) os.setValor(request.getValor());
        if (request.getWhatsappConsentimento() != null) os.setWhatsappConsentimento(request.getWhatsappConsentimento());

        // Validação de transição de status
        if (request.getStatus() != null) {
            StatusOS novoStatus = StatusOS.fromString(request.getStatus());
            StatusOS statusAtual = StatusOS.fromString(statusAnterior);
            if (!statusAtual.podeTransicionarPara(novoStatus)) {
                throw new IllegalArgumentException(
                        "Transição de status inválida: " + statusAnterior + " → " + request.getStatus() +
                        ". Transições permitidas: " + getTransicoesPermitidas(statusAtual));
            }
            os.setStatus(novoStatus.name());
        }

        os = osRepository.save(os);

        // Auto-criar entrada financeira quando OS é concluída
        if ("CONCLUIDA".equals(os.getStatus()) && !"CONCLUIDA".equals(statusAnterior)
                && os.getValor() != null && os.getValor().signum() > 0) {
            try {
                financeiroService.criarEntradaOS(
                        os.getUsuarioId(), os.getId(), os.getValor(),
                        os.getClienteNome(), os.getPlaca());
                log.info("Entrada financeira criada automaticamente para OS #{}", os.getId());
            } catch (Exception e) {
                log.warn("Falha ao criar entrada financeira para OS #{}: {}", os.getId(), e.getMessage());
            }
        }

        return toResponse(os);
    }

    /**
     * Exclui uma OS.
     */
    public void excluir(String emailUsuario, Long osId) {
        Usuario usuario = getUsuario(emailUsuario);
        OrdemServico os = osRepository.findById(osId)
                .orElseThrow(() -> new IllegalArgumentException("Ordem de Serviço não encontrada"));

        if (!os.getUsuarioId().equals(usuario.getId())) {
            throw new IllegalArgumentException("Acesso negado a esta Ordem de Serviço");
        }

        osRepository.delete(os);
    }

    /**
     * Retorna estatísticas do dashboard.
     */
    public DashboardStats getDashboardStats(String emailUsuario) {
        Usuario usuario = getUsuario(emailUsuario);
        Long uid = usuario.getId();

        return new DashboardStats(
                osRepository.countByUsuarioId(uid),
                osRepository.countByUsuarioIdAndStatus(uid, "ABERTA"),
                osRepository.countByUsuarioIdAndStatus(uid, "EM_ANDAMENTO"),
                osRepository.countByUsuarioIdAndStatus(uid, "CONCLUIDA")
        );
    }

    // --- Helpers ---

    private Usuario getUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado"));
    }

    /**
     * Verifica se o usuário ainda pode criar OS dentro do limite do plano.
     */
    private void verificarLimitePlano(Usuario usuario) {
        Plano plano = planoRepository.findByCodigo(usuario.getPlano()).orElse(null);
        if (plano != null && plano.getLimiteOs() != null && plano.getLimiteOs() > 0) {
            // Contar OS do mês atual
            long totalOsMes = osRepository.countByUsuarioId(usuario.getId());
            if (totalOsMes >= plano.getLimiteOs()) {
                throw new IllegalArgumentException(
                        "Limite de " + plano.getLimiteOs() + " Ordens de Serviço do plano " +
                                plano.getNome() + " atingido. Faça upgrade do seu plano para continuar.");
            }
        }
    }

    /**
     * Retorna string com transições permitidas para um status.
     */
    private String getTransicoesPermitidas(StatusOS status) {
        StringBuilder sb = new StringBuilder();
        for (StatusOS s : StatusOS.values()) {
            if (status.podeTransicionarPara(s) && status != s) {
                if (!sb.isEmpty()) sb.append(", ");
                sb.append(s.name());
            }
        }
        return sb.isEmpty() ? "nenhuma (status final)" : sb.toString();
    }

    private OrdemServicoResponse toResponse(OrdemServico os) {
        return OrdemServicoResponse.builder()
                .id(os.getId())
                .clienteNome(os.getClienteNome())
                .clienteTelefone(os.getClienteTelefone())
                .placa(os.getPlaca())
                .modelo(os.getModelo())
                .ano(os.getAno())
                .quilometragem(os.getQuilometragem())
                .descricao(os.getDescricao())
                .diagnostico(os.getDiagnostico())
                .pecas(os.getPecas())
                .valor(os.getValor())
                .status(os.getStatus())
                .whatsappConsentimento(os.getWhatsappConsentimento())
                .criadoEm(os.getCriadoEm())
                .atualizadoEm(os.getAtualizadoEm())
                .concluidoEm(os.getConcluidoEm())
                .build();
    }

    /**
     * Record para estatísticas do dashboard.
     */
    public record DashboardStats(long total, long abertas, long emAndamento, long concluidas) {}
}
