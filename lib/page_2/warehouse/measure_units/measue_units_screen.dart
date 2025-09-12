import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/warehouse/measure_units/add_measure_unit_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/measure_units/measure_unit_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
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
  late MeasureUnitsBloc _clientSaleBloc;
  bool _isInitialLoad = true;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedMax) {
      setState(() {
        _isLoadingMore = true;
      });
      _clientSaleBloc.add(FetchMeasureUnits());
    }
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    _currentFilters['query'] = query;
    _clientSaleBloc.add(FetchMeasureUnits());
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _currentFilters = {};
      _isInitialLoad = true;
      _hasReachedMax = false;
    });
    _clientSaleBloc.add(const FetchMeasureUnits());
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return BlocProvider(
      create: (_) =>
          MeasureUnitsBloc(ApiService())..add(const FetchMeasureUnits()),
      child: Scaffold(
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: CustomAppBarPage2(
            title: localizations!.translate('units_of_measurement') ??
                'Единицы измерения',
            showSearchIcon: true,
            showFilterIcon: false,
            onChangedSearchInput: _onSearch,
            textEditingController: _searchController,
            focusNode: _focusNode,
            clearButtonClick: (value) {
              if (!value) {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
                _clientSaleBloc.add(const FetchMeasureUnits());
              }
            },
            onClickProfileAvatar: () {},
            clearButtonClickFiltr: (bool p1) {},
            currentFilters: {},
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMeasureUnitScreen(),
                ),
              ).then((_) {
                _clientSaleBloc.add(const FetchMeasureUnits());
              });
            }
          },
          backgroundColor: const Color(0xff1E2E52),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: BlocBuilder<MeasureUnitsBloc, MeasureUnitsState>(
          builder: (context, state) {
            if (state is MeasureUnitsLoading || state is MeasureUnitsInitial) {
              return Center(
                child: PlayStoreImageLoading(
                  size: 80.0,
                  duration: Duration(milliseconds: 1000),
                ),
              );
            } else if (state is MeasureUnitsLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<MeasureUnitsBloc>()
                      .add(const RefreshMeasureUnits());
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: state.units.length,
                  itemBuilder: (context, index) {
                    final MeasureUnitModel unit = state.units[index];
                    return MeasureUnitCard(supplier: unit);
                  },
                ),
              );
            } else if (state is MeasureUnitsEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<MeasureUnitsBloc>()
                      .add(const RefreshMeasureUnits());
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 100),
                    Center(child: Text('No measure units found')),
                  ],
                ),
              );
            } else if (state is MeasureUnitsError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error: ${state.message}',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<MeasureUnitsBloc>()
                              .add(const FetchMeasureUnits());
                        },
                        child: const Text('Retry'),
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
