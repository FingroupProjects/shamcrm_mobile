import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
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
import 'package:crm_task_manager/page_2/order/order_screen.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_grid_parking_view.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_grid_settings_view.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/order_create_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/chess_grid_3d_view.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

enum ChessViewMode {
  model3D,
  matrix,
  list,
  orders,
  parking,
  admin,
  settings,
}

class ComplexChessScreen extends StatefulWidget {
  final ResidentialComplex complex;

  /// Флаг включения/скрытия 3D режима в Шахматка 1 (можно скрыть в любой момент, выставив false)
  static const bool is3DEnabled = true;

  const ComplexChessScreen({
    super.key,
    required this.complex,
  });

  @override
  State<ComplexChessScreen> createState() => _ComplexChessScreenState();
}

class _ComplexChessScreenState extends State<ComplexChessScreen> {
  late final ChessGridController _controller;
  late final TransformationController _transformationController;
  double _currentScale = 1.0;
  ChessViewMode _currentView = ChessViewMode.matrix;
  ApartmentStatus? _quickStatusFilter;
  final ChessZoomLevel _zoomLevel = ChessZoomLevel.standard100;

  @override
  void initState() {
    super.initState();
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

    final apts = _controller.getApartmentsForComplex(complex.id);
    final freeCount = _controller.getAvailableCount(complex.id);
    final bookedCount = _controller.getBookedCount(complex.id);
    final soldCount = _controller.getSoldCount(complex.id);
    final reservedCount = _controller.getReservedCount(complex.id);

    final hasActiveFilter = !_controller.filter.isDefault || _quickStatusFilter != null;

    return Scaffold(
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

                // View Mode Tabs Switcher (Шахматка, Список, Заказы, Парковка, Настройки)
                _buildNavTabBar(context),

                // Quick Status Filters (Visible in matrix and list modes)
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
                            count: apts.length,
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

                // Main View Body
                Expanded(
                  child: (_controller.isLoadingComplex || _controller.isLoadingApartments)
                      ? const Center(child: CircularProgressIndicator())
                      : _buildCurrentViewBody(context, building),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTabBar(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.45)),
        boxShadow: context.appShadows.card,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (ComplexChessScreen.is3DEnabled) ...[
              _buildNavTabItem(
                mode: ChessViewMode.model3D,
                label: '3D',
                icon: Icons.view_in_ar_rounded,
              ),
              const SizedBox(width: 4),
            ],
            _buildNavTabItem(
              mode: ChessViewMode.matrix,
              label: context.tr('chess_grid_tab_chess', fallback: 'Шахматка'),
              icon: Icons.grid_view_rounded,
            ),
            const SizedBox(width: 4),
            _buildNavTabItem(
              mode: ChessViewMode.list,
              label: context.tr('chess_grid_tab_list', fallback: 'Список'),
              icon: Icons.view_agenda_rounded,
            ),
            const SizedBox(width: 4),
            _buildNavTabItem(
              mode: ChessViewMode.orders,
              label: context.tr('chess_grid_tab_orders', fallback: 'Сделка'),
              icon: Icons.receipt_long_rounded,
            ),
            const SizedBox(width: 4),
            _buildNavTabItem(
              mode: ChessViewMode.parking,
              label: context.tr('chess_grid_tab_parking', fallback: 'Парковка'),
              icon: Icons.local_parking_rounded,
              badge: _controller.parkingSpots.length,
            ),
            const SizedBox(width: 4),
            _buildNavTabItem(
              mode: ChessViewMode.admin,
              label: context.tr('chess_grid_tab_management', fallback: 'Управление'),
              icon: Icons.domain_add_rounded,
            ),
            const SizedBox(width: 4),
            _buildNavTabItem(
              mode: ChessViewMode.settings,
              label: context.tr('chess_grid_tab_settings', fallback: 'Настройки'),
              icon: Icons.tune_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTabItem({
    required ChessViewMode mode,
    required String label,
    required IconData icon,
    int? badge,
  }) {
    final colors = context.appColors;
    final isSelected = _currentView == mode;

    return InkWell(
      onTap: () => setState(() => _currentView = mode),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.buttonPrimaryBg
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? colors.buttonPrimaryFg : colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12.5,
                color: isSelected ? colors.buttonPrimaryFg : colors.textPrimary,
              ),
            ),
            if (badge != null && badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.buttonPrimaryFg.withValues(alpha: 0.22)
                      : colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    fontFamily: 'Golos',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? colors.buttonPrimaryFg : colors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentViewBody(BuildContext context, Building? building) {
    final colors = context.appColors;

    switch (_currentView) {
      case ChessViewMode.model3D:
        final currentComplex = _controller.complex.id == widget.complex.id &&
                _controller.complex.buildings.isNotEmpty
            ? _controller.complex
            : widget.complex;
        return ChessGrid3DView(
          complex: currentComplex,
          apartments: _controller.getApartmentsForComplex(widget.complex.id),
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
              );

      case ChessViewMode.orders:
        return OrderScreen(
          title: context.tr('chess_grid_tab_orders', fallback: 'Сделка'),
          hideAppBar: true,
          residentialDeal: true,
        );

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
    final complexApts = _controller.getApartmentsForComplex(widget.complex.id);

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
            (a.complexId == widget.complex.id || widget.complex.id == 0) &&
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

  void _openApartmentDetail(Apartment apt) {
    ApartmentDetailSheet.show(
      context: context,
      apartment: apt,
      onCreateOrder: () {
        OrderCreateSheet.show(
          context: context,
          apartment: apt,
        ).then((_) {
          if (mounted) setState(() {});
        });
      },
      onToggleReserve: () {
        _controller.toggleApartmentReserve(apt);
        showCustomSnackBar(
          context: context,
          message: apt.status == ApartmentStatus.reserved
              ? context.tr('chess_grid_unreserved_success', fallback: 'Квартира снята с резерва')
              : context.tr('chess_grid_reserved_success', fallback: 'Квартира поставлена в резерв'),
          isSuccess: true,
        );
      },
      onEdit: () {},
    );
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
            onPressed: () => Navigator.pop(context),
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
          child: InkWell(
            onTap: () => ChessGridFilterDialog.show(
              context: context,
              controller: _controller,
            ),
            borderRadius: BorderRadius.circular(26),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          '$buildingName · $entranceText',
                          style: TextStyle(
                            fontFamily: 'Golos',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: colors.buttonPrimaryBg,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: colors.buttonPrimaryBg,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        trailing: AppBarShell.capsule(
          context,
          width: AppBarShell.orbSize,
          padding: EdgeInsets.zero,
          gradientColors: appBarGradient,
          borderColor: subtleBorder,
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: hasActiveFilter
                      ? colors.buttonPrimaryBg
                      : primaryText,
                ),
                onPressed: () => ChessGridFilterDialog.show(
                  context: context,
                  controller: _controller,
                ),
              ),
              if (hasActiveFilter)
                Positioned(
                  top: 9,
                  right: 9,
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
