package com.osmech.payment.service;

import com.mercadopago.resources.preference.Preference;
import com.osmech.config.ResourceNotFoundException;
import com.osmech.payment.dto.AssinaturaResponse;
import com.osmech.payment.entity.Assinatura;
import com.osmech.payment.entity.Pagamento;
import com.osmech.payment.entity.StatusPagamento;
import com.osmech.payment.repository.AssinaturaRepository;
import com.osmech.payment.repository.PagamentoRepository;
import com.osmech.plan.entity.Plano;
import com.osmech.plan.repository.PlanoRepository;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AssinaturaService {
    private static final String STATUS_ACTIVE = "ACTIVE";
    private static final String STATUS_PAST_DUE = "PAST_DUE";
    private static final String STATUS_SUSPENDED = "SUSPENDED";
    private static final String STATUS_PENDING = "PENDING";
    private static final String STATUS_CANCELED = "CANCELED";
    private static final String METODO_MERCADO_PAGO_CHECKOUT = "MERCADO_PAGO_CHECKOUT";

    private static final List<String> STATUS_ASSINATURA_EM_ABERTO = List.of(
            STATUS_ACTIVE, STATUS_PAST_DUE, STATUS_SUSPENDED, STATUS_PENDING
    );

    private final UsuarioRepository usuarioRepository;
    private final PlanoRepository planoRepository;
    private final AssinaturaRepository assinaturaRepository;
    private final PagamentoRepository pagamentoRepository;
    private final MercadoPagoService mercadoPagoService;

    @Transactional
    public AssinaturaResponse iniciarAssinatura(String email, String planoCodigo) {
        if (!StringUtils.hasText(planoCodigo)) {
            throw new IllegalArgumentException("planoCodigo e obrigatorio");
        }

        String planoCodigoNormalizado = planoCodigo.trim().toUpperCase();

        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario nao encontrado"));

        Plano plano = planoRepository.findByCodigo(planoCodigoNormalizado)
                .orElseThrow(() -> new ResourceNotFoundException("Plano nao encontrado: " + planoCodigoNormalizado));

        // Verificar se o plano está ativo
        if (!Boolean.TRUE.equals(plano.getAtivo())) {
            throw new IllegalArgumentException("Plano nao esta disponivel para assinatura");
        }

        Assinatura assinaturaPendente = assinaturaRepository
                .findFirstByUsuarioIdAndStatusOrderByCriadoEmDesc(usuario.getId(), STATUS_PENDING)
                .orElse(null);

        if (assinaturaPendente != null) {
            Pagamento pagamentoPendente = pagamentoRepository
                    .findFirstByUsuarioIdAndTipoAndReferenciaIdAndStatusOrderByCriadoEmDesc(
                            usuario.getId(), "ASSINATURA", assinaturaPendente.getId(), StatusPagamento.PENDENTE
                    )
                    .orElse(null);

            if (planoCodigoNormalizado.equals(assinaturaPendente.getPlanoCodigo())) {
                String preferenceId = pagamentoPendente != null ? pagamentoPendente.getTransacaoExternaId() : null;
                String checkoutUrl = mercadoPagoService.resolverCheckoutUrlPorPreferenciaId(preferenceId);
                if (checkoutUrl != null) {
                    return toResponse(assinaturaPendente, checkoutUrl, preferenceId);
                }
                throw new IllegalStateException(
                        "Ja existe um pagamento pendente para este plano. Aguarde a confirmacao ou cancele antes de tentar novamente."
                );
            }

            throw new IllegalStateException(
                    "Existe uma assinatura pendente em processamento para outro plano. Finalize ou cancele antes de iniciar nova assinatura."
            );
        }

        Assinatura assinatura = Assinatura.builder()
                .usuarioId(usuario.getId())
                .planoId(plano.getId())
                .planoCodigo(plano.getCodigo())
                .status(STATUS_PENDING)
                .valorMensal(plano.getPreco())  // Valor do plano - não pode ser alterado
                .dataInicio(LocalDate.now())
                .proximaCobranca(LocalDate.now().plusMonths(1))
                .build();

        assinatura = assinaturaRepository.save(assinatura);

        // VALIDAÇÃO DE SEGURANÇA: O valor deve ser exatamente o preço do plano
        // Nunca aceite valores da requisição - sempre use o valor do banco
        BigDecimal valorCobrado = plano.getPreco();
        
        // Verificação adicional: garantir que o valor é positivo e válido
        if (valorCobrado == null || valorCobrado.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalStateException("Preco do plano invalido");
        }

        Pagamento pagamento = Pagamento.builder()
                .usuarioId(usuario.getId())
                .tipo("ASSINATURA")
                .referenciaId(assinatura.getId())
                .descricao("Assinatura Plano " + plano.getNome())
                .metodoPagamento(METODO_MERCADO_PAGO_CHECKOUT)
                .valor(valorCobrado)  // Usa valor do plano - não da requisição
                .status(StatusPagamento.PENDENTE)
                .criadoEm(LocalDateTime.now())
                .build();

        pagamento = pagamentoRepository.save(pagamento);

        Preference preference = mercadoPagoService.criarPreferenciaAssinatura(usuario, plano, assinatura, pagamento);

        pagamento.setTransacaoExternaId(preference.getId());
        pagamentoRepository.save(pagamento);

        String checkoutUrl = mercadoPagoService.resolverCheckoutUrl(preference);
        return toResponse(assinatura, checkoutUrl, preference.getId());
    }

    @Transactional(readOnly = true)
    public AssinaturaResponse buscarAssinaturaAtiva(String email) {
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario nao encontrado"));

        Assinatura assinatura = assinaturaRepository
                .findByUsuarioIdAndStatusIn(usuario.getId(), STATUS_ASSINATURA_EM_ABERTO)
                .orElseGet(() -> assinaturaRepository.findFirstByUsuarioIdOrderByCriadoEmDesc(usuario.getId())
                        .orElseThrow(() -> new ResourceNotFoundException("Nenhuma assinatura encontrada")));

        return toResponse(assinatura);
    }

    @Transactional
    public AssinaturaResponse cancelarAssinatura(String email) {
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario nao encontrado"));

        Assinatura assinatura = assinaturaRepository
                .findByUsuarioIdAndStatusIn(usuario.getId(), STATUS_ASSINATURA_EM_ABERTO)
                .orElseThrow(() -> new ResourceNotFoundException("Assinatura ativa nao encontrada"));

        assinatura.setStatus(STATUS_CANCELED);
        assinatura.setDataCancelamento(LocalDate.now());
        assinatura = assinaturaRepository.save(assinatura);

        // Cancelar assinatura nao deve bloquear login da conta.
        usuario.setPlano("FREE");
        usuario.setAtivo(true);
        usuarioRepository.save(usuario);

        return toResponse(assinatura);
    }

    @Transactional(readOnly = true)
    public List<AssinaturaResponse> listarHistorico(String email) {
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario nao encontrado"));

        return assinaturaRepository.findByUsuarioIdOrderByCriadoEmDesc(usuario.getId())
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public boolean isAssinaturaAtiva(String email) {
        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario nao encontrado"));

        return assinaturaRepository.findByUsuarioIdAndStatusIn(usuario.getId(), List.of(STATUS_ACTIVE))
                .isPresent();
    }

    private AssinaturaResponse toResponse(Assinatura assinatura) {
        String planoCodigo = assinatura.getPlanoCodigo();
        String planoNome = StringUtils.hasText(planoCodigo)
                ? planoRepository.findByCodigo(planoCodigo)
                    .map(Plano::getNome)
                    .orElse(planoCodigo)
                : "PLANO_NAO_DEFINIDO";

        return AssinaturaResponse.builder()
                .id(assinatura.getId())
                .usuarioId(assinatura.getUsuarioId())
                .planoId(assinatura.getPlanoId())
                .planoCodigo(planoCodigo)
                .planoNome(planoNome)
                .valorMensal(assinatura.getValorMensal())
                .status(assinatura.getStatus())
                .dataInicio(assinatura.getDataInicio())
                .proximaCobranca(assinatura.getProximaCobranca())
                .dataCancelamento(assinatura.getDataCancelamento())
                .diasCarencia(assinatura.getDiasCarencia())
                .criadoEm(assinatura.getCriadoEm())
                .atualizadoEm(assinatura.getAtualizadoEm())
                .build();
    }

    private AssinaturaResponse toResponse(Assinatura assinatura, String checkoutUrl, String preferenceId) {
        String planoCodigo = assinatura.getPlanoCodigo();
        String planoNome = StringUtils.hasText(planoCodigo)
                ? planoRepository.findByCodigo(planoCodigo)
                    .map(Plano::getNome)
                    .orElse(planoCodigo)
                : "PLANO_NAO_DEFINIDO";

        return AssinaturaResponse.builder()
                .id(assinatura.getId())
                .usuarioId(assinatura.getUsuarioId())
                .planoId(assinatura.getPlanoId())
                .planoCodigo(planoCodigo)
                .planoNome(planoNome)
                .valorMensal(assinatura.getValorMensal())
                .status(assinatura.getStatus())
                .dataInicio(assinatura.getDataInicio())
                .proximaCobranca(assinatura.getProximaCobranca())
                .dataCancelamento(assinatura.getDataCancelamento())
                .diasCarencia(assinatura.getDiasCarencia())
                .criadoEm(assinatura.getCriadoEm())
                .atualizadoEm(assinatura.getAtualizadoEm())
                .checkoutUrl(checkoutUrl)
                .preferenceId(preferenceId)
                .build();
    }
}
