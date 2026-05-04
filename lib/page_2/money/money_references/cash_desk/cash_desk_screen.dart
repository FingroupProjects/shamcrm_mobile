import 'package:crm_task_manager/api/service/api_service.dart';
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
    context.read<CashDeskBloc>().add(const FetchCashRegisters());
    _scrollController.addListener(_onScroll);
  }

  // НОВОЕ: Проверка прав доступа
  Future<void> _checkPermissions() async {
    try {
      final create = await _apiService.hasPermission('cash_register.create');
      final update = await _apiService.hasPermission('cash_register.update');
      final delete = await _apiService.hasPermission('cash_register.delete');

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

  void _onSearch(String input) {
    final query = input.trim().isEmpty ? null : input.trim();
    context.read<CashDeskBloc>().add(SearchCashRegisters(query));
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
              context.read<CashDeskBloc>().add(const SearchCashRegisters(null));
            }
          },
          currentFilters: {},
        ),
      ),
      body: isClickAvatarIcon
          ? ProfileScreen()
          : BlocBuilder<CashDeskBloc, CashDeskState>(
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
                            final currentState = context.read<CashDeskBloc>().state;
                            final currentQuery = currentState.searchQuery;
                            context.read<CashDeskBloc>().add(FetchCashRegisters(query: currentQuery));
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
                } else if (state.status == CashDeskStatus.initialLoaded ||
                    state.status == CashDeskStatus.loadingMore) {
                  final cashRegisters = state.cashRegisters;
                  if (cashRegisters.isEmpty) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)?.translate('no_cash_registers') ?? 'Нет касс',
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
                      final currentState = context.read<CashDeskBloc>().state;
                      final currentQuery = currentState.searchQuery;
                      context.read<CashDeskBloc>().add(FetchCashRegisters(query: currentQuery));
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: cashRegisters.length +
                          (state.status == CashDeskStatus.loadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= cashRegisters.length) {
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
      // ИЗМЕНЕНО: Показываем FAB только если есть право на создание
      floatingActionButton: _hasCreatePermission
          ? FloatingActionButton(
              backgroundColor: const Color(0xff1E2E52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: _navigateToAddReference,
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            )
          : null,
    );
  }

  Widget _buildCashRegisterCard(CashRegisterModel data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          // ИЗМЕНЕНО: Открываем редактирование только если есть право
          onTap: _hasUpdatePermission
              ? () {
                  _navigateToEditReference(data);
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
      // Сохраняем текущий поисковый запрос
      final currentState = context.read<CashDeskBloc>().state;
      final currentQuery = currentState.searchQuery;
      context.read<CashDeskBloc>().add(FetchCashRegisters(query: currentQuery));
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
      // Сохраняем текущий поисковый запрос
      final currentState = context.read<CashDeskBloc>().state;
      final currentQuery = currentState.searchQuery;
      context.read<CashDeskBloc>().add(FetchCashRegisters(query: currentQuery));
    }
  }

  void _showDeleteConfirmation(CashRegisterModel data, BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              AppLocalizations.of(context)?.translate('delete_reference') ?? 'Удалить справочник',
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
          content: Text(
            AppLocalizations.of(context)?.translate('confirm_delete_reference') ??
                'Вы уверены, что хотите удалить справочник?',
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
                      parentContext.read<CashDeskBloc>().add(DeleteCashDesk(data.id));
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