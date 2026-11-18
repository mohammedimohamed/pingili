class PairingSession {
  final String id;
  final String businessId;
  final String pairingCode;
  final String clientSessionId;
  final int visitCount;
  final String status;
  final DateTime createdAt;

  PairingSession({
    required this.id,
    required this.businessId,
    required this.pairingCode,
    required this.clientSessionId,
    this.visitCount = 1,
    this.status = 'waiting_pair',
    required this.createdAt,
  });

  factory PairingSession.fromJson(Map<String, dynamic> json) {
    return PairingSession(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      pairingCode: json['pairing_code'] as String,
      clientSessionId: json['client_session_id'] as String,
      visitCount: json['visit_count'] as int? ?? 1,
      status: json['status'] as String? ?? 'waiting_pair',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
