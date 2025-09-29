import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/incoming_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/incoming_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/incoming_state.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/incoming_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../custom_widget/app_bar_selection_mode.dart';
import '../../../models/page_2/incoming_document_model.dart';
import '../../../widgets/snackbar_widget.dart';
import '../../money/widgets/error_dialog.dart';
import 'incoming_document_create_screen.dart';
import 'incoming_document_details_screen.dart';

class IncomingScreen extends StatefulWidget {
  final int? organizationId;

  const IncomingScreen({this.organizationId, super.key});

  @override
  State<IncomingScreen> createState() => _IncomingScreenState();
}

class _IncomingScreenState extends State<IncomingScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Map<String, dynamic> _currentFilters = {};
  String? _search;
  late IncomingBloc _incomingBloc;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _incomingBloc = IncomingBloc(ApiService())..add(const FetchIncoming(forceRefresh: true));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _incomingBloc.close();
    super.dispose();
  }

  void _onFilterSelected(Map<String, dynamic> filters) {
    setState(() {
      _currentFilters = Map.from(filters);
      _hasReachedMax = false;
      _isLoadingMore = false;
    });

    _searchController.clear();
    _search = null;

    _incomingBloc.add(FetchIncoming(
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
      _searchController.clear();
      _search = null;
    });

    _incomingBloc.add(const FetchIncoming(
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
      _incomingBloc.add(FetchIncoming(
        forceRefresh: false,
        filters: _currentFilters,
      ));
    }
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.trim().isNotEmpty;
    });
    _search = query;
    _incomingBloc.add(FetchIncoming(
      forceRefresh: true,
      search: _search,
    ));
  }

  Future<void> _onRefresh() async {
    setState(() {
      _hasReachedMax = false;
    });
    _incomingBloc.add(const FetchIncoming(forceRefresh: true));
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
    final localizations = AppLocalizations.of(context);
    return BlocProvider.value(
      value: _incomingBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: !_selectionMode,
          forceMaterialTransparency: true,
          title: _selectionMode
              ? BlocBuilder<IncomingBloc, IncomingState>(
            builder: (context, state) {
              if (state is IncomingLoaded) {
                bool showApprove = state.selectedData!.any((doc) => doc.approved == 0 && doc.deletedAt == null);
                bool showDisapprove = state.selectedData!.any((doc) => doc.approved == 1 && doc.deletedAt == null);
                bool showDelete = state.selectedData!.any((doc) => doc.deletedAt == null);
                bool showRestore = state.selectedData!.any((doc) => doc.deletedAt != null);

                return AppBarSelectionMode(
                  title: localizations?.translate('appbar_incoming') ?? 'Приходы',
                  onDismiss: () {
                    setState(() {
                      _selectionMode = false;
                    });
                    _incomingBloc.add(UnselectAllDocuments());
                  },
                  onApprove: () {
                    setState(() {
                      _selectionMode = false;
                    });
                    _incomingBloc.add(MassApproveIncomingDocuments());
                  },
                  onDisapprove: () {
                    setState(() {
                      _selectionMode = false;
                    });
                    _incomingBloc.add(MassDisapproveIncomingDocuments());
                  },
                  onDelete: () {
                    setState(() {
                      _selectionMode = false;
                    });
                    _incomingBloc.add(MassDeleteIncomingDocuments());
                  },
                  onRestore: () {
                    setState(() {
                      _selectionMode = false;
                    });
                    _incomingBloc.add(MassRestoreIncomingDocuments());
                  },
                  showApprove: showApprove,
                  showDelete: showDelete,
                  showDisapprove: showDisapprove,
                  showRestore: showRestore,
                );
              }

              return AppBarSelectionMode(
                title: localizations?.translate('appbar_incoming') ?? 'Приходы',
                onDismiss: () {
                  setState(() {
                    _selectionMode = false;
                  });
                  _incomingBloc.add(UnselectAllDocuments());
                },
              );
            },
          )
              : CustomAppBarPage2(
            title: localizations!.translate('appbar_incoming') ?? 'Приходы',
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
              if (!value) {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _search = null;
                });
                _incomingBloc.add(FetchIncoming(
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
        body: BlocListener<IncomingBloc, IncomingState>(
          listener: (context, state) {
            debugPrint("IncomingScreen.Bloc.State: ${_incomingBloc.state}");

            if (!mounted) return;

            if (state is IncomingLoaded) {
              setState(() {
                _hasReachedMax = state.hasReachedMax;
                _isLoadingMore = false;
              });
            } else if (state is IncomingError) {
              setState(() {
                _isLoadingMore = false;
              });
              _showSnackBar(state.message, false);
            } else if (state is IncomingCreateSuccess) {
              _showSnackBar(state.message, true);
            } else if (state is IncomingCreateError) {
              if (state.statusCode == 409) {
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message);
                return;
              }
              _showSnackBar(state.message, false);
            } else if (state is IncomingUpdateSuccess) {
              _showSnackBar(state.message, true);
            } else if (state is IncomingUpdateError) {
              if (state.statusCode == 409) {
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message);
                return;
              }
              _showSnackBar(state.message, false);
            } else if (state is IncomingApproveMassSuccess) {
              showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              _incomingBloc.add(const FetchIncoming(forceRefresh: true));
            } else if (state is IncomingApproveMassError) {
              if (state.statusCode == 409) {
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message);
                return;
              }
              showCustomSnackBar(context: context, message: state.message, isSuccess: false);
            } else if (state is IncomingDisapproveMassSuccess) {
              showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              _incomingBloc.add(const FetchIncoming(forceRefresh: true));
            } else if (state is IncomingDisapproveMassError) {
              debugPrint("[ERROR] IncomingDisapproveMassError: ${state.message}, enumType: ${ErrorDialogEnum.goodsIncomingUnapprove}");
              if (state.statusCode == 409) {
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message, errorDialogEnum: ErrorDialogEnum.goodsIncomingUnapprove);
                return;
              }
              showCustomSnackBar(context: context, message: state.message, isSuccess: false);
            } else if (state is IncomingDeleteSuccess) {
              // Показываем SnackBar только если мы находимся на IncomingScreen
              // (т.е. если диалог уже закрыт и мы вернулись сюда)
              _showSnackBar(state.message, true);

              // Обновляем список после успешного удаления
              if (state.shouldReload) _incomingBloc.add(const FetchIncoming(forceRefresh: true));
            } else if (state is IncomingDeleteError) {
              if (state.statusCode == 409) {
                debugPrint("[ERROR] IncomingDeleteError: ${state.message} enumType: ${ErrorDialogEnum.goodsIncomingDelete}");
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message, errorDialogEnum: ErrorDialogEnum.goodsIncomingDelete);
                _incomingBloc.add(const FetchIncoming(forceRefresh: true));
                return;
              }
              showCustomSnackBar(context: context, message: state.message, isSuccess: false);
            } else if (state is IncomingDeleteMassSuccess) {
              showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              _incomingBloc.add(const FetchIncoming(forceRefresh: true));
            } else if (state is IncomingDeleteMassError) {
              if (state.statusCode == 409) {
                debugPrint("[ERROR] IncomingMassDeleteError: ${state.message} enumType: ${ErrorDialogEnum.goodsIncomingDelete}");
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message, errorDialogEnum: ErrorDialogEnum.goodsIncomingDelete);
                _incomingBloc.add(const FetchIncoming(forceRefresh: true));
                return;
              }
              showCustomSnackBar(context: context, message: state.message, isSuccess: false);
            } else if (state is IncomingRestoreMassSuccess) {
              showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              _incomingBloc.add(const FetchIncoming(forceRefresh: true));
            } else if (state is IncomingRestoreMassError) {
              if (state.statusCode == 409) {
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message);
                return;
              }
              showCustomSnackBar(context: context, message: state.message, isSuccess: false);
            }
          },
          child: BlocBuilder<IncomingBloc, IncomingState>(
            builder: (context, state) {
              if (state is IncomingLoading) {
                return Center(
                  child: PlayStoreImageLoading(
                    size: 80.0,
                    duration: const Duration(milliseconds: 1000),
                  ),
                );
              }

              final List<IncomingDocument> currentData = state is IncomingLoaded ? state.data : [];

              if (currentData.isEmpty && state is IncomingLoaded) {
                return Center(
                  child: Text(
                    _isSearching
                        ? localizations!.translate('nothing_found') ?? 'Ничего не найдено'
                        : localizations!.translate('no_incoming') ?? 'Нет приходов',
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
                    return Dismissible(
                        key: Key(currentData[index].id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          padding: const EdgeInsets.all(8),
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
                          child: const Icon(Icons.delete, color: Colors.white, size: 24),
                        ),
                        confirmDismiss: (direction) async {
                          return currentData[index].deletedAt == null;
                        },
                        onDismissed: (direction) {
                          print("🗑️ [UI] Удаление dokumenta ID: ${currentData[index].id}");
                          setState(() {
                            currentData.removeAt(index);
                          });
                          _incomingBloc.add(DeleteIncoming(
                            currentData[index].id!,
                            localizations!,
                            shouldReload: false,
                          ));
                        },
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: IncomingCard(
                              onTap: () {
                                if (_selectionMode) {
                                  _incomingBloc.add(SelectDocument(currentData[index]));

                                  final currentState = context.read<IncomingBloc>().state;

                                  if (currentState is IncomingLoaded) {
                                    final selectedCount = currentState.selectedData?.length ?? 0;
                                    if (selectedCount <= 1 && currentState.selectedData?.contains(currentData[index]) == true) {
                                      setState(() {
                                        _selectionMode = false;
                                      });
                                    }
                                  }
                                  return;
                                }

                                if (currentData[index].deletedAt != null) return;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => IncomingDocumentDetailsScreen(
                                      documentId: currentData[index].id!,
                                      docNumber: currentData[index].docNumber ?? 'N/A',
                                      onDocumentUpdated: () {
                                        _incomingBloc.add(const FetchIncoming(forceRefresh: true));
                                      },
                                    ),
                                  ),
                                );
                              },
                              isSelectionMode: _selectionMode,
                              isSelected: (state as IncomingLoaded).selectedData?.contains(currentData[index]) ?? false,
                              onLongPress: () {
                                if (_selectionMode) return;
                                setState(() {
                                  _selectionMode = true;
                                });
                                _incomingBloc.add(SelectDocument(currentData[index]));
                              },
                              document: currentData[index],
                            )));
                  },
                ),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          key: const Key('create_incoming_button'),
          onPressed: () async {
            if (mounted) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IncomingDocumentCreateScreen(
                    organizationId: widget.organizationId,
                  ),
                ),
              );

              if (result == true && mounted) {
                _incomingBloc.add(const FetchIncoming(forceRefresh: true));
              }
            }
          },
          backgroundColor: const Color(0xff1E2E52),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
