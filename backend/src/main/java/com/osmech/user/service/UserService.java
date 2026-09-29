package com.osmech.user.service;

import com.osmech.config.ResourceNotFoundException;
import com.osmech.oficina.entity.Oficina;
import com.osmech.oficina.repository.OficinaRepository;
import com.osmech.user.dto.ChangePasswordRequest;
import com.osmech.user.dto.UserProfileRequest;
import com.osmech.user.dto.UserProfileResponse;
import com.osmech.user.entity.Usuario;
import com.osmech.user.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.beans.factory.annotation.Value;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

/**
 * Serviço de gerenciamento de perfil do usuário.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class UserService {

    private final UsuarioRepository usuarioRepository;
    private final OficinaRepository oficinaRepository;
    private final PasswordEncoder passwordEncoder;

    @Value("${app.upload.logo-dir:/app/uploads/logos}")
    private String logoDir;

    /**
     * Retorna o perfil do usuário logado.
     */
    @Transactional(readOnly = true)
    public UserProfileResponse getPerfil(String email) {
        Usuario usuario = getUsuario(email);
        return toResponse(usuario);
    }

    /**
     * Atualiza dados do perfil do usuário.
     */
    @Transactional
    public UserProfileResponse atualizarPerfil(String email, UserProfileRequest request) {
        Usuario usuario = getUsuario(email);

        if (request.getNome() != null && !request.getNome().isBlank()) {
            usuario.setNome(request.getNome());
        }
        if (request.getTelefone() != null && !request.getTelefone().isBlank()) {
            usuario.setTelefone(request.getTelefone());
        }
        if (request.getNomeOficina() != null) {
            usuario.setNomeOficina(request.getNomeOficina());
        }
        if (request.getCnpjOficina() != null) {
            usuario.setCnpjOficina(normalizarDocumento(request.getCnpjOficina()));
        }
        if (request.getEnderecoLogradouro() != null) {
            usuario.setEnderecoLogradouro(normalizarOpcional(request.getEnderecoLogradouro()));
        }
        if (request.getEnderecoNumero() != null) {
            usuario.setEnderecoNumero(normalizarOpcional(request.getEnderecoNumero()));
        }
        if (request.getEnderecoComplemento() != null) {
            usuario.setEnderecoComplemento(normalizarOpcional(request.getEnderecoComplemento()));
        }
        if (request.getEnderecoBairro() != null) {
            usuario.setEnderecoBairro(normalizarOpcional(request.getEnderecoBairro()));
        }
        if (request.getEnderecoCidade() != null) {
            usuario.setEnderecoCidade(normalizarOpcional(request.getEnderecoCidade()));
        }
        if (request.getEnderecoEstado() != null) {
            final String uf = normalizarOpcional(request.getEnderecoEstado());
            usuario.setEnderecoEstado(uf == null ? null : uf.toUpperCase());
        }
        if (request.getEnderecoCep() != null) {
            usuario.setEnderecoCep(normalizarOpcional(request.getEnderecoCep()));
        }
        if (request.getSiteOficina() != null) {
            usuario.setSiteOficina(normalizarOpcional(request.getSiteOficina()));
        }

        usuarioRepository.save(usuario);
        sincronizarDadosEmpresaNaOficina(usuario);
        log.info("Perfil atualizado para usuário: {}", email);
        return toResponse(usuario);
    }

    /**
     * Espelha os dados de empresa do usuário na entidade Oficina (tenant).
     * A partir da Fase 1, Oficina é a fonte autoritativa dos dados da empresa;
     * os campos em usuarios permanecem como espelho para telas legadas.
     */
    private void sincronizarDadosEmpresaNaOficina(Usuario usuario) {
        if (usuario.getOficinaId() == null) {
            return;
        }
        oficinaRepository.findById(usuario.getOficinaId()).ifPresent(oficina -> {
            String nome = usuario.getNomeOficina();
            oficina.setNome(nome != null && !nome.isBlank() ? nome : usuario.getNome());
            oficina.setCnpj(usuario.getCnpjOficina());
            oficina.setTelefone(usuario.getTelefone());
            oficina.setEmail(usuario.getEmail());
            oficina.setEnderecoLogradouro(usuario.getEnderecoLogradouro());
            oficina.setEnderecoNumero(usuario.getEnderecoNumero());
            oficina.setEnderecoComplemento(usuario.getEnderecoComplemento());
            oficina.setEnderecoBairro(usuario.getEnderecoBairro());
            oficina.setEnderecoCidade(usuario.getEnderecoCidade());
            oficina.setEnderecoEstado(usuario.getEnderecoEstado());
            oficina.setEnderecoCep(usuario.getEnderecoCep());
            oficina.setSite(usuario.getSiteOficina());
            oficina.setLogoUrl(usuario.getLogoUrl());
            oficinaRepository.save(oficina);
        });
    }

    /**
     * Altera a senha do usuário.
     */
    @Transactional
    public void alterarSenha(String email, ChangePasswordRequest request) {
        Usuario usuario = getUsuario(email);

        // Verificar senha atual
        if (!passwordEncoder.matches(request.getSenhaAtual(), usuario.getSenha())) {
            throw new IllegalArgumentException("Senha atual incorreta");
        }

        // Validar nova senha
        if (request.getNovaSenha().length() < 8) {
            throw new IllegalArgumentException("Nova senha deve ter pelo menos 8 caracteres");
        }

        usuario.setSenha(passwordEncoder.encode(request.getNovaSenha()));
        usuarioRepository.save(usuario);
        log.info("Senha alterada para usuário: {}", email);
    }

    /**
     * Faz upload da logo do usuário.
     */
    @Transactional
    public String uploadLogo(String email, MultipartFile file) throws Exception {
        Usuario usuario = getUsuario(email);

        if (file.isEmpty()) {
            throw new IllegalArgumentException("Arquivo vazio");
        }

        // Criar o diretório se não existir
        Path dir = Paths.get(logoDir).toAbsolutePath().normalize();
        Files.createDirectories(dir);

        // Gerar um nome único para o arquivo
        String originalFilename = file.getOriginalFilename();
        String extension = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            extension = originalFilename.substring(originalFilename.lastIndexOf("."));
        }
        String newFilename = "logo_" + usuario.getId() + "_" + UUID.randomUUID().toString() + extension;
        Path targetLocation = dir.resolve(newFilename);

        // Salvar o arquivo
        Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);

        // Construir a URL pública
        String logoUrlPath = "/api/uploads/logos/" + newFilename;
        usuario.setLogoUrl(logoUrlPath);
        usuarioRepository.save(usuario);
        sincronizarDadosEmpresaNaOficina(usuario);

        log.info("Logo atualizada para usuário: {}", email);
        return logoUrlPath;
    }

    private Usuario getUsuario(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));
    }

    private UserProfileResponse toResponse(Usuario usuario) {
        return UserProfileResponse.builder()
                .id(usuario.getId())
                .nome(usuario.getNome())
                .email(usuario.getEmail())
                .telefone(usuario.getTelefone())
                .nomeOficina(usuario.getNomeOficina())
                .cnpjOficina(usuario.getCnpjOficina())
                .enderecoLogradouro(usuario.getEnderecoLogradouro())
                .enderecoNumero(usuario.getEnderecoNumero())
                .enderecoComplemento(usuario.getEnderecoComplemento())
                .enderecoBairro(usuario.getEnderecoBairro())
                .enderecoCidade(usuario.getEnderecoCidade())
                .enderecoEstado(usuario.getEnderecoEstado())
                .enderecoCep(usuario.getEnderecoCep())
                .siteOficina(usuario.getSiteOficina())
                .logoUrl(usuario.getLogoUrl())
                .role(usuario.getRole())
                .plano(usuario.getPlano())
                .ativo(usuario.getAtivo())
                .criadoEm(usuario.getCriadoEm())
                .build();
    }

    private String normalizarOpcional(String valor) {
        final String trimmed = valor == null ? "" : valor.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private String normalizarDocumento(String valor) {
        final String digits = valor == null ? "" : valor.replaceAll("\\D", "");
        return digits.isBlank() ? null : digits;
    }
}
