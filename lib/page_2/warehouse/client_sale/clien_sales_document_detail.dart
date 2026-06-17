import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/client_sale/bloc/client_sale_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/page_2/expense_details_document_model.dart'
    as expDoc;
import 'package:crm_task_manager/page_2/goods/goods_details/goods_details_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/client_sale/edit_client_sales_document_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/client_sale/widgets/client_sale_delete_document.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/styled_action_button.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/api_exception_model.dart';
import '../../../utils/global_fun.dart';
import '../../money/widgets/error_dialog.dart';

class ClientSalesDocumentDetailsScreen extends StatefulWidget {
  final int documentId;
  final String docNumber;
  final VoidCallback? onDocumentUpdated;
  final bool isRmk;
  // НОВОЕ: Параметры прав доступа
  final bool hasUpdatePermission;
  final bool hasDeletePermission;

  const ClientSalesDocumentDetailsScreen({
    required this.documentId,
    required this.docNumber,
    this.onDocumentUpdated,
    this.isRmk = false,
    this.hasUpdatePermission = false,
    this.hasDeletePermission = false,
    super.key,
  });

  @override
  _ClientSalesDocumentDetailsScreenState createState() =>
      _ClientSalesDocumentDetailsScreenState();
}

class _ClientSalesDocumentDetailsScreenState
    extends State<ClientSalesDocumentDetailsScreen> {
  final ApiService _apiService = ApiService();
  expDoc.ExpenseDocumentDetail? currentDocument;
  List<Map<String, dynamic>> details = [];
  bool _isLoading = false;
  bool _isButtonLoading = false;
  String? baseUrl;
  bool _documentUpdated = false;
  bool _goodMeasurementEnabled = true;

  // ✅ НОВОЕ: Флаг разрешения на проведение документа
  bool _hasApprovePermission = false;

  @override
  void initState() {
    debugPrint("documentId; ${widget.documentId}");

    super.initState();
    _initializeBaseUrl();
    _fetchDocumentDetails();
    _loadGoodMeasurementSetting();
    _checkApprovePermission();
  }

  // ✅ НОВОЕ: Проверка разрешения на проведение документа
  Future<void> _checkApprovePermission() async {
    try {
      final hasPermission =
          await _apiService.hasPermission('expense_document.approve');
      if (mounted) {
        setState(() {
          _hasApprovePermission = hasPermission;
        });
      }
    } catch (e) {
      debugPrint('Ошибка при проверке права на проведение документа: $e');
      if (mounted) {
        setState(() {
          _hasApprovePermission = false;
        });
      }
    }
  }

  Future<void> _loadGoodMeasurementSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _goodMeasurementEnabled = prefs.getBool('good_measurement') ?? true;
    });
  }

  Future<void> _initializeBaseUrl() async {
    try {
      final staticBaseUrl = await _apiService.getStaticBaseUrl();
      setState(() {
        baseUrl = staticBaseUrl;
      });
    } catch (error) {
      setState(() {
        baseUrl = 'https://shamcrm.com/storage';
      });
    }
  }

  Future<void> _fetchDocumentDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final document = widget.isRmk
          ? await _apiService.getRmkSaleById(widget.documentId)
          : await _apiService.getClienSalesById(widget.documentId);
      setState(() {
        currentDocument = document;
        _updateDetails(document);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (e is ApiException && e.statusCode == 409) {
        final localizations = AppLocalizations.of(context)!;
        showSimpleErrorDialog(
            context, localizations.translate('error') ?? 'Ошибка', e.message);
        return;
      }
      _showSnackBar('Ошибка загрузки документа: $e', false);
    }
  }

  void _updateDetails(expDoc.ExpenseDocumentDetail? document) {
    if (document == null) {
      details.clear();
      return;
    }

    final clientCurrencyName =
        document.model?.currency?.name ?? document.currency?.name;

    details = [
      {
        'label':
            '${AppLocalizations.of(context)!.translate('document_number') ?? 'Документ'}:',
        'value': "№${document.docNumber ?? ''}",
      },
      {
        'label': '${AppLocalizations.of(context)!.translate('date') ?? 'Дата'}',
        'value': document.date != null
            ? DateFormat('dd.MM.yyyy HH:mm').format(document.date!)
            : '',
      },
      {
        'label':
            '${AppLocalizations.of(context)!.translate('storage') ?? 'Склад'}:',
        'value': document.storage?.name ?? '',
      },
      {
        'label':
            '${AppLocalizations.of(context)!.translate('client') ?? 'Клиент'}',
        'value': document.model?.name ?? '',
      },
      if ((clientCurrencyName ?? '').isNotEmpty)
        {
          'label': 'Валюта клиента:',
          'value': clientCurrencyName!,
        },
      {
        'label':
            '${AppLocalizations.of(context)!.translate('client_phone') ?? 'Телефон клиента'}',
        'value': document.model?.phone ?? '',
      },
      {
        'label':
            '${AppLocalizations.of(context)!.translate('client_inn') ?? 'ИНН клиента'}:',
        'value': document.model?.inn?.toString() ?? '',
      },
      {
        'label':
            AppLocalizations.of(context)!.translate('comment') ?? 'Комментарий',
        'value': document.comment ?? '',
      },
      if (document.exchangeRate?.value != null &&
          document.exchangeRate!.value!.isNotEmpty)
        {
          'label':
              '${AppLocalizations.of(context)!.translate('exchange_rate') ?? 'Курс валюты'}:',
          'value': document.exchangeRate!.value!,
        },
      if (document.exchangeRate?.value != null &&
          document.exchangeRate!.value!.isNotEmpty)
        {
          'label':
              '${AppLocalizations.of(context)!.translate('total_by_currency') ?? 'Итого по валюте'}${(document.currency?.name ?? '').isNotEmpty ? ': ${document.currency!.name}' : ''}:',
          'value': parseNumberToString(
            (document.totalSum *
                    (double.tryParse(document.exchangeRate!.value!
                            .replaceAll(',', '.')) ??
                        0))
                .toStringAsFixed(2),
          ),
        },
      {
        'label':
            '${AppLocalizations.of(context)!.translate('total_quantity') ?? 'Общее количество'}:',
        'value': document.totalQuantity.toString(),
      },
      {
        'label':
            '${AppLocalizations.of(context)!.translate('total_sum') ?? 'Общая сумма'}:',
        'value':
            '${parseNumberToString(document.totalSum.toStringAsFixed(2))} ${document.currency?.symbolCode ?? ''}',
      },
      {
        'label':
            '${AppLocalizations.of(context)!.translate('status') ?? 'Статус'}:',
        'value': _getLocalizedStatus(document),
      },
      if (document.deletedAt != null)
        {
          'label':
              '${AppLocalizations.of(context)!.translate('deleted_at') ?? 'Дата удаления'}:',
          'value': DateFormat('dd.MM.yyyy HH:mm').format(document.deletedAt!),
        },
    ];
  }

  String _getLocalizedStatus(expDoc.ExpenseDocumentDetail document) {
    final localizations = AppLocalizations.of(context)!;

    if (document.deletedAt != null) {
      return localizations.translate('deleted') ??
          'Удален'; // ИЗМЕНЕНО: Унифицировано
    }

    if (document.approved == 1) {
      return localizations.translate('approved') ?? 'Проведен';
    } else {
      return localizations.translate('not_approved') ?? 'Не проведен';
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor:
            isSuccess ? const Color(0xff16A34A) : const Color(0xffDC2626),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _updateStatusOnly() {
    if (currentDocument != null) {
      setState(() {
        _updateDetails(currentDocument);
      });
    }
  }

  Future<void> _approveDocument() async {
    // НОВОЕ: Проверяем update-право
    if (!widget.hasUpdatePermission) {
      _showSnackBar('Нет прав на проведение документа', false);
      return;
    }

    setState(() {
      _isButtonLoading = true;
    });
    try {
      await _apiService.approveClientSaleDocument(widget.documentId);
      setState(() {
        currentDocument = currentDocument!.copyWith(approved: 1);
        _documentUpdated = true;
      });
      _updateStatusOnly();
      _showSnackBar('Документ проведен', true);
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        final localizations = AppLocalizations.of(context)!;
        showSimpleErrorDialog(
            context, localizations.translate('error') ?? 'Ошибка', e.message);
        return;
      }
      _showSnackBar('Ошибка при проведении документа: $e', false);
    } finally {
      setState(() {
        _isButtonLoading = false;
      });
    }
  }

  Future<void> _unApproveDocument() async {
    // НОВОЕ: Проверяем update-право
    if (!widget.hasUpdatePermission) {
      _showSnackBar('Нет прав на отмену проведения', false);
      return;
    }

    setState(() {
      _isButtonLoading = true;
    });
    try {
      await _apiService.unApproveClientSaleDocument(widget.documentId);
      setState(() {
        currentDocument = currentDocument!.copyWith(approved: 0);
        _documentUpdated = true;
      });
      _updateStatusOnly();
      _showSnackBar('Проведение документа отменено', true);
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        final localizations = AppLocalizations.of(context)!;
        showSimpleErrorDialog(
            context, localizations.translate('error') ?? 'Ошибка', e.message);
        return;
      }
      _showSnackBar('Ошибка при отмене проведения документа: $e', false);
    } finally {
      setState(() {
        _isButtonLoading = false;
      });
    }
  }

  Future<void> _restoreDocument() async {
    // НОВОЕ: Привязываем к update-праву
    if (!widget.hasUpdatePermission) {
      _showSnackBar('Нет прав на восстановление', false);
      return;
    }

    setState(() {
      _isButtonLoading = true;
    });
    try {
      await _apiService.restoreClientSaleDocument(widget.documentId);
      setState(() {
        currentDocument = currentDocument!.copyWith(deletedAt: null);
        _documentUpdated = true;
      });
      _updateStatusOnly();
      _showSnackBar('Документ восстановлен', true);
      // ИЗМЕНЕНО: Reload через BLoC
      context
          .read<ClientSaleBloc>()
          .add(const FetchClientSales(forceRefresh: true));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        final localizations = AppLocalizations.of(context)!;
        showSimpleErrorDialog(
            context, localizations.translate('error') ?? 'Ошибка', e.message);
        return;
      }
      _showSnackBar('Ошибка при восстановлении документа: $e', false);
    } finally {
      setState(() {
        _isButtonLoading = false;
      });
    }
  }

  Widget _buildActionButton() {
    final colors = context.appColors;
    if (_isButtonLoading) {
      return Container(
        height: 48,
        width: 200,
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: colors.buttonPrimaryBg,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (currentDocument == null) return const SizedBox.shrink();

    // НОВОЕ: Restore только с update-правом
    if (currentDocument!.deletedAt != null) {
      if (!widget.hasUpdatePermission) return const SizedBox.shrink();
      return StyledActionButton(
        text: AppLocalizations.of(context)!.translate('restore_document') ??
            'Восстановить',
        icon: Icons.restore,
        color: colors.buttonPrimaryBg,
        onPressed: _restoreDocument,
      );
    }

    // НОВОЕ: approve/unapprove только с update-правом
    if (!widget.hasUpdatePermission) {
      return const SizedBox.shrink();
    }

    // ✅ НОВОЕ: Дополнительная проверка разрешения на проведение
    if (!_hasApprovePermission) {
      return const SizedBox.shrink();
    }

    if (currentDocument!.approved == 0) {
      return StyledActionButton(
        text: AppLocalizations.of(context)!.translate('approve_document') ??
            'Провести',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF16A34A),
        onPressed: _approveDocument,
      );
    }

    return StyledActionButton(
      text: AppLocalizations.of(context)!.translate('unapprove_document') ??
          'Отменить проведение',
      icon: Icons.cancel_outlined,
      color: const Color(0xFFDC2626),
      onPressed: _unApproveDocument,
    );
  }

  void _showFullTextDialog(String title, String content) {
    final colors = context.appColors;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: colors.surfacePrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
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
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: StyledActionButton(
                  text: AppLocalizations.of(context)!.translate('close') ??
                      'Закрыть',
                  icon: Icons.close,
                  color: colors.buttonPrimaryBg,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop && _documentUpdated && widget.onDocumentUpdated != null) {
          widget.onDocumentUpdated!();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        backgroundColor: colors.surfacePrimary,
        body: _isLoading
            ? Center(
                child: PlayStoreImageLoading(
                  size: 80.0,
                  duration: const Duration(milliseconds: 1000),
                ),
              )
            : currentDocument == null
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)!
                              .translate('document_data_unavailable') ??
                          'Данные документа недоступны',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Center(child: _buildActionButton()),
                        ),
                        _buildDetailsList(),
                        const SizedBox(height: 16),
                        if (currentDocument!.documentGoods != null &&
                            currentDocument!.documentGoods!.isNotEmpty) ...[
                          _buildGoodsList(currentDocument!.documentGoods!),
                          const SizedBox(height: 16),
                        ],
                        // ClientSaleDocumentHistoryWidget(documentId: widget.documentId), // Закомментировано, как в оригинале
                      ],
                    ),
                  ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final colors = context.appColors;
    // ИЗМЕНЕНО: showActions с правами
    final showActions = currentDocument?.deletedAt == null &&
        (widget.hasUpdatePermission || widget.hasDeletePermission);
    final titlePrefix = widget.isRmk
        ? 'Продажа РМК'
        : AppLocalizations.of(context)!.translate('client_sale');

    return AppBar(
      backgroundColor: colors.surfacePrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: Transform.translate(
          offset: const Offset(0, -2),
          child: IconButton(
            icon: Image.asset(
              'assets/icons/arrow-left.png',
              width: 24,
              height: 24,
              color: colors.iconPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      title: Transform.translate(
        offset: const Offset(-10, 0),
        child: Text(
          "$titlePrefix №${widget.docNumber}",
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
      actions: showActions
          ? [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // НОВОЕ: Edit только с update-правом
                  if (widget.hasUpdatePermission)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Image.asset(
                        'assets/icons/edit.png',
                        width: 24,
                        height: 24,
                        color: colors.iconPrimary,
                      ),
                      onPressed: () async {
                        if (_isLoading) return;
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditClientSalesDocumentScreen(
                              document: currentDocument!,
                            ),
                          ),
                        );
                        if (result == true) {
                          _fetchDocumentDetails();
                          if (widget.onDocumentUpdated != null) {
                            widget.onDocumentUpdated!();
                          }
                        }
                      },
                    ),
                  // НОВОЕ: Delete только с delete-правом
                  if (widget.hasDeletePermission)
                    IconButton(
                      padding: const EdgeInsets.only(right: 8),
                      constraints: const BoxConstraints(),
                      icon: Image.asset(
                        'assets/icons/delete.png',
                        width: 24,
                        height: 24,
                        color: const Color(0xffDC2626),
                      ),
                      onPressed: () {
                        if (_isLoading) return;
                        showDialog(
                          context: context,
                          builder: (BuildContext ctx) {
                            return BlocProvider.value(
                              value: BlocProvider.of<ClientSaleBloc>(context),
                              child: ClientSaleDeleteDocumentDialog(
                                  documentId: widget.documentId),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ]
          : [],
    );
  }

  Widget _buildDetailsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: details.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _buildDetailItem(
            details[index]['label']!,
            details[index]['value']!,
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    final colors = context.appColors;
    // Обработка клиента с навигацией на экран лида
    if (label == AppLocalizations.of(context)!.translate('client') &&
        value.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          if (currentDocument?.model?.id != null) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => LeadDetailsScreen(
                  leadId: currentDocument!.model!.id.toString(),
                  leadName: value,
                  leadStatus: "",
                  statusId: 0,
                ),
              ),
            );
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (label == AppLocalizations.of(context)!.translate('comment')) {
      return GestureDetector(
        onTap: () {
          if (value.isNotEmpty) {
            _showFullTextDialog(
              label.replaceAll(':', ''),
              value,
            );
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                  decoration:
                      value.isNotEmpty ? TextDecoration.underline : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(width: 8),
        Expanded(child: _buildValue(value)),
      ],
    );
  }

  Widget _buildGoodsList(List<expDoc.DocumentGood> goods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleRow(
            AppLocalizations.of(context)!.translate('goods') ?? 'Товары'),
        const SizedBox(height: 8),
        if (goods.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: TaskCardStyles.taskCardDecoration(context),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.translate('empty') ??
                        'Нет товаров',
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: goods.length,
            itemBuilder: (context, index) {
              return _buildGoodsItem(goods[index]);
            },
          ),
      ],
    );
  }

  Widget _buildGoodsItem(expDoc.DocumentGood good) {
    final colors = context.appColors;
    final selectedUnit = good.selectedUnit;
    final amount = selectedUnit.amount ?? 1;
    final unitShortName = selectedUnit.shortName ?? selectedUnit.name ?? '';

    debugPrint("selectedUnit: $selectedUnit");

    return GestureDetector(
      onTap: () {
        _navigateToGoodsDetails(good);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: TaskCardStyles.taskCardDecoration(context),
          child: Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageWidget(good),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        good.fullName ?? good.good?.name ?? 'N/A',
                        style: TaskCardStyles.titleStyle(context)
                            .copyWith(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_goodMeasurementEnabled)
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!
                                            .translate('unit') ??
                                        'Ед.',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'Gilroy',
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xff6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    unitShortName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Gilroy',
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xff1F2937),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!
                                          .translate('quantity') ??
                                      'Кол-во',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff6B7280),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${good.quantity ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff1F2937),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!
                                          .translate('price') ??
                                      'Цена',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff6B7280),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  parseNumberToString(((amount ?? 1) *
                                          (double.tryParse(
                                                  good.price ?? '0.00') ??
                                              0.00))
                                      .toStringAsFixed(2)),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff1F2937),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                      .translate('total') ??
                                  'Итого',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500,
                                color: Color(0xff1F2937),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${parseNumberToString(((good.quantity ?? 0) * (amount ?? 1) * (double.tryParse(good.price ?? '0') ?? 0)).toStringAsFixed(2))} ${currentDocument!.currency?.symbolCode ?? ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w700,
                                color: Color(0xff16A34A),
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
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(expDoc.DocumentGood good) {
    if (baseUrl == null ||
        good.good == null ||
        good.good!.files == null ||
        good.good!.files!.isEmpty) {
      return _buildPlaceholderImage();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        '$baseUrl/${good.good!.files![0].path}',
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholderImage();
        },
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    final colors = context.appColors;
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 40,
          color: colors.iconSecondary,
        ),
      ),
    );
  }

  void _navigateToGoodsDetails(expDoc.DocumentGood good) {
    final goodId = good.good?.id;
    if (goodId == null || goodId == 0) {
      _showSnackBar('Ошибка: Не удалось определить ID товара', false);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoodsDetailsScreen(
          id: goodId,
          isFromOrder: false,
          showEditButton: false,
        ),
      ),
    );
  }

  Row _buildTitleRow(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          title,
          style: TaskCardStyles.titleStyle(context).copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    final colors = context.appColors;
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: colors.textSecondary,
      ),
    );
  }

  Widget _buildValue(String value) {
    final colors = context.appColors;
    return Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: colors.textPrimary,
      ),
      overflow: TextOverflow.visible,
    );
  }
}
