import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

extension ChessGridContextL10n on BuildContext {
  AppLocalizations? get l10n => AppLocalizations.of(this);

  String tr(String key, {String? fallback}) {
    final value = l10n?.translate(key);
    if (value != null && value.isNotEmpty && value != key) {
      final generatedTitleCase = key
          .split('_')
          .where((part) => part.isNotEmpty)
          .map((part) => part[0].toUpperCase() + part.substring(1))
          .join(' ');
      if (value != generatedTitleCase) {
        return value;
      }
    }
    return fallback ?? key;
  }
}

class ChessGridL10n {
  static String tr(BuildContext context, String key, {String? fallback}) {
    final value = AppLocalizations.of(context)?.translate(key);
    if (value != null && value.isNotEmpty && value != key) {
      final generatedTitleCase = key
          .split('_')
          .where((part) => part.isNotEmpty)
          .map((part) => part[0].toUpperCase() + part.substring(1))
          .join(' ');
      if (value != generatedTitleCase) {
        return value;
      }
    }
    return fallback ?? key;
  }

  static String statusLabel(BuildContext context, ApartmentStatus status) {
    final key = switch (status) {
      ApartmentStatus.available => 'chess_grid_available',
      ApartmentStatus.booked => 'chess_grid_booked',
      ApartmentStatus.sold => 'chess_grid_sold',
      ApartmentStatus.reserved => 'chess_grid_reserved',
    };
    return tr(context, key, fallback: status.labelRu);
  }

  static String dealTypeLabel(BuildContext context, DealType dealType) {
    final key = switch (dealType) {
      DealType.cash => 'chess_grid_deal_cash',
      DealType.installment => 'chess_grid_deal_installment',
      DealType.mixed => 'chess_grid_deal_mixed',
    };
    return tr(context, key, fallback: dealType.labelRu);
  }

  static String orderStatusLabel(BuildContext context, OrderStatus status) {
    final key = switch (status) {
      OrderStatus.inProgress => 'chess_grid_order_in_progress',
      OrderStatus.success => 'chess_grid_order_success',
      OrderStatus.rejected => 'chess_grid_order_rejected',
    };
    return tr(context, key, fallback: status.labelRu);
  }

  static String complexPlural(BuildContext context, int count) {
    final l10n = AppLocalizations.of(context);
    final lang = l10n?.locale.languageCode ?? 'ru';
    if (lang == 'uz') {
      return l10n?.translate('chess_grid_plural_complex_many') ?? 'majmualar';
    }
    if (lang == 'en') {
      return count == 1
          ? (l10n?.translate('chess_grid_plural_complex_one') ?? 'complex')
          : (l10n?.translate('chess_grid_plural_complex_many') ?? 'complexes');
    }
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) {
      return l10n?.translate('chess_grid_plural_complex_one') ?? 'комплекс';
    }
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return l10n?.translate('chess_grid_plural_complex_few') ?? 'комплекса';
    }
    return l10n?.translate('chess_grid_plural_complex_many') ?? 'комплексов';
  }

  static String buildingPlural(BuildContext context, int count) {
    final l10n = AppLocalizations.of(context);
    final lang = l10n?.locale.languageCode ?? 'ru';
    if (lang == 'uz') {
      return l10n?.translate('chess_grid_plural_building_many') ?? 'korpuslar';
    }
    if (lang == 'en') {
      return count == 1
          ? (l10n?.translate('chess_grid_plural_building_one') ?? 'building')
          : (l10n?.translate('chess_grid_plural_building_many') ?? 'buildings');
    }
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) {
      return l10n?.translate('chess_grid_plural_building_one') ?? 'корпус';
    }
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return l10n?.translate('chess_grid_plural_building_few') ?? 'корпуса';
    }
    return l10n?.translate('chess_grid_plural_building_many') ?? 'корпусов';
  }

  static String apartmentPlural(BuildContext context, int count) {
    final l10n = AppLocalizations.of(context);
    final lang = l10n?.locale.languageCode ?? 'ru';
    if (lang == 'uz') {
      return l10n?.translate('chess_grid_plural_apt_many') ?? 'kvartiralar';
    }
    if (lang == 'en') {
      return count == 1
          ? (l10n?.translate('chess_grid_plural_apt_one') ?? 'apartment')
          : (l10n?.translate('chess_grid_plural_apt_many') ?? 'apartments');
    }
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) {
      return l10n?.translate('chess_grid_plural_apt_one') ?? 'квартира';
    }
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return l10n?.translate('chess_grid_plural_apt_few') ?? 'квартиры';
    }
    return l10n?.translate('chess_grid_plural_apt_many') ?? 'квартир';
  }
}

