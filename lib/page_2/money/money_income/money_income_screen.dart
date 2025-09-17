import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/page_2/money/money_income/money_income_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/money_income/money_income_bloc.dart';
import 'add/money_income_from_another_cash_register.dart';
import 'add/money_income_from_client.dart';
import 'add/money_income_other_income.dart';
import 'add/money_income_supplier_return.dart';

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
  late MoneyIncomeBloc _moneyIncomeBloc;
  bool _isInitialLoad = true;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;

  @override
  void initState() {
    super.initState();
    _moneyIncomeBloc = MoneyIncomeBloc()
      ..add(const FetchMoneyIncome(forceRefresh: true));
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

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
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
      _isSearching = query.isNotEmpty;
    });
    _currentFilters['query'] = query;
    _moneyIncomeBloc.add(FetchMoneyIncome(
      forceRefresh: true,
      filters: _currentFilters,
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
    _moneyIncomeBloc.add(const FetchMoneyIncome(forceRefresh: true));
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
      value: _moneyIncomeBloc,
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            forceMaterialTransparency: true,
            title: CustomAppBarPage2(
              title: localizations!.translate('appbar_money_income'),
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
                  });
                  _moneyIncomeBloc
                      .add(const FetchMoneyIncome(forceRefresh: true));
                }
              },
              onClickProfileAvatar: () {},
              clearButtonClickFiltr: (bool p1) {},
              currentFilters: {},
            ),
          ),
          body: BlocListener<MoneyIncomeBloc, MoneyIncomeState>(
            listener: (context, state) {
              if (!mounted) return;

              if (state is MoneyIncomeLoaded) {
                setState(() {
                  _hasReachedMax = state.hasReachedMax;
                  _isInitialLoad = false;
                  _isLoadingMore = false;
                });
              } else if (state is MoneyIncomeError) {
                setState(() {
                  _isInitialLoad = false;
                  _isLoadingMore = false;
                });
                _showSnackBar(state.message, false);
              } else if (state is MoneyIncomeCreateSuccess) {
                _showSnackBar(state.message, true);
              } else if (state is MoneyIncomeCreateError) {
                _showSnackBar(state.message, false);
              } else if (state is MoneyIncomeUpdateSuccess) {
                _showSnackBar(state.message, true);
              } else if (state is MoneyIncomeUpdateError) {
                _showSnackBar(state.message, false);
              } else if (state is MoneyIncomeDeleteSuccess) {
                // Показываем SnackBar только если мы находимся на MoneyIncomeScreen
                // (т.е. если диалог уже закрыт и мы вернулись сюда)
                _showSnackBar(state.message, true);

                // Обновляем список после успешного удаления
                _moneyIncomeBloc
                    .add(const FetchMoneyIncome(forceRefresh: true));
              } else if (state is MoneyIncomeRestoreSuccess) {
                _showSnackBar(state.message, true);
                // Обновляем список после успешного восстановления
                _moneyIncomeBloc
                    .add(const FetchMoneyIncome(forceRefresh: true));
              } else if (state is MoneyIncomeRestoreError) {
                _showSnackBar(state.message, false);
              }
            },
            child: BlocBuilder<MoneyIncomeBloc, MoneyIncomeState>(
              builder: (context, state) {
                if (state is MoneyIncomeLoading) {
                  return Center(
                    child: PlayStoreImageLoading(
                      size: 80.0,
                      duration: const Duration(milliseconds: 1000),
                    ),
                  );
                }

                final currentData =
                    state is MoneyIncomeLoaded ? state.data : [];

                if (currentData.isEmpty && state is MoneyIncomeLoaded) {
                  return Center(
                    child: Text(
                      _isSearching
                          ? localizations.translate('nothing_found')
                          : localizations.translate('no_money_income'),
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
                      return MoneyIncomeCard(
                        document: currentData[index],
                        onUpdate: () {
                          _moneyIncomeBloc.add(AddMoneyIncome());
                        },
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

              switch (value) {
                case 'client_payment':
                  targetScreen = const MoneyIncomeFromClient();
                  break;
                case 'cash_register_transfer':
                  targetScreen = const MoneyIncomeAnotherCashRegister();
                  break;
                case 'other_income':
                  targetScreen = const MoneyIncomeOtherIncome();
                  break;
                case 'supplier_return':
                  targetScreen = const MoneyIncomeSupplierReturn();
                  break;
                default:
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
              final localizations = AppLocalizations.of(context)!;

              return [
                PopupMenuItem<String>(
                  value: 'client_payment',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: Color(0xff1E2E52),
                        size: 24,
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
                        size: 24,
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
                  value: 'other_income',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_circle_outline,
                        color: Color(0xff1E2E52),
                        size: 24,
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
                  value: 'supplier_return',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.keyboard_return,
                        color: Color(0xff1E2E52),
                        size: 24,
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
