import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/absence/absence_models.dart';
import 'package:crm_task_manager/screens/absence/absence_form_sheet.dart';
import 'package:crm_task_manager/screens/absence/absence_logic.dart';
import 'package:crm_task_manager/screens/absence/absence_reject_dialog.dart';
import 'package:crm_task_manager/screens/absence/absence_widgets.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Деталь заявки. Из пуша открывается отдельным экраном, из списка — листом.
class AbsenceDetailScreen extends StatefulWidget {
  const AbsenceDetailScreen({super.key, required this.requestId});

  final int requestId;

  @override
  State<AbsenceDetailScreen> createState() => _AbsenceDetailScreenState();
}

class _AbsenceDetailScreenState extends State<AbsenceDetailScreen> {
  final ApiService _api = ApiService();
  AbsenceAccess _access = AbsenceAccess.none;
  AbsenceRequest? _request;
  bool _loading = true;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _offline = false;
    });
    try {
      final access = await _api.loadAbsenceAccess();
      final request = await _api.getAbsenceRequest(widget.requestId);
      if (!mounted) return;
      setState(() {
        _access = access;
        _request = request;
        _loading = false;
      });
    } on AbsenceApiException catch (error) {
      if (!mounted) return;
      if (error.isUnavailable) {
        final navigator = Navigator.of(context);
        final parent = navigator.context;
        final text = absenceTr(context, 'absence_unavailable');
        navigator.pop();
        if (parent.mounted) {
          showCustomSnackBar(
            context: parent,
            message: text,
            isSuccess: false,
          );
        }
        return;
      }
      setState(() {
        _loading = false;
        _offline = error.network;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  Future<void> _edit() async {
    final request = _request;
    if (request == null) return;
    final saved = await showAbsenceSheet<bool>(
      context: context,
      builder: (_) => AbsenceFormSheet(
        initial: request,
        onSubmit: (body) async {
          await _api.updateAbsenceRequest(request.id, body);
        },
      ),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _cancel() async {
    final request = _request;
    if (request == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appColors.surfacePrimary,
        title: Text(
          absenceTr(context, 'absence_cancel_confirm'),
          style: absenceStyle(context, size: 18, weight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(absenceTr(context, 'cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(absenceTr(context, 'absence_cancel_request')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _api.cancelAbsenceRequest(request.id);
      if (mounted) await _load();
    } on AbsenceApiException catch (error) {
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: error.message,
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    final canEdit = request != null &&
        canEditAbsence(access: _access, request: request);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _viewAppBar(
        context,
        absenceTr(context, 'absence_menu'),
        canEdit: canEdit && !_loading,
        onEdit: _edit,
        onCancel: _cancel,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackgroundOverlay(preset: AppBackgroundPreset.aurora),
          _loading
              ? const Center(
                  child: PlayStoreImageLoading(
                    size: 80,
                    duration: Duration(milliseconds: 1000),
                  ),
                )
              : request == null
                  ? _Offline(
                      onRetry: _offline ? _load : () => Navigator.maybePop(context),
                      textKey: _offline ? 'absence_offline' : 'absence_unavailable',
                      actionKey: _offline ? 'absence_retry' : 'close',
                    )
                  : AbsenceDetailBody(
                      request: request,
                      access: _access,
                      onChanged: (next) => setState(() => _request = next),
                    ),
        ],
      ),
    );
  }
}

AppBar _viewAppBar(
  BuildContext context,
  String title, {
  required bool canEdit,
  required VoidCallback onEdit,
  required VoidCallback onCancel,
}) {
  final colors = context.appColors;
  final gradient = [colors.surfaceElevated, colors.fieldBg];
  return AppBar(
    automaticallyImplyLeading: false,
    backgroundColor: colors.overlay.withValues(alpha: 0),
    forceMaterialTransparency: true,
    elevation: 0,
    scrolledUnderElevation: 0,
    toolbarHeight: 74,
    titleSpacing: 16,
    title: AppBarShell(
      leading: AppBarShell.capsule(
        context,
        width: AppBarShell.orbSize,
        padding: EdgeInsets.zero,
        gradientColors: gradient,
        borderColor: colors.borderSubtle,
        child: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(Icons.arrow_back_rounded, size: 20, color: colors.textPrimary),
        ),
      ),
      center: AppBarShell.capsule(
        context,
        gradientColors: gradient,
        borderColor: colors.borderSubtle,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      trailing: canEdit
          ? AppBarShell.capsule(
              context,
              width: AppBarShell.orbSize,
              padding: EdgeInsets.zero,
              gradientColors: gradient,
              borderColor: colors.borderSubtle,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                tooltip: '',
                color: colors.fieldBg,
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'cancel') onCancel();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    height: 46,
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 19, color: colors.textSecondary),
                        const SizedBox(width: 12),
                        Text(
                          absenceTr(context, 'absence_edit_action'),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'cancel',
                    height: 46,
                    child: Row(
                      children: [
                        Icon(Icons.close_rounded, size: 19, color: colors.textSecondary),
                        const SizedBox(width: 12),
                        Text(
                          absenceTr(context, 'absence_cancel_request'),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : null,
    ),
  );
}

class AbsenceDetailBody extends StatefulWidget {
  const AbsenceDetailBody({
    super.key,
    required this.request,
    required this.access,
    required this.onChanged,
  });

  final AbsenceRequest request;
  final AbsenceAccess access;
  final ValueChanged<AbsenceRequest> onChanged;

  @override
  State<AbsenceDetailBody> createState() => _AbsenceDetailBodyState();
}

class _AbsenceDetailBodyState extends State<AbsenceDetailBody> {
  final ApiService _api = ApiService();
  bool _busy = false;

  Future<void> _refresh(AbsenceRequest? updated) async {
    final fresh = updated ?? await _api.getAbsenceRequest(widget.request.id);
    if (!mounted) return;
    widget.onChanged(fresh);
    setState(() => _busy = false);
  }

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      final updated = await _api.approveAbsenceRequest(widget.request.id);
      await _refresh(updated);
    } on AbsenceApiException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showCustomSnackBar(
        context: context,
        message: error.message,
        isSuccess: false,
      );
      if (error.statusCode == 403) {
        try {
          await _refresh(null);
        } catch (_) {}
      }
    }
  }

  Future<void> _confirmReject() async {
    final reason = await showAbsenceRejectDialog(context);
    if (reason == null || reason.trim().isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      final updated = await _api.rejectAbsenceRequest(widget.request.id, reason.trim());
      await _refresh(updated);
    } on AbsenceApiException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showCustomSnackBar(
        context: context,
        message: error.fieldErrors['rejection_reason'] ?? error.message,
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final days = absenceDayCount(request.dateFrom, request.dateTo);
    final period = formatAbsencePeriod(request.dateFrom, request.dateTo);
    final periodText = days > 1
        ? '$period ($days ${absenceTr(context, 'absence_days')})'
        : period;
    final clock = formatAbsenceClock(request.timeFrom, request.timeTo);
    final canDecide = canDecideAbsence(
      access: widget.access,
      request: request,
    );
    final decision = _decision(context, request);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            decoration: BoxDecoration(
              color: context.appColors.surfacePrimary,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: context.appColors.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: context.appColors.shadow.withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (request.userName.isNotEmpty)
                  _leadRow(context, absenceTr(context, 'employee'), request.userName),
                _leadRow(
                  context,
                  absenceTr(context, 'absence_period'),
                  periodText,
                  maxLines: 2,
                ),
                _leadRow(
                  context,
                  absenceTr(context, 'absence_time'),
                  clock.isEmpty ? absenceTr(context, 'absence_all_day') : clock,
                ),
                _leadRow(context, absenceTr(context, 'absence_reason'), request.reason),
                _leadRow(context, absenceTr(context, 'status'), absenceStatusText(context, request)),
                if (request.status == 'rejected' &&
                    (request.rejectionReason?.trim().isNotEmpty ?? false))
                  _leadRow(
                    context,
                    absenceTr(context, 'absence_reject_reason'),
                    request.rejectionReason!.trim(),
                  ),
                if (decision != null)
                  _leadRow(
                    context,
                    absenceTr(context, 'absence_decision'),
                    decision,
                    maxLines: 2,
                  ),
                if (request.limitWarning != null) ...[
                  const SizedBox(height: 8),
                  AbsenceWarningBanner(message: request.limitWarning!.message),
                ],
                if (canDecide)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Flexible(
                          child: SizedBox(
                            height: 42,
                            child: ElevatedButton(
                              onPressed: _busy ? null : _approve,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: context.appColors.buttonPrimaryBg,
                                foregroundColor: context.appColors.textInverse,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                absenceTr(context, 'absence_approve'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                  color: context.appColors.textInverse,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: ElevatedButton(
                              onPressed: _busy ? null : _confirmReject,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: context.appColors.buttonDangerBg,
                                foregroundColor: context.appColors.buttonDangerFg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                absenceTr(context, 'absence_reject'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                  color: context.appColors.buttonDangerFg,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Подпись с двоеточием. Значение в 1 строку, период и решение — в 2.
  /// Если текст не влезает, в конце три точки, нажатие открывает всё целиком.
  Widget _leadRow(
    BuildContext context,
    String label,
    String value, {
    int maxLines = 1,
  }) {
    final titled = label.endsWith(':') ? label : '$label:';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titled,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
              color: context.appColors.fieldHint,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final plain = _valueStyle(context);
                final overflows = _valueOverflows(
                  value,
                  plain,
                  constraints.maxWidth,
                  maxLines,
                );
                if (!overflows) {
                  return _plainValue(context, value, plain, maxLines);
                }
                return _expandableValue(context, titled, value, maxLines);
              },
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _valueStyle(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      fontFamily: 'Gilroy',
      fontWeight: FontWeight.w600,
      color: context.appColors.textPrimary,
    );
  }

  bool _valueOverflows(
    String value,
    TextStyle style,
    double maxWidth,
    int maxLines,
  ) {
    if (value.isEmpty || maxWidth <= 0) return false;
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }

  Widget _plainValue(
    BuildContext context,
    String value,
    TextStyle style,
    int maxLines,
  ) {
    return GestureDetector(
      onLongPress: () => _copyValue(context, value),
      child: Text(
        value,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Длинное значение обрезается тремя точками. Нажатие открывает полный текст.
  Widget _expandableValue(
    BuildContext context,
    String label,
    String value,
    int maxLines,
  ) {
    return GestureDetector(
      onTap: () => _showFullTextDialog(
        context,
        label.replaceAll(':', ''),
        value,
      ),
      onLongPress: () => _copyValue(context, value),
      child: Text(
        value,
        style: _valueStyle(context).copyWith(
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _copyValue(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          absenceTr(context, 'copied_to_clipboard'),
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: context.appColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFullTextDialog(BuildContext context, String title, String content) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: context.appColors.surfacePrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: context.appColors.borderSubtle),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.appColors.textPrimary,
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      color: context.appColors.textPrimary,
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  buttonText: absenceTr(context, 'close'),
                  onPressed: () => Navigator.pop(dialogContext),
                  buttonColor: context.appColors.buttonPrimaryBg,
                  textColor: context.appColors.buttonPrimaryFg,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String? _decision(BuildContext context, AbsenceRequest request) {
    if (request.isPending) return null;
    final name = request.authorName?.trim() ?? '';
    final when = request.reviewedAt == null
        ? ''
        : formatAbsenceDisplayDateTime(request.reviewedAt!);
    if (name.isEmpty && when.isEmpty) return null;
    if (name.isEmpty) return when;
    if (when.isEmpty) return name;
    return '$name, $when';
  }
}

class _Offline extends StatelessWidget {
  const _Offline({
    required this.onRetry,
    this.textKey = 'absence_offline',
    this.actionKey = 'absence_retry',
  });

  final VoidCallback onRetry;
  final String textKey;
  final String actionKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              absenceTr(context, textKey),
              textAlign: TextAlign.center,
              style: absenceStyle(context),
            ),
            const SizedBox(height: 12),
            absencePrimaryButton(
              context: context,
              label: absenceTr(context, actionKey),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
