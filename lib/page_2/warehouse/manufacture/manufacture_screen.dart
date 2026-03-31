import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/manufacture/manufacture_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/manufacture/manufacture_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/manufacture/manufacture_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/warehouse/manufacture/manufacture_card.dart';
import 'package:crm_task_manager/page_2/warehouse/manufacture/manufacture_create.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../custom_widget/app_bar_selection_mode.dart';
import '../../../models/page_2/incoming_document_model.dart';
import '../../../widgets/snackbar_widget.dart';
import '../../money/widgets/error_dialog.dart';
import 'manufacture_details.dart';
import 'package:crm_task_manager/page_2/widgets/document_confirm_dialog.dart';

class ManufactureScreen extends StatefulWidget {
  const ManufactureScreen({super.key, this.organizationId});

  final int? organizationId;

  @override
  State<ManufactureScreen> createState() => _ManufactureScreenState();
}

class _ManufactureScreenState extends State<ManufactureScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Map<String, dynamic> _currentFilters = {};
  String? _search;
  late ManufactureBloc _manufactureBloc;
  bool _isInitialLoad = true;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;
  bool _selectionMode = false;
  bool _isRefreshing = false;

  // НОВОЕ: Флаги прав доступа
  bool _hasCreatePermission = false;
  bool _hasUpdatePermission = false;
  bool _hasDeletePermission = false;
  bool _hasApprovePermission = false;
  bool _hasUnapprovePermission = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _manufactureBloc = context.read<ManufactureBloc>()
      ..add(const FetchManufactures(forceRefresh: true));
    _scrollController.addListener(_onScroll);
  }

  // НОВОЕ: Проверка прав доступа
  Future<void> _checkPermissions() async {
    try {
      final create = await _apiService.hasPermission('manufacture.create') ||
          await _apiService.hasPermission('manufacture_document.create');
      final update = await _apiService.hasPermission('manufacture.update') ||
          await _apiService.hasPermission('manufacture_document.update');
      final delete = await _apiService.hasPermission('manufacture.delete') ||
          await _apiService.hasPermission('manufacture_document.delete');
      final approve = await _apiService.hasPermission('manufacture.approve') ||
          await _apiService.hasPermission('manufacture_document.approve');
      final unapprove =
          await _apiService.hasPermission('manufacture.unapprove');

      if (mounted) {
        setState(() {
          _hasCreatePermission = create;
          _hasUpdatePermission = update;
          _hasDeletePermission = delete;
          _hasApprovePermission = approve;
          _hasUnapprovePermission = unapprove;
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

    _manufactureBloc.add(FetchManufactures(
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

    _manufactureBloc.add(const FetchManufactures(
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

      _manufactureBloc.add(FetchManufactures(
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

    _manufactureBloc.add(FetchManufactures(
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

    _manufactureBloc.add(FetchManufactures(
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

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Очищаем выбранные элементы при выходе с экрана
          _manufactureBloc.add(UnselectAllDocuments());
        }
      },
      child: BlocProvider.value(
        value: _manufactureBloc,
        child: Scaffold(
          // ИЗМЕНЕНО: Показываем FAB только если есть право на создание
          floatingActionButton: _hasCreatePermission
              ? FloatingActionButton(
                  onPressed: () async {
                    if (!mounted) return;

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateManufactureDocumentScreen(
                            organizationId: widget.organizationId),
                      ),
                    );

                    if (mounted && result == true) {
                      _manufactureBloc
                          .add(const FetchManufactures(forceRefresh: true));
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
                ? BlocBuilder<ManufactureBloc, ManufactureState>(
                    builder: (context, state) {
                      if (state is ManufactureLoaded) {
                        bool showApprove = _hasApprovePermission &&
                            state.selectedData!.any((doc) =>
                                doc.approved == 0 && doc.deletedAt == null);
                        bool showDisapprove = _hasUnapprovePermission &&
                            state.selectedData!.any((doc) =>
                                doc.approved == 1 && doc.deletedAt == null);
                        // ИЗМЕНЕНО: Показываем кнопку удаления только если есть право
                        bool showDelete = _hasDeletePermission &&
                            state.selectedData!
                                .any((doc) => doc.deletedAt == null);
                        bool showRestore = state.selectedData!
                            .any((doc) => doc.deletedAt != null);
                        _isRefreshing = false;

                        return AppBarSelectionMode(
                          title:
                              localizations?.translate('appbar_manufacture') ??
                                  'Перемещение',
                          onDismiss: () {
                            setState(() {
                              _selectionMode = false;
                            });
                            _manufactureBloc.add(UnselectAllDocuments());
                          },
                          onApprove: () {
                            setState(() {
                              _selectionMode = false;
                            });
                            _manufactureBloc
                                .add(MassApproveManufactureDocuments());
                          },
                          onDisapprove: () {
                            setState(() {
                              _selectionMode = false;
                            });
                            _manufactureBloc
                                .add(MassDisapproveManufactureDocuments());
                          },
                          onDelete: () {
                            setState(() {
                              _selectionMode = false;
                            });
                            _manufactureBloc
                                .add(MassDeleteManufactureDocuments());
                          },
                          onRestore: () {
                            setState(() {
                              _selectionMode = false;
                            });
                            _manufactureBloc
                                .add(MassRestoreManufactureDocuments());
                          },
                          showApprove: showApprove,
                          showDelete: showDelete,
                          showDisapprove: showDisapprove,
                          showRestore: showRestore,
                        );
                      }

                      return AppBarSelectionMode(
                        title: localizations?.translate('appbar_manufacture') ??
                            'Перемещение',
                        onDismiss: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _manufactureBloc.add(UnselectAllDocuments());
                        },
                      );
                    },
                  )
                : CustomAppBarPage2(
                    title: localizations?.translate('appbar_manufacture') ??
                        'Перемещение',
                    showSearchIcon: true,
                    showFilterIcon: false,
                    showFilterOrderIcon: false,
                    showFilterIncomeIcon: false,
                    showFilterIncomingIcon: false,
                    showFilterManufactureIcon: true,
                    onFilterManufactureSelected: _onFilterSelected,
                    onManufactureResetFilters: _onResetFilters,
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
                        _manufactureBloc.add(FetchManufactures(
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
              BlocListener<ManufactureBloc, ManufactureState>(
                listener: (context, state) {
                  if (!mounted) return;

                  if (state is ManufactureLoaded) {
                    if (mounted) {
                      setState(() {
                        _hasReachedMax = state.hasReachedMax;
                        _isInitialLoad = false;
                        _isLoadingMore = false;
                        _isRefreshing = false;
                      });
                    }
                  } else if (state is ManufactureError) {
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
                              state.message,
                              errorDialogEnum:
                                  ErrorDialogEnum.goodsMovementDelete,
                            );
                            return;
                          }
                          _showSnackBar(state.message, false);
                        }
                      });
                    }
                  } else if (state is ManufactureCreateSuccess) {
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && context.mounted) {
                          showCustomSnackBar(
                              context: context,
                              message: state.message,
                              isSuccess: true);
                          _manufactureBloc
                              .add(const FetchManufactures(forceRefresh: true));
                        }
                      });
                    }
                  } else if (state is ManufactureCreateError) {
                    if (mounted) {
                      // ✅ ИСПРАВЛЕНО: Обновляем данные после ошибки, чтобы избежать белого экрана
                      _manufactureBloc.add(FetchManufactures(
                          forceRefresh: true,
                          filters: _currentFilters,
                          search: _search));
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && context.mounted) {
                          if (state.statusCode == 409) {
                            showSimpleErrorDialog(
                              context,
                              localizations?.translate('error') ?? 'Ошибка',
                              state.message,
                              errorDialogEnum:
                                  ErrorDialogEnum.goodsMovementUpdate,
                            );
                            return;
                          }
                          showCustomSnackBar(
                              context: context,
                              message: state.message,
                              isSuccess: false);
                        }
                      });
                    }
                  } else if (state is ManufactureUpdateSuccess) {
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && context.mounted) {
                          showCustomSnackBar(
                              context: context,
                              message: state.message,
                              isSuccess: true);
                          _manufactureBloc.add(FetchManufactures(
                              forceRefresh: true,
                              filters: _currentFilters,
                              search: _search));
                        }
                      });
                    }
                  } else if (state is ManufactureUpdateError) {
                    if (mounted) {
                      // ✅ ИСПРАВЛЕНО: Обновляем данные после ошибки, чтобы избежать белого экрана
                      _manufactureBloc.add(FetchManufactures(
                          forceRefresh: true,
                          filters: _currentFilters,
                          search: _search));
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && context.mounted) {
                          if (state.statusCode == 409) {
                            showSimpleErrorDialog(
                                context,
                                localizations?.translate('error') ?? 'Ошибка',
                                state.message,
                                errorDialogEnum:
                                    ErrorDialogEnum.goodsMovementUpdate);
                            return;
                          }
                          showCustomSnackBar(
                              context: context,
                              message: state.message,
                              isSuccess: false);
                        }
                      });
                    }
                  } else if (state is ManufactureDeleteSuccess) {
                    debugPrint(
                        "ManufactureScreen.Bloc.State.ManufactureDeleteSuccess: ${_manufactureBloc.state}");
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && context.mounted) {
                          showCustomSnackBar(
                              context: context,
                              message: state.message,
                              isSuccess: true);
                          setState(() {
                            _isRefreshing = true;
                          });
                          _manufactureBloc.add(FetchManufactures(
                              forceRefresh: true,
                              filters: _currentFilters,
                              search: _search));
                        }
                      });
                    }
                  } else if (state is ManufactureDeleteError) {
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && context.mounted) {
                          if (state.statusCode == 409) {
                            showSimpleErrorDialog(
                                context,
                                localizations?.translate('error') ?? 'Ошибка',
                                state.message,
                                errorDialogEnum:
                                    ErrorDialogEnum.goodsMovementDelete);
                            _manufactureBloc.add(FetchManufactures(
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
                  } else if (state is ManufactureRestoreSuccess) {
                    debugPrint(
                        "ManufactureScreen.Bloc.State.ManufactureRestoreSuccess: ${_manufactureBloc.state}");
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && context.mounted) {
                          showCustomSnackBar(
                              context: context,
                              message: state.message,
                              isSuccess: true);
                          setState(() {
                            _isRefreshing = true;
                          });
                          _manufactureBloc.add(FetchManufactures(
                              forceRefresh: true,
                              filters: _currentFilters,
                              search: _search));
                        }
                      });
                    }
                  } else if (state is ManufactureRestoreError) {
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && context.mounted) {
                          if (state.statusCode == 409) {
                            showSimpleErrorDialog(
                                context,
                                localizations?.translate('error') ?? 'Ошибка',
                                state.message,
                                errorDialogEnum:
                                    ErrorDialogEnum.goodsMovementRestore);
                            _manufactureBloc.add(FetchManufactures(
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
                  } else if (state is ManufactureApproveMassSuccess) {
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && context.mounted) {
                          showCustomSnackBar(
                              context: context,
                              message: state.message,
                              isSuccess: true);
                          _manufactureBloc.add(FetchManufactures(
                              forceRefresh: true,
                              filters: _currentFilters,
                              search: _search));
                        }
                      });
                    }
                  } else if (state is ManufactureApproveMassError) {
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && context.mounted) {
                          if (state.statusCode == 409) {
                            showSimpleErrorDialog(
                                context,
                                localizations?.translate('error') ?? 'Ошибка',
                                state.message,
                                errorDialogEnum:
                                    ErrorDialogEnum.goodsMovementApprove);
                            return;
                          }
                          showCustomSnackBar(
                              context: context,
                              message: state.message,
                              isSuccess: false);
                        }
                      });
                    }
                  } else if (state is ManufactureDisapproveMassSuccess) {
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && context.mounted) {
                          showCustomSnackBar(
                              context: context,
                              message: state.message,
                              isSuccess: true);
                          _manufactureBloc.add(FetchManufactures(
                              forceRefresh: true,
                              filters: _currentFilters,
                              search: _search));
                        }
                      });
                    }
                  } else if (state is ManufactureDisapproveMassError) {
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && context.mounted) {
                          if (state.statusCode == 409) {
                            showSimpleErrorDialog(
                                context,
                                localizations?.translate('error') ?? 'Ошибка',
                                state.message,
                                errorDialogEnum:
                                    ErrorDialogEnum.goodsMovementUnapprove);
                            return;
                          }
                          showCustomSnackBar(
                              context: context,
                              message: state.message,
                              isSuccess: false);
                        }
                      });
                    }
                  } else if (state is ManufactureDeleteMassSuccess) {
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && context.mounted) {
                          showCustomSnackBar(
                              context: context,
                              message: state.message,
                              isSuccess: true);
                          _manufactureBloc.add(FetchManufactures(
                              forceRefresh: true,
                              filters: _currentFilters,
                              search: _search));
                        }
                      });
                    }
                  } else if (state is ManufactureDeleteMassError) {
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && context.mounted) {
                          if (state.statusCode == 409) {
                            showSimpleErrorDialog(
                                context,
                                localizations?.translate('error') ?? 'Ошибка',
                                state.message,
                                errorDialogEnum:
                                    ErrorDialogEnum.goodsMovementDelete);
                            return;
                          }
                          showCustomSnackBar(
                              context: context,
                              message: state.message,
                              isSuccess: false);
                        }
                      });
                    }
                  } else if (state is ManufactureRestoreMassSuccess) {
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && context.mounted) {
                          showCustomSnackBar(
                              context: context,
                              message: state.message,
                              isSuccess: true);
                          _manufactureBloc.add(FetchManufactures(
                              forceRefresh: true,
                              filters: _currentFilters,
                              search: _search));
                        }
                      });
                    }
                  } else if (state is ManufactureRestoreMassError) {
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && context.mounted) {
                          if (state.statusCode == 409) {
                            showSimpleErrorDialog(
                                context,
                                localizations?.translate('error') ?? 'Ошибка',
                                state.message,
                                errorDialogEnum:
                                    ErrorDialogEnum.goodsMovementRestore);
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
            child: BlocBuilder<ManufactureBloc, ManufactureState>(
              builder: (context, state) {
                debugPrint(
                    "ManufactureScreen.Bloc.State.Build: ${_manufactureBloc.state}");

                // ИЗМЕНЕНО: Loading з _isInitialLoad
                if (_isInitialLoad ||
                    state is ManufactureLoading ||
                    state is ManufactureDeleteLoading ||
                    state is ManufactureRestoreLoading ||
                    state is ManufactureCreateLoading ||
                    state is ManufactureApproveMassLoading ||
                    state is ManufactureDisapproveMassLoading ||
                    state is ManufactureDeleteMassLoading ||
                    state is ManufactureRestoreMassLoading ||
                    _isRefreshing) {
                  return Center(
                    child: PlayStoreImageLoading(
                      size: 80.0,
                      duration: const Duration(milliseconds: 1000),
                    ),
                  );
                }

                final List<IncomingDocument> currentData =
                    state is ManufactureLoaded ? state.data : [];

                if (currentData.isEmpty && state is ManufactureLoaded) {
                  return Center(
                    child: Text(
                      _isSearching
                          ? (localizations?.translate('nothing_found') ??
                              'Ничего не найдено')
                          : (localizations?.translate('no_manufactures') ??
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

                      // НОВОЕ: Dismissible только влево - delete або restore в зависимости от состояния
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
                                  _manufactureBloc
                                      .add(RestoreManufactureDocument(
                                    currentData[index].id!,
                                    localizations!,
                                  ));
                                } else {
                                  // DELETE - для активных документов
                                  debugPrint(
                                      "🗑️ [UI] Удаление документа ID: ${currentData[index].id}");
                                  _manufactureBloc
                                      .add(DeleteManufactureDocument(
                                    currentData[index].id!,
                                    localizations!,
                                    shouldReload: true,
                                  ));
                                }
                              },

                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildManufactureCard(
                                    currentData, index, state),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildManufactureCard(
                                  currentData, index, state),
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

  Widget _buildManufactureCard(
      List<IncomingDocument> currentData, int index, ManufactureState state) {
    return ManufactureCard(
      document: currentData[index],
      onTap: () {
        if (_selectionMode) {
          _manufactureBloc.add(SelectDocument(currentData[index]));

          final currentState = context.read<ManufactureBloc>().state;

          if (currentState is ManufactureLoaded) {
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
              value: _manufactureBloc,
              child: ManufactureDocumentDetailsScreen(
                documentId: currentData[index].id!,
                docNumber: currentData[index].docNumber ?? '',
                hasUpdatePermission: _hasUpdatePermission,
                hasDeletePermission: _hasDeletePermission,
                onDocumentUpdated: () {
                  if (mounted) {
                    _manufactureBloc.add(FetchManufactures(
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
              _manufactureBloc.add(SelectDocument(currentData[index]));
            }
          : () {},
      isSelectionMode: _selectionMode,
      isSelected: (state as ManufactureLoaded)
              .selectedData
              ?.contains(currentData[index]) ??
          false,
      onUpdate: () {
        if (mounted) {
          _manufactureBloc.add(FetchManufactures(
              forceRefresh: true, filters: _currentFilters, search: _search));
        }
      },
    );
  }
}
