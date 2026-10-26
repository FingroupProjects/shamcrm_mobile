import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/screens/chess_grid/complex_chess_screen.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/complex_add_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/complex_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
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
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool isClickAvatarIcon = false;

  @override
  void initState() {
    super.initState();
    _controller = ChessGridController.instance;
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

    // Overall stats across all complexes
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
    final totalReserved = _controller.apartments
        .where((a) => a.status == ApartmentStatus.reserved)
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
              : (localizations?.translate('appbar_chess_grid') ?? 'Шахматка'),
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
                                'Жилые комплексы',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${filteredComplexes.length} ${_pluralizeComplex(filteredComplexes.length)}',
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
                            label: const Text(
                              'Добавить ЖК',
                              style: TextStyle(
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

                    // Summary Stats Strip (Всего, Свободно, Бронь, Резерв, Продано)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: colors.surfacePrimary.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.borderSubtle.withValues(alpha: 0.45),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                              title: 'Резерв',
                              value: '$totalReserved',
                              color: ApartmentStatus.reserved.color,
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

                    const SizedBox(height: 6),

                    // Complexes List with Pull-to-refresh
                    Expanded(
                      child: _controller.isLoading && _controller.complexes.isEmpty
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(colors.buttonPrimaryBg),
                              ),
                            )
                          : _controller.errorMessage != null && _controller.complexes.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.cloud_off_rounded,
                                          size: 54,
                                          color: colors.iconSecondary.withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Не удалось загрузить данные',
                                          style: TextStyle(
                                            fontFamily: 'Gilroy',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _controller.errorMessage ?? '',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Golos',
                                            fontSize: 13,
                                            color: colors.textSecondary,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () => _controller.loadDataFromApi(),
                                          icon: const Icon(Icons.refresh_rounded, size: 18),
                                          label: const Text('Повторить попытку'),
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
                                  ),
                                )
                              : filteredComplexes.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.apartment_rounded,
                                            size: 54,
                                            color: colors.iconSecondary
                                                .withValues(alpha: 0.4),
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
                                            onPressed: () =>
                                                ComplexAddSheet.show(context),
                                            icon:
                                                const Icon(Icons.add_rounded, size: 18),
                                            label: const Text(
                                              'Добавить ЖК',
                                              style: TextStyle(
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
                                    )
                                  : RefreshIndicator(
                                      onRefresh: () => _controller.loadDataFromApi(showLoading: false),
                                      color: colors.buttonPrimaryBg,
                                      child: ListView.builder(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
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
                                          builder: (_) => ComplexChessScreen(
                                              complex: complex),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ],
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
    if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return 'комплекса';
    }
    return 'комплексов';
  }
}
