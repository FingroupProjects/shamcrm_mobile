import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/incoming_document_history/incoming_document_history_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/custom_widget/animation.dart'; // Импорт PlayStoreImageLoading
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/goods_details_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/incoming_document_history_widget.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/styled_action_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class IncomingDocumentDetailsScreen extends StatefulWidget {
  final int documentId;
  final String docNumber;
  final VoidCallback? onDocumentUpdated;

  const IncomingDocumentDetailsScreen({
    required this.documentId,
    required this.docNumber,
    this.onDocumentUpdated,
    super.key,
  });

  @override
  _IncomingDocumentDetailsScreenState createState() => _IncomingDocumentDetailsScreenState();
}

class _IncomingDocumentDetailsScreenState extends State<IncomingDocumentDetailsScreen> {
  final ApiService _apiService = ApiService();
  IncomingDocument? currentDocument;
  List<Map<String, dynamic>> details = [];
  bool _isLoading = false;
  String? baseUrl;
  bool _documentUpdated = false;

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl();
    _fetchDocumentDetails();
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
      final document = await _apiService.getIncomingDocumentById(widget.documentId);
      setState(() {
        currentDocument = document;
        _updateDetails(document);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('error_loading_document') ?? 'Ошибка загрузки документа: $e',
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _updateDetails(IncomingDocument? document) {
    if (document == null) {
      details.clear();
      return;
    }

    details = [
      {
        'label': AppLocalizations.of(context)!.translate('document_number') ?? 'Номер документа',
        'value': document.docNumber ?? '',
      },
      {
        'label': AppLocalizations.of(context)!.translate('date') ?? 'Дата',
        'value': document.date != null ? DateFormat('dd.MM.yyyy').format(document.date!) : '',
      },
      {
        'label': AppLocalizations.of(context)!.translate('storage') ?? 'Склад',
        'value': document.storage?.name ?? '',
      },
      {
        'label': AppLocalizations.of(context)!.translate('supplier') ?? 'Поставщик',
        'value': document.model?.name ?? '',
      },
      {
        'label': AppLocalizations.of(context)!.translate('supplier_phone') ?? 'Телефон поставщика',
        'value': document.model?.phone ?? '',
      },
      {
        'label': AppLocalizations.of(context)!.translate('supplier_inn') ?? 'ИНН поставщика',
        'value': document.model?.inn?.toString() ?? '',
      },
      {
        'label': AppLocalizations.of(context)!.translate('comment') ?? 'Комментарий',
        'value': document.comment ?? '',
      },
      {
        'label': AppLocalizations.of(context)!.translate('currency') ?? 'Валюта',
        'value': '${document.currency?.name ?? ''} (${document.currency?.symbolCode ?? ''})',
      },
      {
        'label': AppLocalizations.of(context)!.translate('total_quantity') ?? 'Общее количество',
        'value': document.totalQuantity.toString(),
      },
      {
        'label': AppLocalizations.of(context)!.translate('total_sum') ?? 'Общая сумма',
        'value': '${document.totalSum.toStringAsFixed(2)} ${document.currency?.symbolCode ?? ''}',
      },
      {
        'label': AppLocalizations.of(context)!.translate('status') ?? 'Статус',
        'value': document.statusText,
      },
    ];
  }

  Future<void> _approveDocument() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _apiService.approveIncomingDocument(widget.documentId);
      setState(() {
        _documentUpdated = true;
      });
      await _fetchDocumentDetails();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('document_approved') ?? 'Документ проведен',
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('error_approving_document') ?? 'Ошибка при проведении документа: $e',
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _unApproveDocument() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _apiService.unApproveIncomingDocument(widget.documentId);
      setState(() {
        _documentUpdated = true;
      });
      await _fetchDocumentDetails();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('document_unapproved') ?? 'Проведение документа отменено',
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('error_unapproving_document') ?? 'Ошибка при отмене проведения документа: $e',
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<IncomingDocumentHistoryBloc>(
          create: (context) => IncomingDocumentHistoryBloc(context.read<ApiService>()),
        ),
      ],
      child: PopScope(
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
                    duration: Duration(milliseconds: 1000),
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
                          if (currentDocument!.approved == 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Center(
                                child: _isLoading
                                    ? PlayStoreImageLoading(
                                        size: 80.0,
                                        duration: Duration(milliseconds: 1000),
                                      )
                                    : StyledActionButton(
                                        text: AppLocalizations.of(context)!.translate('approve_document') ?? 'Провести',
                                        icon: Icons.check_circle_outline,
                                        color: const Color(0xFF4CAF50),
                                        onPressed: _approveDocument,
                                      ),
                              ),
                            )
                          else if (currentDocument!.approved == 1)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Center(
                                child: _isLoading
                                    ? PlayStoreImageLoading(
                                        size: 80.0,
                                        duration: Duration(milliseconds: 1000),
                                      )
                                    : StyledActionButton(
                                        text: AppLocalizations.of(context)!.translate('unapprove_document') ?? 'Отменить проведение',
                                        icon: Icons.cancel_outlined,
                                        color: const Color(0xFFFFA500),
                                        onPressed: _unApproveDocument,
                                      ),
                              ),
                            ),
                          _buildDetailsList(),
                          const SizedBox(height: 16),
                          // IncomingDocumentHistoryWidget(documentId: widget.documentId),
                          const SizedBox(height: 16),
                          if (currentDocument!.documentGoods != null && currentDocument!.documentGoods!.isNotEmpty) ...[
                            _buildGoodsList(currentDocument!.documentGoods!),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
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
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // IconButton(
            //   padding: EdgeInsets.zero,
            //   constraints: const BoxConstraints(),
            //   icon: Image.asset(
            //     'assets/icons/edit.png',
            //     width: 24,
            //     height: 24,
            //   ),
            //   onPressed: () {
            //     ScaffoldMessenger.of(context).showSnackBar(
            //        SnackBar(
            //         content: Text('Редактирование документа пока не реализовано'),
            //         backgroundColor: Colors.orange,
            //         behavior: SnackBarBehavior.floating,
            //         margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //         duration: Duration(seconds: 3),
            //       ),
            //     );
            //   },
            // ),
            // IconButton(
            //   padding: const EdgeInsets.only(right: 8),
            //   constraints: const BoxConstraints(),
            //   icon: Image.asset(
            //     'assets/icons/delete.png',
            //     width: 24,
            //     height: 24,
            //   ),
            //   onPressed: () {
            //     ScaffoldMessenger.of(context).showSnackBar(
            //        SnackBar(
            //         content: Text('Удаление документа пока не реализовано'),
            //         backgroundColor: Colors.orange,
            //         behavior: SnackBarBehavior.floating,
            //         margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //         duration: Duration(seconds: 3),
            //       ),
            //     );
            //   },
            // ),
          ],
        ),
      ],
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
    if (label == AppLocalizations.of(context)!.translate('comment') ||
        label == AppLocalizations.of(context)!.translate('supplier')) {
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
          SizedBox(
            height: 550,
            child: ListView.builder(
              itemCount: goods.length,
              itemBuilder: (context, index) {
                return _buildGoodsItem(goods[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildGoodsItem(DocumentGood good) {
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        good.good?.name ?? 'N/A',
                        style: TaskCardStyles.titleStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.translate('quantity') ?? 'Количество',
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff1E2E52),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${good.quantity ?? 0}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              color: Color(0xff1E2E52),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.translate('price') ?? 'Цена',
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff1E2E52),
                            ),
                          ),
                          const SizedBox(width: 8),
                        // Исправленная часть для отображения цены товара
Text(
  '${good.price ?? '0.00'} ${currentDocument!.currency?.symbolCode ?? ''}',
  style: const TextStyle(
    fontSize: 18,
    fontFamily: 'Gilroy',
    fontWeight: FontWeight.w700,
    color: Color(0xff1E2E52),
  ),
),
const SizedBox(height: 4),
Row(
  children: [
    Text(
      AppLocalizations.of(context)!.translate('total') ?? 'Сумма',
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color(0xff1E2E52),
      ),
    ),
    const SizedBox(width: 8),
    Text(
      '${((good.quantity ?? 0) * double.parse(good.price?.toString() ?? '0')).toStringAsFixed(2)} ${currentDocument!.currency?.symbolCode ?? ''}',
      style: const TextStyle(
        fontSize: 18,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w700,
        color: Color(0xff4CAF50),
      ),
    ),
  ],
),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildImageWidget(good),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('error_no_good_id') ?? 'Ошибка: Не удалось определить ID товара',
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoodsDetailsScreen(
          id: goodId,
          isFromOrder: false,
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