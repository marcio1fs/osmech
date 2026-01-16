package com.osmech.os;

import com.osmech.os.dto.OrdemServicoRequest;
import com.osmech.os.dto.OrdemServicoResponse;
import com.osmech.user.Usuario;
import com.osmech.user.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class OrdemServicoService {

    @Autowired
    private OrdemServicoRepository ordemServicoRepository;

    @Autowired
    private ClienteRepository clienteRepository;

    @Autowired
    private VeiculoRepository veiculoRepository;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Transactional
    public OrdemServicoResponse criarOS(OrdemServicoRequest request, Long usuarioId) {
        Usuario usuario = usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new RuntimeException("Usuário não encontrado"));

        // Find or create cliente
        Cliente cliente = clienteRepository.findByUsuarioId(usuarioId).stream()
                .filter(c -> c.getNome().equals(request.getNomeCliente()) && 
                            c.getTelefone().equals(request.getTelefone()))
                .findFirst()
                .orElseGet(() -> {
                    Cliente novoCliente = new Cliente();
                    novoCliente.setNome(request.getNomeCliente());
                    novoCliente.setTelefone(request.getTelefone());
                    novoCliente.setUsuario(usuario);
                    return clienteRepository.save(novoCliente);
                });

        // Find or create veiculo
        Veiculo veiculo = veiculoRepository.findByClienteId(cliente.getId()).stream()
                .filter(v -> v.getPlaca().equalsIgnoreCase(request.getPlaca()))
                .findFirst()
                .orElseGet(() -> {
                    Veiculo novoVeiculo = new Veiculo();
                    novoVeiculo.setPlaca(request.getPlaca().toUpperCase());
                    novoVeiculo.setModelo(request.getModelo());
                    novoVeiculo.setCliente(cliente);
                    return veiculoRepository.save(novoVeiculo);
                });

        // Create ordem servico
        OrdemServico os = new OrdemServico();
        os.setCliente(cliente);
        os.setVeiculo(veiculo);
        os.setUsuario(usuario);
        os.setDescricaoProblema(request.getDescricaoProblema());
        os.setServicosRealizados(request.getServicosRealizados());
        os.setValor(request.getValor());
        os.setStatus(request.getStatus());

        os = ordemServicoRepository.save(os);

        return OrdemServicoResponse.fromEntity(os);
    }

    public List<OrdemServicoResponse> listarOS(Long usuarioId) {
        List<OrdemServico> ordens = ordemServicoRepository.findByUsuarioIdOrderByCreatedAtDesc(usuarioId);
        return ordens.stream()
                .map(OrdemServicoResponse::fromEntity)
                .collect(Collectors.toList());
    }

    public OrdemServicoResponse buscarPorId(Long id, Long usuarioId) {
        OrdemServico os = ordemServicoRepository.findByIdAndUsuarioId(id, usuarioId)
                .orElseThrow(() -> new RuntimeException("Ordem de serviço não encontrada"));
        return OrdemServicoResponse.fromEntity(os);
    }

    @Transactional
    public OrdemServicoResponse atualizarOS(Long id, OrdemServicoRequest request, Long usuarioId) {
        OrdemServico os = ordemServicoRepository.findByIdAndUsuarioId(id, usuarioId)
                .orElseThrow(() -> new RuntimeException("Ordem de serviço não encontrada"));

        // Update cliente
        Cliente cliente = os.getCliente();
        cliente.setNome(request.getNomeCliente());
        cliente.setTelefone(request.getTelefone());
        clienteRepository.save(cliente);

        // Update veiculo
        Veiculo veiculo = os.getVeiculo();
        veiculo.setPlaca(request.getPlaca().toUpperCase());
        veiculo.setModelo(request.getModelo());
        veiculoRepository.save(veiculo);

        // Update OS
        os.setDescricaoProblema(request.getDescricaoProblema());
        os.setServicosRealizados(request.getServicosRealizados());
        os.setValor(request.getValor());
        os.setStatus(request.getStatus());

        os = ordemServicoRepository.save(os);

        return OrdemServicoResponse.fromEntity(os);
    }

    @Transactional
    public void deletarOS(Long id, Long usuarioId) {
        OrdemServico os = ordemServicoRepository.findByIdAndUsuarioId(id, usuarioId)
                .orElseThrow(() -> new RuntimeException("Ordem de serviço não encontrada"));
        ordemServicoRepository.delete(os);
    }
}
