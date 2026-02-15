package com.osmech.finance.service;

import com.osmech.finance.dto.CategoriaRequest;
import com.osmech.finance.dto.CategoriaResponse;
import com.osmech.finance.entity.CategoriaFinanceira;
import com.osmech.finance.repository.CategoriaFinanceiraRepository;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Serviço responsável pelas categorias financeiras.
 */
@Service
@RequiredArgsConstructor
public class CategoriaFinanceiraService {

    private final CategoriaFinanceiraRepository categoriaRepository;
    private final UsuarioRepository usuarioRepository;

    /**
     * Lista todas as categorias disponíveis para o usuário
     * (categorias da oficina + categorias padrão do sistema).
     */
    public List<CategoriaResponse> listarPorUsuario(String emailUsuario) {
        Usuario usuario = getUsuario(emailUsuario);
        return categoriaRepository
                .findByUsuarioIdOrSistemaTrueOrderByNomeAsc(usuario.getId())
                .stream()
                .map(this::toResponse)
                .toList();
    }

    /**
     * Cria uma nova categoria personalizada para a oficina.
     */
    public CategoriaResponse criar(String emailUsuario, CategoriaRequest request) {
        Usuario usuario = getUsuario(emailUsuario);

        // Valida tipo
        if (!"ENTRADA".equals(request.getTipo()) && !"SAIDA".equals(request.getTipo())) {
            throw new IllegalArgumentException("Tipo deve ser ENTRADA ou SAIDA");
        }

        // Verifica duplicata
        if (categoriaRepository.existsByUsuarioIdAndNomeIgnoreCase(usuario.getId(), request.getNome())) {
            throw new IllegalArgumentException("Categoria com este nome já existe");
        }

        CategoriaFinanceira cat = CategoriaFinanceira.builder()
                .usuarioId(usuario.getId())
                .nome(request.getNome())
                .tipo(request.getTipo())
                .icone(request.getIcone())
                .sistema(false)
                .build();

        cat = categoriaRepository.save(cat);
        return toResponse(cat);
    }

    /**
     * Exclui uma categoria personalizada (não é possível excluir categorias do sistema).
     */
    public void excluir(String emailUsuario, Long categoriaId) {
        Usuario usuario = getUsuario(emailUsuario);
        CategoriaFinanceira cat = categoriaRepository.findById(categoriaId)
                .orElseThrow(() -> new IllegalArgumentException("Categoria não encontrada"));

        if (Boolean.TRUE.equals(cat.getSistema())) {
            throw new IllegalArgumentException("Categorias do sistema não podem ser excluídas");
        }
        if (!usuario.getId().equals(cat.getUsuarioId())) {
            throw new IllegalArgumentException("Acesso negado a esta categoria");
        }

        categoriaRepository.delete(cat);
    }

    // --- Helpers ---

    private Usuario getUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado"));
    }

    private CategoriaResponse toResponse(CategoriaFinanceira cat) {
        return CategoriaResponse.builder()
                .id(cat.getId())
                .nome(cat.getNome())
                .tipo(cat.getTipo())
                .icone(cat.getIcone())
                .sistema(cat.getSistema())
                .criadoEm(cat.getCriadoEm())
                .build();
    }
}
