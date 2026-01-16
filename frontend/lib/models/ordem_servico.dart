class OrdemServico {
  final int? id;
  final int? clienteId;
  final String nomeCliente;
  final String telefone;
  final int? veiculoId;
  final String placa;
  final String modelo;
  final String descricaoProblema;
  final String servicosRealizados;
  final double valor;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrdemServico({
    this.id,
    this.clienteId,
    required this.nomeCliente,
    required this.telefone,
    this.veiculoId,
    required this.placa,
    required this.modelo,
    required this.descricaoProblema,
    required this.servicosRealizados,
    required this.valor,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory OrdemServico.fromJson(Map<String, dynamic> json) {
    return OrdemServico(
      id: json['id'] as int?,
      clienteId: json['clienteId'] as int?,
      nomeCliente: json['nomeCliente'] as String,
      telefone: json['telefone'] as String,
      veiculoId: json['veiculoId'] as int?,
      placa: json['placa'] as String,
      modelo: json['modelo'] as String,
      descricaoProblema: json['descricaoProblema'] as String,
      servicosRealizados: json['servicosRealizados'] as String,
      valor: (json['valor'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clienteId': clienteId,
      'nomeCliente': nomeCliente,
      'telefone': telefone,
      'veiculoId': veiculoId,
      'placa': placa,
      'modelo': modelo,
      'descricaoProblema': descricaoProblema,
      'servicosRealizados': servicosRealizados,
      'valor': valor,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  OrdemServico copyWith({
    int? id,
    int? clienteId,
    String? nomeCliente,
    String? telefone,
    int? veiculoId,
    String? placa,
    String? modelo,
    String? descricaoProblema,
    String? servicosRealizados,
    double? valor,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrdemServico(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      nomeCliente: nomeCliente ?? this.nomeCliente,
      telefone: telefone ?? this.telefone,
      veiculoId: veiculoId ?? this.veiculoId,
      placa: placa ?? this.placa,
      modelo: modelo ?? this.modelo,
      descricaoProblema: descricaoProblema ?? this.descricaoProblema,
      servicosRealizados: servicosRealizados ?? this.servicosRealizados,
      valor: valor ?? this.valor,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum StatusOS {
  aberta('ABERTA', 'Aberta'),
  emAndamento('EM_ANDAMENTO', 'Em Andamento'),
  concluida('CONCLUIDA', 'Concluída');

  final String value;
  final String label;

  const StatusOS(this.value, this.label);

  static StatusOS fromValue(String value) {
    return StatusOS.values.firstWhere(
      (status) => status.value == value,
      orElse: () => StatusOS.aberta,
    );
  }
}
