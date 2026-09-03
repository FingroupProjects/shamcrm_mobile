import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar_page_2.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/warehouse_document_filter_type.dart';
import 'package:crm_task_manager/models/common/api_exception_model.dart';
import 'package:crm_task_manager/models/page_2/expense_document_model.dart';
import 'package:crm_task_manager/page_2/warehouse/client_sale/clien_sales_document_detail.dart';
import 'package:crm_task_manager/page_2/warehouse/client_sale/client_sales_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/helpful_empty_state.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

class RmkSalesScreen extends StatefulWidget {
  const RmkSalesScreen({super.key});

  @override
  State<RmkSalesScreen> createState() => _RmkSalesScreenState();
}

class _RmkSalesScreenState extends State<RmkSalesScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<ExpenseDocument> _documents = [];
  Map<String, dynamic> _currentFilters = {};
  String? _search;
  int _page = 1;
  bool _isInitialLoad = true;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchSales(forceRefresh: true);
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
      setState(() => _isLoadingMore = true);
      _fetchSales();
    }
  }

  void _onSearch(String query) {
    setState(() {
      _isSearching = query.trim().isNotEmpty;
      _search = query;
      _hasReachedMax = false;
    });
    _fetchSales(forceRefresh: true);
  }

  void _onFilterSelected(Map<String, dynamic> filters) {
    setState(() {
      _currentFilters = Map.from(filters);
      _hasReachedMax = false;
      _isLoadingMore = false;
      _isSearching = false;
      _searchController.clear();
      _search = null;
    });
    _fetchSales(forceRefresh: true);
  }

  void _onResetFilters() {
    setState(() {
      _currentFilters.clear();
      _hasReachedMax = false;
      _isLoadingMore = false;
      _isSearching = false;
      _searchController.clear();
      _search = null;
    });
    _fetchSales(forceRefresh: true);
  }

  Future<void> _onRefresh() async {
    setState(() {
      _hasReachedMax = false;
      _isSearching = false;
      _searchController.clear();
      _search = null;
    });
    _fetchSales(forceRefresh: true);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _fetchSales({bool forceRefresh = false}) async {
    if (forceRefresh) {
      setState(() {
        _page = 1;
        _documents.clear();
        _isInitialLoad = true;
      });
    }

    try {
      final response = await _apiService.getRmkSales(
        page: _page,
        perPage: 20,
        query: _search,
        dateFrom: _currentFilters['date_from'],
        dateTo: _currentFilters['date_to'],
        approved: _currentFilters['approved'] != null
            ? int.tryParse(_currentFilters['approved'].toString())
            : null,
        deleted: _currentFilters['deleted'] != null
            ? int.tryParse(_currentFilters['deleted'].toString())
            : null,
        storageId: _currentFilters['storage_id'] != null
            ? int.tryParse(_currentFilters['storage_id'].toString())
            : null,
      );

      final newData = response.data ?? const <ExpenseDocument>[];
      final hasReachedMax = (response.pagination?.currentPage ?? 1) >=
          (response.pagination?.totalPages ?? 1);

      if (!mounted) return;
      setState(() {
        if (forceRefresh) {
          _documents
            ..clear()
            ..addAll(newData);
        } else {
          _documents.addAll(newData);
        }
        if (!hasReachedMax && newData.isNotEmpty) {
          _page++;
        }
        _hasReachedMax = hasReachedMax;
        _isInitialLoad = false;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isInitialLoad = false;
        _isLoadingMore = false;
      });
      final message = error is ApiException ? error.toString() : '$error';
      showCustomSnackBar(
        context: context,
        message: message,
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colors.surfacePrimary,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBarPage2(
          title: 'Продажи РМК',
          showSearchIcon: true,
          showFilterIcon: false,
          showFilterOrderIcon: false,
          showFilterIncomeIcon: false,
          showFilterIncomingIcon: true,
          warehouseFilterType: WarehouseDocumentFilterType.clientSale,
          onIncomingResetFilters: _onResetFilters,
          onFilterIncomingSelected: _onFilterSelected,
          onChangedSearchInput: _onSearch,
          textEditingController: _searchController,
          focusNode: _focusNode,
          clearButtonClick: (value) {
            if (!value) {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _search = null;
              });
              _fetchSales(forceRefresh: true);
            }
          },
          onClickProfileAvatar: () {},
          clearButtonClickFiltr: (bool p1) {},
          currentFilters: _currentFilters,
        ),
      ),
      body: _isInitialLoad
          ? Center(
              child: PlayStoreImageLoading(
                size: 80,
                duration: const Duration(milliseconds: 1000),
              ),
            )
          : _documents.isEmpty
              ? (_isSearching
                  ? HelpfulEmptyState.search(localizations!)
                  : HelpfulEmptyState.section(
                      l10n: localizations!,
                      icon: Icons.point_of_sale_rounded,
                      titleKey: 'empty_rmk_sales_title',
                      subtitleKey: 'empty_rmk_sales_subtitle',
                    ))
              : RefreshIndicator(
                  color: colors.buttonPrimaryBg,
                  backgroundColor: colors.surfacePrimary,
                  onRefresh: _onRefresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _documents.length + (_hasReachedMax ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index >= _documents.length) {
                        return _isLoadingMore
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: PlayStoreImageLoading(
                                    size: 80,
                                    duration:
                                        const Duration(milliseconds: 1000),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      }

                      final document = _documents[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ClientSalesCard(
                          document: document,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) =>
                                    ClientSalesDocumentDetailsScreen(
                                  documentId: document.id!,
                                  docNumber: document.docNumber ?? 'N/A',
                                  isRmk: true,
                                  hasUpdatePermission: false,
                                  hasDeletePermission: false,
                                  onDocumentUpdated: () {
                                    _fetchSales(forceRefresh: true);
                                  },
                                ),
                              ),
                            );
                          },
                          isSelectionMode: false,
                          isSelected: false,
                          onLongPress: () {},
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
