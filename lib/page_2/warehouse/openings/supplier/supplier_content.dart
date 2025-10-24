import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../custom_widget/animation.dart';
import '../../../../models/page_2/openings/supplier_openings_model.dart';
import '../../../../bloc/page_2_BLOC/openings/supplier/supplier_openings_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/supplier/supplier_openings_event.dart';
import '../../../../bloc/page_2_BLOC/openings/supplier/supplier_openings_state.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import 'supplier_card.dart';
import 'supplier_details.dart';
import '../opening_delete_dialog.dart';

class SupplierContent extends StatefulWidget {
  const SupplierContent({super.key});

  @override
  State<SupplierContent> createState() => _SupplierContentState();
}

class _SupplierContentState extends State<SupplierContent> {
  bool _isRefreshing = false;
  // Keep track of ScaffoldMessengerState to avoid unsafe lookups
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache the ScaffoldMessengerState safely
    _scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void dispose() {
    _scaffoldMessenger = null;
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;

    setState(() {
      _isRefreshing = true;
    });

    context.read<SupplierOpeningsBloc>().add(LoadSupplierOpenings());

    await context.read<SupplierOpeningsBloc>().stream.firstWhere(
          (state) => state is SupplierOpeningsLoaded || state is SupplierOpeningsError,
    );

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Widget _buildSupplierList(List<SupplierOpening> suppliers) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xff1E2E52),
      child: ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: suppliers.length,
        itemBuilder: (context, index) {
          return SupplierCard(
            supplier: suppliers[index],
            onClick: (supplier) {
              final bloc = context.read<SupplierOpeningsBloc>();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: bloc,
                    child: SupplierOpeningDetailsScreen(
                      opening: supplier,
                    ),
                  ),
                ),
              );
            },
            onLongPress: (supplier) {
              // Handle supplier long press if needed
            },
            onDelete: (supplier) {
              final bloc = context.read<SupplierOpeningsBloc>();
              showDialog(
                context: context,
                builder: (dialogContext) => OpeningDeleteDialog(
                  openingId: supplier.id ?? 0,
                  openingType: OpeningType.supplier,
                  onConfirmDelete: () {
                    bloc.add(
                      DeleteSupplierOpening(id: supplier.id ?? 0),
                    );
                  },
                ),
              );
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
                    localizations.translate('no_suppliers'),
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.translate('no_suppliers_description'),
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
    return const Center(
      child: PlayStoreImageLoading(
        size: 80,
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
                        localizations.translate('error_loading_dialog'),
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
                          localizations.translate('retry'),
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
        // ✅ Handle success messages
        if (state is SupplierOpeningCreateSuccess) {
          _showSnackBarSafely(
            AppLocalizations.of(context)?.translate('supplier_opening_created') ??
                'Остаток поставщика создан',
            isSuccess: true,
          );
          // Refresh data after create
          context.read<SupplierOpeningsBloc>().add(LoadSupplierOpenings());
        }

        if (state is SupplierOpeningUpdateSuccess) {
          _showSnackBarSafely(
            AppLocalizations.of(context)?.translate('successfully_updated') ??
                'Успешно обновлено',
            isSuccess: true,
          );
          // Refresh data after update
          context.read<SupplierOpeningsBloc>().add(LoadSupplierOpenings());
        }

        // ✅ Handle error messages
        if (state is SupplierOpeningCreateError) {
          _showSnackBarSafely(state.message, isSuccess: false);
          // Refresh data to avoid white screen
          context.read<SupplierOpeningsBloc>().add(LoadSupplierOpenings());
        }

        if (state is SupplierOpeningUpdateError) {
          _showSnackBarSafely(state.message, isSuccess: false);
          // Refresh data to avoid white screen
          context.read<SupplierOpeningsBloc>().add(LoadSupplierOpenings());
        }
      },
      builder: (context, state) {
        // Show loading during refresh or initial load
        if (state is SupplierOpeningsLoading || _isRefreshing) {
          return _buildLoadingState();
        }

        // Show error state
        if (state is SupplierOpeningsError) {
          return _buildErrorState(state.message);
        }

        // Show loaded data
        if (state is SupplierOpeningsLoaded) {
          if (state.suppliers.isEmpty) {
            return _buildEmptyState();
          }
          return _buildSupplierList(state.suppliers);
        }

        // Default empty state
        return _buildEmptyState();
      },
    );
  }

  void _showSnackBarSafely(String message, {bool isSuccess = true}) {
    // Use cached ScaffoldMessengerState to avoid unsafe lookups
    if (!mounted || _scaffoldMessenger == null) return;

    _scaffoldMessenger!.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        elevation: 3,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        duration: Duration(seconds: isSuccess ? 2 : 3),
      ),
    );
  }
}