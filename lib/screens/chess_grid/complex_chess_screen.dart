import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/page_2/warehouse/order_payments/order_payments_screen.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/utils/chess_grid_localizations.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/apartment_detail_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/apartment_form_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/building_form_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_grid_admin_view.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/apartment_preview_tooltip.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_grid_catalog_view.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_grid_cell.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_grid_filter_dialog.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart' as deal;
import 'package:crm_task_manager/page_2/order/order_details/chess_deal_details_screen.dart';
import 'package:crm_task_manager/page_2/order/order_screen.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_grid_parking_view.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_payments_view.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_grid_settings_view.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/order_create_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/parking_detail_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/chess_grid_3d_view.dart';
import 'package:crm_task_manager/utils/safe_converters.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

enum ChessViewMode {
  sections,
  model3D,
  matrix,
  list,
  orders,
  payments,
  orderPayments,
  parking,
  admin,
  settings,
}

class ComplexChessScreen extends StatefulWidget {
  final ResidentialComplex complex;
  final ChessViewMode initialView;

  /// Флаг включения/скрытия 3D режима в Шахматка 1 (можно скрыть в любой момент, выставив false)
  static const bool is3DEnabled = true;

  const ComplexChessScreen({
    super.key,
    required this.complex,
    this.initialView = ChessViewMode.sections,
  });

  @override
  State<ComplexChessScreen> createState() => _ComplexChessScreenState();
}

class _ComplexChessScreenState extends State<ComplexChessScreen> {
  late final ChessGridController _controller;
  late final TransformationController _transformationController;
  final GlobalKey _complexTitleKey = GlobalKey();
  double _currentScale = 1.0;
  late ChessViewMode _currentView;
  ApartmentStatus? _quickStatusFilter;
  final ChessZoomLevel _zoomLevel = ChessZoomLevel.standard100;

