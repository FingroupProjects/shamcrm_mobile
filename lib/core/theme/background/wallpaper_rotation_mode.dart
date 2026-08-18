enum WallpaperRotationMode {
  onLaunch,
  shuffleOnLaunch,
  interval,
  daily,
  manual,
}

extension WallpaperRotationModeX on WallpaperRotationMode {
  String get storageKey => switch (this) {
        WallpaperRotationMode.onLaunch => 'on_launch',
        WallpaperRotationMode.shuffleOnLaunch => 'shuffle_on_launch',
        WallpaperRotationMode.interval => 'interval',
        WallpaperRotationMode.daily => 'daily',
        WallpaperRotationMode.manual => 'manual',
      };

  String get title => switch (this) {
        WallpaperRotationMode.onLaunch => 'При каждом входе',
        WallpaperRotationMode.shuffleOnLaunch => 'Случайно при входе',
        WallpaperRotationMode.interval => 'По таймеру',
        WallpaperRotationMode.daily => 'Раз в сутки',
        WallpaperRotationMode.manual => 'Вручную',
      };

  String get subtitle => switch (this) {
        WallpaperRotationMode.onLaunch =>
          'Следующее фото при каждом открытии приложения.',
        WallpaperRotationMode.shuffleOnLaunch =>
          'Случайное фото из выбранных при каждом входе.',
        WallpaperRotationMode.interval =>
          'Фон меняется автоматически через заданный интервал.',
        WallpaperRotationMode.daily =>
          'Новое фото один раз в календарные сутки.',
        WallpaperRotationMode.manual =>
          'Меняйте фото стрелками, автосмена выключена.',
      };

  static WallpaperRotationMode fromStorageKey(String? value) {
    return WallpaperRotationMode.values.firstWhere(
      (mode) => mode.storageKey == value,
      orElse: () => WallpaperRotationMode.onLaunch,
    );
  }
}
