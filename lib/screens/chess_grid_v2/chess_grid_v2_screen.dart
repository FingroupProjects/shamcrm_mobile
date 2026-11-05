import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/controllers/chess_grid_v2_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/complex_add_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/complex_card.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/complex_chess_v2_screen.dart';
import 'package:crm_task_manager/screens/chess_grid/utils/chess_grid_localizations.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';

/// Root Screen for the "Шахматка 2" Navigation Bar Item.
/// Displays active Residential Complexes, aggregated metrics, and fast search.
class ChessGridV2Screen extends StatefulWidget {
  const ChessGridV2Screen({super.key});

  @override
  State<ChessGridV2Screen> createState() => _ChessGridV2ScreenState();
}

class _ChessGridV2ScreenState extends State<ChessGridV2Screen> {
  late final ChessGridV2Controller _controller;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool isClickAvatarIcon = false;

  @override
  void initState() {
    super.initState();
    _controller = ChessGridV2Controller.instance;
    _controller.addListener(_onControllerUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.loadDataFromApi();
      }
    });
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
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final localizations = AppLocalizations.of(context);
    final allComplexes = _controller.complexes;

    final filteredComplexes = allComplexes.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) ||
          c.address.toLowerCase().contains(q);
    }).toList();

    // Aggregated stats across complexes
    final totalApartments = _controller.apartments.length;
    final totalAvailable = _controller.apartments
        .where((a) => a.status == ApartmentStatus.available)
        .length;
    final totalBooked = _controller.apartments
        .where((a) => a.status == ApartmentStatus.booked)
        .length;
    final totalSold = _controller.apartments
        .where((a) => a.status == ApartmentStatus.sold)
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: CustomAppBar(
          title: isClickAvatarIcon
              ? (localizations?.translate('appbar_settings') ?? 'Настройки')
              : (localizations?.translate('appbar_chess_grid_v2') ?? 'Шахматка 2'),
          onClickProfileAvatar: () {
            if (mounted) {
              setState(() {
                isClickAvatarIcon = !isClickAvatarIcon;
              });
            }
          },
          onChangedSearchInput: (String value) {
            if (mounted) {
              setState(() {
                _searchQuery = value.trim();
              });
            }
          },
          textEditingController: _searchController,
          focusNode: _searchFocusNode,
          showMenuIcon: true,
          showMyTaskIcon: true,
          showCallCenter: true,
          showNotificationInMenu: true,
          showFilterIcon: false,
          clearButtonClick: (value) {
            if (value == false) {
              if (mounted) {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              }
            }
          },
          clearButtonClickFiltr: (value) {},
        ),
      ),
      body: isClickAvatarIcon
          ? const ProfileScreen()
          : Stack(
              fit: StackFit.expand,
              children: [
                const Positioned.fill(
                  child: AppBackgroundOverlay(
                    preset: AppBackgroundPreset.aurora,
                    forceRender: true,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).padding.top +
                          kToolbarHeight +
                          15,
                    ),

                    // Top Subheader (Title + Total count + Add ЖК button)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${context.tr('chess_grid_residential_complexes', fallback: 'Жилые комплексы')} 2.0',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${filteredComplexes.length} ${ChessGridL10n.complexPlural(context, filteredComplexes.length)}',
                                style: TextStyle(
                                  fontFamily: 'Golos',
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () => ComplexAddSheet.show(context),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              context.tr('chess_grid_add_complex', fallback: 'Добавить ЖК'),
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.buttonPrimaryBg,
                              foregroundColor: colors.buttonPrimaryFg,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Aggregated Quick Stats Card
                    if (totalApartments > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                        child: _buildSummaryMetricsCard(
                          colors: colors,
                          total: totalApartments,
                          available: totalAvailable,
                          booked: totalBooked,
                          sold: totalSold,
                        ),
                      ),

                    // Complexes List
                    Expanded(
                      child: filteredComplexes.isEmpty
                          ? _buildEmptyState(colors)
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                              itemCount: filteredComplexes.length,
                              itemBuilder: (context, index) {
                                final complex = filteredComplexes[index];
                                return ComplexCard(
                                  complex: complex,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ComplexChessV2Screen(
                                          complex: complex,
                                        ),
                                      ),
                                    );
                                  },
                                  onEdit: () {
                                    ComplexAddSheet.show(context, complex: complex);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryMetricsCard({
    required dynamic colors,
    required int total,
    required int available,
    required int booked,
    required int sold,
  }) {
    final soldRatio = total == 0 ? 0.0 : (sold / total).clamp(0.0, 1.0);
    final bookedRatio = total == 0 ? 0.0 : (booked / total).clamp(0.0, 1.0);
    final availRatio = total == 0 ? 0.0 : (available / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.borderSubtle.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem(
                label: context.tr('chess_grid_total', fallback: 'Всего'),
                value: '$total',
                color: colors.textPrimary,
              ),
              _buildMetricItem(
                label: context.tr('chess_grid_available', fallback: 'Свободно'),
                value: '$available',
                color: ApartmentStatus.available.color,
              ),
              _buildMetricItem(
                label: context.tr('chess_grid_booked', fallback: 'Бронь'),
                value: '$booked',
                color: ApartmentStatus.booked.color,
              ),
              _buildMetricItem(
                label: context.tr('chess_grid_sold', fallback: 'Продано'),
                value: '$sold',
                color: ApartmentStatus.sold.color,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 5,
              child: Row(
                children: [
                  if (availRatio > 0)
                    Expanded(
                      flex: (availRatio * 1000).toInt(),
                      child: Container(color: ApartmentStatus.available.color),
                    ),
                  if (bookedRatio > 0)
                    Expanded(
                      flex: (bookedRatio * 1000).toInt(),
                      child: Container(color: ApartmentStatus.booked.color),
                    ),
                  if (soldRatio > 0)
                    Expanded(
                      flex: (soldRatio * 1000).toInt(),
                      child: Container(color: ApartmentStatus.sold.color),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Golos',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(dynamic colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apartment_rounded,
            size: 56,
            color: colors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isEmpty
                ? context.tr('chess_grid_no_complexes', fallback: 'Нет жилых комплексов')
                : context.tr('chess_grid_complexes_not_found', fallback: 'Ничего не найдено'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

