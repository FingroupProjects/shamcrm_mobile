import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/expense/add/add_expense_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
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
import '../../../../widgets/helpful_empty_state.dart';
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
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: colors.surfacePrimary,
        title: CustomAppBarPage2(
          title: isClickAvatarIcon
              ? AppLocalizations.of(context)?.translate('appbar_settings') ??
                  'Настройки'
              : AppLocalizations.of(context)?.translate('expenses') ??
                  'Расходы',
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
              context
                  .read<ExpenseBloc>()
                  .add(const SearchExpenses(query: null));
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
                          AppLocalizations.of(context)
                                  ?.translate('error_loading') ??
                              'Ошибка загрузки',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Сохраняем текущий поисковый запрос при повторной попытке
                            final currentState =
                                context.read<ExpenseBloc>().state;
                            final currentQuery = currentState.searchQuery;
                            context
                                .read<ExpenseBloc>()
                                .add(FetchExpenses(query: currentQuery));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.buttonPrimaryBg,
                            foregroundColor: colors.buttonPrimaryFg,
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.translate('retry') ??
                                'Повторить',
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (state.status == ExpenseStatus.initialLoaded ||
                    state.status == ExpenseStatus.loadingMore) {
                  final expenses = state.expenses;
                  if (expenses.isEmpty) {
                    final l10n = AppLocalizations.of(context)!;
                    final hasQuery =
                        (state.searchQuery ?? '').trim().isNotEmpty;
                    return hasQuery
                        ? HelpfulEmptyState.search(l10n)
                        : HelpfulEmptyState.section(
                            l10n: l10n,
                            icon: Icons.receipt_long_outlined,
                            titleKey: 'empty_expense_types_title',
                            subtitleKey: 'empty_expense_types_subtitle',
                          );
                  }
                  return RefreshIndicator(
                    color: colors.buttonPrimaryBg,
                    backgroundColor: colors.surfacePrimary,
                    onRefresh: () async {
                      // Сохраняем текущий поисковый запрос при обновлении
                      final currentState = context.read<ExpenseBloc>().state;
                      final currentQuery = currentState.searchQuery;
                      context
                          .read<ExpenseBloc>()
                          .add(FetchExpenses(query: currentQuery));
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      itemCount: expenses.length +
                          (state.status == ExpenseStatus.loadingMore ? 1 : 0),
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
                        return _buildExpenseCard(data, colors);
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
              backgroundColor: colors.buttonPrimaryBg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onPressed: _navigateToAddExpense,
              child: Icon(Icons.add, color: colors.buttonPrimaryFg, size: 32),
            )
          : null,
    );
  }

  Widget _buildExpenseCard(ExpenseModel data, dynamic colors) {
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
              color: colors.surfacePrimary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderSubtle),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                // ИЗМЕНЕНО: Показываем кнопку удаления только если есть право
                if (_hasDeletePermission)
                  GestureDetector(
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 24,
                      color: colors.buttonDangerBg,
                    ),
                    onTap: () {
                      _showDeleteConfirmation(data, context, colors);
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

  void _showDeleteConfirmation(
      ExpenseModel data, BuildContext parentContext, dynamic colors) {
    showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colors.surfacePrimary,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.borderSubtle),
          ),
          title: Center(
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.buttonDangerBg.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: colors.buttonDangerBg,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)?.translate('delete_expense') ??
                      'Удалить расход',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          content: Text(
            '${AppLocalizations.of(context)?.translate('delete_expense_confirm') ?? 'Вы уверены, что хотите удалить расход'} "${data.name}"?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: CustomButton(
                    buttonText:
                        AppLocalizations.of(context)!.translate('cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    buttonColor: colors.buttonSecondaryBg,
                    textColor: colors.buttonSecondaryFg,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    buttonText:
                        AppLocalizations.of(context)!.translate('delete'),
                    onPressed: () {
                      parentContext
                          .read<ExpenseBloc>()
                          .add(DeleteExpense(data.id));
                      Navigator.of(context).pop();
                    },
                    buttonColor: colors.buttonDangerBg,
                    textColor: colors.buttonDangerFg,
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
