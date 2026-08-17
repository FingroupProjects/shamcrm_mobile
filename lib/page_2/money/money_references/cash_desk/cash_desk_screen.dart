import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/cash_desk/add/add_cash_desk_bloc.dart';
import 'package:crm_task_manager/bloc/cash_desk/edit/edit_cash_desk_bloc.dart';
import 'package:crm_task_manager/bloc/cash_desk/cash_desk_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/money/cash_register_model.dart';
import 'package:crm_task_manager/page_2/money/money_references/cash_desk/add_cash_desk_screen.dart';
import 'package:crm_task_manager/page_2/money/money_references/cash_desk/edit_cash_desk_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/helpful_empty_state.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CashDeskScreen extends StatefulWidget {
  const CashDeskScreen({super.key});

  @override
  State<CashDeskScreen> createState() => _CashDeskScreenState();
}

class _CashDeskScreenState extends State<CashDeskScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ApiService _apiService = ApiService();

  bool isClickAvatarIcon = false;
  bool _hasCreatePermission = false;
  bool _hasUpdatePermission = false;
  bool _hasDeletePermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    context.read<CashDeskBloc>().add(const FetchCashRegisters());
    _scrollController.addListener(_onScroll);
  }

  Future<void> _checkPermissions() async {
    try {
      final create = await _apiService.hasPermission('cash_register.create');
      final update = await _apiService.hasPermission('cash_register.update');
      final delete = await _apiService.hasPermission('cash_register.delete');
      if (!mounted) return;
      setState(() {
        _hasCreatePermission = create;
        _hasUpdatePermission = update;
        _hasDeletePermission = delete;
      });
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
    return _scrollController.offset >= (maxScroll * 0.9);
  }

  void _onSearch(String input) {
    final query = input.trim().isEmpty ? null : input.trim();
    context.read<CashDeskBloc>().add(SearchCashRegisters(query));
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
              : AppLocalizations.of(context)?.translate('cash_desk') ?? 'Касса',
          onClickProfileAvatar: () {
            setState(() => isClickAvatarIcon = !isClickAvatarIcon);
          },
          clearButtonClickFiltr: (_) {},
          showSearchIcon: !isClickAvatarIcon,
          showFilterIcon: false,
          showFilterOrderIcon: false,
          onChangedSearchInput: _onSearch,
          textEditingController: _searchController,
          focusNode: _searchFocusNode,
          clearButtonClick: (isSearching) {
            if (!isSearching) {
              setState(() => _searchController.clear());
              context.read<CashDeskBloc>().add(const SearchCashRegisters(null));
            }
          },
          currentFilters: const {},
        ),
      ),
      body: isClickAvatarIcon
          ? const ProfileScreen()
          : BlocBuilder<CashDeskBloc, CashDeskState>(
              builder: (context, state) {
                if (state.status == CashDeskStatus.initialLoading) {
                  return Center(
                    child: PlayStoreImageLoading(
                      size: 80.0,
                      duration: const Duration(milliseconds: 1000),
                    ),
                  );
                }

                if (state.status == CashDeskStatus.initialError) {
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
                            final currentQuery =
                                context.read<CashDeskBloc>().state.searchQuery;
                            context
                                .read<CashDeskBloc>()
                                .add(FetchCashRegisters(query: currentQuery));
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
                }

                if (state.status == CashDeskStatus.initialLoaded ||
                    state.status == CashDeskStatus.loadingMore) {
                  final cashRegisters = state.cashRegisters;
                  if (cashRegisters.isEmpty) {
                    final l10n = AppLocalizations.of(context)!;
                    final hasQuery =
                        (state.searchQuery ?? '').trim().isNotEmpty;
                    return hasQuery
                        ? HelpfulEmptyState.search(l10n)
                        : HelpfulEmptyState.section(
                            l10n: l10n,
                            icon: Icons.point_of_sale_outlined,
                            titleKey: 'empty_cash_desk_title',
                            subtitleKey: 'empty_cash_desk_subtitle',
                          );
                  }

                  return RefreshIndicator(
                    color: colors.buttonPrimaryBg,
                    backgroundColor: colors.surfacePrimary,
                    onRefresh: () async {
                      final currentQuery =
                          context.read<CashDeskBloc>().state.searchQuery;
                      context
                          .read<CashDeskBloc>()
                          .add(FetchCashRegisters(query: currentQuery));
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
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

                        return _buildCashRegisterCard(
                            cashRegisters[index], colors);
                      },
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
      floatingActionButton: _hasCreatePermission
          ? FloatingActionButton(
              backgroundColor: colors.buttonPrimaryBg,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              onPressed: _navigateToAddReference,
              child: Icon(Icons.add, color: colors.buttonPrimaryFg, size: 32),
            )
          : null,
    );
  }

  Widget _buildCashRegisterCard(CashRegisterModel data, dynamic colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _hasUpdatePermission
              ? () => _navigateToEditReference(data)
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
              children: [
                Expanded(
                  child: Text(
                    data.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (_hasDeletePermission)
                  GestureDetector(
                    onTap: () => _showDeleteConfirmation(data),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 24,
                      color: colors.buttonDangerBg,
                    ),
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
          child: const AddCashDesk(),
        ),
      ),
    );

    if (result == true) {
      final currentQuery = context.read<CashDeskBloc>().state.searchQuery;
      context.read<CashDeskBloc>().add(FetchCashRegisters(query: currentQuery));
    }
  }

  void _navigateToEditReference(CashRegisterModel data) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => EditCashDeskBloc(),
          child: EditCashDesk(initialData: data),
        ),
      ),
    );

    if (result == true) {
      final currentQuery = context.read<CashDeskBloc>().state.searchQuery;
      context.read<CashDeskBloc>().add(FetchCashRegisters(query: currentQuery));
    }
  }

  void _showDeleteConfirmation(CashRegisterModel data) {
    final colors = context.appColors;

    showDialog(
      context: context,
      builder: (dialogContext) {
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
                  AppLocalizations.of(dialogContext)
                          ?.translate('delete_reference') ??
                      'Удалить справочник',
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
            AppLocalizations.of(dialogContext)
                    ?.translate('confirm_delete_reference') ??
                'Вы уверены, что хотите удалить справочник?',
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
              children: [
                Expanded(
                  child: CustomButton(
                    buttonText:
                        AppLocalizations.of(dialogContext)!.translate('cancel'),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    buttonColor: colors.buttonSecondaryBg,
                    textColor: colors.buttonSecondaryFg,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    buttonText:
                        AppLocalizations.of(dialogContext)!.translate('delete'),
                    onPressed: () {
                      context.read<CashDeskBloc>().add(DeleteCashDesk(data.id));
                      Navigator.of(dialogContext).pop();
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
