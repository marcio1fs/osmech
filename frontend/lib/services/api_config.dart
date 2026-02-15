/// Configurações globais da API.
class ApiConfig {
  // Alterar para o IP/domínio correto em produção.
  // Para emulador Android: 10.0.2.2
  // Para dispositivo físico: IP da máquina na rede local
  // Para Chrome/Windows: localhost
  static const String baseUrl = 'http://localhost:8081/api';

  // Timeout padrão em segundos
  static const int timeoutSeconds = 30;
}
