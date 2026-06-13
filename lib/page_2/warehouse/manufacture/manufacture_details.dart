import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/manufacture/manufacture_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/goods_details_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/styled_action_button.dart';
import 'package:crm_task_manager/page_2/warehouse/manufacture/manufacture_delete.dart';
import 'package:crm_task_manager/page_2/warehouse/manufacture/manufacture_edit.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/api_exception_model.dart';
import '../../money/widgets/error_dialog.dart';

class ManufactureDocumentDetailsScreen extends StatefulWidget {
  final int documentId;
  final String docNumber;
  final VoidCallback? onDocumentUpdated;
  // НОВОЕ: Добавляем параметры прав доступа
  final bool hasUpdatePermission;
  final bool hasDeletePermission;

  const ManufactureDocumentDetailsScreen({
    required this.documentId,
    required this.docNumber,
    this.onDocumentUpdated,
    this.hasUpdatePermission = false,
    this.hasDeletePermission = false,
    super.key,
  });

  @override
  _ManufactureDocumentDetailsScreenState createState() =>
      _ManufactureDocumentDetailsScreenState();
}

class _ManufactureDocumentDetailsScreenState
    extends State<ManufactureDocumentDetailsScreen> {
  final ApiService _apiService = ApiService();
  IncomingDocument? currentDocument;
  List<Map<String, dynamic>> details = [];
  bool _isLoading = false;
  bool _isButtonLoading = false;
  String? baseUrl;
  bool _documentUpdated = false;
  bool _goodMeasurementEnabled = true;
  final Map<int, bool> _collapsedMaterialSections = {};

  // ✅ НОВОЕ: Флаг разрешения на проведение документа
  bool _hasApprovePermission = false;
  bool _hasUnapprovePermission = false;

  final Map<int, String> _unitMap = {
    23: 'шт',
  };

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl();
    _fetchDocumentDetails();
    _loadGoodMeasurementSetting();
    _checkApprovePermission();
  }

  // ✅ НОВОЕ: Проверка разрешения на проведение документа
  Future<void> _checkApprovePermission() async {
    try {
      final hasApprovePermission =
          await _apiService.hasPermission('manufacture.approve') ||
              await _apiService.hasPermission('manufacture_document.approve');
      final hasUnapprovePermission =
          await _apiService.hasPermission('manufacture.unapprove');
      if (mounted) {
        setState(() {
          _hasApprovePermission = hasApprovePermission;
          _hasUnapprovePermission = hasUnapprovePermission;
        });
      }
    } catch (e) {
      debugPrint('Ошибка при проверке права на проведение документа: $e');
      if (mounted) {
        setState(() {
          _hasApprovePermission = false;
          _hasUnapprovePermission = false;
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
      final document =
          await _apiService.getManufactureDocumentById(widget.documentId);
      setState(() {
        currentDocument = document;
        _syncCollapsedMaterialSections(document);
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
            context, localizations.translate('error') ?? 'Ошибка', e.message,
            errorDialogEnum: ErrorDialogEnum.goodsMovementDelete);
        return;
      }
      final localizations = AppLocalizations.of(context)!;
      _showSnackBar(
          '${localizations.translate('error_loading_document') ?? 'Ошибка загрузки документа'}: $e',
          false);
    }
  }

  void _updateDetails(IncomingDocument? document) {
    if (document == null) {
      details.clear();
      return;
    }

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
            '${AppLocalizations.of(context)!.translate('manufacture_writeoff_storage') ?? 'Склад списания'}:',
        'value':
            document.sender_storage_id?.name ?? document.storage?.name ?? '',
      },
      {
        'label':
            '${AppLocalizations.of(context)!.translate('manufacture_income_storage') ?? 'Склад прихода'}:',
        'value': document.recipient_storage_id?.name ?? '',
      },
      {
        'label':
            AppLocalizations.of(context)!.translate('comment') ?? 'Комментарий',
        'value': document.comment ?? '',
      },
      {
        'label':
            '${AppLocalizations.of(context)!.translate('total_quantity') ?? 'Общее количество'}:',
        'value': document.totalQuantity.toString(),
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

  void _syncCollapsedMaterialSections(IncomingDocument? document) {
    final goods = document?.documentGoods ?? const <DocumentGood>[];
    final activeKeys = <int>{};

    for (final good in goods) {
      if ((good.materials ?? const <DocumentGoodMaterial>[]).isEmpty) continue;
      final key = _getMaterialSectionKey(good);
      activeKeys.add(key);
      _collapsedMaterialSections.putIfAbsent(key, () => true);
    }

    _collapsedMaterialSections.removeWhere(
      (key, value) => !activeKeys.contains(key),
    );
  }

  int _getMaterialSectionKey(DocumentGood good) {
    return good.id ??
        good.goodVariantId ??
        good.variantId ??
        good.good?.id ??
        good.hashCode;
  }

  void _toggleMaterialSection(DocumentGood good) {
    final key = _getMaterialSectionKey(good);
    setState(() {
      _collapsedMaterialSections[key] =
          !(_collapsedMaterialSections[key] ?? true);
    });
  }

  String _getLocalizedStatus(IncomingDocument document) {
    final localizations = AppLocalizations.of(context)!;

    if (document.deletedAt != null) {
      return localizations.translate('deleted') ?? 'Удален';
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
        backgroundColor: isSuccess ? Colors.green : Colors.red,
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
    setState(() {
      _isButtonLoading = true;
    });
    try {
      await _apiService.approveManufactureDocument(widget.documentId);
      setState(() {
        currentDocument = currentDocument!.copyWith(approved: 1);
        _documentUpdated = true;
      });
      _updateStatusOnly();
      final localizations = AppLocalizations.of(context)!;
      _showSnackBar(
          localizations.translate('document_approved') ?? 'Документ проведен',
          true);
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        final localizations = AppLocalizations.of(context)!;
        showSimpleErrorDialog(
            context, localizations.translate('error') ?? 'Ошибка', e.message,
            errorDialogEnum: ErrorDialogEnum.goodsMovementApprove);
        return;
      }
      final localizations = AppLocalizations.of(context)!;
      _showSnackBar(
          '${localizations.translate('error_approving_document') ?? 'Ошибка при проведении документа'}: $e',
          false);
    } finally {
      setState(() {
        _isButtonLoading = false;
      });
    }
  }

  Future<void> _unApproveDocument() async {
    setState(() {
      _isButtonLoading = true;
    });
    try {
      await _apiService.unApproveManufactureDocument(widget.documentId);
      setState(() {
        currentDocument = currentDocument!.copyWith(approved: 0);
        _documentUpdated = true;
      });
      _updateStatusOnly();
      final localizations = AppLocalizations.of(context)!;
      _showSnackBar(
          localizations.translate('document_unapproved') ??
              'Проведение документа отменено',
          true);
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        final localizations = AppLocalizations.of(context)!;
        showSimpleErrorDialog(
            context, localizations.translate('error') ?? 'Ошибка', e.message,
            errorDialogEnum: ErrorDialogEnum.goodsMovementUnapprove);
        return;
      }
      final localizations = AppLocalizations.of(context)!;
      _showSnackBar(
          '${localizations.translate('error_unapproving_document') ?? 'Ошибка при отмене проведения документа'}: $e',
          false);
    } finally {
      setState(() {
        _isButtonLoading = false;
      });
    }
  }

  Future<void> _restoreDocument() async {
    setState(() {
      _isButtonLoading = true;
    });
    try {
      await _apiService.restoreManufactureDocument(widget.documentId);
      setState(() {
        currentDocument = currentDocument!.copyWith(clearDeletedAt: true);
        _documentUpdated = true;
      });
      _updateStatusOnly();
      final localizations = AppLocalizations.of(context)!;
      _showSnackBar(
          localizations.translate('document_restored') ??
              'Документ восстановлен',
          true);
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        final localizations = AppLocalizations.of(context)!;
        showSimpleErrorDialog(
            context, localizations.translate('error') ?? 'Ошибка', e.message,
            errorDialogEnum: ErrorDialogEnum.goodsMovementRestore);
        return;
      }
      final localizations = AppLocalizations.of(context)!;
      _showSnackBar(
          '${localizations.translate('error_restoring_document') ?? 'Ошибка при восстановлении документа'}: $e',
          false);
    } finally {
      setState(() {
        _isButtonLoading = false;
      });
    }
  }

  Widget _buildActionButton() {
    if (_isButtonLoading) {
      return Container(
        height: 48,
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Color(0xff1E2E52),
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (currentDocument == null) return const SizedBox.shrink();

    // НОВОЕ: Если документ удалён - показываем кнопку восстановления
    if (currentDocument!.deletedAt != null) {
      return StyledActionButton(
        text: AppLocalizations.of(context)!.translate('restore_document') ??
            'Восстановить',
        icon: Icons.restore,
        color: const Color(0xFF2196F3),
        onPressed: _restoreDocument,
      );
    }

    // НОВОЕ: Кнопки провести/отменить проведение требуют права UPDATE
    if (!widget.hasUpdatePermission) {
      return const SizedBox.shrink();
    }

    if (currentDocument!.approved == 0) {
      if (!_hasApprovePermission) {
        return const SizedBox.shrink();
      }

      return StyledActionButton(
        text: AppLocalizations.of(context)!.translate('approve_document') ??
            'Провести',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF4CAF50),
        onPressed: _approveDocument,
      );
    }

    if (!_hasUnapprovePermission) {
      return const SizedBox.shrink();
    }

    return StyledActionButton(
      text: AppLocalizations.of(context)!.translate('unapprove_document') ??
          'Отменить проведение',
      icon: Icons.cancel_outlined,
      color: const Color(0xFFFFA500),
      onPressed: _unApproveDocument,
    );
  }

  void _showFullTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
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
                  style: const TextStyle(
                    color: Color(0xff1E2E52),
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
                    style: const TextStyle(
                      color: Color(0xff1E2E52),
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
                  color: const Color(0xff1E2E52),
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
    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop && _documentUpdated && widget.onDocumentUpdated != null) {
          widget.onDocumentUpdated!();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(context),
        backgroundColor: Colors.white,
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff99A4BA),
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
                      ],
                    ),
                  ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    // ИЗМЕНЕНО: Показываем кнопки только если есть права И документ не удалён
    final showActions = currentDocument?.deletedAt == null &&
        (widget.hasUpdatePermission || widget.hasDeletePermission);

    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
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
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      title: Transform.translate(
        offset: const Offset(-10, 0),
        child: Text(
          "${AppLocalizations.of(context)!.translate('manufacture') ?? 'Производство'} №${widget.docNumber}",
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      actions: showActions
          ? [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // НОВОЕ: Кнопка редактирования только если есть право
                  if (widget.hasUpdatePermission)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Image.asset(
                        'assets/icons/edit.png',
                        width: 24,
                        height: 24,
                      ),
                      onPressed: () async {
                        if (_isLoading) return;
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditManufactureDocumentScreen(
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
                  // НОВОЕ: Кнопка удаления только если есть право
                  if (widget.hasDeletePermission)
                    IconButton(
                      padding: const EdgeInsets.only(right: 8),
                      constraints: const BoxConstraints(),
                      icon: Image.asset(
                        'assets/icons/delete.png',
                        width: 24,
                        height: 24,
                      ),
                      onPressed: () {
                        if (_isLoading) return;
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return BlocProvider.value(
                              value: BlocProvider.of<ManufactureBloc>(context),
                              child: ManufactureDeleteDocumentDialog(
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
                  color: const Color(0xff1E2E52),
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

  Widget _buildGoodsList(List<DocumentGood> goods) {
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

  Widget _buildGoodsItem(DocumentGood good) {
    final selectedUnit =
        good.good?.unit ?? Unit(id: null, name: '', shortName: '');
    final unitShortName = selectedUnit.shortName ?? selectedUnit.name ?? '';
    final materials = good.materials ?? const <DocumentGoodMaterial>[];
    final isMaterialsCollapsed =
        _collapsedMaterialSections[_getMaterialSectionKey(good)] ?? true;
    final costPrice = _formatNumberString(good.costPrice);
    final quantity = _formatNumber(good.quantity);
    final price = _formatNumberString(good.price);
    final sum = _formatGoodsSum(good);

    return GestureDetector(
      onTap: () {
        _navigateToGoodsDetails(good);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: TaskCardStyles.taskCardDecoration(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageWidget(good),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text(
                          //   good.fullName ?? good.good?.name ?? 'N/A',
                          //   style: TaskCardStyles.titleStyle
                          //       .copyWith(fontSize: 14),
                          //   maxLines: 2,
                          //   overflow: TextOverflow.ellipsis,
                          // ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 2,
                            ),
                            child: Wrap(
                              spacing: 24,
                              runSpacing: 6,
                              children: [
                                _buildInfoText(
                                  AppLocalizations.of(context)!
                                          .translate('cost_price_per_unit') ??
                                      'Себестоимость',
                                  costPrice,
                                ),
                                _buildInfoText(
                                  AppLocalizations.of(context)!
                                          .translate('quantity') ??
                                      'Кол-во',
                                  quantity,
                                ),
                                _buildInfoText(
                                  (AppLocalizations.of(context)!
                                              .translate('price') ??
                                          'Цена')
                                      .replaceAll(':', ''),
                                  price,
                                ),
                                _buildInfoText(
                                  AppLocalizations.of(context)!
                                          .translate('sum') ??
                                      'Сумма',
                                  sum,
                                ),
                                if (_goodMeasurementEnabled &&
                                    unitShortName.isNotEmpty)
                                  _buildInfoText(
                                    AppLocalizations.of(context)!
                                            .translate('unit') ??
                                        'Ед.',
                                    unitShortName,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (materials.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildMaterialsSection(
                    good: good,
                    materials: materials,
                    isCollapsed: isMaterialsCollapsed,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialsSection({
    required DocumentGood good,
    required List<DocumentGoodMaterial> materials,
    required bool isCollapsed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD9E4F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _toggleMaterialSection(good),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!
                              .translate('raw_materials') ??
                          'Сырье',
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate(
                                isCollapsed ? 'expand' : 'collapse',
                              ) ??
                              (isCollapsed ? 'Развернуть' : 'Свернуть'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isCollapsed
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_up_rounded,
                          size: 18,
                          color: const Color(0xff1E2E52),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: isCollapsed
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                children: List.generate(
                  materials.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
                    child: _buildMaterialItem(materials[index]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialItem(DocumentGoodMaterial material) {
    final materialName = material.goodVariant?.fullName ??
        material.goodVariant?.good?.name ??
        'N/A';
    final unitName = material.unit?.shortName ?? material.unit?.name ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7EEF9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            materialName,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildMaterialMeta(
                AppLocalizations.of(context)!.translate('norm') ?? 'Норма',
                '${material.norm ?? 0}',
              ),
              _buildMaterialMeta(
                AppLocalizations.of(context)!.translate('quantity') ?? 'Кол-во',
                '${material.quantity ?? 0}',
              ),
              if (_goodMeasurementEnabled && unitName.isNotEmpty)
                _buildMaterialMeta(
                  'Ед. изм.',
                  unitName,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialMeta(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 12,
          fontFamily: 'Gilroy',
          color: Color(0xff1E2E52),
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w400,
              color: Color(0xff99A4BA),
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText(String label, String value) {
    return SizedBox(
      width: 145,
      child: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                color: Color(0xff99A4BA),
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _formatGoodsSum(DocumentGood good) {
    if ((good.sum ?? '').isNotEmpty) {
      return _formatNumberString(good.sum);
    }

    final quantity = good.quantity?.toDouble() ?? 0;
    final price = double.tryParse(good.price ?? '0') ?? 0;
    return _formatNumber(quantity * price);
  }

  String _formatNumberString(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    final normalized = value.replaceAll(',', '.').trim();
    final parsed = double.tryParse(normalized);
    if (parsed == null) return value;
    return _formatNumber(parsed);
  }

  String _formatNumber(num? value) {
    if (value == null) return '-';
    if (value == value.toInt()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  Widget _buildImageWidget(DocumentGood good) {
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
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child:
            Icon(Icons.image_not_supported, size: 40, color: Color(0xff99A4BA)),
      ),
    );
  }

  void _navigateToGoodsDetails(DocumentGood good) {
    final goodId = good.good?.id;
    if (goodId == null || goodId == 0) {
      final localizations = AppLocalizations.of(context)!;
      _showSnackBar(
          localizations.translate('error_no_good_id') ??
              'Ошибка: Не удалось определить ID товара',
          false);
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
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: Color(0xff99A4BA),
      ),
    );
  }

  Widget _buildValue(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color(0xff1E2E52),
      ),
      overflow: TextOverflow.visible,
    );
  }
}
