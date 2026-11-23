import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../models/business.dart';
import '../providers/queue_provider.dart';
import 'queue_dashboard_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  String _selectedColor = '#f97316';
  bool _isLoading = false;
  String? _error;

  final List<String> _colors = [
    '#f97316', // Orange
    '#0284c7', // Sky Blue
    '#10b981', // Emerald
    '#8b5cf6', // Violet
    '#ef4444', // Red
    '#ec4899', // Pink
  ];

  String _generateSlug(String name) {
    final clean = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final suffix = (1000 + Random().nextInt(9000)).toString();
    return '${clean.isEmpty ? 'biz' : clean}-$suffix';
  }

  Future<void> _startBusiness() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your business name');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = SupabaseConfig.client;
      if (client != null) {
        // 1. Anonymous sign-in (zero login friction)
        if (client.auth.currentUser == null) {
          await client.auth.signInAnonymously();
        }
        final userId = client.auth.currentUser!.id;
        final slug = _generateSlug(name);

        // 2. Create business row
        final data = await client
            .from('businesses')
            .insert({
              'owner_id': userId,
              'name': name,
              'slug': slug,
              'theme_color': _selectedColor,
              'tagline': 'Order Ready Notification',
            })
            .select()
            .single();

        final business = Business.fromJson(data);
        ref.read(currentBusinessProvider.notifier).state = business;
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const QueueDashboardScreen()),
      );
    } catch (e) {
      setState(() => _error = 'Setup failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.notifications_active, color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome to Pingili',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Set up your digital pager in 5 seconds.\nNo email or password required.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Business Name',
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g. Cafe Medina',
                      hintStyle: const TextStyle(color: Color(0xFF475569)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                    ),
                    onSubmitted: (_) => _startBusiness(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Brand Color',
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _colors.map((hex) {
                      final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                      final isSelected = _selectedColor == hex;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = hex),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                          ),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isLoading ? null : _startBusiness,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Start Using Pingili 🚀',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
