import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/client_sale/bloc/client_sale_bloc.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/warehouse/client_sale/client_sales_card.dart';
import 'package:crm_task_manager/page_2/warehouse/client_sale/create_clien_sales_document_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../custom_widget/app_bar_selection_mode.dart';
import '../../../models/page_2/incoming_document_model.dart';
import '../../../widgets/snackbar_widget.dart';
import '../../money/widgets/error_dialog.dart';
import 'clien_sales_document_detail.dart';

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
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;
  bool _selectionMode = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _clientSaleBloc.close();
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
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
    });
    _search = query;
    _clientSaleBloc.add(FetchClientSales(
      forceRefresh: true,
      search: _search,
      filters: _currentFilters,
    ));
  }

  Future<void> _onRefresh() async {
    setState(() {
      _hasReachedMax = false;
    });
    _clientSaleBloc.add(FetchClientSales(
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
    _clientSaleBloc = ClientSaleBloc(ApiService())..add(const FetchClientSales(forceRefresh: true));
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return BlocProvider.value(
      value: _clientSaleBloc,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          key: const Key('create_client_sale_button'),
          onPressed: () async {
            if (mounted) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateClienSalesDocumentScreen(organizationId: widget.organizationId),
                ),
              );

              if (result == true && mounted) {
                _clientSaleBloc.add(FetchClientSales(
                  forceRefresh: true,
                  filters: _currentFilters,
                  search: _search,
                ));
              }
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
              ? BlocBuilder<ClientSaleBloc, ClientSaleState>(
                  builder: (context, state) {
                    if (state is ClientSaleLoaded) {
                      bool showApprove = state.selectedData!.any((doc) => doc.approved == 0 && doc.deletedAt == null);
                      bool showDisapprove = state.selectedData!.any((doc) => doc.approved == 1 && doc.deletedAt == null);
                      bool showDelete = state.selectedData!.any((doc) => doc.deletedAt == null);
                      bool showRestore = state.selectedData!.any((doc) => doc.deletedAt != null);

                      return AppBarSelectionMode(
                        title: localizations?.translate('appbar_client_sales') ?? 'Реализация клиент',
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
                          _clientSaleBloc.add(MassApproveClientSaleDocuments());
                        },
                        onDisapprove: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _clientSaleBloc.add(MassDisapproveClientSaleDocuments());
                        },
                        onDelete: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _clientSaleBloc.add(MassDeleteClientSaleDocuments());
                        },
                        onRestore: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _clientSaleBloc.add(MassRestoreClientSaleDocuments());
                        },
                        showApprove: showApprove,
                        showDelete: showDelete,
                        showDisapprove: showDisapprove,
                        showRestore: showRestore,
                      );
                    }

                    return AppBarSelectionMode(
                      title: localizations?.translate('appbar_client_sales') ?? 'Реализация клиент',
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
                  title: localizations!.translate('appbar_client_sales') ?? 'Реализация клиент',
                  showSearchIcon: true,
                  showFilterIcon: false,
                  showFilterOrderIcon: false,
                  showFilterIncomeIcon: false,
                  showFilterIncomingIcon: true,
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
            debugPrint("ClientSaleScreen.Bloc.State: ${_clientSaleBloc.state}");

            if (!mounted) return;

            if (state is ClientSaleLoaded) {
              setState(() {
                _hasReachedMax = state.hasReachedMax;
                _isLoadingMore = false;
              });
            } else if (state is ClientSaleError) {
              setState(() {
                _isLoadingMore = false;
              });
              _showSnackBar(state.message, false);
            } else if (state is ClientSaleCreateSuccess) {
              _showSnackBar(state.message, true);
            } else if (state is ClientSaleCreateError) {
              if (state.statusCode == 409) {
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message);
                return;
              }
              _showSnackBar(state.message, false);
            } else if (state is ClientSaleUpdateSuccess) {
              _showSnackBar(state.message, true);
            } else if (state is ClientSaleUpdateError) {
              if (state.statusCode == 409) {
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message);
                return;
              }
              _showSnackBar(state.message, false);
            } else if (state is ClientSaleApproveMassSuccess) {
              showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              _clientSaleBloc.add(FetchClientSales(forceRefresh: true, filters: _currentFilters, search: _search));
            } else if (state is ClientSaleApproveMassError) {
              if (state.statusCode == 409) {
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message);
                return;
              }
              showCustomSnackBar(context: context, message: state.message, isSuccess: false);
            } else if (state is ClientSaleDisapproveMassSuccess) {
              showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              _clientSaleBloc.add(FetchClientSales(forceRefresh: true, filters: _currentFilters, search: _search));
            } else if (state is ClientSaleDisapproveMassError) {
              debugPrint(
                  "[ERROR] ClientSaleDisapproveMassError: ${state.message}, enumType: ${ErrorDialogEnum.goodsIncomingUnapprove}");
              if (state.statusCode == 409) {
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message,
                    errorDialogEnum: ErrorDialogEnum.goodsIncomingUnapprove);
                return;
              }
              showCustomSnackBar(context: context, message: state.message, isSuccess: false);
            } else if (state is ClientSaleDeleteSuccess) {
              _showSnackBar(state.message, true);
              if (state.shouldReload)
                _clientSaleBloc.add(FetchClientSales(forceRefresh: true, filters: _currentFilters, search: _search));
            } else if (state is ClientSaleDeleteError) {
              if (state.statusCode == 409) {
                debugPrint("[ERROR] ClientSaleDeleteError: ${state.message} enumType: ${ErrorDialogEnum.goodsIncomingDelete}");
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message,
                    errorDialogEnum: ErrorDialogEnum.goodsIncomingDelete);
                _clientSaleBloc.add(FetchClientSales(forceRefresh: true, filters: _currentFilters, search: _search));
                return;
              }
              showCustomSnackBar(context: context, message: state.message, isSuccess: false);
            } else if (state is ClientSaleDeleteMassSuccess) {
              showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              _clientSaleBloc.add(FetchClientSales(forceRefresh: true, filters: _currentFilters, search: _search));
            } else if (state is ClientSaleDeleteMassError) {
              if (state.statusCode == 409) {
                debugPrint(
                    "[ERROR] ClientSaleMassDeleteError: ${state.message} enumType: ${ErrorDialogEnum.goodsIncomingDelete}");
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message,
                    errorDialogEnum: ErrorDialogEnum.goodsIncomingDelete);
                _clientSaleBloc.add(FetchClientSales(forceRefresh: true, filters: _currentFilters, search: _search));
                return;
              }
              showCustomSnackBar(context: context, message: state.message, isSuccess: false);
            } else if (state is ClientSaleRestoreMassSuccess) {
              showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              _clientSaleBloc.add(FetchClientSales(forceRefresh: true, filters: _currentFilters, search: _search));
            } else if (state is ClientSaleRestoreMassError) {
              if (state.statusCode == 409) {
                showSimpleErrorDialog(context, localizations?.translate('error') ?? 'Ошибка', state.message);
                return;
              }
              showCustomSnackBar(context: context, message: state.message, isSuccess: false);
            }
          },
          child: BlocBuilder<ClientSaleBloc, ClientSaleState>(
            builder: (context, state) {
              if (state is ClientSaleLoading) {
                return Center(
                  child: PlayStoreImageLoading(
                    size: 80.0,
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              }

              final List<IncomingDocument> currentData = state is ClientSaleLoaded ? state.data : [];

              if (currentData.isEmpty && state is ClientSaleLoaded) {
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
                          print("🗑️ [UI] Удаление dokumenta ID: ${currentData[index].id}");
                          setState(() {
                            currentData.removeAt(index);
                          });
                          _clientSaleBloc.add(DeleteClientSale(
                            currentData[index].id!,
                            localizations!,
                            shouldReload: false,
                          ));
                        },
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ClientSalesCard(
                              onTap: () {
                                if (_selectionMode) {
                                  _clientSaleBloc.add(SelectDocument(currentData[index]));

                                  final currentState = context.read<ClientSaleBloc>().state;

                                  if (currentState is ClientSaleLoaded) {
                                    final selectedCount = currentState.selectedData?.length ?? 0;
                                    if (selectedCount <= 1 && currentState.selectedData?.contains(currentData[index]) == true) {
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
                                    builder: (context) => ClientSalesDocumentDetailsScreen(
                                      documentId: currentData[index].id!,
                                      docNumber: currentData[index].docNumber ?? 'N/A',
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
                              isSelected: (state as ClientSaleLoaded).selectedData?.contains(currentData[index]) ?? false,
                              onLongPress: () {
                                if (_selectionMode) return;
                                setState(() {
                                  _selectionMode = true;
                                });
                                _clientSaleBloc.add(SelectDocument(currentData[index]));
                              },
                              document: currentData[index],
                            )));
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
