import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/models/money/money_outcome_document_model.dart';
import 'package:crm_task_manager/page_2/money/money_outcome/widgets/money_outcome_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/main.dart' show scaffoldMessengerKey;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/money_outcome/money_outcome_bloc.dart';
import 'add/add_money_outcome_from_another_cash_register.dart';
import 'add/add_money_outcome_from_client.dart';
import 'add/add_money_outcome_other_outcome.dart';
import 'add/add_money_outcome_supplier_return.dart';
import 'edit/edit_money_outcome_from_another_cash_register.dart';
import 'edit/edit_money_outcome_from_client.dart';
import 'edit/edit_money_outcome_other_outcome.dart';
import 'edit/edit_money_outcome_supplier_return.dart';
import 'operation_type.dart';

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

  bool _isInitialLoad = true;
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
    if (kDebugMode) {
      print('MoneyOutcomeScreen: Применение фильтров: $filters');
    }
    setState(() {
      _currentFilters = Map.from(filters);
      _isInitialLoad = true;
      _hasReachedMax = false;
      _isLoadingMore = false;
      if (kDebugMode) {
        print('MoneyOutcomeScreen: Сохранены текущие фильтры: $_currentFilters');
      }
    });

    // Clear search when applying filters
    _searchController.clear();
    _search = null;

    _moneyOutcomeBloc.add(FetchMoneyOutcome(
      filters: filters,
      forceRefresh: true,
      search: null,
    ));
  }

  void _onResetFilters() {
    if (kDebugMode) {
      print('MoneyOutcomeScreen: Сброс фильтров');
    }
    setState(() {
      _currentFilters.clear();
      _isInitialLoad = true;
      _hasReachedMax = false;
      _isLoadingMore = false;
      _searchController.clear();
      _search = null;
      if (kDebugMode) {
        print('MoneyOutcomeScreen: Очищены текущие фильтры');
      }
    });

    _moneyOutcomeBloc.add(FetchMoneyOutcome(
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
      _moneyOutcomeBloc.add(FetchMoneyOutcome(
        forceRefresh: false,
        filters: _currentFilters,
      ));
    }
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    _search = query;
    _moneyOutcomeBloc.add(FetchMoneyOutcome(
      forceRefresh: true,
      search: _search,
    ));
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _currentFilters = {};
      _isInitialLoad = true;
      _hasReachedMax = false;
    });
    _moneyOutcomeBloc.add(const FetchMoneyOutcome(forceRefresh: true));
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _showSnackBar(String message, bool isSuccess) {
    // Используем глобальный scaffoldMessengerKey, чтобы не зависеть от жизненного цикла локального контекста
    // и избежать ошибок «deactivated widget's ancestor».
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
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

  Future<void> _navigateToEditScreen(BuildContext context, Document document) async {
    if (!mounted) return;

    final operationType = getOperationTypeFromString(document.operationType);

    if (operationType == null) {
      return;
    }

    Widget? targetScreen;

    switch (operationType) {
      case OperationType.client_payment:
        targetScreen = EditMoneyOutcomeFromClient(document: document);
        break;
      case OperationType.send_another_cash_register:
        targetScreen = EditMoneyOutcomeAnotherCashRegister(document: document);
        break;
      case OperationType.other_incomes:
        targetScreen = EditMoneyOutcomeOtherOutcome(document: document);
        break;
      case OperationType.return_supplier:
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return BlocProvider.value(
      value: _moneyOutcomeBloc,
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            forceMaterialTransparency: true,
            title: CustomAppBarPage2(
              title: localizations!.translate('appbar_money_outcome'),
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
              currentFilters: {},
            ),
          ),
          body: BlocListener<MoneyOutcomeBloc, MoneyOutcomeState>(
            listener: (context, state) {
              if (!mounted) return;

              if (kDebugMode) {
                print('MoneyOutcomeScreen: State changed to ${state.runtimeType}');
                if (state is MoneyOutcomeLoaded) {
                  print('MoneyOutcomeScreen: Data count in state: ${state.data.length}');
                }
              }

              if (state is MoneyOutcomeDeleteError && mounted) {
                _showSnackBar(state.message, false);
                _moneyOutcomeBloc.add(FetchMoneyOutcome(
                  forceRefresh: true,
                  filters: _currentFilters,
                  search: _search,
                ));
              }

              if (state is MoneyOutcomeLoaded) {
                setState(() {
                  _hasReachedMax = state.hasReachedMax;
                  _isInitialLoad = false;
                  _isLoadingMore = false;
                });
              } else if (state is MoneyOutcomeError) {
                setState(() {
                  _isInitialLoad = false;
                  _isLoadingMore = false;
                });
                _showSnackBar(state.message, false);
              } else if (state is MoneyOutcomeCreateSuccess) {
                _showSnackBar(state.message, true);
              } else if (state is MoneyOutcomeCreateError) {
                _showSnackBar(state.message, false);
              } else if (state is MoneyOutcomeUpdateSuccess) {
                _showSnackBar(state.message, true);
              } else if (state is MoneyOutcomeUpdateError) {
                _showSnackBar(state.message, false);
              } else if (state is MoneyOutcomeDeleteSuccess) {
                _showSnackBar(state.message, true);
                _moneyOutcomeBloc.add(FetchMoneyOutcome(
                  forceRefresh: true,
                  filters: _currentFilters,
                  search: _search,
                ));
              } else if (state is MoneyOutcomeRestoreSuccess) {
                _showSnackBar(state.message, true);
                _moneyOutcomeBloc.add(const FetchMoneyOutcome(forceRefresh: true));
              } else if (state is MoneyOutcomeRestoreError) {
                _showSnackBar(state.message, false);
              }
            },
            child: BlocBuilder<MoneyOutcomeBloc, MoneyOutcomeState>(
              builder: (context, state) {
                if (state is MoneyOutcomeLoading) {
                  return Center(
                    child: PlayStoreImageLoading(
                      size: 80.0,
                      duration: const Duration(milliseconds: 1000),
                    ),
                  );
                }

                final currentData =
                    state is MoneyOutcomeLoaded ? state.data : [];

                if (currentData.isEmpty && state is MoneyOutcomeLoaded) {
                  return Center(
                    child: Text(
                      _isSearching
                          ? localizations.translate('nothing_found')
                          : localizations.translate('no_money_outcome'),
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
                                    duration:
                                        const Duration(milliseconds: 1000),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                      return MoneyOutcomeCard(
                        document: currentData[index],
                        onUpdate: (document) {
                          _navigateToEditScreen(context, document);
                        },
                        onDelete: (documentId) {
                          _moneyOutcomeBloc.add(const FetchMoneyOutcome(forceRefresh: true));
                        },
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

              switch (value) {
                case 'client_payment':
                  targetScreen = const AddMoneyOutcomeFromClient();
                  break;
                case 'cash_register_transfer':
                  targetScreen = const AddMoneyOutcomeAnotherCashRegister();
                  break;
                case 'other_outcome':
                  targetScreen = const AddMoneyOutcomeOtherOutcome();
                  break;
                case 'supplier_return':
                  targetScreen = const AddMoneyOutcomeSupplierReturn();
                  break;
                default:
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
              final localizations = AppLocalizations.of(context)!;

              return [
                PopupMenuItem<String>(
                  value: 'client_payment',
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
                  value: 'cash_register_transfer',
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
                  value: 'other_outcome',
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
                          localizations.translate('other_outcome'),
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
                  value: 'supplier_return',
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
            offset: const Offset(0, -220), // Positions the menu above the button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.1),
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xff1E2E52),
                borderRadius: BorderRadius.all(Radius.circular(18))
              ),
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
