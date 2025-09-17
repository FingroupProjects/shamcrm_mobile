import 'package:crm_task_manager/bloc/expense/add/add_expense_bloc.dart';
import 'package:crm_task_manager/page_2/money/money_references/expense/add_expense_screen.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bloc/expense/expense_bloc.dart';
import '../../../../bloc/expense/edit/edit_expense_bloc.dart';
import '../../../../custom_widget/custom_button.dart';
import '../../../../models/money/expense_model.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import 'edit_expense_screen.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(const FetchExpenses());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        centerTitle: true,
        title: Text(AppLocalizations.of(context)?.translate('expenses') ?? 'Расходы',
            style: const TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52))),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<ExpenseBloc, ExpenseState>(
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
                  const Text('Ошибка загрузки'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      return context
                          .read<ExpenseBloc>()
                          .add(const FetchExpenses());
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          } else if (state.status == ExpenseStatus.initialLoaded ||
              state.status == ExpenseStatus.loadingMore) {
            final expenses = state.expenses;
            if (expenses.isEmpty) {
              return const Center(
                child: Text(
                  'Нет данных',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<ExpenseBloc>()
                    .add(const FetchExpenses());
              },
              child: ListView.builder(
                controller: _scrollController,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: expenses.length +
                    (state.status == ExpenseStatus.loadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= expenses.length) {
                    // Show loading indicator at the bottom
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff1E2E52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: _navigateToAddExpense,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseModel data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _navigateToEditExpense(data);
          },
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
                        'N: ${data.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${AppLocalizations.of(context)?.translate('type') ?? 'Тип'}: ${data.type}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w400,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ],
                  ),
                ),
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
      context.read<ExpenseBloc>().add(const FetchExpenses());
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
      context.read<ExpenseBloc>().add(const FetchExpenses());
    }
  }

  void _showDeleteConfirmation(
      ExpenseModel data, BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              AppLocalizations.of(context)?.translate('delete_expense') ?? 'Удалить расход',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
          content: Text(
            '${AppLocalizations.of(context)?.translate('delete_expense_confirm') ?? 'Вы уверены, что хотите удалить расход'} "${data.name}"?',
            style: TextStyle(
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
                    buttonText:
                    AppLocalizations.of(context)!.translate('cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    buttonColor: Colors.red,
                    textColor: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    buttonText:
                    AppLocalizations.of(context)!.translate('delete'),
                    onPressed: () {
                      // Use parentContext instead of context to access the ExpenseBloc
                      parentContext
                          .read<ExpenseBloc>()
                          .add(DeleteExpense(data.id));
                      Navigator.of(context)
                          .pop(); // Use context for dialog navigation
                    },
                    buttonColor: Color(0xff1E2E52),
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
