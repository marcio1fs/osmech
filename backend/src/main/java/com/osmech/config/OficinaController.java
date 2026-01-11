package com.osmech.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/oficinas")
@CrossOrigin
public class OficinaController {
    @Autowired
    private OficinaRepository oficinaRepository;

    @GetMapping
    public List<Oficina> getAll() {
        return oficinaRepository.findAll();
    }

    @PostMapping
    public ResponseEntity<Oficina> create(@RequestBody OficinaDTO dto) {
        Oficina oficina = new Oficina();
        oficina.setNome(dto.getNome());
        oficina.setEndereco(dto.getEndereco());
        return ResponseEntity.ok(oficinaRepository.save(oficina));
    }
}
