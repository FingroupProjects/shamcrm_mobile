import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/chess_grid/complex_chess_screen.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/complex_add_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/complex_card.dart';
import 'package:flutter/material.dart';

enum ChessGridTab { matrix, catalog, orders, parking, admin, settings }

class ChessGridScreen extends StatefulWidget {
  final ChessGridTab? initialTab;

  const ChessGridScreen({
    super.key,
    this.initialTab,
  });

  @override
  State<ChessGridScreen> createState() => _ChessGridScreenState();
}

class _ChessGridScreenState extends State<ChessGridScreen> {
  late final ChessGridController _controller;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = ChessGridController.instance;
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final allComplexes = _controller.complexes;

    final filteredComplexes = allComplexes.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) || c.address.toLowerCase().contains(q);
    }).toList();

    // Overall stats across all complexes
    final totalApartments = _controller.apartments.length;
    final totalAvailable = _controller.apartments.where((a) => a.status == ApartmentStatus.available).length;
    final totalBooked = _controller.apartments.where((a) => a.status == ApartmentStatus.booked).length;
    final totalSold = _controller.apartments.where((a) => a.status == ApartmentStatus.sold).length;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: AppBackgroundOverlay(
              preset: AppBackgroundPreset.aurora,
              forceRender: true,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: AppBarShell(
                    leading: AppBarShell.capsule(
                      context,
                      width: AppBarShell.orbSize,
                      padding: EdgeInsets.zero,
                      child: IconButton(
                        icon: Navigator.canPop(context)
                            ? const Icon(Icons.arrow_back_ios_new_rounded, size: 18)
                            : Image.asset(
                                'assets/icons/MyNavBar/chess_grid_ON.png',
                                width: 22,
                                height: 22,
                              ),
                        onPressed: Navigator.canPop(context)
                            ? () => Navigator.pop(context)
                            : null,
                      ),
                    ),
                    center: AppBarShell.capsule(
                      context,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Шахматка',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            '${allComplexes.length} ${_pluralizeComplex(allComplexes.length)}',
                            style: TextStyle(
                              fontFamily: 'Golos',
                              fontSize: 11.5,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: AppBarShell.capsule(
                      context,
                      width: AppBarShell.orbSize,
                      padding: EdgeInsets.zero,
                      child: IconButton(
                        icon: Icon(
                          Icons.add_rounded,
                          size: 24,
                          color: colors.buttonPrimaryBg,
                        ),
                        onPressed: () => ComplexAddSheet.show(context),
                      ),
                    ),
                  ),
                ),

                // Search field in Lead style
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: CustomTextField(
                    controller: _searchController,
                    label: 'Поиск жилого комплекса',
                    hintText: 'Введите название или адрес...',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colors.iconSecondary,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: colors.iconSecondary,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                  ),
                ),

                // Summary Stats Strip
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.surfacePrimary.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.borderSubtle.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTopStat(
                          title: 'Всего',
                          value: '$totalApartments',
                          color: colors.textPrimary,
                        ),
                        _buildTopDivider(),
                        _buildTopStat(
                          title: 'Свободно',
                          value: '$totalAvailable',
                          color: ApartmentStatus.available.color,
                        ),
                        _buildTopDivider(),
                        _buildTopStat(
                          title: 'Бронь',
                          value: '$totalBooked',
                          color: ApartmentStatus.booked.color,
                        ),
                        _buildTopDivider(),
                        _buildTopStat(
                          title: 'Продано',
                          value: '$totalSold',
                          color: ApartmentStatus.sold.color,
                        ),
                      ],
                    ),
                  ),
                ),

                // Header for Complexes List
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Жилые комплексы',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        'Нажмите на ЖК для входа',
                        style: TextStyle(
                          fontFamily: 'Golos',
                          fontSize: 11.5,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Complexes List
                Expanded(
                  child: filteredComplexes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.apartment_rounded,
                                size: 54,
                                color: colors.iconSecondary.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Комплексы не найдены'
                                    : 'Нет добавленных ЖК',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => ComplexAddSheet.show(context),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text(
                                  'Добавить ЖК',
                                  style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.buttonPrimaryBg,
                                  foregroundColor: colors.buttonPrimaryFg,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            4,
                            16,
                            MediaQuery.paddingOf(context).bottom + 90,
                          ),
                          itemCount: filteredComplexes.length,
                          itemBuilder: (context, index) {
                            final complex = filteredComplexes[index];
                            return ComplexCard(
                              complex: complex,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ComplexChessScreen(complex: complex),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ComplexAddSheet.show(context),
        backgroundColor: colors.buttonPrimaryBg,
        foregroundColor: colors.buttonPrimaryFg,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Добавить ЖК',
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTopStat({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Golos',
            fontSize: 11,
            color: context.appColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTopDivider() {
    return Container(
      width: 1,
      height: 22,
      color: context.appColors.borderSubtle.withValues(alpha: 0.5),
    );
  }

  String _pluralizeComplex(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'комплекс';
    if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
      return 'комплекса';
    }
    return 'комплексов';
  }
}
