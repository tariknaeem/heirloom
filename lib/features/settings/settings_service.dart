import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// User settings, persisted as a small JSON file in the app documents dir.
/// Kept dependency-free (no shared_preferences / no db migration).
class AppSettings {
  final bool remindersEnabled;
  final bool hideLivingOnShare;

  const AppSettings({
    this.remindersEnabled = true,
    this.hideLivingOnShare = true,
  });

  AppSettings copyWith({bool? remindersEnabled, bool? hideLivingOnShare}) =>
      AppSettings(
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        hideLivingOnShare: hideLivingOnShare ?? this.hideLivingOnShare,
      );

  Map<String, Object?> toMap() => {
        'remindersEnabled': remindersEnabled,
        'hideLivingOnShare': hideLivingOnShare,
      };

  static AppSettings fromMap(Map<String, Object?> m) => AppSettings(
        remindersEnabled: m['remindersEnabled'] as bool? ?? true,
        hideLivingOnShare: m['hideLivingOnShare'] as bool? ?? true,
      );
}

class SettingsService {
  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'settings.json'));
  }

  Future<AppSettings> load() async {
    try {
      final f = await _file();
      if (!f.existsSync()) return const AppSettings();
      final map = jsonDecode(await f.readAsString()) as Map<String, Object?>;
      return AppSettings.fromMap(map);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings s) async {
    final f = await _file();
    await f.writeAsString(jsonEncode(s.toMap()), flush: true);
  }
}
