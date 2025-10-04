import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/storage/bloc/storage_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/storage/bloc/storage_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/storage/bloc/storage_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/models/page_2/storage_model.dart';
import 'package:crm_task_manager/page_2/warehouse/ware_house/add_warehouse_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/ware_house/warehouse_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WareHouseScreen extends StatefulWidget {
  const WareHouseScreen({Key? key}) : super(key: key);

  @override
  State<WareHouseScreen> createState() => _WareHouseScreenState();
}

class _WareHouseScreenState extends State<WareHouseScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Map<String, dynamic> _currentFilters = {};
  late WareHouseBloc _warehousebloc;
  bool _isInitialLoad = true;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;

  // НОВОЕ: Флаги прав доступа
  bool _hasCreatePermission = false;
  bool _hasUpdatePermission = false;
  bool _hasDeletePermission = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _warehousebloc = context.read<WareHouseBloc>()..add(FetchWareHouse());
    _scrollController.addListener(_onScroll);
  }

  // НОВОЕ: Проверка прав доступа
  Future<void> _checkPermissions() async {
    try {
      final create = await _apiService.hasPermission('storage.create');
      final update = await _apiService.hasPermission('storage.update');
      final delete = await _apiService.hasPermission('storage.delete');

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
    _focusNode.dispose();
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
      _warehousebloc.add(FetchWareHouse());
    }
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    _currentFilters['query'] = query;
    _warehousebloc.add(FetchWareHouse());
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _currentFilters = {};
      _isInitialLoad = true;
      _hasReachedMax = false;
    });
    _warehousebloc.add(FetchWareHouse());
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return BlocProvider(
      create: (_) => WareHouseBloc(ApiService())..add(FetchWareHouse()),
      child: Scaffold(
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: CustomAppBarPage2(
            title: localizations!.translate('warehouse') ?? 'Склад',
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
                _warehousebloc.add(FetchWareHouse());
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddWarehouseScreen(),
                    ),
                  ).then((value) {
                    context.read<WareHouseBloc>().add(FetchWareHouse());
                  });
                },
                backgroundColor: const Color(0xff1E2E52),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        body: BlocBuilder<WareHouseBloc, WareHouseState>(
          builder: (context, state) {
            if (state is WareHouseLoading) {
              return Center(
                child: PlayStoreImageLoading(
                  size: 80.0,
                  duration: const Duration(milliseconds: 1000),
                ),
              );
            } else if (state is WareHouseLoaded) {
              if (state.storages.isEmpty) {
                return Center(
                  child: Text(
                    _isSearching
                        ? (localizations.translate('nothing_found') ?? 'Ничего не найдено')
                        : (localizations.translate('no_warehouses') ?? 'Нет складов'),
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
                  context.read<WareHouseBloc>().add(FetchWareHouse());
                },
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: state.storages.length,
                  itemBuilder: (context, index) {
                    final WareHouse warehouse = state.storages[index];
                    // НОВОЕ: Передаём права в карточку склада
                    return WareHouseCard(
                      warehouse: warehouse,
                      hasUpdatePermission: _hasUpdatePermission,
                      hasDeletePermission: _hasDeletePermission,
                      onUpdate: () {
                        context.read<WareHouseBloc>().add(FetchWareHouse());
                      },
                    );
                  },
                ),
              );
            } else if (state is WareHouseError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Error: ${state.message}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          context.read<WareHouseBloc>().add(FetchWareHouse());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff1E2E52),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          localizations.translate('retry') ?? 'Повторить',
                        ),
                      )
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}