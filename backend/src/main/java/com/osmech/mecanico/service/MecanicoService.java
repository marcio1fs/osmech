package com.osmech.mecanico.service;

import com.osmech.config.ResourceNotFoundException;
import com.osmech.mecanico.dto.MecanicoRequest;
import com.osmech.mecanico.dto.MecanicoResponse;
import com.osmech.mecanico.entity.Mecanico;
import com.osmech.mecanico.repository.MecanicoRepository;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class MecanicoService {

    private final MecanicoRepository mecanicoRepository;
    private final UsuarioRepository usuarioRepository;

    @Transactional
    public MecanicoResponse criar(String emailUsuario, MecanicoRequest request) {
        Usuario usuario = getUsuario(emailUsuario);

        Mecanico mecanico = Mecanico.builder()
                .usuarioId(usuario.getId())
                .nome(request.getNome().trim())
                .telefone(request.getTelefone() != null ? request.getTelefone().trim() : null)
                .especialidade(request.getEspecialidade() != null ? request.getEspecialidade().trim() : null)
                .ativo(request.getAtivo() != null ? request.getAtivo() : true)
                .build();

        return MecanicoResponse.fromEntity(mecanicoRepository.save(mecanico));
    }

    @Transactional(readOnly = true)
    public List<MecanicoResponse> listar(String emailUsuario, boolean ativosOnly) {
        Usuario usuario = getUsuario(emailUsuario);

        List<Mecanico> mecanicos = ativosOnly
                ? mecanicoRepository.findByUsuarioIdAndAtivoTrueOrderByNomeAsc(usuario.getId())
                : mecanicoRepository.findByUsuarioIdOrderByNomeAsc(usuario.getId());

        return mecanicos.stream().map(MecanicoResponse::fromEntity).toList();
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
