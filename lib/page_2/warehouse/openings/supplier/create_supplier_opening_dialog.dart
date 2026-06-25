import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/helpers/theme_context_extension.dart';
import '../../../../bloc/page_2_BLOC/openings/supplier/supplier_openings_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/supplier/supplier_dialog_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/supplier/supplier_dialog_event.dart';
import '../../../../bloc/page_2_BLOC/openings/supplier/supplier_dialog_state.dart';
import '../../../../models/page_2/opening_supplier_model.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import 'add_supplier_opening_screen.dart';

class CreateSupplierOpeningDialog extends StatelessWidget {
  const CreateSupplierOpeningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем оригинальный блок для передачи в AddSupplierOpeningScreen
    final supplierOpeningsBloc = context.read<SupplierOpeningsBloc>();

    return BlocProvider(
      create: (context) => SupplierDialogBloc()..add(LoadSuppliersForDialog()),
      child: SupplierVariantsDialog(
        supplierOpeningsBloc: supplierOpeningsBloc,
      ),
    );
  }
}

class SupplierVariantsDialog extends StatefulWidget {
  final SupplierOpeningsBloc supplierOpeningsBloc;

  const SupplierVariantsDialog({
    super.key,
    required this.supplierOpeningsBloc,
  });

  @override
  State<SupplierVariantsDialog> createState() => _SupplierVariantsDialogState();
}

class _SupplierVariantsDialogState extends State<SupplierVariantsDialog> {
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
    context
        .read<SupplierDialogBloc>()
        .add(SearchSuppliersForDialog(search: query));
  }

  Widget _buildSuppliersList(List<Supplier> items) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Отображаем список поставщиков
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surfacePrimary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.borderSubtle,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.business_outlined,
                  size: 48,
                  color: Colors.blueGrey,
                ),
                const SizedBox(height: 12),
                Text(
                  _translate(context, 'no_data_to_display',
                      'Нет данных для отображения'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          )
        else
          ...items.map((item) => _buildSupplierCard(item)).toList(),
      ],
    );
  }

  Widget _buildSupplierCard(Supplier item) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () {
        // Закрываем диалог
        Navigator.pop(context);

        // Открываем экран добавления с существующим блоком
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (newContext) => BlocProvider.value(
              value: widget.supplierOpeningsBloc,
              child: AddSupplierOpeningScreen(
                supplierName: item.name ?? '',
                supplierId: item.id ?? 0,
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
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.borderSubtle,
            width: 1,
          ),
        ),
        child: Text(
          item.name ?? '',
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.15),
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
                color: Color(0xff38BDF8),
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
                          color: Colors.white.withValues(alpha: 0.2),
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
                          _translate(context, 'choose_supplier',
                              'Выберите поставщика'),
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
                              context
                                  .read<SupplierDialogBloc>()
                                  .add(LoadSuppliersForDialog(search: null));
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
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onChanged: _onSearch,
                    ),
                  ],
                ],
              ),
            ),

            // Body
            Flexible(
              child: BlocBuilder<SupplierDialogBloc, SupplierDialogState>(
                builder: (context, state) {
                  if (state is SupplierDialogLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: colors.buttonPrimaryBg,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _translate(context, 'loading_data_dialog',
                                'Загрузка данных...'),
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is SupplierDialogError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _translate(context, 'error_loading_dialog',
                                  'Ошибка загрузки'),
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 14,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context
                                    .read<SupplierDialogBloc>()
                                    .add(LoadSuppliersForDialog());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.buttonPrimaryBg,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _translate(
                                    context, 'retry_dialog', 'Повторить'),
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

                  if (state is SupplierDialogLoaded) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: _buildSuppliersList(state.suppliers),
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
