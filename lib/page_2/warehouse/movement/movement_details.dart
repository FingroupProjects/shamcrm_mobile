import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/movement/movement_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/movement/movement_event.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/goods_details_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/styled_action_button.dart';
import 'package:crm_task_manager/page_2/warehouse/movement/movement_delete.dart';
import 'package:crm_task_manager/page_2/warehouse/movement/movement_edit.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../models/api_exception_model.dart';
import '../../money/widgets/error_dialog.dart';

class MovementDocumentDetailsScreen extends StatefulWidget {
  final int documentId;
  final String docNumber;
  final VoidCallback? onDocumentUpdated;

  const MovementDocumentDetailsScreen({
    required this.documentId,
    required this.docNumber,
    this.onDocumentUpdated,
    super.key,
  });

  @override
  _MovementDocumentDetailsScreenState createState() => _MovementDocumentDetailsScreenState();
}

class _MovementDocumentDetailsScreenState extends State<MovementDocumentDetailsScreen> {
  final ApiService _apiService = ApiService();
  IncomingDocument? currentDocument;
  List<Map<String, dynamic>> details = [];
  bool _isLoading = false;
  bool _isButtonLoading = false;
  String? baseUrl;
  bool _documentUpdated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeBaseUrl();
        _fetchDocumentDetails();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeBaseUrl() async {
    if (!mounted) return;
    
    try {
      final staticBaseUrl = await _apiService.getStaticBaseUrl();
      if (mounted) {
        setState(() {
          baseUrl = staticBaseUrl;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          baseUrl = 'https://shamcrm.com/storage';
        });
      }
    }
  }

  Future<void> _fetchDocumentDetails() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final document = await _apiService.getMovementDocumentById(widget.documentId);
      if (mounted) {
        setState(() {
          currentDocument = document;
          _updateDetails(document);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (e is ApiException && e.statusCode == 409) {
          final localizations = AppLocalizations.of(context)!;
          showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', e.message);
          return;
        }
        _showSnackBar(
            AppLocalizations.of(context)?.translate('error_loading_document') ??
                'Ошибка загрузки документа: $e',
            false);
      }
    }
  }

  void _updateDetails(IncomingDocument? document) {
    if (document == null || !mounted) {
      details.clear();
      return;
    }

    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    details = [
      {
        'label': '${localizations.translate('document_number') ?? 'Номер документа'}:',
        'value': document.docNumber ?? '',
      },
      {
        'label': '${localizations.translate('date') ?? 'Дата'}:',
        'value': document.date != null
            ? DateFormat('dd.MM.yyyy').format(document.date!)
            : '',
      },
      {
        'label': '${localizations.translate('sender_storage') ?? 'Склад отправитель'}:',
        'value': document.storage?.name ?? '',
      },
      {
        'label': '${localizations.translate('recipient_storage') ?? 'Склад получатель'}:',
        'value': 'Получатель', // В реальном проекте здесь должно быть поле из модели
      },
      {
        'label': localizations.translate('comment') ?? 'Комментарий',
        'value': document.comment ?? '',
      },
      {
        'label': '${localizations.translate('total_quantity') ?? 'Общее количество'}:',
        'value': document.totalQuantity.toString(),
      },
      {
        'label': '${localizations.translate('status') ?? 'Статус'}:',
        'value': _getLocalizedStatus(document),
      },
      if (document.deletedAt != null)
        {
          'label': '${localizations.translate('deleted_at') ?? 'Дата удаления'}:',
          'value': DateFormat('dd.MM.yyyy HH:mm').format(document.deletedAt!),
        },
    ];
  }

