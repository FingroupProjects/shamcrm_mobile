import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/page_2/openings/supplier_openings_model.dart';
import '../../../../bloc/page_2_BLOC/openings/supplier/supplier_openings_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/supplier/supplier_openings_event.dart';
import '../../../../bloc/page_2_BLOC/openings/supplier/supplier_openings_state.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import 'supplier_card.dart';
import 'edit_supplier_opening_screen.dart';

class SupplierContent extends StatefulWidget {
  const SupplierContent({super.key});

  @override
  State<SupplierContent> createState() => _SupplierContentState();
}

class _SupplierContentState extends State<SupplierContent> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottomReached && !_isLoadingMore) {
      final state = context.read<SupplierOpeningsBloc>().state;
      if (state is SupplierOpeningsLoaded && !state.hasReachedMax) {
        setState(() => _isLoadingMore = true);
        context.read<SupplierOpeningsBloc>().add(
          LoadSupplierOpenings(page: state.pagination.current_page + 1),
        );
      }
    }
  }

  bool get _isBottomReached {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _onRefresh() async {
    context.read<SupplierOpeningsBloc>().add(LoadSupplierOpenings(page: 1));
    await context.read<SupplierOpeningsBloc>().stream.firstWhere(
          (state) => state is! SupplierOpeningsLoading || state is SupplierOpeningsLoaded || state is SupplierOpeningsError,
    );
  }

  Widget _buildSupplierList(List<SupplierOpening> suppliers, bool hasReachedMax) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xff1E2E52),
      child: ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: suppliers.length + (hasReachedMax ? 0 : 1),
        itemBuilder: (context, index) {
          if (index >= suppliers.length) {
            return _isLoadingMore
                ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xff1E2E52),
                ),
              ),
            )
                : const SizedBox.shrink();
          }

          return SupplierCard(
            supplier: suppliers[index],
            onClick: (supplier) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditSupplierOpeningScreen(
                    supplierOpening: supplier,
                  ),
                ),
              );
            },
            onLongPress: (supplier) {
              // Handle supplier long press
            },
            onDelete: (supplier) {
              // Handle delete action
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context)!;
    
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: Color(0xff99A4BA),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.translate('no_suppliers') ?? 'Нет поставщиков',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.translate('no_suppliers_description') ?? 'Список поставщиков пуст',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final localizations = AppLocalizations.of(context)!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xff1E2E52),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('loading_data') ?? 'Загрузка данных',
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              color: Color(0xff64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final localizations = AppLocalizations.of(context)!;
    
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xffFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xffFECACA),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Color(0xffEF4444),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.translate('error_loading_dialog') ?? 'Ошибка загрузки',
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          color: Color(0xff64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<SupplierOpeningsBloc>().add(LoadSupplierOpenings());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff1E2E52),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          localizations.translate('retry') ?? 'Повторить',
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SupplierOpeningsBloc, SupplierOpeningsState>(
      listener: (context, state) {
        if (state is SupplierOpeningsLoaded) {
          setState(() => _isLoadingMore = false);
        }

        if (state is SupplierOpeningsPaginationError) {
          showCustomSnackBar(
            context: context,
            message: state.message,
            isSuccess: false,
          );
          setState(() => _isLoadingMore = false);
        }
      },
      builder: (context, state) {
        if (state is SupplierOpeningsLoading) {
          return _buildLoadingState();
        } else if (state is SupplierOpeningsError) {
          return _buildErrorState(state.message);
        } else if (state is SupplierOpeningsLoaded) {
          if (state.suppliers.isEmpty) {
            return _buildEmptyState();
          }
          return _buildSupplierList(state.suppliers, state.hasReachedMax);
        }

        return _buildEmptyState();
      },
    );
  }
}

// Helper function for snackbar
void showCustomSnackBar({
  required BuildContext context,
  required String message,
  required bool isSuccess,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: isSuccess ? Colors.green : const Color(0xffEF4444),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}