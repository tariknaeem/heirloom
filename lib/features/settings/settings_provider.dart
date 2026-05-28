import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_service.dart';

final settingsServiceProvider =
    Provider<SettingsService>((ref) => SettingsService());

/// Loads + holds [AppSettings], persisting every change to disk.
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._service) : super(const AppSettings()) {
    _load();
  }

  final SettingsService _service;

  Future<void> _load() async {
    state = await _service.load();
  }

  Future<void> setRemindersEnabled(bool v) async {
    state = state.copyWith(remindersEnabled: v);
    await _service.save(state);
  }

  Future<void> setHideLivingOnShare(bool v) async {
    state = state.copyWith(hideLivingOnShare: v);
    await _service.save(state);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(settingsServiceProvider));
});
