import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/ticket.dart';
import '../providers/queue_provider.dart';
import 'qr_modal.dart';

class QueueDashboardScreen extends ConsumerStatefulWidget {
  const QueueDashboardScreen({super.key});

  @override
  ConsumerState<QueueDashboardScreen> createState() => _QueueDashboardScreenState();
}

class _QueueDashboardScreenState extends ConsumerState<QueueDashboardScreen> {
  bool _isKanbanView = true;

  void _showNewTicketDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Issue New Ticket',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Optional label (Customer Name, Table, or Order #):',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. John - Table 4',
                hintStyle: const TextStyle(color: Color(0xFF475569)),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFF97316), width: 2),
                ),
              ),
              onSubmitted: (_) {
                Navigator.of(ctx).pop();
                _createAndShowQr(textController.text);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _createAndShowQr(textController.text);
            },
            child: const Text('Generate Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _createAndShowQr(String label) async {
    final ticket = await ref.read(queueProvider.notifier).createTicket(label);
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => QrModal(ticket: ticket),
    );
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(currentBusinessProvider);
    final queueState = ref.watch(queueProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF97316),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'P',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text(
                  'Pingili Cashier Station • Phase 1 MVP',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // View Switcher (Kanban vs List)
          IconButton(
            icon: Icon(
              _isKanbanView ? Icons.view_agenda_outlined : Icons.view_column_outlined,
              color: Colors.white70,
            ),
            tooltip: _isKanbanView ? 'Switch to List View' : 'Switch to Kanban View',
            onPressed: () => setState(() => _isKanbanView = !_isKanbanView),
          ),
          const SizedBox(width: 8),

          // Primary + New Ticket Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 20),
              label: const Text('New Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: _showNewTicketDialog,
            ),
          ),
        ],
      ),
      body: queueState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFF97316)),
        ),
        error: (err, _) => Center(
          child: Text('Error loading queue: $err', style: const TextStyle(color: Colors.redAccent)),
        ),
        data: (tickets) {
          final activeTickets = tickets.where((t) => t.status != TicketStatus.cancelled).toList();

          if (activeTickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.confirmation_number_outlined, size: 64, color: Color(0xFF334155)),
                  const SizedBox(height: 16),
                  const Text(
                    'No active tickets',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap "New Ticket" to generate a QR code for your customer.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Ticket'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _showNewTicketDialog,
                  ),
                ],
              ),
            );
          }

          if (!_isKanbanView) {
            return _buildListView(activeTickets);
          }

          return _buildKanbanView(activeTickets);
        },
      ),
    );
  }

  Widget _buildKanbanView(List<Ticket> tickets) {
    final waiting = tickets.where((t) => t.status == TicketStatus.waiting).toList();
    final inProgress = tickets.where((t) => t.status == TicketStatus.inProgress).toList();
    final ready = tickets.where((t) => t.status == TicketStatus.ready).toList();
    final completed = tickets.where((t) => t.status == TicketStatus.completed).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKanbanColumn('Queued', waiting, const Color(0xFF64748B)),
              _buildKanbanColumn('Preparing', inProgress, const Color(0xFF0284C7)),
              _buildKanbanColumn('Ready / Buzzed', ready, const Color(0xFFF97316)),
              _buildKanbanColumn('Completed', completed, const Color(0xFF10B981)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKanbanColumn(String title, List<Ticket> items, Color headerColor) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: const Color(0xFF1E293B))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: headerColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length}',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Cards
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (ctx, idx) => _buildTicketCard(items[idx]),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<Ticket> tickets) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      itemBuilder: (ctx, idx) => _buildTicketCard(tickets[idx]),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    final notifier = ref.read(queueProvider.notifier);
    final timeStr = DateFormat('h:mm a').format(ticket.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ticket.status == TicketStatus.ready
              ? const Color(0xFFF97316)
              : const Color(0xFF334155),
          width: ticket.status == TicketStatus.ready ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Number, Presence & Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ticket.displayNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),

              Row(
                children: [
                  // Presence indicator dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: ticket.isConnected ? const Color(0xFF10B981) : const Color(0xFF64748B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ticket.isConnected ? 'Connected' : 'Unscanned',
                    style: TextStyle(
                      color: ticket.isConnected ? const Color(0xFF34D399) : const Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),

          if (ticket.customLabel != null && ticket.customLabel!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              ticket.customLabel!,
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],

          if (ticket.isAcknowledged) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF065F46),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 14, color: Color(0xFF34D399)),
                  SizedBox(width: 4),
                  Text(
                    'Customer Coming!',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              // Show QR code button
              IconButton(
                icon: const Icon(Icons.qr_code, size: 20, color: Color(0xFF94A3B8)),
                tooltip: 'Show QR Code',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => QrModal(ticket: ticket),
                  );
                },
              ),
              const Spacer(),

              // State progression buttons
              if (ticket.status == TicketStatus.waiting)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => notifier.updateStatus(ticket.id, TicketStatus.inProgress),
                  child: const Text('Start Prep', style: TextStyle(fontSize: 12)),
                ),

              if (ticket.status == TicketStatus.inProgress)
                ElevatedButton.icon(
                  icon: const Icon(Icons.notifications_active, size: 16),
                  label: const Text('Buzz Ready!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => notifier.buzzTicket(ticket.id),
                ),

              if (ticket.status == TicketStatus.ready) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.repeat, size: 14),
                  label: const Text('Re-Ping', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF97316),
                    side: const BorderSide(color: Color(0xFFF97316)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => notifier.rePingTicket(ticket.id),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => notifier.updateStatus(ticket.id, TicketStatus.completed),
                  child: const Text('Done ✅', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
