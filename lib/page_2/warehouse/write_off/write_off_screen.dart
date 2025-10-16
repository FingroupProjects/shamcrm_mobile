import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/write_off/write_off_bloc.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/app_bar_selection_mode.dart';
import 'package:crm_task_manager/page_2/money/widgets/error_dialog.dart';
import 'package:crm_task_manager/page_2/warehouse/write_off/write_off_card.dart';
import 'package:crm_task_manager/page_2/warehouse/write_off/write_off_create.dart';
import 'package:crm_task_manager/page_2/warehouse/write_off/write_off_details.dart';
import 'package:crm_task_manager/page_2/warehouse/client_sale/client_sale_confirm_dialog.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/page_2/incoming_document_model.dart';

class WriteOffScreen extends StatefulWidget {
  const WriteOffScreen({super.key, this.organizationId});

  final int? organizationId;

  @override
  State<WriteOffScreen> createState() => _WriteOffScreenState();
}

class _WriteOffScreenState extends State<WriteOffScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Map<String, dynamic> _currentFilters = {};
  String? _search;
  late WriteOffBloc _writeOffBloc;
  bool _isInitialLoad = true; // НОВОЕ: Как в примере
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;
  bool _selectionMode = false;
  bool _isRefreshing = false; // НОВОЕ: Для consistency

  // НОВОЕ: Флаги прав доступа
  bool _hasCreatePermission = false;
  bool _hasUpdatePermission = false;
  bool _hasDeletePermission = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkPermissions(); // НОВОЕ: Проверка прав
    _writeOffBloc = context.read<WriteOffBloc>()..add(FetchWriteOffs(forceRefresh: true,));
    _scrollController.addListener(_onScroll);
  }

  // НОВОЕ: Проверка прав доступа
  Future<void> _checkPermissions() async {
    try {
      final create = await _apiService.hasPermission('write_off_document.create');
      final update = await _apiService.hasPermission('write_off_document.update');
      final delete = await _apiService.hasPermission('write_off_document.delete');

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

    _writeOffBloc.add(FetchWriteOffs(
      filters: filters,
      forceRefresh: true,
      search: null,
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

    _writeOffBloc.add(const FetchWriteOffs(
      filters: {},
      forceRefresh: true,
      search: null,
    ));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedMax) {
      setState(() {
        _isLoadingMore = true;
      });
      _writeOffBloc.add(FetchWriteOffs(
        forceRefresh: false,
        filters: _currentFilters,
        search: _search,
      ));
    }
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.trim().isNotEmpty;
      _search = query;
    });
    _writeOffBloc.add(FetchWriteOffs(
      forceRefresh: true,
      search: _search,
      filters: _currentFilters,
    ));
  }

  Future<void> _onRefresh() async {
    setState(() {
      _hasReachedMax = false;
      _isSearching = false;
      _searchController.clear();
      _search = null;
    });

    _writeOffBloc.add(FetchWriteOffs(
      forceRefresh: true,
      filters: _currentFilters,
      search: null,
    ));
    await Future.delayed(const Duration(milliseconds: 500));
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Очищаем выбранные элементы при выходе с экрана
          _writeOffBloc.add(UnselectAllDocuments());
        }
      },
      child: BlocProvider.value(
        value: _writeOffBloc,
        child: Scaffold(
          // ИЗМЕНЕНО: FAB только с create-правом
          floatingActionButton: _hasCreatePermission
            ? FloatingActionButton(
                key: const Key('create_write_off_button'),
                onPressed: () async {
                  if (!mounted) return;

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateWriteOffDocumentScreen(
                        organizationId: widget.organizationId,
                      ),
                    ),
                  );

                  if (mounted && result == true) {
                    _writeOffBloc.add(const FetchWriteOffs(forceRefresh: true));
                  }
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
              ? BlocBuilder<WriteOffBloc, WriteOffState>(
                  builder: (context, state) {
                    if (state is WriteOffLoaded) {
                      bool showApprove = state.selectedData!.any((doc) => doc.approved == 0 && doc.deletedAt == null);
                      bool showDisapprove = state.selectedData!.any((doc) => doc.approved == 1 && doc.deletedAt == null);
                      // ИЗМЕНЕНО: showDelete только с delete-правом
                      bool showDelete = _hasDeletePermission &&
                          state.selectedData!.any((doc) => doc.deletedAt == null);
                      bool showRestore = state.selectedData!.any((doc) => doc.deletedAt != null);
                      _isRefreshing = false;

                      return AppBarSelectionMode(
                        title: localizations?.translate('appbar_write_off') ?? 'Списание',
                        onDismiss: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _writeOffBloc.add(UnselectAllDocuments());
                        },
                        onApprove: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _writeOffBloc.add(MassApproveWriteOffDocuments());
                        },
                        onDisapprove: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _writeOffBloc.add(MassDisapproveWriteOffDocuments());
                        },
                        onDelete: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _writeOffBloc.add(MassDeleteWriteOffDocuments());
                        },
                        onRestore: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _writeOffBloc.add(MassRestoreWriteOffDocuments());
                        },
                        showApprove: showApprove,
                        showDelete: showDelete,
                        showDisapprove: showDisapprove,
                        showRestore: showRestore,
                      );
                    }

                    return AppBarSelectionMode(
                      title: localizations?.translate('appbar_write_off') ?? 'Списание',
                      onDismiss: () {
                        setState(() {
                          _selectionMode = false;
                        });
                        _writeOffBloc.add(UnselectAllDocuments());
                      },
                    );
                  },
                )
              : CustomAppBarPage2(
                  title: localizations?.translate('appbar_write_off') ?? 'Списание',
                  showSearchIcon: true,
                  showFilterIcon: false,
                  showFilterOrderIcon: false,
                  showFilterIncomeIcon: false,
                  showFilterIncomingIcon: true,
                  onChangedSearchInput: _onSearch,
                  onFilterIncomingSelected: _onFilterSelected,
                  onIncomingResetFilters: _onResetFilters,
                  textEditingController: _searchController,
                  focusNode: _focusNode,
                  clearButtonClick: (value) {
                    if (!value) {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                        _search = null;
                      });
                      _writeOffBloc.add(FetchWriteOffs(
                        forceRefresh: true,
                        filters: _currentFilters,
                        search: null,
                      ));
                    }
                  },
                  onClickProfileAvatar: () {},
                  clearButtonClickFiltr: (bool p1) {},
                  currentFilters: _currentFilters,
                ),
        ),
        body: BlocListener<WriteOffBloc, WriteOffState>(
          listener: (context, state) {
            debugPrint("WriteOffScreen.Bloc.State: ${_writeOffBloc.state}");

            if (!mounted) return;

            if (state is WriteOffLoaded) {
              if (mounted) {
                setState(() {
                  _hasReachedMax = state.hasReachedMax;
                  _isInitialLoad = false;
                  _isLoadingMore = false;
                  _isRefreshing = false;
                });
              }
            } else if (state is WriteOffError) {
              if (mounted) {
                setState(() {
                  _isInitialLoad = false;
                  _isLoadingMore = false;
                  _isRefreshing = false;
                });

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    if (state.statusCode == 409) {
                      final localizations = AppLocalizations.of(context)!;
                      showSimpleErrorDialog(
                          context,
                          localizations.translate('error'),
                          state.message,
                        errorDialogEnum: ErrorDialogEnum.writeOffApprove,
                      );
                      return;
                    }
                    _showSnackBar(state.message, false);
                  }
                });
              }
            } else if (state is WriteOffCreateSuccess) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    _showSnackBar(state.message, true);
                    _writeOffBloc.add(const FetchWriteOffs(forceRefresh: true));
                  }
                });
              }
            } else if (state is WriteOffCreateError) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    if (state.statusCode == 409) {
                      final localizations = AppLocalizations.of(context)!;
                      showSimpleErrorDialog(
                          context,
                          localizations.translate('error'),
                          state.message,
                      errorDialogEnum: ErrorDialogEnum.writeOffApprove);
                      return;
                    }
                    _showSnackBar(state.message, false);
                  }
                });
              }
            } else if (state is WriteOffUpdateSuccess) { // НОВОЕ: Обработка update
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    _showSnackBar(state.message, true);
                    _writeOffBloc.add(FetchWriteOffs(
                        forceRefresh: true,
                        filters: _currentFilters,
                        search: _search));
                  }
                });
              }
            } else if (state is WriteOffUpdateError) { // НОВОЕ: Обработка update error
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    if (state.statusCode == 409) {
                      final localizations = AppLocalizations.of(context)!;
                      showSimpleErrorDialog(
                          context,
                          localizations.translate('error'),
                          state.message,
                      errorDialogEnum: ErrorDialogEnum.writeOffApprove);
                      return;
                    }
                    _showSnackBar(state.message, false);
                  }
                });
              }
            } else if (state is WriteOffDeleteSuccess) {
              debugPrint("WriteOffScreen.Bloc.State.WriteOffDeleteSuccess: ${_writeOffBloc.state}");
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    _showSnackBar(state.message, true);
                    setState(() {
                      _isRefreshing = true; // ИЗМЕНЕНО: Как в примере
                    });
                    _writeOffBloc.add(FetchWriteOffs(
                        forceRefresh: true,
                        filters: _currentFilters,
                        search: _search));
                  }
                });
              }
            } else if (state is WriteOffDeleteError) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    if (state.statusCode == 409) {
                      showSimpleErrorDialog(
                          context,
                          localizations?.translate('error') ?? 'Ошибка',
                          state.message,
                      errorDialogEnum: ErrorDialogEnum.writeOffDelete);
                      _writeOffBloc.add(FetchWriteOffs(forceRefresh: true, filters: _currentFilters, search: _search));
                      return;
                    }
                    _showSnackBar(state.message, false);
                  }
                });
              }
            } else if (state is WriteOffRestoreSuccess) {
              debugPrint("WriteOffScreen.Bloc.State.WriteOffRestoreSuccess: ${_writeOffBloc.state}");
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    _showSnackBar(state.message, true);
                    setState(() {
                      _isRefreshing = true;
                    });
                    _writeOffBloc.add(FetchWriteOffs(
                        forceRefresh: true,
                        filters: _currentFilters,
                        search: _search));
                  }
                });
              }
            } else if (state is WriteOffRestoreError) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    if (state.statusCode == 409) {
                      showSimpleErrorDialog(
                          context,
                          localizations?.translate('error') ?? 'Ошибка',
                          state.message,
                      errorDialogEnum: ErrorDialogEnum.writeOffRestore);
                      _writeOffBloc.add(FetchWriteOffs(forceRefresh: true, filters: _currentFilters, search: _search));
                      return;
                    }
                    _showSnackBar(state.message, false);
                  }
                });
              }
            } else if (state is WriteOffApproveMassSuccess) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    showCustomSnackBar(
                        context: context,
                        message: state.message,
                        isSuccess: true);
                    _writeOffBloc.add(FetchWriteOffs(
                        forceRefresh: true,
                        filters: _currentFilters,
                        search: _search));
                  }
                });
              }
            } else if (state is WriteOffApproveMassError) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    if (state.statusCode == 409) {
                      showSimpleErrorDialog(
                          context,
                          localizations?.translate('error') ?? 'Ошибка',
                          state.message,
                      errorDialogEnum: ErrorDialogEnum.writeOffApprove);
                      return;
                    }
                    showCustomSnackBar(
                        context: context,
                        message: state.message,
                        isSuccess: false);
                  }
                });
              }
            } else if (state is WriteOffDisapproveMassSuccess) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    showCustomSnackBar(
                        context: context,
                        message: state.message,
                        isSuccess: true);
                    _writeOffBloc.add(FetchWriteOffs(
                        forceRefresh: true,
                        filters: _currentFilters,
                        search: _search));
                  }
                });
              }
            } else if (state is WriteOffDisapproveMassError) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    if (state.statusCode == 409) {
                      showSimpleErrorDialog(
                          context,
                          localizations?.translate('error') ?? 'Ошибка',
                          state.message,
                      errorDialogEnum: ErrorDialogEnum.writeOffUnapprove);
                      return;
                    }
                    showCustomSnackBar(
                        context: context,
                        message: state.message,
                        isSuccess: false);
                  }
                });
              }
            } else if (state is WriteOffDeleteMassSuccess) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    showCustomSnackBar(
                        context: context,
                        message: state.message,
                        isSuccess: true);
                    _writeOffBloc.add(FetchWriteOffs(
                        forceRefresh: true,
                        filters: _currentFilters,
                        search: _search));
                  }
                });
              }
            } else if (state is WriteOffDeleteMassError) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    if (state.statusCode == 409) {
                      showSimpleErrorDialog(
                          context,
                          localizations?.translate('error') ?? 'Ошибка',
                          state.message,
                      errorDialogEnum: ErrorDialogEnum.writeOffDelete);
                      _writeOffBloc.add(FetchWriteOffs(forceRefresh: true, filters: _currentFilters, search: _search));
                      return;
                    }
                    showCustomSnackBar(
                        context: context,
                        message: state.message,
                        isSuccess: false);
                  }
                });
              }
            } else if (state is WriteOffRestoreMassSuccess) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    showCustomSnackBar(
                        context: context,
                        message: state.message,
                        isSuccess: true);
                    _writeOffBloc.add(FetchWriteOffs(
                        forceRefresh: true,
                        filters: _currentFilters,
                        search: _search));
                  }
                });
              }
            } else if (state is WriteOffRestoreMassError) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && context.mounted) {
                    if (state.statusCode == 409) {
                      showSimpleErrorDialog(
                          context,
                          localizations?.translate('error') ?? 'Ошибка',
                          state.message,
                      errorDialogEnum: ErrorDialogEnum.writeOffRestore);
                      return;
                    }
                    showCustomSnackBar(
                        context: context,
                        message: state.message,
                        isSuccess: false);
                  }
                });
              }
            }
          },
          child: BlocBuilder<WriteOffBloc, WriteOffState>(
            builder: (context, state) {
              // ИЗМЕНЕНО: Loading с _isInitialLoad и всеми состояниями загрузки
              if (_isInitialLoad || state is WriteOffLoading || state is WriteOffDeleteLoading ||
                  state is WriteOffRestoreLoading || state is WriteOffCreateLoading ||
                  state is WriteOffApproveMassLoading || state is WriteOffDisapproveMassLoading ||
                  state is WriteOffDeleteMassLoading || state is WriteOffRestoreMassLoading ||
              _isRefreshing) {
                return Center(
                  child: PlayStoreImageLoading(
                    size: 80.0,
                    duration: const Duration(milliseconds: 1000),
                  ),
                );
              }

              final List<IncomingDocument> currentData = state is WriteOffLoaded ? state.data : [];

              if (currentData.isEmpty && state is WriteOffLoaded) {
                return Center(
                  child: Text(
                    _isSearching
                        ? (localizations?.translate('nothing_found') ?? 'Ничего не найдено')
                        : (localizations?.translate('no_write_offs') ?? 'Нет документов списания'),
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
                                _writeOffBloc.add(RestoreWriteOff(
                                  currentData[index].id!,
                                  localizations!,
                                ));
                              } else {
                                // DELETE - для активных документов
                                debugPrint("🗑️ [UI] Удаление документа ID: ${currentData[index].id}");
                                _writeOffBloc.add(DeleteWriteOffDocument(
                                  currentData[index].id!,
                                  localizations!,
                                  shouldReload: true,
                                ));
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: WriteOffCard(
                                document: currentData[index],
                                onTap: () {
                                  if (_selectionMode) {
                                    _writeOffBloc.add(SelectDocument(currentData[index]));

                                    final currentState = context.read<WriteOffBloc>().state;

                                    if (currentState is WriteOffLoaded) {
                                      final selectedCount = currentState.selectedData?.length ?? 0;
                                      if (selectedCount <= 1 &&
                                          currentState.selectedData?.contains(currentData[index]) == true) {
                                        setState(() {
                                          _selectionMode = false;
                                        });
                                      }
                                    }
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (ctx) => BlocProvider.value(
                                        value: _writeOffBloc,
                                        child: WriteOffDocumentDetailsScreen(
                                          documentId: currentData[index].id!,
                                          docNumber: currentData[index].docNumber ?? 'N/A',
                                          // ИЗМЕНЕНО: Передаём права
                                          hasUpdatePermission: _hasUpdatePermission,
                                          hasDeletePermission: _hasDeletePermission,
                                          onDocumentUpdated: () {
                                            _writeOffBloc.add(FetchWriteOffs(
                                              forceRefresh: true,
                                              filters: _currentFilters,
                                              search: _search,
                                            ));
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                isSelectionMode: _selectionMode,
                                isSelected: (state as WriteOffLoaded).selectedData?.contains(currentData[index]) ?? false,
                                // ИЗМЕНЕНО: onLongPress только с delete-правом
                                onLongPress: _hasDeletePermission
                                    ? () {
                                        if (_selectionMode) return;
                                        setState(() {
                                          _selectionMode = true;
                                        });
                                        _writeOffBloc.add(SelectDocument(currentData[index]));
                                      }
                                    : () {},
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: WriteOffCard(
                              document: currentData[index],
                              onTap: () {
                                // ... (тот же onTap без longPress)
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) => BlocProvider.value(
                                      value: _writeOffBloc,
                                      child: WriteOffDocumentDetailsScreen(
                                        documentId: currentData[index].id!,
                                        docNumber: currentData[index].docNumber ?? 'N/A',
                                        hasUpdatePermission: _hasUpdatePermission,
                                        hasDeletePermission: _hasDeletePermission,
                                        onDocumentUpdated: () {
                                          _writeOffBloc.add(FetchWriteOffs(
                                            forceRefresh: true,
                                            filters: _currentFilters,
                                            search: _search,
                                          ));
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                              isSelectionMode: _selectionMode,
                              isSelected: (state as WriteOffLoaded).selectedData?.contains(currentData[index]) ?? false,
                              onLongPress: () {}, // Без delete — ничего
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