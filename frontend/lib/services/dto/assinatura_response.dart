class AssinaturaResponse {
  final int assinaturaId;
  final String status;
  final String checkoutUrl;

  AssinaturaResponse({
    required this.assinaturaId,
    required this.status,
    required this.checkoutUrl,
  });

  factory AssinaturaResponse.fromJson(Map<String, dynamic> json) {
    return AssinaturaResponse(
      assinaturaId: json['assinaturaId'] ?? json['id'],
      status: json['status'],
      checkoutUrl: json['checkoutUrl'],
    );
  }
}
