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
  late PriceTypeScreenBloc priceType;

  @override
  initState() {
    priceType = PriceTypeScreenBloc(_apiService)..add(FetchPriceType());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return BlocProvider.value(
      value: priceType,
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            forceMaterialTransparency: true,
            title: CustomAppBarPage2(
              title:  AppLocalizations.of(context)!.translate('price_type') ?? 'Типы цен',
              showSearchIcon: true,
              showFilterIcon: false,
              onChangedSearchInput: (String value) {
                if (value.isNotEmpty) {
                  // _isSearching = true;
                  // _currentFilters['query'] = value;
                  // _clientSaleBloc.add(FetchClientSales(
                  //   forceRefresh: true,
                  //   filters: _currentFilters,
                  // ));
                } else {
                  // _isSearching = false;
                  // _currentFilters.remove('query');
                  // _clientSaleBloc
                  //     .add(const FetchClientSales(forceRefresh: true));
                }
              },
              textEditingController: TextEditingController(),
              focusNode: FocusNode(),
              clearButtonClick: (value) {},
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
                    builder: (context) => AddPriceTypeScreen(),
                  ),
                ).then((_) {
                  priceType.add(FetchPriceType());
                });
              }
            },
            backgroundColor: const Color(0xff1E2E52),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: BlocBuilder<PriceTypeScreenBloc, PriceTypeState>(
            builder: (context, state) {
              if (state is PriceTypeLoading) {
                return Center(
                  child: PlayStoreImageLoading(
                    size: 80.0,
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              } else if (state is PriceTypeLoaded) {
                final suppliers = state.priceTypes;
                return RefreshIndicator(
                  onRefresh: () {
                    priceType.add(FetchPriceType());
                    return Future.value();
                  },
                  child: ListView.builder(
                    itemCount: suppliers.length,
                    itemBuilder: (context, index) {
                      final supplier = suppliers[index];
                      return PriceTypeCard(
                        supplier: supplier,
                        onDelete: () {
                          priceType.add(DeletePriceType(supplier.id));
                        },
                      );
                    },
                  ),
                );
              } else if (state is PriceTypeError) {
                return Center(child: Text('Error: ${state.message}'));
              }
              return const Center(child: Text('No data'));
            },
          )),
    );
  }
}
