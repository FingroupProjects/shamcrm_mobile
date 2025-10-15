import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/write_off/write_off_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/models/api_exception_model.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/goods_details_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/styled_action_button.dart';
import 'package:crm_task_manager/page_2/warehouse/write_off/write_off_delete.dart';
import 'package:crm_task_manager/page_2/warehouse/write_off/write_off_edit.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../money/widgets/error_dialog.dart';

class WriteOffDocumentDetailsScreen extends StatefulWidget {
  final int documentId;
  final String docNumber;
  final VoidCallback? onDocumentUpdated;
  // НОВОЕ: Параметры прав доступа
  final bool hasUpdatePermission;
  final bool hasDeletePermission;

  const WriteOffDocumentDetailsScreen({
    required this.documentId,
    required this.docNumber,
    this.onDocumentUpdated,
    this.hasUpdatePermission = false,
    this.hasDeletePermission = false,
    super.key,
  });

  @override
  _WriteOffDocumentDetailsScreenState createState() => _WriteOffDocumentDetailsScreenState();
}

class _WriteOffDocumentDetailsScreenState extends State<WriteOffDocumentDetailsScreen> {
  final ApiService _apiService = ApiService();
  IncomingDocument? currentDocument;
  List<Map<String, dynamic>> details = [];
  bool _isLoading = false;
  bool _isButtonLoading = false;
  String? baseUrl;
  bool _documentUpdated = false;
  bool _goodMeasurementEnabled = true;
  final Map<int, String> _unitMap = {
    23: 'шт',
  };

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl();
    _fetchDocumentDetails();
    _loadGoodMeasurementSetting();
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
      final document = await _apiService.getWriteOffDocumentById(widget.documentId);
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
        showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', e.message);
        return;
      }
      final localizations = AppLocalizations.of(context)!;
      _showSnackBar('${localizations.translate('error_loading_document') ?? 'Ошибка загрузки документа'}: $e', false);
    }
  }

  void _updateDetails(IncomingDocument? document) {
    if (document == null) {
      details.clear();
      return;
    }

    details = [
      {
        'label': '${AppLocalizations.of(context)!.translate('document_number') ?? 'Номер документа'}:',
        'value': document.docNumber ?? '',
      },
      {
        'label': '${AppLocalizations.of(context)!.translate('date') ?? 'Дата'}:',
        'value': document.date != null ? DateFormat('dd.MM.yyyy').format(document.date!) : '',
      },
      {
        'label': '${AppLocalizations.of(context)!.translate('storage') ?? 'Склад'}:',
        'value': document.storage?.name ?? '',
      },
      {
        'label': '${AppLocalizations.of(context)!.translate('article') ?? 'Статья'}:',
        'value': document.article?.name ?? '',
      },
      {
        'label': AppLocalizations.of(context)!.translate('comment') ?? 'Комментарий',
        'value': document.comment ?? '',
      },
      {
        'label': '${AppLocalizations.of(context)!.translate('total_quantity') ?? 'Общее количество'}:',
        'value': document.totalQuantity.toString(),
      },
      {
        'label': '${AppLocalizations.of(context)!.translate('status') ?? 'Статус'}:',
        'value': _getLocalizedStatus(document),
      },
      if (document.deletedAt != null)
        {
          'label': '${AppLocalizations.of(context)!.translate('deleted_at') ?? 'Дата удаления'}:',
          'value': DateFormat('dd.MM.yyyy HH:mm').format(document.deletedAt!),
        },
    ];
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
    // ИЗМЕНЕНО: Проверяем update-право
    if (!widget.hasUpdatePermission) {
      final localizations = AppLocalizations.of(context)!;
      _showSnackBar(localizations.translate('no_permission_to_approve') ?? 'Нет прав на проведение документа', false);
      return;
    }

    setState(() {
      _isButtonLoading = true;
    });
    try {
      await _apiService.approveWriteOffDocument(widget.documentId);
      setState(() {
        currentDocument = currentDocument!.copyWith(approved: 1);
        _documentUpdated = true;
      });
      _updateStatusOnly();
      final localizations = AppLocalizations.of(context)!;
      _showSnackBar(localizations.translate('document_approved') ?? 'Документ проведен', true);
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        final localizations = AppLocalizations.of(context)!;
        showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', e.message);
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
    // ИЗМЕНЕНО: Проверяем update-право
    if (!widget.hasUpdatePermission) {
      final localizations = AppLocalizations.of(context)!;
      _showSnackBar(localizations.translate('no_permission_to_unapprove') ?? 'Нет прав на отмену проведения', false);
      return;
    }

    setState(() {
      _isButtonLoading = true;
    });
    try {
      await _apiService.unApproveWriteOffDocument(widget.documentId);
      setState(() {
        currentDocument = currentDocument!.copyWith(approved: 0);
        _documentUpdated = true;
      });
      _updateStatusOnly();
      final localizations = AppLocalizations.of(context)!;
      _showSnackBar(localizations.translate('document_approval_canceled') ?? 'Проведение документа отменено', true);
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        final localizations = AppLocalizations.of(context)!;
        showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', e.message);
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
    // ИЗМЕНЕНО: Привязываем к update или delete (здесь — update, как approve)
    if (!widget.hasUpdatePermission) {
      final localizations = AppLocalizations.of(context)!;
      _showSnackBar(localizations.translate('no_permission_to_restore') ?? 'Нет прав на восстановление', false);
      return;
    }

    setState(() {
      _isButtonLoading = true;
    });
    try {
      await _apiService.restoreWriteOffDocument(widget.documentId);
      setState(() {
        currentDocument = currentDocument!.copyWith(deletedAt: null); // clearDeletedAt
        _documentUpdated = true;
      });
      _updateStatusOnly();
      final localizations = AppLocalizations.of(context)!;
      _showSnackBar(localizations.translate('document_restored') ?? 'Документ восстановлен', true);
      // ИЗМЕНЕНО: Reload через BLoC
      context.read<WriteOffBloc>().add(const FetchWriteOffs(forceRefresh: true));
    } catch (e) {
      if (e is ApiException && e.statusCode == 409) {
        final localizations = AppLocalizations.of(context)!;
        showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', e.message);
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

    // НОВОЕ: Если удалён — restore только с update-правом
    if (currentDocument!.deletedAt != null) {
      if (!widget.hasUpdatePermission) return const SizedBox.shrink();
      return StyledActionButton(
        text: AppLocalizations.of(context)!.translate('restore_document') ?? 'Восстановить',
        icon: Icons.restore,
        color: const Color(0xFF2196F3),
        onPressed: _restoreDocument,
      );
    }

    // НОВОЕ: approve/unapprove только с update-правом
    if (!widget.hasUpdatePermission) {
      return const SizedBox.shrink();
    }

    if (currentDocument!.approved == 0) {
      return StyledActionButton(
        text: AppLocalizations.of(context)!.translate('approve_document') ?? 'Провести',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF4CAF50),
        onPressed: _approveDocument,
      );
    }

    return StyledActionButton(
      text: AppLocalizations.of(context)!.translate('unapprove_document') ?? 'Отменить проведение',
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
                  text: AppLocalizations.of(context)!.translate('close') ?? 'Закрыть',
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
                      AppLocalizations.of(context)!.translate('document_data_unavailable') ?? 'Данные документа недоступны',
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Center(child: _buildActionButton()),
                        ),
                        _buildDetailsList(),
                        const SizedBox(height: 16),
                        if (currentDocument!.documentGoods != null && currentDocument!.documentGoods!.isNotEmpty) ...[
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
    // ИЗМЕНЕНО: showActions с правами
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
          "${AppLocalizations.of(context)!.translate('view_document') ?? 'Просмотр документа'} №${widget.docNumber}",
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
                  // НОВОЕ: Edit только с update-правом
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
                            builder: (context) => EditWriteOffDocumentScreen(
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
                      ),
                      onPressed: () {
                        if (_isLoading) return;
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return BlocProvider.value(
                              value: BlocProvider.of<WriteOffBloc>(context),
                              child: WriteOffDeleteDocumentDialog(documentId: widget.documentId),
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
                  decoration: value.isNotEmpty ? TextDecoration.underline : null,
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
        _buildTitleRow(AppLocalizations.of(context)!.translate('goods') ?? 'Товары'),
        const SizedBox(height: 8),
        if (goods.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: TaskCardStyles.taskCardDecoration,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.translate('empty') ?? 'Нет товаров',
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
    final availableUnits = good.good?.units ?? [];

    final selectedUnit = good.unit ??
        availableUnits.firstWhere(
              (unit) => unit.id == good.unitId,
          orElse: () => Unit(id: null, name: 'шт'),
        );

    final unitShortName = selectedUnit.shortName ?? selectedUnit.name ?? 'шт';

    return GestureDetector(
      onTap: () {
        _navigateToGoodsDetails(good);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: TaskCardStyles.taskCardDecoration,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
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
                        style: TaskCardStyles.titleStyle.copyWith(fontSize: 14),
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
                                    AppLocalizations.of(context)!.translate('unit') ?? 'Ед.',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'Gilroy',
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xff99A4BA),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    unitShortName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Gilroy',
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xff1E2E52),
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
                                  AppLocalizations.of(context)!.translate('quantity') ?? 'Кол-во',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff99A4BA),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${good.quantity ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff1E2E52),
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
                                  AppLocalizations.of(context)!.translate('price') ?? 'Цена',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff99A4BA),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${(double.tryParse(good.price ?? '0.00') ?? 0.00).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff1E2E52),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F7FD),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.translate('total') ?? 'Итого',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500,
                                color: Color(0xff1E2E52),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${((good.quantity ?? 0) * (double.tryParse(good.price ?? '0') ?? 0)).toStringAsFixed(2)} ${currentDocument!.currency?.symbolCode ?? ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w700,
                                color: Color(0xff4CAF50),
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

  Widget _buildImageWidget(DocumentGood good) {
    if (baseUrl == null || good.good == null || good.good!.files == null || good.good!.files!.isEmpty) {
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
        child: Icon(Icons.image_not_supported, size: 40, color: Color(0xff99A4BA)),
      ),
    );
  }

  void _navigateToGoodsDetails(DocumentGood good) {
    final goodId = good.good?.id;
    if (goodId == null || goodId == 0) {
      _showSnackBar(
          AppLocalizations.of(context)!.translate('error_no_good_id') ?? 'Ошибка: Не удалось определить ID товара', false);
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
          style: TaskCardStyles.titleStyle.copyWith(
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