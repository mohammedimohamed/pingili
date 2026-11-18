import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pairing_session.dart';
import '../models/ticket.dart';
import '../core/supabase_client.dart';
import 'queue_provider.dart';

class PairingNotifier extends StateNotifier<List<PairingSession>> {
  final Ref ref;

  PairingNotifier(this.ref) : super([]) {
    _init();
  }

  Future<void> _init() async {
    final business = ref.read(currentBusinessProvider);

    if (SupabaseConfig.isLiveConfigured && SupabaseConfig.client != null) {
      final client = SupabaseConfig.client!;
      await _refresh();

      client
          .channel('pairing_waiting_${business.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'pairing_sessions',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'business_id',
              value: business.id,
            ),
            callback: (_) => _refresh(),
          )
          .subscribe();
    } else {
      // Mock waiting customers who just scanned the counter sticker
      state = [
        PairingSession(
          id: 'pair-1',
          businessId: business.id,
          pairingCode: '4821',
          clientSessionId: 'client_abc123',
          visitCount: 3,
          createdAt: DateTime.now().subtract(const Duration(seconds: 15)),
        ),
        PairingSession(
          id: 'pair-2',
          businessId: business.id,
          pairingCode: '9104',
          clientSessionId: 'client_xyz789',
          visitCount: 1,
          createdAt: DateTime.now().subtract(const Duration(seconds: 5)),
        ),
      ];
    }
  }

  Future<void> _refresh() async {
    final business = ref.read(currentBusinessProvider);
    if (!SupabaseConfig.isLiveConfigured || SupabaseConfig.client == null) return;

    final response = await SupabaseConfig.client!
        .from('pairing_sessions')
        .select()
        .eq('business_id', business.id)
        .eq('status', 'waiting_pair')
        .order('created_at', ascending: true);

    state = (response as List)
        .map((row) => PairingSession.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// 1-Tap Magic: Cashier taps a 4-digit code to create & link a ticket immediately
  Future<Ticket> pairSession(PairingSession session, {String? customLabel}) async {
    if (SupabaseConfig.isLiveConfigured && SupabaseConfig.client != null) {
      final response = await SupabaseConfig.client!.rpc(
        'pair_session_to_ticket',
        params: {
          'p_pairing_id': session.id,
          'p_custom_label': customLabel,
        },
      );
      await _refresh();
      return Ticket.fromJson(response as Map<String, dynamic>);
    }

    // Mock 1-tap pairing
    state = state.where((s) => s.id != session.id).toList();
    final label = customLabel ??
        (session.visitCount > 1
            ? 'Returning Guest (Visit #${session.visitCount})'
            : 'Counter Check-In (${session.pairingCode})');
    return ref.read(queueProvider.notifier).createTicket(label);
  }
}

final pairingQueueProvider =
    StateNotifierProvider<PairingNotifier, List<PairingSession>>((ref) {
  return PairingNotifier(ref);
});
