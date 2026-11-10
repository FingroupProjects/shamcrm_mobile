import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

enum _PickerLevel { complex, building, entrance, goods }

/// Выбор квартиры в том же виде, что список товаров при создании заказа.
/// Категория — ЖК, подкатегория — корпус, дальше подъезд и квартиры.
class ChessDealGoodsSheet extends StatefulWidget {
  const ChessDealGoodsSheet({super.key});

  static Future<Apartment?> show(BuildContext context) {
    return showModalBottomSheet<Apartment>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => const ChessDealGoodsSheet(),
    );
  }

  @override
  State<ChessDealGoodsSheet> createState() => _ChessDealGoodsSheetState();
}

class _ChessDealGoodsSheetState extends State<ChessDealGoodsSheet> {
  final _api = ApiService();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  _PickerLevel _level = _PickerLevel.complex;
  bool _loading = true;
  String _query = '';

  List<ResidentialComplex> _complexes = [];
  ResidentialComplex? _complex;
  List<Building> _buildings = [];
  Building? _building;
  List<Apartment> _apartments = [];
  int? _entrance;
  Apartment? _selected;

  @override
  void initState() {
    super.initState();
    _loadComplexes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComplexes() async {
    setState(() => _loading = true);
    try {
      var complexes = ChessGridController.instance.complexes;
      if (complexes.isEmpty) {
        complexes = await _api.getResidentialComplexes();
      }
      if (!mounted) return;
      setState(() {
        _complexes = complexes;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      showCustomSnackBar(
        context: context,
        message: error.toString().replaceFirst('Exception: ', ''),
        isSuccess: false,
      );
    }
  }

  Future<void> _openComplex(ResidentialComplex complex) async {
    setState(() {
      _loading = true;
      _complex = complex;
      _building = null;
      _entrance = null;
      _selected = null;
      _query = '';
      _searchController.clear();
    });
    try {
      var buildings = complex.buildings;
      if (buildings.isEmpty) {
        buildings = await _api.getBuildings(residentialComplexId: complex.id);
      }
      if (!mounted) return;
      setState(() {
        _buildings = buildings;
        _level = _PickerLevel.building;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      showCustomSnackBar(
        context: context,
        message: 'Не удалось загрузить корпуса',
        isSuccess: false,
      );
    }
  }

  Future<void> _openBuilding(Building building) async {
    final buildingId = building.id;
    if (buildingId == null) {
      showCustomSnackBar(
        context: context,
        message: 'У корпуса нет идентификатора',
        isSuccess: false,
      );
      return;
    }
    setState(() {
      _loading = true;
      _building = building;
      _entrance = null;
      _selected = null;
      _query = '';
      _searchController.clear();
    });
    try {
      final goods = await _api.getBuildingGoods(
        buildingId: buildingId,
        residentialComplexId: _complex?.id,
        buildingKey: building.key,
        buildingName: building.name,
      );
      if (!mounted) return;
      final entrances = goods.apartments.map((item) => item.entrance).toSet();
      setState(() {
        _apartments = goods.apartments;
        _level = entrances.length > 1 ? _PickerLevel.entrance : _PickerLevel.goods;
        if (entrances.length == 1) _entrance = entrances.first;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      showCustomSnackBar(
        context: context,
        message: 'Не удалось загрузить квартиры',
        isSuccess: false,
      );
    }
  }

  void _goBack() {
    setState(() {
      _query = '';
      _searchController.clear();
      _selected = null;
      if (_level == _PickerLevel.goods && _entranceCount > 1) {
        _level = _PickerLevel.entrance;
        _entrance = null;
      } else if (_level == _PickerLevel.goods || _level == _PickerLevel.entrance) {
        _level = _PickerLevel.building;
        _entrance = null;
      } else if (_level == _PickerLevel.building) {
        _level = _PickerLevel.complex;
        _complex = null;
      }
    });
  }

  int get _entranceCount => _apartments.map((item) => item.entrance).toSet().length;

  bool _matches(String value) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return value.toLowerCase().contains(query);
  }

  List<Apartment> get _visibleApartments {
    final source = _entrance == null
        ? _apartments
        : _apartments.where((item) => item.entrance == _entrance);
    return source.where((item) => _matches('Квартира ${item.number} ${item.type}')).toList()
      ..sort((a, b) {
        final left = int.tryParse(a.number) ?? 0;
        final right = int.tryParse(b.number) ?? 0;
        return left.compareTo(right);
      });
  }

  String get _breadcrumb {
    final parts = <String>[
      if (_complex != null) _complex!.name,
      if (_building != null) _building!.name,
      if (_entrance != null && _level == _PickerLevel.goods) 'Подъезд $_entrance',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PopScope(
      canPop: _level == _PickerLevel.complex,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(colors),
            _buildSearch(colors),
            Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _buildBody(colors)),
            _buildAddButton(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderSubtle.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: colors.borderSubtle,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text(
                  'Добавление товара',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                if (_level != _PickerLevel.complex)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: GestureDetector(
                      onTap: _goBack,
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back, size: 14, color: colors.buttonPrimaryBg),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _breadcrumb,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500,
                                color: colors.buttonPrimaryBg,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            style: IconButton.styleFrom(backgroundColor: colors.surfaceAccent),
            icon: Icon(Icons.close, color: colors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        decoration: InputDecoration(
          hintText: 'Поиск',
          hintStyle: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
          prefixIcon: Icon(Icons.search, color: colors.textSecondary),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close, color: colors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
          filled: true,
          fillColor: colors.fieldBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: colors.buttonPrimaryBg.withValues(alpha: 0.45)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildBody(dynamic colors) {
    switch (_level) {
      case _PickerLevel.complex:
        final items = _complexes.where((item) => _matches(item.name)).toList();
        if (items.isEmpty) return _empty(colors, 'ЖК не найдены');
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (context, index) => _folderCard(
            colors,
            title: items[index].name,
            subtitle: 'ЖК',
            level: 0,
            onTap: () => _openComplex(items[index]),
          ),
        );
      case _PickerLevel.building:
        final items = _buildings.where((item) => _matches(item.name)).toList();
        if (items.isEmpty) return _empty(colors, 'В этом ЖК нет корпусов');
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (context, index) => _folderCard(
            colors,
            title: items[index].name,
            subtitle: 'Корпус',
            level: 1,
            onTap: () => _openBuilding(items[index]),
          ),
        );
      case _PickerLevel.entrance:
        final numbers = _apartments.map((item) => item.entrance).toSet().toList()..sort();
        final items = numbers.where((item) => _matches('Подъезд $item')).toList();
        if (items.isEmpty) return _empty(colors, 'Подъезды не найдены');
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (context, index) => _folderCard(
            colors,
            title: 'Подъезд ${items[index]}',
            subtitle: 'Подъезд',
            level: 1,
            onTap: () => setState(() {
              _entrance = items[index];
              _level = _PickerLevel.goods;
              _query = '';
              _searchController.clear();
            }),
          ),
        );
      case _PickerLevel.goods:
        final items = _visibleApartments;
        if (items.isEmpty) return _empty(colors, 'В этом подъезде нет квартир');
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          itemCount: items.length,
          itemBuilder: (context, index) => _apartmentCard(colors, items[index]),
        );
    }
  }

  Widget _folderCard(
    dynamic colors, {
    required String title,
    required String subtitle,
    required int level,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12, left: level > 0 ? 24 : 0),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (level > 0) ...[
                Container(
                  width: 3,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.buttonPrimaryBg.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                width: level > 0 ? 40 : 50,
                height: level > 0 ? 40 : 50,
                decoration: BoxDecoration(
                  color: colors.fieldBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  level > 0 ? Icons.subdirectory_arrow_right : Icons.apartment_rounded,
                  color: colors.buttonPrimaryBg,
                  size: level > 0 ? 20 : 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: level > 0 ? 14 : 16,
                        fontFamily: 'Gilroy',
                        fontWeight: level > 0 ? FontWeight.w500 : FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: colors.textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _apartmentCard(dynamic colors, Apartment apartment) {
    final selected = _selected?.id == apartment.id;
    final price = apartment.totalPrice > 0
        ? apartment.totalPrice
        : apartment.pricePerSqm * apartment.totalArea;
    return GestureDetector(
      onTap: () => setState(() => _selected = apartment),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? colors.buttonPrimaryBg : colors.borderSubtle.withValues(alpha: 0.55),
            width: selected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.fieldBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.home_work_outlined, color: colors.buttonPrimaryBg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Квартира № ${apartment.number}',
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${apartment.rooms} комн. · ${apartment.totalArea.toStringAsFixed(1)} м² · ${apartment.status.labelRu}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                    if (price > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          price.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            color: colors.buttonPrimaryBg,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? colors.buttonPrimaryBg : colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(dynamic colors, String title) {
    return Center(
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 16,
          color: colors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildAddButton(dynamic colors) {
    final enabled = _selected != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        border: Border(top: BorderSide(color: colors.borderSubtle.withValues(alpha: 0.5))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: enabled ? () => Navigator.pop(context, _selected) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.buttonPrimaryBg,
            foregroundColor: colors.buttonPrimaryFg,
            disabledBackgroundColor: colors.buttonPrimaryBg.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            'Добавить',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: colors.buttonPrimaryFg,
            ),
          ),
        ),
      ),
    );
  }
}
