package com.osmech.stock.service;

import com.osmech.stock.dto.*;
import com.osmech.stock.entity.StockItem;
import com.osmech.stock.entity.StockMovement;
import com.osmech.stock.repository.StockItemRepository;
import com.osmech.stock.repository.StockMovementRepository;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/**
 * Serviço de controle de estoque.
 * Gerencia itens, movimentações, alertas e integração com OS.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class StockService {

    private final StockItemRepository itemRepository;
    private final StockMovementRepository movementRepository;
    private final UsuarioRepository usuarioRepository;

    private static final Set<String> CATEGORIAS_VALIDAS = Set.of(
            "MOTOR", "SUSPENSAO", "FREIOS", "ELETRICA", "TRANSMISSAO",
            "ARREFECIMENTO", "FILTROS", "OLEOS", "FUNILARIA", "ACESSORIOS", "OUTROS"
    );

    private static final Set<String> MOTIVOS_VALIDOS = Set.of(
            "COMPRA", "AJUSTE", "PERDA", "CONSUMO_INTERNO", "OS", "DEVOLUCAO"
    );

    // ==========================================
    // ITENS DE ESTOQUE
    // ==========================================

    /** Criar novo item de estoque */
    @Transactional
    public StockItemResponse criarItem(String emailUsuario, StockItemRequest request) {
        Usuario usuario = getUsuario(emailUsuario);

        // Validar código único
        if (itemRepository.existsByUsuarioIdAndCodigoIgnoreCase(usuario.getId(), request.getCodigo())) {
            throw new IllegalArgumentException("Já existe um item com o código '" + request.getCodigo() + "'");
        }

        // Validar categoria
        String categoria = request.getCategoria() != null ? request.getCategoria().toUpperCase() : "OUTROS";
        if (!CATEGORIAS_VALIDAS.contains(categoria)) {
            throw new IllegalArgumentException("Categoria inválida: " + categoria);
        }

        StockItem item = StockItem.builder()
                .usuarioId(usuario.getId())
                .codigo(request.getCodigo().toUpperCase().trim())
                .nome(request.getNome().trim())
                .categoria(categoria)
                .quantidade(request.getQuantidade() != null ? request.getQuantidade() : 0)
                .quantidadeMinima(request.getQuantidadeMinima() != null ? request.getQuantidadeMinima() : 1)
                .precoCusto(request.getPrecoCusto())
                .precoVenda(request.getPrecoVenda())
                .localizacao(request.getLocalizacao())
                .build();

        item = itemRepository.save(item);

        // Se criou com quantidade > 0, registrar movimentação de entrada inicial
        if (item.getQuantidade() > 0) {
            registrarMovimentacao(item, "ENTRADA", item.getQuantidade(), 0,
                    item.getQuantidade(), "AJUSTE", "Estoque inicial", null);
        }

        log.info("Item de estoque criado: {} - {} (qty: {})", item.getCodigo(), item.getNome(), item.getQuantidade());
        return StockItemResponse.fromEntity(item);
    }

    /** Atualizar item existente */
    @Transactional
    public StockItemResponse atualizarItem(String emailUsuario, Long itemId, StockItemRequest request) {
        Usuario usuario = getUsuario(emailUsuario);
        StockItem item = getItemDoUsuario(usuario.getId(), itemId);

        // Verificar duplicata de código (se mudou)
        if (!item.getCodigo().equalsIgnoreCase(request.getCodigo())) {
            if (itemRepository.existsByUsuarioIdAndCodigoIgnoreCase(usuario.getId(), request.getCodigo())) {
                throw new IllegalArgumentException("Já existe um item com o código '" + request.getCodigo() + "'");
            }
            item.setCodigo(request.getCodigo().toUpperCase().trim());
        }

        if (request.getNome() != null) item.setNome(request.getNome().trim());
        if (request.getCategoria() != null) {
            String cat = request.getCategoria().toUpperCase();
            if (!CATEGORIAS_VALIDAS.contains(cat)) {
                throw new IllegalArgumentException("Categoria inválida: " + cat);
            }
            item.setCategoria(cat);
        }
        if (request.getQuantidadeMinima() != null) item.setQuantidadeMinima(request.getQuantidadeMinima());
        if (request.getPrecoCusto() != null) item.setPrecoCusto(request.getPrecoCusto());
        if (request.getPrecoVenda() != null) item.setPrecoVenda(request.getPrecoVenda());
        if (request.getLocalizacao() != null) item.setLocalizacao(request.getLocalizacao());

        // Se a quantidade mudou, gerar movimentação de ajuste
        if (request.getQuantidade() != null && !request.getQuantidade().equals(item.getQuantidade())) {
            int diff = request.getQuantidade() - item.getQuantidade();
            String tipo = diff > 0 ? "ENTRADA" : "SAIDA";
            int qtdAnterior = item.getQuantidade();
            item.setQuantidade(request.getQuantidade());
            registrarMovimentacao(item, tipo, Math.abs(diff), qtdAnterior,
                    item.getQuantidade(), "AJUSTE", "Ajuste manual de quantidade", null);
        }

        item = itemRepository.save(item);
        return StockItemResponse.fromEntity(item);
    }

    /** Listar itens da oficina */
    public List<StockItemResponse> listarItens(String emailUsuario, String categoria, String busca) {
        Usuario usuario = getUsuario(emailUsuario);

        List<StockItem> itens;
        if (busca != null && !busca.isBlank()) {
            itens = itemRepository.searchByNome(usuario.getId(), busca.trim());
        } else if (categoria != null && !categoria.isBlank()) {
            itens = itemRepository.findByUsuarioIdAndCategoriaAndAtivoTrueOrderByNomeAsc(
                    usuario.getId(), categoria.toUpperCase());
        } else {
            itens = itemRepository.findByUsuarioIdAndAtivoTrueOrderByNomeAsc(usuario.getId());
        }

        return itens.stream().map(StockItemResponse::fromEntity).toList();
    }

    /** Buscar item por ID */
    public StockItemResponse buscarItem(String emailUsuario, Long itemId) {
        Usuario usuario = getUsuario(emailUsuario);
        StockItem item = getItemDoUsuario(usuario.getId(), itemId);
        return StockItemResponse.fromEntity(item);
    }

    /** Desativar item (soft delete) */
    @Transactional
    public void desativarItem(String emailUsuario, Long itemId) {
        Usuario usuario = getUsuario(emailUsuario);
        StockItem item = getItemDoUsuario(usuario.getId(), itemId);
        item.setAtivo(false);
        itemRepository.save(item);
        log.info("Item desativado: {} - {}", item.getCodigo(), item.getNome());
    }

    // ==========================================
    // MOVIMENTAÇÕES
    // ==========================================

    /** Registrar movimentação manual (entrada ou saída) */
    @Transactional
    public StockMovementResponse registrarMovimentacaoManual(String emailUsuario, StockMovementRequest request) {
        Usuario usuario = getUsuario(emailUsuario);
        StockItem item = getItemDoUsuario(usuario.getId(), request.getStockItemId());

        String tipo = request.getTipo().toUpperCase();
        if (!"ENTRADA".equals(tipo) && !"SAIDA".equals(tipo)) {
            throw new IllegalArgumentException("Tipo deve ser ENTRADA ou SAIDA");
        }

        String motivo = request.getMotivo().toUpperCase();
        if (!MOTIVOS_VALIDOS.contains(motivo)) {
            throw new IllegalArgumentException("Motivo inválido: " + motivo);
        }

        int qtdAnterior = item.getQuantidade();
        int novaQtd;

        if ("SAIDA".equals(tipo)) {
            if (item.getQuantidade() < request.getQuantidade()) {
                throw new IllegalArgumentException(
                        "Estoque insuficiente. Disponível: " + item.getQuantidade() +
                        ", solicitado: " + request.getQuantidade());
            }
            novaQtd = item.getQuantidade() - request.getQuantidade();
        } else {
            novaQtd = item.getQuantidade() + request.getQuantidade();
        }

        item.setQuantidade(novaQtd);
        itemRepository.save(item);

        StockMovement mov = registrarMovimentacao(item, tipo, request.getQuantidade(),
                qtdAnterior, novaQtd, motivo, request.getDescricao(), request.getOrdemServicoId());

        log.info("Movimentação: {} {} x{} ({} -> {})", tipo, item.getCodigo(),
                request.getQuantidade(), qtdAnterior, novaQtd);

        return StockMovementResponse.fromEntity(mov);
    }

    /** Dar baixa automática no estoque ao concluir OS (chamado pelo OrdemServicoService) */
    @Transactional
    public void darBaixaOS(Long usuarioId, Long ordemServicoId, List<StockMovementRequest> itens) {
        for (StockMovementRequest req : itens) {
            StockItem item = itemRepository.findById(req.getStockItemId())
                    .orElseThrow(() -> new IllegalArgumentException("Item não encontrado: " + req.getStockItemId()));

            if (!item.getUsuarioId().equals(usuarioId)) {
                throw new IllegalArgumentException("Item não pertence a esta oficina");
            }

            int qtdAnterior = item.getQuantidade();
            if (item.getQuantidade() < req.getQuantidade()) {
                throw new IllegalArgumentException(
                        "Estoque insuficiente para " + item.getNome() +
                        ". Disponível: " + item.getQuantidade() +
                        ", necessário: " + req.getQuantidade());
            }

            int novaQtd = item.getQuantidade() - req.getQuantidade();
            item.setQuantidade(novaQtd);
            itemRepository.save(item);

            registrarMovimentacao(item, "SAIDA", req.getQuantidade(), qtdAnterior,
                    novaQtd, "OS", "Baixa automática - OS #" + ordemServicoId, ordemServicoId);

            log.info("Baixa OS #{}: {} x{} ({} -> {})", ordemServicoId,
                    item.getCodigo(), req.getQuantidade(), qtdAnterior, novaQtd);
        }
    }

    /** Listar movimentações de um item */
    public List<StockMovementResponse> listarMovimentacoes(String emailUsuario, Long stockItemId) {
        Usuario usuario = getUsuario(emailUsuario);
        // Validar que o item pertence ao usuário
        getItemDoUsuario(usuario.getId(), stockItemId);

        return movementRepository.findByStockItemIdOrderByCriadoEmDesc(stockItemId)
                .stream().map(StockMovementResponse::fromEntity).toList();
    }

    /** Listar todas as movimentações da oficina */
    public List<StockMovementResponse> listarTodasMovimentacoes(String emailUsuario) {
        Usuario usuario = getUsuario(emailUsuario);
        return movementRepository.findByUsuarioIdOrderByCriadoEmDesc(usuario.getId())
                .stream().map(StockMovementResponse::fromEntity).toList();
    }

    // ==========================================
    // ALERTAS
    // ==========================================

    /** Retorna itens com estoque baixo ou zerado */
    public List<StockAlertResponse> getAlertas(String emailUsuario) {
        Usuario usuario = getUsuario(emailUsuario);
        List<StockItem> alertItems = itemRepository.findAlertItems(usuario.getId());

        List<StockAlertResponse> alerts = new ArrayList<>();
        for (StockItem item : alertItems) {
            String nivel = item.isEstoqueZerado() ? "CRITICO" : "ALERTA";
            String msg = item.isEstoqueZerado()
                    ? "Estoque ZERADO — " + item.getNome()
                    : "Estoque baixo — " + item.getNome() + " (" + item.getQuantidade() + "/" + item.getQuantidadeMinima() + ")";

            alerts.add(StockAlertResponse.builder()
                    .id(item.getId())
                    .codigo(item.getCodigo())
                    .nome(item.getNome())
                    .categoria(item.getCategoria())
                    .quantidade(item.getQuantidade())
                    .quantidadeMinima(item.getQuantidadeMinima())
                    .precoCusto(item.getPrecoCusto())
                    .precoVenda(item.getPrecoVenda())
                    .nivel(nivel)
                    .mensagem(msg)
                    .build());
        }
        return alerts;
    }

    // ==========================================
    // HELPERS
    // ==========================================

    private Usuario getUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado"));
    }

    private StockItem getItemDoUsuario(Long usuarioId, Long itemId) {
        StockItem item = itemRepository.findById(itemId)
                .orElseThrow(() -> new IllegalArgumentException("Item não encontrado"));
        if (!item.getUsuarioId().equals(usuarioId)) {
            throw new IllegalArgumentException("Acesso negado a este item");
        }
        if (!item.getAtivo()) {
            throw new IllegalArgumentException("Item está desativado");
        }
        return item;
    }

    private StockMovement registrarMovimentacao(StockItem item, String tipo, int quantidade,
            int qtdAnterior, int qtdPosterior, String motivo, String descricao, Long osId) {
        StockMovement mov = StockMovement.builder()
                .usuarioId(item.getUsuarioId())
                .stockItem(item)
                .tipo(tipo)
                .quantidade(quantidade)
                .quantidadeAnterior(qtdAnterior)
                .quantidadePosterior(qtdPosterior)
                .motivo(motivo)
                .descricao(descricao)
                .ordemServicoId(osId)
                .build();
        return movementRepository.save(mov);
    }
}
