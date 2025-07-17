import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_state.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/variant_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class VariantSelectionSheet extends StatefulWidget {
  final Order order;

  const VariantSelectionSheet({required this.order, super.key});

  @override
  State<VariantSelectionSheet> createState() => _VariantSelectionSheetState();
}

class _VariantSelectionSheetState extends State<VariantSelectionSheet> {
  String _searchQuery = '';
  String _selectedFilter = 'Новый';
  String? baseUrl;
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl();
    context.read<VariantBloc>().add(FetchVariants(page: _currentPage));
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initializeBaseUrl() async {
    try {
      final enteredDomainMap = await _apiService.getEnteredDomain();
      String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
      String? enteredDomain = enteredDomainMap['enteredDomain'];

      setState(() {
        baseUrl = 'https://$enteredDomain-back.$enteredMainDomain/storage';
      });
    } catch (error) {
      setState(() {
        baseUrl = 'https://shamcrm.com/storage/';
      });
    }
  }

  void _filterVariants(String query, List<Variant> variants) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreVariants();
    }
  }

  void _loadMoreVariants() {
    final state = context.read<VariantBloc>().state;
    if (state is VariantDataLoaded) {
      setState(() {
        _isLoadingMore = true;
      });
      context
          .read<VariantBloc>()
          .add(FetchMoreVariants(state.currentPage));
    }
  }

  void _updateOrderWithSelectedVariants(List<Variant> variants) {
    final selectedVariants = variants
        .where((variant) => variant.isSelected == true)
        .map((variant) => {
              'variant_id': variant.id, // Изменено на variant_id
              'quantity': variant.quantitySelected ?? 1,
              'price': variant.price ?? 0.0,
            })
        .toList();

    if (selectedVariants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('please_select_variant'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.red,
          elevation: 3,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final currentGoods = widget.order.goods.map((good) => {
              'good_id': good.goodId,
              'quantity': good.quantity,
              'price': good.price,
            }).toList();

    final updatedGoods = [...currentGoods, ...selectedVariants];

    context.read<OrderBloc>().add(UpdateOrder(
          orderId: widget.order.id,
          phone: widget.order.phone,
          leadId: widget.order.lead.id,
          delivery: widget.order.delivery,
          deliveryAddress: widget.order.deliveryAddress ?? '',
          goods: updatedGoods,
          organizationId: 1,
        ));

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchField(),
          const SizedBox(height: 12),
          Expanded(
            child: BlocConsumer<VariantBloc, VariantState>(
              listener: (context, state) {
                if (state is VariantDataLoaded) {
                  setState(() {
                    _isLoadingMore = false;
                    _hasMore = state.pagination.currentPage <
                        state.pagination.totalPages;
                  });
                }
              },
              builder: (context, state) {
                if (state is VariantLoading && _currentPage == 1) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is VariantDataLoaded) {
                  final filteredVariants = _searchQuery.isEmpty
                      ? state.variants
                      : state.variants
                          .where((variant) => variant.fullName
                              ?.toLowerCase()
                              .contains(_searchQuery.toLowerCase()) ?? false)
                          .toList();
                  return _buildVariantList(filteredVariants, state);
                } else if (state is VariantEmpty) {
                  return Center(
                      child: Text(AppLocalizations.of(context)!
                          .translate('no_variants_found')));
                } else if (state is VariantError) {
                  return Center(child: Text(state.message));
                }
                return Center(
                    child: Text(AppLocalizations.of(context)!
                        .translate('loading_data')));
              },
            ),
          ),
          _buildAddButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('add_product'),
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xff1E2E52), size: 24),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (query) {
          final state = context.read<VariantBloc>().state;
          if (state is VariantDataLoaded) {
            _filterVariants(query, state.variants);
          }
        },
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!
              .translate('search_variant_placeholder'),
          hintStyle: TextStyle(
              fontFamily: 'Gilroy', fontSize: 14, color: Color(0xff99A4BA)),
          prefixIcon: Icon(Icons.search, color: Color(0xff99A4BA)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xffE0E7FF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xff4759FF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xffE0E7FF)),
          ),
        ),
      ),
    );
  }

  Widget _buildVariantList(List<Variant> variants, VariantDataLoaded state) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: variants.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == variants.length && _isLoadingMore) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final variant = variants[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      variant.isSelected = !variant.isSelected;
                      if (!variant.isSelected) variant.quantitySelected = 1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildVariantImage(variant),
                        const SizedBox(width: 12),
                        Expanded(child: _buildVariantDetails(variant)),
                        _buildSelectionIndicator(variant),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVariantImage(Variant variant) {
    // Варианты не содержат изображений, используем заглушку
    return SizedBox(
      width: 48,
      height: 48,
      child: Container(
        color: Colors.grey[200],
        child: const Center(
            child: Icon(Icons.image, color: Colors.grey, size: 24)),
      ),
    );
  }

  Widget _buildVariantDetails(Variant variant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          variant.fullName ?? 'Вариант ${variant.id}',
          style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Color(0xff1E2E52)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // const SizedBox(height: 4),
        // Text(
        //   'ID: ${variant.id}',
        //   style: const TextStyle(
        //       fontSize: 12,
        //       fontFamily: 'Gilroy',
        //       fontWeight: FontWeight.w500,
        //       color: Color(0xff99A4BA)),
        // ),
        const SizedBox(height: 4),
        // Отображаем атрибуты варианта
        ...variant.attributeValues.map((attr) => Text(
              '${attr.categoryAttribute?.attribute?.name ?? ''}: ${attr.value}',
              style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w400,
                  color: Color(0xff99A4BA)),
            )),
        if (variant.isSelected) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  AppLocalizations.of(context)!
                      .translate('stock_quantity_details'),
                  style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff99A4BA))),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    color: const Color(0xff1E2E52),
                    onPressed: () {
                      if (variant.quantitySelected > 1)
                        setState(() => variant.quantitySelected--);
                    },
                  ),
                  Text(
                    '${variant.quantitySelected}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff1E2E52)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    color: const Color(0xff1E2E52),
                    onPressed: () => setState(() => variant.quantitySelected++),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSelectionIndicator(Variant variant) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: variant.isSelected
                ? const Color.fromARGB(255, 86, 76, 175)
                : const Color(0xff99A4BA),
            width: 2),
      ),
      child: variant.isSelected
          ? const Icon(Icons.check, color: Color(0xff4CAF50), size: 16)
          : null,
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ElevatedButton(
        onPressed: () {
          final state = context.read<VariantBloc>().state;
          if (state is VariantDataLoaded) {
            _updateOrderWithSelectedVariants(state.variants);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff4759FF),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.translate('add'),
            style: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Colors.white),
          ),
        ),
      ),
    );
  }
}

extension VariantSelection on Variant {
  static final _isSelected = Expando<bool>();
  static final _quantitySelected = Expando<int>();

  bool get isSelected => _isSelected[this] ?? false;
  set isSelected(bool value) => _isSelected[this] = value;

  int get quantitySelected => _quantitySelected[this] ?? 1;
  set quantitySelected(int value) => _quantitySelected[this] = value;
}