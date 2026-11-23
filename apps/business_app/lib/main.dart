import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/supabase_client.dart';
import 'models/business.dart';
import 'providers/queue_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/queue_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();

  Business? initialBusiness;
  bool needsOnboarding = false;

  if (SupabaseConfig.isLiveConfigured && SupabaseConfig.client != null) {
    final client = SupabaseConfig.client!;
    final user = client.auth.currentUser;
    if (user != null) {
      final data = await client
          .from('businesses')
          .select()
          .eq('owner_id', user.id)
          .maybeSingle();
      if (data != null) {
        initialBusiness = Business.fromJson(data);
      } else {
        needsOnboarding = true;
      }
    } else {
      needsOnboarding = true;
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        if (initialBusiness != null)
          currentBusinessProvider.overrideWith((ref) => initialBusiness!),
      ],
      child: PingiliBusinessApp(needsOnboarding: needsOnboarding),
    ),
  );
}

class PingiliBusinessApp extends StatelessWidget {
  final bool needsOnboarding;

  const PingiliBusinessApp({super.key, this.needsOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pingili Business Pager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020617),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF97316),
          secondary: Color(0xFF0284C7),
          surface: Color(0xFF0F172A),
        ),
      ),
      home: needsOnboarding ? const OnboardingScreen() : const QueueDashboardScreen(),
    );
  }
}
