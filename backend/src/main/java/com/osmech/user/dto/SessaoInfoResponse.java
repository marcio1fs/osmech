package com.osmech.user.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * Visão segura de uma sessão ativa (sem o hash/token).
 */
@Data
@Builder
public class SessaoInfoResponse {
    private LocalDateTime criadoEm;
    private LocalDateTime expiraEm;
    private String userAgent;
    /** true para a sessão que originou a consulta */
    private boolean atual;
}
