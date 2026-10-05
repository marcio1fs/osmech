package com.osmech.user.service;

import com.osmech.auditoria.entity.LogAuditoria;
import com.osmech.auditoria.service.AuditoriaService;
import com.osmech.oficina.entity.Oficina;
import com.osmech.oficina.repository.OficinaRepository;
import com.osmech.sessao.service.SessaoService;
import com.osmech.user.dto.AdminDtos;
import com.osmech.user.entity.Papel;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;

/**
 * Regras de negócio das operações administrativas da plataforma.
 *
 * Todas as ações são auditadas e protegidas por salvaguardas para evitar que o
 * próprio administrador se tranque para fora ou quebre invariantes de tenant
 * (ex.: rebaixar o DONO de uma oficina, criar/derrubar outro ADMIN).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AdminService {

    /** Planos reconhecidos pela plataforma (fonte de verdade da validação). */
    private static final Set<String> PLANOS_VALIDOS =
            Set.of("FREE", "PRO", "PRO_PLUS", "PREMIUM");

    private final UsuarioRepository usuarioRepository;
    private final OficinaRepository oficinaRepository;
    private final SessaoService sessaoService;
    private final AuditoriaService auditoria;

    // ------------------------------------------------------------------
    // Listagem paginada + agregados
    // ------------------------------------------------------------------

    @Transactional(readOnly = true)
    public AdminDtos.PaginaUsuarios listar(String termo, int pagina, int tamanho) {
        int tam = Math.max(1, Math.min(tamanho, 100));   // teto de 100 por página
        int pag = Math.max(0, pagina);
        String termoNormalizado = termo == null ? null : termo.trim();

        Page<Usuario> page = usuarioRepository.buscarAdmin(
                termoNormalizado,
                PageRequest.of(pag, tam, Sort.by(Sort.Direction.DESC, "criadoEm")));

        List<AdminDtos.UsuarioAdmin> usuarios = page.getContent().stream()
                .map(this::toDto)
                .toList();

        // Agregados globais de contas de clientes/oficinas e administradores
        // (exclui funcionários/colaboradores internos cadastrados pelas oficinas)
        List<Usuario> contasPrincipais = usuarioRepository.findAll().stream()
                .filter(u -> u.getOwnerId() == null || java.util.List.of("ADMIN", "DONO", "OFICINA").contains(u.getRole()))
                .toList();
        long ativos = contasPrincipais.stream().filter(u -> Boolean.TRUE.equals(u.getAtivo())).count();
        long free = contasPrincipais.stream().filter(u -> "FREE".equalsIgnoreCase(nvl(u.getPlano(), "FREE"))).count();

        return AdminDtos.PaginaUsuarios.builder()
                .usuarios(usuarios)
                .totalUsuarios(contasPrincipais.size())
                .totalAtivos(ativos)
                .totalFree(free)
                .totalPagos(contasPrincipais.size() - free)
                .pagina(pag)
                .tamanho(tam)
                .totalFiltrado(page.getTotalElements())
                .totalPaginas(page.getTotalPages())
                .build();
    }

    // ------------------------------------------------------------------
    // Ações de gestão
    // ------------------------------------------------------------------

    /** Ativa ou inativa a conta de um usuário. */
    @Transactional
    public AdminDtos.UsuarioAdmin definirAtivo(String adminEmail, Long id, boolean ativo) {
        Usuario admin = carregarAdmin(adminEmail);
        Usuario alvo = carregarAlvo(id);

        if (alvo.getId().equals(admin.getId())) {
            throw new IllegalArgumentException("Você não pode inativar a própria conta.");
        }
        if (!ativo && isAdmin(alvo)) {
            throw new IllegalArgumentException("Não é permitido inativar outro administrador da plataforma.");
        }

        boolean atual = Boolean.TRUE.equals(alvo.getAtivo());
        if (atual == ativo) {
            return toDto(alvo); // nada a fazer (idempotente)
        }

        alvo.setAtivo(ativo);
        usuarioRepository.save(alvo);

        if (!ativo) {
            // Ao inativar, derruba todas as sessões abertas do usuário
            sessaoService.revogarTodas(alvo.getId(), "ADMIN_INATIVACAO");
        }

        auditoria.registrar(admin,
                ativo ? LogAuditoria.ADMIN_USUARIO_ATIVADO : LogAuditoria.ADMIN_USUARIO_DESATIVADO,
                "Alvo=" + alvo.getEmail() + " (id=" + alvo.getId() + ")");
        return toDto(alvo);
    }

    /** Altera o plano do usuário (espelhado para a oficina/tenant). */
    @Transactional
    public AdminDtos.UsuarioAdmin definirPlano(String adminEmail, Long id, String plano) {
        Usuario admin = carregarAdmin(adminEmail);
        Usuario alvo = carregarAlvo(id);

        String novo = plano == null ? "" : plano.trim().toUpperCase();
        if (!PLANOS_VALIDOS.contains(novo)) {
            throw new IllegalArgumentException(
                    "Plano inválido. Valores aceitos: " + String.join(", ", PLANOS_VALIDOS));
        }

        String anterior = nvl(alvo.getPlano(), "FREE");
        alvo.setPlano(novo);
        usuarioRepository.save(alvo);

        // O plano é autoritativo na OFICINA (tenant) — espelha em todos os membros
        if (alvo.getOficinaId() != null) {
            Oficina oficina = oficinaRepository.findById(alvo.getOficinaId()).orElse(null);
            if (oficina != null) {
                oficina.setPlano(novo);
                oficinaRepository.save(oficina);
            }
            List<Usuario> membros = usuarioRepository.findAllByOficinaId(alvo.getOficinaId());
            for (Usuario membro : membros) {
                if (!novo.equalsIgnoreCase(membro.getPlano())) {
                    membro.setPlano(novo);
                    usuarioRepository.save(membro);
                }
            }
        }

        auditoria.registrar(admin, LogAuditoria.ADMIN_PLANO_ALTERADO,
                "Alvo=" + alvo.getEmail() + " " + anterior + " -> " + novo);
        return toDto(alvo);
    }

    /**
     * Altera o papel (role) de um usuário.
     *
     * Salvaguardas para não corromper invariantes de tenant:
     *  - não é possível alterar a própria conta;
     *  - não é possível mexer em outro ADMIN, nem promover ninguém a ADMIN
     *    (papel reservado à plataforma);
     *  - não é possível alterar nem atribuir DONO (propriedade estrutural da
     *    oficina — a troca de dono não é uma operação de suporte casual).
     * Papéis atribuíveis: GERENTE, ATENDENTE, MECANICO.
     */
    @Transactional
    public AdminDtos.UsuarioAdmin definirPapel(String adminEmail, Long id, String role) {
        Usuario admin = carregarAdmin(adminEmail);
        Usuario alvo = carregarAlvo(id);

        if (alvo.getId().equals(admin.getId())) {
            throw new IllegalArgumentException("Você não pode alterar o próprio papel.");
        }
        if (isAdmin(alvo)) {
            throw new IllegalArgumentException("Não é permitido alterar o papel de outro administrador.");
        }

        Papel atual = Papel.from(alvo.getRole());
        if (atual == Papel.DONO) {
            throw new IllegalArgumentException(
                    "Não é possível alterar o papel do DONO da oficina (propriedade estrutural).");
        }

        Papel novo = Papel.from(role);
        if (novo == Papel.ADMIN || novo == Papel.DONO) {
            throw new IllegalArgumentException(
                    "Papel não atribuível por aqui. Aceitos: GERENTE, ATENDENTE, MECANICO.");
        }

        String anterior = atual.name();
        alvo.setRole(novo.name());
        usuarioRepository.save(alvo);

        auditoria.registrar(admin, LogAuditoria.ADMIN_PAPEL_ALTERADO,
                "Alvo=" + alvo.getEmail() + " " + anterior + " -> " + novo.name());
        return toDto(alvo);
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    private Usuario carregarAdmin(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalStateException("Administrador não encontrado: " + email));
    }

    private Usuario carregarAlvo(Long id) {
        return usuarioRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado: " + id));
    }

    private boolean isAdmin(Usuario u) {
        return Papel.from(u.getRole()) == Papel.ADMIN;
    }

    private String nvl(String v, String fallback) {
        return (v == null || v.isBlank()) ? fallback : v;
    }

    private AdminDtos.UsuarioAdmin toDto(Usuario u) {
        return AdminDtos.UsuarioAdmin.builder()
                .id(u.getId())
                .nome(u.getNome())
                .email(u.getEmail())
                .telefone(u.getTelefone())
                .nomeOficina(u.getNomeOficina())
                .oficinaId(u.getOficinaId())
                .role(u.getRole())
                .plano(nvl(u.getPlano(), "FREE"))
                .ativo(u.getAtivo())
                .emailVerificado(u.getEmailVerificado())
                .criadoEm(u.getCriadoEm())
                .build();
    }
}
