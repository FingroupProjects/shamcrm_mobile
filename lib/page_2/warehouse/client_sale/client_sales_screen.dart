import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/client_sale/bloc/client_sale_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/warehouse_document_filter_type.dart';
import 'package:crm_task_manager/custom_widget/app_bar_selection_mode.dart';
import 'package:crm_task_manager/page_2/warehouse/client_sale/client_sales_card.dart';
import 'package:crm_task_manager/page_2/warehouse/client_sale/create_clien_sales_document_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/client_sale/widgets/pinned_client_sale_total.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/document_date_period.dart';
import 'package:crm_task_manager/widgets/helpful_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/page_2/expense_document_model.dart';
import '../../../models/page_2/incoming_document_model.dart';
import '../../../widgets/snackbar_widget.dart';
import '../../money/widgets/error_dialog.dart';
import 'clien_sales_document_detail.dart';
import '../../widgets/document_confirm_dialog.dart';

class ClientSaleScreen extends StatefulWidget {
  const ClientSaleScreen({super.key, this.organizationId});

  final int? organizationId;

  @override
  State<ClientSaleScreen> createState() => _ClientSaleScreenState();
}

class _ClientSaleScreenState extends State<ClientSaleScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Map<String, dynamic> _currentFilters = {};
  String? _search;
  late ClientSaleBloc _clientSaleBloc;
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
    _clientSaleBloc = context.read<ClientSaleBloc>()
      ..add(const FetchClientSales(forceRefresh: true));
    _scrollController.addListener(_onScroll);
  }

  // НОВОЕ: Проверка прав доступа
  Future<void> _checkPermissions() async {
    try {
      final create = await _apiService.hasPermission('expense_document.create');
      final update = await _apiService.hasPermission('expense_document.update');
      final delete = await _apiService.hasPermission('expense_document.delete');

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

    _clientSaleBloc.add(FetchClientSales(
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

    _clientSaleBloc.add(const FetchClientSales(
      filters: {},
      forceRefresh: true,
      search: null,
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
      _clientSaleBloc.add(FetchClientSales(
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
    _clientSaleBloc.add(FetchClientSales(
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

    _clientSaleBloc.add(FetchClientSales(
      forceRefresh: true,
      filters: _currentFilters,
      search: null,
    ));
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colors = context.appColors;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Очищаем выбранные элементы при выходе с экрана
          _clientSaleBloc.add(UnselectAllDocuments());
        }
      },
      child: BlocProvider.value(
        value: _clientSaleBloc,
        child: Scaffold(
          // ИЗМЕНЕНО: FAB только с create-правом
          floatingActionButton: _hasCreatePermission
              ? FloatingActionButton(
                  key: const Key('create_client_sale_button'),
                  onPressed: () async {
                    if (!mounted) return;

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: _clientSaleBloc,
                          child: CreateClienSalesDocumentScreen(
                              organizationId: widget.organizationId),
                        ),
                      ),
                    );

                    if (mounted && result == true) {
                      _clientSaleBloc
                          .add(const FetchClientSales(forceRefresh: true));
                    }
                  },
                  backgroundColor: const Color(0xff1E2E52),
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
          backgroundColor: colors.surfacePrimary,
          appBar: AppBar(
            backgroundColor: colors.surfacePrimary,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            automaticallyImplyLeading: !_selectionMode,
            forceMaterialTransparency: false,
            title: _selectionMode
                ? BlocBuilder<ClientSaleBloc, ClientSaleState>(
                    builder: (context, state) {
                      if (state is ClientSaleLoaded) {
                        bool showApprove = state.selectedData!.any((doc) =>
                            doc.approved == 0 && doc.deletedAt == null);
                        bool showDisapprove = state.selectedData!.any((doc) =>
                            doc.approved == 1 && doc.deletedAt == null);
                        // ИЗМЕНЕНО: showDelete только с delete-правом
                        bool showDelete = _hasDeletePermission &&
                            state.selectedData!
                                .any((doc) => doc.deletedAt == null);
                        bool showRestore = state.selectedData!
                            .any((doc) => doc.deletedAt != null);
                        _isRefreshing = false;

                        return AppBarSelectionMode(
                          title:
                              localizations?.translate('appbar_client_sales') ??
                                  'Реализация клиент',
                          onDismiss: () {
                            setState(() {
                              _selectionMode = false;
                            });
                            _clientSaleBloc.add(UnselectAllDocuments());
                          },
                          onApprove: () {
                            setState(() {
                              _selectionMode = false;
                            });
                            _clientSaleBloc
                                .add(MassApproveClientSaleDocuments());
                          },
                          onDisapprove: () {
                            setState(() {
                              _selectionMode = false;
                            });
                            _clientSaleBloc
                                .add(MassDisapproveClientSaleDocuments());
                          },
                          onDelete: () {
                            setState(() {
                              _selectionMode = false;
                            });
                            _clientSaleBloc
                                .add(MassDeleteClientSaleDocuments());
                          },
                          onRestore: () {
                            setState(() {
                              _selectionMode = false;
                            });
                            _clientSaleBloc
                                .add(MassRestoreClientSaleDocuments());
                          },
                          showApprove: showApprove,
                          showDelete: showDelete,
                          showDisapprove: showDisapprove,
                          showRestore: showRestore,
                        );
                      }

                      return AppBarSelectionMode(
                        title:
                            localizations?.translate('appbar_client_sales') ??
                                'Реализация клиент',
                        onDismiss: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _clientSaleBloc.add(UnselectAllDocuments());
                        },
                      );
                    },
                  )
                : CustomAppBarPage2(
                    title: localizations?.translate('appbar_client_sales') ??
                        'Продажа',
                    showSearchIcon: true,
                    showFilterIcon: false,
                    showFilterOrderIcon: false,
                    showFilterIncomeIcon: false,
                    showFilterIncomingIcon: true,
                    warehouseFilterType: WarehouseDocumentFilterType.clientSale,
                    onIncomingResetFilters: _onResetFilters,
                    onFilterIncomingSelected: _onFilterSelected,
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
                        _clientSaleBloc.add(FetchClientSales(
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
          body: BlocListener<ClientSaleBloc, ClientSaleState>(
            listener: (context, state) {
              debugPrint(
                  "ClientSaleScreen.Bloc.State: ${_clientSaleBloc.state}");

              if (!mounted) return;

              if (state is ClientSaleLoaded) {
                if (mounted) {
                  setState(() {
                    _hasReachedMax = state.hasReachedMax;
                    _isInitialLoad = false;
                    _isLoadingMore = false;
                    _isRefreshing = false;
                  });
                }
              } else if (state is ClientSaleError) {
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
                            localizations.translate('error') ?? 'Ошибка',
                            state.message);
                        return;
                      }
                      debugPrint("ClientSaleScreen.Error: ${state.message}");
                      showCustomSnackBar(
                          context: context,
                          message: state.message,
                          isSuccess: false);
                    }
                  });
                }
              } else if (state is ClientSaleCreateSuccess) {
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && context.mounted) {
                      showCustomSnackBar(
                          context: context,
                          message: state.message,
                          isSuccess: true);
                      _clientSaleBloc
                          .add(const FetchClientSales(forceRefresh: true));
                    }
                  });
                }
              } else if (state is ClientSaleCreateError) {
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && context.mounted) {
                      if (state.statusCode == 409) {
                        // ✅ ИСПРАВЛЕНО: Обновляем данные после ошибки, чтобы избежать белого экрана
                        _clientSaleBloc.add(FetchClientSales(
                            forceRefresh: true,
                            filters: _currentFilters,
                            search: _search));
                        final localizations = AppLocalizations.of(context)!;
                        showSimpleErrorDialog(
                            context,
                            localizations.translate('error') ?? 'Ошибка',
                            state.message);
                        return;
                      }
                      showCustomSnackBar(
                          context: context,
                          message: state.message,
                          isSuccess: false);
                    }
                  });
                }
              } else if (state is ClientSaleUpdateSuccess) {
                // ИЗМЕНЕНО: С addPostFrameCallback
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && context.mounted) {
                      showCustomSnackBar(
                          context: context,
                          message: state.message,
                          isSuccess: true);
                      _clientSaleBloc.add(FetchClientSales(
                          forceRefresh: true,
                          filters: _currentFilters,
                          search: _search));
                    }
                  });
                }
              } else if (state is ClientSaleUpdateError) {
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && context.mounted) {
                      if (state.statusCode == 409) {
                        // ✅ ИСПРАВЛЕНО: Обновляем данные после ошибки, чтобы избежать белого экрана
                        _clientSaleBloc.add(FetchClientSales(
                            forceRefresh: true,
                            filters: _currentFilters,
                            search: _search));
                        final localizations = AppLocalizations.of(context)!;
                        showSimpleErrorDialog(
                            context,
                            localizations.translate('error') ?? 'Ошибка',
                            state.message);
                        return;
                      }
                      showCustomSnackBar(
                          context: context,
                          message: state.message,
                          isSuccess: false);
                    }
                  });
                }
              } else if (state is ClientSaleApproveMassSuccess) {
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && context.mounted) {
                      showCustomSnackBar(
                          context: context,
                          message: state.message,
                          isSuccess: true);
                      _clientSaleBloc.add(FetchClientSales(
                          forceRefresh: true,
                          filters: _currentFilters,
                          search: _search));
                    }
                  });
                }
              } else if (state is ClientSaleApproveMassError) {
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
                      showCustomSnackBar(
                          context: context,
                          message: state.message,
                          isSuccess: false);
                    }
                  });
                }
              } else if (state is ClientSaleDisapproveMassSuccess) {
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && context.mounted) {
                      showCustomSnackBar(
                          context: context,
                          message: state.message,
                          isSuccess: true);
                      _clientSaleBloc.add(FetchClientSales(
                          forceRefresh: true,
                          filters: _currentFilters,
                          search: _search));
                    }
                  });
                }
              } else if (state is ClientSaleDisapproveMassError) {
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
                      showCustomSnackBar(
                          context: context,
                          message: state.message,
                          isSuccess: false);
                    }
                  });
                }
              } else if (state is ClientSaleDeleteSuccess) {
                debugPrint(
                    "ClientSaleScreen.Bloc.State.ClientSaleDeleteSuccess: ${_clientSaleBloc.state}");
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && context.mounted) {
                      showCustomSnackBar(
                          context: context,
                          message: state.message,
                          isSuccess: true);
                      setState(() {
                        _isRefreshing = true; // ИЗМЕНЕНО: Как в примере
                      });
                      _clientSaleBloc.add(FetchClientSales(
                          forceRefresh: true,
                          filters: _currentFilters,
                          search: _search));
                    }
                  });
                }
              } else if (state is ClientSaleDeleteError) {
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && context.mounted) {
                      if (state.statusCode == 409) {
                        showSimpleErrorDialog(
                            context,
                            localizations?.translate('error') ?? 'Ошибка',
                            state.message);
                        _clientSaleBloc.add(FetchClientSales(
                            forceRefresh: true,
                            filters: _currentFilters,
                            search: _search));
                        return;
                      }
                      showCustomSnackBar(
                          context: context,
                          message: state.message,
                          isSuccess: false);
                    }
                  });
                }
              } else if (state is ClientSaleRestoreSuccess) {
                debugPrint(
                    "ClientSaleScreen.Bloc.State.ClientSaleRestoreSuccess: ${_clientSaleBloc.state}");
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && context.mounted) {
                      showCustomSnackBar(
                          context: context,
                          message: state.message,
                          isSuccess: true);
                      setState(() {
                        _isRefreshing = true; // ИЗМЕНЕНО: Как в примере
                      });
                      _clientSaleBloc.add(FetchClientSales(
                          forceRefresh: true,
                          filters: _currentFilters,
                          search: _search));
                    }
                  });
                }
              } else if (state is ClientSaleRestoreError) {
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && context.mounted) {
                      if (state.statusCode == 409) {
                        showSimpleErrorDialog(
                            context,
                            localizations?.translate('error') ?? 'Ошибка',
                            state.message);
                        _clientSaleBloc.add(FetchClientSales(
                            forceRefresh: true,
                            filters: _currentFilters,
                            search: _search));
                        return;
                      }
                      showCustomSnackBar(
                          context: context,
                          message: state.message,
                          isSuccess: false);
                    }
                  });
                }
              } else if (state is ClientSaleDeleteMassSuccess) {
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && context.mounted) {
                      showCustomSnackBar(
                          context: context,
                          message: state.message,
                          isSuccess: true);
                      _clientSaleBloc.add(FetchClientSales(
                          forceRefresh: true,
                          filters: _currentFilters,
                          search: _search));
                    }
                  });
                }
              } else if (state is ClientSaleDeleteMassError) {
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && context.mounted) {
                      if (state.statusCode == 409) {
                        showSimpleErrorDialog(
                            context,
                            localizations?.translate('error') ?? 'Ошибка',
                            state.message);
                        _clientSaleBloc.add(FetchClientSales(
                            forceRefresh: true,
                            filters: _currentFilters,
                            search: _search));
                        return;
                      }
                      showCustomSnackBar(
                          context: context,
                          message: state.message,
                          isSuccess: false);
                    }
                  });
                }
              } else if (state is ClientSaleRestoreMassSuccess) {
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && context.mounted) {
                      showCustomSnackBar(
                          context: context,
                          message: state.message,
                          isSuccess: true);
                      _clientSaleBloc.add(FetchClientSales(
                          forceRefresh: true,
                          filters: _currentFilters,
                          search: _search));
                    }
                  });
                }
              } else if (state is ClientSaleRestoreMassError) {
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
                      showCustomSnackBar(
                          context: context,
                          message: state.message,
                          isSuccess: false);
                    }
                  });
                }
              }
            },
            child: BlocBuilder<ClientSaleBloc, ClientSaleState>(
              builder: (context, state) {
                debugPrint(
                    "ClientSaleScreen.Bloc.State.Build: ${_clientSaleBloc.state}");

                // ИЗМЕНЕНО: Loading с _isInitialLoad
                if (_isInitialLoad ||
                    state is ClientSaleLoading ||
                    state is ClientSaleDeleteLoading ||
                    state is ClientSaleRestoreLoading ||
                    state is ClientSaleCreateLoading ||
                    state is ClientSaleApproveMassLoading ||
                    state is ClientSaleDisapproveMassLoading ||
                    state is ClientSaleDeleteMassLoading ||
                    state is ClientSaleRestoreMassLoading ||
                    _isRefreshing) {
                  return Center(
                    child: PlayStoreImageLoading(
                      size: 80.0,
                      duration: const Duration(milliseconds: 1000),
                    ),
                  );
                }

                final List<ExpenseDocument> currentData =
                    state is ClientSaleLoaded ? state.data : [];
                final ClientSaleLoaded? loadedState =
                    state is ClientSaleLoaded ? state : null;

                if (currentData.isEmpty && state is ClientSaleLoaded) {
                  return Column(
                    children: [
                      PinnedClientSaleTotal(
                        period: loadedState?.datePeriod ??
                            DocumentDatePeriod.today,
                        total: loadedState?.totalSum,
                      ),
                      Expanded(
                        child: _isSearching
                            ? HelpfulEmptyState.search(localizations!)
                            : HelpfulEmptyState.section(
                                l10n: localizations!,
                                icon: Icons.point_of_sale_rounded,
                                titleKey: 'empty_client_sale_title',
                                subtitleKey: 'empty_client_sale_subtitle',
                              ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    PinnedClientSaleTotal(
                      period:
                          loadedState?.datePeriod ?? DocumentDatePeriod.today,
                      total: loadedState?.totalSum,
                    ),
                    Expanded(
                      child: RefreshIndicator(
                  color: const Color(0xff1E2E52),
                  backgroundColor: Colors.white,
                  onRefresh: _onRefresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
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
                                    duration:
                                        const Duration(milliseconds: 1000),
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: currentData[index].deletedAt == null
                                      ? Colors.red
                                      : const Color(0xFF2196F3),
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
                                final isDeleted =
                                    currentData[index].deletedAt != null;
                                final docNumber =
                                    currentData[index].docNumber ?? 'N/A';

                                if (isDeleted) {
                                  return await DocumentConfirmDialog
                                      .showRestoreConfirmation(
                                    context,
                                    docNumber,
                                  );
                                } else {
                                  return await DocumentConfirmDialog
                                      .showDeleteConfirmation(
                                    context,
                                    docNumber,
                                  );
                                }
                              },
                              onDismissed: (direction) {
                                final isDeleted =
                                    currentData[index].deletedAt != null;

                                if (isDeleted) {
                                  // RESTORE - для удалённых документов
                                  debugPrint(
                                      "♻️ [UI] Восстановление документа ID: ${currentData[index].id}");
                                  _clientSaleBloc.add(RestoreClientSale(
                                    currentData[index].id!,
                                    localizations!,
                                  ));
                                } else {
                                  // DELETE - для активных документов
                                  debugPrint(
                                      "🗑️ [UI] Удаление документа ID: ${currentData[index].id}");
                                  _clientSaleBloc.add(DeleteClientSale(
                                    currentData[index].id!,
                                    localizations!,
                                    shouldReload: true,
                                  ));
                                }
                              },

                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: ClientSalesCard(
                                  document: currentData[index],
                                  onTap: () {
                                    if (_selectionMode) {
                                      _clientSaleBloc.add(
                                          SelectDocument(currentData[index]));

                                      final currentState =
                                          context.read<ClientSaleBloc>().state;

                                      if (currentState is ClientSaleLoaded) {
                                        final selectedCount =
                                            currentState.selectedData?.length ??
                                                0;
                                        if (selectedCount <= 1 &&
                                            currentState.selectedData?.contains(
                                                    currentData[index]) ==
                                                true) {
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
                                          value: _clientSaleBloc,
                                          child:
                                              ClientSalesDocumentDetailsScreen(
                                            documentId: currentData[index].id!,
                                            docNumber:
                                                currentData[index].docNumber ??
                                                    'N/A',
                                            hasUpdatePermission:
                                                _hasUpdatePermission,
                                            hasDeletePermission:
                                                _hasDeletePermission,
                                            onDocumentUpdated: () {
                                              _clientSaleBloc
                                                  .add(FetchClientSales(
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
                                  isSelected: (state as ClientSaleLoaded)
                                          .selectedData
                                          ?.contains(currentData[index]) ??
                                      false,
                                  onLongPress: _hasDeletePermission
                                      ? () {
                                          if (_selectionMode) return;
                                          setState(() {
                                            _selectionMode = true;
                                          });
                                          _clientSaleBloc.add(SelectDocument(
                                              currentData[index]));
                                        }
                                      : () {},
                                ),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ClientSalesCard(
                                document: currentData[index],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (ctx) =>
                                          ClientSalesDocumentDetailsScreen(
                                        documentId: currentData[index].id!,
                                        docNumber:
                                            currentData[index].docNumber ??
                                                'N/A',
                                        hasUpdatePermission:
                                            _hasUpdatePermission,
                                        hasDeletePermission:
                                            _hasDeletePermission,
                                        onDocumentUpdated: () {
                                          _clientSaleBloc.add(FetchClientSales(
                                            forceRefresh: true,
                                            filters: _currentFilters,
                                            search: _search,
                                          ));
                                        },
                                      ),
                                    ),
                                  );
                                },
                                isSelectionMode: _selectionMode,
                                isSelected: (state as ClientSaleLoaded)
                                        .selectedData
                                        ?.contains(currentData[index]) ??
                                    false,
                                onLongPress: () {},
                              ),
                            );
                    },
                  ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
