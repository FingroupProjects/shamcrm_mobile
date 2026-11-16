import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/firebase/firebase_api.dart';
import 'package:crm_task_manager/app/app_keys.dart';
import 'package:crm_task_manager/core/navigation/lead_deep_link.dart';
import 'package:crm_task_manager/models/workday/workday_status_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Открывает лид из ссылки после входа в приложение.
/// До PIN ссылка ждёт: запрос на сервер уходит уже из сессии пользователя.
class LeadLinkCoordinator {
  LeadLinkCoordinator._();

  static final LeadLinkCoordinator instance = LeadLinkCoordinator._();

  static const MethodChannel _channel =
      MethodChannel('com.softtech.crm_task_manager/widget');

  final ApiService _api = ApiService();

  bool _homeReady = false;
  bool _opening = false;
  OverlayEntry? _loader;
  String? _pending;
  String? _handlingUrl;

  void receive(String raw) {
    final url = raw.trim();
    if (url.isEmpty) return;
    if (_handlingUrl == url || _pending == url) return;
    _pending = url;
    if (_homeReady) {
      unawaited(_drain());
    }
  }

  Future<void> markHomeReady() async {
    _homeReady = true;
    await _pullNativePending();
    await _drain();
  }

  void markHomeNotReady() {
    _homeReady = false;
  }

  Future<void> _pullNativePending() async {
    try {
      final url = await _channel.invokeMethod<String>('getPendingLeadLink');
      if (url == null || url.trim().isEmpty) return;
      final trimmed = url.trim();
      if (_handlingUrl == trimmed || _pending == trimmed) return;
      _pending = trimmed;
    } catch (error) {
      debugPrint('LeadLink: pending read failed: $error');
    }
  }

  Future<void> _drain() async {
    if (!_homeReady || _opening) return;
    final url = _pending;
    if (url == null) return;

    _pending = null;
    _opening = true;
    _handlingUrl = url;
    try {
      await _channel.invokeMethod<void>('ackPendingLeadLink');
    } catch (error) {
      debugPrint('LeadLink: ack failed: $error');
    }

    try {
      await _open(url);
    } finally {
      _opening = false;
      _handlingUrl = null;
      if (_pending != null && _homeReady) {
        await _drain();
      }
    }
  }

  Future<void> _open(String raw) async {
    final link = LeadDeepLink.tryParse(raw);
    if (link == null) return;
    // Домен просто открыл приложение. Конкретной карточки в адресе нет.
    if (link.section == ShamcrmLinkSection.app || link.entityId == null) {
      return;
    }

    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      _pending = raw;
      _homeReady = false;
      return;
    }

    _showLoader();
    var switchedOrganization = false;
    var switchedFunnel = false;
    String? previousOrganization;
    String? previousFunnel;