  @override
  void initState() {
    super.initState();
    _currentView = widget.initialView;
    _transformationController = TransformationController();
    _transformationController.addListener(_onScaleChanged);
    _controller = ChessGridController.instance;
    _controller.addListener(_onControllerUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.loadComplexDetails(widget.complex.id);
      }
    });
  }

  void _onScaleChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.05) {
      if (mounted) {
        setState(() {
          _currentScale = scale;
        });
      }
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onScaleChanged);
    _transformationController.dispose();
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final complex = _controller.complex;
    final building = _controller.currentBuilding;

    final selectedEntrance = _controller.filter.entrance;
    final complexApts = _controller.getApartmentsForComplex(complex.id);
    final visibleApts = complexApts.where((apt) {
      if (building != null) {
        final sameBuilding = apt.buildingKey == building.key ||
            (building.id != null && apt.buildingId == building.id);
        if (!sameBuilding) return false;
      }
      if (selectedEntrance != 0 && apt.entrance != selectedEntrance) return false;
      return true;
    }).toList();
    final visibleParking = _controller.parkingSpots.where((spot) {
      if (building == null) {
        final buildingIds = complex.buildings.map((item) => item.id).whereType<int>().toSet();
        final keys = complex.buildings.map((item) => item.key).toSet();
        return buildingIds.contains(spot.buildingId) ||
            keys.contains(spot.buildingKey) ||
            spot.complexId == complex.id;
      }
      return (building.id != null && spot.buildingId == building.id) ||
          spot.buildingKey == building.key;
    }).toList();

    int countByStatus(ApartmentStatus status) {
      return visibleApts.where((apt) => apt.status == status).length +
          visibleParking.where((spot) => spot.status == status).length;
    }

    final totalCount = visibleApts.length + visibleParking.length;
    final freeCount = countByStatus(ApartmentStatus.available);
    final bookedCount = countByStatus(ApartmentStatus.booked);
    final soldCount = countByStatus(ApartmentStatus.sold);
    final reservedCount = countByStatus(ApartmentStatus.reserved);

    final hasActiveFilter = !_controller.filter.isDefault || _quickStatusFilter != null;

    return PopScope(
      canPop: _currentView == ChessViewMode.sections,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && mounted) {
          setState(() => _currentView = ChessViewMode.sections);
        }
      },
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(context, complex, building, hasActiveFilter),
      floatingActionButton: (_currentView == ChessViewMode.matrix || _currentView == ChessViewMode.list)
          ? FloatingActionButton.extended(
              onPressed: () => _showQuickCreateMenu(context),
              backgroundColor: colors.buttonPrimaryBg,
              foregroundColor: colors.buttonPrimaryFg,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Добавить',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            )
          : null,
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
            top: false,
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),

                if (_currentView == ChessViewMode.sections)
                  Expanded(child: _buildSectionGrid(context))
                else ...[
                  if (_currentView == ChessViewMode.matrix || _currentView == ChessViewMode.list)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatusFilterChip(
                              status: null,
                              label: context.tr('chess_grid_filter_all', fallback: 'Все'),
                              count: totalCount,
                              color: colors.buttonPrimaryBg,
                            ),
                            const SizedBox(width: 6),
                            _buildStatusFilterChip(
                              status: ApartmentStatus.available,
                              label: context.tr('chess_grid_filter_available', fallback: 'Свободно'),
                              count: freeCount,
                              color: ApartmentStatus.available.color,
                            ),
                            const SizedBox(width: 6),
                            _buildStatusFilterChip(
                              status: ApartmentStatus.booked,
                              label: context.tr('chess_grid_filter_booked', fallback: 'Бронь'),
                              count: bookedCount,
                              color: ApartmentStatus.booked.color,
                            ),
                            const SizedBox(width: 6),
                            _buildStatusFilterChip(
                              status: ApartmentStatus.sold,
                              label: context.tr('chess_grid_filter_sold', fallback: 'Продано'),
                              count: soldCount,
                              color: ApartmentStatus.sold.color,
                            ),
                            if (reservedCount > 0) ...[
                              const SizedBox(width: 6),
                              _buildStatusFilterChip(
                                status: ApartmentStatus.reserved,
                                label: context.tr('chess_grid_filter_reserved', fallback: 'Резерв'),
                                count: reservedCount,
                                color: ApartmentStatus.reserved.color,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: (_controller.isLoadingComplex || _controller.isLoadingApartments)
                        ? const Center(child: CircularProgressIndicator())
                        : _buildCurrentViewBody(context, building),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildSectionGrid(BuildContext context) {
    final colors = context.appColors;
    final tiles = <({ChessViewMode mode, String label, IconData icon})>[
      if (ComplexChessScreen.is3DEnabled)
        (mode: ChessViewMode.model3D, label: '3D', icon: Icons.view_in_ar_rounded),
      (
        mode: ChessViewMode.matrix,
        label: context.tr('chess_grid_tab_chess', fallback: 'Шахматка'),
        icon: Icons.grid_view_rounded,
      ),
      (
        mode: ChessViewMode.orders,
        label: context.tr('chess_grid_tab_orders', fallback: 'Сделка'),
        icon: Icons.receipt_long_rounded,
      ),
      (mode: ChessViewMode.payments, label: 'Платежи', icon: Icons.payments_outlined),
      (
        mode: ChessViewMode.orderPayments,
        label: 'История платежей',
        icon: Icons.receipt_long_rounded,
      ),
      (
        mode: ChessViewMode.admin,
        label: context.tr('chess_grid_tab_management', fallback: 'Управление'),
        icon: Icons.domain_add_rounded,
      ),
      (
        mode: ChessViewMode.settings,
        label: context.tr('chess_grid_tab_settings', fallback: 'Настройки'),
        icon: Icons.tune_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 600
            ? 2
            : constraints.maxWidth < 900
                ? 3
                : 4;
        const spacing = 10.0;
        final itemWidth = (constraints.maxWidth - 32 - spacing * (columns - 1)) / columns;
        final itemHeight = itemWidth / (constraints.maxWidth < 400 ? 1.0 : 1.1);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final tile in tiles)
                SizedBox(
                  width: itemWidth,
                  height: itemHeight,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (tile.mode == ChessViewMode.orderPayments) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OrderPaymentsScreen(),
                            ),
                          );
                          return;
                        }
                        setState(() => _currentView = tile.mode);
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          color: colors.surfacePrimary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.borderSubtle),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: colors.buttonPrimaryBg.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(tile.icon, size: 24, color: colors.buttonPrimaryBg),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tile.label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentViewBody(BuildContext context, Building? building) {
    final colors = context.appColors;

    switch (_currentView) {
      case ChessViewMode.sections:
        return const SizedBox.shrink();
      case ChessViewMode.model3D:
        final currentComplex = _controller.complex.buildings.isNotEmpty
            ? _controller.complex
            : widget.complex;
        return ChessGrid3DView(
          complex: currentComplex,
          apartments: _controller.getApartmentsForComplex(_controller.complex.id),
          parkingSpots: _controller.parkingSpots.where((spot) {
            final buildingIds = currentComplex.buildings.map((item) => item.id).whereType<int>().toSet();
            final keys = currentComplex.buildings.map((item) => item.key).toSet();
            return buildingIds.contains(spot.buildingId) || keys.contains(spot.buildingKey);
          }).toList(),
          onSwitchTo2D: () {
            setState(() {
              _currentView = ChessViewMode.matrix;
            });
          },
          onToggleReserve: (apt) {
            _controller.toggleApartmentReserve(apt);
            setState(() {});
          },
        );

      case ChessViewMode.matrix:
        return building == null
            ? _buildEmptyBuildingsState(context, colors)
            : _buildMatrix(context, building);

      case ChessViewMode.list:
        return building == null
            ? _buildEmptyBuildingsState(context, colors)
            : ChessGridCatalogView(
                controller: _controller,
                onSelectApartment: _openApartmentDetail,
                onOpenDeal: _openApartmentDeal,
              );

      case ChessViewMode.orders:
        return OrderScreen(
          title: context.tr('chess_grid_tab_orders', fallback: 'Сделка'),
          hideAppBar: true,
          residentialDeal: true,
        );

      case ChessViewMode.payments:
        return const ChessPaymentsView();

      case ChessViewMode.orderPayments:
        return const OrderPaymentsScreen();

      case ChessViewMode.parking:
        return ChessGridParkingView(
          controller: _controller,
          onAddParking: () => ApartmentFormSheet.show(
            context: context,
            isParkingMode: true,
          ),
        );

      case ChessViewMode.admin:
        return ChessGridAdminView(controller: _controller);

      case ChessViewMode.settings:
        return ChessGridSettingsView(controller: _controller);
    }
  }

  Widget _buildEmptyBuildingsState(BuildContext context, dynamic colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.domain_disabled_rounded,
            size: 52,
            color: colors.iconSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('chess_grid_no_buildings', fallback: 'В этом ЖК пока нет корпусов'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => BuildingFormSheet.show(context: context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              context.tr('chess_grid_action_add_building', fallback: 'Добавить корпус'),
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.buttonPrimaryBg,
              foregroundColor: colors.buttonPrimaryFg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
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
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.14)
              : colors.surfacePrimary.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? color
                : colors.borderSubtle.withValues(alpha: 0.5),
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
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
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12,
                color: isSelected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Golos',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 11.5,
                color: isSelected
                    ? color
                    : colors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrix(BuildContext context, Building building) {
    final colors = context.appColors;
    final complexApts = _controller.getApartmentsForComplex(_controller.complex.id);

    // Filter by building
    var filtered = complexApts
        .where((a) => a.buildingKey == building.key || (building.id != null && a.buildingId == building.id))
        .toList();

    // Filter by entrance from filter
    final selectedEntrance = _controller.filter.entrance;
    if (selectedEntrance != 0) {
      filtered = filtered.where((a) => a.entrance == selectedEntrance).toList();
    }

    // Filter by quick status
    if (_quickStatusFilter != null) {
      filtered = filtered.where((a) => a.status == _quickStatusFilter).toList();
    }

    // Filter by dialog filter if active
    if (!_controller.filter.isDefault) {
      filtered = filtered.where((a) => _controller.filter.matches(a)).toList();
    }

    final effectiveEntranceCount = building.getEffectiveEntranceCount(complexApts);
    final effectiveFloorCount = building.getEffectiveFloorCount(complexApts);
    final effectiveApartsPerFloor = building.getApartsPerFloorForEntrance(complexApts);

    final entrances = selectedEntrance == 0
        ? List.generate(effectiveEntranceCount, (i) => i + 1)
        : [selectedEntrance];

    final parkingSpots = _parkingForMatrix(building);
    final rawSlots = entrances.length * effectiveApartsPerFloor;
    final slotsPerRow = rawSlots < 1 ? 1 : rawSlots;
    final parkingRowCount = parkingSpots.isEmpty
        ? 0
        : (parkingSpots.length + slotsPerRow - 1) ~/ slotsPerRow;

    final isMicro = _zoomLevel == ChessZoomLevel.micro50;
    final cellWidth = _zoomLevel.cellWidth;
    final cellHeight = _zoomLevel.cellHeight;
    final floorWidth = _zoomLevel.floorWidth;
    final headerHeight = _zoomLevel.headerHeight;
    final marginVal = isMicro ? 2.0 : 3.0;
    const rowGap = 4.0;

    final isZoomed = (_currentScale - 1.0).abs() > 0.05;

    final floorColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top Spacer matching entrance header height
        SizedBox(height: headerHeight),

        for (int floor = effectiveFloorCount; floor >= 1; floor--)
          Container(
            width: floorWidth,
            height: cellHeight,
            margin: EdgeInsets.only(
              top: marginVal,
              bottom: marginVal + rowGap,
              right: 6,
              left: 2,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surfaceElevated.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colors.borderSubtle.withValues(alpha: 0.5),
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
                    fontSize: 15,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  context.tr('chess_grid_floor_badge', fallback: 'эт'),
                  style: TextStyle(
                    fontFamily: 'Golos',
                    fontSize: 9.5,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        if (parkingRowCount > 0)
          for (int row = 0; row < parkingRowCount; row++)
            Container(
              width: floorWidth,
              height: cellHeight,
              margin: EdgeInsets.only(
                top: marginVal,
                bottom: marginVal + rowGap,
                right: 6,
                left: 2,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.buttonPrimaryBg.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'P',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF1D9BF0),
                    ),
                  ),
                  Text(
                    parkingRowCount == 1 ? 'парк' : '-${row + 1}',
                    style: const TextStyle(
                      fontFamily: 'Golos',
                      fontSize: 9.5,
                      color: Color(0xFF1D9BF0),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );

    final apartmentsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Entrance Header Row
        Row(
          children: [
            for (final e in entrances)
              Container(
                width: effectiveApartsPerFloor * (cellWidth + (marginVal * 2)),
                height: headerHeight,
                padding: const EdgeInsets.only(bottom: 6),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: colors.borderSubtle.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    '${context.tr('chess_grid_entrance_label', fallback: 'Подъезд')} $e',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Floor Rows
        for (int floor = effectiveFloorCount; floor >= 1; floor--)
          Padding(
            padding: const EdgeInsets.only(bottom: rowGap),
            child: Row(
              children: [
                for (final e in entrances)
                  for (int p = 0; p < effectiveApartsPerFloor; p++)
                    _buildCellSlot(
                      filteredApts: filtered,
                      building: building,
                      buildingKey: building.key,
                      entrance: e,
                      floor: floor,
                      position: p,
                    ),
              ],
            ),
          ),
        if (parkingRowCount > 0)
          for (int row = 0; row < parkingRowCount; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: rowGap),
              child: Row(
                children: [
                  for (int slot = 0; slot < slotsPerRow; slot++)
                    row * slotsPerRow + slot < parkingSpots.length
                        ? _buildParkingCell(parkingSpots[row * slotsPerRow + slot])
                        : _buildEmptyMatrixSlot(),
                ],
              ),
            ),
      ],
    );

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
        child: Stack(
          children: [
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.35,
              maxScale: 2.5,
              boundaryMargin: const EdgeInsets.all(80),
              constrained: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    floorColumn,
                    apartmentsColumn,
                    const SizedBox(width: 4),
                    floorColumn,
                  ],
                ),
              ),
            ),
            if (isZoomed)
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    _transformationController.value = Matrix4.identity();
                    if (mounted) {
                      setState(() {
                        _currentScale = 1.0;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colors.borderSubtle.withValues(alpha: 0.6),
                      ),
                      boxShadow: context.appShadows.card,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.restart_alt_rounded,
                          size: 14,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(_currentScale * 100).round()}%',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<ParkingSpot> _parkingForMatrix(Building building) {
    return _controller.parkingSpots.where((spot) {
      final sameBuilding = (building.id != null && spot.buildingId == building.id) ||
          spot.buildingKey == building.key;
      if (!sameBuilding) return false;
      if (_quickStatusFilter != null && spot.status != _quickStatusFilter) return false;
      return true;
    }).toList();
  }

  Widget _buildEmptyMatrixSlot() {
    final cellWidth = _zoomLevel.cellWidth;
    final cellHeight = _zoomLevel.cellHeight;
    final isMicro = _zoomLevel == ChessZoomLevel.micro50;
    return Container(
      width: cellWidth,
      height: cellHeight,
      margin: EdgeInsets.all(isMicro ? 2.0 : 3.0),
      decoration: BoxDecoration(
        color: context.appColors.surfaceElevated.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(isMicro ? 8 : 12),
      ),
    );
  }

  Widget _buildParkingCell(ParkingSpot spot) {
    final colors = context.appColors;
    final cellWidth = _zoomLevel.cellWidth;
    final cellHeight = _zoomLevel.cellHeight;
    final isMicro = _zoomLevel == ChessZoomLevel.micro50;
    final statusColor = spot.status.color;
    final areaLabel = spot.area > 0 ? '${spot.area.toStringAsFixed(0)} м²' : spot.type;
    final priceLabel = spot.price > 0 ? _formatMatrixPrice(spot.price) : '';

    return GestureDetector(
      onTap: () => ParkingDetailSheet.show(
        context: context,
        spot: spot,
        onCreateOrder: () {
          OrderCreateSheet.show(context: context, parking: spot).then((_) {
            if (mounted) setState(() {});
          });
        },
      ),
      child: Container(
        width: cellWidth,
        height: cellHeight,
        margin: EdgeInsets.all(isMicro ? 2.0 : 3.0),
        padding: EdgeInsets.symmetric(
          horizontal: isMicro ? 2 : 5,
          vertical: isMicro ? 2 : 5,
        ),
        decoration: BoxDecoration(
          color: spot.status.bgColor,
          borderRadius: BorderRadius.circular(isMicro ? 8 : 11),
          border: Border.all(color: statusColor.withValues(alpha: 0.55), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '№${spot.number}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: isMicro ? 11.5 : 13.5,
                      color: colors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              areaLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Golos',
                fontWeight: FontWeight.w500,
                fontSize: isMicro ? 9 : 11,
                color: colors.textSecondary,
                height: 1.1,
              ),
            ),
            Text(
              priceLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
                fontSize: isMicro ? 9 : 11,
                color: statusColor,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMatrixPrice(double price) {
    if (price >= 1000000) return '${(price / 1000000).toStringAsFixed(1)} млн';
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)} тыс';
    return price.toStringAsFixed(0);
  }

  Widget _buildCellSlot({
    required List<Apartment> filteredApts,
    required Building building,
    required String buildingKey,
    required int entrance,
    required int floor,
    required int position,
  }) {
    final cellWidth = _zoomLevel.cellWidth;
    final cellHeight = _zoomLevel.cellHeight;
    final isMicro = _zoomLevel == ChessZoomLevel.micro50;

    Apartment? apt = filteredApts.firstWhereOrNull(
      (a) =>
          (a.buildingKey == buildingKey || (building.id != null && a.buildingId == building.id)) &&
          a.entrance == entrance &&
          a.floor == floor &&
          a.position == position,
    );
    if (apt == null) {
      // Check if apartment exists without filters to display ghost/empty slot
      final rawApt = _controller.apartments.firstWhereOrNull(
        (a) =>
            (a.complexId == _controller.complex.id || _controller.complex.id == 0) &&
            (a.buildingKey == buildingKey || (building.id != null && a.buildingId == building.id)) &&
            a.entrance == entrance &&
            a.floor == floor &&
            a.position == position,
      );
      if (rawApt != null) {
        // It was filtered out
        return Container(
          width: cellWidth,
          height: cellHeight,
          margin: EdgeInsets.all(isMicro ? 2.0 : 3.0),
          decoration: BoxDecoration(
            color: context.appColors.surfaceElevated.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(isMicro ? 8 : 12),
            border: Border.all(
              color: context.appColors.borderSubtle.withValues(alpha: 0.18),
            ),
          ),
          child: Center(
            child: Text(
              '№${rawApt.number}',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: isMicro ? 9.5 : 11,
                color: context.appColors.textSecondary.withValues(alpha: 0.35),
              ),
            ),
          ),
        );
      }
    }

    if (apt == null) {
      return Container(
        width: cellWidth,
        height: cellHeight,
        margin: EdgeInsets.all(isMicro ? 2.0 : 3.0),
        decoration: BoxDecoration(
          color: context.appColors.surfaceElevated.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(isMicro ? 8 : 12),
        ),
      );
    }

    final currentApt = apt;
    return ChessGridCell(
      apartment: currentApt,
      zoomLevel: _zoomLevel,
      onTap: () => _openApartmentDetail(currentApt),
      onLongPress: () {
        ApartmentPreviewTooltip.show(
          context: context,
          apartment: currentApt,
          onOpenCard: () => _openApartmentDetail(currentApt),
        );
      },
    );
  }

  Future<void> _openApartmentDetail(Apartment apt) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    Apartment fresh;
    try {
      fresh = await _controller.loadApartmentById(apt);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        showCustomSnackBar(
          context: context,
          message: e.toString().replaceFirst('Exception: ', ''),
          isSuccess: false,
        );
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ApartmentDetailSheet.show(
      context: context,
      apartment: fresh,
      onCreateOrder: () {
        if (fresh.status == ApartmentStatus.available) {
          OrderCreateSheet.show(
            context: context,
            apartment: fresh,
          ).then((_) {
            if (mounted) setState(() {});
          });
          return;
        }
        if (fresh.status == ApartmentStatus.booked || fresh.status == ApartmentStatus.reserved) {
          _openApartmentDeal(fresh);
        }
      },
      onToggleReserve: () {
        _controller.toggleApartmentReserve(fresh);
        showCustomSnackBar(
          context: context,
          message: fresh.status == ApartmentStatus.reserved
              ? context.tr('chess_grid_unreserved_success', fallback: 'Квартира снята с резерва')
              : context.tr('chess_grid_reserved_success', fallback: 'Квартира поставлена в резерв'),
          isSuccess: true,
        );
      },
    );
  }

  Future<void> _openApartmentDeal(Apartment apartment) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    var loaderOpen = true;
    void closeLoader() {
      if (!loaderOpen || !mounted) return;
      loaderOpen = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
    try {
      final api = ApiService();
      final order = await _findApartmentOrder(api, apartment);
      closeLoader();
      if (!mounted) return;
      if (order == null) {
        showCustomSnackBar(
          context: context,
          message: 'Сделка по этой квартире не найдена',
          isSuccess: false,
        );
        return;
      }
      final organizationId = await api.resolveSelectedOrganizationId();
      if (!mounted) return;
      final navResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChessDealDetailsScreen(
            orderId: order.id,
            order: order,
            organizationId: organizationId,
          ),
        ),
      );
      if (navResult is Map && navResult['success'] == true) {
        if (mounted) {
          _controller.loadComplexDetails(_controller.complex.id, showLoading: false);
        }
      }
    } catch (e) {
      closeLoader();
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: e.toString().replaceFirst('Exception: ', ''),
        isSuccess: false,
      );
    }
  }

  Future<deal.Order?> _findApartmentOrder(ApiService api, Apartment apartment) async {
    var orderId = apartment.orderId;
    if (orderId == null || orderId <= 0) {
      final localOrder = _controller.orders.firstWhereOrNull(
        (o) => o.apartmentId == apartment.id,
      );
      if (localOrder != null) {
        orderId = int.tryParse(localOrder.id);
      }
    }
    if (orderId == null || orderId <= 0) {
      try {
        final good = await api.getGoodById(apartment.id);
        orderId = _orderIdFromGood(good);
      } catch (e) {
        debugPrint('ApiService: error getting good by id #${apartment.id}: $e');
      }
    }
    if (orderId == null || orderId <= 0) {
      try {
        final orderResp = await api.getOrders(query: apartment.number, perPage: 15);
        for (final o in orderResp.data) {
          final hasGood = o.goods.any(
            (g) => g.goodId == apartment.id ||
                g.goodName.contains(apartment.number) ||
                g.good.id == apartment.id ||
                g.good.name.contains(apartment.number),
          );
          if (hasGood) {
            orderId = o.id;
            break;
          }
        }
      } catch (e) {
        debugPrint('ApiService: error searching order fallback: $e');
      }
    }
    if (orderId == null || orderId <= 0) return null;
    return api.getOrderDetails(orderId);
  }

  int? _orderIdFromGood(Map<String, dynamic> good) {
    final nested = good['good'] is Map ? Map<String, dynamic>.from(good['good'] as Map) : good;
    final direct = SafeConverters.toIntOrNull(
      nested['deal_id'] ??
      good['deal_id'] ??
      nested['order_id'] ??
      good['order_id'] ??
      nested['dealId'] ??
      good['dealId'] ??
      nested['orderId'] ??
      good['orderId'] ??
      nested['active_deal_id'] ??
      good['active_deal_id'] ??
      nested['active_order_id'] ??
      good['active_order_id'] ??
      nested['last_deal_id'] ??
      good['last_deal_id'] ??
      nested['last_order_id'] ??
      good['last_order_id'],
    );
    if (direct != null && direct > 0) return direct;

    for (final key in ['deal', 'order', 'active_deal', 'active_order', 'latest_deal', 'latest_order']) {
      final value = nested[key] ?? good[key];
      if (value is Map) {
        final id = SafeConverters.toIntOrNull(
          value['id'] ?? value['deal_id'] ?? value['order_id'] ?? value['dealId'] ?? value['orderId'],
        );
        if (id != null && id > 0) return id;
      } else if (value is num || (value is String && int.tryParse(value) != null)) {
        final id = SafeConverters.toIntOrNull(value);
        if (id != null && id > 0) return id;
      }
    }

    for (final listKey in ['deals', 'orders', 'good_orders', 'order_goods']) {
      final list = nested[listKey] ?? good[listKey];
      if (list is List && list.isNotEmpty) {
        final first = list.first;
        if (first is Map) {
          final id = SafeConverters.toIntOrNull(
            first['id'] ?? first['deal_id'] ?? first['order_id'] ?? first['dealId'] ?? first['orderId'],
          );
          if (id != null && id > 0) return id;
        } else if (first is num || (first is String && int.tryParse(first) != null)) {
          final id = SafeConverters.toIntOrNull(first);
          if (id != null && id > 0) return id;
        }
      }
    }

    final attrs = nested['attributes'] ?? good['attributes'] ?? nested['attribute_values'] ?? good['attribute_values'];
    if (attrs is List) {
      for (final a in attrs) {
        if (a is Map) {
          final name = (a['attribute'] is Map ? a['attribute']['name'] : a['name'])?.toString().toLowerCase() ?? '';
          if (name.contains('deal') || name.contains('order') || name.contains('сделк') || name.contains('заказ')) {
            final val = SafeConverters.toIntOrNull(a['value'] ?? a['val']);
            if (val != null && val > 0) return val;
          }
        }
      }
    }

    return null;
  }

  void _showComplexPicker(BuildContext context) async {
    final complexes = _controller.complexes;
    if (complexes.isEmpty) {
      await _controller.loadDataFromApi();
    }
    if (!mounted || _controller.complexes.isEmpty) return;

    final RenderBox? button = _complexTitleKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (button == null || overlay == null) return;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final colors = context.appColors;

    final selectedId = await showMenu<int>(
      context: context,
      position: position,
      color: colors.surfaceElevated,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.borderSubtle.withValues(alpha: 0.5)),
      ),
      items: _controller.complexes.map((c) {
        final isSelected = c.id == _controller.complex.id;
        return PopupMenuItem<int>(
          value: c.id,
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  c.name,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                    color: isSelected ? colors.buttonPrimaryBg : colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: colors.buttonPrimaryBg,
                ),
            ],
          ),
        );
      }).toList(),
    );

    if (selectedId != null && selectedId != _controller.complex.id) {
      await _controller.loadComplexDetails(selectedId);
      _transformationController.value = Matrix4.identity();
      if (mounted) setState(() {});
    }
  }

  AppBar _buildAppBar(
    BuildContext context,
    ResidentialComplex complex,
    Building? building,
    bool hasActiveFilter,
  ) {
    final colors = context.appColors;
    final appBarGradient = [
      colors.surfacePrimary.withValues(alpha: 0.88),
      colors.surfaceElevated.withValues(alpha: 0.72),
    ];
    final primaryText = colors.textPrimary;
    final subtleBorder = colors.borderSubtle.withValues(alpha: 0.36);

    final buildingName = building?.name ?? context.tr('chess_grid_building', fallback: 'Корпус');
    final entranceNum = _controller.filter.entrance;
    final entranceText = entranceNum == 0
        ? context.tr('chess_grid_all_entrances', fallback: 'Все подъезды')
        : '${context.tr('chess_grid_entrance_label', fallback: 'Подъезд')} $entranceNum';

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: colors.overlay.withValues(alpha: 0),
      forceMaterialTransparency: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: colors.overlay.withValues(alpha: 0),
      shadowColor: colors.overlay.withValues(alpha: 0),
      centerTitle: false,
      toolbarHeight: 74,
      titleSpacing: 16,
      title: AppBarShell(
        leading: AppBarShell.capsule(
          context,
          width: AppBarShell.orbSize,
          padding: EdgeInsets.zero,
          gradientColors: appBarGradient,
          borderColor: subtleBorder,
          child: IconButton(
            onPressed: () {
              if (_currentView != ChessViewMode.sections) {
                setState(() => _currentView = ChessViewMode.sections);
                return;
              }
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: primaryText,
            ),
          ),
        ),
        center: AppBarShell.capsule(
          context,
          gradientColors: appBarGradient,
          borderColor: subtleBorder,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  key: _complexTitleKey,
                  onTap: () => _showComplexPicker(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          complex.name,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                            color: primaryText,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: colors.buttonPrimaryBg,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => ChessGridFilterDialog.show(
                    context: context,
                    controller: _controller,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          '$buildingName · $entranceText',
                          style: TextStyle(
                            fontFamily: 'Golos',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: colors.buttonPrimaryBg.withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.tune_rounded,
                        size: 11,
                        color: colors.buttonPrimaryBg.withValues(alpha: 0.85),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        trailing: AppBarShell.capsule(
          context,
          width: AppBarShell.orbSize,
          padding: EdgeInsets.zero,
          gradientColors: appBarGradient,
          borderColor: subtleBorder,
          child: IconButton(
            onPressed: () => ChessGridFilterDialog.show(
              context: context,
              controller: _controller,
            ),
            icon: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/icons/AppBar/filter.png',
                  width: 20,
                  height: 20,
                  color: hasActiveFilter ? colors.buttonPrimaryBg : primaryText,
                ),
                if (hasActiveFilter)
                  Positioned(
                    top: -1,
                    right: -1,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colors.buttonPrimaryBg,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQuickCreateMenu(BuildContext context) {
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              context.tr('chess_grid_action_add_to_object', fallback: 'Добавить в объект'),
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildCreateMenuItem(
              context: ctx,
              icon: Icons.domain_rounded,
              color: colors.buttonPrimaryBg,
              title: context.tr('chess_grid_action_add_building', fallback: 'Добавить корпус'),
              subtitle: context.tr('chess_grid_action_add_building_sub', fallback: 'Создать новый блок, этажи и квартиры на этаже'),
              onTap: () {
                Navigator.pop(ctx);
                BuildingFormSheet.show(context: context);
              },
            ),
            const SizedBox(height: 10),
            _buildCreateMenuItem(
              context: ctx,
              icon: Icons.meeting_room_rounded,
              color: ApartmentStatus.available.color,
              title: context.tr('chess_grid_action_add_apartment', fallback: 'Добавить квартиру'),
              subtitle: context.tr('chess_grid_action_add_apartment_sub', fallback: 'Указать номер, комнатность, площадь, цену и фото'),
              onTap: () {
                Navigator.pop(ctx);
                ApartmentFormSheet.show(context: context);
              },
            ),
            const SizedBox(height: 10),
            _buildCreateMenuItem(
              context: ctx,
              icon: Icons.local_parking_rounded,
              color: Colors.blueAccent,
              title: context.tr('chess_grid_action_add_parking', fallback: 'Добавить парковочное место'),
              subtitle: context.tr('chess_grid_action_add_parking_sub', fallback: 'Подземная, крытая или открытая парковка'),
              onTap: () {
                Navigator.pop(ctx);
                ApartmentFormSheet.show(context: context, isParkingMode: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    return Material(
      color: colors.surfaceElevated.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Golos',
                        fontSize: 11.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.iconSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
