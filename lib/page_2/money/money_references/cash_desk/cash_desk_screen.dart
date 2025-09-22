import 'package:crm_task_manager/bloc/cash_desk/add/add_cash_desk_bloc.dart';
import 'package:crm_task_manager/page_2/money/money_references/cash_desk/add_cash_desk_screen.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bloc/cash_desk/cash_desk_bloc.dart';
import '../../../../bloc/cash_desk/edit/edit_cash_desk_bloc.dart';
import '../../../../custom_widget/custom_app_bar_page_2.dart';
import '../../../../custom_widget/custom_button.dart';
import '../../../../models/money/cash_register_model.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../screens/profile/profile_screen.dart';
import 'edit_cash_desk_screen.dart';

class CashDeskScreen extends StatefulWidget {
  const CashDeskScreen({super.key});

  @override
  State<CashDeskScreen> createState() => _CashDeskScreenState();
}

class _CashDeskScreenState extends State<CashDeskScreen> {
  final ScrollController _scrollController = ScrollController();
  bool isClickAvatarIcon = false;

  @override
  void initState() {
    super.initState();
    context.read<CashDeskBloc>().add(const FetchCashRegisters());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && !context.read<CashDeskBloc>().state.hasReachedMax) {
      context.read<CashDeskBloc>().add(const LoadMoreCashRegisters());
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
              : AppLocalizations.of(context)?.translate('cash_desk') ?? 'Касса',
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
          BlocBuilder<CashDeskBloc, CashDeskState>(
        builder: (context, state) {
          if (state.status == CashDeskStatus.initialLoading) {
            return Center(
              child: PlayStoreImageLoading(
                size: 80.0,
                duration: const Duration(milliseconds: 1000),
              ),
            );
          } else if (state.status == CashDeskStatus.initialError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)?.translate('error_loading') ?? 'Ошибка загрузки'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      return context
                          .read<CashDeskBloc>()
                          .add(const FetchCashRegisters());
                    },
                    child: Text(AppLocalizations.of(context)?.translate('retry') ?? 'Повторить'),
                  ),
                ],
              ),
            );
          } else if (state.status == CashDeskStatus.initialLoaded ||
              state.status == CashDeskStatus.loadingMore) {
            final cashRegisters = state.cashRegisters;
            if (cashRegisters.isEmpty) {
              return Center(
                child: Text(
                  AppLocalizations.of(context)?.translate('no_data') ?? 'Нет данных',
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
                    .read<CashDeskBloc>()
                    .add(const FetchCashRegisters());
              },
              child: ListView.builder(
                controller: _scrollController,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: cashRegisters.length +
                    (state.status == CashDeskStatus.loadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= cashRegisters.length) {
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

                  final data = cashRegisters[index];
                  return _buildCashRegisterCard(data);
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
        onPressed: _navigateToAddReference,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildCashRegisterCard(CashRegisterModel data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _navigateToEditReference(data);
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

  void _navigateToAddReference() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => AddCashDeskBloc(),
          child: AddCashDesk(),
        ),
      ),
    );

    if (result == true) {
      context.read<CashDeskBloc>().add(const FetchCashRegisters());
    }
  }

  void _navigateToEditReference(CashRegisterModel data) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => EditCashDeskBloc(),
          child: EditCashDesk(
            initialData: data,
          ),
        ),
      ),
    );

    if (result == true) {
      context.read<CashDeskBloc>().add(const FetchCashRegisters());
    }
  }

  void _showDeleteConfirmation(
      CashRegisterModel data, BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              AppLocalizations.of(context)?.translate('delete_reference') ?? 'Удалить справочник',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
          content: Text(
            AppLocalizations.of(context)?.translate('confirm_delete_reference') ?? 'Вы уверены, что хотите удалить справочник',
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
                      // Use parentContext instead of context to access the CashDeskBloc
                      parentContext
                          .read<CashDeskBloc>()
                          .add(DeleteCashDesk(data.id));
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