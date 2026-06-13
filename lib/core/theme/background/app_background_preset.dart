enum AppBackgroundPreset {
  none,
  aurora,
  mesh,
  sunrise,
  paper,
  custom,
}

extension AppBackgroundPresetX on AppBackgroundPreset {
  String get storageKey => switch (this) {
        AppBackgroundPreset.none => 'none',
        AppBackgroundPreset.aurora => 'aurora',
        AppBackgroundPreset.mesh => 'mesh',
        AppBackgroundPreset.sunrise => 'sunrise',
        AppBackgroundPreset.paper => 'paper',
        AppBackgroundPreset.custom => 'custom',
      };

  String get title => switch (this) {
        AppBackgroundPreset.none => 'Без фона',
        AppBackgroundPreset.aurora => 'Aurora',
        AppBackgroundPreset.mesh => 'Mesh',
        AppBackgroundPreset.sunrise => 'Sunrise',
        AppBackgroundPreset.paper => 'Paper',
        AppBackgroundPreset.custom => 'Своя картинка',
      };

  double get opacity => switch (this) {
        AppBackgroundPreset.none => 0,
        AppBackgroundPreset.aurora => 0.18,
        AppBackgroundPreset.mesh => 0.16,
        AppBackgroundPreset.sunrise => 0.14,
        AppBackgroundPreset.paper => 0.1,
        AppBackgroundPreset.custom => 0.24,
      };

  static AppBackgroundPreset fromStorageKey(String? value) {
    return AppBackgroundPreset.values.firstWhere(
      (preset) => preset.storageKey == value,
      orElse: () => AppBackgroundPreset.none,
    );
  }
}
