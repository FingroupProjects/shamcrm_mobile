import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/custom_widget/custom_tasks_tabBar.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/apartment_detail_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_grid_cell.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_grid_filter_dialog.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/order_create_sheet.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

class ComplexChessScreen extends StatefulWidget {
  final ResidentialComplex complex;

  const ComplexChessScreen({
    super.key,
    required this.complex,
  });

  @override
  State<ComplexChessScreen> createState() => _ComplexChessScreenState();
}

class _ComplexChessScreenState extends State<ComplexChessScreen> {
  late final ChessGridController _controller;
  ApartmentStatus? _quickStatusFilter;
  int _selectedEntrance = 0; // 0 = all

  @override
  void initState() {
    super.initState();
    _controller = ChessGridController.instance;
    _controller.addListener(_onControllerUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.selectComplex(widget.complex.id);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final complex = _controller.complex;
    final building = _controller.currentBuilding;

    final apts = _controller.getApartmentsForComplex(complex.id);
    final freeCount = _controller.getAvailableCount(complex.id);
    final bookedCount = _controller.getBookedCount(complex.id);
    final soldCount = _controller.getSoldCount(complex.id);
    final reservedCount = _controller.getReservedCount(complex.id);

    final hasActiveFilter = !_controller.filter.isDefault || _quickStatusFilter != null || _selectedEntrance != 0;

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
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: AppBarShell(
                    leading: AppBarShell.capsule(
                      context,
                      width: AppBarShell.orbSize,
                      padding: EdgeInsets.zero,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    center: AppBarShell.capsule(
                      context,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            complex.name,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: colors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            complex.address,
                            style: TextStyle(
                              fontFamily: 'Golos',
                              fontSize: 11,
                              color: colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                          Icons.tune_rounded,
                          size: 20,
                          color: hasActiveFilter
                              ? colors.buttonPrimaryBg
                              : colors.iconSecondary,
                        ),
                        onPressed: () => ChessGridFilterDialog.show(
                          context: context,
                          controller: _controller,
                        ),
                      ),
                    ),
                  ),
                ),

                // Building Tabs (if multiple buildings exist)
                if (complex.buildings.length > 1) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: complex.buildings.map((b) {
                          final isSelected = b.key == _controller.selectedBuildingKey;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _controller.selectBuilding(b.key),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: TaskStyles.tabButtonDecoration(
                                    context,
                                    isSelected,
                                  ),
                                  child: Text(
                                    b.name,
                                    style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      fontSize: 13,
                                      color: isSelected
                                          ? colors.buttonPrimaryFg
                                          : colors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],

                // Entrances Chips (if current building has > 1 entrance)
                if (building != null && building.entranceCount > 1) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildEntranceChip(0, 'Все подъезды'),
                          for (int e = 1; e <= building.entranceCount; e++)
                            _buildEntranceChip(e, 'Подъезд $e'),
                        ],
                      ),
                    ),
                  ),
                ],

                // Quick Status Filters Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusFilterChip(
                          status: null,
                          label: 'Все',
                          count: apts.length,
                          color: colors.buttonPrimaryBg,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusFilterChip(
                          status: ApartmentStatus.available,
                          label: 'Свободно',
                          count: freeCount,
                          color: ApartmentStatus.available.color,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusFilterChip(
                          status: ApartmentStatus.booked,
                          label: 'Бронь',
                          count: bookedCount,
                          color: ApartmentStatus.booked.color,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusFilterChip(
                          status: ApartmentStatus.sold,
                          label: 'Продано',
                          count: soldCount,
                          color: ApartmentStatus.sold.color,
                        ),
                        if (reservedCount > 0) ...[
                          const SizedBox(width: 8),
                          _buildStatusFilterChip(
                            status: ApartmentStatus.reserved,
                            label: 'Резерв',
                            count: reservedCount,
                            color: ApartmentStatus.reserved.color,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Matrix Body
                Expanded(
                  child: building == null
                      ? Center(
                          child: Text(
                            'Корпус не выбран',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              color: colors.textSecondary,
                            ),
                          ),
                        )
                      : _buildMatrix(context, building),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntranceChip(int entrance, String title) {
    final colors = context.appColors;
    final isSelected = _selectedEntrance == entrance;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedEntrance = entrance;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? colors.surfaceElevated : colors.surfacePrimary.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? colors.buttonPrimaryBg : colors.borderSubtle.withValues(alpha: 0.6),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Golos',
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
              color: isSelected ? colors.buttonPrimaryBg : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip({
    required ApartmentStatus? status,
    required String label,
    required int count,
    required Color color,
  }) {
    final colors = context.appColors;
    final isSelected = _quickStatusFilter == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_quickStatusFilter == status) {
            _quickStatusFilter = null;
          } else {
            _quickStatusFilter = status;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : colors.surfacePrimary.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : colors.borderSubtle.withValues(alpha: 0.5),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12,
                color: isSelected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                  color: isSelected ? color : colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrix(BuildContext context, Building building) {
    final colors = context.appColors;
    final complexApts = _controller.getApartmentsForComplex(widget.complex.id);

    // Filter by building
    var filtered = complexApts.where((a) => a.buildingKey == building.key).toList();

    // Filter by entrance
    if (_selectedEntrance != 0) {
      filtered = filtered.where((a) => a.entrance == _selectedEntrance).toList();
    }

    // Filter by quick status
    if (_quickStatusFilter != null) {
      filtered = filtered.where((a) => a.status == _quickStatusFilter).toList();
    }

    // Filter by dialog filter if active
    if (!_controller.filter.isDefault) {
      filtered = filtered.where((a) => _controller.filter.matches(a)).toList();
    }

    final entrances = _selectedEntrance == 0
        ? List.generate(building.entranceCount, (i) => i + 1)
        : [_selectedEntrance];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.borderSubtle.withValues(alpha: 0.5),
        ),
        boxShadow: context.appShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Entrance Header Row
                Row(
                  children: [
                    const SizedBox(width: 52), // spacer for floor column
                    for (final e in entrances)
                      Container(
                        width: building.apartsPerFloor * 94.0,
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colors.borderSubtle.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              'Подъезд $e',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Floor Rows (from top floor down to 1)
                for (int floor = building.floorCount; floor >= 1; floor--)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left floor badge
                        Container(
                          width: 48,
                          height: 70,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: colors.borderSubtle.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$floor',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: colors.textPrimary,
                                ),
                              ),
                              Text(
                                'эт',
                                style: TextStyle(
                                  fontFamily: 'Golos',
                                  fontSize: 10,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),

                        // Apartment cells for this floor
                        for (final e in entrances)
                          for (int p = 0; p < building.apartsPerFloor; p++)
                            _buildCellSlot(
                              filteredApts: filtered,
                              buildingKey: building.key,
                              entrance: e,
                              floor: floor,
                              position: p,
                            ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCellSlot({
    required List<Apartment> filteredApts,
    required String buildingKey,
    required int entrance,
    required int floor,
    required int position,
  }) {
    Apartment? apt;
    try {
      apt = filteredApts.firstWhere(
        (a) =>
            a.buildingKey == buildingKey &&
            a.entrance == entrance &&
            a.floor == floor &&
            a.position == position,
      );
    } catch (_) {
      // Check if apartment exists without filters to display ghost/empty slot
      try {
        final rawApt = _controller.apartments.firstWhere(
          (a) =>
              a.complexId == widget.complex.id &&
              a.buildingKey == buildingKey &&
              a.entrance == entrance &&
              a.floor == floor &&
              a.position == position,
        );
        // It was filtered out
        return Container(
          width: 88,
          height: 70,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: context.appColors.surfaceElevated.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.appColors.borderSubtle.withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: Text(
              '№${rawApt.number}',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 11,
                color: context.appColors.textSecondary.withValues(alpha: 0.35),
              ),
            ),
          ),
        );
      } catch (_) {
        apt = null;
      }
    }

    if (apt == null) {
      return Container(
        width: 88,
        height: 70,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: context.appColors.surfaceElevated.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    return ChessGridCell(
      apartment: apt,
      onTap: () {
        final currentApt = apt!;
        ApartmentDetailSheet.show(
          context: context,
          apartment: currentApt,
          onCreateOrder: () {
            OrderCreateSheet.show(
              context: context,
              apartment: currentApt,
            ).then((_) {
              if (mounted) setState(() {});
            });
          },
          onToggleReserve: () {
            _controller.toggleApartmentReserve(currentApt);
            showCustomSnackBar(
              context: context,
              message: currentApt.status == ApartmentStatus.reserved
                  ? 'Квартира снята с резерва'
                  : 'Квартира поставлена в резерв',
              isSuccess: true,
            );
          },
          onEdit: () {},
        );
      },
    );
  }
}
