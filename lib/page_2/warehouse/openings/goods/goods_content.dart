import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../custom_widget/animation.dart';
import '../../../../models/page_2/openings/goods_openings_model.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_openings_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_openings_event.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_openings_state.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import 'goods_card.dart';
import 'goods_details.dart';
import '../opening_delete_dialog.dart';

class GoodsContent extends StatefulWidget {
  const GoodsContent({super.key});

  @override
  State<GoodsContent> createState() => _GoodsContentState();
}

class _GoodsContentState extends State<GoodsContent> {
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

    context.read<GoodsOpeningsBloc>().add(LoadGoodsOpenings());

    await context.read<GoodsOpeningsBloc>().stream.firstWhere(
          (state) => state is GoodsOpeningsLoaded || state is GoodsOpeningsError,
    );

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Widget _buildGoodsList(List<GoodsOpeningDocument> goods) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xff1E2E52),
      child: ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: goods.length,
        itemBuilder: (context, index) {
          return GoodsCard(
            goods: goods[index],
            onClick: (goods) {
              final bloc = context.read<GoodsOpeningsBloc>();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: bloc,
                    child: GoodsOpeningDetailsScreen(
                      document: goods,
                    ),
                  ),
                ),
              );
            },
            onLongPress: (goods) {
              // Handle goods long press
            },
            onDelete: (goods) {
              final bloc = context.read<GoodsOpeningsBloc>();
              showDialog(
                context: context,
                builder: (dialogContext) => OpeningDeleteDialog(
                  openingId: goods.id ?? 0,
                  openingType: OpeningType.goods,
                  onConfirmDelete: () {
                    bloc.add(
                      DeleteGoodsOpening(id: goods.id ?? 0),
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
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Color(0xff99A4BA),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.translate('no_goods') ?? 'Нет товаров',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.translate('no_goods_description') ?? 'Список товаров пуст',
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
                          context.read<GoodsOpeningsBloc>().add(LoadGoodsOpenings());
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
    return BlocConsumer<GoodsOpeningsBloc, GoodsOpeningsState>(
      listener: (context, state) {
        // ✅ Handle success messages
        if (state is GoodsOpeningCreateSuccess) {
          _showSnackBarSafely(
            AppLocalizations.of(context)?.translate('goods_opening_created') ??
                'Остаток товара создан',
            isSuccess: true,
          );
          // Refresh data after create
          context.read<GoodsOpeningsBloc>().add(LoadGoodsOpenings());
        }

        // if (state is GoodsOpeningDeleteError) {
        //   _showSnackBarSafely(state.message, isSuccess: false);
        //   context.read<GoodsOpeningsBloc>().add(LoadGoodsOpenings());
        // }

        if (state is GoodsOpeningUpdateSuccess) {
          _showSnackBarSafely(
            AppLocalizations.of(context)?.translate('successfully_updated') ??
                'Успешно обновлено',
            isSuccess: true,
          );
          // Refresh data after update
          context.read<GoodsOpeningsBloc>().add(LoadGoodsOpenings());
        }

        // ✅ Handle error messages
        if (state is GoodsOpeningCreateError) {
          _showSnackBarSafely(state.message, isSuccess: false);
          // Refresh data to avoid white screen
          context.read<GoodsOpeningsBloc>().add(LoadGoodsOpenings());
        }

        if (state is GoodsOpeningUpdateError) {
          _showSnackBarSafely(state.message, isSuccess: false);
          // Refresh data to avoid white screen
          context.read<GoodsOpeningsBloc>().add(LoadGoodsOpenings());
        }

        // Support for operational error state (if exists)
        if (state is GoodsOpeningsOperationError) {
          _showSnackBarSafely(state.message, isSuccess: false);
        }
      },
      builder: (context, state) {
        // Show loading during refresh or initial load
        if (state is GoodsOpeningsLoading || _isRefreshing) {
          return _buildLoadingState();
        }

        // Show error state
        if (state is GoodsOpeningsError) {
          return _buildErrorState(state.message);
        }

        // Show loaded data
        if (state is GoodsOpeningsLoaded) {
          if (state.goods.isEmpty) {
            return _buildEmptyState();
          }
          return _buildGoodsList(state.goods);
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