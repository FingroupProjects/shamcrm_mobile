import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/price_type/bloc/price_type_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/price_type/bloc/price_type_state.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/models/page_2/price_type_model.dart';

import 'package:crm_task_manager/models/page_2/supplier_model.dart';
import 'package:crm_task_manager/page_2/warehouse/price_type/pricetype_card.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier/add_supplier_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier/supllier_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PriceTypeScreen extends StatefulWidget {
  const PriceTypeScreen({super.key});

  @override
  State<PriceTypeScreen> createState() => _PriceTypeScreenState();
}

class _PriceTypeScreenState extends State<PriceTypeScreen> {
  List<PriceTypeModel> suppliers = [];

  final ApiService _apiService = ApiService();
  late SupplierBloc _supplierBloc;
  getSupliers() async {
    suppliers = await _apiService.getPriceTypes();
    setState(() {});
  }

  @override
  initState() {
    _supplierBloc = SupplierBloc(_apiService)..add(FetchSupplier());
    super.initState();
    getSupliers();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return BlocProvider.value(
      value: _supplierBloc,
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            forceMaterialTransparency: true,
            title: CustomAppBarPage2(
              title: 'Поставщики',
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
                    builder: (context) => AddSupplierScreen(),
                  ),
                ).then((_) {
                  _supplierBloc.add(FetchSupplier());
                });
              }
            },
            backgroundColor: const Color(0xff1E2E52),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: BlocBuilder<PriceTypeBloc, PriceTypeState>(
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
                    _supplierBloc.add(FetchSupplier());
                    return Future.value();
                  },
                  child: ListView.builder(
                    itemCount: suppliers.length,
                    itemBuilder: (context, index) {
                      final supplier = suppliers[index];
                      return PriceTypeCard(
                        supplier: supplier,
                        onDelete: () {
                          _supplierBloc.add(DeleteSupplier(supplier.id));
                          ;
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
