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
  Future<void> _onRefresh() async {
    context.read<SupplierOpeningsBloc>().add(LoadSupplierOpenings());
    await context.read<SupplierOpeningsBloc>().stream.firstWhere(
          (state) => state is! SupplierOpeningsLoading || state is SupplierOpeningsLoaded || state is SupplierOpeningsError,
    );
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
              // Handle supplier long press
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
        // Обработка операционных ошибок через snackbar
        if (state is SupplierOpeningsOperationError) {
          showCustomSnackBar(
            context: context,
            message: state.message,
            isSuccess: false,
          );
        }
      },
      builder: (context, state) {
        // Если это операционная ошибка, показываем предыдущее состояние
        if (state is SupplierOpeningsOperationError) {
          state = state.previousState;
        }

        if (state is SupplierOpeningsLoading) {
          return _buildLoadingState();
        } else if (state is SupplierOpeningsError) {
          return _buildErrorState(state.message);
        } else if (state is SupplierOpeningsLoaded) {
          if (state.suppliers.isEmpty) {
            return _buildEmptyState();
          }
          return _buildSupplierList(state.suppliers);
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