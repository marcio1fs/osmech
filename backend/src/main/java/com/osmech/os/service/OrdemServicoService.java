package com.osmech.os.service;

import com.osmech.config.ResourceNotFoundException;
import com.osmech.finance.dto.TransacaoRequest;
import com.osmech.finance.dto.TransacaoResponse;
import com.osmech.finance.repository.TransacaoFinanceiraRepository;
import com.osmech.finance.service.FinanceiroService;
import com.osmech.notification.service.WhatsAppService;
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
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
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
    private final FinanceiroService financeiroService;
    private final PlanoRepository planoRepository;
    private final ServicoOSRepository servicoOSRepository;
    private final ItemOSRepository itemOSRepository;
    private final StockItemRepository stockItemRepository;
    private final StockService stockService;
    private final TransacaoFinanceiraRepository transacaoFinanceiraRepository;
    private final WhatsAppService whatsAppService;

    /**
     * Cria uma nova Ordem de Serviço.
     * Suporta múltiplos serviços e itens de estoque.
     * Verifica limites do plano antes de criar.
     */
    @Transactional
    public OrdemServicoResponse criar(String emailUsuario, OrdemServicoRequest request) {
        Usuario usuario = getUsuario(emailUsuario);

        // Verificar limite do plano
        verificarLimitePlano(usuario);

        // Validar campo obrigatório placa
        if (request.getPlaca() == null || request.getPlaca().isBlank()) {
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

        OrdemServico os = OrdemServico.builder()
                .usuarioId(usuario.getId())
                .clienteNome(request.getClienteNome())
                .clienteCpf(request.getClienteCpf())
                .clienteCnpj(request.getClienteCnpj())
                .clienteTelefone(request.getClienteTelefone())
                .placa(request.getPlaca().toUpperCase())
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
                .status("ABERTA")
                .whatsappConsentimento(request.getWhatsappConsentimento() != null ? request.getWhatsappConsentimento() : false)
                .build();

        os = osRepository.save(os);

        // Salvar serviços
        List<ServicoOS> servicos = salvarServicos(os, request.getServicos());

        // Salvar itens de estoque e dar baixa no estoque
        List<ItemOS> itens = salvarItens(os, request.getItens(), usuario.getId());

        // Recalcular valor total se tem serviços ou itens
        recalcularValorTotal(os, servicos, itens);

        return toResponse(os, servicos, itens);
    }

    /**
     * Lista todas as OS do usuário logado.
     */
    @Transactional(readOnly = true)
    public List<OrdemServicoResponse> listarPorUsuario(String emailUsuario) {
        Usuario usuario = getUsuario(emailUsuario);
        return osRepository.findByUsuarioIdOrderByCriadoEmDesc(usuario.getId())
                .stream()
                .map(os -> {
                    List<ServicoOS> servicos = servicoOSRepository.findByOrdemServicoId(os.getId());
                    List<ItemOS> itens = itemOSRepository.findByOrdemServicoId(os.getId());
                    return toResponse(os, servicos, itens);
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

        if (!os.getUsuarioId().equals(usuario.getId())) {
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

        if (!os.getUsuarioId().equals(usuario.getId())) {
            throw new AccessDeniedException("Acesso negado a esta Ordem de Serviço");
        }

        // Captura status anterior para detectar mudança para CONCLUIDA
        String statusAnterior = os.getStatus();

        // Atualiza campos básicos
        if (request.getClienteNome() != null) os.setClienteNome(request.getClienteNome());
        if (request.getClienteCpf() != null) os.setClienteCpf(request.getClienteCpf());
        if (request.getClienteCnpj() != null) os.setClienteCnpj(request.getClienteCnpj());
        if (request.getClienteTelefone() != null) os.setClienteTelefone(request.getClienteTelefone());
        if (request.getPlaca() != null) os.setPlaca(request.getPlaca().toUpperCase());
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
            devolverItensEstoque(itensAntigos, usuario.getId(), os.getId());

            // Remover itens antigos
            itemOSRepository.deleteByOrdemServicoId(os.getId());
            itemOSRepository.flush();

            // Salvar novos itens e dar baixa no estoque
            itens = salvarItens(os, request.getItens(), usuario.getId());
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

        if (!os.getUsuarioId().equals(usuario.getId())) {
            throw new AccessDeniedException("Acesso negado a esta Ordem de Servico");
        }
        if ("CONCLUIDA".equalsIgnoreCase(os.getStatus())) {
            throw new IllegalArgumentException("OS ja esta encerrada");
        }
        if ("CANCELADA".equalsIgnoreCase(os.getStatus())) {
            throw new IllegalArgumentException("OS cancelada nao pode ser encerrada");
        }

        os.setStatus("CONCLUIDA");
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
                .existsByUsuarioIdAndReferenciaTipoAndReferenciaIdAndEstornoFalse(usuario.getId(), "OS", os.getId());

        if (!jaTemTransacaoOs && os.getValor() != null && os.getValor().signum() > 0) {
            TransacaoRequest transacaoRequest = new TransacaoRequest();
            transacaoRequest.setTipo("ENTRADA");
            transacaoRequest.setDescricao("Recebimento OS #" + os.getId() + " - " + os.getClienteNome());
            transacaoRequest.setValor(os.getValor());
            transacaoRequest.setReferenciaTipo("OS");
            transacaoRequest.setReferenciaId(os.getId());
            transacaoRequest.setMetodoPagamento(metodoPagamento);
            transacaoRequest.setObservacoes(request.getObservacoesPagamento());
            transacao = financeiroService.criarTransacao(emailUsuario, transacaoRequest);
        }

        String recibo = montarReciboExtrato(usuario, os, servicos, itens, metodoPagamento, transacao);

        boolean enviarWhatsapp = request.getEnviarReciboWhatsapp() == null || request.getEnviarReciboWhatsapp();
        boolean whatsappEnviado = false;
        String whatsappDestino = null;
        String whatsappDetalhe = "Envio nao solicitado";

        if (enviarWhatsapp) {
            if (!Boolean.TRUE.equals(os.getWhatsappConsentimento())) {
                whatsappDetalhe = "Cliente sem consentimento de WhatsApp nesta OS";
            } else {
                whatsappDestino = request.getTelefoneWhatsapp() != null && !request.getTelefoneWhatsapp().isBlank()
                        ? request.getTelefoneWhatsapp()
                        : os.getClienteTelefone();

                if (whatsappDestino == null || whatsappDestino.isBlank()) {
                    whatsappDetalhe = "Telefone do cliente nao informado";
                } else {
                    WhatsAppService.ResultadoEnvio resultado = whatsAppService.enviarMensagem(whatsappDestino, recibo);
                    whatsappEnviado = resultado.enviado();
                    whatsappDestino = resultado.destino();
                    whatsappDetalhe = resultado.detalhe();
                }
            }
        }

        return EncerrarOsResponse.builder()
                .os(toResponse(os, servicos, itens))
                .metodoPagamento(metodoPagamento)
                .transacaoFinanceiraId(transacao != null ? transacao.getId() : null)
                .recibo(recibo)
                .whatsappEnviado(whatsappEnviado)
                .whatsappDestino(whatsappDestino)
                .whatsappDetalhe(whatsappDetalhe)
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

        if (!os.getUsuarioId().equals(usuario.getId())) {
            throw new AccessDeniedException("Acesso negado a esta Ordem de Serviço");
        }

        // Devolver itens de estoque
        List<ItemOS> itens = itemOSRepository.findByOrdemServicoId(osId);
        devolverItensEstoque(itens, usuario.getId(), osId);

        // Limpar serviços e itens (cascade delete)
        servicoOSRepository.deleteByOrdemServicoId(osId);
        itemOSRepository.deleteByOrdemServicoId(osId);

        osRepository.delete(os);
    }

    /**
     * Retorna estatísticas do dashboard.
     */
    @Transactional(readOnly = true)
    public DashboardStats getDashboardStats(String emailUsuario) {
        Usuario usuario = getUsuario(emailUsuario);
        Long uid = usuario.getId();

        // Contagens mensais
        YearMonth mesAtual = YearMonth.now();
        LocalDateTime inicioMes = mesAtual.atDay(1).atStartOfDay();
        LocalDateTime fimMes = mesAtual.atEndOfMonth().atTime(LocalTime.MAX);

        return new DashboardStats(
                osRepository.countByUsuarioId(uid),
                osRepository.countByUsuarioIdAndStatus(uid, "ABERTA"),
                osRepository.countByUsuarioIdAndStatus(uid, "EM_ANDAMENTO"),
                osRepository.countByUsuarioIdAndStatus(uid, "CONCLUIDA"),
                osRepository.countByUsuarioIdAndCriadoEmBetween(uid, inicioMes, fimMes)
        );
    }

    // --- Helpers ---

    private Usuario getUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));
    }

    /**
     * Verifica se o usuário ainda pode criar OS dentro do limite do plano.
     * Conta apenas as OS do mês atual.
     */
    private void verificarLimitePlano(Usuario usuario) {
        Plano plano = planoRepository.findByCodigo(usuario.getPlano()).orElse(null);
        if (plano != null && plano.getLimiteOs() != null && plano.getLimiteOs() > 0) {
            // Contar OS do mês atual
            YearMonth mesAtual = YearMonth.now();
            LocalDateTime inicioMes = mesAtual.atDay(1).atStartOfDay();
            LocalDateTime fimMes = mesAtual.atEndOfMonth().atTime(LocalTime.MAX);
            long totalOsMes = osRepository.countByUsuarioIdAndCriadoEmBetween(
                    usuario.getId(), inicioMes, fimMes);
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
        String dataHora = LocalDateTime.now().toString().replace("T", " ");
        StringBuilder sb = new StringBuilder();

        sb.append("EXTRATO DE RECEBIMENTO - OSMECH").append("\n");
        sb.append("====================================").append("\n");
        sb.append("OFICINA: ").append(oficinaNome).append("\n");
        sb.append("CNPJ OFICINA: ").append(defaultText(usuario.getCnpjOficina())).append("\n");
        sb.append("RESPONSAVEL: ").append(usuario.getNome()).append("\n");
        sb.append("EMAIL: ").append(usuario.getEmail()).append("\n");
        sb.append("TELEFONE: ").append(usuario.getTelefone()).append("\n");
        sb.append("ENDERECO: ").append(defaultText(montarEnderecoOficina(usuario))).append("\n");
        sb.append("SITE: ").append(defaultText(usuario.getSiteOficina())).append("\n");
        sb.append("------------------------------------").append("\n");
        sb.append("CLIENTE: ").append(defaultText(os.getClienteNome())).append("\n");
        sb.append("CPF: ").append(defaultText(os.getClienteCpf())).append("\n");
        sb.append("CNPJ: ").append(defaultText(os.getClienteCnpj())).append("\n");
        sb.append("TEL CLIENTE: ").append(defaultText(os.getClienteTelefone())).append("\n");
        sb.append("VEICULO: ").append(defaultText(os.getModelo())).append("\n");
        sb.append("MONTADORA: ").append(defaultText(os.getMontadora())).append("\n");
        sb.append("COR: ").append(defaultText(os.getCorVeiculo())).append("\n");
        sb.append("PLACA: ").append(defaultText(os.getPlaca())).append("\n");
        sb.append("ANO: ").append(os.getAno() != null ? os.getAno() : "-").append("\n");
        sb.append("KM: ").append(os.getQuilometragem() != null ? os.getQuilometragem() : "-").append("\n");
        sb.append("------------------------------------").append("\n");
        sb.append("LANCAMENTOS (SERVICOS)").append("\n");

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

        sb.append("LANCAMENTOS (PECAS)").append("\n");
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
        sb.append("SERVICOS: ").append(moeda.format(totalServicos)).append("\n");
        sb.append("PECAS: ").append(moeda.format(totalPecas)).append("\n");
        sb.append("TOTAL RECEBIDO: ").append(moeda.format(valorTotal)).append("\n");
        sb.append("METODO: ").append(defaultText(metodoPagamento)).append("\n");
        sb.append("OS: #").append(os.getId()).append("\n");
        if (transacao != null) {
            sb.append("TRANSACAO: #").append(transacao.getId()).append("\n");
        }
        sb.append("STATUS OS: ").append(defaultText(os.getStatus())).append("\n");
        sb.append("DATA/HORA: ").append(dataHora).append("\n");
        sb.append("====================================").append("\n");
        sb.append("Comprovante gerado automaticamente.");

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
            ServicoOS servico = ServicoOS.builder()
                    .ordemServico(os)
                    .descricao(req.getDescricao())
                    .quantidade(req.getQuantidade())
                    .valorUnitario(req.getValorUnitario())
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
            os.setValor(totalServicos.add(totalItens));

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
    public record DashboardStats(long total, long abertas, long emAndamento, long concluidas, long esteMes) {}
}
