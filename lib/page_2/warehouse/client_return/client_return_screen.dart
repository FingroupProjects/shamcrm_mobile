import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/client_return/client_return_bloc.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/app_bar_selection_mode.dart';
import 'package:crm_task_manager/page_2/money/widgets/error_dialog.dart';
import 'package:crm_task_manager/page_2/warehouse/client_return/client_return_card.dart';
import 'package:crm_task_manager/page_2/warehouse/client_return/client_return_create.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  String? _search;
  late ClientReturnBloc _clientReturnBloc;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;
  bool _selectionMode = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _clientReturnBloc.close();
    super.dispose();
  }

  void _onScroll() {

    if (_isLoadingMore || _hasReachedMax) return;

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
        search: _search,
      ));
    }
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.trim().isNotEmpty;
    });
    _search = query;
    _clientReturnBloc.add(FetchClientReturns(
      forceRefresh: true,
      filters: _currentFilters,
      search: _search,
    ));
  }

  Future<void> _onRefresh() async {
    setState(() {
      _hasReachedMax = false;
    });
    _clientReturnBloc.add(FetchClientReturns(
      forceRefresh: true,
      filters: _currentFilters,
      search: _search,
    ));
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
  void initState() {
    super.initState();
    _clientReturnBloc = ClientReturnBloc(ApiService())
      ..add(const FetchClientReturns(forceRefresh: true));
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return BlocProvider.value(
      value: _clientReturnBloc,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateClientReturnDocumentScreen(
                      organizationId: widget.organizationId),
                ),
              ).then((_) {
                _clientReturnBloc.add(FetchClientReturns(
                  forceRefresh: true,
                  filters: _currentFilters,
                  search: _search,
                ));
              });
            }
          },
          backgroundColor: const Color(0xff1E2E52),
          child: const Icon(Icons.add, color: Colors.white),
        ),
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
                bool showDelete = state.selectedData!.any((doc) => doc.deletedAt == null);
                bool showRestore = state.selectedData!.any((doc) => doc.deletedAt != null);

                return AppBarSelectionMode(
                  title: localizations!.translate('appbar_client_returns') ?? 'Возврат от клиента',
                  onDismiss: () {
                    setState(() {
                      _selectionMode = false;
                    });
                    _clientReturnBloc.add(UnselectAllDocuments());
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
                title: localizations!.translate('appbar_client_returns') ?? 'Возврат от клиента',
                onDismiss: () {
                  setState(() {
                    _selectionMode = false;
                  });
                  _clientReturnBloc.add(UnselectAllDocuments());
                },
              );
            },
          )
              : CustomAppBarPage2(
            title: localizations!.translate('appbar_client_returns') ?? 'Возврат от клиента',
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
                  _search = null;
                });
                _clientReturnBloc.add(FetchClientReturns(
                  forceRefresh: true,
                  filters: _currentFilters,
                  search: null,
                ));
              }
            },
            onClickProfileAvatar: () {},
            clearButtonClickFiltr: (bool p1) {},
            currentFilters: {},
          ),
        ),
        body: BlocListener<ClientReturnBloc, ClientReturnState>(
          listener: (context, state) {
            if (!mounted) return;

            if (state is ClientReturnLoaded) {
              setState(() {
                _hasReachedMax = state.hasReachedMax;
                _isLoadingMore = false;
              });
            } else if (state is ClientReturnError) {
              setState(() {
                _isLoadingMore = false;
              });
              if (state.statusCode == 409) {
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message);
                return;
              }
              showCustomSnackBar(context: context, message: state.message, isSuccess: false);
            } else if (state is ClientReturnApproveMassSuccess) {
              showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              _clientReturnBloc.add(FetchClientReturns(forceRefresh: true, filters: _currentFilters, search: _search));
            } else if (state is ClientReturnApproveMassError) {
              if (state.statusCode == 409) {
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message);
                return;
              }
              showCustomSnackBar(context: context, message: state.message, isSuccess: false);
            } else if (state is ClientReturnDisapproveMassSuccess) {
              showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              _clientReturnBloc.add(FetchClientReturns(forceRefresh: true, filters: _currentFilters, search: _search));
            } else if (state is ClientReturnDisapproveMassError) {
              if (state.statusCode == 409) {
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message);
                return;
              }
              showCustomSnackBar(context: context, message: state.message, isSuccess: false);
            } else if (state is ClientReturnDeleteSuccess) {
              _showSnackBar(state.message, true);
              if (state.shouldReload) _clientReturnBloc.add(FetchClientReturns(forceRefresh: true, filters: _currentFilters, search: _search));
            } else if (state is ClientReturnDeleteError) {
              if (state.statusCode == 409) {
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message);
                _clientReturnBloc.add(FetchClientReturns(forceRefresh: true, filters: _currentFilters, search: _search));
                return;
              }
              showCustomSnackBar(context: context, message: state.message, isSuccess: false);
            } else if (state is ClientReturnDeleteMassSuccess) {
              showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              _clientReturnBloc.add(FetchClientReturns(forceRefresh: true, filters: _currentFilters, search: _search));
            } else if (state is ClientReturnDeleteMassError) {
              if (state.statusCode == 409) {
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message);
                _clientReturnBloc.add(FetchClientReturns(forceRefresh: true, filters: _currentFilters, search: _search));
                return;
              }
              showCustomSnackBar(context: context, message: state.message, isSuccess: false);
            } else if (state is ClientReturnRestoreMassSuccess) {
              showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              _clientReturnBloc.add(FetchClientReturns(forceRefresh: true, filters: _currentFilters, search: _search));
            } else if (state is ClientReturnRestoreMassError) {
              if (state.statusCode == 409) {
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message);
                return;
              }
              showCustomSnackBar(context: context, message: state.message, isSuccess: false);
            }
          },
          child: BlocBuilder<ClientReturnBloc, ClientReturnState>(
            builder: (context, state) {
              if (state is ClientReturnLoading) {
                return Center(
                  child: PlayStoreImageLoading(
                    size: 80.0,
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              }

              final currentData = state is ClientReturnLoaded ? state.data : [];

              if (currentData.isEmpty && state is ClientReturnLoaded) {
                return Center(
                  child: Text(
                    _isSearching
                        ? localizations?.translate('nothing_found') ?? 'Ничего не найдено'
                        : localizations?.translate('no_returns') ?? 'Нет возвратов',
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
                            duration: Duration(milliseconds: 1000),
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
                        final documentToDelete = currentData[index];

                        setState(() {
                          currentData.removeAt(index);
                        });

                        _clientReturnBloc.add(DeleteClientReturn(
                          documentToDelete.id!,
                          localizations!,
                          shouldReload: false,
                        ));
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ClientReturnCard(
                          document: currentData[index],
                          onTap: () {
                            if (_selectionMode) {
                              _clientReturnBloc.add(SelectDocument(currentData[index]));

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

                            if (currentData[index].deletedAt != null) return;

                            Navigator.pushNamed(
                              context,
                              '/client_return_details',
                              arguments: {
                                'documentId': currentData[index].id!,
                                'docNumber': currentData[index].docNumber ?? 'N/A',
                              },
                            ).then((_) {
                              _clientReturnBloc.add(FetchClientReturns(
                                forceRefresh: true,
                                filters: _currentFilters,
                                search: _search,
                              ));
                            });
                          },
                          isSelectionMode: _selectionMode,
                          isSelected: (state as ClientReturnLoaded).selectedData?.contains(currentData[index]) ?? false,
                          onLongPress: () {
                            if (_selectionMode) return;
                            setState(() {
                              _selectionMode = true;
                            });
                            _clientReturnBloc.add(SelectDocument(currentData[index]));
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}