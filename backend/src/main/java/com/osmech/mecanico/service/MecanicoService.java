package com.osmech.mecanico.service;

import com.osmech.config.ResourceNotFoundException;
import com.osmech.mecanico.dto.MecanicoRequest;
import com.osmech.mecanico.dto.MecanicoResponse;
import com.osmech.mecanico.entity.Mecanico;
import com.osmech.mecanico.repository.MecanicoRepository;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class MecanicoService {

    private final MecanicoRepository mecanicoRepository;
    private final UsuarioRepository usuarioRepository;

    @Transactional
    public MecanicoResponse criar(String emailUsuario, MecanicoRequest request) {
        log.info("Criando mecánico para usuario: {}", emailUsuario);
        try {
            Usuario usuario = getUsuario(emailUsuario);
            log.debug("Usuario encontrado: {}", usuario.getId());

            Mecanico mecanico = Mecanico.builder()
                    .usuarioId(usuario.getId())
                    .nome(request.getNome().trim())
                    .telefone(request.getTelefone() != null ? request.getTelefone().trim() : null)
                    .especialidade(request.getEspecialidade() != null ? request.getEspecialidade().trim() : null)
                    .percentualComissao(request.getPercentualComissao() != null ? request.getPercentualComissao() : BigDecimal.ZERO)
                    .ativo(request.getAtivo() != null ? request.getAtivo() : true)
                    .build();

            Mecanico salvo = mecanicoRepository.save(mecanico);
            log.info("Mecânico criado com ID: {}", salvo.getId());
            return MecanicoResponse.fromEntity(salvo);
        } catch (Exception e) {
            log.error("Erro ao criar mecánico: {}", e.getMessage(), e);
            throw e;
        }
    }

    @Transactional(readOnly = true)
    public List<MecanicoResponse> listar(String emailUsuario, boolean ativosOnly) {
        log.info("Listando mecanicos para usuario: {}, ativosOnly: {}", emailUsuario, ativosOnly);
        try {
            Usuario usuario = getUsuario(emailUsuario);
            log.debug("Usuario encontrado: {}", usuario.getId());

            List<Mecanico> mecanicos = ativosOnly
                    ? mecanicoRepository.findByUsuarioIdAndAtivoTrueOrderByNomeAsc(usuario.getId())
                    : mecanicoRepository.findByUsuarioIdOrderByNomeAsc(usuario.getId());

            log.debug("Mecanicos encontrados: {}", mecanicos.size());
            return mecanicos.stream().map(MecanicoResponse::fromEntity).toList();
        } catch (Exception e) {
            log.error("Erro ao listar mecanicos: {}", e.getMessage(), e);
            throw e;
        }
    }

    @Transactional(readOnly = true)
    public MecanicoResponse buscarPorId(String emailUsuario, Long id) {
        Usuario usuario = getUsuario(emailUsuario);
        Mecanico mecanico = getMecanicoDoUsuario(usuario.getId(), id);
        return MecanicoResponse.fromEntity(mecanico);
    }

    @Transactional
    public MecanicoResponse atualizar(String emailUsuario, Long id, MecanicoRequest request) {
        Usuario usuario = getUsuario(emailUsuario);
        Mecanico mecanico = getMecanicoDoUsuario(usuario.getId(), id);

        if (request.getNome() != null && !request.getNome().isBlank()) {
            mecanico.setNome(request.getNome().trim());
        }
        if (request.getTelefone() != null) {
            mecanico.setTelefone(request.getTelefone().trim());
        }
        if (request.getEspecialidade() != null) {
            mecanico.setEspecialidade(request.getEspecialidade().trim());
        }
        if (request.getPercentualComissao() != null) {
            mecanico.setPercentualComissao(request.getPercentualComissao());
        }
        if (request.getAtivo() != null) {
            mecanico.setAtivo(request.getAtivo());
        }

        return MecanicoResponse.fromEntity(mecanicoRepository.save(mecanico));
    }

    @Transactional
    public void desativar(String emailUsuario, Long id) {
        Usuario usuario = getUsuario(emailUsuario);
        Mecanico mecanico = getMecanicoDoUsuario(usuario.getId(), id);
        mecanico.setAtivo(false);
        mecanicoRepository.save(mecanico);
    }

    @Transactional
    public void reativar(String emailUsuario, Long id) {
        Usuario usuario = getUsuario(emailUsuario);
        Mecanico mecanico = getMecanicoDoUsuario(usuario.getId(), id);
        mecanico.setAtivo(true);
        mecanicoRepository.save(mecanico);
    }

    private Usuario getUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));
    }

    private Mecanico getMecanicoDoUsuario(Long usuarioId, Long mecanicoId) {
        Mecanico mecanico = mecanicoRepository.findById(mecanicoId)
                .orElseThrow(() -> new ResourceNotFoundException("Mecânico não encontrado"));
        if (!mecanico.getUsuarioId().equals(usuarioId)) {
            throw new AccessDeniedException("Acesso negado ao mecânico");
        }
        return mecanico;
    }
}
