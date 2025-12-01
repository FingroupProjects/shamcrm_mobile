import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/price_type/bloc/price_type_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/price_type/bloc/price_type_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/price_type/bloc/price_type_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/warehouse/price_type/add_pricetype_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/price_type/pricetype_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PriceTypeScreen extends StatefulWidget {
  const PriceTypeScreen({super.key});

  @override
  State<PriceTypeScreen> createState() => _PriceTypeScreenState();
}

class _PriceTypeScreenState extends State<PriceTypeScreen> {
  final ApiService _apiService = ApiService();
  late PriceTypeScreenBloc _priceTypeBloc;
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
    _priceTypeBloc = context.read<PriceTypeScreenBloc>()..add(const FetchPriceType(query: null));
  }

  // НОВОЕ: Проверка прав доступа
  Future<void> _checkPermissions() async {
    try {
      final create = await _apiService.hasPermission('price_type.create');
      final update = await _apiService.hasPermission('price_type.update');
      final delete = await _apiService.hasPermission('price_type.delete');

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
    debugPrint('PriceTypeScreen: Поиск типов цен с запросом: $query');
    
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    _currentFilters['query'] = query;
    _priceTypeBloc.add(FetchPriceType(query: query.isNotEmpty ? query : null));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return BlocProvider.value(
      value: _priceTypeBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: CustomAppBarPage2(
            title: localizations.translate('price_type') ?? 'Типы цен',
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
                _priceTypeBloc.add(const FetchPriceType(query: null));
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
                        builder: (context) => AddPriceTypeScreen(),
                      ),
                    ).then((_) {
                      final query = _currentFilters['query'] as String?;
                      _priceTypeBloc.add(FetchPriceType(query: query));
                    });
                  }
                },
                backgroundColor: const Color(0xff1E2E52),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        body: BlocBuilder<PriceTypeScreenBloc, PriceTypeState>(
          builder: (context, state) {
            if (state is PriceTypeLoading) {
              return Center(
                child: PlayStoreImageLoading(
                  size: 80.0,
                  duration: const Duration(milliseconds: 1000),
                ),
              );
            } else if (state is PriceTypeLoaded) {
              final priceTypes = state.priceTypes;

              if (priceTypes.isEmpty) {
                return Center(
                  child: Text(
                    _isSearching
                        ? (localizations.translate('nothing_found') ?? 'Ничего не найдено')
                        : (localizations.translate('no_price_types') ?? 'Нет типов цен'),
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
                onRefresh: () {
                  final query = _currentFilters['query'] as String?;
                  _priceTypeBloc.add(FetchPriceType(query: query));
                  return Future.value();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: priceTypes.length,
                  itemBuilder: (context, index) {
                    final priceTypeItem = priceTypes[index];
                    // НОВОЕ: Передаём права в карточку
                    return PriceTypeCard(
                      priceType: priceTypeItem,
                      hasUpdatePermission: _hasUpdatePermission,
                      hasDeletePermission: _hasDeletePermission,
                      onUpdate: () {
                        final query = _currentFilters['query'] as String?;
                        _priceTypeBloc.add(FetchPriceType(query: query));
                      },
                    );
                  },
                ),
              );
            } else if (state is PriceTypeError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${state.message}',
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
                          final query = _currentFilters['query'] as String?;
                          _priceTypeBloc.add(FetchPriceType(query: query));
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
            return Center(
              child: Text(
                localizations.translate('no_data') ?? 'Нет данных',
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff99A4BA),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}