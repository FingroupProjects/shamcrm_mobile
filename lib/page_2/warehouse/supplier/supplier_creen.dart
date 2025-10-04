import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/models/page_2/supplier_model.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier/add_supplier_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/supplier/supllier_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
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

  // НОВОЕ: Флаги прав доступа
  bool _hasCreatePermission = false;
  bool _hasUpdatePermission = false;
  bool _hasDeletePermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _supplierBloc = SupplierBloc(_apiService)..add(FetchSupplier());
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
    _supplierBloc.close();
    super.dispose();
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
            title: localizations?.translate('suppliers') ?? 'Поставщики',
            showSearchIcon: true,
            showFilterIcon: false,
            showFilterOrderIcon: false,
            onChangedSearchInput: (String value) {
              // Здесь можно добавить логику поиска
            },
            textEditingController: _searchController,
            focusNode: _focusNode,
            clearButtonClick: (value) {},
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
                    ).then((_) {
                      _supplierBloc.add(FetchSupplier());
                    });
                  }
                },
                backgroundColor: const Color(0xff1E2E52),
                child: const Icon(Icons.add, color: Colors.white),
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
                return Center(
                  child: Text(
                    localizations?.translate('no_suppliers') ?? 'Нет поставщиков',
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
                  _supplierBloc.add(FetchSupplier());
                  return Future.value();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = suppliers[index];
                    // НОВОЕ: Передаём права в карточку
                    return SupplierCard(
                      supplier: supplier,
                      hasUpdatePermission: _hasUpdatePermission,
                      hasDeletePermission: _hasDeletePermission,
                      onUpdate: () {
                        _supplierBloc.add(FetchSupplier());
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
                          _supplierBloc.add(FetchSupplier());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff1E2E52),
                          foregroundColor: Colors.white,
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