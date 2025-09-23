import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/models/money/money_income_document_model.dart';
import 'package:crm_task_manager/page_2/money/money_income/widgets/money_income_card.dart';
import 'package:crm_task_manager/page_2/money/money_income/widgets/money_income_deletion.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/money_income/money_income_bloc.dart';
import '../../../custom_widget/app_bar_selection_mode.dart';
import '../../../widgets/snackbar_widget.dart';
import 'add/add_money_income_from_another_cash_register.dart';
import 'add/add_money_income_from_client.dart';
import 'add/add_money_income_other_income.dart';
import 'add/add_money_income_supplier_return.dart';
import 'edit/edit_money_income_from_another_cash_register.dart';
import 'edit/edit_money_income_from_client.dart';
import 'edit/edit_money_income_other_income.dart';
import 'edit/edit_money_income_supplier_return.dart';
import 'operation_type.dart';

class MoneyIncomeScreen extends StatefulWidget {
  final int? organizationId;

  const MoneyIncomeScreen({this.organizationId, super.key});

  @override
  State<MoneyIncomeScreen> createState() => _MoneyIncomeScreenState();
}

class _MoneyIncomeScreenState extends State<MoneyIncomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Map<String, dynamic> _currentFilters = {};
  String? _search = null;
  late MoneyIncomeBloc _moneyIncomeBloc;

  bool _selectionMode = false;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;

  @override
  void initState() {
    super.initState();
    _moneyIncomeBloc = MoneyIncomeBloc()..add(const FetchMoneyIncome(forceRefresh: true));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _moneyIncomeBloc.close();
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

    _moneyIncomeBloc.add(FetchMoneyIncome(
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

    _moneyIncomeBloc.add(FetchMoneyIncome(
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
      _moneyIncomeBloc.add(FetchMoneyIncome(
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
    _moneyIncomeBloc.add(FetchMoneyIncome(
      forceRefresh: true,
      search: _search,
    ));
  }

  Future<void> _onRefresh() async {
    setState(() {
      _hasReachedMax = false;
    });
    _moneyIncomeBloc.add(const FetchMoneyIncome(forceRefresh: true));
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _navigateToEditScreen(BuildContext context, Document document) async {
    if (!mounted) return;

    final operationType = getOperationTypeFromString(document.operationType);

    if (operationType == null) {
      return;
    }

    Widget? targetScreen;

    switch (operationType) {
      case OperationType.client_payment:
        targetScreen = EditMoneyIncomeFromClient(document: document);
        break;
      case OperationType.send_another_cash_register:
        targetScreen = EditMoneyIncomeAnotherCashRegister(document: document);
        break;
      case OperationType.other_incomes:
        targetScreen = EditMoneyIncomeOtherIncome(document: document);
        break;
      case OperationType.return_supplier:
        targetScreen = EditMoneyIncomeSupplierReturn(document: document);
        break;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: _moneyIncomeBloc,
          child: targetScreen,
        ),
      ),
    );

    if (result == true && mounted) {
      _moneyIncomeBloc.add(const FetchMoneyIncome(forceRefresh: true));
    }
  }

  void showDeleteDialog({required BuildContext context, required Document document, required VoidCallback onDelete}) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<MoneyIncomeBloc>(),
        child: MoneyIncomeDeleteDialog(
            documentId: document.id!,
            onDelete: (id) {
              onDelete();
            }),
      ),
    ).then((value) {
      if (mounted) {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocProvider.value(
      value: _moneyIncomeBloc,
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            forceMaterialTransparency: true,
            automaticallyImplyLeading: !_selectionMode,
            title: _selectionMode
                ? BlocBuilder<MoneyIncomeBloc, MoneyIncomeState>(
                    builder: (context, state) {
                      if (state is MoneyIncomeLoaded) {

                        bool showApprove = state.selectedData!.any((doc) => doc.approved == false && doc.deletedAt == null);
                        bool showDisapprove = state.selectedData!.any((doc) => doc.approved == true && doc.deletedAt == null);
                        bool showDelete = state.selectedData!.any((doc) => doc.deletedAt == null);
                        bool showRestore = state.selectedData!.any((doc) => doc.deletedAt != null);

                        return AppBarSelectionMode(
                            title: localizations.translate('appbar_money_income'),
                            onDismiss: () {
                              setState(() {
                                _selectionMode = false;
                              });
                              _moneyIncomeBloc.add(UnselectAllDocuments());
                            },
                            onApprove: () {
                              setState(() {
                                _selectionMode = false;
                              });
                              _moneyIncomeBloc.add(MassApproveMoneyIncomeDocuments());
                            },
                            onDisapprove: () {
                              setState(() {
                                _selectionMode = false;
                              });
                              _moneyIncomeBloc.add(MassDisapproveMoneyIncomeDocuments());
                            },
                            onDelete: () {
                              setState(() {
                                _selectionMode = false;
                              });
                              _moneyIncomeBloc.add(MassDeleteMoneyIncomeDocuments());
                            },
                            onRestore: () {
                              setState(() {
                                _selectionMode = false;
                              });
                              _moneyIncomeBloc.add(MassRestoreMoneyIncomeDocuments());
                            },
                            showApprove: showApprove,
                            showDelete: showDelete,
                            showDisapprove: showDisapprove,
                            showRestore: showRestore,
                        );
                      }

                      return AppBarSelectionMode(
                        title: localizations.translate('appbar_money_income'),
                        onDismiss: () {
                          setState(() {
                            _selectionMode = false;
                          });
                          _moneyIncomeBloc.add(UnselectAllDocuments());
                        },
                      );
                    },
                  )
                : CustomAppBarPage2(
                    title: localizations.translate('appbar_money_income'),
                    showSearchIcon: true,
                    showFilterIcon: false,
                    showFilterOrderIcon: false,
                    showFilterIncomeIcon: true,
                    onFilterIncomeSelected: _onFilterSelected,
                    onIncomeResetFilters: _onResetFilters,
                    onChangedSearchInput: _onSearch,
                    textEditingController: _searchController,
                    focusNode: _focusNode,
                    clearButtonClick: (value) {
                      if (!value) {
                        setState(() {
                          _isSearching = false;
                          _searchController.clear();
                          _search = null; // Очищаем поиск
                        });
                        _moneyIncomeBloc.add(FetchMoneyIncome(
                          forceRefresh: true,
                          filters: _currentFilters, // Сохраняем фильтры при очистке поиска
                        ));
                      }
                    },
                    onClickProfileAvatar: () {},
                    clearButtonClickFiltr: (bool p1) {},
                    currentFilters: _currentFilters,
                  ),
          ),
          body: BlocListener<MoneyIncomeBloc, MoneyIncomeState>(
            listener: (context, state) {
              if (!mounted) return;

              if (state is MoneyIncomeLoaded) {
                setState(() {
                  _hasReachedMax = state.hasReachedMax;
                  _isLoadingMore = false;
                });
              } else if (state is MoneyIncomeError) {
                setState(() {
                  _isLoadingMore = false;
                });
                showCustomSnackBar(context: context, message: state.message, isSuccess: false);
              } else if (state is MoneyIncomeCreateSuccess) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              } else if (state is MoneyIncomeCreateError) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: false);
              } else if (state is MoneyIncomeUpdateSuccess) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              } else if (state is MoneyIncomeUpdateError) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: false);
              } else if (state is MoneyIncomeToggleOneApproveSuccess) {
                showCustomSnackBar(context: context, message: localizations.translate('status_changed_successfully_approve'), isSuccess: true);
              } else if (state is MoneyIncomeToggleOneApproveError) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: false);
              } else if (state is MoneyIncomeDeleteSuccess) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              } else if (state is MoneyIncomeRestoreSuccess) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              } else if (state is MoneyIncomeRestoreError) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: false);
              } else if (state is MoneyIncomeApproveMassSuccess) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: true);
                _moneyIncomeBloc.add(const FetchMoneyIncome(forceRefresh: true));
              } else if (state is MoneyIncomeApproveMassError) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: false);
              } else if (state is MoneyIncomeDisapproveMassSuccess) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: true);
                _moneyIncomeBloc.add(const FetchMoneyIncome(forceRefresh: true));
              } else if (state is MoneyIncomeDisapproveMassError) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: false);
              } else if (state is MoneyIncomeDeleteMassSuccess) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: true);
                _moneyIncomeBloc.add(const FetchMoneyIncome(forceRefresh: true));
              } else if (state is MoneyIncomeDeleteMassError) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: false);
              } else if (state is MoneyIncomeRestoreMassSuccess) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: true);
                _moneyIncomeBloc.add(const FetchMoneyIncome(forceRefresh: true));
              } else if (state is MoneyIncomeRestoreMassError) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: false);
              }
            },
            child: BlocBuilder<MoneyIncomeBloc, MoneyIncomeState>(
              builder: (context, state) {

                if (kDebugMode) {
                  print("📝 [UI] Текущий статус MoneyIncomeBloc: $state");
                }

                if (
                state is MoneyIncomeLoading
                ) {
                  return Center(
                    child: PlayStoreImageLoading(
                      size: 80.0,
                      duration: const Duration(milliseconds: 1000),
                    ),
                  );
                }

                final List<Document> currentData = state is MoneyIncomeLoaded ? state.data : [];

                if (currentData.isEmpty && state is MoneyIncomeLoaded) {
                  return Center(
                    child: Text(
                      _isSearching ? localizations.translate('nothing_found') : localizations.translate('no_money_income'),
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
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                    duration: const Duration(milliseconds: 500),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      }

                      final document = currentData[index];

                      return Dismissible(
                        key: Key(document.id.toString()),
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
                          return document.deletedAt == null;
                        },
                        onDismissed: (direction) {
                          print("🗑️ [UI] Удаление dokumenta ID: ${document.id}");
                          setState(() {
                            currentData.removeAt(index);
                          });
                          _moneyIncomeBloc.add(DeleteMoneyIncome(document.id!, reload: false));
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: MoneyIncomeCard(
                            isSelectionMode: _selectionMode,
                            isSelected: (state as MoneyIncomeLoaded).selectedData?.contains(document) ?? false,
                            document: document,
                            onLongPress: (document) {
                              if (_selectionMode) return;
                              setState(() {
                                _selectionMode = true;
                              });
                              _moneyIncomeBloc.add(SelectDocument(document));
                            },
                            onClick: (document) {
                              if (_selectionMode) {
                                final currentState = context.read<MoneyIncomeBloc>().state;
                                if (currentState is MoneyIncomeLoaded) {
                                  final selectedCount = currentState.selectedData?.length ?? 0;
                                  if (selectedCount <= 1 && currentState.selectedData?.contains(document) == true) {
                                    setState(() {
                                      _selectionMode = false;
                                    });
                                  }
                                }

                                _moneyIncomeBloc.add(SelectDocument(document));
                              } else {
                                if (document.deletedAt == null) {
                                  _navigateToEditScreen(context, document);
                                }
                              }
                            },
                            onDelete: () {
                              debugPrint("show delete dialog for document ID: ${document.id}");
                              showDeleteDialog(
                                  context: context,
                                  document: currentData[index],
                                  onDelete: () {
                                    _moneyIncomeBloc.add(DeleteMoneyIncome(document.id!));
                                  });
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
          floatingActionButton: PopupMenuButton<String>(
            key: const Key('create_money_income_button'),
            onSelected: (String value) async {
              if (!mounted) return;

              Widget targetScreen;

              if (value == OperationType.client_payment.name) {
                targetScreen = const AddMoneyIncomeFromClient();
              } else if (value == OperationType.send_another_cash_register.name) {
                targetScreen = const AddMoneyIncomeAnotherCashRegister();
              } else if (value == OperationType.other_incomes.name) {
                targetScreen = const AddMoneyIncomeOtherIncome();
              } else if (value == OperationType.return_supplier.name) {
                targetScreen = const AddMoneyIncomeSupplierReturn();
              } else {
                return;
              }

              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: _moneyIncomeBloc,
                    child: targetScreen,
                  ),
                ),
              );

              if (result == true && mounted) {
                _moneyIncomeBloc.add(const FetchMoneyIncome(forceRefresh: true));
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: OperationType.client_payment.name,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: Color(0xff1E2E52),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          localizations.translate('client_payment'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: OperationType.send_another_cash_register.name,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.swap_horiz,
                        color: Color(0xff1E2E52),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          localizations.translate('cash_register_transfer'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: OperationType.other_incomes.name,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_circle_outline,
                        color: Color(0xff1E2E52),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          localizations.translate('other_income'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: OperationType.return_supplier.name,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.keyboard_return,
                        color: Color(0xff1E2E52),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          localizations.translate('supplier_return'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
            offset: const Offset(0, -220),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.1),
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: Color(0xff1E2E52), borderRadius: BorderRadius.all(Radius.circular(18))),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 24,
              ),
            ),
          )),
    );
  }
}
