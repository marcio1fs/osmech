package com.osmech.payment.service;

import com.osmech.payment.dto.AssinaturaRequest;
import com.osmech.payment.dto.AssinaturaResponse;
import com.osmech.payment.entity.Assinatura;
import com.osmech.payment.entity.Pagamento;
import com.osmech.payment.repository.AssinaturaRepository;
import com.osmech.payment.repository.PagamentoRepository;
import com.osmech.plan.entity.Plano;
import com.osmech.plan.repository.PlanoRepository;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Serviço responsável pelas regras de negócio de Assinaturas.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AssinaturaService {

    private final AssinaturaRepository assinaturaRepository;
    private final PagamentoRepository pagamentoRepository;
    private final PlanoRepository planoRepository;
    private final UsuarioRepository usuarioRepository;

    /**
     * Cria ou atualiza uma assinatura para o usuário.
     * Se já existe assinatura ativa, faz upgrade/downgrade do plano.
     */
    @Transactional
    public AssinaturaResponse assinar(String emailUsuario, AssinaturaRequest request) {
        Usuario usuario = getUsuario(emailUsuario);
        Plano plano = planoRepository.findByCodigo(request.getPlanoCodigo())
                .orElseThrow(() -> new IllegalArgumentException("Plano não encontrado: " + request.getPlanoCodigo()));

        // Verifica se já tem assinatura ativa
        var assinaturaAtiva = assinaturaRepository
                .findByUsuarioIdAndStatusIn(usuario.getId(), List.of("ACTIVE", "PAST_DUE"));

        Assinatura assinatura;

        if (assinaturaAtiva.isPresent()) {
            // Upgrade/Downgrade: atualiza plano da assinatura existente
            assinatura = assinaturaAtiva.get();
            assinatura.setPlanoId(plano.getId());
            assinatura.setPlanoCodigo(plano.getCodigo());
            assinatura.setValorMensal(plano.getPreco());
            assinatura.setStatus("ACTIVE");
            log.info("Upgrade/Downgrade de plano para {} - usuário {}", plano.getCodigo(), usuario.getEmail());
        } else {
            // Nova assinatura
            assinatura = Assinatura.builder()
                    .usuarioId(usuario.getId())
                    .planoId(plano.getId())
                    .planoCodigo(plano.getCodigo())
                    .valorMensal(plano.getPreco())
                    .status("ACTIVE")
                    .dataInicio(LocalDate.now())
                    .proximaCobranca(LocalDate.now().plusMonths(1))
                    .build();
            log.info("Nova assinatura {} criada para usuário {}", plano.getCodigo(), usuario.getEmail());
        }

        assinatura = assinaturaRepository.save(assinatura);

        // Atualiza o plano do usuário
        usuario.setPlano(plano.getCodigo());
        usuario.setAtivo(true);
        usuarioRepository.save(usuario);

        // Cria pagamento inicial da assinatura
        Pagamento pagamento = Pagamento.builder()
                .usuarioId(usuario.getId())
                .tipo("ASSINATURA")
                .referenciaId(assinatura.getId())
                .descricao("Assinatura " + plano.getNome() + " - " + plano.getCodigo())
                .metodoPagamento(request.getMetodoPagamento())
                .valor(plano.getPreco())
                .status("PENDENTE")
                .build();
        pagamentoRepository.save(pagamento);

        return toResponse(assinatura, plano.getNome());
    }

    /**
     * Busca a assinatura ativa do usuário.
     */
    public AssinaturaResponse buscarAtiva(String emailUsuario) {
        Usuario usuario = getUsuario(emailUsuario);

        Assinatura assinatura = assinaturaRepository
                .findByUsuarioIdAndStatusIn(usuario.getId(), List.of("ACTIVE", "PAST_DUE", "SUSPENDED"))
                .or(() -> assinaturaRepository.findFirstByUsuarioIdOrderByCriadoEmDesc(usuario.getId()))
                .orElse(null);

        if (assinatura == null) {
            // Retorna assinatura "virtual" baseada no plano do usuário
            Plano plano = planoRepository.findByCodigo(usuario.getPlano()).orElse(null);
            return AssinaturaResponse.builder()
                    .usuarioId(usuario.getId())
                    .planoCodigo(usuario.getPlano())
                    .planoNome(plano != null ? plano.getNome() : usuario.getPlano())
                    .valorMensal(plano != null ? plano.getPreco() : java.math.BigDecimal.ZERO)
                    .status(usuario.getAtivo() ? "ACTIVE" : "SUSPENDED")
                    .build();
        }

        Plano plano = planoRepository.findByCodigo(assinatura.getPlanoCodigo()).orElse(null);
        return toResponse(assinatura, plano != null ? plano.getNome() : assinatura.getPlanoCodigo());
    }

    /**
     * Lista histórico de assinaturas do usuário.
     */
    public List<AssinaturaResponse> listarHistorico(String emailUsuario) {
        Usuario usuario = getUsuario(emailUsuario);
        return assinaturaRepository.findByUsuarioIdOrderByCriadoEmDesc(usuario.getId())
                .stream()
                .map(a -> {
                    Plano plano = planoRepository.findByCodigo(a.getPlanoCodigo()).orElse(null);
                    return toResponse(a, plano != null ? plano.getNome() : a.getPlanoCodigo());
                })
                .toList();
    }

    /**
     * Cancela a assinatura ativa.
     */
    @Transactional
    public AssinaturaResponse cancelar(String emailUsuario) {
        Usuario usuario = getUsuario(emailUsuario);

        Assinatura assinatura = assinaturaRepository
                .findByUsuarioIdAndStatusIn(usuario.getId(), List.of("ACTIVE", "PAST_DUE"))
                .orElseThrow(() -> new IllegalArgumentException("Nenhuma assinatura ativa encontrada"));

        assinatura.setStatus("CANCELED");
        assinatura.setDataCancelamento(LocalDate.now());
        assinatura = assinaturaRepository.save(assinatura);

        log.info("Assinatura cancelada para usuário {}", usuario.getEmail());

        Plano plano = planoRepository.findByCodigo(assinatura.getPlanoCodigo()).orElse(null);
        return toResponse(assinatura, plano != null ? plano.getNome() : assinatura.getPlanoCodigo());
    }

    /**
     * Verifica assinaturas vencidas e aplica regras de inadimplência.
     * Deve ser chamado por um scheduler ou manualmente.
     */
    @Transactional
    public void verificarInadimplencia() {
        LocalDate hoje = LocalDate.now();

        // Assinaturas ativas com cobrança vencida → marca como PAST_DUE
        List<Assinatura> vencidas = assinaturaRepository
                .findByStatusAndProximaCobrancaBefore("ACTIVE", hoje);
        for (Assinatura a : vencidas) {
            a.setStatus("PAST_DUE");
            assinaturaRepository.save(a);
            log.warn("Assinatura {} marcada como PAST_DUE (vencida em {})", a.getId(), a.getProximaCobranca());
        }

        // Assinaturas PAST_DUE com carência expirada → suspende
        List<Assinatura> pastDue = assinaturaRepository.findByStatus("PAST_DUE");
        for (Assinatura a : pastDue) {
            LocalDate limiteCarencia = a.getProximaCobranca().plusDays(a.getDiasCarencia());
            if (hoje.isAfter(limiteCarencia)) {
                a.setStatus("SUSPENDED");
                assinaturaRepository.save(a);

                // Desativa o usuário
                usuarioRepository.findById(a.getUsuarioId()).ifPresent(u -> {
                    u.setAtivo(false);
                    usuarioRepository.save(u);
                });

                log.warn("Assinatura {} SUSPENSA por inadimplência", a.getId());
            }
        }
    }

    /**
     * Verifica se o usuário está com a assinatura em dia.
     */
    public boolean isAssinaturaAtiva(String emailUsuario) {
        Usuario usuario = getUsuario(emailUsuario);
        return assinaturaRepository
                .findByUsuarioIdAndStatusIn(usuario.getId(), List.of("ACTIVE"))
                .isPresent() || usuario.getAtivo();
    }

    // --- Helpers ---

    private Usuario getUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado"));
    }

    private AssinaturaResponse toResponse(Assinatura a, String planoNome) {
        return AssinaturaResponse.builder()
                .id(a.getId())
                .usuarioId(a.getUsuarioId())
                .planoId(a.getPlanoId())
                .planoCodigo(a.getPlanoCodigo())
                .planoNome(planoNome)
                .valorMensal(a.getValorMensal())
                .status(a.getStatus())
                .dataInicio(a.getDataInicio())
                .proximaCobranca(a.getProximaCobranca())
                .dataCancelamento(a.getDataCancelamento())
                .diasCarencia(a.getDiasCarencia())
                .criadoEm(a.getCriadoEm())
                .atualizadoEm(a.getAtualizadoEm())
                .build();
    }
}
