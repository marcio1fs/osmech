package com.osmech.os.service;

import com.osmech.auditoria.entity.LogAuditoria;
import com.osmech.auditoria.service.AuditoriaService;
import com.osmech.config.ResourceNotFoundException;
import com.osmech.finance.dto.TransacaoRequest;
import com.osmech.finance.dto.TransacaoResponse;
import com.osmech.finance.repository.TransacaoFinanceiraRepository;
import com.osmech.finance.service.FinanceiroService;
import com.osmech.mecanico.entity.Mecanico;
import com.osmech.mecanico.repository.MecanicoRepository;
import com.osmech.notification.service.WhatsAppService;
import com.osmech.oficina.entity.Oficina;
import com.osmech.oficina.repository.OficinaRepository;
import com.osmech.os.dto.*;
import com.osmech.os.entity.ItemOS;
import com.osmech.os.entity.OrdemServico;
import com.osmech.os.entity.ServicoOS;
import com.osmech.os.entity.StatusOS;
import com.osmech.os.repository.ItemOSRepository;
import com.osmech.os.repository.OrdemServicoRepository;
import com.osmech.os.repository.ServicoOSRepository;
import com.osmech.plan.entity.Plano;
import com.osmech.plan.repository.PlanoRepository;
import com.osmech.security.SecurityContextHelper;
import com.osmech.stock.entity.StockItem;
import com.osmech.stock.repository.StockItemRepository;
import com.osmech.stock.service.StockService;
import com.osmech.stock.dto.StockMovementRequest;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.text.NumberFormat;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

