import 'package:crm_task_manager/bloc/income/add/add_income_bloc.dart';
import 'package:crm_task_manager/page_2/money/money_references/income/add_income_screen.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bloc/income/income_bloc.dart';
import '../../../../bloc/income/edit/edit_income_bloc.dart';
import '../../../../custom_widget/custom_app_bar_page_2.dart';
import '../../../../custom_widget/custom_button.dart';
import '../../../../models/money/income_model.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../screens/profile/profile_screen.dart';
import 'edit_income_screen.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool isClickAvatarIcon = false;

  @override
  void initState() {
    super.initState();
    context.read<IncomeBloc>().add(const FetchIncomes());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && !context.read<IncomeBloc>().state.hasReachedMax) {
      context.read<IncomeBloc>().add(const LoadMoreIncomes());
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
        title: CustomAppBarPage2(
          title: isClickAvatarIcon
              ? AppLocalizations.of(context)?.translate('appbar_settings') ?? 'Настройки'
              : AppLocalizations.of(context)?.translate('incomes') ?? 'Доходы',
          onClickProfileAvatar: () {
            setState(() {
              isClickAvatarIcon = !isClickAvatarIcon;
            });
          },
          clearButtonClickFiltr: (isSearching) {},
          showSearchIcon: false,
          showFilterIcon: false,
          showFilterOrderIcon: false,
          onChangedSearchInput: (input) {},
          textEditingController: TextEditingController(),
          focusNode: FocusNode(),
          clearButtonClick: (isSearching) {},
          currentFilters: {},
        ),
      ),
      body: isClickAvatarIcon ?
          ProfileScreen() :
          BlocBuilder<IncomeBloc, IncomeState>(
        builder: (context, state) {
          if (state.status == IncomeStatus.initialLoading) {
            return Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: const Duration(milliseconds: 1000),
              ),
            );
          } else if (state.status == IncomeStatus.initialError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Ошибка загрузки'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      return context
                          .read<IncomeBloc>()
                          .add(const FetchIncomes());
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          } else if (state.status == IncomeStatus.initialLoaded ||
              state.status == IncomeStatus.loadingMore) {
            final incomes = state.incomes;
            if (incomes.isEmpty) {
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
                    .read<IncomeBloc>()
                    .add(const FetchIncomes());
              },
              child: ListView.builder(
                controller: _scrollController,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: incomes.length +
                    (state.status == IncomeStatus.loadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= incomes.length) {
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

                  final data = incomes[index];
                  return _buildIncomeCard(data);
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
        onPressed: _navigateToAddIncome,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildIncomeCard(IncomeModel data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _navigateToEditIncome(data);
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

  void _navigateToAddIncome() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => AddIncomeBloc(),
          child: AddIncomeScreen(),
        ),
      ),
    );

    if (result == true) {
      context.read<IncomeBloc>().add(const FetchIncomes());
    }
  }

  void _navigateToEditIncome(IncomeModel data) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => EditIncomeBloc(),
          child: EditIncomeScreen(
            initialData: data,
          ),
        ),
      ),
    );

    if (result == true) {
      context.read<IncomeBloc>().add(const FetchIncomes());
    }
  }

  void _showDeleteConfirmation(
      IncomeModel data, BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              AppLocalizations.of(context)?.translate('delete_income') ?? 'Удалить доход',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
          content: Text(
            '${AppLocalizations.of(context)?.translate('delete_income_confirm') ?? 'Вы уверены, что хотите удалить доход'} "${data.name}"?',
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
                      // Use parentContext instead of context to access the IncomeBloc
                      parentContext
                          .read<IncomeBloc>()
                          .add(DeleteIncome(data.id));
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
