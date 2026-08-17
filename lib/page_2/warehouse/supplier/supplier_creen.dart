import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier/add_supplier_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier/supllier_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/helpful_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SupplierCreen extends StatefulWidget {
  const SupplierCreen({super.key});

  @override
  State<SupplierCreen> createState() => _SupplierCreenState();
}

class _SupplierCreenState extends State<SupplierCreen> {
  final ApiService _apiService = ApiService();
  late SupplierBloc _supplierBloc;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Map<String, dynamic> _currentFilters = {};

  // НОВОЕ: Флаги прав доступа
  bool _hasCreatePermission = false;
  bool _hasUpdatePermission = false;
  bool _hasDeletePermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _supplierBloc = context.read<SupplierBloc>()
      ..add(FetchSupplier(query: null));
  }

  // НОВОЕ: Проверка прав доступа
  Future<void> _checkPermissions() async {
    try {
      final create = await _apiService.hasPermission('supplier.create');
      final update = await _apiService.hasPermission('supplier.update');
      final delete = await _apiService.hasPermission('supplier.delete');

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
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    debugPrint('SupplierCreen: Поиск поставщиков с запросом: $query');

    setState(() {
      _isSearching = query.isNotEmpty;
    });
    _currentFilters['query'] = query;
    _supplierBloc.add(FetchSupplier(query: query.isNotEmpty ? query : null));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colors = context.appColors;

    return BlocProvider.value(
      value: _supplierBloc,
      child: Scaffold(
        backgroundColor: colors.backgroundPrimary,
        appBar: AppBar(
          forceMaterialTransparency: true,
          backgroundColor: colors.surfacePrimary,
          title: CustomAppBarPage2(
            title: localizations?.translate('suppliers') ?? 'Поставщики',
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
                  _currentFilters.remove('query');
                });
                _supplierBloc.add(FetchSupplier(query: null));
              }
            },
            onClickProfileAvatar: () {},
            clearButtonClickFiltr: (bool p1) {},
            currentFilters: {},
          ),
        ),
        // ИЗМЕНЕНО: Показываем FAB только если есть право на создание
        floatingActionButton: _hasCreatePermission
            ? FloatingActionButton(
                onPressed: () {
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddSupplierScreen(),
                      ),
                    ).then((wasAdded) {
                      // Перезагружаем список только если поставщик был добавлен
                      if (wasAdded == true) {
                        final query = _currentFilters['query'] as String?;
                        _supplierBloc.add(FetchSupplier(query: query));
                      }
                    });
                  }
                },
                backgroundColor: colors.buttonPrimaryBg,
                child: Icon(Icons.add, color: colors.buttonPrimaryFg),
              )
            : null,
        body: BlocBuilder<SupplierBloc, SupplierState>(
          builder: (context, state) {
            if (state is SupplierLoading) {
              return Center(
                child: PlayStoreImageLoading(
                  size: 80.0,
                  duration: const Duration(milliseconds: 1000),
                ),
              );
            } else if (state is SupplierLoaded) {
              final suppliers = state.supplierList;

              if (suppliers.isEmpty) {
                return _isSearching
                    ? HelpfulEmptyState.search(localizations!)
                    : HelpfulEmptyState.section(
                        l10n: localizations!,
                        icon: Icons.local_shipping_outlined,
                        titleKey: 'empty_suppliers_title',
                        subtitleKey: 'empty_suppliers_subtitle',
                        actionKey: _hasCreatePermission
                            ? 'empty_suppliers_action'
                            : null,
                        onAction: _hasCreatePermission
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddSupplierScreen(),
                                  ),
                                ).then((wasAdded) {
                                  if (wasAdded == true) {
                                    final query =
                                        _currentFilters['query'] as String?;
                                    _supplierBloc
                                        .add(FetchSupplier(query: query));
                                  }
                                });
                              }
                            : null,
                      );
              }

              return RefreshIndicator(
                color: colors.buttonPrimaryBg,
                backgroundColor: colors.backgroundPrimary,
                onRefresh: () {
                  final query = _currentFilters['query'] as String?;
                  _supplierBloc.add(FetchSupplier(query: query));
                  return Future.value();
                },
                child: ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];
                    // НОВОЕ: Передаём права в карточку
                    return SupplierCard(
                      supplier: supplier,
                      hasUpdatePermission: _hasUpdatePermission,
                      hasDeletePermission: _hasDeletePermission,
                      onUpdate: () {
                        final query = _currentFilters['query'] as String?;
                        _supplierBloc.add(FetchSupplier(query: query));
                      },
                    );
                  },
                ),
              );
            } else if (state is SupplierError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          final query = _currentFilters['query'] as String?;
                          _supplierBloc.add(FetchSupplier(query: query));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.buttonPrimaryBg,
                          foregroundColor: colors.buttonPrimaryFg,
                        ),
                        child: Text(
                          localizations?.translate('retry') ?? 'Повторить',
                        ),
                      )
                    ],
                  ),
                ),
              );
            }
            return Center(
              child: Text(
                localizations?.translate('no_data') ?? 'Нет данных',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
