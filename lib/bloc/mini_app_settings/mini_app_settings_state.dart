part of 'mini_app_settings_bloc.dart';

abstract class MiniAppSettingsState {}

class MiniAppSettingsInitial extends MiniAppSettingsState {}

class MiniAppSettingsLoading extends MiniAppSettingsState {}

class MiniAppSettingsLoaded extends MiniAppSettingsState {
  final List<MiniAppSettings> settings;
  MiniAppSettingsLoaded(this.settings);
}

class MiniAppSettingsError extends MiniAppSettingsState {
  final String message;
  MiniAppSettingsError(this.message);
}