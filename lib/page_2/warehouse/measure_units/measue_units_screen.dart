import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/warehouse/measure_units/add_measure_unit_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/measure_units/measure_unit_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/models/page_2/measure_unit_model.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/measure_units/measure_units_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/measure_units/measure_units_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/measure_units/measure_units_state.dart';

class MeasureUnitsScreen extends StatefulWidget {
  const MeasureUnitsScreen({Key? key}) : super(key: key);

  @override
  State<MeasureUnitsScreen> createState() => _MeasureUnitsScreenState();
}

class _MeasureUnitsScreenState extends State<MeasureUnitsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Map<String, dynamic> _currentFilters = {};
  late MeasureUnitsBloc _measureUnitsBloc;
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
    _measureUnitsBloc = context.read<MeasureUnitsBloc>()
      ..add(const FetchMeasureUnits(query: null));
    _scrollController.addListener(_onScroll);
  }

  // НОВОЕ: Проверка прав доступа
  Future<void> _checkPermissions() async {
    try {
      final create = await _apiService.hasPermission('unit.create');
      final update = await _apiService.hasPermission('unit.update');
      final delete = await _apiService.hasPermission('unit.delete');

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
      final query = _currentFilters['query'] as String?;
      _measureUnitsBloc.add(FetchMeasureUnits(query: query));
    }
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    _currentFilters['query'] = query;
    _measureUnitsBloc
        .add(FetchMeasureUnits(query: query.isNotEmpty ? query : null));
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _currentFilters = {};
      _isInitialLoad = true;
      _hasReachedMax = false;
    });
    _measureUnitsBloc.add(const FetchMeasureUnits(query: null));
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colors = context.appColors;

    return BlocProvider.value(
      value: _measureUnitsBloc,
      child: Scaffold(
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: CustomAppBarPage2(
            title: localizations!.translate('units_of_measurement') ??
                'Единицы измерения',
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
                _measureUnitsBloc.add(const FetchMeasureUnits(query: null));
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
                onPressed: () async {
                  if (mounted) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddMeasureUnitScreen(),
                      ),
                    );

                    if (result == true) {
                      final query = _currentFilters['query'] as String?;
                      _measureUnitsBloc.add(FetchMeasureUnits(query: query));
                    }
                  }
                },
                backgroundColor: colors.buttonPrimaryBg,
                child: Icon(Icons.add, color: colors.buttonPrimaryFg),
              )
            : null,
        body: BlocBuilder<MeasureUnitsBloc, MeasureUnitsState>(
          builder: (context, state) {
            if (state is MeasureUnitsLoading || state is MeasureUnitsInitial) {
              return Center(
                child: PlayStoreImageLoading(
                  size: 80.0,
                  duration: const Duration(milliseconds: 1000),
                ),
              );
            } else if (state is MeasureUnitsLoaded) {
              if (state.units.isEmpty) {
                return Center(
                  child: Text(
                    _isSearching
                        ? (localizations.translate('nothing_found') ??
                            'Ничего не найдено')
                        : (localizations.translate('no_measure_units') ??
                            'Нет единиц измерения'),
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                color: colors.buttonPrimaryBg,
                backgroundColor: colors.backgroundPrimary,
                onRefresh: () async {
                  final query = _currentFilters['query'] as String?;
                  context
                      .read<MeasureUnitsBloc>()
                      .add(RefreshMeasureUnits(query: query));
                },
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: state.units.length,
                  itemBuilder: (context, index) {
                    final MeasureUnitModel unit = state.units[index];
                    // НОВОЕ: Передаём права в карточку
                    return MeasureUnitCard(
                      supplier: unit,
                      hasUpdatePermission: _hasUpdatePermission,
                      hasDeletePermission: _hasDeletePermission,
                      onUpdate: () {
                        final query = _currentFilters['query'] as String?;
                        _measureUnitsBloc.add(FetchMeasureUnits(query: query));
                      },
                    );
                  },
                ),
              );
            } else if (state is MeasureUnitsEmpty) {
              return Center(
                child: Text(
                  _isSearching
                      ? (localizations.translate('nothing_found') ??
                          'Ничего не найдено')
                      : (localizations.translate('no_measure_units') ??
                          'Нет единиц измерения'),
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              );
            } else if (state is MeasureUnitsError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Error: ${state.message}',
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
                          context
                              .read<MeasureUnitsBloc>()
                              .add(FetchMeasureUnits(query: query));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.buttonPrimaryBg,
                          foregroundColor: colors.buttonPrimaryFg,
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
