import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/home_shell.dart';
import 'features/reminders/notification_service.dart';
import 'features/settings/settings_provider.dart';
import 'providers.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: HeirloomApp()));
}

class HeirloomApp extends ConsumerStatefulWidget {
  const HeirloomApp({super.key});

  @override
  ConsumerState<HeirloomApp> createState() => _HeirloomAppState();
}

class _HeirloomAppState extends ConsumerState<HeirloomApp> {
  @override
  void initState() {
    super.initState();
    // Re-sync scheduled birthday/anniversary reminders to current data on each
    // launch (covers added people + survives the inexact-schedule window).
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncReminders());
  }

  Future<void> _syncReminders() async {
    try {
      final settings = await ref.read(settingsServiceProvider).load();
      final repo = ref.read(repositoryProvider);
      await NotificationService.instance.rescheduleFrom(
        repo,
        DateTime.now(),
        enabled: settings.remindersEnabled,
      );
    } catch (_) {
      // Reminders are best-effort; never block app startup on them.
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Heirloom',
        debugShowCheckedModeBanner: false,
        theme: heirloomTheme(),
        home: const HomeShell(),
      );
}
