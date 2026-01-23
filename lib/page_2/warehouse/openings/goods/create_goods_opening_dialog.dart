import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/models/page_2/good_variants_model.dart' as good_variants;
import '../../../../bloc/page_2_BLOC/openings/goods/goods_openings_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_dialog_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_dialog_event.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_dialog_state.dart';
import '../../../../bloc/page_2_BLOC/openings/goods/goods_list_bloc.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import 'add_goods_opening_screen.dart';

class CreateGoodsOpeningDialog extends StatelessWidget {
  const CreateGoodsOpeningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GoodsDialogBloc()..add(LoadGoodVariantsForDialog()),
      child: const GoodVariantsDialog(),
    );
  }
}

class GoodVariantsDialog extends StatefulWidget {
  const GoodVariantsDialog({super.key});

  @override
  State<GoodVariantsDialog> createState() => _GoodVariantsDialogState();
}

class _GoodVariantsDialogState extends State<GoodVariantsDialog> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _translate(BuildContext context, String key, String fallback) {
    return AppLocalizations.of(context)?.translate(key) ?? fallback;
  }

  void _onSearch(String input) {
    final query = input.trim().isEmpty ? null : input.trim();
    context.read<GoodsDialogBloc>().add(SearchGoodVariantsForDialog(search: query));
  }

  Widget _buildVariantsList(
      List<good_variants.GoodVariantItem> items,
      int currentPage,
      int totalPages,
      bool isLoadingMore,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xffF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xffE2E8F0),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: Color(0xff64748B),
                ),
                const SizedBox(height: 12),
                Text(
                  _translate(context, 'no_data_to_display', 'Нет данных для отображения'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff475569),
                  ),
                ),
              ],
            ),
          )
        else ...[
          ...items.map((item) => _buildVariantCard(item)).toList(),

          if (currentPage < totalPages || isLoadingMore)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Загрузка страницы $currentPage из $totalPages...',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 13,
                      color: Color(0xff64748B),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildVariantCard(good_variants.GoodVariantItem item) {
    return GestureDetector(
      onTap: () {
          final goodsOpeningsBloc = context.read<GoodsOpeningsBloc>();

          // Now close the dialog
          Navigator.pop(context);

          // Navigate to the add screen with the captured blocs
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (newContext) => MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: goodsOpeningsBloc),
                  BlocProvider.value(value: GetAllGoodsListBloc()),
                ],
                child: AddGoodsOpeningScreen(
                  goodName: item.fullName ?? item.good?.name ?? 'Неизвестный товар',
                  goodVariantId: item.id ?? 0,
                ),
              ),
            ),
          );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xffE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          item.fullName ?? item.good?.name ?? 'Неизвестный товар',
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: BoxConstraints(
          minHeight: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 420,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff1E2E52).withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff1E2E52), Color(0xff2C3E68)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _translate(context, 'choose_good', 'Выберите товар'),
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isSearching ? Icons.close : Icons.search,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSearching = !_isSearching;
                            if (!_isSearching) {
                              _searchController.clear();
                              context.read<GoodsDialogBloc>().add(LoadGoodVariantsForDialog(search: null));
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (_isSearching) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: _translate(context, 'search', 'Поиск...'),
                        hintStyle: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: _onSearch,
                    ),
                  ],
                ],
              ),
            ),

            // Body
            Flexible(
              child: BlocBuilder<GoodsDialogBloc, GoodsDialogState>(
                builder: (context, state) {
                  if (state is GoodsDialogLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xff1E2E52),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _translate(context, 'loading_data_dialog', 'Загрузка данных...'),
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

                  if (state is GoodsDialogError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Color(0xffEF4444),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _translate(context, 'error_loading_dialog', 'Ошибка загрузки'),
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff1E2E52),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
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
                                context.read<GoodsDialogBloc>().add(LoadGoodVariantsForDialog());
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
                                _translate(context, 'retry_dialog', 'Повторить'),
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is GoodsDialogLoaded) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: _buildVariantsList(
                        state.variants,
                        state.currentPage,
                        state.totalPages,
                        state.isLoadingMore,
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}