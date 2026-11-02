import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ticket.dart';
import '../models/business.dart';
import '../core/supabase_client.dart';

final currentBusinessProvider = StateProvider<Business>((ref) {
  return Business(
    id: 'b1111111-1111-1111-1111-111111111111',
    name: 'Pingili Gourmet Burgers & Shakes',
    slug: 'gourmet-burgers',
    themeColor: '#f97316',
    tagline: 'Freshly Crafted, Notified Fast',
  );
});

class QueueNotifier extends StateNotifier<AsyncValue<List<Ticket>>> {
  final Ref ref;

  QueueNotifier(this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  // Pre-seeded mock tickets for instant offline QA
  final List<Ticket> _mockTickets = [
    Ticket(
      id: 't-041',
      businessId: 'b1111111-1111-1111-1111-111111111111',
      shortToken: 'demo041',
      sequenceNumber: 41,
      displayNumber: '#041',
      customLabel: 'Double Smash + Truffle Fries',
      status: TicketStatus.inProgress,
      isConnected: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    Ticket(
      id: 't-042',
      businessId: 'b1111111-1111-1111-1111-111111111111',
      shortToken: 'demo042',
      sequenceNumber: 42,
      displayNumber: '#042',
      customLabel: 'Sarah - Vanilla Milkshake',
      status: TicketStatus.waiting,
      isConnected: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    Ticket(
      id: 't-043',
      businessId: 'b1111111-1111-1111-1111-111111111111',
      shortToken: 'demo043',
      sequenceNumber: 43,
      displayNumber: '#043',
      customLabel: 'Alex - Spicy Chicken Burger',
      status: TicketStatus.ready,
      isConnected: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      notifiedAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  int _mockSequence = 43;

  Future<void> _init() async {
    final business = ref.read(currentBusinessProvider);

    if (SupabaseConfig.isLiveConfigured && SupabaseConfig.client != null) {
      try {
        final client = SupabaseConfig.client!;
        final response = await client
            .from('tickets')
            .select()
            .eq('business_id', business.id)
            .order('created_at', ascending: false);

        final tickets = (response as List)
            .map((row) => Ticket.fromJson(row as Map<String, dynamic>))
            .toList();

        state = AsyncValue.data(tickets);

        // Subscribe to realtime changes
        client
            .channel('business_tickets_${business.id}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'tickets',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'business_id',
                value: business.id,
              ),
              callback: (payload) {
                _refreshFromDb();
              },
            )
            .subscribe();
      } catch (e, st) {
        state = AsyncValue.error(e, st);
      }
    } else {
      // Mock mode: Load pre-seeded tickets
      state = AsyncValue.data(List.from(_mockTickets));
    }
  }

  Future<void> _refreshFromDb() async {
    final business = ref.read(currentBusinessProvider);
    if (!SupabaseConfig.isLiveConfigured || SupabaseConfig.client == null) return;

    try {
      final response = await SupabaseConfig.client!
          .from('tickets')
          .select()
          .eq('business_id', business.id)
          .order('created_at', ascending: false);

      final tickets = (response as List)
          .map((row) => Ticket.fromJson(row as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(tickets);
    } catch (_) {}
  }

  Future<Ticket> createTicket(String? customLabel) async {
    final business = ref.read(currentBusinessProvider);

    if (SupabaseConfig.isLiveConfigured && SupabaseConfig.client != null) {
      final response = await SupabaseConfig.client!.rpc(
        'create_daily_ticket',
        params: {
          'p_business_id': business.id,
          'p_custom_label': customLabel,
        },
      );
      final newTicket = Ticket.fromJson(response as Map<String, dynamic>);
      await _refreshFromDb();
      return newTicket;
    }

    // Mock ticket creation
    _mockSequence++;
    final token = _generateRandomToken();
    final newTicket = Ticket(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      businessId: business.id,
      shortToken: token,
      sequenceNumber: _mockSequence,
      displayNumber: '#${_mockSequence.toString().padLeft(3, '0')}',
      customLabel: customLabel?.trim().isEmpty == true ? null : customLabel?.trim(),
      status: TicketStatus.waiting,
      isConnected: false,
      createdAt: DateTime.now(),
    );

    _mockTickets.insert(0, newTicket);
    state = AsyncValue.data(List.from(_mockTickets));
    return newTicket;
  }

  Future<void> updateStatus(String ticketId, TicketStatus newStatus) async {
    if (SupabaseConfig.isLiveConfigured && SupabaseConfig.client != null) {
      await SupabaseConfig.client!.rpc(
        'update_ticket_status',
        params: {
          'p_ticket_id': ticketId,
          'p_new_status': newStatus.toDbString(),
        },
      );
      await _refreshFromDb();
      return;
    }

    // Mock update
    final currentList = state.value ?? [];
    final updatedList = currentList.map((t) {
      if (t.id == ticketId) {
        return t.copyWith(
          status: newStatus,
          notifiedAt: newStatus == TicketStatus.ready ? DateTime.now() : t.notifiedAt,
          completedAt: newStatus == TicketStatus.completed ? DateTime.now() : t.completedAt,
        );
      }
      return t;
    }).toList();

    state = AsyncValue.data(updatedList);
  }

  Future<void> buzzTicket(String ticketId) async {
    await updateStatus(ticketId, TicketStatus.ready);
  }

  Future<void> rePingTicket(String ticketId) async {
    final currentList = state.value ?? [];
    final updatedList = currentList.map((t) {
      if (t.id == ticketId) {
        return t.copyWith(notifiedAt: DateTime.now());
      }
      return t;
    }).toList();
    state = AsyncValue.data(updatedList);
  }

  String _generateRandomToken() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
    final rand = Random();
    return List.generate(7, (index) => chars[rand.nextInt(chars.length)]).join();
  }
}

final queueProvider = StateNotifierProvider<QueueNotifier, AsyncValue<List<Ticket>>>((ref) {
  return QueueNotifier(ref);
});
