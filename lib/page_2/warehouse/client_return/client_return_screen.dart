import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/client_return/client_return_bloc.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/app_bar_selection_mode.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/page_2/money/widgets/error_dialog.dart';
import 'package:crm_task_manager/page_2/warehouse/client_return/client_return_card.dart';
import 'package:crm_task_manager/page_2/warehouse/client_return/client_return_create.dart';
import 'package:crm_task_manager/page_2/warehouse/client_return/client_return_details.dart';
import 'package:crm_task_manager/page_2/warehouse/client_sale/client_sale_confirm_dialog.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../widgets/snackbar_widget.dart';

class ClientReturnScreen extends StatefulWidget {
  const ClientReturnScreen({super.key, this.organizationId});
  final int? organizationId;

  @override
  State<ClientReturnScreen> createState() => _ClientReturnScreenState();
}

class _ClientReturnScreenState extends State<ClientReturnScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Map<String, dynamic> _currentFilters = {};
  String? _search; // НОВОЕ: Для consistency
  late ClientReturnBloc _clientReturnBloc;
  bool _isInitialLoad = true;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;
  bool _isRefreshing = false; // НОВОЕ: Для consistency
  bool _selectionMode = false; // НОВОЕ: Режим выбора

  // НОВОЕ: Флаги прав доступа
  bool _hasCreatePermission = false;
  bool _hasUpdatePermission = false;
  bool _hasDeletePermission = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkPermissions(); // НОВОЕ: Проверка прав
    _clientReturnBloc = context.read<ClientReturnBloc>()..add(const FetchClientReturns(forceRefresh: true));
    _scrollController.addListener(_onScroll);
  }

  // НОВОЕ: Проверка прав доступа
  Future<void> _checkPermissions() async {
    try {
      final create = await _apiService.hasPermission('client_return_document.create');
      final update = await _apiService.hasPermission('client_return_document.update');
      final delete = await _apiService.hasPermission('client_return_document.delete');

      if (mounted) {
        setState(() {
          _hasCreatePermission = create;
          _hasUpdatePermission = update;
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

  void _onFilterSelected(Map<String, dynamic> filters) {
    setState(() {
      _currentFilters = Map.from(filters);
      _hasReachedMax = false;
      _isLoadingMore = false;
      _isSearching = false;
      _searchController.clear();
      _search = null;
    });

    _clientReturnBloc.add(FetchClientReturns(
      filters: filters,
      forceRefresh: true,
    ));
  }

  void _onResetFilters() {
    setState(() {
      _currentFilters.clear();
      _hasReachedMax = false;
      _isLoadingMore = false;
      _isSearching = false;
      _searchController.clear();
      _search = null;
    });

    _clientReturnBloc.add(const FetchClientReturns(
      filters: {},
      forceRefresh: true,
    ));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedMax) {
      setState(() {
        _isLoadingMore = true;
      });
      _clientReturnBloc.add(FetchClientReturns(
        forceRefresh: false,
        filters: _currentFilters,
        // search: _search, // НОВОЕ: Добавь search в event если нужно
      ));
    }
  }

  void _onSearch(String query) {
    if (!mounted) return;

    setState(() {
      _isSearching = query.trim().isNotEmpty;
      _search = query;
      _currentFilters['query'] = query; // Сохраняем в filters
    });
    _clientReturnBloc.add(FetchClientReturns(
      forceRefresh: true,
      filters: _currentFilters,
      // search: _search,
    ));
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;

    setState(() {
      _hasReachedMax = false;
      _isSearching = false;
      _searchController.clear();
      _search = null;
      _currentFilters.clear();
    });

    _clientReturnBloc.add(const FetchClientReturns(
      forceRefresh: true,
      filters: {},
      // search: null,
    ));
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _showSnackBar(String message, bool isSuccess) {
    debugPrint("SHOW _showSnackBar: $message");
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Очищаем выбранные элементы при выходе с экрана
          _clientReturnBloc.add(UnselectAllClientReturnDocuments());
        }
      },
      child: BlocProvider.value(
        value: _clientReturnBloc,
        child: Scaffold(
        // ИЗМЕНЕНО: FAB только с create-правом
        floatingActionButton: _hasCreatePermission
            ? FloatingActionButton(
                onPressed: () {
                  if (!mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateClientReturnDocumentScreen(
                          organizationId: widget.organizationId),
                    ),
                  ).then((_) {
                    if (mounted) {
                      _clientReturnBloc.add(FetchClientReturns(
                        forceRefresh: true,
                        filters: _currentFilters,
                      ));
                    }
                  });
                },
                backgroundColor: const Color(0xff1E2E52),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: !_selectionMode,
          forceMaterialTransparency: true,
          title: _selectionMode
              ? BlocBuilder<ClientReturnBloc, ClientReturnState>(
                  builder: (context, state) {
                    if (state is ClientReturnLoaded) {
                      bool showApprove = state.selectedData!.any((doc) => doc.approved == 0 && doc.deletedAt == null);
                      bool showDisapprove = state.selectedData!.any((doc) => doc.approved == 1 && doc.deletedAt == null);
                      bool showDelete = _hasDeletePermission &&
                          state.selectedData!.any((doc) => doc.deletedAt == null);
                      bool showRestore = state.selectedData!.any((doc) => doc.deletedAt != null);
                      _isRefreshing = false;

                      return AppBarSelectionMode(
                        title: localizations?.translate('appbar_client_returns') ?? 'Возврат от клиента',
                        onDismiss: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _clientReturnBloc.add(UnselectAllClientReturnDocuments());
                        },
                        onApprove: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _clientReturnBloc.add(MassApproveClientReturnDocuments());
                        },
                        onDisapprove: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _clientReturnBloc.add(MassDisapproveClientReturnDocuments());
                        },
                        onDelete: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _clientReturnBloc.add(MassDeleteClientReturnDocuments());
                        },
                        onRestore: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _clientReturnBloc.add(MassRestoreClientReturnDocuments());
                        },
                        showApprove: showApprove,
                        showDelete: showDelete,
                        showDisapprove: showDisapprove,
                        showRestore: showRestore,
                      );
                    }

                    return AppBarSelectionMode(
                      title: localizations?.translate('appbar_client_returns') ?? 'Возврат от клиента',
                      onDismiss: () {
                        setState(() {
                          _selectionMode = false;
                        });
                        _clientReturnBloc.add(UnselectAllClientReturnDocuments());
                      },
                    );
                  },
                )
              : CustomAppBarPage2(
            title: localizations?.translate('appbar_client_returns') ??
                'Возврат от клиента',
            showSearchIcon: true,
            showFilterIcon: false,
            showFilterOrderIcon: false,
            showFilterIncomeIcon: false,
            showFilterIncomingIcon: false,
            showFilterClientSaleIcon: false,
            showFilterClientReturnIcon: true,
            onFilterClientReturnSelected: _onFilterSelected,
            onClientReturnResetFilters: _onResetFilters,
            onChangedSearchInput: _onSearch,
            textEditingController: _searchController,
            focusNode: _focusNode,
            clearButtonClick: (value) {
              if (!value) {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _search = null;
                });
                _clientReturnBloc.add(FetchClientReturns(
                  forceRefresh: true,
                  filters: _currentFilters,
                ));
              }
            },
            onClickProfileAvatar: () {},
            clearButtonClickFiltr: (bool p1) {},
            currentFilters: _currentFilters,
          ),
        ),
        body: BlocListener<ClientReturnBloc, ClientReturnState>(
          listener: (context, state) {
            if (!mounted) return;

            if (state is ClientReturnLoaded) {
              if (mounted) {
                setState(() {
                  _hasReachedMax = state.hasReachedMax;
                  _isInitialLoad = false;
                  _isLoadingMore = false;
                  _isRefreshing = false; // НОВОЕ
                });
              }
            } else if (state is ClientReturnError) {
              if (mounted) {
                setState(() {
                  _isInitialLoad = false;
                  _isLoadingMore = false;
                  _isRefreshing = false;
                });

                WidgetsBinding.instance.addPostFrameCallback((_) { // ИЗМЕНЕНО: postFrame
                  if (mounted && context.mounted) {
                    if (state.statusCode == 409) {
                      showSimpleErrorDialog(
                          context,
                          localizations?.translate('error') ?? 'Ошибка',
                          state.message,
                        errorDialogEnum: ErrorDialogEnum.clientReturnApprove,
                      );
                      return;
                    }
                    _showSnackBar(state.message, false);
                  }
                });
              }
            } else if (state is ClientReturnCreateSuccess) { // НОВОЕ: Если state есть
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    _showSnackBar(state.message, true);
                    _clientReturnBloc.add(FetchClientReturns(
                      forceRefresh: true,
                      filters: _currentFilters,
                    ));
                  }
                });
              }
            } else if (state is ClientReturnCreateError) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    if (state.statusCode == 409) {
                      showSimpleErrorDialog(
                          context,
                          localizations?.translate('error') ?? 'Ошибка',
                          state.message,
                        errorDialogEnum: ErrorDialogEnum.clientReturnApprove,

                      );
                      return;
                    }
                    _showSnackBar(state.message, false);
                  }
                });
              }
            } else if (state is ClientReturnUpdateSuccess) { // НОВОЕ
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    _showSnackBar(state.message, true);
                    _clientReturnBloc.add(FetchClientReturns(
                        forceRefresh: true, filters: _currentFilters));
                  }
                });
              }
            } else if (state is ClientReturnUpdateError) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    if (state.statusCode == 409) {
                      showSimpleErrorDialog(
                          context,
                          localizations?.translate('error') ?? 'Ошибка',
                          state.message,
                        errorDialogEnum: ErrorDialogEnum.clientReturnApprove,
                      );
                      return;
                    }
                    _showSnackBar(state.message, false);
                  }
                });
              }
            } else if (state is ClientReturnDeleteSuccess) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    _showSnackBar(state.message, true);
                    setState(() {
                      _isRefreshing = true; // НОВОЕ
                    });
                    _clientReturnBloc.add(FetchClientReturns(
                        forceRefresh: true, filters: _currentFilters));
                  }
                });
              }
            } else if (state is ClientReturnDeleteError) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    if (state.statusCode == 409) {
                      showSimpleErrorDialog(
                          context,
                          localizations?.translate('error') ?? 'Ошибка',
                          state.message,
                        errorDialogEnum: ErrorDialogEnum.clientReturnApprove,
                      );
                      _clientReturnBloc.add(FetchClientReturns(
                          forceRefresh: true, filters: _currentFilters));
                      return;
                    }
                    _showSnackBar(state.message, false);
                  }
                });
              }
            } else if (state is ClientReturnRestoreSuccess) {
              debugPrint("ClientReturnScreen.Bloc.State.ClientReturnRestoreSuccess: ${_clientReturnBloc.state}");
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    _showSnackBar(state.message, true);
                    setState(() {
                      _isRefreshing = true;
                    });
                    _clientReturnBloc.add(FetchClientReturns(
                        forceRefresh: true, filters: _currentFilters));
                  }
                });
              }
            } else if (state is ClientReturnRestoreError) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    if (state.statusCode == 409) {
                      showSimpleErrorDialog(
                          context,
                          localizations?.translate('error') ?? 'Ошибка',
                          state.message,
                        errorDialogEnum: ErrorDialogEnum.clientReturnApprove,
                      );
                      _clientReturnBloc.add(FetchClientReturns(
                          forceRefresh: true, filters: _currentFilters));
                      return;
                    }
                    _showSnackBar(state.message, false);
                  }
                });
              }
            } else if (state is ClientReturnApproveMassSuccess) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    showCustomSnackBar(context: context, message: state.message, isSuccess: true);
                    _clientReturnBloc.add(FetchClientReturns(forceRefresh: true, filters: _currentFilters));
                  }
                });
              }
            } else if (state is ClientReturnApproveMassError) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    if (state.statusCode == 409) {
                      showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message);
                      return;
                    }
                    showCustomSnackBar(context: context, message: state.message, isSuccess: false);
                  }
                });
              }
            } else if (state is ClientReturnDisapproveMassSuccess) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    showCustomSnackBar(context: context, message: state.message, isSuccess: true);
                    _clientReturnBloc.add(FetchClientReturns(forceRefresh: true, filters: _currentFilters));
                  }
                });
              }
            } else if (state is ClientReturnDisapproveMassError) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    if (state.statusCode == 409) {
                      showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message);
                      return;
                    }
                    showCustomSnackBar(context: context, message: state.message, isSuccess: false);
                  }
                });
              }
            } else if (state is ClientReturnDeleteMassSuccess) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    showCustomSnackBar(context: context, message: state.message, isSuccess: true);
                    _clientReturnBloc.add(FetchClientReturns(forceRefresh: true, filters: _currentFilters));
                  }
                });
              }
            } else if (state is ClientReturnDeleteMassError) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    if (state.statusCode == 409) {
                      showSimpleErrorDialog(
                          context,
                          localizations?.translate('error') ?? 'Ошибка',
                          state.message);
                      _clientReturnBloc.add(FetchClientReturns(forceRefresh: true, filters: _currentFilters));
                      return;
                    }
                    showCustomSnackBar(context: context, message: state.message, isSuccess: false);
                  }
                });
              }
            } else if (state is ClientReturnRestoreMassSuccess) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    showCustomSnackBar(context: context, message: state.message, isSuccess: true);
                    _clientReturnBloc.add(FetchClientReturns(forceRefresh: true, filters: _currentFilters));
                  }
                });
              }
            } else if (state is ClientReturnRestoreMassError) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    if (state.statusCode == 409) {
                      showSimpleErrorDialog(
                          context,
                          localizations?.translate('error') ?? 'Ошибка',
                          state.message);
                      return;
                    }
                    showCustomSnackBar(context: context, message: state.message, isSuccess: false);
                  }
                });
              }
            }
          },
          child: BlocBuilder<ClientReturnBloc, ClientReturnState>(
            builder: (context, state) {
              if (_isInitialLoad || state is ClientReturnLoading || state is ClientReturnDeleteLoading ||
                  state is ClientReturnRestoreLoading || state is ClientReturnApproveMassLoading ||
                  state is ClientReturnDisapproveMassLoading || state is ClientReturnDeleteMassLoading ||
                  state is ClientReturnRestoreMassLoading || _isRefreshing) {
                return Center(
                  child: PlayStoreImageLoading(
                    size: 80.0,
                    duration: const Duration(milliseconds: 1000),
                  ),
                );
              }

              final List<IncomingDocument> currentData =
                  state is ClientReturnLoaded ? state.data : []; // ИЗМЕНЕНО: List<>

              if (currentData.isEmpty && state is ClientReturnLoaded) {
                return Center(
                  child: Text(
                    _isSearching
                        ? (localizations?.translate('nothing_found') ??
                            'Ничего не найдено')
                        : (localizations?.translate('no_returns') ??
                            'Нет возвратов'),
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
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
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
                          _clientReturnBloc.add(RestoreClientReturnDocument(
                            currentData[index].id!,
                            localizations!,
                          ));
                        } else {
                          // DELETE - для активных документов
                          debugPrint("🗑️ [UI] Удаление документа ID: ${currentData[index].id}");
                          _clientReturnBloc.add(DeleteClientReturnDocument(
                            currentData[index].id!,
                            localizations!,
                            shouldReload: true,
                          ));
                        }
                      },
                      
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ClientReturnCard(
                          document: currentData[index],
                          onTap: () {
                            if (_selectionMode) {
                              _clientReturnBloc.add(SelectClientReturnDocument(currentData[index]));

                              final currentState = context.read<ClientReturnBloc>().state;

                              if (currentState is ClientReturnLoaded) {
                                final selectedCount = currentState.selectedData?.length ?? 0;
                                if (selectedCount <= 1 && currentState.selectedData?.contains(currentData[index]) == true) {
                                  setState(() {
                                    _selectionMode = false;
                                  });
                                }
                              }
                              return;
                            }

                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => BlocProvider.value(
                                  value: _clientReturnBloc,
                                  child: ClientReturnDocumentDetailsScreen(
                                    documentId: currentData[index].id!,
                                    docNumber: currentData[index].docNumber ?? 'N/A',
                                    hasUpdatePermission: _hasUpdatePermission,
                                    hasDeletePermission: _hasDeletePermission,
                                    onDocumentUpdated: () {
                                      _clientReturnBloc.add(FetchClientReturns(
                                        forceRefresh: true,
                                        filters: _currentFilters,
                                      ));
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          isSelectionMode: _selectionMode,
                          isSelected: (state as ClientReturnLoaded).selectedData?.contains(currentData[index]) ?? false,
                          onLongPress: _hasDeletePermission
                              ? () {
                            if (_selectionMode) return;
                            setState(() {
                              _selectionMode = true;
                            });
                            _clientReturnBloc.add(SelectClientReturnDocument(currentData[index]));
                          }
                              : null,
                        ),
                      ),
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ClientReturnCard(
                        document: currentData[index],
                        onTap: () {
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => BlocProvider.value(
                                value: _clientReturnBloc,
                                child: ClientReturnDocumentDetailsScreen(
                                  documentId: currentData[index].id!,
                                  docNumber: currentData[index].docNumber ?? 'N/A',
                                  hasUpdatePermission: _hasUpdatePermission,
                                  hasDeletePermission: _hasDeletePermission,
                                  onDocumentUpdated: () {
                                    _clientReturnBloc.add(FetchClientReturns(
                                      forceRefresh: true,
                                      filters: _currentFilters,
                                    ));
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    ),
    );
  }
}