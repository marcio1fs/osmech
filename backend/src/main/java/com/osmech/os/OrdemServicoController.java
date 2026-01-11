
package com.osmech.os;
import com.osmech.integration.TwilioWhatsAppService;

import com.osmech.user.User;
import com.osmech.user.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/os")
@CrossOrigin
public class OrdemServicoController {
        @Autowired
        private TwilioWhatsAppService twilioWhatsAppService;
    @Autowired
    private OrdemServicoRepository ordemServicoRepository;
    @Autowired
    private UserRepository userRepository;

    @GetMapping
    public List<OrdemServicoDTO> getAll() {
        return ordemServicoRepository.findAll().stream().map(this::toDTO).toList();
    }

    private OrdemServicoDTO toDTO(OrdemServico os) {
        OrdemServicoDTO dto = new OrdemServicoDTO();
        dto.setDescricao(os.getDescricao());
        dto.setStatus(os.getStatus());
        dto.setUsuarioId(os.getUsuario() != null ? os.getUsuario().getId() : null);
        dto.setTelefone(os.getTelefone());
        return dto;
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody OrdemServicoDTO dto) {
        User usuario = userRepository.findById(dto.getUsuarioId()).orElse(null);
        if (usuario == null) {
            return ResponseEntity.badRequest().body("Usuário não encontrado");
        }
        OrdemServico os = new OrdemServico();
        os.setDescricao(dto.getDescricao());
        os.setStatus(dto.getStatus());
        os.setUsuario(usuario);
        os.setTelefone(dto.getTelefone());
        OrdemServico saved = ordemServicoRepository.save(os);
        // Disparar WhatsApp ao criar OS usando template
        try {
            twilioWhatsAppService.sendWhatsAppTemplate(
                saved.getTelefone(),
                "os_created",
                saved.getDescricao(),
                saved.getStatus()
            );
        } catch (Exception e) {
            System.err.println("Erro ao enviar WhatsApp: " + e.getMessage());
        }
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody OrdemServicoDTO dto) {
        OrdemServico os = ordemServicoRepository.findById(id).orElse(null);
        if (os == null) {
            return ResponseEntity.notFound().build();
        }
        os.setDescricao(dto.getDescricao());
        os.setStatus(dto.getStatus());
        os.setTelefone(dto.getTelefone());
        OrdemServico saved = ordemServicoRepository.save(os);
        // Disparar WhatsApp ao atualizar status usando template
        try {
            twilioWhatsAppService.sendWhatsAppTemplate(
                saved.getTelefone(),
                "os_updated",
                saved.getDescricao(),
                saved.getStatus()
            );
        } catch (Exception e) {
            System.err.println("Erro ao enviar WhatsApp: " + e.getMessage());
        }
        return ResponseEntity.ok(saved);
    }
}
