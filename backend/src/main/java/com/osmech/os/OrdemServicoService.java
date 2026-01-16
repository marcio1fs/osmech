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

        // Create or find cliente
        Cliente cliente = new Cliente();
        cliente.setNome(request.getNomeCliente());
        cliente.setTelefone(request.getTelefone());
        cliente.setUsuario(usuario);
        cliente = clienteRepository.save(cliente);

        // Create or find veiculo
        Veiculo veiculo = new Veiculo();
        veiculo.setPlaca(request.getPlaca().toUpperCase());
        veiculo.setModelo(request.getModelo());
        veiculo.setCliente(cliente);
        veiculo = veiculoRepository.save(veiculo);

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
