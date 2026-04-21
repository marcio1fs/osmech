# Checklist QA – Ordem de Serviço (OS)

1. Criar OS com payload mínimo
- `POST /api/os` com `clienteNome`, `placa`, `modelo`
- Esperado: 200 + OS criada

2. Criar OS sem placa
- `POST /api/os` sem `placa`
- Esperado: 400 + erro de validação no campo `placa`

3. Criar OS com telefone inválido
- `clienteTelefone` com 9 dígitos ou letras
- Esperado: 400 + erro em `clienteTelefone`

4. Criar OS com CPF inválido
- `clienteCpf` inválido
- Esperado: 400 + erro em `clienteCpf`

5. Criar OS com CNPJ inválido
- `clienteCnpj` inválido
- Esperado: 400 + erro em `clienteCnpj`

6. Criar OS com itens de estoque insuficientes
- `itens` solicitando quantidade maior que disponível
- Esperado: 400 + erro “Estoque insuficiente”

7. Listar OS
- `GET /api/os`
- Esperado: 200 + lista do usuário logado

8. Buscar OS por ID válido
- `GET /api/os/{id}`
- Esperado: 200 + OS detalhada

9. Buscar OS inexistente
- `GET /api/os/999999`
- Esperado: 404 + “Ordem de Serviço não encontrada”

10. Atualizar OS com status válido
- `PUT /api/os/{id}` com `status` permitido
- Esperado: 200 + status atualizado

11. Atualizar OS com status inválido
- `PUT /api/os/{id}` com `status` fora do enum
- Esperado: 400 + erro de status inválido

12. Atualizar OS com transição proibida
- Ex.: `CONCLUIDA` → `EM_ANDAMENTO`
- Esperado: 400 + erro de transição inválida

13. Encerrar OS com método de pagamento
- `POST /api/os/{id}/encerrar` com `metodoPagamento`
- Esperado: 200 + OS concluída + recibo

14. Encerrar OS sem método de pagamento
- `POST /api/os/{id}/encerrar` vazio
- Esperado: 400 + erro “Método de pagamento é obrigatório”

15. Encerrar OS já concluída
- `POST /api/os/{id}/encerrar` em OS `CONCLUIDA`
- Esperado: 400 + erro “OS ja esta encerrada”

16. Enviar recibo WhatsApp com consentimento
- `POST /api/os/{id}/enviar-recibo-whatsapp`
- Esperado: 200 + `enviado=true`

17. Enviar recibo WhatsApp sem consentimento
- OS com `whatsappConsentimento=false`
- Esperado: 400 + erro de consentimento

18. Enviar recibo sem telefone e OS sem telefone
- `POST /api/os/{id}/enviar-recibo-whatsapp` sem telefone
- Esperado: 400 + erro “Telefone do cliente não informado”

19. Excluir OS
- `DELETE /api/os/{id}`
- Esperado: 200 + mensagem de sucesso
