import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/supplier_return/supplier_return_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/supplier_return/supplier_return_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/supplier_return/supplier_return_state.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/page_2/money/widgets/error_dialog.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier_return_document/supplier_return_document_card_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/client_sale/client_sale_confirm_dialog.dart'; // НОВОЕ: Импорт диалога подтверждения
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'supplier_return_document_create_screen.dart';

class SupplierReturnScreen extends StatefulWidget {
  final int? organizationId;

  const SupplierReturnScreen({this.organizationId, super.key});

  @override
  State<SupplierReturnScreen> createState() => _SupplierReturnScreenState();
}

class _SupplierReturnScreenState extends State<SupplierReturnScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Map<String, dynamic> _currentFilters = {};
  late SupplierReturnBloc _supplierReturnBloc;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;

  // НОВОЕ: Флаги прав доступа
  bool _hasCreatePermission = false;
  bool _hasDeletePermission = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkPermissions(); // НОВОЕ: Проверка прав
    _supplierReturnBloc = context.read<SupplierReturnBloc>()..add(FetchSupplierReturn(forceRefresh: true,));
    _scrollController.addListener(_onScroll);
  }

  // НОВОЕ: Проверка прав доступа
  Future<void> _checkPermissions() async {
    try {
      final create = await _apiService.hasPermission('supplier_return_document.create');
      final delete = await _apiService.hasPermission('supplier_return_document.delete');

      if (mounted) {
        setState(() {
          _hasCreatePermission = create;
          _hasDeletePermission = delete;
        });
      }
    } catch (e) {
      debugPrint('Ошибка при проверке прав доступа: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedMax) {
      setState(() {
        _isLoadingMore = true;
      });
      _supplierReturnBloc.add(FetchSupplierReturn(
        forceRefresh: false,
        filters: _currentFilters,
      ));
    }
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    _currentFilters['query'] = query;
    _supplierReturnBloc.add(FetchSupplierReturn(
      forceRefresh: true,
      filters: _currentFilters,
    ));
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _currentFilters = {};
      _hasReachedMax = false;
    });
    _supplierReturnBloc.add(const FetchSupplierReturn(forceRefresh: true));
    await Future.delayed(const Duration(milliseconds: 500));
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return BlocProvider.value(
      value: _supplierReturnBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: CustomAppBarPage2(
            title: localizations.translate('appbar_supplier_return') ?? 'Возврат поставщику',
            showSearchIcon: true,
            showFilterIcon: false,
            showFilterOrderIcon: false,
            onChangedSearchInput: _onSearch,
            textEditingController: _searchController,
            focusNode: _focusNode,
            clearButtonClick: (value) {
              if (!value) {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
                _supplierReturnBloc.add(const FetchSupplierReturn(forceRefresh: true));
              }
            },
            onClickProfileAvatar: () {},
            clearButtonClickFiltr: (bool p1) {},
            currentFilters: {},
          ),
        ),
        body: BlocListener<SupplierReturnBloc, SupplierReturnState>(
          listener: (context, state) {
            if (!mounted) return;
            
            if (state is SupplierReturnLoaded) {
              setState(() {
                _hasReachedMax = state.hasReachedMax;
                _isLoadingMore = false;
              });
            } else if (state is SupplierReturnError) {
              setState(() {
                _isLoadingMore = false;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) { // НОВОЕ: postFrame
                if (mounted && context.mounted) {
                  if (state.statusCode  == 409) {
                    final localizations = AppLocalizations.of(context)!;
                    showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', state.message);
                    return;
                  }
                  _showSnackBar(state.message, false);
                }
              });
            } else if (state is SupplierReturnCreateSuccess) {
              WidgetsBinding.instance.addPostFrameCallback((_) { // НОВОЕ: postFrame
                if (mounted && context.mounted) {
                  _showSnackBar(state.message, true);
                }
              });
            } else if (state is SupplierReturnCreateError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && context.mounted) {
                  if (state.statusCode  == 409) {
                    final localizations = AppLocalizations.of(context)!;
                    showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', state.message);
                    return;
                  }
                  _showSnackBar(state.message, false);
                }
              });
            } else if (state is SupplierReturnUpdateSuccess) { // НОВОЕ: Обработка update
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && context.mounted) {
                  _showSnackBar(state.message, true);
                  _supplierReturnBloc.add(const FetchSupplierReturn(forceRefresh: true));
                }
              });
            } else if (state is SupplierReturnUpdateError) { // НОВОЕ
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && context.mounted) {
                  if (state.statusCode  == 409) {
                    final localizations = AppLocalizations.of(context)!;
                    showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', state.message);
                    return;
                  }
                  _showSnackBar(state.message, false);
                }
              });
            } else if (state is SupplierReturnDeleteSuccess) {
              WidgetsBinding.instance.addPostFrameCallback((_) { // НОВОЕ: postFrame
                if (mounted && context.mounted) {
                  _showSnackBar(state.message, true);
                  _supplierReturnBloc.add(FetchSupplierReturn(forceRefresh: true, filters: _currentFilters));
                }
              });
            } else if (state is SupplierReturnDeleteError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && context.mounted) {
                  if (state.statusCode == 409) {
                    final localizations = AppLocalizations.of(context)!;
                    showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', state.message);
                    _supplierReturnBloc.add(FetchSupplierReturn(forceRefresh: true, filters: _currentFilters));
                    return;
                  }
                  _showSnackBar(state.message, false);
                }
              });
            } else if (state is SupplierReturnRestoreSuccess) { // НОВОЕ: Обработка restore
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && context.mounted) {
                  _showSnackBar(state.message, true);
                  _supplierReturnBloc.add(FetchSupplierReturn(forceRefresh: true, filters: _currentFilters));
                }
              });
            } else if (state is SupplierReturnRestoreError) { // НОВОЕ
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && context.mounted) {
                  if (state.statusCode == 409) {
                    final localizations = AppLocalizations.of(context)!;
                    showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', state.message);
                    _supplierReturnBloc.add(FetchSupplierReturn(forceRefresh: true, filters: _currentFilters));
                    return;
                  }
                  _showSnackBar(state.message, false);
                }
              });
            }
          },
         child: BlocBuilder<SupplierReturnBloc, SupplierReturnState>(
  builder: (context, state) {
    if (state is SupplierReturnLoading || 
        state is SupplierReturnDeleteLoading || 
        state is SupplierReturnRestoreLoading) {
      return Center(
        child: PlayStoreImageLoading(
          size: 80.0,
          duration: const Duration(milliseconds: 1000),
        ),
      );
    }

    final List<IncomingDocument> currentData = state is SupplierReturnLoaded ? state.data : []; // ИЗМЕНЕНО: List<>

    if (currentData.isEmpty && state is SupplierReturnLoaded) {
      return Center(
        child: Text(
          _isSearching
              ? localizations.translate('nothing_found') ?? 'Ничего не найдено'
              : localizations.translate('no_supplier_return') ?? 'Нет возвратов поставщику',
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff99A4BA),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xff1E2E52),
      backgroundColor: Colors.white,
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: currentData.length + (_hasReachedMax ? 0 : 1),
        itemBuilder: (context, index) {
          if (index >= currentData.length) {
            return _isLoadingMore
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: PlayStoreImageLoading(
                        size: 80.0,
                        duration: const Duration(milliseconds: 1000),
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }
          
          // НОВОЕ: Dismissible только влево - delete или restore в зависимости от состояния
          return _hasDeletePermission
              ? Dismissible(
                  key: Key(currentData[index].id.toString()),
                  // Свайп только справа налево для обоих действий
                  direction: DismissDirection.endToStart,

                  background: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: currentData[index].deletedAt == null ? Colors.red : const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.centerRight,
                    child: Icon(
                      currentData[index].deletedAt == null 
                          ? Icons.delete 
                          : Icons.restore_from_trash,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  confirmDismiss: (direction) async {
                    final isDeleted = currentData[index].deletedAt != null;
                    final docNumber = currentData[index].docNumber ?? 'N/A';

                    if (isDeleted) {
                      return await DocumentConfirmDialog.showRestoreConfirmation(
                        context,
                        docNumber,
                      );
                    } else {
                      return await DocumentConfirmDialog.showDeleteConfirmation(
                        context,
                        docNumber,
                      );
                    }
                  },
                  onDismissed: (direction) {
                    final isDeleted = currentData[index].deletedAt != null;
                    
                    if (isDeleted) {
                      // RESTORE - для удалённых документов
                      debugPrint("♻️ [UI] Восстановление документа ID: ${currentData[index].id}");
                      _supplierReturnBloc.add(RestoreSupplierReturn(
                        currentData[index].id!,
                        localizations,
                      ));
                    } else {
                      // DELETE - для активных документов
                      debugPrint("🗑️ [UI] Удаление документа ID: ${currentData[index].id}");
                      _supplierReturnBloc.add(DeleteSupplierReturn(
                        currentData[index].id!,
                        shouldReload: true,
                      ));
                    }
                  },

                  child: SupplierReturnCard(
                    document: currentData[index],
                    onUpdate: () {
                      _supplierReturnBloc.add(const FetchSupplierReturn(forceRefresh: true));
                    },
                  ),
                )
              : SupplierReturnCard(
                  document: currentData[index],
                  onUpdate: () {
                    _supplierReturnBloc.add(const FetchSupplierReturn(forceRefresh: true));
                  },
                );
        },
      ),
    );
  },
),
        ),
        // ИЗМЕНЕНО: FAB только с create-правом
        floatingActionButton: _hasCreatePermission
            ? FloatingActionButton(
                key: const Key('create_supplier_return_button'),
                onPressed: () async {
                  if (mounted) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SupplierReturnDocumentCreateScreen(
                          organizationId: widget.organizationId,
                        ),
                      ),
                    );

                    if (result == true && mounted) {
                      _supplierReturnBloc.add(const FetchSupplierReturn(forceRefresh: true));
                    }
                  }
                },
                backgroundColor: const Color(0xff1E2E52),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
      ),
    );
  }
}