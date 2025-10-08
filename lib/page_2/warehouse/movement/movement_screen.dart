import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/movement/movement_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/movement/movement_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/movement/movement_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/warehouse/movement/movement_card.dart';
import 'package:crm_task_manager/page_2/warehouse/movement/movement_create.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../custom_widget/app_bar_selection_mode.dart';
import '../../../models/page_2/incoming_document_model.dart';
import '../../../widgets/snackbar_widget.dart';
import '../../money/widgets/error_dialog.dart';
import 'movement_details.dart';

class MovementScreen extends StatefulWidget {
  const MovementScreen({super.key, this.organizationId});

  final int? organizationId;

  @override
  State<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends State<MovementScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Map<String, dynamic> _currentFilters = {};
  String? _search;
  late MovementBloc _movementBloc;
  bool _isInitialLoad = true;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;
  bool _selectionMode = false;
  bool _isRefreshing = false;

  // НОВОЕ: Флаги прав доступа
  bool _hasCreatePermission = false;
  bool _hasUpdatePermission = false;
  bool _hasDeletePermission = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _movementBloc = context.read<MovementBloc>()..add(const FetchMovements(forceRefresh: true));
    _scrollController.addListener(_onScroll);
  }

  // НОВОЕ: Проверка прав доступа
  Future<void> _checkPermissions() async {
    try {
      final create = await _apiService.hasPermission('movement_document.create');
      final update = await _apiService.hasPermission('movement_document.update');
      final delete = await _apiService.hasPermission('movement_document.delete');

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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFilterSelected(Map<String, dynamic> filters) {
    if (!mounted) return;

    setState(() {
      _currentFilters = Map.from(filters);
      _hasReachedMax = false;
      _isLoadingMore = false;
      _isSearching = false;
      _searchController.clear();
      _search = null;
    });

    _movementBloc.add(FetchMovements(
      forceRefresh: true,
      filters: _currentFilters,
      search: null,
    ));
  }

  void _onResetFilters() {
    if (!mounted) return;

    setState(() {
      _currentFilters.clear();
      _hasReachedMax = false;
      _isLoadingMore = false;
      _isSearching = false;
      _searchController.clear();
      _search = null;
    });

    _movementBloc.add(const FetchMovements(
      forceRefresh: true,
      filters: {},
      search: null,
    ));
  }

  void _onScroll() {
    if (!mounted) return;

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedMax) {
      setState(() {
        _isLoadingMore = true;
      });

      _movementBloc.add(FetchMovements(
        forceRefresh: false,
        filters: _currentFilters,
        search: _search,
      ));
    }
  }

  void _onSearch(String query) {
    if (!mounted) return;

    setState(() {
      _isSearching = query.trim().isNotEmpty;
      _search = query;
    });

    _movementBloc.add(FetchMovements(
      forceRefresh: true,
      filters: _currentFilters,
      search: _search,
    ));
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;

    setState(() {
      _hasReachedMax = false;
      _isSearching = false;
      _searchController.clear();
      _search = null;
    });

    _movementBloc.add(FetchMovements(
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return BlocProvider.value(
      value: _movementBloc,
      child: Scaffold(
        // ИЗМЕНЕНО: Показываем FAB только если есть право на создание
        floatingActionButton: _hasCreatePermission
            ? FloatingActionButton(
                onPressed: () async {
                  if (!mounted) return;

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateMovementDocumentScreen(
                          organizationId: widget.organizationId),
                    ),
                  );

                  if (mounted && result == true) {
                    _movementBloc.add(const FetchMovements(forceRefresh: true));
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
              ? BlocBuilder<MovementBloc, MovementState>(
                  builder: (context, state) {
                    if (state is MovementLoaded) {
                      bool showApprove = state.selectedData!.any(
                          (doc) => doc.approved == 0 && doc.deletedAt == null);
                      bool showDisapprove = state.selectedData!.any(
                          (doc) => doc.approved == 1 && doc.deletedAt == null);
                      // ИЗМЕНЕНО: Показываем кнопку удаления только если есть право
                      bool showDelete = _hasDeletePermission &&
                          state.selectedData!
                              .any((doc) => doc.deletedAt == null);
                      bool showRestore = state.selectedData!
                          .any((doc) => doc.deletedAt != null);
                      _isRefreshing = false;

                      return AppBarSelectionMode(
                        title: localizations?.translate('appbar_movement') ??
                            'Перемещение',
                        onDismiss: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _movementBloc.add(UnselectAllDocuments());
                        },
                        onApprove: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _movementBloc.add(MassApproveMovementDocuments());
                        },
                        onDisapprove: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _movementBloc.add(MassDisapproveMovementDocuments());
                        },
                        onDelete: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _movementBloc.add(MassDeleteMovementDocuments());
                        },
                        onRestore: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _movementBloc.add(MassRestoreMovementDocuments());
                        },
                        showApprove: showApprove,
                        showDelete: showDelete,
                        showDisapprove: showDisapprove,
                        showRestore: showRestore,
                      );
                    }

                    return AppBarSelectionMode(
                      title: localizations?.translate('appbar_movement') ??
                          'Перемещение',
                      onDismiss: () {
                        setState(() {
                          _selectionMode = false;
                        });
                        _movementBloc.add(UnselectAllDocuments());
                      },
                    );
                  },
                )
              : CustomAppBarPage2(
                  title: localizations?.translate('appbar_movement') ??
                      'Перемещение',
                  showSearchIcon: true,
                  showFilterIcon: false,
                  showFilterOrderIcon: false,
                  showFilterIncomeIcon: false,
                  showFilterIncomingIcon: true,
                  onFilterIncomingSelected: _onFilterSelected,
                  onIncomingResetFilters: _onResetFilters,
                  onChangedSearchInput: _onSearch,
                  textEditingController: _searchController,
                  focusNode: _focusNode,
                  clearButtonClick: (value) {
                    if (!mounted) return;

                    if (!value) {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                        _search = null;
                      });
                      _movementBloc.add(FetchMovements(
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
        body: MultiBlocListener(
          listeners: [
            BlocListener<MovementBloc, MovementState>(
              listener: (context, state) {
                if (!mounted) return;

                if (state is MovementLoaded) {
                  if (mounted) {
                    setState(() {
                      _hasReachedMax = state.hasReachedMax;
                      _isInitialLoad = false;
                      _isLoadingMore = false;
                      _isRefreshing = false;
                    });
                  }
                } else if (state is MovementError) {
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
                        _showSnackBar(state.message, false);
                      }
                    });
                  }
                } else if (state is MovementCreateSuccess) {
                  if (mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && context.mounted) {
                        _showSnackBar(state.message, true);
                        _movementBloc
                            .add(const FetchMovements(forceRefresh: true));
                      }
                    });
                  }
                } else if (state is MovementDeleteSuccess) {
                  if (mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && context.mounted) {
                        _showSnackBar(state.message, true);
                        setState(() {
                          _isRefreshing = true;
                        });
                        _movementBloc.add(FetchMovements(
                            forceRefresh: true,
                            filters: _currentFilters,
                            search: _search));
                      }
                    });
                  }
                } else if (state is MovementRestoreSuccess) {
                  if (mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && context.mounted) {
                        _showSnackBar(state.message, true);
                        _movementBloc
                            .add(const FetchMovements(forceRefresh: true));
                      }
                    });
                  }
                } else if (state is MovementApproveMassSuccess) {
                  if (mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && context.mounted) {
                        showCustomSnackBar(
                            context: context,
                            message: state.message,
                            isSuccess: true);
                        _movementBloc.add(FetchMovements(
                            forceRefresh: true,
                            filters: _currentFilters,
                            search: _search));
                      }
                    });
                  }
                } else if (state is MovementApproveMassError) {
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
                } else if (state is MovementDisapproveMassSuccess) {
                  if (mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && context.mounted) {
                        showCustomSnackBar(
                            context: context,
                            message: state.message,
                            isSuccess: true);
                        _movementBloc.add(FetchMovements(
                            forceRefresh: true,
                            filters: _currentFilters,
                            search: _search));
                      }
                    });
                  }
                } else if (state is MovementDisapproveMassError) {
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
                } else if (state is MovementDeleteMassSuccess) {
                  if (mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && context.mounted) {
                        showCustomSnackBar(
                            context: context,
                            message: state.message,
                            isSuccess: true);
                        _movementBloc.add(FetchMovements(
                            forceRefresh: true,
                            filters: _currentFilters,
                            search: _search));
                      }
                    });
                  }
                } else if (state is MovementDeleteMassError) {
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
                } else if (state is MovementRestoreMassSuccess) {
                  if (mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && context.mounted) {
                        showCustomSnackBar(
                            context: context,
                            message: state.message,
                            isSuccess: true);
                        _movementBloc.add(FetchMovements(
                            forceRefresh: true,
                            filters: _currentFilters,
                            search: _search));
                      }
                    });
                  }
                } else if (state is MovementRestoreMassError) {
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
            ),
          ],
          child: BlocBuilder<MovementBloc, MovementState>(
            builder: (context, state) {
              if (state is MovementLoading || state is MovementDeleteLoading) {
                return Center(
                  child: PlayStoreImageLoading(
                    size: 80.0,
                    duration: const Duration(milliseconds: 1000),
                  ),
                );
              }

              final List<IncomingDocument> currentData =
                  state is MovementLoaded ? state.data : [];

              if (currentData.isEmpty && state is MovementLoaded) {
                return Center(
                  child: Text(
                    _isSearching
                        ? (localizations?.translate('nothing_found') ??
                            'Ничего не найдено')
                        : (localizations?.translate('no_movements') ??
                            'Нет документов перемещения'),
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

                    // ИЗМЕНЕНО: Показываем Dismissible только если есть право на удаление
                    return _hasDeletePermission
                        ? Dismissible(
                            key: Key(currentData[index].id.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red,
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
                              child: const Icon(Icons.delete,
                                  color: Colors.white, size: 24),
                            ),
                            confirmDismiss: (direction) async {
                              return currentData[index].deletedAt == null;
                            },
                            onDismissed: (direction) {
                              print(
                                  "🗑️ [UI] Удаление документа ID: ${currentData[index].id}");
                              _movementBloc.add(DeleteMovementDocument(
                                currentData[index].id!,
                                localizations!,
                                shouldReload: true,
                              ));
                            },
                            child: _buildMovementCard(currentData, index, state),
                          )
                        : _buildMovementCard(currentData, index, state);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMovementCard(
      List<IncomingDocument> currentData, int index, MovementState state) {
    return MovementCard(
      document: currentData[index],
      onTap: () {
        if (_selectionMode) {
          _movementBloc.add(SelectDocument(currentData[index]));

          final currentState = context.read<MovementBloc>().state;

          if (currentState is MovementLoaded) {
            final selectedCount = currentState.selectedData?.length ?? 0;
            if (selectedCount <= 1 &&
                currentState.selectedData?.contains(currentData[index]) ==
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
              value: _movementBloc,
              child: MovementDocumentDetailsScreen(
                documentId: currentData[index].id!,
                docNumber: currentData[index].docNumber ?? '',
                hasUpdatePermission: _hasUpdatePermission,
                hasDeletePermission: _hasDeletePermission,
                onDocumentUpdated: () {
                  if (mounted) {
                    _movementBloc.add(FetchMovements(
                        forceRefresh: true,
                        filters: _currentFilters,
                        search: _search));
                  }
                },
              ),
            ),
          ),
        );
      },
      // ИЗМЕНЕНО: Разрешаем долгое нажатие только если есть право на удаление
      onLongPress: _hasDeletePermission
          ? () {
              if (_selectionMode) return;
              setState(() {
                _selectionMode = true;
              });
              _movementBloc.add(SelectDocument(currentData[index]));
            }
          : () {},
      isSelectionMode: _selectionMode,
      isSelected: (state as MovementLoaded)
              .selectedData
              ?.contains(currentData[index]) ??
          false,
      onUpdate: () {
        if (mounted) {
          _movementBloc.add(FetchMovements(
              forceRefresh: true, filters: _currentFilters, search: _search));
        }
      },
    );
  }
}