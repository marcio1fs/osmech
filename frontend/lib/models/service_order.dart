class ServiceOrder {
  final int id;
  final String osNumber;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String vehiclePlate;
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? vehicleYear;
  final String description;
  final String? diagnostics;
  final double? estimatedCost;
  final double? finalCost;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? finishedAt;

  ServiceOrder({
    required this.id,
    required this.osNumber,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.vehiclePlate,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleYear,
    required this.description,
    this.diagnostics,
    this.estimatedCost,
    this.finalCost,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.finishedAt,
  });

  factory ServiceOrder.fromJson(Map<String, dynamic> json) {
    return ServiceOrder(
      id: json['id'],
      osNumber: json['osNumber'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      customerEmail: json['customerEmail'],
      vehiclePlate: json['vehiclePlate'],
      vehicleBrand: json['vehicleBrand'],
      vehicleModel: json['vehicleModel'],
      vehicleYear: json['vehicleYear'],
      description: json['description'],
      diagnostics: json['diagnostics'],
      estimatedCost: json['estimatedCost']?.toDouble(),
      finalCost: json['finalCost']?.toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'])
          : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'ABERTA':
        return 'Aberta';
      case 'EM_ANALISE':
        return 'Em Análise';
      case 'EM_ANDAMENTO':
        return 'Em Andamento';
      case 'AGUARDANDO_PECAS':
        return 'Aguardando Peças';
      case 'CONCLUIDA':
        return 'Concluída';
      case 'CANCELADA':
        return 'Cancelada';
      case 'ENTREGUE':
        return 'Entregue';
      default:
        return status;
    }
  }
}
