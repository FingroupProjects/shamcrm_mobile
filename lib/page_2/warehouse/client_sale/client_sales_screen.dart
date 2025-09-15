import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/client_sale/bloc/client_sale_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/incoming_event.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/page_2/warehouse/client_sale/client_sales_card.dart';
import 'package:crm_task_manager/page_2/warehouse/client_sale/create_clien_sales_document_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/incoming_card.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/incoming_document_create_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ClientSaleScreen extends StatefulWidget {
  const ClientSaleScreen({super.key, this.organizationId});
  final int? organizationId;

  @override
  State<ClientSaleScreen> createState() => _ClientSaleScreenState();
}

class _ClientSaleScreenState extends State<ClientSaleScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  Map<String, dynamic> _currentFilters = {};
  late ClientSaleBloc _clientSaleBloc;
  bool _isInitialLoad = true;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _clientSaleBloc.close();
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
      _clientSaleBloc.add(FetchClientSales(
        forceRefresh: false,
        filters: _currentFilters,
      ));
    }
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    _currentFilters['query'] = query;
    _clientSaleBloc.add(FetchClientSales(
      forceRefresh: true,
      filters: _currentFilters,
    ));
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _currentFilters = {};
      _isInitialLoad = true;
      _hasReachedMax = false;
    });
    _clientSaleBloc.add(const FetchClientSales(forceRefresh: true));
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void initState() {
    super.initState();
    _clientSaleBloc = ClientSaleBloc(ApiService())
      ..add(const FetchClientSales(forceRefresh: true));
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return BlocProvider.value(
      value: _clientSaleBloc,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateClienSalesDocumentScreen(
                      organizationId: widget.organizationId),
                ),
              ).then((_) {
                _clientSaleBloc.add(const FetchClientSales(forceRefresh: true));
              });
            }
          },
          backgroundColor: const Color(0xff1E2E52),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: CustomAppBarPage2(
            title: localizations!.translate('appbar_client_sales') ??
                'Реализация клиент',
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
                _clientSaleBloc.add(const FetchClientSales(forceRefresh: true));
              }
            },
            onClickProfileAvatar: () {},
            clearButtonClickFiltr: (bool p1) {},
            currentFilters: {},
          ),
        ),
        body: BlocListener<ClientSaleBloc, ClientSaleState>(
          listener: (context, state) {
            if (state is ClientSaleLoaded) {
              setState(() {
                _hasReachedMax = state.hasReachedMax;
                _isInitialLoad = false;
                _isLoadingMore = false;
              });
            } else if (state is ClientSaleError) {
              setState(() {
                _isInitialLoad = false;
                _isLoadingMore = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          child: BlocBuilder<ClientSaleBloc, ClientSaleState>(
            builder: (context, state) {
              if (state is ClientSaleLoading) {
                return Center(
                  child: PlayStoreImageLoading(
                    size: 80.0,
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              }

              final currentData = state is ClientSaleLoaded ? state.data : [];

              if (currentData.isEmpty && state is ClientSaleLoaded) {
                return Center(
                  child: Text(
                    _isSearching
                        ? localizations.translate('nothing_found') ??
                            'Ничего не найдено'
                        : localizations.translate('no_incoming') ??
                            'Нет приходов',
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
                onRefresh: _onRefresh,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: currentData.length + (_hasReachedMax ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (index >= currentData.length) {
                      return _isLoadingMore
                          ? Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: PlayStoreImageLoading(
                                  size: 80.0,
                                  duration: Duration(milliseconds: 1000),
                                ),
                              ),
                            )
                          : const SizedBox.shrink();
                    }
                    return ClientSalesCard(
                      document: currentData[index],
                      onUpdate: () {
                        _clientSaleBloc
                            .add(const FetchClientSales(forceRefresh: true));
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