/**
 * Serviço responsável pelas regras de negócio das Ordens de Serviço.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class OrdemServicoService {

    private final OrdemServicoRepository osRepository;
    private final UsuarioRepository usuarioRepository;
    private final OficinaRepository oficinaRepository;
    private final FinanceiroService financeiroService;
    private final PlanoRepository planoRepository;
    private final ServicoOSRepository servicoOSRepository;
    private final ItemOSRepository itemOSRepository;
    private final MecanicoRepository mecanicoRepository;
    private final StockItemRepository stockItemRepository;
    private final StockService stockService;
    private final TransacaoFinanceiraRepository transacaoFinanceiraRepository;
    private final WhatsAppService whatsAppService;
    private final SecurityContextHelper securityContextHelper;
    private final AuditoriaService auditoriaService;

    /**
     * Cria uma nova Ordem de Serviço.
     * Suporta múltiplos serviços e itens de estoque.
     * Verifica limites do plano antes de criar.
     */
    @Transactional
    public OrdemServicoResponse criar(String emailUsuario, OrdemServicoRequest request) {
        Usuario usuario = getUsuario(emailUsuario);
        String placaNormalizada = normalizarPlaca(request.getPlaca());
        String clienteCpf = normalizarDocumento(request.getClienteCpf(), 11);
        String clienteCnpj = normalizarDocumento(request.getClienteCnpj(), 14);

        // Verificar limite do plano
        verificarLimitePlano(usuario);

        // Validar campo obrigatório placa
        if (placaNormalizada == null || placaNormalizada.isBlank()) {
            throw new IllegalArgumentException("Placa é obrigatória");
        }

        // Gerar descrição a partir dos serviços se não fornecida diretamente
        String descricao = request.getDescricao();
        if ((descricao == null || descricao.isBlank()) && request.getServicos() != null && !request.getServicos().isEmpty()) {
            descricao = request.getServicos().stream()
                    .map(ServicoOSRequest::getDescricao)
                    .collect(Collectors.joining("; "));
        }
        if (descricao == null || descricao.isBlank()) {
            descricao = "Serviço";
        }

        // Garante sequência única e concorrente por oficina
        oficinaRepository.findByIdForUpdate(usuario.getOficinaId());
        Long proximoNumero = osRepository.findMaxNumeroByUsuarioId(usuario.getOficinaId()) + 1L;

        OrdemServico os = OrdemServico.builder()
                .usuarioId(usuario.getOficinaId())
                .numero(proximoNumero)
                .clienteNome(request.getClienteNome())
                .clienteCpf(clienteCpf)
                .clienteCnpj(clienteCnpj)
                .clienteTelefone(request.getClienteTelefone())
                .placa(placaNormalizada)
                .modelo(request.getModelo())
                .montadora(request.getMontadora())
                .corVeiculo(request.getCorVeiculo())
                .ano(request.getAno())
                .quilometragem(request.getQuilometragem())
                .descricao(descricao)
                .diagnostico(request.getDiagnostico())
                .mecanicoResponsavel(resolverMecanicoResponsavel(request.getMecanicoResponsavel(), usuario))
                .pecas(request.getPecas())
                .valor(request.getValor() != null ? request.getValor() : BigDecimal.ZERO)
                .descontoPercentual(BigDecimal.ZERO)
                .valorFinal(request.getValor() != null ? request.getValor() : BigDecimal.ZERO)
                .status("ABERTA")
                .whatsappConsentimento(request.getWhatsappConsentimento() != null ? request.getWhatsappConsentimento() : false)
                .build();

        os = osRepository.save(os);

        // Salvar serviços
        List<ServicoOS> servicos = salvarServicos(os, request.getServicos());

        // Salvar itens de estoque e dar baixa no estoque
        List<ItemOS> itens = salvarItens(os, request.getItens(), usuario.getOficinaId());

        // Recalcular valor total se tem serviços ou itens
        recalcularValorTotal(os, servicos, itens);

        Long numOS = os.getNumero() != null ? os.getNumero() : os.getId();
        auditoriaService.registrar(usuario, LogAuditoria.OS_CRIADA,
                String.format("OS os%02d criada para %s (Placa: %s, Total: R$ %s)",
                        numOS, os.getClienteNome(), os.getPlaca(), os.getValorFinal()));

        return toResponse(os, servicos, itens);
    }

    /**
     * Lista todas as OS do usuário logado.
     */
    @Transactional(readOnly = true)
    public List<OrdemServicoResponse> listarPorUsuario(String emailUsuario) {
        Usuario usuario = getUsuario(emailUsuario);
        return osRepository.findByUsuarioIdOrderByCriadoEmDesc(usuario.getOficinaId())
                .stream()
                .map(os -> {
                    try {
                        List<ServicoOS> servicos = servicoOSRepository.findByOrdemServicoId(os.getId());
                        List<ItemOS> itens = itemOSRepository.findByOrdemServicoId(os.getId());
                        return toResponse(os, servicos, itens);
                    } catch (Exception e) {
                        log.warn("Falha ao carregar relacionamentos da OS #{} para o usuario {}. Retornando dados basicos. Motivo: {}",
                                os.getId(), usuario.getOficinaId(), e.getMessage());
                        return toResponse(os, List.of(), List.of());
                    }
                })
                .toList();
    }

    /**
     * Busca uma OS por ID (validando que pertence ao usuário).
     */
    @Transactional(readOnly = true)
    public OrdemServicoResponse buscarPorId(String emailUsuario, Long osId) {
        Usuario usuario = getUsuario(emailUsuario);
        OrdemServico os = osRepository.findById(osId)
                .orElseThrow(() -> new ResourceNotFoundException("Ordem de Serviço não encontrada"));

        if (!os.getUsuarioId().equals(usuario.getOficinaId())) {
            throw new AccessDeniedException("Acesso negado a esta Ordem de Serviço");
        }

        List<ServicoOS> servicos = servicoOSRepository.findByOrdemServicoId(os.getId());
        List<ItemOS> itens = itemOSRepository.findByOrdemServicoId(os.getId());
        return toResponse(os, servicos, itens);
    }

    /**
     * Atualiza uma OS existente.
     * Valida transições de status.
     * Reconcilia serviços e itens de estoque.
     */
    @Transactional
    public OrdemServicoResponse atualizar(String emailUsuario, Long osId, OrdemServicoRequest request) {
        Usuario usuario = getUsuario(emailUsuario);
        OrdemServico os = osRepository.findById(osId)
                .orElseThrow(() -> new ResourceNotFoundException("Ordem de Serviço não encontrada"));

        if (!os.getUsuarioId().equals(usuario.getOficinaId())) {
            throw new AccessDeniedException("Acesso negado a esta Ordem de Serviço");
        }

        // Captura status anterior para detectar mudança para CONCLUIDA
        String statusAnterior = os.getStatus();
        String placaNormalizada = normalizarPlaca(request.getPlaca());
        String clienteCpf = normalizarDocumento(request.getClienteCpf(), 11);
        String clienteCnpj = normalizarDocumento(request.getClienteCnpj(), 14);

        // Atualiza campos básicos
        if (request.getClienteNome() != null) os.setClienteNome(request.getClienteNome());
        if (request.getClienteCpf() != null) os.setClienteCpf(clienteCpf);
        if (request.getClienteCnpj() != null) os.setClienteCnpj(clienteCnpj);
        if (request.getClienteTelefone() != null) os.setClienteTelefone(request.getClienteTelefone());
        if (request.getPlaca() != null && placaNormalizada != null && !placaNormalizada.isBlank()) {
            os.setPlaca(placaNormalizada);
        }
        if (request.getModelo() != null) os.setModelo(request.getModelo());
        if (request.getMontadora() != null) os.setMontadora(request.getMontadora());
        if (request.getCorVeiculo() != null) os.setCorVeiculo(request.getCorVeiculo());
        if (request.getAno() != null) os.setAno(request.getAno());
        if (request.getQuilometragem() != null) os.setQuilometragem(request.getQuilometragem());
        if (request.getDescricao() != null) os.setDescricao(request.getDescricao());
        if (request.getDiagnostico() != null) os.setDiagnostico(request.getDiagnostico());
        if (request.getMecanicoResponsavel() != null) {
            os.setMecanicoResponsavel(resolverMecanicoResponsavel(request.getMecanicoResponsavel(), usuario));
        }
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

        // Reconciliar serviços (remove antigos, insere novos)
        List<ServicoOS> servicos;
        if (request.getServicos() != null) {
            // Remover serviços antigos
            servicoOSRepository.deleteByOrdemServicoId(os.getId());
            servicoOSRepository.flush();
            // Salvar novos
            servicos = salvarServicos(os, request.getServicos());

            // Atualizar descrição a partir dos serviços
            if (!servicos.isEmpty()) {
                os.setDescricao(servicos.stream()
                        .map(ServicoOS::getDescricao)
                        .collect(Collectors.joining("; ")));
            }
        } else {
            servicos = servicoOSRepository.findByOrdemServicoId(os.getId());
        }

        // Reconciliar itens de estoque
        List<ItemOS> itens;
        if (request.getItens() != null) {
            // Devolver itens antigos ao estoque
            List<ItemOS> itensAntigos = itemOSRepository.findByOrdemServicoId(os.getId());
            devolverItensEstoque(itensAntigos, usuario.getOficinaId(), os.getId());

            // Remover itens antigos
            itemOSRepository.deleteByOrdemServicoId(os.getId());
            itemOSRepository.flush();

            // Salvar novos itens e dar baixa no estoque
            itens = salvarItens(os, request.getItens(), usuario.getOficinaId());
        } else {
            itens = itemOSRepository.findByOrdemServicoId(os.getId());
        }

        // Recalcular valor total
        recalcularValorTotal(os, servicos, itens);

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

        return toResponse(os, servicos, itens);
    }

    /**
     * Encerra a OS, registra recebimento com metodo de pagamento e envia recibo por WhatsApp.
     */
    @Transactional
    public EncerrarOsResponse encerrar(String emailUsuario, Long osId, EncerrarOsRequest request) {
        Usuario usuario = getUsuario(emailUsuario);
        OrdemServico os = osRepository.findById(osId)
                .orElseThrow(() -> new ResourceNotFoundException("Ordem de Servico nao encontrada"));

        if (!os.getUsuarioId().equals(usuario.getOficinaId())) {
            throw new AccessDeniedException("Acesso negado a esta Ordem de Servico");
        }
        if ("CONCLUIDA".equalsIgnoreCase(os.getStatus())) {
            throw new IllegalArgumentException("OS ja esta encerrada");
        }
        if ("CANCELADA".equalsIgnoreCase(os.getStatus())) {
            throw new IllegalArgumentException("OS cancelada nao pode ser encerrada");
        }

        // Calcula desconto (0–10%)
        BigDecimal descontoPerc = request.getDescontoPercentual() != null
                ? request.getDescontoPercentual().min(BigDecimal.TEN).max(BigDecimal.ZERO)
                : BigDecimal.ZERO;
        BigDecimal valorOriginal = os.getValor() != null ? os.getValor() : BigDecimal.ZERO;
        BigDecimal valorDesconto = valorOriginal.multiply(descontoPerc)
                .divide(BigDecimal.valueOf(100), 2, java.math.RoundingMode.HALF_UP);
        BigDecimal valorFinal = valorOriginal.subtract(valorDesconto);

        os.setStatus("CONCLUIDA");
        os.setDescontoPercentual(descontoPerc);
        os.setValorFinal(valorFinal);
        os = osRepository.save(os);

        List<ServicoOS> servicos = servicoOSRepository.findByOrdemServicoId(os.getId());
        List<ItemOS> itens = itemOSRepository.findByOrdemServicoId(os.getId());

        String metodoPagamento = request.getMetodoPagamento();
        if (metodoPagamento == null || metodoPagamento.isBlank()) {
            throw new IllegalArgumentException("Método de pagamento é obrigatório para encerrar a OS");
        }
        metodoPagamento = metodoPagamento.trim().toUpperCase();
        TransacaoResponse transacao = null;

        boolean jaTemTransacaoOs = transacaoFinanceiraRepository
                .existsByUsuarioIdAndReferenciaTipoAndReferenciaIdAndEstornoFalse(usuario.getOficinaId(), "OS", os.getId());

        Long numRaw = os.getNumero() != null ? os.getNumero() : os.getId();
        String numFormatado = (numRaw != null && numRaw >= 0 && numRaw < 10)
                ? String.format("os%02d", numRaw)
                : (numRaw != null ? "os" + numRaw : "os--");

        if (!jaTemTransacaoOs && valorFinal.signum() > 0) {
            TransacaoRequest transacaoRequest = new TransacaoRequest();
            transacaoRequest.setTipo("ENTRADA");
            String descricao = "Recebimento " + numFormatado + " - " + os.getClienteNome();
            if (descontoPerc.signum() > 0) {
                descricao += " (desconto " + descontoPerc.stripTrailingZeros().toPlainString() + "%)";
            }
            transacaoRequest.setDescricao(descricao);
            transacaoRequest.setValor(valorFinal);
            transacaoRequest.setReferenciaTipo("OS");
            transacaoRequest.setReferenciaId(os.getId());
            transacaoRequest.setMetodoPagamento(metodoPagamento);
            transacaoRequest.setObservacoes(request.getObservacoesPagamento());
            transacao = financeiroService.criarTransacao(emailUsuario, transacaoRequest);
        } else if (jaTemTransacaoOs) {
            List<com.osmech.finance.entity.TransacaoFinanceira> transacoesExistentes = transacaoFinanceiraRepository
                    .findByUsuarioIdAndReferenciaTipoAndReferenciaId(usuario.getOficinaId(), "OS", os.getId());
            for (com.osmech.finance.entity.TransacaoFinanceira tf : transacoesExistentes) {
                if (!Boolean.TRUE.equals(tf.getEstorno())) {
                    tf.setValor(valorFinal);
                    tf.setMetodoPagamento(metodoPagamento);
                    String descricao = "Recebimento " + numFormatado + " - " + os.getClienteNome();
                    if (descontoPerc.signum() > 0) {
                        descricao += " (desconto " + descontoPerc.stripTrailingZeros().toPlainString() + "%)";
                    }
                    tf.setDescricao(descricao);
                    if (request.getObservacoesPagamento() != null) {
                        tf.setObservacoes(request.getObservacoesPagamento());
                    }
                    transacaoFinanceiraRepository.save(tf);
                    financeiroService.atualizarFluxoCaixa(usuario.getOficinaId(), tf.getDataMovimentacao().toLocalDate());
                }
            }
        }

        String recibo = montarReciboExtrato(usuario, os, servicos, itens, metodoPagamento, transacao);

        boolean enviarWhatsapp = request.getEnviarReciboWhatsapp() == null || request.getEnviarReciboWhatsapp();
        boolean whatsappEnviado = false;
        String whatsappDestino = null;
        String whatsappDetalhe = "Envio nao solicitado";

        if (enviarWhatsapp) {
            whatsappDestino = request.getTelefoneWhatsapp() != null && !request.getTelefoneWhatsapp().isBlank()
                    ? request.getTelefoneWhatsapp()
                    : os.getClienteTelefone();

            if (whatsappDestino == null || whatsappDestino.isBlank()) {
                whatsappDetalhe = "Telefone do cliente nao informado";
            } else {
                com.osmech.oficina.entity.Oficina oficina = usuario.getOficinaId() != null
                        ? oficinaRepository.findById(usuario.getOficinaId()).orElse(null)
                        : null;
                WhatsAppService.ResultadoEnvio resultado = whatsAppService.enviarMensagem(oficina, whatsappDestino, recibo);
                whatsappEnviado = resultado.enviado();
                whatsappDestino = resultado.destino();
                whatsappDetalhe = resultado.detalhe();
            }
        }

        auditoriaService.registrar(usuario, LogAuditoria.OS_ENCERRADA,
                String.format("OS %s encerrada. Valor final: R$ %s, Pagamento: %s",
                        numFormatado, valorFinal, metodoPagamento));

        return EncerrarOsResponse.builder()
                .os(toResponse(os, servicos, itens))
                .metodoPagamento(metodoPagamento)
                .transacaoFinanceiraId(transacao != null ? transacao.getId() : null)
                .recibo(recibo)
                .whatsappEnviado(whatsappEnviado)
                .whatsappDestino(whatsappDestino)
                .whatsappDetalhe(whatsappDetalhe)
                .descontoPercentual(descontoPerc)
                .valorDesconto(valorDesconto)
                .valorFinal(valorFinal)
                .build();
    }

    /**
     * Exclui uma OS.
     * Devolve itens de estoque ao estoque antes de excluir.
     */
    @Transactional
    public void excluir(String emailUsuario, Long osId) {
        Usuario usuario = getUsuario(emailUsuario);
        OrdemServico os = osRepository.findById(osId)
                .orElseThrow(() -> new ResourceNotFoundException("Ordem de Serviço não encontrada"));

        if (!os.getUsuarioId().equals(usuario.getOficinaId())) {
            throw new AccessDeniedException("Acesso negado a esta Ordem de Serviço");
        }

        // Devolver itens de estoque
        List<ItemOS> itens = itemOSRepository.findByOrdemServicoId(osId);
        devolverItensEstoque(itens, usuario.getOficinaId(), osId);

        // Limpar serviços e itens (cascade delete)
        servicoOSRepository.deleteByOrdemServicoId(osId);
        itemOSRepository.deleteByOrdemServicoId(osId);

        Long numOS = os.getNumero() != null ? os.getNumero() : os.getId();
        auditoriaService.registrar(usuario, LogAuditoria.OS_EXCLUIDA,
                String.format("OS os%02d de %s (Placa %s, Valor R$ %s) foi excluída do sistema",
                        numOS, os.getClienteNome(), os.getPlaca(), os.getValorFinal()));

        osRepository.delete(os);
    }

    /**
     * Atualiza apenas o status de uma Ordem de Serviço.
     */
    @Transactional
    public OrdemServicoResponse atualizarStatus(String emailUsuario, Long osId, String novoStatus) {
        Usuario usuario = getUsuario(emailUsuario);
        OrdemServico os = osRepository.findById(osId)
                .orElseThrow(() -> new ResourceNotFoundException("Ordem de Serviço não encontrada"));

        if (!os.getUsuarioId().equals(usuario.getOficinaId())) {
            throw new AccessDeniedException("Acesso negado a esta Ordem de Serviço");
        }

        // Validação de transição de status
        StatusOS statusAtual = StatusOS.fromString(os.getStatus());
        StatusOS novoStatusEnum = StatusOS.fromString(novoStatus);
        
        if (!statusAtual.podeTransicionarPara(novoStatusEnum)) {
            throw new IllegalArgumentException(
                    "Transição de status inválida: " + os.getStatus() + " → " + novoStatus +
                    ". Transições permitidas: " + getTransicoesPermitidas(statusAtual));
        }
        
        String statusAntigo = os.getStatus();
        os.setStatus(novoStatusEnum.name());
        os.setAtualizadoEm(LocalDateTime.now());
        
        osRepository.save(os);

        Long numOS = os.getNumero() != null ? os.getNumero() : os.getId();
        auditoriaService.registrar(usuario, LogAuditoria.OS_STATUS_ALTERADO,
                String.format("OS os%02d: status alterado de %s para %s", numOS, statusAntigo, novoStatusEnum.name()));
        
        return toResponse(os, 
                servicoOSRepository.findByOrdemServicoId(osId),
                itemOSRepository.findByOrdemServicoId(osId));
    }

    /**
     * Retorna estatísticas do dashboard.
     */
    @Transactional(readOnly = true)
    public DashboardStats getDashboardStats(String emailUsuario) {
        Usuario usuario = getUsuario(emailUsuario);
        Long uid = usuario.getOficinaId();

        // Contagens mensais
        YearMonth mesAtual = YearMonth.now();
        LocalDateTime inicioMes = mesAtual.atDay(1).atStartOfDay();
        LocalDateTime fimMes = mesAtual.atEndOfMonth().atTime(LocalTime.MAX);

        return new DashboardStats(
                osRepository.countByUsuarioId(uid),
                osRepository.countByUsuarioIdAndStatus(uid, "ABERTA"),
                osRepository.countByUsuarioIdAndStatus(uid, "EM_ANDAMENTO"),
                osRepository.countByUsuarioIdAndStatus(uid, "CONCLUIDA"),
                osRepository.countByUsuarioIdAndCriadoEmBetween(uid, inicioMes, fimMes),
                osRepository.countByUsuarioIdAndStatus(uid, "AGUARDANDO_PECA"),
                osRepository.countByUsuarioIdAndStatus(uid, "AGUARDANDO_APROVACAO"),
                osRepository.countByUsuarioIdAndStatus(uid, "CANCELADA"),
                osRepository.countByUsuarioIdAndCriadoEmBetween(uid,
                        LocalDate.now().atStartOfDay(),
                        LocalDate.now().atTime(LocalTime.MAX))
        );
    }

    // --- Helpers ---

    /**
     * Retorna o usuário correspondente ao email autenticado.
     * Para sub-usuários (ATENDENTE, MECANICO etc), retorna o usuário dono da oficina,
     * garantindo que os dados corretos sejam acessados.
     */
    private Usuario getUsuario(String email) {
        Long dataOwnerId = securityContextHelper.getDataOwnerId(email);
        return usuarioRepository.findById(dataOwnerId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));
    }

    /**
     * Verifica se o usuário ainda pode criar OS dentro do limite do plano.
     * Conta apenas as OS do mês atual.
     */
    private void verificarLimitePlano(Usuario usuario) {
        // Fonte autoritativa do plano é a OFICINA (tenant), desde a Fase 1
        String planoCodigo = oficinaRepository.findById(usuario.getOficinaId())
                .map(Oficina::getPlano)
                .orElse(usuario.getPlano());
        Plano plano = planoRepository.findByCodigo(planoCodigo).orElse(null);
        if (plano != null && plano.getLimiteOs() != null && plano.getLimiteOs() > 0) {
            // Contar OS do mês atual
            YearMonth mesAtual = YearMonth.now();
            LocalDateTime inicioMes = mesAtual.atDay(1).atStartOfDay();
            LocalDateTime fimMes = mesAtual.atEndOfMonth().atTime(LocalTime.MAX);
            long totalOsMes = osRepository.countByUsuarioIdAndCriadoEmBetween(
                    usuario.getOficinaId(), inicioMes, fimMes);
            if (totalOsMes >= plano.getLimiteOs()) {
                throw new IllegalArgumentException(
                        "Limite de " + plano.getLimiteOs() + " Ordens de Serviço do plano " +
                                plano.getNome() + " atingido neste mês. Faça upgrade do seu plano para continuar.");
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

    private OrdemServicoResponse toResponse(OrdemServico os, List<ServicoOS> servicos, List<ItemOS> itens) {
        List<ServicoOSResponse> servicoResponses = servicos != null ? servicos.stream()
                .map(s -> ServicoOSResponse.builder()
                        .id(s.getId())
                        .descricao(s.getDescricao())
                        .quantidade(s.getQuantidade())
                        .valorUnitario(s.getValorUnitario())
                        .valorTotal(s.getValorTotal())
                        .mecanicoId(s.getMecanicoId())
                        .mecanicoNome(s.getMecanicoNome())
                        .percentualComissao(s.getPercentualComissao())
                        .valorComissao(s.getValorComissao())
                        .build())
                .toList() : List.of();

        List<ItemOSResponse> itemResponses = itens != null ? itens.stream()
                .map(i -> ItemOSResponse.builder()
                        .id(i.getId())
                        .stockItemId(i.getStockItemId())
                        .nomeItem(i.getNomeItem())
                        .codigoItem(i.getCodigoItem())
                        .quantidade(i.getQuantidade())
                        .valorUnitario(i.getValorUnitario())
                        .valorTotal(i.getValorTotal())
                        .build())
                .toList() : List.of();

        return OrdemServicoResponse.builder()
                .id(os.getId())
                .numero(os.getNumero() != null ? os.getNumero() : os.getId())
                .clienteNome(os.getClienteNome())
                .clienteCpf(os.getClienteCpf())
                .clienteCnpj(os.getClienteCnpj())
                .clienteTelefone(os.getClienteTelefone())
                .placa(os.getPlaca())
                .modelo(os.getModelo())
                .montadora(os.getMontadora())
                .corVeiculo(os.getCorVeiculo())
                .ano(os.getAno())
                .quilometragem(os.getQuilometragem())
                .descricao(os.getDescricao())
                .diagnostico(os.getDiagnostico())
                .mecanicoResponsavel(os.getMecanicoResponsavel())
                .pecas(os.getPecas())
                .valor(os.getValor())
                .descontoPercentual(os.getDescontoPercentual())
                .valorFinal(os.getValorFinal())
                .status(os.getStatus())
                .whatsappConsentimento(os.getWhatsappConsentimento())
                .criadoEm(os.getCriadoEm())
                .atualizadoEm(os.getAtualizadoEm())
                .concluidoEm(os.getConcluidoEm())
                .servicos(servicoResponses)
                .itens(itemResponses)
                .build();
    }

    private String montarReciboExtrato(Usuario usuario, OrdemServico os,
                                       List<ServicoOS> servicos, List<ItemOS> itens,
                                       String metodoPagamento, TransacaoResponse transacao) {
        NumberFormat moeda = NumberFormat.getCurrencyInstance(new Locale("pt", "BR"));
        String oficinaNome = usuario.getNomeOficina() != null && !usuario.getNomeOficina().isBlank()
                ? usuario.getNomeOficina()
                : usuario.getNome();
        String dataHora = LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm"));
        StringBuilder sb = new StringBuilder();

        sb.append("RECIBO / EXTRATO DE PAGAMENTO - OSMECH").append("\n");
        sb.append("====================================").append("\n");
        sb.append("OFICINA: ").append(oficinaNome).append("\n");
        sb.append("CNPJ OFICINA: ").append(defaultText(usuario.getCnpjOficina())).append("\n");
        sb.append("RESPONSÁVEL: ").append(usuario.getNome()).append("\n");
        sb.append("EMAIL: ").append(usuario.getEmail()).append("\n");
        sb.append("TELEFONE: ").append(usuario.getTelefone()).append("\n");
        sb.append("ENDEREÇO: ").append(defaultText(montarEnderecoOficina(usuario))).append("\n");
        sb.append("SITE: ").append(defaultText(usuario.getSiteOficina())).append("\n");
        sb.append("------------------------------------").append("\n");
        sb.append("CLIENTE: ").append(defaultText(os.getClienteNome())).append("\n");
        sb.append("CPF: ").append(defaultText(os.getClienteCpf())).append("\n");
        sb.append("CNPJ: ").append(defaultText(os.getClienteCnpj())).append("\n");
        sb.append("TEL CLIENTE: ").append(defaultText(os.getClienteTelefone())).append("\n");
        sb.append("VEÍCULO: ").append(defaultText(os.getModelo())).append("\n");
        sb.append("MONTADORA: ").append(defaultText(os.getMontadora())).append("\n");
        sb.append("COR: ").append(defaultText(os.getCorVeiculo())).append("\n");
        sb.append("PLACA: ").append(defaultText(os.getPlaca())).append("\n");
        sb.append("ANO: ").append(os.getAno() != null ? os.getAno() : "-").append("\n");
        sb.append("KM: ").append(os.getQuilometragem() != null ? os.getQuilometragem() : "-").append("\n");
        sb.append("------------------------------------").append("\n");
        sb.append("LANÇAMENTOS (SERVIÇOS)").append("\n");

        BigDecimal totalServicos = BigDecimal.ZERO;
        if (servicos != null && !servicos.isEmpty()) {
            for (ServicoOS servico : servicos) {
                BigDecimal total = servico.getValorTotal() != null ? servico.getValorTotal() : BigDecimal.ZERO;
                totalServicos = totalServicos.add(total);
                sb.append("+ ").append(defaultText(servico.getDescricao()))
                        .append(" | QTD ").append(servico.getQuantidade() != null ? servico.getQuantidade() : 1)
                        .append(" | ").append(moeda.format(total))
                        .append("\n");
            }
        } else {
            sb.append("+ ").append(defaultText(os.getDescricao())).append("\n");
        }

        sb.append("LANÇAMENTOS (PEÇAS)").append("\n");
        BigDecimal totalPecas = BigDecimal.ZERO;
        if (itens != null && !itens.isEmpty()) {
            for (ItemOS item : itens) {
                BigDecimal total = item.getValorTotal() != null ? item.getValorTotal() : BigDecimal.ZERO;
                totalPecas = totalPecas.add(total);
                sb.append("+ ").append(defaultText(item.getNomeItem()))
                        .append(" | QTD ").append(item.getQuantidade() != null ? item.getQuantidade() : 1)
                        .append(" | ").append(moeda.format(total))
                        .append("\n");
            }
        } else {
            sb.append("+ ").append(defaultText(os.getPecas())).append("\n");
        }

        BigDecimal valorTotal = os.getValor() != null ? os.getValor() : totalServicos.add(totalPecas);

        sb.append("------------------------------------").append("\n");
        sb.append("RESUMO FINANCEIRO").append("\n");
        sb.append("SERVIÇOS: ").append(moeda.format(totalServicos)).append("\n");
        sb.append("PEÇAS: ").append(moeda.format(totalPecas)).append("\n");
        sb.append("VALOR TOTAL: ").append(moeda.format(valorTotal)).append("\n");

        BigDecimal descPerc = os.getDescontoPercentual() != null ? os.getDescontoPercentual() : BigDecimal.ZERO;
        if (descPerc.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal valorDesconto = valorTotal.multiply(descPerc)
                    .divide(BigDecimal.valueOf(100), 2, java.math.RoundingMode.HALF_UP);
            BigDecimal valorFinal = valorTotal.subtract(valorDesconto);
            sb.append("DESCONTO (").append(descPerc.stripTrailingZeros().toPlainString()).append("%): -").append(moeda.format(valorDesconto)).append("\n");
            sb.append("TOTAL RECEBIDO: ").append(moeda.format(valorFinal)).append("\n");
        } else {
            sb.append("TOTAL RECEBIDO: ").append(moeda.format(valorTotal)).append("\n");
        }
        sb.append("MÉTODO: ").append(defaultText(metodoPagamento)).append("\n");
        Long osNumVal = os.getNumero() != null ? os.getNumero() : os.getId();
        String osNumStr = (osNumVal != null && osNumVal >= 0 && osNumVal < 10)
                ? String.format("os%02d", osNumVal)
                : (osNumVal != null ? "os" + osNumVal : "os--");
        sb.append("OS: ").append(osNumStr).append("\n");
        if (transacao != null) {
            sb.append("TRANSAÇÃO: #").append(transacao.getId()).append("\n");
        }
        sb.append("STATUS OS: ").append(defaultText(os.getStatus())).append("\n");
        sb.append("DATA/HORA: ").append(dataHora).append("\n");
        sb.append("====================================").append("\n");
        sb.append("Comprovante gerado automaticamente.\n\n");
        sb.append("Agradecemos pela confiança e preferência!\n");
        sb.append("Seu veículo em boas mãos. Volte sempre!");

        return sb.toString();
    }

    private String defaultText(String value) {
        return (value == null || value.isBlank()) ? "-" : value.trim();
    }

    private String resolverMecanicoResponsavel(String mecanicoResponsavel, Usuario usuario) {
        if (mecanicoResponsavel != null && !mecanicoResponsavel.isBlank()) {
            return mecanicoResponsavel.trim();
        }
        return usuario.getNome();
    }

    private Mecanico resolverMecanicoServico(Long usuarioId, Long mecanicoId) {
        if (mecanicoId == null) {
            return null;
        }

        Mecanico mecanico = mecanicoRepository.findById(mecanicoId)
                .orElseThrow(() -> new ResourceNotFoundException("Mecanico nao encontrado: " + mecanicoId));

        if (!mecanico.getUsuarioId().equals(usuarioId)) {
            throw new AccessDeniedException("Mecanico nao pertence a esta oficina");
        }

        if (!Boolean.TRUE.equals(mecanico.getAtivo())) {
            throw new IllegalArgumentException("Mecanico inativo nao pode receber comissao");
        }

        return mecanico;
    }

    private BigDecimal resolverPercentualComissao(ServicoOSRequest request, Mecanico mecanico) {
        if (request.getPercentualComissao() != null) {
            return request.getPercentualComissao();
        }
        if (mecanico != null && mecanico.getPercentualComissao() != null) {
            return mecanico.getPercentualComissao();
        }
        return BigDecimal.ZERO;
    }

    private String montarEnderecoOficina(Usuario usuario) {
        List<String> partes = new ArrayList<>();
        String logradouro = defaultText(usuario.getEnderecoLogradouro());
        String numero = defaultText(usuario.getEnderecoNumero());
        if (!"-".equals(logradouro)) {
            if (!"-".equals(numero)) {
                partes.add(logradouro + ", " + numero);
            } else {
                partes.add(logradouro);
            }
        }

        String complemento = defaultText(usuario.getEnderecoComplemento());
        if (!"-".equals(complemento)) partes.add(complemento);

        String bairro = defaultText(usuario.getEnderecoBairro());
        if (!"-".equals(bairro)) partes.add(bairro);

        String cidade = defaultText(usuario.getEnderecoCidade());
        String estado = defaultText(usuario.getEnderecoEstado());
        if (!"-".equals(cidade) || !"-".equals(estado)) {
            if (!"-".equals(cidade) && !"-".equals(estado)) {
                partes.add(cidade + " - " + estado);
            } else if (!"-".equals(cidade)) {
                partes.add(cidade);
            } else {
                partes.add(estado);
            }
        }

        String cep = defaultText(usuario.getEnderecoCep());
        if (!"-".equals(cep)) partes.add("CEP " + cep);

        if (partes.isEmpty()) return "-";
        return String.join(" | ", partes);
    }

    /**
     * Salva os serviços da OS.
     */
    private List<ServicoOS> salvarServicos(OrdemServico os, List<ServicoOSRequest> servicoRequests) {
        if (servicoRequests == null || servicoRequests.isEmpty()) {
            return List.of();
        }

        List<ServicoOS> servicos = new ArrayList<>();
        for (ServicoOSRequest req : servicoRequests) {
            Mecanico mecanico = resolverMecanicoServico(os.getUsuarioId(), req.getMecanicoId());
            BigDecimal percentualComissao = resolverPercentualComissao(req, mecanico);
            ServicoOS servico = ServicoOS.builder()
                    .ordemServico(os)
                    .descricao(req.getDescricao())
                    .quantidade(req.getQuantidade())
                    .valorUnitario(req.getValorUnitario())
                    .mecanicoId(mecanico != null ? mecanico.getId() : null)
                    .mecanicoNome(mecanico != null ? mecanico.getNome() : null)
                    .percentualComissao(percentualComissao)
                    .build();
            servico.calcularTotal();
            servicos.add(servicoOSRepository.save(servico));
        }
        return servicos;
    }

    /**
     * Salva os itens de estoque da OS e dá baixa no estoque.
     */
    private List<ItemOS> salvarItens(OrdemServico os, List<ItemOSRequest> itemRequests, Long usuarioId) {
        if (itemRequests == null || itemRequests.isEmpty()) {
            return List.of();
        }

        List<ItemOS> itens = new ArrayList<>();
        List<StockMovementRequest> movimentacoes = new ArrayList<>();

        for (ItemOSRequest req : itemRequests) {
            StockItem stockItem = stockItemRepository.findById(req.getStockItemId())
                    .orElseThrow(() -> new ResourceNotFoundException("Item de estoque não encontrado: " + req.getStockItemId()));

            if (!stockItem.getUsuarioId().equals(usuarioId)) {
                throw new AccessDeniedException("Item de estoque não pertence a esta oficina");
            }
            if (!stockItem.getAtivo()) {
                throw new IllegalArgumentException("Item de estoque está desativado: " + stockItem.getNome());
            }
            if (stockItem.getQuantidade() < req.getQuantidade()) {
                throw new IllegalArgumentException(
                        "Estoque insuficiente para " + stockItem.getNome() +
                        ". Disponível: " + stockItem.getQuantidade() +
                        ", solicitado: " + req.getQuantidade());
            }

            // Usar preço de venda se valor não informado
            BigDecimal valorUnit = req.getValorUnitario() != null ? req.getValorUnitario() : stockItem.getPrecoVenda();

            ItemOS itemOS = ItemOS.builder()
                    .ordemServico(os)
                    .stockItemId(stockItem.getId())
                    .nomeItem(stockItem.getNome())
                    .codigoItem(stockItem.getCodigo())
                    .quantidade(req.getQuantidade())
                    .valorUnitario(valorUnit)
                    .build();
            itemOS.calcularTotal();
            itens.add(itemOSRepository.save(itemOS));

            // Preparar movimentação de saída
            StockMovementRequest movReq = StockMovementRequest.builder()
                    .stockItemId(stockItem.getId())
                    .tipo("SAIDA")
                    .quantidade(req.getQuantidade())
                    .motivo("OS")
                    .descricao("Baixa automática - OS #" + os.getId())
                    .ordemServicoId(os.getId())
                    .build();
            movimentacoes.add(movReq);
        }

        // Dar baixa no estoque
        if (!movimentacoes.isEmpty()) {
            stockService.darBaixaOS(usuarioId, os.getId(), movimentacoes);
        }

        return itens;
    }

    /**
     * Devolve itens de estoque ao estoque (quando OS é editada ou excluída).
     */
    private void devolverItensEstoque(List<ItemOS> itens, Long usuarioId, Long osId) {
        if (itens == null || itens.isEmpty()) return;

        for (ItemOS item : itens) {
            try {
                StockItem stockItem = stockItemRepository.findById(item.getStockItemId()).orElse(null);
                if (stockItem != null && stockItem.getUsuarioId().equals(usuarioId) && stockItem.getAtivo()) {
                    int qtdAnterior = stockItem.getQuantidade();
                    stockItem.setQuantidade(qtdAnterior + item.getQuantidade());
                    stockItemRepository.save(stockItem);
                    log.info("Devolvido ao estoque: {} x{} (OS #{})",
                            stockItem.getCodigo(), item.getQuantidade(), osId);
                }
            } catch (Exception e) {
                log.warn("Falha ao devolver item {} ao estoque (OS #{}): {}",
                        item.getStockItemId(), osId, e.getMessage());
            }
        }
    }

    /**
     * Recalcula o valor total da OS com base nos serviços e itens.
     */
    private void recalcularValorTotal(OrdemServico os, List<ServicoOS> servicos, List<ItemOS> itens) {
        boolean hasServicos = servicos != null && !servicos.isEmpty();
        boolean hasItens = itens != null && !itens.isEmpty();

        if (hasServicos || hasItens) {
            BigDecimal totalServicos = hasServicos ?
                    servicos.stream().map(ServicoOS::getValorTotal).reduce(BigDecimal.ZERO, BigDecimal::add)
                    : BigDecimal.ZERO;
            BigDecimal totalItens = hasItens ?
                    itens.stream().map(ItemOS::getValorTotal).reduce(BigDecimal.ZERO, BigDecimal::add)
                    : BigDecimal.ZERO;
            BigDecimal total = totalServicos.add(totalItens);
            os.setValor(total);

            // Recalcular valor final com base no desconto
            BigDecimal descontoPerc = os.getDescontoPercentual() != null ? os.getDescontoPercentual() : BigDecimal.ZERO;
            BigDecimal valorDesconto = total.multiply(descontoPerc)
                    .divide(BigDecimal.valueOf(100), 2, java.math.RoundingMode.HALF_UP);
            os.setValorFinal(total.subtract(valorDesconto));

            // Atualizar campo pecas com resumo dos itens
            if (hasItens) {
                os.setPecas(itens.stream()
                        .map(i -> i.getNomeItem() + " x" + i.getQuantidade())
                        .collect(Collectors.joining(", ")));
            }

            osRepository.save(os);
        }
    }

    /**
     * Record para estatísticas do dashboard.
     */
    public record DashboardStats(
        long total,
        long abertas,
        long emAndamento,
        long concluidas,
        long esteMes,
        long aguardandoPeca,
        long aguardandoAprovacao,
        long canceladas,
        long concluidasHoje
    ) {}

    private String normalizarDocumento(String documento, int tamanhoEsperado) {
        if (documento == null) {
            return null;
        }

        String digits = documento.replaceAll("\\D", "");
        if (digits.isBlank()) {
            return null;
        }

        return digits.length() == tamanhoEsperado ? digits : documento.trim();
    }

    private String normalizarPlaca(String placa) {
        if (placa == null) {
            return null;
        }

        String normalizada = placa.replaceAll("[^A-Za-z0-9]", "").toUpperCase().trim();
        return normalizada.isBlank() ? null : normalizada;
    }
}
