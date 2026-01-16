class Usuario {
  final int? usuarioId;
  final String nomeOficina;
  final String email;

  Usuario({
    this.usuarioId,
    required this.nomeOficina,
    required this.email,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      usuarioId: json['usuarioId'] as int?,
      nomeOficina: json['nomeOficina'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usuarioId': usuarioId,
      'nomeOficina': nomeOficina,
      'email': email,
    };
  }
}

class AuthResponse {
  final String token;
  final String tipo;
  final int usuarioId;
  final String nomeOficina;
  final String email;

  AuthResponse({
    required this.token,
    required this.tipo,
    required this.usuarioId,
    required this.nomeOficina,
    required this.email,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      tipo: json['tipo'] as String,
      usuarioId: json['usuarioId'] as int,
      nomeOficina: json['nomeOficina'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'tipo': tipo,
      'usuarioId': usuarioId,
      'nomeOficina': nomeOficina,
      'email': email,
    };
  }
}
