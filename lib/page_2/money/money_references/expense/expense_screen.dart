import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/expense/add/add_expense_bloc.dart';
import 'package:crm_task_manager/page_2/money/money_references/expense/add_expense_screen.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bloc/expense/expense_bloc.dart';
import '../../../../bloc/expense/edit/edit_expense_bloc.dart';
import '../../../../custom_widget/custom_app_bar_page_2.dart';
import '../../../../custom_widget/custom_button.dart';
import '../../../../models/money/expense_model.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../screens/profile/profile_screen.dart';
import 'edit_expense_screen.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool isClickAvatarIcon = false;

  // НОВОЕ: Флаги прав доступа
  bool _hasCreatePermission = false;
  bool _hasUpdatePermission = false;
  bool _hasDeletePermission = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    context.read<ExpenseBloc>().add(const FetchExpenses());
    _scrollController.addListener(_onScroll);
  }

  // НОВОЕ: Проверка прав доступа
  Future<void> _checkPermissions() async {
    try {
      final create = await _apiService.hasPermission('rko_article.create');
      final update = await _apiService.hasPermission('rko_article.update');
      final delete = await _apiService.hasPermission('rko_article.delete');

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
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && !context.read<ExpenseBloc>().state.hasReachedMax) {
      context.read<ExpenseBloc>().add(const LoadMoreExpenses());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _onSearch(String input) {
    final query = input.trim().isEmpty ? null : input.trim();
    context.read<ExpenseBloc>().add(SearchExpenses(query: query));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBarPage2(
          title: isClickAvatarIcon
              ? AppLocalizations.of(context)?.translate('appbar_settings') ?? 'Настройки'
              : AppLocalizations.of(context)?.translate('expenses') ?? 'Расходы',
          onClickProfileAvatar: () {
            setState(() {
              isClickAvatarIcon = !isClickAvatarIcon;
            });
          },
          clearButtonClickFiltr: (isSearching) {},
          showSearchIcon: !isClickAvatarIcon,
          showFilterIcon: false,
          showFilterOrderIcon: false,
          onChangedSearchInput: _onSearch,
          textEditingController: _searchController,
          focusNode: _searchFocusNode,
          clearButtonClick: (isSearching) {
            if (!isSearching) {
              setState(() {
                _searchController.clear();
              });
              context.read<ExpenseBloc>().add(const SearchExpenses(query: null));
            }
          },
          currentFilters: {},
        ),
      ),
      body: isClickAvatarIcon
          ? ProfileScreen()
          : BlocBuilder<ExpenseBloc, ExpenseState>(
              builder: (context, state) {
                if (state.status == ExpenseStatus.initialLoading) {
                  return Center(
                    child: PlayStoreImageLoading(
                      size: 80.0,
                      duration: const Duration(milliseconds: 1000),
                    ),
                  );
                } else if (state.status == ExpenseStatus.initialError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.translate('error_loading') ?? 'Ошибка загрузки',
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Сохраняем текущий поисковый запрос при повторной попытке
                            final currentState = context.read<ExpenseBloc>().state;
                            final currentQuery = currentState.searchQuery;
                            context.read<ExpenseBloc>().add(FetchExpenses(query: currentQuery));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1E2E52),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.translate('retry') ?? 'Повторить',
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (state.status == ExpenseStatus.initialLoaded ||
                    state.status == ExpenseStatus.loadingMore) {
                  final expenses = state.expenses;
                  if (expenses.isEmpty) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)?.translate('no_expenses') ?? 'Нет расходов',
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
                    onRefresh: () async {
                      // Сохраняем текущий поисковый запрос при обновлении
                      final currentState = context.read<ExpenseBloc>().state;
                      final currentQuery = currentState.searchQuery;
                      context.read<ExpenseBloc>().add(FetchExpenses(query: currentQuery));
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: expenses.length + (state.status == ExpenseStatus.loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= expenses.length) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.center,
                            child: PlayStoreImageLoading(
                              size: 80.0,
                              duration: const Duration(milliseconds: 1000),
                            ),
                          );
                        }

                        final data = expenses[index];
                        return _buildExpenseCard(data);
                      },
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
      // ИЗМЕНЕНО: Показываем FAB только если есть право на создание
      floatingActionButton: _hasCreatePermission
          ? FloatingActionButton(
              backgroundColor: const Color(0xff1E2E52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: _navigateToAddExpense,
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            )
          : null,
    );
  }

  Widget _buildExpenseCard(ExpenseModel data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          // ИЗМЕНЕНО: Открываем редактирование только если есть право
          onTap: _hasUpdatePermission
              ? () {
                  _navigateToEditExpense(data);
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xffF2F6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ],
                  ),
                ),
                // ИЗМЕНЕНО: Показываем кнопку удаления только если есть право
                if (_hasDeletePermission)
                  GestureDetector(
                    child: Image.asset(
                      'assets/icons/delete.png',
                      width: 24,
                      height: 24,
                    ),
                    onTap: () {
                      _showDeleteConfirmation(data, context);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => AddExpenseBloc(),
          child: AddExpenseScreen(),
        ),
      ),
    );

    if (result == true) {
      // Сохраняем текущий поисковый запрос
      final currentState = context.read<ExpenseBloc>().state;
      final currentQuery = currentState.searchQuery;
      context.read<ExpenseBloc>().add(FetchExpenses(query: currentQuery));
    }
  }

  void _navigateToEditExpense(ExpenseModel data) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => EditExpenseBloc(),
          child: EditExpenseScreen(
            initialData: data,
          ),
        ),
      ),
    );

    if (result == true) {
      // Сохраняем текущий поисковый запрос
      final currentState = context.read<ExpenseBloc>().state;
      final currentQuery = currentState.searchQuery;
      context.read<ExpenseBloc>().add(FetchExpenses(query: currentQuery));
    }
  }

  void _showDeleteConfirmation(ExpenseModel data, BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              AppLocalizations.of(context)?.translate('delete_expense') ?? 'Удалить расход',
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
          content: Text(
            '${AppLocalizations.of(context)?.translate('delete_expense_confirm') ?? 'Вы уверены, что хотите удалить расход'} "${data.name}"?',
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Color(0xff1E2E52),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: CustomButton(
                    buttonText: AppLocalizations.of(context)!.translate('cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    buttonColor: Colors.red,
                    textColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    buttonText: AppLocalizations.of(context)!.translate('delete'),
                    onPressed: () {
                      parentContext.read<ExpenseBloc>().add(DeleteExpense(data.id));
                      Navigator.of(context).pop();
                    },
                    buttonColor: const Color(0xff1E2E52),
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}