    try {
      final entered = await _api.getEnteredDomain();
      final verified = await _api.getVerifiedDomain();
      final sameTenant = leadLinkMatchesSignedInTenant(
        linkHost: link.host,
        enteredDomain: entered['enteredDomain'],
        enteredMainDomain: entered['enteredMainDomain'],
        verifiedDomain: verified,
      );
      if (!sameTenant) {
        _hideLoader();
        _showNoAccess();
        return;
      }

      previousOrganization = await _api.getSelectedOrganization();
      previousFunnel = await _api.getSelectedSalesFunnel();

      if (link.organizationId != null) {
        final organizations = await _api.getOrganization();
        final allowed = organizations.any(
          (organization) => organization.id == link.organizationId,
        );
        if (!allowed) {
          _hideLoader();
          _showNoAccess();
          return;
        }
        await _api.saveSelectedOrganization(link.organizationId.toString());
        switchedOrganization = true;
      }

      if (link.salesFunnelId != null) {
        final funnels = await _api.getSalesFunnels();
        final allowed = funnels.any((funnel) => funnel.id == link.salesFunnelId);
        if (!allowed) {
          await _restoreSelection(
            switchedOrganization: switchedOrganization,
            switchedFunnel: false,
            previousOrganization: previousOrganization,
            previousFunnel: previousFunnel,
          );
          _hideLoader();
          _showNoAccess();
          return;
        }
        await _api.saveSelectedSalesFunnel(link.salesFunnelId.toString());
        switchedFunnel = true;
      }

      if (link.section != ShamcrmLinkSection.lead) {
        _hideLoader();
        final id = link.entityId.toString();
        await FirebaseApi().navigateToSpecificScreen(
          link.navigationType ?? '',
          id,
          {
            'id': id,
            'lead_id': id,
            'deal_id': id,
            'task_id': id,
            'event_id': id,
            'notice_id': id,
            'chat_id': id,
            'order_id': id,
          },
        );
        return;
      }

      final response = await _api.fetchLeadByIdResponse(link.leadId);
      final access = classifyLeadHttpResponse(
        response.statusCode,
        response.body,
      );
      if (access != LeadLinkAccess.granted) {
        await _restoreSelection(
          switchedOrganization: switchedOrganization,
          switchedFunnel: switchedFunnel,
          previousOrganization: previousOrganization,
          previousFunnel: previousFunnel,
        );
        _hideLoader();
        if (access == LeadLinkAccess.denied) {
          _showNoAccess();
        } else {
          _showFailure();
        }
        return;
      }

      _hideLoader();
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;
      await navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => LeadDetailsScreen(
            leadId: link.leadId.toString(),
            leadName: '',
            leadStatus: '',
            statusId: 0,
          ),
        ),
      );
    } on WorkdayAccessException {
      _hideLoader();
    } catch (error) {
      await _restoreSelection(
        switchedOrganization: switchedOrganization,
        switchedFunnel: switchedFunnel,
        previousOrganization: previousOrganization,
        previousFunnel: previousFunnel,
      );
      _hideLoader();
      if (_shouldStayQuiet(error)) return;
      debugPrint('LeadLink: open failed: $error');
      if (_isDeniedError(error)) {
        _showNoAccess();
      } else {
        _showFailure();
      }
    }
  }

  Future<void> _restoreSelection({
    required bool switchedOrganization,
    required bool switchedFunnel,
    required String? previousOrganization,
    required String? previousFunnel,
  }) async {
    if (switchedOrganization &&
        previousOrganization != null &&
        previousOrganization.isNotEmpty &&
        previousOrganization != 'null') {
      await _api.saveSelectedOrganization(previousOrganization);
    }
    if (switchedFunnel &&
        previousFunnel != null &&
        previousFunnel.isNotEmpty &&
        previousFunnel != 'null') {
      await _api.saveSelectedSalesFunnel(previousFunnel);
    }
  }

  void _showLoader() {
    _hideLoader();
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => const ColoredBox(
        color: Color(0x42000000),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xff1E2E52)),
        ),
      ),
    );
    _loader = entry;
    overlay.insert(entry);
  }

  void _hideLoader() {
    _loader?.remove();
    _loader = null;
  }

  void _showNoAccess() {
    _showMessage(
      titleKey: 'no_access_title',
      titleFallback: 'У вас нет доступа',
      bodyKey: 'lead_link_no_access',
      bodyFallback: 'У вас нет доступа к этому лиду',
    );
  }

  void _showFailure() {
    _showMessage(
      titleKey: 'lead_link_failed_title',
      titleFallback: 'Не удалось открыть лид',
      bodyKey: 'lead_link_failed',
      bodyFallback:
          'Не удалось открыть лид. Проверьте интернет и попробуйте ещё раз.',
    );
  }

  void _showMessage({
    required String titleKey,
    required String titleFallback,
    required String bodyKey,
    required String bodyFallback,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final loc = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: Text(
            loc?.translate(titleKey) ?? titleFallback,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            loc?.translate(bodyKey) ?? bodyFallback,
            style: const TextStyle(fontFamily: 'Gilroy', fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                loc?.translate('understood_button') ?? 'Понятно',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _shouldStayQuiet(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('неавториз') ||
        text.contains('session is invalid') ||
        text.contains('401');
  }

  bool _isDeniedError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('403') ||
        text.contains('404') ||
        text.contains('не существует') ||
        text.contains('не найден') ||
        text.contains('не найдено') ||
        text.contains('нет доступа');
  }
}
