import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/models/money/money_outcome_document_model.dart';
import 'package:crm_task_manager/page_2/money/money_outcome/widgets/money_outcome_card.dart';
import 'package:crm_task_manager/page_2/money/widgets/error_dialog.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/money_outcome/money_outcome_bloc.dart';
import '../../../custom_widget/app_bar_selection_mode.dart';
import '../../../widgets/snackbar_widget.dart';
import 'add/add_money_outcome_from_client.dart';
import 'add/add_money_outcome_other_outcome.dart';
import 'add/add_money_outcome_supplier_return.dart';
import 'edit/edit_money_outcome_from_client.dart';
import 'edit/edit_money_outcome_other_outcome.dart';
import 'edit/edit_money_outcome_supplier_return.dart';
import 'money_outcome_operation_type.dart';

class MoneyOutcomeScreen extends StatefulWidget {
  final int? organizationId;

  const MoneyOutcomeScreen({this.organizationId, super.key});

  @override
  State<MoneyOutcomeScreen> createState() => _MoneyOutcomeScreenState();
}

class _MoneyOutcomeScreenState extends State<MoneyOutcomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Map<String, dynamic> _currentFilters = {};
  String? _search = null;
  late MoneyOutcomeBloc _moneyOutcomeBloc;

  bool _selectionMode = false;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;

  @override
  void initState() {
    super.initState();
    _moneyOutcomeBloc = MoneyOutcomeBloc()..add(const FetchMoneyOutcome(forceRefresh: true));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _moneyOutcomeBloc.close();
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

    _moneyOutcomeBloc.add(FetchMoneyOutcome(
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

    _moneyOutcomeBloc.add(FetchMoneyOutcome(
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
      _moneyOutcomeBloc.add(FetchMoneyOutcome(
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
    _moneyOutcomeBloc.add(FetchMoneyOutcome(
      forceRefresh: true,
      search: _search,
    ));
  }

  Future<void> _onRefresh() async {
    setState(() {
      _hasReachedMax = false;
    });
    _moneyOutcomeBloc.add(const FetchMoneyOutcome(forceRefresh: true));
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
      case MoneyOutcomeOperationType.client_return:
        targetScreen = EditMoneyOutcomeFromClient(document: document);
        break;
      // case MoneyOutcomeOperationType.send_another_cash_register:
      //   targetScreen = EditMoneyOutcomeAnotherCashRegister(document: document);
      //   break;
      case MoneyOutcomeOperationType.other_expenses:
        targetScreen = EditMoneyOutcomeOtherOutcome(document: document);
        break;
      case MoneyOutcomeOperationType.supplier_payment:
        targetScreen = EditMoneyOutcomeSupplierReturn(document: document);
        break;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: _moneyOutcomeBloc,
          child: targetScreen,
        ),
      ),
    );

    if (result == true && mounted) {
      _moneyOutcomeBloc.add(const FetchMoneyOutcome(forceRefresh: true));
    }
  }

/*  void showDeleteDialog({required BuildContext context, required Document document, required VoidCallback onDelete}) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<MoneyOutcomeBloc>(),
        child: MoneyOutcomeDeleteDialog(
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
  }*/

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocProvider.value(
      value: _moneyOutcomeBloc,
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            forceMaterialTransparency: true,
            automaticallyImplyLeading: !_selectionMode,
            title: _selectionMode
                ? BlocBuilder<MoneyOutcomeBloc, MoneyOutcomeState>(
              builder: (context, state) {
                if (state is MoneyOutcomeLoaded) {
                  bool showApprove = state.selectedData!.any((doc) => doc.approved == false && doc.deletedAt == null);
                  bool showDisapprove = state.selectedData!.any((doc) => doc.approved == true && doc.deletedAt == null);
                  bool showDelete = state.selectedData!.any((doc) => doc.deletedAt == null);
                  bool showRestore = state.selectedData!.any((doc) => doc.deletedAt != null);

                  return AppBarSelectionMode(
                    title: localizations.translate('appbar_money_outcome'),
                    onDismiss: () {
                      setState(() {
                        _selectionMode = false;
                      });
                      _moneyOutcomeBloc.add(UnselectAllDocuments());
                    },
                    onApprove: () {
                      setState(() {
                        _selectionMode = false;
                      });
                      _moneyOutcomeBloc.add(MassApproveMoneyOutcomeDocuments());
                    },
                    onDisapprove: () {
                      setState(() {
                        _selectionMode = false;
                      });
                      _moneyOutcomeBloc.add(MassDisapproveMoneyOutcomeDocuments());
                    },
                    onDelete: () {
                      setState(() {
                        _selectionMode = false;
                      });
                      _moneyOutcomeBloc.add(MassDeleteMoneyOutcomeDocuments());
                    },
                    onRestore: () {
                      setState(() {
                        _selectionMode = false;
                      });
                      _moneyOutcomeBloc.add(MassRestoreMoneyOutcomeDocuments());
                    },
                    showApprove: showApprove,
                    showDelete: showDelete,
                    showDisapprove: showDisapprove,
                    showRestore: showRestore,
                  );
                }

                return AppBarSelectionMode(
                  title: localizations.translate('appbar_money_outcome'),
                  onDismiss: () {
                    setState(() {
                      _selectionMode = false;
                    });
                    _moneyOutcomeBloc.add(UnselectAllDocuments());
                  },
                );
              },
            )
                : CustomAppBarPage2(
              title: localizations.translate('appbar_money_outcome'),
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
                  _moneyOutcomeBloc.add(FetchMoneyOutcome(
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
          body: BlocListener<MoneyOutcomeBloc, MoneyOutcomeState>(
            listener: (context, state) {
              if (!mounted) return;

              if (state is MoneyOutcomeLoaded) {
                setState(() {
                  _hasReachedMax = state.hasReachedMax;
                  _isLoadingMore = false;
                });
              } else if (state is MoneyOutcomeError) {
                setState(() {
                  _isLoadingMore = false;
                });
                showCustomSnackBar(context: context, message: state.message, isSuccess: false);
              } else if (state is MoneyOutcomeCreateSuccess) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              } else if (state is MoneyOutcomeCreateError) {
                if (state.statusCode == 409) {
                  showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', state.message);
                  return;
                }
                showCustomSnackBar(context: context, message: state.message, isSuccess: false);
              } else if (state is MoneyOutcomeUpdateSuccess) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              } else if (state is MoneyOutcomeUpdateError) {
                if (state.statusCode == 409) {
                  showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', state.message);
                  return;
                }
                showCustomSnackBar(context: context, message: state.message, isSuccess: false);
              } else if (state is MoneyOutcomeToggleOneApproveSuccess) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              } else if (state is MoneyOutcomeToggleOneApproveError) {
                if (state.statusCode == 409) {
                  showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', state.message);
                  return;
                }
                showCustomSnackBar(context: context, message: state.message, isSuccess: false);
              } else if (state is MoneyOutcomeDeleteSuccess) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: true);
              } else if (state is MoneyOutcomeDeleteError) {
                if (state.statusCode == 409) {
                  showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', state.message);
                  return;
                }
                showCustomSnackBar(context: context, message: state.message, isSuccess: false);
              } else if (state is MoneyOutcomeApproveMassSuccess) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: true);
                _moneyOutcomeBloc.add(const FetchMoneyOutcome(forceRefresh: true));
              } else if (state is MoneyOutcomeApproveMassError) {
                if (state.statusCode == 409) {
                  showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', state.message);
                  return;
                }
                showCustomSnackBar(context: context, message: state.message, isSuccess: false);
              } else if (state is MoneyOutcomeDisapproveMassSuccess) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: true);
                _moneyOutcomeBloc.add(const FetchMoneyOutcome(forceRefresh: true));
              } else if (state is MoneyOutcomeDisapproveMassError) {
                if (state.statusCode == 409) {
                  showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', state.message);
                  return;
                }
                showCustomSnackBar(context: context, message: state.message, isSuccess: false);
              } else if (state is MoneyOutcomeDeleteMassSuccess) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: true);
                _moneyOutcomeBloc.add(const FetchMoneyOutcome(forceRefresh: true));
              } else if (state is MoneyOutcomeDeleteMassError) {
                if (state.statusCode == 409) {
                  showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', state.message);
                  return;
                }
                showCustomSnackBar(context: context, message: state.message, isSuccess: false);
              } else if (state is MoneyOutcomeRestoreMassSuccess) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: true);
                _moneyOutcomeBloc.add(const FetchMoneyOutcome(forceRefresh: true));
              } else if (state is MoneyOutcomeRestoreMassError) {
                if (state.statusCode == 409) {
                  showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', state.message);
                  return;
                }
                showCustomSnackBar(context: context, message: state.message, isSuccess: false);
              } else if (state is MoneyOutcomeUpdateThenToggleOneApproveSuccess) {
                showCustomSnackBar(context: context, message: state.message, isSuccess: true);
                _moneyOutcomeBloc.add(const FetchMoneyOutcome(forceRefresh: true));
              }
            },
            child: BlocBuilder<MoneyOutcomeBloc, MoneyOutcomeState>(
              builder: (context, state) {
                if (kDebugMode) {
                  print("📝 [UI] Текущий статус MoneyOutcomeBloc: $state");
                }

                if (state is MoneyOutcomeLoading) {
                  return Center(
                    child: PlayStoreImageLoading(
                      size: 80.0,
                      duration: const Duration(milliseconds: 1000),
                    ),
                  );
                }

                final List<Document> currentData = state is MoneyOutcomeLoaded ? state.data : [];

                if (currentData.isEmpty) {
                  return Center(
                    child: Text(
                      _isSearching ? localizations.translate('nothing_found') : localizations.translate('no_money_outcome'),
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
                          _moneyOutcomeBloc.add(DeleteMoneyOutcome(document));
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: MoneyOutcomeCard(
                            isSelectionMode: _selectionMode,
                            isSelected: (state as MoneyOutcomeLoaded).selectedData?.contains(document) ?? false,
                            document: document,
                            onLongPress: (document) {
                              if (_selectionMode) return;
                              setState(() {
                                _selectionMode = true;
                              });
                              _moneyOutcomeBloc.add(SelectDocument(document));
                            },
                            onClick: (document) {
                              if (_selectionMode) {
                                final currentState = context.read<MoneyOutcomeBloc>().state;
                                if (currentState is MoneyOutcomeLoaded) {
                                  final selectedCount = currentState.selectedData?.length ?? 0;
                                  if (selectedCount <= 1 && currentState.selectedData?.contains(document) == true) {
                                    setState(() {
                                      _selectionMode = false;
                                    });
                                  }
                                }

                                _moneyOutcomeBloc.add(SelectDocument(document));
                              } else {
                                if (document.deletedAt == null) {
                                  _navigateToEditScreen(context, document);
                                }
                              }
                            },
                            /*onDelete: () {
                              debugPrint("show delete dialog for document ID: ${document.id}");
                              showDeleteDialog(
                                  context: context,
                                  document: currentData[index],
                                  onDelete: () {
                                    _moneyOutcomeBloc.add(DeleteMoneyOutcome(document));
                                  });
                            },*/
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
            key: const Key('create_money_outcome_button'),
            onSelected: (String value) async {
              if (!mounted) return;

              Widget targetScreen;

              if (value == MoneyOutcomeOperationType.client_return.name) {
                targetScreen = const AddMoneyOutcomeFromClient();
              } /*else if (value == MoneyOutcomeOperationType.send_another_cash_register.name) {
                targetScreen = const AddMoneyOutcomeAnotherCashRegister();
              }*/ else if (value == MoneyOutcomeOperationType.other_expenses.name) {
                targetScreen = const AddMoneyOutcomeOtherOutcome();
              } else if (value == MoneyOutcomeOperationType.supplier_payment.name) {
                targetScreen = const AddMoneyOutcomeSupplierReturn();
              } else {
                return;
              }

              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: _moneyOutcomeBloc,
                    child: targetScreen,
                  ),
                ),
              );

              if (result == true && mounted) {
                _moneyOutcomeBloc.add(const FetchMoneyOutcome(forceRefresh: true));
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: MoneyOutcomeOperationType.client_return.name,
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
                          localizations.translate(MoneyOutcomeOperationType.client_return.name),
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
                // PopupMenuItem<String>(
                //   value: MoneyOutcomeOperationType.send_another_cash_register.name,
                //   child: Row(
                //     children: [
                //       const Icon(
                //         Icons.swap_horiz,
                //         color: Color(0xff1E2E52),
                //         size: 20,
                //       ),
                //       const SizedBox(width: 12),
                //       Expanded(
                //         child: Text(
                //           localizations.translate(MoneyOutcomeOperationType.send_another_cash_register.name),
                //           style: const TextStyle(
                //             fontSize: 14,
                //             fontFamily: 'Gilroy',
                //             fontWeight: FontWeight.w500,
                //             color: Color(0xff1E2E52),
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                PopupMenuItem<String>(
                  value: MoneyOutcomeOperationType.other_expenses.name,
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
                          localizations.translate(MoneyOutcomeOperationType.other_expenses.name),
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
                  value: MoneyOutcomeOperationType.supplier_payment.name,
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
            offset: const Offset(0, -170),
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

void showSimpleErrorDialog(BuildContext context, String title, String errorMessage) {
  showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return ErrorDialog(title: title, errorMessage: errorMessage);
      });
}
