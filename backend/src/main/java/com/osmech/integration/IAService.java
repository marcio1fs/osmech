package com.osmech.integration;

public interface IAService {

    /**
     * Gera uma resposta para o cliente com base na entrada fornecida.
     * @param input Entrada do cliente.
     * @return Resposta gerada pela IA.
     */
    String gerarResposta(String input);

    /**
     * Ajuda o mecânico com diagnósticos baseados em descrições de problemas.
     * @param descricaoProblema Descrição do problema fornecida pelo mecânico.
     * @return Diagnóstico sugerido pela IA.
     */
    String diagnosticarProblema(String descricaoProblema);

    /**
     * Gera um resumo da ordem de serviço.
     * @param detalhesOS Detalhes da ordem de serviço.
     * @return Resumo gerado pela IA.
     */
    String gerarResumoOS(String detalhesOS);

    /**
     * Analisa o histórico do veículo e fornece insights.
     * @param historico Dados históricos do veículo.
     * @return Insights gerados pela IA.
     */
    String analisarHistoricoVeiculo(String historico);
}