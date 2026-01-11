package com.osmech.integration;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "whatsapp_logs")
public class WhatsAppLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String telefone;

    @Column(length = 512)
    private String mensagem;

    private String status;

    private String erro;

    private String provider; // Novo campo para registrar o provedor

    private LocalDateTime dataEnvio;

    private int tentativas = 1;

    private boolean reenviar = false;

    public WhatsAppLog() {
        this.dataEnvio = LocalDateTime.now();
    }

    // Getters e Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getTelefone() { return telefone; }
    public void setTelefone(String telefone) { this.telefone = telefone; }
    public String getMensagem() { return mensagem; }
    public void setMensagem(String mensagem) { this.mensagem = mensagem; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getErro() { return erro; }
    public void setErro(String erro) { this.erro = erro; }
    public String getProvider() { return provider; }
    public void setProvider(String provider) { this.provider = provider; }
    public LocalDateTime getDataEnvio() { return dataEnvio; }
    public void setDataEnvio(LocalDateTime dataEnvio) { this.dataEnvio = dataEnvio; }
    public int getTentativas() { return tentativas; }
    public void setTentativas(int tentativas) { this.tentativas = tentativas; }
    public boolean isReenviar() { return reenviar; }
    public void setReenviar(boolean reenviar) { this.reenviar = reenviar; }
}