  String _getLocalizedStatus(IncomingDocument document) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      if (document.deletedAt != null) return 'Удален';
      return document.approved == 1 ? 'Проведен' : 'Не проведен';
    }

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
    if (!mounted || !context.mounted) return;
    
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
    if (currentDocument != null && mounted) {
      setState(() {
        _updateDetails(currentDocument);
      });
    }
  }

  Future<void> _approveDocument() async {
    if (!mounted) return;
    
    setState(() {
      _isButtonLoading = true;
    });
    
    try {
      await _apiService.approveMovementDocument(widget.documentId);
      if (mounted) {
        setState(() {
          currentDocument = currentDocument!.copyWith(approved: 1);
          _documentUpdated = true;
        });
        _updateStatusOnly();
        _showSnackBar(
            AppLocalizations.of(context)?.translate('document_approved') ??
                'Документ проведен',
            true);
      }
    } catch (e) {
      if (mounted) {
        if (e is ApiException && e.statusCode == 409) {
          final localizations = AppLocalizations.of(context)!;
          showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', e.message);
          return;
        }
        _showSnackBar(
            AppLocalizations.of(context)?.translate('error_approving_document') ??
                'Ошибка при проведении документа: $e',
            false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  Future<void> _unApproveDocument() async {
    if (!mounted) return;
    
    setState(() {
      _isButtonLoading = true;
    });
    
    try {
      await _apiService.unApproveMovementDocument(widget.documentId);
      if (mounted) {
        setState(() {
          currentDocument = currentDocument!.copyWith(approved: 0);
          _documentUpdated = true;
        });
        _updateStatusOnly();
        _showSnackBar(
            AppLocalizations.of(context)?.translate('document_unapproved') ??
                'Проведение документа отменено',
            true);
      }
    } catch (e) {
      if (mounted) {
        if (e is ApiException && e.statusCode == 409) {
          final localizations = AppLocalizations.of(context)!;
          showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', e.message);
          return;
        }
        _showSnackBar(
            AppLocalizations.of(context)?.translate('error_unapproving_document') ??
                'Ошибка при отмене проведения документа: $e',
            false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  Future<void> _restoreDocument() async {
    if (!mounted) return;
    
    setState(() {
      _isButtonLoading = true;
    });
    
    try {
      await _apiService.restoreMovementDocument(widget.documentId);
      
      if (mounted) {
        await _fetchDocumentDetails();
        _documentUpdated = true;
        _showSnackBar(
            AppLocalizations.of(context)?.translate('document_restored') ??
                'Документ восстановлен',
            true);
        
        if (context.mounted) {
          context.read<MovementBloc>().add(const FetchMovements(forceRefresh: true));
        }
      }
    } catch (e) {
      if (mounted) {
        if (e is ApiException && e.statusCode == 409) {
          final localizations = AppLocalizations.of(context)!;
          showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', e.message);
          return;
        }
        _showSnackBar(
            AppLocalizations.of(context)?.translate('error_restoring_document') ??
                'Ошибка при восстановлении документа: $e',
            false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  Widget _buildActionButton() {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();
    
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

    if (currentDocument!.deletedAt != null) {
      return StyledActionButton(
        text: localizations.translate('restore_document') ?? 'Восстановить',
        icon: Icons.restore,
        color: const Color(0xFF2196F3),
        onPressed: _restoreDocument,
      );
    }

    if (currentDocument!.approved == 0) {
      return StyledActionButton(
        text: localizations.translate('approve_document') ?? 'Провести',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF4CAF50),
        onPressed: _approveDocument,
      );
    }

    return StyledActionButton(
      text: localizations.translate('unapprove_document') ?? 'Отменить проведение',
      icon: Icons.cancel_outlined,
      color: const Color(0xFFFFA500),
      onPressed: _unApproveDocument,
    );
  }

  void _showFullTextDialog(String title, String content) {
    final localizations = AppLocalizations.of(context);
    if (!mounted || localizations == null) return;
    
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
                  text: localizations.translate('close') ?? 'Закрыть',
                  icon: Icons.close,
                  color: const Color(0xff1E2E52),
                  onPressed: () {
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
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
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<MovementBloc>(
          create: (context) => MovementBloc(context.read<ApiService>()),
        ),
      ],
      child: PopScope(
        onPopInvoked: (didPop) {
          if (didPop && _documentUpdated && widget.onDocumentUpdated != null) {
            widget.onDocumentUpdated!();
          }
        },
        child: Scaffold(
          appBar: _buildAppBar(context, localizations),
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
                        localizations.translate('document_data_unavailable') ??
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
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                          ],
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, AppLocalizations localizations) {
    final showActions = currentDocument?.deletedAt == null;

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
            onPressed: () {
              if (mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
      title: Transform.translate(
        offset: const Offset(-10, 0),
        child: Text(
          "${localizations.translate('view_document') ?? 'Просмотр документа'} №${widget.docNumber}",
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
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Image.asset(
                      'assets/icons/edit.png',
                      width: 24,
                      height: 24,
                    ),
                    onPressed: () async {
                      if (!mounted) return;
                      
                      try {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditMovementDocumentScreen(
                              document: currentDocument!,
                            ),
                          ),
                        );
                        
                        if (mounted && result == true) {
                          _fetchDocumentDetails();
                          if (widget.onDocumentUpdated != null) {
                            widget.onDocumentUpdated!();
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          _showSnackBar('Ошибка при редактировании: $e', false);
                        }
                      }
                    },
                  ),
                  IconButton(
                    padding: const EdgeInsets.only(right: 8),
                    constraints: const BoxConstraints(),
                    icon: Image.asset(
                      'assets/icons/delete.png',
                      width: 24,
                      height: 24,
                    ),
                    onPressed: () {
                      if (!mounted) return;
                      
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return BlocProvider.value(
                            value: BlocProvider.of<MovementBloc>(context),
                            child: MovementDeleteDocumentDialog(documentId: widget.documentId),
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
    final localizations = AppLocalizations.of(context);
    
    if (label == (localizations?.translate('comment') ?? 'Комментарий')) {
      return GestureDetector(
        onTap: () {
          if (value.isNotEmpty && mounted) {
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
    final localizations = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleRow(localizations?.translate('goods') ?? 'Товары'),
        const SizedBox(height: 8),
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
    final localizations = AppLocalizations.of(context);
    
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
                            localizations?.translate('quantity') ?? 'Количество',
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
    final localizations = AppLocalizations.of(context);
    final goodId = good.good?.id;
    
    if (goodId == null || goodId == 0) {
      _showSnackBar(
          localizations?.translate('error_no_good_id') ??
              'Ошибка: Не удалось определить ID товара',
          false);
      return;
    }

    if (mounted) {
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