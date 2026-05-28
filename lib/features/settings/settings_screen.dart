import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../export/export_service.dart';
import '../../providers.dart';
import '../../theme.dart';
import '../reminders/notification_service.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _sharing = false;

  Future<void> _toggleReminders(bool value) async {
    await ref.read(settingsProvider.notifier).setRemindersEnabled(value);
    final repo = ref.read(repositoryProvider);
    final svc = NotificationService.instance;
    if (value) {
      final granted = await svc.requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications are blocked in system settings.'),
          ),
        );
      }
    }
    await svc.rescheduleFrom(repo, DateTime.now(), enabled: value);
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final repo = ref.read(repositoryProvider);
      final hide = ref.read(settingsProvider).hideLivingOnShare;
      await ExportService.shareTree(repo, hideLivingDetails: hide);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        title: const Text('Settings'),
        iconTheme: const IconThemeData(color: kInk),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _sectionLabel('Reminders'),
          _card(
            child: SwitchListTile(
              activeThumbColor: kAccent,
              title: const Text('Birthday & anniversary reminders'),
              subtitle: const Text(
                'Notify me at 9am on the day for living relatives.',
                style: TextStyle(color: kMuted, fontSize: 13),
              ),
              value: settings.remindersEnabled,
              onChanged: _toggleReminders,
            ),
          ),
          _sectionLabel('Backup & share'),
          _card(
            child: Column(
              children: [
                SwitchListTile(
                  activeThumbColor: kAccent,
                  title: const Text('Hide living people on share'),
                  subtitle: const Text(
                    'Redact dates, bios, events and stories for living '
                    'relatives in exported files.',
                    style: TextStyle(color: kMuted, fontSize: 13),
                  ),
                  value: settings.hideLivingOnShare,
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .setHideLivingOnShare(v),
                ),
                const Divider(height: 1, color: kLine),
                ListTile(
                  leading: _sharing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share_rounded, color: kAccent),
                  title: const Text('Export & share family tree'),
                  subtitle: const Text(
                    'Portable .zip — tree data plus photos.',
                    style: TextStyle(color: kMuted, fontSize: 13),
                  ),
                  onTap: _sharing ? null : _share,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text(
              'Heirloom keeps everything on this device. Exports let you back '
              'up or move your tree.',
              style: TextStyle(color: kMuted, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: kMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      );

  Widget _card({required Widget child}) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: kLine),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
}
