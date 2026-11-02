enum TicketStatus {
  waiting,
  inProgress,
  ready,
  completed,
  cancelled;

  static TicketStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'in_progress':
        return TicketStatus.inProgress;
      case 'ready':
        return TicketStatus.ready;
      case 'completed':
        return TicketStatus.completed;
      case 'cancelled':
        return TicketStatus.cancelled;
      case 'waiting':
      default:
        return TicketStatus.waiting;
    }
  }

  String toDbString() {
    switch (this) {
      case TicketStatus.inProgress:
        return 'in_progress';
      case TicketStatus.ready:
        return 'ready';
      case TicketStatus.completed:
        return 'completed';
      case TicketStatus.cancelled:
        return 'cancelled';
      case TicketStatus.waiting:
        return 'waiting';
    }
  }

  String get label {
    switch (this) {
      case TicketStatus.waiting:
        return 'Waiting';
      case TicketStatus.inProgress:
        return 'Preparing';
      case TicketStatus.ready:
        return 'Ready / Buzzed';
      case TicketStatus.completed:
        return 'Completed';
      case TicketStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class Ticket {
  final String id;
  final String businessId;
  final String shortToken;
  final int sequenceNumber;
  final String displayNumber;
  final String? customLabel;
  final TicketStatus status;
  final String? clientSessionId;
  final bool isConnected;
  final DateTime createdAt;
  final DateTime? notifiedAt;
  final DateTime? acknowledgedAt;
  final DateTime? completedAt;

  Ticket({
    required this.id,
    required this.businessId,
    required this.shortToken,
    required this.sequenceNumber,
    required this.displayNumber,
    this.customLabel,
    required this.status,
    this.clientSessionId,
    this.isConnected = false,
    required this.createdAt,
    this.notifiedAt,
    this.acknowledgedAt,
    this.completedAt,
  });

  bool get isAcknowledged => acknowledgedAt != null;

  Ticket copyWith({
    String? id,
    String? businessId,
    String? shortToken,
    int? sequenceNumber,
    String? displayNumber,
    String? customLabel,
    TicketStatus? status,
    String? clientSessionId,
    bool? isConnected,
    DateTime? createdAt,
    DateTime? notifiedAt,
    DateTime? acknowledgedAt,
    DateTime? completedAt,
  }) {
    return Ticket(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      shortToken: shortToken ?? this.shortToken,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      displayNumber: displayNumber ?? this.displayNumber,
      customLabel: customLabel ?? this.customLabel,
      status: status ?? this.status,
      clientSessionId: clientSessionId ?? this.clientSessionId,
      isConnected: isConnected ?? this.isConnected,
      createdAt: createdAt ?? this.createdAt,
      notifiedAt: notifiedAt ?? this.notifiedAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      shortToken: json['short_token'] as String,
      sequenceNumber: json['sequence_number'] as int? ?? 0,
      displayNumber: json['display_number'] as String,
      customLabel: json['custom_label'] as String?,
      status: TicketStatus.fromString(json['status'] as String? ?? 'waiting'),
      clientSessionId: json['client_session_id'] as String?,
      isConnected: json['is_connected'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      notifiedAt: json['notified_at'] != null ? DateTime.tryParse(json['notified_at'] as String) : null,
      acknowledgedAt: json['acknowledged_at'] != null ? DateTime.tryParse(json['acknowledged_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'short_token': shortToken,
      'sequence_number': sequenceNumber,
      'display_number': displayNumber,
      'custom_label': customLabel,
      'status': status.toDbString(),
      'client_session_id': clientSessionId,
      'is_connected': isConnected,
      'created_at': createdAt.toIso8601String(),
      'notified_at': notifiedAt?.toIso8601String(),
      'acknowledged_at': acknowledgedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
